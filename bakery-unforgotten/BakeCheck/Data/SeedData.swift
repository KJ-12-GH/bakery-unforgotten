//
//  SeedData.swift
//  BakeCheck
//
//  Mock catalogue / order book / verification history.
//  Times are relative to first launch so the dashboard always looks "live".
//

import Foundation

enum SeedData {
    // MARK: - Catalogue

    static let products: [Product] = [
        Product(id: "croissant", name: "ครัวซองต์", nameEn: "Croissant", emoji: "🥐"),
        Product(id: "milk-bread", name: "ขนมปังนมสด", nameEn: "Fresh Milk Bread", emoji: "🍞"),
        Product(id: "choc-bread", name: "ขนมปังช็อกโกแลต", nameEn: "Chocolate Bread", emoji: "🍫"),
        Product(id: "donut", name: "โดนัท", nameEn: "Donut", emoji: "🍩"),
        Product(id: "almond-croissant", name: "ครัวซองต์อัลมอนด์", nameEn: "Almond Croissant", emoji: "🥐"),
        Product(id: "walnut-bread", name: "ขนมปังวอลนัท", nameEn: "Walnut Bread", emoji: "🌰"),
        Product(id: "butter-cake", name: "เค้กเนยสด", nameEn: "Butter Cake", emoji: "🍰"),
        Product(id: "mochi-bread", name: "ขนมปังโมจิ", nameEn: "Mochi Bread", emoji: "🍡"),
    ]

    static func product(_ id: String) -> Product {
        products.first { $0.id == id }
            ?? Product(id: id, name: id, nameEn: id, emoji: "🍞")
    }

    // MARK: - Staff

    /// Sample signed-in staff member (prototype only — no real authentication).
    static let staff = Staff(
        name: "ณัฐนนท์ รัตนโชติ",
        role: "พนักงานตรวจสอบออเดอร์",
        initials: "ณร",
        store: "ครัวอบอุ่น เบเกอรี่"
    )

    static let defaultSettings = AppSettings(
        storeName: "ครัวอบอุ่น เบเกอรี่",
        language: .th,
        notifyMismatch: true,
        notifyHandover: true,
        notifyDailySummary: false,
        autoAdvance: true
    )

    /// Sample delivery drivers available for handover.
    static let drivers: [String] = ["พี่สมพงษ์", "พี่วิชัย", "พี่อาร์ต", "พี่นัท"]

    // MARK: - Time anchors

    private static func minutesAgo(_ minutes: Double, from now: Date) -> Date {
        now.addingTimeInterval(-minutes * 60)
    }

    private static func hoursAgo(_ hours: Double, from now: Date) -> Date {
        minutesAgo(hours * 60, from: now)
    }

    private static func daysAgo(_ days: Double, from now: Date) -> Date {
        hoursAgo(days * 24, from: now)
    }

    // MARK: - Orders

    private struct OrderSeed {
        let id: String
        let customer: String
        let createdAt: Date
        let updatedAt: Date
        let status: OrderStatus
        var handover: HandoverStatus = .blocked
        var verifiedAt: Date? = nil
        var handedOverAt: Date? = nil
        var driver: String? = nil
        let items: [OrderItem]
    }

    private static func item(_ productId: String, _ qty: Int) -> OrderItem {
        OrderItem(productId: productId, expectedQty: qty)
    }

    static func initialOrders(now: Date = Date()) -> [Order] {
        let seeds: [OrderSeed] = [
            OrderSeed(
                id: "BK-1001",
                customer: "ร้านกาแฟบ้านสวน",
                createdAt: minutesAgo(42, from: now),
                updatedAt: minutesAgo(12, from: now),
                status: .pending,
                items: [item("croissant", 4), item("milk-bread", 3), item("donut", 2)]
            ),
            OrderSeed(
                id: "BK-1002",
                customer: "คุณมานะ ใจดี",
                createdAt: minutesAgo(33, from: now),
                updatedAt: minutesAgo(30, from: now),
                status: .pending,
                items: [item("choc-bread", 6), item("almond-croissant", 2)]
            ),
            OrderSeed(
                id: "BK-1003",
                customer: "ร้านขนมปังปิ้งสุขใจ",
                createdAt: minutesAgo(26, from: now),
                updatedAt: minutesAgo(24, from: now),
                status: .pending,
                items: [item("donut", 12), item("mochi-bread", 4), item("butter-cake", 2)]
            ),
            OrderSeed(
                id: "BK-1004",
                customer: "บริษัทอรุณเบเกอรี่ จำกัด",
                createdAt: minutesAgo(18, from: now),
                updatedAt: minutesAgo(15, from: now),
                status: .pending,
                items: [
                    item("croissant", 6), item("milk-bread", 6),
                    item("choc-bread", 4), item("donut", 3),
                ]
            ),
            OrderSeed(
                id: "BK-1005",
                customer: "คุณปิยะ ศรีสุข",
                createdAt: minutesAgo(58, from: now),
                updatedAt: minutesAgo(9, from: now),
                status: .verifying,
                items: [item("walnut-bread", 5), item("butter-cake", 3)]
            ),
            OrderSeed(
                id: "BK-1006",
                customer: "ร้านกาแฟบ้านสวน",
                createdAt: hoursAgo(2, from: now),
                updatedAt: minutesAgo(22, from: now),
                status: .passed,
                handover: .ready,
                verifiedAt: minutesAgo(22, from: now),
                items: [item("croissant", 8), item("donut", 4)]
            ),
            OrderSeed(
                id: "BK-1007",
                customer: "คุณสมชาย ตั้งใจ",
                createdAt: minutesAgo(80, from: now),
                updatedAt: minutesAgo(35, from: now),
                status: .mismatch,
                items: [item("milk-bread", 10), item("choc-bread", 2)]
            ),
            OrderSeed(
                id: "BK-1008",
                customer: "ร้านขนมอบเช้า",
                createdAt: hoursAgo(4, from: now),
                updatedAt: hoursAgo(2.5, from: now),
                status: .handedOver,
                handover: .handedOver,
                verifiedAt: hoursAgo(3, from: now),
                handedOverAt: hoursAgo(2.5, from: now),
                driver: "พี่สมพงษ์",
                items: [item("croissant", 3), item("butter-cake", 1)]
            ),
            OrderSeed(
                id: "BK-1009",
                customer: "คุณนภา พรหมมา",
                createdAt: hoursAgo(6, from: now),
                updatedAt: hoursAgo(5, from: now),
                status: .handedOver,
                handover: .handedOver,
                verifiedAt: hoursAgo(5.17, from: now),
                handedOverAt: hoursAgo(5, from: now),
                driver: "พี่วิชัย",
                items: [item("donut", 6), item("mochi-bread", 2), item("choc-bread", 3)]
            ),
            OrderSeed(
                id: "BK-1010",
                customer: "ร้านกาแฟบ้านสวน",
                createdAt: daysAgo(1.08, from: now),
                updatedAt: daysAgo(1, from: now),
                status: .handedOver,
                handover: .handedOver,
                verifiedAt: daysAgo(1.04, from: now),
                handedOverAt: daysAgo(1, from: now),
                driver: "พี่สมพงษ์",
                items: [item("almond-croissant", 4), item("walnut-bread", 2)]
            ),
            OrderSeed(
                id: "BK-1011",
                customer: "คุณธนา รักดี",
                createdAt: daysAgo(1.25, from: now),
                updatedAt: daysAgo(1.17, from: now),
                status: .handedOver,
                handover: .handedOver,
                verifiedAt: daysAgo(1.21, from: now),
                handedOverAt: daysAgo(1.17, from: now),
                driver: "พี่อาร์ต",
                items: [item("croissant", 5), item("milk-bread", 2)]
            ),
        ]

        return seeds.map { seed in
            Order(
                id: seed.id,
                customer: seed.customer,
                items: seed.items,
                createdAt: seed.createdAt,
                updatedAt: seed.updatedAt,
                status: seed.status,
                handover: seed.handover,
                verifiedAt: seed.verifiedAt,
                handedOverAt: seed.handedOverAt,
                driver: seed.driver
            )
        }
    }

    // MARK: - Verification history

    private struct LineSeed {
        let productId: String
        let expected: Int
        /// The quantity the comparison finally used (detection or correction).
        let effective: Int?
        var corrected = false
    }

    private struct RecordSeed {
        let id: String
        let orderId: String
        let scannedAt: Date
        let verifiedAt: Date
        let lines: [LineSeed]
    }

    static func initialScans(now: Date = Date()) -> [ScanRecord] {
        let seeds: [RecordSeed] = [
            RecordSeed(
                id: "BC-2001", orderId: "BK-1006",
                scannedAt: minutesAgo(28, from: now), verifiedAt: minutesAgo(22, from: now),
                lines: [
                    LineSeed(productId: "croissant", expected: 8, effective: 8),
                    LineSeed(productId: "donut", expected: 4, effective: 4),
                ]
            ),
            RecordSeed(
                id: "BC-2002", orderId: "BK-1007",
                scannedAt: minutesAgo(38, from: now), verifiedAt: minutesAgo(35, from: now),
                lines: [
                    LineSeed(productId: "milk-bread", expected: 10, effective: 8),
                    LineSeed(productId: "choc-bread", expected: 2, effective: 2),
                ]
            ),
            RecordSeed(
                id: "BC-2003", orderId: "BK-1008",
                scannedAt: hoursAgo(3.1, from: now), verifiedAt: hoursAgo(3, from: now),
                lines: [
                    LineSeed(productId: "croissant", expected: 3, effective: 3),
                    LineSeed(productId: "butter-cake", expected: 1, effective: 1),
                ]
            ),
            RecordSeed(
                id: "BC-2004", orderId: "BK-1009",
                scannedAt: hoursAgo(5.25, from: now), verifiedAt: hoursAgo(5.17, from: now),
                lines: [
                    LineSeed(productId: "donut", expected: 6, effective: 6),
                    LineSeed(productId: "mochi-bread", expected: 2, effective: 2),
                    LineSeed(productId: "choc-bread", expected: 3, effective: 3),
                ]
            ),
            RecordSeed(
                id: "BC-2005", orderId: "BK-1010",
                scannedAt: daysAgo(1.05, from: now), verifiedAt: daysAgo(1.04, from: now),
                lines: [
                    LineSeed(productId: "almond-croissant", expected: 4, effective: 4),
                    LineSeed(productId: "walnut-bread", expected: 2, effective: 2),
                ]
            ),
            // Verified after a staff correction (detected 4 → corrected to 5).
            RecordSeed(
                id: "BC-2006", orderId: "BK-1011",
                scannedAt: daysAgo(1.22, from: now), verifiedAt: daysAgo(1.21, from: now),
                lines: [
                    LineSeed(productId: "croissant", expected: 5, effective: 5, corrected: true),
                    LineSeed(productId: "milk-bread", expected: 2, effective: 2),
                ]
            ),
        ]

        return seeds.map { seed in
            let lines = seed.lines.map { line in
                ScanRecordLine(
                    productId: line.productId,
                    expectedQty: line.expected,
                    effectiveQty: line.effective,
                    status: Verification.classify(expected: line.expected, effective: line.effective),
                    corrected: line.corrected
                )
            }
            let outcome: ScanOutcome
            if lines.contains(where: { $0.status == .uncertain }) {
                outcome = .uncertain
            } else if lines.contains(where: { $0.status == .missing || $0.status == .extra }) {
                outcome = .mismatch
            } else {
                outcome = .passed
            }

            return ScanRecord(
                id: seed.id,
                orderId: seed.orderId,
                scannedAt: seed.scannedAt,
                verifiedAt: seed.verifiedAt,
                outcome: outcome,
                corrected: lines.contains { $0.corrected },
                lines: lines
            )
        }
    }
}
