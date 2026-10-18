//
//  HistoryPage.swift
//  BakeCheck
//
//  Every committed verification record, with filters and a breakdown sheet.
//

import SwiftUI

private enum PeriodFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case week
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "ทั้งหมด"
        case .today: "วันนี้"
        case .week: "7 วันล่าสุด"
        case .month: "30 วันล่าสุด"
        }
    }

    func contains(_ date: Date, now: Date) -> Bool {
        switch self {
        case .all: true
        case .today: Calendar.current.isDate(date, inSameDayAs: now)
        case .week: date >= now.addingTimeInterval(-7 * 24 * 3600)
        case .month: date >= now.addingTimeInterval(-30 * 24 * 3600)
        }
    }
}

struct HistoryPage: View {
    /// The area root (nil) or a pushed, order-filtered view.
    var orderId: String?

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    @State private var query = ""
    @State private var outcomeFilter: ScanOutcome? = nil
    @State private var period: PeriodFilter = .all
    @State private var selectedRecord: IdentifiedID?

    private var now = Date()

    private var rows: [(record: ScanRecord, order: Order?, mismatches: Int)] {
        let term = query.trimmingCharacters(in: .whitespaces).lowercased()

        return store.scans
            .map { record in
                (
                    record: record,
                    order: store.order(record.orderId),
                    mismatches: record.lines.filter { $0.status != .match }.count
                )
            }
            .filter { row in
                if !term.isEmpty {
                    let productMatch = row.record.lines.contains { line in
                        SeedData.product(line.productId).name.lowercased().contains(term)
                    }
                    let orderMatch = row.record.orderId.lowercased().contains(term)
                        || (row.order?.customer.lowercased().contains(term) ?? false)
                    if !productMatch && !orderMatch { return false }
                }
                if let outcomeFilter, row.record.outcome != outcomeFilter { return false }
                if !period.contains(row.record.scannedAt, now: now) { return false }
                return true
            }
            .sorted { $0.record.scannedAt > $1.record.scannedAt }
    }

    private var filterActive: Bool {
        !query.isEmpty || outcomeFilter != nil || period != .all
    }

    var body: some View {
        PushedPageScaffold { content }
            .navigationTitle("ประวัติออเดอร์")
            .bakeInlineTitle()
            .sheet(item: $selectedRecord) { target in
            if let row = rows.first(where: { $0.record.id == target.id }) {
                RecordDetailSheet(
                    record: row.record,
                    order: row.order,
                    onShowOrder: { id in router.go(.orderDetail(id)) },
                    onShowResult: { id in router.go(.result(id)) }
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        PageHeader(
            title: "ประวัติออเดอร์",
            subtitle: "บันทึกผลการตรวจสอบจำนวนสินค้าย้อนหลัง",
            accessory: AnyView(Badge(text: "\(rows.count) บันทึก", tone: .neutral))
        )

        BakeButton(title: "เริ่มตรวจสอบออเดอร์", icon: .scan, variant: .primary, block: true) {
            router.startScanning()
        }

        BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                BakeTextField(
                    placeholder: "ค้นหารหัสออเดอร์ ลูกค้า หรือชื่อสินค้า",
                    text: $query,
                    icon: .search
                )

                VStack(alignment: .leading, spacing: BakeSpace.s2) {
                    Text("ผลการตรวจสอบ")
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.text)

                    Menu {
                        Button("ทั้งหมด") { outcomeFilter = nil }
                        Button("ตรวจสอบผ่าน") { outcomeFilter = .passed }
                        Button("พบข้อผิดพลาด") { outcomeFilter = .mismatch }
                        Button("ต้องตรวจสอบเพิ่มเติม") { outcomeFilter = .uncertain }
                    } label: {
                        HStack(spacing: BakeSpace.s2) {
                            Text(outcomeFilter.map(Labels.outcome) ?? "ทั้งหมด")
                                .font(BakeFont.small)
                                .foregroundStyle(BakeColor.text)
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
                }

                VStack(alignment: .leading, spacing: BakeSpace.s2) {
                    Text("ช่วงวันที่")
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.text)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BakeSpace.s2) {
                            ForEach(PeriodFilter.allCases) { option in
                                Chip(
                                    title: option.label,
                                    count: store.scans.filter { option.contains($0.scannedAt, now: now) }.count,
                                    isOn: period == option
                                ) {
                                    period = option
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if filterActive {
                    BakeButton(title: "ล้างตัวกรอง", icon: .refresh, variant: .ghost, block: true) {
                        query = ""
                        outcomeFilter = nil
                        period = .all
                    }
                }
            }
        }

        if orderId != nil, rows.contains(where: { $0.record.orderId == orderId }) {
            Text("กรองจากออเดอร์ \(orderId ?? "") (กดที่รายการเพื่อดูรายละเอียด)")
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.muted)
        }

        Text("พบ \(Text("\(rows.count)").bold()) บันทึกการตรวจสอบ")
            .font(BakeFont.small)
            .foregroundStyle(BakeColor.muted)

        if rows.isEmpty {
            BakeCard {
                EmptyState(
                    icon: .history,
                    title: "ไม่พบประวัติการตรวจสอบ",
                    text: "ลองปรับตัวกรองหรือล้างคำค้นหาเพื่อดูบันทึกทั้งหมด",
                    actionTitle: filterActive ? "ล้างตัวกรอง" : nil,
                    actionIcon: .refresh
                ) {
                    query = ""
                    outcomeFilter = nil
                    period = .all
                }
            }
        } else {
            LazyVStack(spacing: BakeSpace.s3) {
                ForEach(rows, id: \.record.id) { row in
                    recordRow(row.record, order: row.order, mismatches: row.mismatches)
                }
            }
        }
    }

    private func recordRow(_ record: ScanRecord, order: Order?, mismatches: Int) -> some View {
        let totalQty = order.map(OrderMath.totalQty)
            ?? record.lines.reduce(0) { $0 + $1.expectedQty }

        return BakeCard {
            VStack(alignment: .leading, spacing: BakeSpace.s3) {
                HStack(alignment: .top, spacing: BakeSpace.s2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.orderId)
                            .font(BakeFont.mono)
                            .foregroundStyle(BakeColor.wood)
                        if let order {
                            Text(order.customer)
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                        }
                    }
                    Spacer(minLength: 0)
                    Badge(text: Labels.outcome(record.outcome), tone: Labels.outcomeTone(record.outcome), dot: true)
                }

                HStack(alignment: .top, spacing: BakeSpace.s4) {
                    metric("ตรวจสอบเมื่อ", BakeFormat.dateTime(record.scannedAt), footnote: record.verifiedAt.map { "ยืนยัน \(BakeFormat.date($0))" })
                    metric("จำนวนสินค้า", "\(totalQty) ชิ้น", footnote: "\(record.lines.count) รายการ")
                    metric("ไม่ตรง", "\(mismatches)", color: mismatches > 0 ? BakeColor.errorStrong : BakeColor.muted)
                }

                HStack(spacing: BakeSpace.s2) {
                    if record.corrected {
                        Badge(text: "มีการแก้ไข", tone: .warning)
                    }
                    Badge(text: Labels.handover(order?.handover ?? .blocked), tone: Labels.handoverTone(order?.handover ?? .blocked))
                    Spacer(minLength: 0)
                }

                BakeButton(title: "รายละเอียด", variant: .ghost, size: .small, block: true) {
                    selectedRecord = IdentifiedID(id: record.id)
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String, color: Color = BakeColor.text, footnote: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.muted)
            Text(value)
                .font(BakeFont.smallStrong)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let footnote {
                Text(footnote)
                    .font(BakeFont.tiny)
                    .foregroundStyle(BakeColor.dune)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
