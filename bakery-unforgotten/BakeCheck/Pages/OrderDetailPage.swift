//
//  OrderDetailPage.swift
//  BakeCheck
//
//  Full-screen order detail (the push destination of `.orderDetail`).
//

import SwiftUI

struct OrderDetailPage: View {
    var orderId: String

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter

    @State private var confirmTarget: IdentifiedID?
    @State private var driver = SeedData.drivers[0]

    var body: some View {
        Group {
            if let order = store.order(orderId) {
                content(for: order)
            } else {
                PushedPageScaffold(maxContentWidth: 820) {
                    BakeCard {
                        EmptyState(
                            icon: .inbox,
                            title: "ไม่พบออเดอร์นี้",
                            text: "ออเดอร์อาจถูกลบหรือรหัสไม่ถูกต้อง",
                            actionTitle: "กลับไปยังออเดอร์",
                            actionIcon: .arrowLeft
                        ) { router.go(.orders) }
                    }
                }
            }
        }
        .navigationTitle("")
        .bakeInlineTitle()
    }

    @ViewBuilder
    private func content(for order: Order) -> some View {
        let scan = store.latestScan(order.id)

        PushedPageScaffold {
            PageHeader(
                title: order.id,
                subtitle: order.customer,
                note: "อัปเดตล่าสุด \(BakeFormat.relative(order.updatedAt))",
                accessory: AnyView(
                    VStack(alignment: .trailing, spacing: BakeSpace.s2) {
                        StatusBadge(order: order)
                        Badge(text: Labels.handover(order.handover), tone: Labels.handoverTone(order.handover))
                    }
                )
            )

            BakeCard {
                VStack(spacing: BakeSpace.s3) {
                    DefRow(key: "จำนวนที่สั่งรวม", value: "\(OrderMath.totalQty(order)) ชิ้น")
                    DefRow(key: "จำนวนรายการ", value: "\(order.items.count) รายการ")
                    DefRow(key: "สร้างเมื่อ", value: BakeFormat.dateTime(order.createdAt), footnote: BakeFormat.relative(order.createdAt))
                    if let verifiedAt = order.verifiedAt {
                        DefRow(key: "ยืนยันผลตรวจสอบ", value: BakeFormat.dateTime(verifiedAt))
                    }
                    if let handedOverAt = order.handedOverAt {
                        DefRow(
                            key: "ส่งมอบเมื่อ",
                            value: BakeFormat.dateTime(handedOverAt),
                            footnote: order.driver.map { "โดย \($0)" }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                Text("รายการสินค้า")
                    .font(BakeFont.sectionTitle)
                    .foregroundStyle(BakeColor.text)

                ForEach(order.items) { item in
                    HStack(spacing: BakeSpace.s3) {
                        let product = SeedData.product(item.productId)
                        Text(product.emoji)
                            .font(.system(size: 20))
                            .frame(width: 38, height: 38)
                            .background(BakeColor.surfaceSunken)
                            .clipShape(RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(product.name)
                                .font(BakeFont.smallStrong)
                                .foregroundStyle(BakeColor.text)
                            Text(product.nameEn)
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                        }
                        Spacer(minLength: 0)
                        Text("×\(item.expectedQty)")
                            .font(BakeFont.bodyStrong)
                            .foregroundStyle(BakeColor.wood)
                    }
                    .padding(BakeSpace.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BakeColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                            .stroke(BakeColor.border, lineWidth: 1)
                    )
                }
            }

            if let scan {
                VStack(alignment: .leading, spacing: BakeSpace.s3) {
                    Text("ผลการตรวจสอบล่าสุด")
                        .font(BakeFont.sectionTitle)
                        .foregroundStyle(BakeColor.text)

                    Notice(tone: Labels.outcomeTone(scan.outcome), icon: .shield) {
                        VStack(alignment: .leading, spacing: BakeSpace.s3) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Labels.outcome(scan.outcome))
                                    .font(BakeFont.bodyStrong)
                                    .foregroundStyle(BakeColor.text)
                                Text(
                                    "สแกนเมื่อ \(BakeFormat.dateTime(scan.scannedAt))"
                                    + (scan.verifiedAt.map { " · ยืนยันเมื่อ \(BakeFormat.dateTime($0))" } ?? "")
                                )
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                            }
                            HStack(spacing: BakeSpace.s2) {
                                Badge(text: "\(scan.lines.count) รายการ", tone: .neutral)
                                if scan.corrected {
                                    Badge(text: "มีการแก้ไขโดยพนักงาน", tone: .warning)
                                }
                            }
                            ComparisonList(rows: Verification.rows(from: scan))
                        }
                    }
                }
            } else {
                Notice(tone: .neutral, icon: .scan) {
                    Text("ออเดอร์นี้ยังไม่มีการสแกนตรวจสอบสินค้า")
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.muted)
                }
            }

            VStack(spacing: BakeSpace.s2) {
                BakeButton(
                    title: "ประวัติการตรวจสอบ",
                    icon: .history,
                    variant: .ghost,
                    block: true,
                    isEnabled: scan != nil
                ) {
                    router.go(.history(order.id))
                }

                if order.status == .passed && order.handover == .ready {
                    BakeButton(title: "ส่งมอบออเดอร์", icon: .truck, variant: .success, block: true) {
                        driver = SeedData.drivers[0]
                        confirmTarget = IdentifiedID(id: order.id)
                    }
                } else if order.status != .handedOver {
                    BakeButton(title: "ไปตรวจสอบสินค้า", icon: .scan, variant: .primary, block: true) {
                        router.go(.packing(order.id))
                    }
                }
            }
        }
        .sheet(item: $confirmTarget) { target in
            handoverConfirm(for: target.id)
        }
    }

    @ViewBuilder
    private func handoverConfirm(for id: String) -> some View {
        if let order = store.order(id) {
            ConfirmDialogContent(
                icon: .truck,
                tone: .success,
                title: "ยืนยันการส่งมอบออเดอร์",
                message: "ยืนยันว่าพนักงานขับรถได้รับออเดอร์ \(order.id) แล้ว และจำนวนสินค้าครบถ้วน",
                confirmTitle: "ยืนยันการส่งมอบ",
                confirmVariant: .success,
                detail: {
                    VStack(alignment: .leading, spacing: BakeSpace.s4) {
                        BakeCard {
                            VStack(spacing: BakeSpace.s3) {
                                DefRow(key: "ออเดอร์", value: order.id, mono: true)
                                DefRow(key: "ลูกค้า", value: order.customer)
                                DefRow(key: "จำนวนรวม", value: "\(OrderMath.totalQty(order)) ชิ้น")
                            }
                        }

                        VStack(alignment: .leading, spacing: BakeSpace.s2) {
                            Text("พนักงานขับรถผู้รับมอบ")
                                .font(BakeFont.smallStrong)
                                .foregroundStyle(BakeColor.text)
                            Picker("พนักงานขับรถ", selection: $driver) {
                                ForEach(SeedData.drivers, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(BakeColor.terra)
                            Text("เมื่อยืนยันแล้ว สถานะออเดอร์จะเปลี่ยนเป็น “ส่งมอบแล้ว” และไม่สามารถส่งมอบซ้ำได้")
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                        }
                    }
                },
                onConfirm: {
                    if store.handOver(orderId: order.id, driver: driver) {
                        toasts.show(.success, "ส่งมอบสำเร็จ", "\(order.id) ส่งมอบให้ \(driver) แล้ว")
                    }
                },
                onCancel: {}
            )
        }
    }
}
