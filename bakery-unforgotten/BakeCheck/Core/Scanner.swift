//
//  Scanner.swift
//  BakeCheck
//
//  Simulated product detection.
//
//  ⚠️ MOCK: this prototype does NOT run any real AI / computer-vision model.
//  Results are deterministic per order so the demo is repeatable.
//
//  Replace `ScanService.simulate(order:)` with a real CV service call to go
//  live — the rest of the app only depends on the `[ScanLine]` shape it returns.
//

import Foundation

/// One scripted detection for the mock scanner.
struct SimulatedDetection: Hashable {
    /// Detected quantity, or nil when the detection was uncertain.
    let qty: Int?
    /// Mock confidence 0...1 (illustrative only).
    let confidence: Double
}

/// ⚠️ MOCK DETECTION PROFILES — NOT REAL AI.
///
/// Scripted outcomes for the prototype's simulated scanner. `qty: nil` means
/// the (mock) detector was not confident and the line must be reviewed.
struct ScanService {
    /// Fallback confidence when an order has no simulation profile.
    private static let fallbackConfidence: Double = 0.95

    /// Scripted profile per order id → product id.
    static let profiles: [String: [String: SimulatedDetection]] = [
        // Missing one ขนมปังนมสด — the headline demo scenario.
        "BK-1001": [
            "croissant": SimulatedDetection(qty: 4, confidence: 0.97),
            "milk-bread": SimulatedDetection(qty: 2, confidence: 0.94),
            "donut": SimulatedDetection(qty: 2, confidence: 0.96),
        ],
        // Everything matches → passes.
        "BK-1002": [
            "choc-bread": SimulatedDetection(qty: 6, confidence: 0.95),
            "almond-croissant": SimulatedDetection(qty: 2, confidence: 0.90),
        ],
        // Extra donuts + an uncertain mochi line → needs review.
        "BK-1003": [
            "donut": SimulatedDetection(qty: 14, confidence: 0.88),
            "mochi-bread": SimulatedDetection(qty: nil, confidence: 0.36),
            "butter-cake": SimulatedDetection(qty: 2, confidence: 0.93),
        ],
        // Everything matches → passes.
        "BK-1004": [
            "croissant": SimulatedDetection(qty: 6, confidence: 0.96),
            "milk-bread": SimulatedDetection(qty: 6, confidence: 0.95),
            "choc-bread": SimulatedDetection(qty: 4, confidence: 0.97),
            "donut": SimulatedDetection(qty: 3, confidence: 0.94),
        ],
        // One extra butter cake.
        "BK-1005": [
            "walnut-bread": SimulatedDetection(qty: 5, confidence: 0.92),
            "butter-cake": SimulatedDetection(qty: 4, confidence: 0.90),
        ],
    ]

    /// Runs the mock detector for an order.
    static func simulate(order: Order) -> [ScanLine] {
        let profile = profiles[order.id] ?? [:]

        return order.items.map { item in
            guard let sim = profile[item.productId] else {
                // No scripted profile → pretend a confident exact detection.
                return ScanLine(
                    productId: item.productId,
                    detectedQty: item.expectedQty,
                    confidence: fallbackConfidence,
                    manualQty: nil
                )
            }
            return ScanLine(
                productId: item.productId,
                detectedQty: sim.qty,
                confidence: sim.confidence,
                manualQty: nil
            )
        }
    }
}
