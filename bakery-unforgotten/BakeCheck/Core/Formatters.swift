//
//  Formatters.swift
//  BakeCheck
//
//  Locale-aware Thai formatting helpers.
//  Mirrors web `utils/format.ts`, including the Buddhist-era year used by
//  `Intl.DateTimeFormat('th-TH')`.
//

import Foundation

enum BakeFormat {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "th_TH")
        f.calendar = Calendar(identifier: .buddhist)
        f.timeZone = .current
        f.dateFormat = format
        return f
    }

    private static let timeFmt = formatter("HH:mm")
    private static let dateFmt = formatter("d MMM yyyy")
    private static let dateTimeFmt = formatter("d MMM yyyy HH:mm")
    private static let fullDateFmt = formatter("EEEE'ที่' d MMMM yyyy")

    static func time(_ date: Date) -> String { timeFmt.string(from: date) }

    static func date(_ date: Date) -> String { dateFmt.string(from: date) }

    static func dateTime(_ date: Date) -> String { dateTimeFmt.string(from: date) }

    /// e.g. "วันอาทิตย์ที่ 18 ตุลาคม 2569"
    static func fullDate(_ date: Date) -> String { fullDateFmt.string(from: date) }

    /// Human, Thai-language relative time.
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let diff = now.timeIntervalSince(date)
        let minutes = Int((diff / 60).rounded())

        if minutes < 0 { return "กำลังจะถึง" }
        if minutes < 1 { return "เมื่อสักครู่" }
        if minutes < 60 { return "\(minutes) นาทีที่แล้ว" }

        let hours = Int((Double(minutes) / 60).rounded())
        if hours < 24 { return "\(hours) ชั่วโมงที่แล้ว" }

        let days = Int((Double(hours) / 24).rounded())
        if days == 1 { return "เมื่อวาน" }
        if days < 7 { return "\(days) วันก่อน" }
        return dateFmt.string(from: date)
    }

    static func qty(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value) ชิ้น"
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }

    /// `+2` / `-1` / `0` / `—`
    static func signed(_ value: Int?) -> String {
        guard let value else { return "—" }
        if value == 0 { return "0" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}

/// Short Thai sentence describing a comparison result.
nonisolated enum Labels {
    static func orderStatus(_ status: OrderStatus) -> String {
        switch status {
        case .pending: "รอตรวจสอบ"
        case .verifying: "กำลังตรวจสอบ"
        case .review: "ต้องตรวจสอบเพิ่มเติม"
        case .mismatch: "พบข้อผิดพลาด"
        case .passed: "ตรวจสอบผ่าน"
        case .handedOver: "ส่งมอบแล้ว"
        }
    }

    /// Display label; a verified order awaiting handover reads "พร้อมส่งมอบ".
    static func orderStatus(_ order: Order) -> String {
        if order.status == .passed && order.handover == .ready { return "พร้อมส่งมอบ" }
        return orderStatus(order.status)
    }

    static func orderTone(_ order: Order) -> BadgeTone {
        if order.status == .passed { return .success }
        switch order.status {
        case .pending: return .neutral
        case .verifying: return .info
        case .review: return .warning
        case .mismatch: return .error
        case .handedOver: return .brand
        case .passed: return .success
        }
    }

    static func handover(_ status: HandoverStatus) -> String {
        switch status {
        case .blocked: "ยังส่งมอบไม่ได้"
        case .ready: "พร้อมส่งมอบ"
        case .handedOver: "ส่งมอบแล้ว"
        }
    }

    static func handoverTone(_ status: HandoverStatus) -> BadgeTone {
        switch status {
        case .blocked: .neutral
        case .ready: .success
        case .handedOver: .brand
        }
    }

    static func itemStatus(_ status: ItemStatus) -> String {
        switch status {
        case .pending: "รอผล"
        case .match: "ตรงกัน"
        case .missing: "ขาด"
        case .extra: "เกิน"
        case .uncertain: "ไม่แน่ชัด"
        }
    }

    static func itemTone(_ status: ItemStatus) -> BadgeTone {
        switch status {
        case .match: .success
        case .missing, .extra: .error
        case .uncertain: .warning
        case .pending: .neutral
        }
    }

    static func comparison(_ status: ItemStatus, difference: Int?) -> String {
        switch status {
        case .match: "ตรงกัน"
        case .missing: "ขาด \(abs(difference ?? 0)) ชิ้น"
        case .extra: "เกิน \(difference ?? 0) ชิ้น"
        case .uncertain: "ต้องตรวจสอบ"
        case .pending: "รอผล"
        }
    }

    static func outcome(_ outcome: ScanOutcome) -> String {
        switch outcome {
        case .passed: "ตรวจสอบผ่าน"
        case .mismatch: "พบข้อผิดพลาด"
        case .uncertain: "ต้องตรวจสอบเพิ่มเติม"
        }
    }

    static func outcomeTone(_ outcome: ScanOutcome) -> BadgeTone {
        switch outcome {
        case .passed: .success
        case .mismatch: .error
        case .uncertain: .warning
        }
    }
}
