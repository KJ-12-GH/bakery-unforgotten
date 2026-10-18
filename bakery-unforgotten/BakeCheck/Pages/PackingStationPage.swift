//
//  PackingStationPage.swift
//  BakeCheck
//
//  ★ The heart of the product: scan a packed order and compare the detected
//  quantities against the customer's order before it leaves the bakery.
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

    var body: some View {
        Group {
            if isRoot {
                RootPageScaffold(tab: .packing) { content }
            } else {
                PushedPageScaffold { content }
                    .navigationTitle(selectedId ?? "ตรวจสอบสินค้า")
                    .navigationBarTitleDisplayMode(.inline)
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
    }

    @ViewBuilder
    private var content: some View {
        PageHeader(
            title: "ตรวจสอบสินค้า",
            subtitle: "เทียบจำนวนสินค้าจริงกับออเดอร์ของลูกค้าก่อนส่งมอบให้พนักงานขับรถ",
            accessory: AnyView(SimTag(text: "ผลจำลอง"))
        )

        if currentOrder == nil {
            BakeCard {
                EmptyState(
                    icon: .inbox,
                    title: "ยังไม่มีออเดอร์ให้ตรวจสอบ",
                    text: "เมื่อมีออเดอร์ใหม่ ระบบจะแสดงที่นี่เพื่อให้สแกนตรวจสอบ",
                    actionTitle: "ไปที่จัดการออเดอร์",
                    actionIcon: .orders
                ) { router.select(.orders) }
            }
        } else if let order = currentOrder {
            orderPickerCard(order)

            CameraPanel(
                isScanning: isScanning,
                isDisabled: isLocked,
                lastCapture: lastCapture,
                onScan: runScan
            )

            comparisonCard(order)

            instructionsCard
        }
    }

    // MARK: - Order picker

    private func orderPickerCard(_ order: Order) -> some View {
        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                BakeCardHeader(
                    title: "ออเดอร์ที่ตรวจสอบ",
                    icon: .orders,
                    accessory: AnyView(StatusBadge(order: order))
                )

                VStack(alignment: .leading, spacing: BakeSpace.s2) {
                    Text("เลือกออเดอร์")
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.text)

                    Menu {
                        ForEach(selectableOrders) { item in
                            Button {
                                selectedId = item.id
                                lastCapture = nil
                            } label: {
                                Text("\(item.id) — \(item.customer) (\(item.items.count) รายการ)")
                            }
                        }
                    } label: {
                        HStack(spacing: BakeSpace.s2) {
                            Text("\(order.id) — \(order.customer) (\(order.items.count) รายการ)")
                                .font(BakeFont.small)
                                .foregroundStyle(BakeColor.text)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Icon(name: .chevronRight, size: 13)
                                .foregroundStyle(BakeColor.dune)
                        }
                        .padding(.horizontal, BakeSpace.s3)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(BakeColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                                .stroke(BakeColor.border, lineWidth: 1)
                        )
                    }
                    .disabled(isLocked)
                }

                BakeSeparator()

                VStack(spacing: BakeSpace.s3) {
                    DefRow(key: "ลูกค้า", value: order.customer)
                    DefRow(
                        key: "จำนวนที่สั่งรวม",
                        value: "\(OrderMath.totalQty(order)) ชิ้น · \(order.items.count) รายการ"
                    )
                    DefRow(key: "เวลาที่อัปเดต", value: BakeFormat.dateTime(order.updatedAt))
                    DefRow(key: "สถานะการส่งมอบ", value: Labels.handover(order.handover))
                }

                BakeButton(title: "รายละเอียดออเดอร์", icon: .orders, variant: .ghost, block: true) {
                    router.go(.orderDetail(order.id))
                }
            }
        }
    }

    // MARK: - Comparison

    private func comparisonCard(_ order: Order) -> some View {
        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                BakeCardHeader(
                    title: "ผลการเปรียบเทียบ",
                    subtitle: draft.map { "สแกนเมื่อ \(BakeFormat.dateTime($0.scannedAt)) · ผลจำลอง" }
                        ?? "ยังไม่ได้สแกนออเดอร์นี้",
                    icon: .shield,
                    accessory: isScanning
                        ? AnyView(
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small).tint(BakeColor.terra)
                                Text("กำลังประมวลผล…")
                                    .font(BakeFont.tiny)
                                    .foregroundStyle(BakeColor.muted)
                            }
                        )
                        : nil
                )

                ResultBanner(outcome: outcome, summary: summary)

                if draft != nil {
                    SummaryStrip(tiles: [
                        ("สั่งรวม", "\(summary.totalExpected)", BakeColor.text),
                        ("ตรวจพบรวม", "\(summary.totalEffective)", BakeColor.text),
                        ("ขาด", "\(summary.missing)", BakeColor.errorStrong),
                        ("เกิน", "\(summary.extra)", BakeColor.warningStrong),
                    ])

                    ComparisonList(
                        rows: rows,
                        onEdit: isLocked ? nil : { productId in
                            openEditSheet(for: productId)
                        }
                    )
                } else {
                    Notice(tone: .neutral, icon: .scan) {
                        Text("กด “ตรวจสอบด้วยการจำลอง” เพื่อจำลองผลการตรวจจับสินค้า ระบบจะเทียบจำนวนให้อัตโนมัติ")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if isLocked {
                    Notice(tone: .warning, icon: .lock) {
                        Text("ออเดอร์นี้ส่งมอบแล้ว ไม่สามารถสแกนหรือแก้ไขได้อีก")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.warningStrong)
                    }
                }

                BakeSeparator()

                VStack(spacing: BakeSpace.s2) {
                    BakeButton(
                        title: "ตรวจสอบอีกครั้ง",
                        icon: .refresh,
                        variant: .ghost,
                        block: true,
                        isEnabled: !isLocked,
                        isLoading: isScanning && draft != nil
                    ) {
                        runScan(nil)
                    }

                    if (order.status == .passed || order.status == .handedOver) && draft == nil && !isScanning {
                        BakeButton(title: "ดูผลการตรวจสอบ", icon: .shield, variant: .secondary, block: true) {
                            router.go(.result(order.id))
                        }
                        if order.handover == .ready {
                            BakeButton(title: "ไปส่งมอบ", icon: .truck, variant: .success, block: true) {
                                router.go(.handover(order.id), in: .orders)
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
        }
    }

    private var instructionsCard: some View {
        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                BakeCardHeader(title: "วิธีใช้งาน", icon: .info)

                InstructionStep(number: 1, text: "เลือกออเดอร์ที่ต้องการตรวจสอบจากเมนูด้านบน")
                InstructionStep(number: 2, text: "วางสินค้าแต่ละชนิดให้อยู่ในกรอบกล้อง แล้วกด “จับภาพและตรวจสอบ”")
                InstructionStep(number: 3, text: "หากไม่สะดวกใช้กล้อง กด “ตรวจสอบด้วยการจำลอง” เพื่อสาธิตขั้นตอน")
                InstructionStep(number: 4, text: "แก้ไขรายการที่ไม่ตรง แล้วกด “ยืนยันผลตรวจสอบ” เมื่อจำนวนครบถ้วน")
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

struct InstructionStep: View {
    var number: Int
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: BakeSpace.s3) {
            Text("\(number)")
                .font(BakeFont.tiny.weight(.bold))
                .foregroundStyle(BakeColor.terraStrong)
                .frame(width: 22, height: 22)
                .background(BakeColor.terraSoft)
                .clipShape(Circle())
            Text(text)
                .font(BakeFont.small)
                .foregroundStyle(BakeColor.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
