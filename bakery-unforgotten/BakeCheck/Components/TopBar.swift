//
//  TopBar.swift
//  BakeCheck
//
//  Custom header shown on the root screen of every area: brand, context,
//  global order search, notification feed and the signed-in staff member.
//

import SwiftUI

struct TopBar: View {
    var tab: AppTab

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var query = ""
    @State private var showNotifications = false
    @State private var showSearch = false
    @State private var readIds: Set<String> = []

    private var notifications: [NotificationItem] { store.notifications }

    private var unreadCount: Int {
        notifications.filter { !readIds.contains($0.id) }.count
    }

    var body: some View {
        HStack(spacing: BakeSpace.s3) {
            Text("BakeCheck")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(BakeColor.wood)
                .layoutPriority(1)

            Text(tab.title)
                .font(BakeFont.small)
                .foregroundStyle(BakeColor.muted)
                .lineLimit(1)

            Spacer(minLength: 0)

            if sizeClass == .regular {
                searchField
                    .frame(width: 240)
            } else {
                IconButton(icon: .search, size: 38, iconSize: 16) {
                    showSearch = true
                }
            }

            notificationButton
            profileButton
        }
        .padding(.horizontal, BakeSpace.s4)
        .padding(.vertical, BakeSpace.s3)
        .background(BakeColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BakeColor.border)
                .frame(height: 1)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(
                notifications: notifications,
                readIds: readIds,
                onOpen: open(notification:)
            )
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet { orderId in
                showSearch = false
                router.go(.orderDetail(orderId), in: .orders)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: BakeSpace.s2) {
            Icon(name: .search, size: 15)
                .foregroundStyle(BakeColor.dune)
            TextField("ค้นหารหัสออเดอร์ เช่น BK-1001", text: $query)
                .font(BakeFont.small)
                .autocorrectionDisabled()
                .bakeUppercaseAutocapitalization()
                .onSubmit(submitSearch)
        }
        .padding(.horizontal, BakeSpace.s3)
        .frame(height: 38)
        .background(BakeColor.surfaceSunken)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(BakeColor.border, lineWidth: 1)
        )
    }

    private var notificationButton: some View {
        ZStack(alignment: .topTrailing) {
            IconButton(icon: .bell, size: 38, iconSize: 16) {
                showNotifications = true
            }
            if unreadCount > 0 {
                Circle()
                    .fill(BakeColor.terra)
                    .frame(width: 8, height: 8)
                    .offset(x: 1, y: -1)
            }
        }
    }

    private var profileButton: some View {
        Button {
            router.select(.settings)
        } label: {
            AvatarCircle(initials: store.staff.initials, size: 38)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("โปรไฟล์ \(store.staff.name)")
    }

    private func submitSearch() {
        let term = query.trimmingCharacters(in: .whitespaces).uppercased()
        guard !term.isEmpty else { return }
        if let match = store.orders.first(where: { $0.id.uppercased().contains(term) }) {
            query = ""
            router.go(.orderDetail(match.id), in: .orders)
        } else {
            toasts.show(.warning, "ไม่พบออเดอร์", "ไม่พบออเดอร์ที่ตรงกับ “\(query.trimmingCharacters(in: .whitespaces))”")
        }
    }

    private func open(notification: NotificationItem) {
        readIds.insert(notification.id)
        let destination: Destination = notification.opensHandover
            ? .handover(notification.orderId)
            : .packing(notification.orderId)
        router.go(destination, in: notification.opensHandover ? .orders : .packing)
    }
}

// MARK: - Compact search sheet

struct SearchSheet: View {
    var onSelect: (String) -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var matches: [Order] {
        let term = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !term.isEmpty else { return [] }
        return store.orders.filter { order in
            if order.id.lowercased().contains(term) { return true }
            if order.customer.lowercased().contains(term) { return true }
            return order.items.contains { item in
                let product = SeedData.product(item.productId)
                return product.name.lowercased().contains(term)
                    || product.nameEn.lowercased().contains(term)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BakeSpace.s3) {
                BakeTextField(placeholder: "ค้นหารหัสออเดอร์ ลูกค้า หรือชื่อสินค้า", text: $query, icon: .search)

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    EmptyState(
                        icon: .search,
                        title: "ค้นหาออเดอร์",
                        text: "พิมพ์รหัสออเดอร์ ชื่อลูกค้า หรือชื่อสินค้าเพื่อค้นหา"
                    )
                } else if matches.isEmpty {
                    EmptyState(
                        icon: .inbox,
                        title: "ไม่พบออเดอร์",
                        text: "ลองตรวจสอบคำค้นหาแล้วลองอีกครั้ง"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: BakeSpace.s2) {
                            ForEach(matches) { order in
                                Button {
                                    onSelect(order.id)
                                } label: {
                                    HStack(spacing: BakeSpace.s3) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(order.id)
                                                .font(BakeFont.mono)
                                                .foregroundStyle(BakeColor.wood)
                                            Text(order.customer)
                                                .font(BakeFont.tiny)
                                                .foregroundStyle(BakeColor.muted)
                                        }
                                        Spacer(minLength: 0)
                                        StatusBadge(order: order)
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
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(BakeSpace.s4)
            .background(BakeColor.cream)
            .navigationTitle("ค้นหาออเดอร์")
            .bakeInlineTitle()
            .toolbar {
                ToolbarItem(placement: .bakeTrailing) {
                    Button("ปิด") { dismiss() }
                        .foregroundStyle(BakeColor.bark)
                }
            }
        }
    }
}
