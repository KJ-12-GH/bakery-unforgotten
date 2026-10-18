//
//  OrdersPage.swift
//  BakeCheck
//
//  Search, filter and open orders. The primary action on each row is decided
//  by the order's own state (verify / hand over / inspect).
//

import SwiftUI

private enum OrderFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case active
    case passed
    case problem
    case handedOver

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "ทั้งหมด"
        case .pending: "รอตรวจสอบ"
        case .active: "กำลังตรวจสอบ"
        case .passed: "ตรวจสอบผ่าน"
        case .problem: "พบข้อผิดพลาด"
        case .handedOver: "ส่งมอบแล้ว"
        }
    }

    func matches(_ order: Order) -> Bool {
        switch self {
        case .all: true
        case .pending: order.status == .pending
        case .active: order.status == .verifying
        case .passed: order.status == .passed
        case .problem: order.status == .mismatch || order.status == .review
        case .handedOver: order.status == .handedOver
        }
    }
}

struct OrdersPage: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    @State private var query = ""
    @State private var filter: OrderFilter = .all

    private var filtered: [Order] {
        store.orders
            .filter { filter.matches($0) && matchesQuery($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func matchesQuery(_ order: Order) -> Bool {
        let term = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !term.isEmpty else { return true }
        if order.id.lowercased().contains(term) { return true }
        if order.customer.lowercased().contains(term) { return true }
        return order.items.contains { item in
            let product = SeedData.product(item.productId)
            return product.name.lowercased().contains(term)
                || product.nameEn.lowercased().contains(term)
        }
    }

    var body: some View {
        PushedPageScaffold {
            PageHeader(
                title: "จัดการออเดอร์",
                subtitle: "ค้นหา ตรวจสอบรายละเอียด และเลือกออเดอร์เพื่อเข้าสู่ขั้นตอนตรวจสอบสินค้า"
            )

            BakeButton(title: "เริ่มตรวจสอบออเดอร์", icon: .scan, variant: .primary, block: true) {
                router.startScanning()
            }

            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                BakeTextField(
                    placeholder: "ค้นหารหัสออเดอร์ ลูกค้า หรือชื่อสินค้า",
                    text: $query,
                    icon: .search
                )

                Text("พบ \(Text("\(filtered.count)").bold()) ออเดอร์")
                    .font(BakeFont.small)
                    .foregroundStyle(BakeColor.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BakeSpace.s2) {
                    ForEach(OrderFilter.allCases) { option in
                        Chip(
                            title: option.label,
                            count: store.orders.filter(option.matches).count,
                            isOn: filter == option
                        ) {
                            filter = option
                        }
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }

            if filtered.isEmpty {
                BakeCard {
                    EmptyState(
                        icon: .inbox,
                        title: "ไม่พบออเดอร์ที่ตรงกับเงื่อนไข",
                        text: "ลองล้างคำค้นหาหรือเลือกตัวกรองสถานะอื่น",
                        actionTitle: "ล้างตัวกรอง",
                        actionIcon: .refresh
                    ) {
                        query = ""
                        filter = .all
                    }
                }
            } else {
                LazyVStack(spacing: BakeSpace.s3) {
                    ForEach(filtered) { order in
                        OrderRow(
                            order: order,
                            onOpen: { router.go(.orderDetail(order.id)) },
                            onPrimary: { performPrimaryAction(for: order) }
                        )
                    }
                }
            }

            Notice(tone: .info) {
                Text("ออเดอร์ที่ยังไม่ผ่านการตรวจสอบจะไม่สามารถส่งมอบได้ — เลือก “ตรวจสอบ” เพื่อเข้าสู่สถานีตรวจสอบสินค้า")
                    .font(BakeFont.small)
                    .foregroundStyle(BakeColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle("")
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
