//
//  Sheets.swift
//  BakeCheck
//
//  Sheet-based dialogs: confirmations, staff quantity correction, order
//  detail, notification feed and a history record breakdown.
//

import SwiftUI

/// Generic `Identifiable` wrapper so a `String` id can drive `.sheet(item:)`.
struct IdentifiedID: Identifiable, Hashable {
    let id: String
}

// MARK: - Confirm dialog

struct ConfirmDialogContent<Detail: View>: View {
    var icon: IconName = .alertCircle
    var tone: BadgeTone = .neutral
    var title: String
    var message: String
    var confirmTitle: String
    var confirmVariant: BakeButtonVariant = .primary
    @ViewBuilder var detail: () -> Detail
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    HStack(alignment: .top, spacing: BakeSpace.s3) {
                        Icon(name: icon, size: 22)
                            .foregroundStyle(tone.foreground)
                            .padding(BakeSpace.s3)
                            .background(tone.background)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(BakeFont.cardTitle)
                                .foregroundStyle(BakeColor.text)
                            Text(message)
                                .font(BakeFont.small)
                                .foregroundStyle(BakeColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }

                    detail()

                    HStack(spacing: BakeSpace.s2) {
                        BakeButton(title: "ยกเลิก", variant: .ghost, block: true) {
                            onCancel()
                            dismiss()
                        }
                        BakeButton(
                            title: confirmTitle,
                            icon: .check,
                            variant: confirmVariant,
                            block: true
                        ) {
                            onConfirm()
                            dismiss()
                        }
                    }
                }
                .padding(BakeSpace.s4)
            }
            .background(BakeColor.cream)
            .navigationTitle("ยืนยันการทำรายการ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Staff quantity correction

struct EditQuantityTarget: Identifiable, Hashable {
    let productId: String
    let productName: String
    let expected: Int
    let detected: Int?
    let current: Int?

    var id: String { productId }
}

struct EditQuantitySheet: View {
    var target: EditQuantityTarget
    var onSave: (Int) -> Void
    var onRevert: () -> Void

    @State private var draft: Int
    @Environment(\.dismiss) private var dismiss

    init(target: EditQuantityTarget, onSave: @escaping (Int) -> Void, onRevert: @escaping () -> Void) {
        self.target = target
        self.onSave = onSave
        self.onRevert = onRevert
        // The sheet is created fresh for each product, so this is enough.
        _draft = State(initialValue: target.current ?? target.expected)
    }

    private var isReverted: Bool { target.current == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    Notice(tone: .warning, icon: .alertCircle) {
                        Text("ผลจากระบบเป็นการตรวจจับแบบจำลอง ไม่ใช่ AI จริง — ตัวเลขที่พนักงานกรอกจะถูกใช้แทนในการเปรียบเทียบ")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.warningStrong)
                    }

                    BakeCard {
                        VStack(spacing: BakeSpace.s3) {
                            DefRow(key: "สินค้า", value: target.productName)
                            DefRow(key: "จำนวนที่สั่ง", value: "\(target.expected) ชิ้น")
                            DefRow(
                                key: "ระบบตรวจพบ",
                                value: target.detected.map(String.init) ?? "ไม่แน่ชัด"
                            )
                        }
                    }

                    QuantityStepper(value: $draft)
                        .frame(maxWidth: .infinity)

                    Text("เมื่อบันทึกแล้ว ระบบจะคำนวณผลเปรียบเทียบใหม่ให้อัตโนมัติ")
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    HStack(spacing: BakeSpace.s2) {
                        BakeButton(
                            title: "ล้างการแก้ไข",
                            variant: .ghost,
                            block: true,
                            isEnabled: !isReverted
                        ) {
                            onRevert()
                            dismiss()
                        }
                        BakeButton(title: "บันทึกการแก้ไข", icon: .check, variant: .primary, block: true) {
                            onSave(draft)
                            dismiss()
                        }
                    }
                }
                .padding(BakeSpace.s4)
            }
            .background(BakeColor.cream)
            .navigationTitle("แก้ไขจำนวนที่ตรวจพบ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Order detail

struct OrderDetailSheet: View {
    var order: Order
    var latestScan: ScanRecord?
    var onVerify: (String) -> Void
    var onHandover: (String) -> Void
    var onViewHistory: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakeSpace.s5) {
                    VStack(alignment: .leading, spacing: BakeSpace.s2) {
                        Text("รหัสออเดอร์")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                        Text(order.id)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(BakeColor.text)
                        Text(order.customer)
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.muted)
                        HStack(spacing: BakeSpace.s2) {
                            StatusBadge(order: order)
                            Badge(text: Labels.handover(order.handover), tone: Labels.handoverTone(order.handover))
                        }
                    }

                    BakeCard {
                        VStack(spacing: BakeSpace.s3) {
                            DefRow(key: "จำนวนที่สั่งรวม", value: "\(OrderMath.totalQty(order)) ชิ้น")
                            DefRow(
                                key: "สร้างเมื่อ",
                                value: BakeFormat.dateTime(order.createdAt),
                                footnote: BakeFormat.relative(order.createdAt)
                            )
                            DefRow(key: "อัปเดตล่าสุด", value: BakeFormat.relative(order.updatedAt))
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

                    VStack(alignment: .leading, spacing: BakeSpace.s2) {
                        Text("รายการสินค้า")
                            .font(BakeFont.sectionTitle)
                            .foregroundStyle(BakeColor.text)

                        ForEach(order.items) { item in
                            let product = SeedData.product(item.productId)
                            HStack(spacing: BakeSpace.s3) {
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
                            .background(BakeColor.surfaceSunken)
                            .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                                    .stroke(BakeColor.borderSoft, lineWidth: 1)
                            )
                        }
                    }

                    if let latestScan {
                        VStack(alignment: .leading, spacing: BakeSpace.s2) {
                            Text("ผลการตรวจสอบล่าสุด")
                                .font(BakeFont.sectionTitle)
                                .foregroundStyle(BakeColor.text)

                            Notice(tone: Labels.outcomeTone(latestScan.outcome), icon: .shield) {
                                VStack(alignment: .leading, spacing: BakeSpace.s2) {
                                    Text(Labels.outcome(latestScan.outcome))
                                        .font(BakeFont.bodyStrong)
                                        .foregroundStyle(BakeColor.text)
                                    Text(
                                        "สแกนเมื่อ \(BakeFormat.dateTime(latestScan.scannedAt))"
                                        + (latestScan.verifiedAt.map { " · ยืนยันเมื่อ \(BakeFormat.dateTime($0))" } ?? "")
                                    )
                                    .font(BakeFont.tiny)
                                    .foregroundStyle(BakeColor.muted)

                                    ComparisonList(rows: Verification.rows(from: latestScan))
                                }
                            }
                        }
                    }

                    VStack(spacing: BakeSpace.s2) {
                        BakeButton(
                            title: "ประวัติการตรวจสอบ",
                            icon: .history,
                            variant: .ghost,
                            block: true,
                            isEnabled: latestScan != nil
                        ) {
                            dismiss()
                            onViewHistory(order.id)
                        }

                        if order.status == .passed && order.handover == .ready {
                            BakeButton(title: "ส่งมอบออเดอร์", icon: .truck, variant: .success, block: true) {
                                dismiss()
                                onHandover(order.id)
                            }
                        } else if order.status != .handedOver {
                            BakeButton(title: "ไปตรวจสอบสินค้า", icon: .scan, variant: .primary, block: true) {
                                dismiss()
                                onVerify(order.id)
                            }
                        }
                    }
                }
                .padding(BakeSpace.s4)
            }
            .background(BakeColor.cream)
            .navigationTitle(order.id)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                        .foregroundStyle(BakeColor.bark)
                }
            }
        }
    }
}

// MARK: - Notification feed

struct NotificationsSheet: View {
    var notifications: [NotificationItem]
    var readIds: Set<String>
    var onOpen: (NotificationItem) -> Void

    @Environment(\.dismiss) private var dismiss

    private var unreadCount: Int {
        notifications.filter { !readIds.contains($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty {
                    EmptyState(
                        icon: .inbox,
                        title: "ไม่มีการแจ้งเตือน",
                        text: "เมื่อมีออเดอร์ที่ต้องตรวจสอบหรือพร้อมส่งมอบ รายการจะแสดงที่นี่"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: BakeSpace.s2) {
                            ForEach(notifications) { item in
                                Button {
                                    dismiss()
                                    onOpen(item)
                                } label: {
                                    HStack(alignment: .top, spacing: BakeSpace.s3) {
                                        Icon(name: item.tone.symbol, size: 17)
                                            .foregroundStyle(item.tone.foreground)
                                            .padding(BakeSpace.s2)
                                            .background(item.tone.background)
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.title)
                                                .font(BakeFont.smallStrong)
                                                .foregroundStyle(BakeColor.text)
                                            Text(item.detail)
                                                .font(BakeFont.tiny)
                                                .foregroundStyle(BakeColor.muted)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text(BakeFormat.relative(item.at))
                                                .font(BakeFont.tiny)
                                                .foregroundStyle(BakeColor.dune)
                                        }
                                        Spacer(minLength: 0)

                                        if !readIds.contains(item.id) {
                                            Circle()
                                                .fill(BakeColor.terra)
                                                .frame(width: 8, height: 8)
                                                .padding(.top, 6)
                                        }
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
                        .padding(BakeSpace.s4)
                    }
                }
            }
            .background(BakeColor.cream)
            .navigationTitle("การแจ้งเตือน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(unreadCount) ใหม่")
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                        .foregroundStyle(BakeColor.bark)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - History record breakdown

struct RecordDetailSheet: View {
    var record: ScanRecord
    var order: Order?
    var onShowOrder: (String) -> Void
    var onShowResult: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    HStack(spacing: BakeSpace.s2) {
                        Badge(text: Labels.outcome(record.outcome), tone: Labels.outcomeTone(record.outcome), dot: true)
                        Badge(text: "\(record.lines.count) รายการ", tone: .neutral)
                        if record.corrected {
                            Badge(text: "มีการแก้ไขโดยพนักงาน", tone: .warning)
                        }
                    }

                    BakeCard {
                        VStack(spacing: BakeSpace.s3) {
                            DefRow(key: "รหัสผลตรวจสอบ", value: record.id, mono: true)
                            DefRow(key: "รหัสออเดอร์", value: record.orderId, mono: true)
                            if let order {
                                DefRow(key: "ลูกค้า", value: order.customer)
                            }
                            DefRow(key: "สแกนเมื่อ", value: BakeFormat.dateTime(record.scannedAt))
                            if let verifiedAt = record.verifiedAt {
                                DefRow(key: "ยืนยันเมื่อ", value: BakeFormat.dateTime(verifiedAt))
                            }
                        }
                    }

                    ComparisonList(rows: Verification.rows(from: record))

                    Notice(tone: .warning, icon: .flask) {
                        Text("บันทึกนี้มาจากผลการตรวจจับแบบจำลอง ไม่ใช่การวิเคราะห์ด้วย AI จริง")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.warningStrong)
                    }

                    HStack(spacing: BakeSpace.s2) {
                        BakeButton(title: "ดูออเดอร์", icon: .orders, variant: .secondary, block: true) {
                            dismiss()
                            onShowOrder(record.orderId)
                        }
                        BakeButton(title: "ดูผลการตรวจสอบ", icon: .shield, variant: .primary, block: true) {
                            dismiss()
                            onShowResult(record.orderId)
                        }
                    }
                }
                .padding(BakeSpace.s4)
            }
            .background(BakeColor.cream)
            .navigationTitle("ผลการตรวจสอบ \(record.orderId)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                        .foregroundStyle(BakeColor.bark)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
