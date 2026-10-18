//
//  main.swift
//  BakeCheck — business-rule check
//
//  Compiles the app's real Core/Data/State sources (no re-implementation) and
//  exercises the verification rules end to end. Run with:
//
//    ./ios-scripts/logic-check.sh
//
//  Nothing here ships inside the app bundle; this folder lives outside the
//  folder Xcode synchronises.
//

import Foundation

// MARK: - Tiny assertion harness (file scope so helpers stay reusable)

var passed = 0
var failed = 0

func group(_ title: String) {
    print("\n▸ \(title)")
}

func check(_ condition: Bool, _ label: String, _ detail: String = "") {
    if condition {
        passed += 1
        print("   ✓ \(label)")
    } else {
        failed += 1
        print("   ✗ \(label)\(detail.isEmpty ? "" : " — \(detail)")")
    }
}

func equal<T: Equatable>(_ actual: T, _ expected: T, _ label: String) {
    check(actual == expected, label, "ได้ \(actual) คาดว่า \(expected)")
}

/// Plain line helpers (the app's `LineSeed` types are private).
func line(_ productId: String, detected: Int?, manual: Int? = nil, confidence: Double? = 0.9) -> ScanLine {
    ScanLine(productId: productId, detectedQty: detected, confidence: confidence, manualQty: manual)
}

func draft(_ orderId: String, _ lines: [ScanLine]) -> ScanDraft {
    ScanDraft(orderId: orderId, scannedAt: Date(), lines: lines)
}

func order(_ id: String, _ items: [(String, Int)]) -> Order {
    Order(
        id: id,
        customer: "ทดสอบ",
        items: items.map { OrderItem(productId: $0.0, expectedQty: $0.1) },
        createdAt: Date(),
        updatedAt: Date(),
        status: .pending,
        handover: .blocked,
        verifiedAt: nil,
        handedOverAt: nil,
        driver: nil
    )
}

// MARK: - Checks

@main
struct LogicCheck {
    @MainActor
    static func main() {

// MARK: - 1. Classification

group("การจำแนกผลรายสินค้า (classify / effectiveQty)")
equal(Verification.classify(expected: 4, effective: nil), .uncertain, "ตรวจไม่พบจำนวน → ไม่แน่ชัด")
equal(Verification.classify(expected: 4, effective: 4), .match, "เท่ากับที่สั่ง → ตรงกัน")
equal(Verification.classify(expected: 4, effective: 3), .missing, "น้อยกว่าที่สั่ง → ขาด")
equal(Verification.classify(expected: 4, effective: 5), .extra, "มากกว่าที่สั่ง → เกิน")
equal(Verification.classify(expected: 0, effective: 0), .match, "ศูนย์เท่ากับศูนย์ → ตรงกัน")

equal(Verification.effectiveQty(line("croissant", detected: 4, manual: nil)), 4, "ใช้ค่าที่ตรวจจับได้เมื่อไม่มีการแก้ไข")
equal(Verification.effectiveQty(line("croissant", detected: 2, manual: 3)), 3, "ค่าที่พนักงานแก้ไขชนะค่าที่ตรวจจับได้")
equal(Verification.effectiveQty(line("croissant", detected: nil, manual: 5)), 5, "แก้ไขได้แม้ระบบตรวจไม่พบ")

// MARK: - 2. Comparison rows

group("การเปรียบเทียบทั้งออเดอร์ (compare)")
let orderA = order("T-1", [("croissant", 4), ("milk-bread", 3), ("donut", 2)])
let rowsA = Verification.compare(
    order: orderA,
    draft: draft("T-1", [
        line("croissant", detected: 4),
        line("milk-bread", detected: 2),
        line("donut", detected: nil),
    ])
)
equal(rowsA.count, 3, "สร้างผลเปรียบเทียบครบทุกรายการในออเดอร์")
equal(rowsA[0].status, .match, "ครัวซองต์ 4/4 → ตรงกัน")
equal(rowsA[1].status, .missing, "ขนมปังนมสด 3/2 → ขาด")
equal(rowsA[1].difference, -1, "ส่วนต่าง = -1")
equal(rowsA[2].status, .uncertain, "โดนัทตรวจไม่พบ → ไม่แน่ชัด")
equal(rowsA[2].difference, nil, "ส่วนต่างเป็น nil เมื่อไม่ทราบจำนวน")

let correctedRows = Verification.compare(
    order: orderA,
    draft: draft("T-1", [
        line("croissant", detected: 4),
        line("milk-bread", detected: 2, manual: 3),
        line("donut", detected: 2),
    ])
)
equal(correctedRows[1].status, .match, "หลังพนักงานแก้ไขเป็น 3 → ตรงกัน")
check(correctedRows[1].corrected, "ตั้งค่าธงว่าแก้ไขโดยพนักงาน")
check(!correctedRows[0].corrected, "รายการที่ไม่ถูกแก้ไขไม่ติดธง")

let revertRows = Verification.compare(
    order: orderA,
    draft: draft("T-1", [
        line("croissant", detected: 4),
        line("milk-bread", detected: 2, manual: 2),
        line("donut", detected: 2),
    ])
)
check(!revertRows[1].corrected, "แก้ไขให้เท่ากับค่าที่ตรวจพบ = ไม่ถือว่าแก้ไข")

// MARK: - 3. Outcome + gating

group("ผลรวมและการอนุญาตให้ยืนยัน (outcome / isVerifiable)")
equal(Verification.outcome(rows: rowsA), .uncertain, "มีรายการที่ต้องตรวจสอบเอง → ไม่แน่ชัด ชนะ mismatch")
equal(
    Verification.outcome(rows: Verification.compare(
        order: orderA,
        draft: draft("T-1", [line("croissant", detected: 4), line("milk-bread", detected: 1), line("donut", detected: 2)])
    )),
    .mismatch,
    "มีรายการขาด/เกิน → พบข้อผิดพลาด"
)
equal(
    Verification.outcome(rows: Verification.compare(
        order: orderA,
        draft: draft("T-1", [line("croissant", detected: 4), line("milk-bread", detected: 3), line("donut", detected: 3)])
    )),
    .mismatch,
    "มีรายการเกิน → พบข้อผิดพลาด"
)
equal(
    Verification.outcome(rows: Verification.compare(
        order: orderA,
        draft: draft("T-1", [line("croissant", detected: 4), line("milk-bread", detected: 3), line("donut", detected: 2)])
    )),
    .passed,
    "ตรงทุกรายการ → ตรวจสอบผ่าน"
)
equal(Verification.outcome(rows: []), .uncertain, "ยังไม่มีข้อมูล → ยังไม่ผ่าน")

check(!Verification.isVerifiable(rows: rowsA), "ยืนยันผลไม่ได้เมื่อยังมีรายการไม่ตรง/ไม่แน่ชัด")
check(
    Verification.isVerifiable(rows: correctedRows),
    "ยืนยันผลได้หลังพนักงานแก้ไขจนครบทุกอย่าง"
)

// MARK: - 4. Summary

group("สรุปตัวเลข (summarize)")
let summaryA = Verification.summarize(rows: rowsA)
equal(summaryA.totalExpected, 9, "จำนวนที่สั่งรวม 9 ชิ้น")
equal(summaryA.totalEffective, 6, "จำนวนที่นับได้รวม 6 ชิ้น")
equal(summaryA.missing, 1, "นับจำนวนที่ขาดได้ 1 ชิ้น")
equal(summaryA.extra, 0, "ไม่มีจำนวนเกิน")
equal(summaryA.uncertain, 1, "มี 1 รายการที่ต้องตรวจสอบเอง")
equal(summaryA.matched, 1, "มี 1 รายการที่ตรงกัน")
equal(summaryA.corrected, 0, "ยังไม่มีการแก้ไข")

let summaryB = Verification.summarize(rows: correctedRows)
equal(summaryB.corrected, 1, "สรุปนับจำนวนรายการที่พนักงานแก้ไข")
equal(summaryB.missing, 0, "หลังแก้ไขไม่มีรายการขาด")

// MARK: - 5. Simulated detector profiles

group("ผลการตรวจจับจำลอง (ScanService)")
let simulatedOutcome: (String) -> ScanOutcome = { id in
    guard let order = SeedData.initialOrders().first(where: { $0.id == id }) else { return .uncertain }
    let lines = ScanService.simulate(order: order)
    let rows = Verification.compare(order: order, draft: draft(id, lines))
    return Verification.outcome(rows: rows)
}
equal(simulatedOutcome("BK-1001"), .mismatch, "BK-1001 → ขาดขนมปังนมสด 1 ชิ้น (พบข้อผิดพลาด)")
equal(simulatedOutcome("BK-1002"), .passed, "BK-1002 → ตรงทุกรายการ (ตรวจสอบผ่าน)")
equal(simulatedOutcome("BK-1003"), .uncertain, "BK-1003 → มีรายการไม่แน่ชัด + โดนัทเกิน")
equal(simulatedOutcome("BK-1004"), .passed, "BK-1004 → ตรงทุกรายการ (ตรวจสอบผ่าน)")
equal(simulatedOutcome("BK-1005"), .mismatch, "BK-1005 → เค้กเนยสดเกิน 1 ชิ้น")

let unknownOrder = order("BK-9999", [("croissant", 2)])
let unknownLines = ScanService.simulate(order: unknownOrder)
equal(unknownLines.first?.detectedQty, 2, "ออเดอร์ที่ไม่มีโปรไฟล์จำลอง → ถือว่าตรงกับที่สั่ง")
equal(unknownLines.first?.manualQty, nil, "ผลจำลองไม่ตั้งค่าแก้ไขโดยพนักงาน")
equal(unknownLines.first?.confidence ?? 0, 0.95, "ใช้ค่าความมั่นใจมาตรฐาน 0.95")

// MARK: - 6. Seed data integrity

group("ความถูกต้องของข้อมูลตัวอย่าง")
let seedOrders = SeedData.initialOrders()
equal(seedOrders.count, 11, "มีออเดอร์ตัวอย่าง 11 รายการ")
equal(Set(seedOrders.map(\.id)).count, seedOrders.count, "รหัสออเดอร์ไม่ซ้ำกัน")
check(
    seedOrders.allSatisfy { order in
        order.items.allSatisfy { !SeedData.product($0.productId).nameEn.isEmpty && SeedData.product($0.productId).id == $0.productId }
    },
    "ทุกรายการในออเดอร์อ้างถึงสินค้าที่มีอยู่ในแค็ตตาล็อก"
)
check(
    seedOrders.filter { $0.handover == .handedOver }.allSatisfy { $0.driver != nil && $0.handedOverAt != nil },
    "ออเดอร์ที่ส่งมอบแล้วมีชื่อพนักงานขับรถและเวลาส่งมอบ"
)
check(
    seedOrders.allSatisfy { $0.status == .handedOver ? $0.handover == .handedOver : true },
    "สถานะ handed_over สอดคล้องกับสถานะการส่งมอบ"
)

let seedScans = SeedData.initialScans()
equal(seedScans.count, 6, "มีบันทึกการตรวจสอบตัวอย่าง 6 รายการ")
check(
    seedScans.allSatisfy { record in
        record.lines.allSatisfy { $0.status == Verification.classify(expected: $0.expectedQty, effective: $0.effectiveQty) }
    },
    "สถานะในทุกรายการของบันทึกตรงกับกฎการจำแนก"
)
check(
    seedScans.allSatisfy { record in
        let rows = record.lines.map {
            ComparisonRow(
                productId: $0.productId, expectedQty: $0.expectedQty,
                detectedQty: $0.effectiveQty, manualQty: nil,
                effectiveQty: $0.effectiveQty, difference: nil,
                status: $0.status, confidence: nil, corrected: $0.corrected
            )
        }
        return record.outcome == Verification.outcome(rows: rows)
    },
    "ผลรวมของบันทึกตรงกับผลรวมที่คำนวณใหม่"
)
check(seedScans.contains { $0.corrected }, "มีบันทึกตัวอย่างที่เกิดหลังพนักงานแก้ไขจำนวน")

// MARK: - 7. Store: real business rules end to end

group("กฎทางธุรกิจผ่าน store จริง (AppStore)")
UserDefaults.standard.removeObject(forKey: "bakecheck.state.v1")
let store = AppStore()

equal(store.orders.count, 11, "โหลดออเดอร์ตัวอย่างเมื่อเริ่มระบบ")
equal(store.order("BK-1001")?.status, .pending, "BK-1001 เริ่มต้นที่สถานะรอตรวจสอบ")

// An unscanned order cannot be confirmed.
check(!store.confirmVerification(orderId: "BK-1001"), "ยืนยันผลไม่ได้ถ้ายังไม่สแกน")

// Scanning a mismatched order blocks confirmation.
let bk1001 = store.order("BK-1001")!
store.recordScan(orderId: "BK-1001", lines: ScanService.simulate(order: bk1001))
equal(store.order("BK-1001")?.status, .mismatch, "สแกนแล้วพบข้อผิดพลาด → สถานะเป็น mismatch")
check(!store.confirmVerification(orderId: "BK-1001"), "ยืนยันผลไม่ได้ขณะยังมีจำนวนไม่ตรง")
check(!store.handOver(orderId: "BK-1001", driver: "พี่สมพงษ์"), "ส่งมอบไม่ได้ถ้ายังไม่ผ่านการตรวจสอบ")

// A staff correction re-runs the comparison immediately.
store.setManualQty(orderId: "BK-1001", productId: "milk-bread", qty: 3)
equal(store.orders.first { $0.id == "BK-1001" }?.status, .verifying, "แก้ไขจำนวนแล้วผลใหม่คือผ่าน (พร้อมยืนยัน)")
check(
    store.comparisons(forOrder: "BK-1001").allSatisfy { $0.status == .match },
    "ทุกรายการตรงกันหลังการแก้ไข"
)

// Confirming creates exactly one history record and unlocks handover.
let scansBefore = store.scans.count
check(store.confirmVerification(orderId: "BK-1001"), "ยืนยันผลสำเร็จเมื่อทุกรายการตรงกัน")
equal(store.scans.count, scansBefore + 1, "สร้างบันทึกประวัติ 1 รายการ")
equal(store.order("BK-1001")?.status, .passed, "สถานะหลังยืนยันเป็นตรวจสอบผ่าน")
equal(store.order("BK-1001")?.handover, .ready, "สถานะการส่งมอบเป็นพร้อมส่งมอบ")
check(store.drafts["BK-1001"] == nil, "ล้างสถานะการสแกนชั่วคราวหลังยืนยัน")
check(store.latestScan("BK-1001")?.corrected == true, "บันทึกว่าผลนี้มีการแก้ไขโดยพนักงาน")

// An uncertain detection must be reviewed by a human.
let bk1003 = store.order("BK-1003")!
store.recordScan(orderId: "BK-1003", lines: ScanService.simulate(order: bk1003))
equal(store.order("BK-1003")?.status, .review, "ผลไม่แน่ชัด → สถานะต้องตรวจสอบเพิ่มเติม")
check(!store.confirmVerification(orderId: "BK-1003"), "ผลไม่แน่ชัดยืนยันไม่ได้จนกว่าคนจะแก้ไข")

// Handover happens once, and only for a ready order.
check(store.handOver(orderId: "BK-1002", driver: "พี่วิชัย") == false, "ออเดอร์ที่ยังไม่ผ่านยืนยันส่งมอบไม่ได้")
check(store.handOver(orderId: "BK-1001", driver: "พี่สมพงษ์"), "ออเดอร์ที่พร้อมส่งมอบส่งมอบได้")
equal(store.order("BK-1001")?.status, .handedOver, "สถานะหลังส่งมอบเป็นส่งมอบแล้ว")
equal(store.order("BK-1001")?.driver, "พี่สมพงษ์", "บันทึกชื่อพนักงานขับรถ")
check(store.order("BK-1001")?.handedOverAt != nil, "บันทึกเวลาส่งมอบ")
check(!store.handOver(orderId: "BK-1001", driver: "พี่นัท"), "ส่งมอบซ้ำไม่ได้")

// A handed-over order is frozen.
let draftCount = store.drafts.count
store.recordScan(orderId: "BK-1001", lines: [line("croissant", detected: 99)])
equal(store.drafts.count, draftCount, "สแกนออเดอร์ที่ส่งมอบแล้วไม่มีผลใด ๆ")

// Notifications are derived from the same state.
let notifications = NotificationBuilder.build(orders: store.orders)
check(notifications.contains { $0.orderId == "BK-1003" && $0.tone == .warning }, "มีแจ้งเตือนสำหรับออเดอร์ที่ต้องตรวจสอบเพิ่มเติม")
check(notifications.contains { $0.id.hasPrefix("mismatch-") || $0.id.hasPrefix("ready-") }, "มีแจ้งเตือนจากสถานะออเดอร์ปัจจุบัน")
check(notifications.count <= 12, "จำกัดจำนวนการแจ้งเตือนไม่เกิน 12 รายการ")

// Settings round-trip.
store.updateSettings { $0.notifyDailySummary = true; $0.storeName = "ร้านทดสอบ" }
equal(store.settings.notifyDailySummary, true, "บันทึกการตั้งค่าการแจ้งเตือน")
equal(store.settings.storeName, "ร้านทดสอบ", "บันทึกชื่อร้าน")

// Reset restores the demo data.
store.resetDemo()
equal(store.orders.count, 11, "รีเซ็ตแล้วกลับมามีออเดอร์ตัวอย่าง 11 รายการ")
equal(store.scans.count, 6, "รีเซ็ตแล้วกลับมามีประวัติ 6 รายการ")
equal(store.settings.storeName, "ครัวอบอุ่น เบเกอรี่", "รีเซ็ตการตั้งค่ากลับเป็นค่าเริ่มต้น")
equal(store.order("BK-1001")?.status, .pending, "รีเซ็ตสถานะออเดอร์กลับเป็นรอตรวจสอบ")

// MARK: - 8. Labels & formatting

group("ป้ายข้อความและรูปแบบการแสดงผล (Labels / BakeFormat)")
let readyOrder = order("T-2", [("donut", 1)])
var ready = readyOrder
ready.status = .passed
ready.handover = .ready
equal(Labels.orderStatus(ready), "พร้อมส่งมอบ", "ออเดอร์ที่ผ่านและพร้อมส่งมอบแสดงว่า พร้อมส่งมอบ")
var blocked = readyOrder
blocked.status = .passed
blocked.handover = .blocked
equal(Labels.orderStatus(blocked), "ตรวจสอบผ่าน", "ออเดอร์ที่ผ่านแต่ยังไม่พร้อมแสดงว่า ตรวจสอบผ่าน")
equal(Labels.orderStatus(.review), "ต้องตรวจสอบเพิ่มเติม", "ป้ายสถานะต้องตรวจสอบเพิ่มเติม")
equal(Labels.comparison(.missing, difference: -2), "ขาด 2 ชิ้น", "ข้อความอธิบายรายการที่ขาด")
equal(Labels.comparison(.extra, difference: 3), "เกิน 3 ชิ้น", "ข้อความอธิบายรายการที่เกิน")
equal(Labels.itemStatus(.uncertain), "ไม่แน่ชัด", "ป้ายรายการที่ไม่แน่ชัด")
equal(Labels.outcome(.passed), "ตรวจสอบผ่าน", "ป้ายผลรวมที่ผ่าน")

equal(BakeFormat.signed(2), "+2", "แสดงส่วนต่างบวก")
equal(BakeFormat.signed(-1), "-1", "แสดงส่วนต่างลบ")
equal(BakeFormat.signed(0), "0", "แสดงส่วนต่างศูนย์")
equal(BakeFormat.signed(nil), "—", "แสดงขีดเมื่อไม่ทราบส่วนต่าง")
equal(BakeFormat.qty(nil), "—", "แสดงขีดเมื่อไม่ทราบจำนวน")
equal(BakeFormat.percent(0.943), "94%", "ปัดค่าความมั่นใจเป็นเปอร์เซ็นต์")

// MARK: - Summary

print("\n" + String(repeating: "─", count: 56))
if failed == 0 {
    print("ผลการทดสอบ: ผ่าน \(passed) / ไม่ผ่าน 0 ✅")
} else {
    print("ผลการทดสอบ: ผ่าน \(passed) / ไม่ผ่าน \(failed) ❌")
}
print(String(repeating: "─", count: 56))

exit(failed == 0 ? 0 : 1)

    }
}
