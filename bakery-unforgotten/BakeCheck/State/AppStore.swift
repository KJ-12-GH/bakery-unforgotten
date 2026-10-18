//
//  AppStore.swift
//  BakeCheck
//
//  Single source of truth for orders, verification drafts, history and
//  settings. Every screen reads from here so dashboard metrics can never
//  disagree with the order list.
//
//  Business rules (enforced here, not in the views):
//   • an order cannot be verified while any line is incomplete or mismatched
//   • an uncertain detection always requires a human decision
//   • a mismatch blocks handover
//   • a staff correction re-runs the comparison immediately
//   • an order can only be handed over once, and only after verification
//

import Combine
import Foundation
import SwiftUI

/// Snapshot persisted between launches (mirrors the web `localStorage` blob).
private struct PersistedState: Codable {
    var orders: [Order]
    var scans: [ScanRecord]
    var drafts: [String: ScanDraft]
    var settings: AppSettings
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var orders: [Order] = []
    @Published private(set) var scans: [ScanRecord] = []
    @Published private(set) var drafts: [String: ScanDraft] = [:]
    @Published private(set) var settings: AppSettings = SeedData.defaultSettings

    let staff = SeedData.staff
    let products = SeedData.products

    private static let storageKey = "bakecheck.state.v1"
    private var idCounter = 3000

    init() {
        restore()
    }

    // MARK: - Lookups

    func order(_ id: String) -> Order? {
        orders.first { $0.id == id }
    }

    func draft(_ orderId: String) -> ScanDraft? {
        drafts[orderId]
    }

    func latestScan(_ orderId: String) -> ScanRecord? {
        scans.filter { $0.orderId == orderId }.max { $0.scannedAt < $1.scannedAt }
    }

    func comparisons(forOrder orderId: String) -> [ComparisonRow] {
        guard let order = order(orderId), let draft = drafts[orderId] else { return [] }
        return Verification.compare(order: order, draft: draft)
    }

    var notifications: [NotificationItem] {
        NotificationBuilder.build(orders: orders)
    }

    /// Orders that still need packing verification work.
    var ordersNeedingVerification: [Order] {
        orders.filter(OrderMath.needsVerification)
    }

    // MARK: - Actions

    /// Starts (or restarts) a scan session for an order.
    func recordScan(orderId: String, lines: [ScanLine], at date: Date = Date()) {
        guard let order = order(orderId), order.handover != .handedOver else { return }

        let draft = ScanDraft(orderId: orderId, scannedAt: date, lines: lines)
        drafts[orderId] = draft
        applyStatus(orderId: orderId, rows: Verification.compare(order: order, draft: draft), at: date)
        persist()
    }

    /// Staff correction — re-runs the comparison straight away.
    func setManualQty(orderId: String, productId: String, qty: Int?, at date: Date = Date()) {
        guard let order = order(orderId), var draft = drafts[orderId] else { return }

        draft.lines = draft.lines.map { line in
            guard line.productId == productId else { return line }
            var copy = line
            copy.manualQty = qty
            return copy
        }
        drafts[orderId] = draft
        applyStatus(orderId: orderId, rows: Verification.compare(order: order, draft: draft), at: date)
        persist()
    }

    func clearDraft(orderId: String) {
        guard drafts[orderId] != nil else { return }
        drafts.removeValue(forKey: orderId)
        persist()
    }

    /// Commits the verification. Refuses to run unless every line matches.
    @discardableResult
    func confirmVerification(orderId: String, at date: Date = Date()) -> Bool {
        guard let order = order(orderId),
              let draft = drafts[orderId],
              order.handover != .handedOver
        else { return false }

        let rows = Verification.compare(order: order, draft: draft)
        // Business rule: never verify while a check is incomplete or mismatched.
        guard Verification.isVerifiable(rows: rows) else { return false }

        idCounter += 1
        let record = ScanRecord(
            id: "BC-\(idCounter)",
            orderId: orderId,
            scannedAt: draft.scannedAt,
            verifiedAt: date,
            outcome: .passed,
            corrected: rows.contains { $0.corrected },
            lines: Verification.recordLines(rows: rows)
        )

        scans.insert(record, at: 0)
        drafts.removeValue(forKey: orderId)

        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            orders[index].status = .passed
            orders[index].handover = .ready
            orders[index].verifiedAt = date
            orders[index].updatedAt = date
        }
        persist()
        return true
    }

    /// Hands the order to a driver. Only possible once, and only when ready.
    @discardableResult
    func handOver(orderId: String, driver: String, at date: Date = Date()) -> Bool {
        guard let index = orders.firstIndex(where: { $0.id == orderId }) else { return false }
        // Business rule: only a verified order can be handed over, and only once.
        guard orders[index].status == .passed, orders[index].handover == .ready else { return false }

        orders[index].status = .handedOver
        orders[index].handover = .handedOver
        orders[index].handedOverAt = date
        orders[index].driver = driver
        orders[index].updatedAt = date
        persist()
        return true
    }

    func updateSettings(_ patch: (inout AppSettings) -> Void) {
        var next = settings
        patch(&next)
        settings = next
        persist()
    }

    func resetDemo() {
        let now = Date()
        orders = SeedData.initialOrders(now: now)
        scans = SeedData.initialScans(now: now)
        drafts = [:]
        settings = SeedData.defaultSettings
        idCounter = 3000
        persist()
    }

    // MARK: - Internals

    private func applyStatus(orderId: String, rows: [ComparisonRow], at date: Date) {
        guard let index = orders.firstIndex(where: { $0.id == orderId }) else { return }
        orders[index].status = Self.status(for: Verification.outcome(rows: rows))
        orders[index].updatedAt = date
    }

    /// Order status implied by a scan outcome (before explicit confirmation).
    private static func status(for outcome: ScanOutcome) -> OrderStatus {
        switch outcome {
        case .mismatch: .mismatch
        case .uncertain: .review
        case .passed: .verifying
        }
    }

    private func persist() {
        let snapshot = PersistedState(orders: orders, scans: scans, drafts: drafts, settings: settings)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func restore() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let snapshot = try? JSONDecoder().decode(PersistedState.self, from: data) {
            orders = snapshot.orders
            scans = snapshot.scans
            drafts = snapshot.drafts
            settings = snapshot.settings
            // Keep generated ids ahead of anything already stored.
            let highest = scans
                .compactMap { Int($0.id.split(separator: "-").last ?? "") }
                .max() ?? 3000
            idCounter = max(3000, highest)
            return
        }
        resetDemo()
    }
}
