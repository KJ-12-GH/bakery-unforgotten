import type { ScanOutcome, ScanRecord, ScanRecordLine } from '../types'
import { hoursAgo, minutesAgo, daysAgo } from './time'

interface LineSeed {
  productId: string
  expected: number
  /** The quantity the comparison finally used (detection or correction). */
  effective: number | null
  corrected?: boolean
}

interface RecordSeed {
  id: string
  orderId: string
  scannedAt: string
  verifiedAt: string
  lines: LineSeed[]
}

function classify(expected: number, effective: number | null): ScanRecordLine['status'] {
  if (effective === null) return 'uncertain'
  if (effective === expected) return 'match'
  if (effective < expected) return 'missing'
  return 'extra'
}

function outcomeOf(lines: ScanRecordLine[]): ScanOutcome {
  if (lines.some((l) => l.status === 'uncertain')) return 'uncertain'
  if (lines.some((l) => l.status === 'missing' || l.status === 'extra')) return 'mismatch'
  return 'passed'
}

function buildRecord(seed: RecordSeed): ScanRecord {
  const lines: ScanRecordLine[] = seed.lines.map((line) => ({
    productId: line.productId,
    expectedQty: line.expected,
    effectiveQty: line.effective,
    status: classify(line.expected, line.effective),
    corrected: line.corrected ?? false,
  }))

  return {
    id: seed.id,
    orderId: seed.orderId,
    scannedAt: seed.scannedAt,
    verifiedAt: seed.verifiedAt,
    outcome: outcomeOf(lines),
    corrected: lines.some((l) => l.corrected),
    lines,
  }
}

/** Verification history for orders that were already processed. */
const RECORD_SEEDS: RecordSeed[] = [
  {
    id: 'BC-2001',
    orderId: 'BK-1006',
    scannedAt: minutesAgo(28),
    verifiedAt: minutesAgo(22),
    lines: [
      { productId: 'croissant', expected: 8, effective: 8 },
      { productId: 'donut', expected: 4, effective: 4 },
    ],
  },
  {
    id: 'BC-2002',
    orderId: 'BK-1007',
    scannedAt: minutesAgo(38),
    verifiedAt: minutesAgo(35),
    lines: [
      { productId: 'milk-bread', expected: 10, effective: 8 },
      { productId: 'choc-bread', expected: 2, effective: 2 },
    ],
  },
  {
    id: 'BC-2003',
    orderId: 'BK-1008',
    scannedAt: hoursAgo(3.1),
    verifiedAt: hoursAgo(3),
    lines: [
      { productId: 'croissant', expected: 3, effective: 3 },
      { productId: 'butter-cake', expected: 1, effective: 1 },
    ],
  },
  {
    id: 'BC-2004',
    orderId: 'BK-1009',
    scannedAt: hoursAgo(5.25),
    verifiedAt: hoursAgo(5.17),
    lines: [
      { productId: 'donut', expected: 6, effective: 6 },
      { productId: 'mochi-bread', expected: 2, effective: 2 },
      { productId: 'choc-bread', expected: 3, effective: 3 },
    ],
  },
  {
    id: 'BC-2005',
    orderId: 'BK-1010',
    scannedAt: daysAgo(1.05),
    verifiedAt: daysAgo(1.04),
    lines: [
      { productId: 'almond-croissant', expected: 4, effective: 4 },
      { productId: 'walnut-bread', expected: 2, effective: 2 },
    ],
  },
  {
    // Verified after a staff correction (detected 4 → corrected to 5).
    id: 'BC-2006',
    orderId: 'BK-1011',
    scannedAt: daysAgo(1.22),
    verifiedAt: daysAgo(1.21),
    lines: [
      { productId: 'croissant', expected: 5, effective: 5, corrected: true },
      { productId: 'milk-bread', expected: 2, effective: 2 },
    ],
  },
]

export function createInitialScans(): ScanRecord[] {
  return RECORD_SEEDS.map(buildRecord)
}
