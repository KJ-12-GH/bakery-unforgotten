/**
 * Verification logic.
 *
 * Deliberately independent from the scanning mechanism (see utils/scan.ts) so
 * a real computer-vision service can be plugged in without touching these rules.
 */
import type {
  ItemStatus,
  Order,
  ScanDraft,
  ScanLine,
  ScanOutcome,
  ScanRecordLine,
} from '../types'

/** The quantity that should be compared: a staff correction wins over detection. */
export function effectiveQty(line: ScanLine): number | null {
  return line.manualQty ?? line.detectedQty
}

/** Classify a single product against its expected quantity. */
export function classify(expected: number, effective: number | null): ItemStatus {
  if (effective === null) return 'uncertain'
  if (effective === expected) return 'match'
  if (effective < expected) return 'missing'
  return 'extra'
}

export interface ComparisonRow {
  productId: string
  expectedQty: number
  detectedQty: number | null
  manualQty: number | null
  effectiveQty: number | null
  /** effective - expected (null when effective is unknown). */
  difference: number | null
  status: ItemStatus
  confidence: number | null
  /** True when a staff correction changed the detected value. */
  corrected: boolean
}

/** Build the full per-product comparison for an order + draft. */
export function compareOrder(order: Order, draft: ScanDraft): ComparisonRow[] {
  return order.items.map((item) => {
    const line = draft.lines.find((l) => l.productId === item.productId)
    const detectedQty = line?.detectedQty ?? null
    const manualQty = line?.manualQty ?? null
    const effective = manualQty ?? detectedQty

    return {
      productId: item.productId,
      expectedQty: item.expectedQty,
      detectedQty,
      manualQty,
      effectiveQty: effective,
      difference: effective === null ? null : effective - item.expectedQty,
      status: classify(item.expectedQty, effective),
      confidence: line?.confidence ?? null,
      corrected: manualQty !== null && manualQty !== detectedQty,
    }
  })
}

/**
 * Overall outcome.
 * An uncertain line always wins over a mismatch, because it must be reviewed
 * by a human before a decision can be made.
 */
export function outcomeOf(rows: ComparisonRow[]): ScanOutcome {
  if (rows.length === 0) return 'uncertain'
  if (rows.some((r) => r.status === 'uncertain')) return 'uncertain'
  if (rows.some((r) => r.status === 'missing' || r.status === 'extra')) return 'mismatch'
  return 'passed'
}

/** An order may only be confirmed when every product matches exactly. */
export function isVerifiable(rows: ComparisonRow[]): boolean {
  return outcomeOf(rows) === 'passed'
}

export function toRecordLines(rows: ComparisonRow[]): ScanRecordLine[] {
  return rows.map((row) => ({
    productId: row.productId,
    expectedQty: row.expectedQty,
    effectiveQty: row.effectiveQty,
    status: row.status,
    corrected: row.corrected,
  }))
}

export interface ComparisonSummary {
  totalExpected: number
  totalEffective: number
  missing: number
  extra: number
  uncertain: number
  corrected: number
  matched: number
}

export function summarize(rows: ComparisonRow[]): ComparisonSummary {
  return rows.reduce<ComparisonSummary>(
    (acc, row) => {
      acc.totalExpected += row.expectedQty
      acc.totalEffective += row.effectiveQty ?? 0
      if (row.status === 'missing') acc.missing += Math.abs(row.difference ?? 0)
      if (row.status === 'extra') acc.extra += row.difference ?? 0
      if (row.status === 'uncertain') acc.uncertain += 1
      if (row.status === 'match') acc.matched += 1
      if (row.corrected) acc.corrected += 1
      return acc
    },
    {
      totalExpected: 0,
      totalEffective: 0,
      missing: 0,
      extra: 0,
      uncertain: 0,
      corrected: 0,
      matched: 0,
    },
  )
}
