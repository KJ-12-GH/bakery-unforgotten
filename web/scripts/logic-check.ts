/**
 * BakeCheck — logic smoke test for the core verification workflow.
 *
 * Runs the real verification + simulated-scan modules (no DOM, no React) and
 * asserts the business rules required by the product spec.
 *
 *   npm run check
 */
import { createInitialOrders } from '../src/data/orders'
import { createInitialScans } from '../src/data/scans'
import { simulateScan } from '../src/utils/scan'
import { classify, compareOrder, isVerifiable, outcomeOf, summarize } from '../src/utils/verification'
import type { Order, ScanDraft } from '../src/types'

let passed = 0
let failed = 0

function check(name: string, condition: boolean): void {
  if (condition) {
    passed += 1
    console.log(`  \u2713 ${name}`)
  } else {
    failed += 1
    console.error(`  \u2717 ${name}`)
  }
}

function draftFor(order: Order): ScanDraft {
  return { orderId: order.id, scannedAt: new Date().toISOString(), lines: simulateScan(order) }
}

const orders = createInitialOrders()
const byId = (id: string): Order => {
  const order = orders.find((item) => item.id === id)
  if (!order) throw new Error(`missing seed order ${id}`)
  return order
}

console.log('\nBakeCheck logic checks\n')

// ---- classify() ----------------------------------------------------------
console.log('classify')
check('exact match', classify(4, 4) === 'match')
check('missing when fewer', classify(3, 2) === 'missing')
check('extra when more', classify(2, 4) === 'extra')
check('uncertain when detection unknown', classify(3, null) === 'uncertain')

// ---- BK-1001: the headline "missing one" scenario ------------------------
console.log('\nBK-1001 — ขนมปังนมสด missing')
const o1001 = byId('BK-1001')
const d1001 = draftFor(o1001)
const r1001 = compareOrder(o1001, d1001)

check('all three products compared', r1001.length === 3)
check('ครัวซองต์ matches (4/4)', r1001[0].status === 'match')
check('ขนมปังนมสด missing 1 (3 vs 2)', r1001[1].status === 'missing' && r1001[1].difference === -1)
check('โดนัท matches (2/2)', r1001[2].status === 'match')
check('overall outcome is mismatch', outcomeOf(r1001) === 'mismatch')
check('cannot verify while mismatched', !isVerifiable(r1001))

const s1001 = summarize(r1001)
check('summary counts 1 missing piece', s1001.missing === 1)
check('summary totals 9 expected pieces', s1001.totalExpected === 9)

// ---- manual correction unblocks verification ----------------------------
console.log('\nBK-1001 — staff corrects ขนมปังนมสด to 3')
const corrected: ScanDraft = {
  ...d1001,
  lines: d1001.lines.map((line) =>
    line.productId === 'milk-bread' ? { ...line, manualQty: 3 } : line,
  ),
}
const rCorrected = compareOrder(o1001, corrected)
check('corrected line now matches', rCorrected[1].status === 'match')
check('correction is flagged', rCorrected[1].corrected === true)
check('overall outcome becomes passed', outcomeOf(rCorrected) === 'passed')
check('verification now allowed', isVerifiable(rCorrected))

// ---- BK-1002: clean pass -------------------------------------------------
console.log('\nBK-1002 — everything matches')
const r1002 = compareOrder(byId('BK-1002'), draftFor(byId('BK-1002')))
check('all lines match', r1002.every((row) => row.status === 'match'))
check('outcome passed', outcomeOf(r1002) === 'passed')

// ---- BK-1003: extra + uncertain ------------------------------------------
console.log('\nBK-1003 — extra donuts and an uncertain line')
const r1003 = compareOrder(byId('BK-1003'), draftFor(byId('BK-1003')))
check('donut line is extra (+2)', r1003[0].status === 'extra' && r1003[0].difference === 2)
check('mochi line is uncertain', r1003[1].status === 'uncertain')
check('uncertain wins over mismatch', outcomeOf(r1003) === 'uncertain')
check('cannot verify uncertain result', !isVerifiable(r1003))

// ---- seeded history records ---------------------------------------------
console.log('\nSeeded verification history')
const scans = createInitialScans()
const rec2002 = scans.find((scan) => scan.id === 'BC-2002')
const rec2006 = scans.find((scan) => scan.id === 'BC-2006')
check('BC-2002 recorded as mismatch', rec2002?.outcome === 'mismatch')
check('BC-2002 flags the missing milk bread', rec2002?.lines[0].status === 'missing')
check('BC-2006 recorded as passed', rec2006?.outcome === 'passed')
check('BC-2006 records a staff correction', rec2006?.corrected === true)

// ---- ordering invariants -------------------------------------------------
console.log('\nSeed data invariants')
check(
  'handed-over orders are always verified',
  orders.filter((o) => o.handover === 'handed_over').every((o) => o.status === 'handed_over'),
)
check(
  'no order is ready for handover without passing',
  orders.filter((o) => o.handover === 'ready').every((o) => o.status === 'passed'),
)

console.log(`\n${passed} passed, ${failed} failed\n`)
if (failed > 0) process.exit(1)
