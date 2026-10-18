//
//  DashboardPage.swift
//  BakeCheck
//
//  Overview of the whole order book. Reached from the bottom of the settings
//  screen. Every number is derived from the single store, so it can never
//  disagree with the order list.
//

import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    private var orders: [Order] { store.orders }

    private var pending: Int { orders.filter { $0.status == .pending }.count }
    private var passed: Int { orders.filter { $0.status == .passed }.count }
    private var problems: Int {
        orders.filter { $0.status == .mismatch || $0.status == .review }.count
    }
    private var readyToHandOver: Int {
        orders.filter { $0.status == .passed && $0.handover == .ready }.count
    }
    private var inProgress: Int { orders.filter(OrderMath.needsVerification).count }

    private var recent: [Order] {
        Array(orders.sorted { $0.updatedAt > $1.updatedAt }.prefix(5))
    }

    private var lastUpdated: Date? { recent.first?.updatedAt }

    var body: some View {
        PushedPageScaffold {
            BakeHero(
                title: store.settings.storeName,
                subtitle: BakeFormat.fullDate(Date()),
                symbol: "birthday.cake",
                tag: "โหมดสาธิต",
                footnote: "\(orders.count) ออเดอร์ · \(pending) รอตรวจสอบ · \(problems) ต้องแก้ไข"
            )

            BakeButton(title: "เริ่มตรวจสอบออเดอร์", icon: .scan, variant: .primary, block: true) {
                router.startScanning()
            }

            if problems > 0 {
                Notice(tone: .error, icon: .alertTriangle) {
                    VStack(alignment: .leading, spacing: BakeSpace.s3) {
                        Text("มี \(Text("\(problems)").bold()) ออเดอร์ที่พบข้อผิดพลาดหรือต้องตรวจสอบเพิ่มเติม ซึ่งยังส่งมอบไม่ได้")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.errorStrong)
                            .fixedSize(horizontal: false, vertical: true)
                        BakeButton(title: "ดูออเดอร์ที่ต้องแก้ไข", variant: .dangerOutline, size: .small) {
                            router.openOrders()
                        }
                    }
                }
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 158), spacing: BakeSpace.s3)],
                spacing: BakeSpace.s3
            ) {
                StatCard(
                    label: "ออเดอร์ทั้งหมด",
                    value: orders.count,
                    icon: .package,
                    tone: .brand,
                    support: lastUpdated.map { "อัปเดตล่าสุด \(BakeFormat.relative($0))" } ?? "ยังไม่มีออเดอร์"
                )
                StatCard(
                    label: "รอตรวจสอบ",
                    value: pending,
                    icon: .clock,
                    tone: .neutral,
                    support: "ต้องสแกนก่อนส่งมอบ"
                )
                StatCard(
                    label: "ตรวจสอบผ่าน",
                    value: passed,
                    icon: .checkCircle,
                    tone: .success,
                    support: readyToHandOver > 0 ? "พร้อมส่งมอบ \(readyToHandOver) ออเดอร์" : "ยืนยันผลแล้ว"
                )
                StatCard(
                    label: "พบข้อผิดพลาด",
                    value: problems,
                    icon: .alertTriangle,
                    tone: .error,
                    support: "ต้องแก้ไขก่อนส่งมอบ"
                )
            }

            SectionHead(title: "ทางลัด", meta: "เหลืออีก \(inProgress) ออเดอร์ที่ต้องตรวจสอบ")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 300), spacing: BakeSpace.s3)],
                spacing: BakeSpace.s3
            ) {
                QuickAction(
                    icon: .scan,
                    title: "ตรวจสอบออเดอร์",
                    desc: "สแกนเทียบจำนวนสินค้าก่อนส่งมอบ"
                ) { router.startScanning() }

                QuickAction(
                    icon: .orders,
                    title: "ดูออเดอร์ทั้งหมด",
                    desc: "ทั้งหมด \(orders.count) ออเดอร์"
                ) { router.openOrders() }

                QuickAction(
                    icon: .truck,
                    title: "ส่งมอบสินค้า",
                    desc: readyToHandOver > 0
                        ? "พร้อมส่งมอบ \(readyToHandOver) ออเดอร์"
                        : "ยังไม่มีออเดอร์ที่พร้อมส่งมอบ"
                ) { router.go(.handover(nil)) }

                QuickAction(
                    icon: .history,
                    title: "ดูประวัติการตรวจสอบ",
                    desc: "\(store.scans.count) บันทึกการตรวจสอบ"
                ) { router.go(.history(nil)) }
            }

            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                SectionHead(
                    title: "ออเดอร์ล่าสุด",
                    meta: "อัปเดตล่าสุด 5 รายการ",
                    accessoryTitle: "ดูทั้งหมด",
                    accessoryIcon: .arrowRight
                ) { router.openOrders() }

                ForEach(recent) { order in
                    OrderRow(
                        order: order,
                        onOpen: { router.go(.orderDetail(order.id)) },
                        onPrimary: { performPrimaryAction(for: order) }
                    )
                }
            }
        }
        .navigationTitle("ภาพรวม")
        .bakeInlineTitle()
    }

    private func performPrimaryAction(for order: Order) {
        if order.status == .passed && order.handover == .ready {
            router.go(.handover(order.id))
        } else if order.status == .handedOver {
            router.go(.orderDetail(order.id))
        } else {
            router.startScanning(orderId: order.id)
        }
    }
}

/// Tappable shortcut row (web `.quick-action`), restyled with an illustrated
/// icon tile and a trailing chevron.
struct QuickAction: View {
    var icon: IconName
    var title: String
    var desc: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BakeSpace.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [BakeColor.terraSoft, BakeColor.surfaceTint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Icon(name: icon, size: 19)
                        .foregroundStyle(BakeColor.bark)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BakeFont.bodyStrong)
                        .foregroundStyle(BakeColor.text)
                    Text(desc)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Icon(name: .chevronRight, size: 14)
                    .foregroundStyle(BakeColor.dune)
            }
            .padding(BakeSpace.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BakeRadius.card, style: .continuous)
                    .fill(BakeColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BakeRadius.card, style: .continuous)
                    .stroke(BakeColor.borderSoft, lineWidth: 1)
            )
            .bakeCardShadow()
        }
        .buttonStyle(.plain)
    }
}
