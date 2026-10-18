/**
 * Simulated product detection.
 *
 * ⚠️ MOCK: This prototype does NOT run any real AI / computer-vision model.
 * Results are deterministic per order (see data/simulations.ts) so the demo is
 * repeatable. Replace this function with a real CV service call to go live —
 * the rest of the app only depends on the `ScanLine[]` shape it returns.
 */
import { SIMULATIONS } from '../data/simulations'
import type { Order, ScanLine } from '../types'

/** Fallback confidence when an order has no simulation profile. */
const FALLBACK_CONFIDENCE = 0.95

export function simulateScan(order: Order): ScanLine[] {
  const profile = SIMULATIONS[order.id] ?? {}

  return order.items.map((item) => {
    const sim = profile[item.productId]

    if (!sim) {
      // No scripted profile → pretend a confident exact detection.
      return {
        productId: item.productId,
        detectedQty: item.expectedQty,
        confidence: FALLBACK_CONFIDENCE,
        manualQty: null,
      }
    }

    return {
      productId: item.productId,
      detectedQty: sim.qty,
      confidence: sim.confidence,
      manualQty: null,
    }
  })
}
