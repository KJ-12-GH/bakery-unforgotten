//
//  Models.swift
//  BakeCheck
//
//  Shared domain types. Status values are explicit so business state is never
//  inferred from display labels.
//

import Foundation

// MARK: - Status enums

/// Lifecycle of an order's verification.
enum OrderStatus: String, Codable, Hashable, CaseIterable {
    case pending            // รอตรวจสอบ
    case verifying          // กำลังตรวจสอบ
    case review             // ต้องตรวจสอบเพิ่มเติม (ผลตรวจจับไม่แน่ชัด)
    case mismatch           // พบข้อผิดพลาด
    case passed             // ตรวจสอบผ่าน
    case handedOver = "handed_over"
}

/// Whether an order may be handed to a delivery driver.
enum HandoverStatus: String, Codable, Hashable, CaseIterable {
    case blocked
    case ready
    case handedOver = "handed_over"
}

/// Per-product verification result.
enum ItemStatus: String, Codable, Hashable, CaseIterable {
    case pending
    case match
    case missing
    case extra
    case uncertain
}

/// Overall outcome of a scan.
enum ScanOutcome: String, Codable, Hashable, CaseIterable {
    case passed
    case mismatch
    case uncertain
}

/// Visual tone used by badges, notices and stat cards.
enum BadgeTone: String, Codable, Hashable, CaseIterable {
    case neutral
    case info
    case success
    case warning
    case error
    case brand
}

// MARK: - Catalogue

struct Product: Identifiable, Hashable, Codable {
    let id: String
    /// Thai display name.
    let name: String
    /// Latin name for secondary display.
    let nameEn: String
    let emoji: String
}

// MARK: - Orders

struct OrderItem: Identifiable, Hashable, Codable {
    let productId: String
    let expectedQty: Int

    var id: String { productId }
}

struct Order: Identifiable, Hashable, Codable {
    let id: String
    let customer: String
    let items: [OrderItem]
    var createdAt: Date
    var updatedAt: Date
    var status: OrderStatus
    var handover: HandoverStatus
    var verifiedAt: Date?
    var handedOverAt: Date?
    var driver: String?
}

// MARK: - Scanning

/// One line produced by the scanner for an order.
/// `detectedQty == nil` means the detector could not identify the product
/// confidently, so a staff member must review the line.
struct ScanLine: Hashable, Codable {
    let productId: String
    var detectedQty: Int?
    var confidence: Double?
    /// Staff correction. When set it takes precedence over the detection.
    var manualQty: Int?
}

/// An in-progress packing session for an order.
struct ScanDraft: Hashable, Codable {
    let orderId: String
    var scannedAt: Date
    var lines: [ScanLine]
}

/// A committed verification result, persisted to history.
struct ScanRecordLine: Identifiable, Hashable, Codable {
    let productId: String
    let expectedQty: Int
    let effectiveQty: Int?
    let status: ItemStatus
    let corrected: Bool

    var id: String { productId }
}

struct ScanRecord: Identifiable, Hashable, Codable {
    let id: String
    let orderId: String
    let scannedAt: Date
    var verifiedAt: Date?
    let outcome: ScanOutcome
    let corrected: Bool
    let lines: [ScanRecordLine]
}

// MARK: - People & settings

struct Staff: Hashable {
    let name: String
    let role: String
    let initials: String
    let store: String
}

/// Language of the (Thai-first) prototype UI.
enum AppLanguage: String, Codable, Hashable, CaseIterable {
    case th
    case en

    var title: String {
        switch self {
        case .th: "ไทย (ค่าเริ่มต้น)"
        case .en: "English"
        }
    }
}

struct AppSettings: Hashable, Codable {
    var storeName: String
    var language: AppLanguage
    var notifyMismatch: Bool
    var notifyHandover: Bool
    var notifyDailySummary: Bool
    var autoAdvance: Bool
}

struct NotificationItem: Identifiable, Hashable {
    let id: String
    let orderId: String
    let title: String
    let detail: String
    let tone: BadgeTone
    let at: Date
    /// Notifications that lead straight to the handover screen.
    let opensHandover: Bool
}
