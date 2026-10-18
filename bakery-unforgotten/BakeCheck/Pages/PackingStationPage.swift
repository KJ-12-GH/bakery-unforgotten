//
//  PackingStationPage.swift
//  BakeCheck
//
//  ★ The heart of the product: scan a packed order and compare the detected
//  quantities against the customer's order before it leaves the bakery.
//
//  Decluttered for a live demo — the screen is just: pick the order (in the
//  toolbar) → capture → compare → confirm. No hero, no how-to, no filler.
//

import SwiftUI

struct PackingStationPage: View {
    /// nil when opened as a tab root (the station picks the first order itself).
    var orderId: String?

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter

    @State private var selectedId: String?
    @State private var isScanning = false
    @State private var lastCapture: Data?
    @State private var editTarget: EditQuantityTarget?
    @State private var showConfirm = false
    @State private var showNotifications = false
    @State private var readIds: Set<String> = []
    @State private var scanTask: Task<Void, Never>?

    private var isRoot: Bool { orderId == nil }

    /// Orders that can be picked in the station (everything still in flight).
    private var selectableOrders: [Order] {
        store.orders.filter { OrderMath.needsVerification($0) || $0.id == selectedId }
    }

    private var fallbackId: String? {
        store.orders.first { $0.status == .pending }?.id
            ?? store.ordersNeedingVerification.first?.id
            ?? store.orders.first?.id
    }

    private var currentOrder: Order? {
        guard let id = selectedId ?? orderId ?? fallbackId else { return nil }
        return store.order(id)
    }

    private var draft: ScanDraft? {
        guard let order = currentOrder else { return nil }
        return store.draft(order.id)
    }

    private var rows: [ComparisonRow] {
        guard let order = currentOrder else { return [] }
        return store.comparisons(forOrder: order.id)
    }

    private var outcome: ScanOutcome? {
        draft == nil ? nil : Verification.outcome(rows: rows)
    }

    private var summary: ComparisonSummary { Verification.summarize(rows: rows) }

    private var isLocked: Bool { currentOrder?.handover == .handedOver }

    private var unreadCount: Int {
        store.notifications.filter { !readIds.contains($0.id) }.count
    }

    var body: some View {
        Group {
            if isRoot {
                RootPageScaffold(tab: .packing) { content }
                    .navigationTitle("ตรวจสอบสินค้า")
                    .toolbar { rootToolbar }
            } else {
                PushedPageScaffold { content }
                    .navigationTitle(currentOrder?.id ?? "ตรวจสอบสินค้า")
                    .bakeInlineTitle()
            }
        }
        .onAppear {
            if selectedId == nil { selectedId = orderId ?? fallbackId }
        }
        .onChange(of: orderId) { _, newValue in
            if let newValue { selectedId = newValue }
        }
        .onDisappear {
            scanTask?.cancel()
            scanTask = nil
            isScanning = false
        }
        .sheet(item: $editTarget) { target in
            EditQuantitySheet(
                target: target,
                onSave: { qty in
                    guard let order = currentOrder else { return }
                    store.setManualQty(orderId: order.id, productId: target.productId, qty: qty)
                    toasts.show(.info, "บันทึกการแก้ไขแล้ว", "ระบบคำนวณผลเปรียบเทียบใหม่ให้อัตโนมัติ")
                },
                onRevert: {
                    guard let order = currentOrder else { return }
                    store.setManualQty(orderId: order.id, productId: target.productId, qty: nil)
                }
            )
        }
        .sheet(isPresented: $showConfirm) { confirmDialog }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(
                notifications: store.notifications,
                readIds: readIds,
                onOpen: { item in
                    readIds.insert(item.id)
                    router.go(item.opensHandover ? .handover(item.orderId) : .packing(item.orderId))
                }
            )
        }
    }

    // MARK: - Toolbar (root only)

    @ToolbarContentBuilder
    private var rootToolbar: some ToolbarContent {
        ToolbarItem(placement: .bakeTrailing) {
            Button {
                showNotifications = true
            } label: {
                Image(systemName: unreadCount > 0 ? "bell.badge" : "bell")
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("การแจ้งเตือน")
        }
        if !selectableOrders.isEmpty {
            ToolbarItem(placement: .bakeTrailing) {
                Menu {
                    Picker("เลือกออเดอร์", selection: Binding(
                        get: { selectedId ?? currentOrder?.id ?? "" },
                        set: { selectedId = $0; lastCapture = nil }
                    )) {
                        ForEach(selectableOrders) { item in
                            Text("\(item.id) · \(item.customer)").tag(item.id)
                        }
                    }
                } label: {
                    Label("เลือกออเดอร์", systemImage: "arrow.left.arrow.right")
                }
                .disabled(isLocked)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let order = currentOrder {
            orderSummaryCard(order)

            BakeSplit(
                primary: {
                    CameraPanel(
                        isScanning: isScanning,
                        isDisabled: isLocked,
                        lastCapture: lastCapture,
                        onScan: runScan
                    )
                },
                secondary: {
                    comparisonCard(order)
                }
            )
        } else {
            BakeCard {
                EmptyState(
                    icon: .inbox,
                    title: "ยังไม่มีออเดอร์ให้ตรวจสอบ",
                    text: "เมื่อมีออเดอร์ใหม่ ระบบจะแสดงที่นี่เพื่อให้สแกนตรวจสอบ",
                    actionTitle: "ไปที่จัดการออเดอร์",
                    actionIcon: .orders
                ) { router.go(.orders) }
            }
        }
    }

    // MARK: - Order summary (compact)

    private func orderSummaryCard(_ order: Order) -> some View {
        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                HStack(spacing: BakeSpace.s3) {
                    if let first = order.items.first {
                        ProductGlyph(productId: first.productId, size: 44)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(order.id)
                            .font(BakeFont.mono)
                            .foregroundStyle(BakeColor.wood)
                        Text(order.customer)
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    StatusBadge(order: order)
                }

                HStack(spacing: BakeSpace.s2) {
                    Label("\(order.items.count) รายการ", systemImage: "list.bullet")
                    Text("·")
                    Label("\(OrderMath.totalQty(order)) ชิ้น", systemImage: "number")
                }
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.muted)
                .labelStyle(.titleAndIcon)
            }
        }
    }

    // MARK: - Comparison

    private func comparisonCard(_ order: Order) -> some View {
        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                BakeCardHeader(
                    title: "ผลการเปรียบเทียบ",
                    subtitle: draft.map { "สแกนเมื่อ \(BakeFormat.time($0.scannedAt)) · ผลจำลอง" }
                        ?? "ยังไม่ได้สแกนออเดอร์นี้",
                    icon: .shield,
                    accessory: isScanning
                        ? AnyView(ProgressView().controlSize(.small).tint(BakeColor.terra))
                        : nil
                )

                ResultBanner(outcome: outcome, summary: summary)

                if draft != nil {
                    SummaryStrip(tiles: [
                        ("สั่งรวม", "\(summary.totalExpected)", BakeColor.text),
                        ("ตรวจพบ", "\(summary.totalEffective)", BakeColor.text),
                        ("ขาด", "\(summary.missing)", BakeColor.errorStrong),
                        ("เกิน", "\(summary.extra)", BakeColor.warningStrong),
                    ])

                    ComparisonList(
                        rows: rows,
                        onEdit: isLocked ? nil : { productId in
                            openEditSheet(for: productId)
                        }
                    )
                }

                if isLocked {
                    Notice(tone: .warning, icon: .lock) {
                        Text("ออเดอร์นี้ส่งมอบแล้ว ไม่สามารถสแกนหรือแก้ไขได้อีก")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.warningStrong)
                    }
                }

                actions(order)
            }
        }
    }

    @ViewBuilder
    private func actions(_ order: Order) -> some View {
        VStack(spacing: BakeSpace.s2) {
            if draft != nil {
                BakeButton(
                    title: "ตรวจสอบอีกครั้ง",
                    icon: .refresh,
                    variant: .secondary,
                    block: true,
                    isEnabled: !isLocked,
                    isLoading: isScanning
                ) {
                    runScan(nil)
                }
            }

            if (order.status == .passed || order.status == .handedOver) && draft == nil && !isScanning {
                BakeButton(title: "ดูผลการตรวจสอบ", icon: .shield, variant: .secondary, block: true) {
                    router.go(.result(order.id))
                }
                if order.handover == .ready {
                    BakeButton(title: "ไปส่งมอบ", icon: .truck, variant: .success, block: true) {
                        router.go(.handover(order.id))
                    }
                }
            } else {
                BakeButton(
                    title: "ยืนยันผลตรวจสอบ",
                    icon: .shield,
                    variant: .success,
                    block: true,
                    isEnabled: draft != nil && outcome == .passed && !isScanning
                ) {
                    showConfirm = true
                }

                if draft != nil, outcome != .passed {
                    Text("ต้องให้ทุกรายการตรงกันก่อนจึงจะยืนยันผลได้")
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Actions

    private func openEditSheet(for productId: String) {
        guard let row = rows.first(where: { $0.productId == productId }) else { return }
        let product = SeedData.product(productId)
        editTarget = EditQuantityTarget(
            productId: productId,
            productName: product.name,
            expected: row.expectedQty,
            detected: row.detectedQty,
            current: row.manualQty
        )
    }

    private func runScan(_ image: Data?) {
        guard let order = currentOrder, !isScanning else { return }

        if isLocked {
            toasts.show(.warning, "ออเดอร์นี้ส่งมอบแล้ว", "ไม่สามารถสแกนซ้ำได้")
            return
        }

        isScanning = true
        lastCapture = image

        scanTask?.cancel()
        scanTask = Task {
            try? await Task.sleep(for: .milliseconds(1600))
            guard !Task.isCancelled else { return }

            let lines = ScanService.simulate(order: order)
            store.recordScan(orderId: order.id, lines: lines)
            isScanning = false
            scanTask = nil

            switch Verification.outcome(rows: store.comparisons(forOrder: order.id)) {
            case .passed:
                toasts.show(.success, "ตรวจสอบผ่าน", "\(order.id) จำนวนสินค้าตรงกับออเดอร์")
            case .mismatch:
                toasts.show(.error, "พบข้อผิดพลาด", "มีสินค้าไม่ตรงจำนวน ต้องแก้ไขก่อนส่งมอบ")
            case .uncertain:
                toasts.show(.warning, "ต้องตรวจสอบเพิ่มเติม", "มีรายการที่ระบบไม่มั่นใจ กรุณาตรวจสอบ")
            }
        }
    }

    @ViewBuilder
    private var confirmDialog: some View {
        if let order = currentOrder {
            ConfirmDialogContent(
                icon: .shield,
                tone: .success,
                title: "ยืนยันผลการตรวจสอบ",
                message: "ยืนยันว่าออเดอร์ \(order.id) มีจำนวนสินค้าตรงตามรายการครบทุกรายการ",
                confirmTitle: "ยืนยันผลตรวจสอบ",
                confirmVariant: .success,
                detail: {
                    VStack(alignment: .leading, spacing: BakeSpace.s3) {
                        BakeCard {
                            VStack(spacing: BakeSpace.s3) {
                                DefRow(key: "ออเดอร์", value: order.id, mono: true)
                                DefRow(key: "จำนวนรวม", value: "\(summary.totalEffective) ชิ้น")
                                DefRow(key: "รายการที่แก้ไขโดยพนักงาน", value: "\(summary.corrected) รายการ")
                                DefRow(key: "ผลรวม", value: "ตรงกันครบทุกรายการ", valueColor: BakeColor.successStrong)
                            }
                        }
                        if summary.corrected > 0 {
                            Text("หมายเหตุ: บางรายการใช้จำนวนที่พนักงานแก้ไขแทนผลการตรวจจับของระบบ")
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                        }
                    }
                },
                onConfirm: {
                    if store.confirmVerification(orderId: order.id) {
                        toasts.show(.success, "ยืนยันผลตรวจสอบเรียบร้อย", "\(order.id) พร้อมส่งมอบ")
                        if store.settings.autoAdvance {
                            router.go(.result(order.id))
                        }
                    }
                },
                onCancel: {}
            )
        }
    }
}
