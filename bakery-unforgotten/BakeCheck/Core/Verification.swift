//
//  Verification.swift
//  BakeCheck
//
//  Verification logic.
//
//  Deliberately independent from the scanning mechanism (see Scanner.swift) so
//  a real computer-vision service can be plugged in without touching these
//  business rules.
//

import Foundation

/// One row of the expected-vs-detected comparison for a product.
struct ComparisonRow: Identifiable, Hashable {
    let productId: String
    let expectedQty: Int
    let detectedQty: Int?
    let manualQty: Int?
    let effectiveQty: Int?
    /// effective - expected (nil when effective is unknown).
    let difference: Int?
    let status: ItemStatus
    let confidence: Double?
    /// True when a staff correction changed the detected value.
    let corrected: Bool

    var id: String { productId }
}

nonisolated struct ComparisonSummary: Hashable {
    var totalExpected = 0
    var totalEffective = 0
    var missing = 0
    var extra = 0
    var uncertain = 0
    var corrected = 0
    var matched = 0
}

nonisolated enum Verification {
    /// The quantity that should be compared: a staff correction wins over detection.
    static func effectiveQty(_ line: ScanLine) -> Int? { line.manualQty ?? line.detectedQty }

    /// Classify a single product against its expected quantity.
    static func classify(expected: Int, effective: Int?) -> ItemStatus {
        guard let effective else { return .uncertain }
        if effective == expected { return .match }
        if effective < expected { return .missing }
        return .extra
    }

    /// Build the full per-product comparison for an order + draft.
    static func compare(order: Order, draft: ScanDraft) -> [ComparisonRow] {
        order.items.map { item in
            let line = draft.lines.first { $0.productId == item.productId }
            let detectedQty = line?.detectedQty
            let manualQty = line?.manualQty
            let effective = manualQty ?? detectedQty
            let corrected = manualQty != nil && manualQty != detectedQty

            return ComparisonRow(
                productId: item.productId,
                expectedQty: item.expectedQty,
                detectedQty: detectedQty,
                manualQty: manualQty,
                effectiveQty: effective,
                difference: effective.map { $0 - item.expectedQty },
                status: classify(expected: item.expectedQty, effective: effective),
                confidence: line?.confidence,
                corrected: corrected
            )
        }
    }

    /// Overall outcome.
    ///
    /// An uncertain line always wins over a mismatch, because it must be
    /// reviewed by a human before a decision can be made.
    static func outcome(rows: [ComparisonRow]) -> ScanOutcome {
        if rows.isEmpty { return .uncertain }
        if rows.contains(where: { $0.status == .uncertain }) { return .uncertain }
        if rows.contains(where: { $0.status == .missing || $0.status == .extra }) { return .mismatch }
        return .passed
    }

    /// An order may only be confirmed when every product matches exactly.
    static func isVerifiable(rows: [ComparisonRow]) -> Bool {
        outcome(rows: rows) == .passed
    }

    static func recordLines(rows: [ComparisonRow]) -> [ScanRecordLine] {
        rows.map { row in
            ScanRecordLine(
                productId: row.productId,
                expectedQty: row.expectedQty,
                effectiveQty: row.effectiveQty,
                status: row.status,
                corrected: row.corrected
            )
        }
    }

    static func summarize(rows: [ComparisonRow]) -> ComparisonSummary {
        rows.reduce(into: ComparisonSummary()) { acc, row in
            acc.totalExpected += row.expectedQty
            acc.totalEffective += row.effectiveQty ?? 0
            if row.status == .missing { acc.missing += abs(row.difference ?? 0) }
            if row.status == .extra { acc.extra += row.difference ?? 0 }
            if row.status == .uncertain { acc.uncertain += 1 }
            if row.status == .match { acc.matched += 1 }
            if row.corrected { acc.corrected += 1 }
        }
    }

    /// Derives rows from a committed record (history view).
    static func rows(from record: ScanRecord) -> [ComparisonRow] {
        record.lines.map { line in
            let difference = line.effectiveQty.map { $0 - line.expectedQty }
            return ComparisonRow(
                productId: line.productId,
                expectedQty: line.expectedQty,
                detectedQty: line.effectiveQty,
                manualQty: line.corrected ? line.effectiveQty : nil,
                effectiveQty: line.effectiveQty,
                difference: difference,
                status: line.status,
                confidence: nil,
                corrected: line.corrected
            )
        }
    }
}

nonisolated enum OrderMath {
    static func totalQty(_ order: Order) -> Int {
        order.items.reduce(0) { $0 + $1.expectedQty }
    }

    /// Orders that still need packing verification work.
    static func needsVerification(_ order: Order) -> Bool {
        switch order.status {
        case .pending, .verifying, .mismatch, .review: true
        case .passed, .handedOver: false
        }
    }
}
