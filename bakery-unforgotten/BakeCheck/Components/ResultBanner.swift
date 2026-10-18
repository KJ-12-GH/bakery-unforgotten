//
//  ResultBanner.swift
//  BakeCheck
//
//  Headline verdict for a scan outcome.
//

import SwiftUI

struct ResultBanner: View {
    var outcome: ScanOutcome?
    var summary: ComparisonSummary? = nil
    /// True when the order has already been confirmed.
    var verified: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: BakeSpace.s3) {
            Icon(name: symbol, size: 24)
                .foregroundStyle(foreground)
                .padding(9)
                .background(background)
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
        .padding(BakeSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    private var symbol: IconName {
        switch outcome {
        case .none: .scan
        case .passed: .checkCircle
        case .mismatch: .xCircle
        case .uncertain: .alertTriangle
        }
    }

    private var title: String {
        switch outcome {
        case .none: "ยังไม่มีผลการตรวจสอบ"
        case .passed: "ตรวจสอบผ่าน"
        case .mismatch: "พบข้อผิดพลาด"
        case .uncertain: "ต้องตรวจสอบเพิ่มเติม"
        }
    }

    private var message: String {
        switch outcome {
        case .none:
            return "เริ่มสแกนสินค้าเพื่อเทียบจำนวนกับออเดอร์"
        case .passed:
            var text = "จำนวนสินค้าตรงกับออเดอร์ครบทุกรายการ"
            if let summary, summary.corrected > 0 { text += " (มีการแก้ไขโดยพนักงาน)" }
            text += verified ? " · ยืนยันผลแล้ว" : " — กด “ยืนยันผลตรวจสอบ” เพื่อยืนยันก่อนส่งมอบ"
            return text
        case .mismatch:
            var parts: [String] = []
            if let summary, summary.missing > 0 { parts.append("ขาดสินค้า \(summary.missing) ชิ้น") }
            if let summary, summary.extra > 0 { parts.append("เกินสินค้า \(summary.extra) ชิ้น") }
            if parts.isEmpty { parts.append("จำนวนสินค้าไม่ตรงกับออเดอร์") }
            return parts.joined(separator: " · ") + " — กรุณาแก้ไขและตรวจสอบอีกครั้งก่อนส่งมอบ"
        case .uncertain:
            let count = summary?.uncertain ?? 0
            let head = count > 0 ? "\(count) รายการที่ระบบไม่มั่นใจ" : "ระบบไม่มั่นใจในบางรายการ"
            return head + " — กรุณาตรวจสอบด้วยตนเองและระบุจำนวนที่ถูกต้อง"
        }
    }

    private var foreground: Color {
        guard let outcome else { return BakeColor.bark }
        return Labels.outcomeTone(outcome).foreground
    }

    private var background: Color {
        guard let outcome else { return BakeColor.surfaceSunken }
        return Labels.outcomeTone(outcome).background
    }

    private var border: Color {
        guard let outcome else { return BakeColor.border }
        return Labels.outcomeTone(outcome).border
    }
}

/// Four compact tiles (ordered / detected / missing / extra).
struct SummaryStrip: View {
    var tiles: [(String, String, Color)]

    var body: some View {
        HStack(spacing: BakeSpace.s2) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.0)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                    Text(tile.1)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(tile.2)
                }
                .padding(BakeSpace.s3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BakeColor.surfaceSunken)
                .clipShape(RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous))
            }
        }
    }
}
