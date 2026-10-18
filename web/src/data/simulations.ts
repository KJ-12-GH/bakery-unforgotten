/**
 * ⚠️ MOCK DETECTION PROFILES — NOT REAL AI.
 *
 * Scripted outcomes for the prototype's simulated scanner so demos are
 * repeatable. `qty: null` means the (mock) detector was not confident and the
 * line must be reviewed by a staff member.
 *
 * Replace together with `utils/scan.ts` when a real computer-vision service
 * is available; nothing else in the app depends on this file.
 */
export interface SimulatedDetection {
  /** Detected quantity, or null when the detection was uncertain. */
  qty: number | null
  /** Mock confidence 0..1 (illustrative only). */
  confidence: number
}

export const SIMULATIONS: Record<string, Record<string, SimulatedDetection>> = {
  // Missing one ขนมปังนมสด — the headline demo scenario.
  'BK-1001': {
    croissant: { qty: 4, confidence: 0.97 },
    'milk-bread': { qty: 2, confidence: 0.94 },
    donut: { qty: 2, confidence: 0.96 },
  },
  // Everything matches → passes.
  'BK-1002': {
    'choc-bread': { qty: 6, confidence: 0.95 },
    'almond-croissant': { qty: 2, confidence: 0.9 },
  },
  // Extra donuts + an uncertain mochi line → needs review.
  'BK-1003': {
    donut: { qty: 14, confidence: 0.88 },
    'mochi-bread': { qty: null, confidence: 0.36 },
    'butter-cake': { qty: 2, confidence: 0.93 },
  },
  // Everything matches → passes.
  'BK-1004': {
    croissant: { qty: 6, confidence: 0.96 },
    'milk-bread': { qty: 6, confidence: 0.95 },
    'choc-bread': { qty: 4, confidence: 0.97 },
    donut: { qty: 3, confidence: 0.94 },
  },
  // One extra butter cake.
  'BK-1005': {
    'walnut-bread': { qty: 5, confidence: 0.92 },
    'butter-cake': { qty: 4, confidence: 0.9 },
  },
}
