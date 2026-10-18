//
//  HandoverPage.swift
//  BakeCheck
//
//  Hand verified orders to a delivery driver.
//  Guard rails: an unverified order never appears here, and an order can only
//  be handed over once.
//

import SwiftUI

struct HandoverPage: View {
    var orderId: String?

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter

    @State private var targetId: String?
    @State private var driver = SeedData.drivers[0]

    private var ready: [Order] {
        store.orders
            .filter { $0.status == .passed && $0.handover == .ready }
            .sorted { lhs, rhs in
                if let orderId {
                    if lhs.id == orderId { return true }
                    if rhs.id == orderId { return false }
                }
                return (lhs.verifiedAt ?? .distantPast) > (rhs.verifiedAt ?? .distantPast)
            }
    }

    private var handedOver: [Order] {
        store.orders
            .filter { $0.handover == .handedOver }
            .sorted { ($0.handedOverAt ?? .distantPast) > ($1.handedOverAt ?? .distantPast) }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        PushedPageScaffold(maxContentWidth: 820) {
            PageHeader(
                title: "ส่งมอบสินค้า",
                subtitle: "ยืนยันการรับมอบออเดอร์ที่ตรวจสอบผ่านแล้วให้พนักงานขับรถ",
                accessory: AnyView(Badge(text: "\(ready.count) ออเดอร์", tone: ready.isEmpty ? .neutral : .success, dot: true))
            )

            BakeButton(title: "ไปที่จัดการออเดอร์", icon: .orders, variant: .ghost, block: true) {
                router.go(.orders)
            }

            SectionHead(title: "พร้อมส่งมอบ", meta: "เฉพาะออเดอร์ที่ยืนยันผลตรวจสอบแล้วเท่านั้น")

            if ready.isEmpty {
                BakeCard {
                    EmptyState(
                        icon: .truck,
                        title: "ยังไม่มีออเดอร์ที่พร้อมส่งมอบ",
                        text: "ออเดอร์จะปรากฏที่นี่หลังผ่านการยืนยันผลตรวจสอบจำนวนสินค้าแล้ว",
                        actionTitle: "ไปตรวจสอบสินค้า",
                        actionIcon: .scan
                    ) { router.startScanning() }
                }
            } else {
                LazyVStack(spacing: BakeSpace.s3) {
                    ForEach(ready) { order in
                        handoverCard(order)
                    }
                }
            }

            if !handedOver.isEmpty {
                SectionHead(title: "ส่งมอบล่าสุด", meta: "บันทึกการส่งมอบที่เสร็จสิ้นแล้ว")

                VStack(spacing: BakeSpace.s2) {
                    ForEach(handedOver) { order in
                        BakeCard(padding: BakeSpace.s3) {
                            VStack(alignment: .leading, spacing: BakeSpace.s2) {
                                HStack(spacing: BakeSpace.s2) {
                                    Text(order.id)
                                        .font(BakeFont.mono)
                                        .foregroundStyle(BakeColor.wood)
                                    Spacer(minLength: 0)
                                    Badge(text: "ส่งมอบแล้ว", tone: .brand)
                                }
                                Text(order.customer)
                                    .font(BakeFont.tiny)
                                    .foregroundStyle(BakeColor.muted)
                                HStack(spacing: BakeSpace.s4) {
                                    miniMetric("จำนวนรวม", "\(OrderMath.totalQty(order)) ชิ้น")
                                    miniMetric("พนักงานขับรถ", order.driver ?? "—")
                                    miniMetric("ส่งมอบเมื่อ", order.handedOverAt.map { BakeFormat.relative($0) } ?? "—")
                                }
                                BakeButton(title: "ประวัติ", variant: .ghost, size: .small, block: true) {
                                    router.go(.history(order.id))
                                }
                            }
                        }
                    }
                }
            }

            Notice(tone: .neutral, icon: .lock) {
                Text("ระบบจะไม่อนุญาตให้ส่งมอบออเดอร์ที่ยังไม่ผ่านการตรวจสอบ หรือที่ส่งมอบไปแล้ว เพื่อป้องกันการส่งมอบซ้ำ")
                    .font(BakeFont.small)
                    .foregroundStyle(BakeColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle("ส่งมอบสินค้า")
        .bakeInlineTitle()
        .sheet(item: Binding(
            get: { targetId.map(IdentifiedID.init(id:)) },
            set: { targetId = $0?.id }
        )) { target in
            confirmDialog(for: target.id)
        }
    }

    private func handoverCard(_ order: Order) -> some View {
        let scan = store.latestScan(order.id)

        return BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                HStack(alignment: .top, spacing: BakeSpace.s2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.id)
                            .font(BakeFont.mono)
                            .foregroundStyle(BakeColor.wood)
                        Text(order.customer)
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                    }
                    Spacer(minLength: 0)
                    Badge(text: "พร้อมส่งมอบ", tone: .success, dot: true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(order.items) { item in
                        let product = SeedData.product(item.productId)
                        HStack(spacing: BakeSpace.s2) {
                            Text("\(product.emoji) \(product.name)")
                                .font(BakeFont.small)
                                .foregroundStyle(BakeColor.text)
                            Spacer(minLength: 0)
                            Text("\(item.expectedQty) ชิ้น")
                                .font(BakeFont.smallStrong)
                                .foregroundStyle(BakeColor.wood)
                        }
                    }
                }

                BakeSeparator()

                VStack(spacing: BakeSpace.s3) {
                    DefRow(key: "จำนวนรวม", value: "\(OrderMath.totalQty(order)) ชิ้น")
                    DefRow(
                        key: "ยืนยันผลเมื่อ",
                        value: order.verifiedAt.map { BakeFormat.dateTime($0) } ?? "—",
                        footnote: order.verifiedAt.map { BakeFormat.relative($0) }
                    )
                    DefRow(key: "รหัสผลตรวจสอบ", value: scan?.id ?? "—", mono: true)
                }

                HStack(spacing: BakeSpace.s2) {
                    BakeButton(title: "ดูผลตรวจสอบ", icon: .shield, variant: .ghost, size: .small, block: true) {
                        router.go(.result(order.id))
                    }
                    BakeButton(title: "ยืนยันการส่งมอบ", icon: .truck, variant: .success, size: .small, block: true) {
                        driver = SeedData.drivers[0]
                        targetId = order.id
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.lg, style: .continuous)
                .stroke(order.id == orderId ? BakeColor.terra : .clear, lineWidth: 1.5)
        )
    }

    private func miniMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.muted)
            Text(value)
                .font(BakeFont.smallStrong)
                .foregroundStyle(BakeColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func confirmDialog(for id: String) -> some View {
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
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                },
                onConfirm: {
                    if store.handOver(orderId: order.id, driver: driver) {
                        toasts.show(.success, "ส่งมอบสำเร็จ", "\(order.id) ส่งมอบให้ \(driver) แล้ว")
                    }
                    targetId = nil
                },
                onCancel: { targetId = nil }
            )
        }
    }
}
