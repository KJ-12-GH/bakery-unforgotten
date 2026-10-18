/* eslint-disable react/only-export-components -- context module exports its provider and hook together */
import { createContext, useCallback, useContext, useEffect, useMemo, useReducer } from 'react'
import type { ReactNode } from 'react'
import { createInitialOrders } from '../data/orders'
import { PRODUCTS } from '../data/products'
import { createInitialScans } from '../data/scans'
import { DEFAULT_SETTINGS, STAFF } from '../data/staff'
import type {
  Order,
  OrderStatus,
  Product,
  ScanDraft,
  ScanLine,
  ScanOutcome,
  ScanRecord,
  Settings,
  Staff,
} from '../types'
import { createId } from '../utils/id'
import { compareOrder, isVerifiable, outcomeOf, toRecordLines } from '../utils/verification'

export interface DataState {
  orders: Order[]
  scans: ScanRecord[]
  drafts: Record<string, ScanDraft>
  settings: Settings
}

type DataAction =
  | { type: 'START_SCAN'; orderId: string; lines: ScanLine[]; at: string }
  | { type: 'SET_MANUAL_QTY'; orderId: string; productId: string; qty: number | null; at: string }
  | { type: 'CLEAR_DRAFT'; orderId: string }
  | { type: 'CONFIRM_VERIFICATION'; orderId: string; at: string }
  | { type: 'HANDOVER'; orderId: string; at: string; driver: string }
  | { type: 'UPDATE_SETTINGS'; patch: Partial<Settings> }
  | { type: 'RESET_DEMO' }

const STORAGE_KEY = 'bakecheck.state.v1'

/** Order status implied by a scan outcome (before explicit confirmation). */
function statusForOutcome(outcome: ScanOutcome): OrderStatus {
  switch (outcome) {
    case 'mismatch':
      return 'mismatch'
    case 'uncertain':
      return 'review'
    case 'passed':
      return 'verifying'
  }
}

function patchOrder(orders: Order[], orderId: string, patch: Partial<Order>): Order[] {
  return orders.map((order) => (order.id === orderId ? { ...order, ...patch } : order))
}

function reducer(state: DataState, action: DataAction): DataState {
  switch (action.type) {
    case 'START_SCAN': {
      const order = state.orders.find((o) => o.id === action.orderId)
      if (!order || order.handover === 'handed_over') return state

      const draft: ScanDraft = {
        orderId: order.id,
        scannedAt: action.at,
        lines: action.lines,
      }
      const rows = compareOrder(order, draft)

      return {
        ...state,
        drafts: { ...state.drafts, [order.id]: draft },
        orders: patchOrder(state.orders, order.id, {
          status: statusForOutcome(outcomeOf(rows)),
          updatedAt: action.at,
        }),
      }
    }

    case 'SET_MANUAL_QTY': {
      const order = state.orders.find((o) => o.id === action.orderId)
      const draft = state.drafts[action.orderId]
      if (!order || !draft) return state

      const lines = draft.lines.map((line) =>
        line.productId === action.productId ? { ...line, manualQty: action.qty } : line,
      )
      const nextDraft: ScanDraft = { ...draft, lines }
      const rows = compareOrder(order, nextDraft)

      return {
        ...state,
        drafts: { ...state.drafts, [order.id]: nextDraft },
        orders: patchOrder(state.orders, order.id, {
          status: statusForOutcome(outcomeOf(rows)),
          updatedAt: action.at,
        }),
      }
    }

    case 'CLEAR_DRAFT': {
      if (!state.drafts[action.orderId]) return state
      const drafts = { ...state.drafts }
      delete drafts[action.orderId]
      return { ...state, drafts }
    }

    case 'CONFIRM_VERIFICATION': {
      const order = state.orders.find((o) => o.id === action.orderId)
      const draft = state.drafts[action.orderId]
      if (!order || !draft || order.handover === 'handed_over') return state

      const rows = compareOrder(order, draft)
      // Business rule: never verify while a check is incomplete or mismatched.
      if (!isVerifiable(rows)) return state

      const record: ScanRecord = {
        id: createId('BC'),
        orderId: order.id,
        scannedAt: draft.scannedAt,
        verifiedAt: action.at,
        outcome: 'passed',
        corrected: rows.some((row) => row.corrected),
        lines: toRecordLines(rows),
      }

      const drafts = { ...state.drafts }
      delete drafts[order.id]

      return {
        ...state,
        scans: [record, ...state.scans],
        drafts,
        orders: patchOrder(state.orders, order.id, {
          status: 'passed',
          handover: 'ready',
          verifiedAt: action.at,
          updatedAt: action.at,
        }),
      }
    }

    case 'HANDOVER': {
      const order = state.orders.find((o) => o.id === action.orderId)
      if (!order) return state
      // Business rule: only a verified order can be handed over, and only once.
      if (order.status !== 'passed' || order.handover !== 'ready') return state

      return {
        ...state,
        orders: patchOrder(state.orders, order.id, {
          status: 'handed_over',
          handover: 'handed_over',
          handedOverAt: action.at,
          driver: action.driver,
          updatedAt: action.at,
        }),
      }
    }

    case 'UPDATE_SETTINGS':
      return { ...state, settings: { ...state.settings, ...action.patch } }

    case 'RESET_DEMO':
      return createInitialState()

    default:
      return state
  }
}

function createInitialState(): DataState {
  return {
    orders: createInitialOrders(),
    scans: createInitialScans(),
    drafts: {},
    settings: DEFAULT_SETTINGS,
  }
}

function loadState(): DataState {
  if (typeof window === 'undefined') return createInitialState()
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY)
    if (!raw) return createInitialState()
    const parsed = JSON.parse(raw) as Partial<DataState>
    if (!parsed.orders || !parsed.scans || !parsed.settings) return createInitialState()
    return {
      orders: parsed.orders,
      scans: parsed.scans,
      drafts: parsed.drafts ?? {},
      settings: parsed.settings,
    }
  } catch {
    return createInitialState()
  }
}

export interface DataApi {
  state: DataState
  staff: Staff
  products: Product[]
  getOrder: (id: string) => Order | undefined
  getDraft: (orderId: string) => ScanDraft | undefined
  getLatestScan: (orderId: string) => ScanRecord | undefined
  recordScan: (orderId: string, lines: ScanLine[]) => void
  setManualQty: (orderId: string, productId: string, qty: number | null) => void
  clearDraft: (orderId: string) => void
  confirmVerification: (orderId: string) => void
  handOver: (orderId: string, driver: string) => void
  updateSettings: (patch: Partial<Settings>) => void
  resetDemo: () => void
}

const DataContext = createContext<DataApi | null>(null)

export function DataProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, loadState)

  useEffect(() => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
    } catch {
      // Storage may be unavailable (private mode); the prototype still works in memory.
    }
  }, [state])

  const getOrder = useCallback(
    (id: string) => state.orders.find((order) => order.id === id),
    [state.orders],
  )

  const getDraft = useCallback((orderId: string) => state.drafts[orderId], [state.drafts])

  const getLatestScan = useCallback(
    (orderId: string) =>
      state.scans
        .filter((scan) => scan.orderId === orderId)
        .sort((a, b) => b.scannedAt.localeCompare(a.scannedAt))[0],
    [state.scans],
  )

  const value = useMemo<DataApi>(
    () => ({
      state,
      staff: STAFF,
      products: PRODUCTS,
      getOrder,
      getDraft,
      getLatestScan,
      recordScan: (orderId, lines) =>
        dispatch({ type: 'START_SCAN', orderId, lines, at: new Date().toISOString() }),
      setManualQty: (orderId, productId, qty) =>
        dispatch({
          type: 'SET_MANUAL_QTY',
          orderId,
          productId,
          qty,
          at: new Date().toISOString(),
        }),
      clearDraft: (orderId) => dispatch({ type: 'CLEAR_DRAFT', orderId }),
      confirmVerification: (orderId) =>
        dispatch({ type: 'CONFIRM_VERIFICATION', orderId, at: new Date().toISOString() }),
      handOver: (orderId, driver) =>
        dispatch({ type: 'HANDOVER', orderId, at: new Date().toISOString(), driver }),
      updateSettings: (patch) => dispatch({ type: 'UPDATE_SETTINGS', patch }),
      resetDemo: () => dispatch({ type: 'RESET_DEMO' }),
    }),
    [state, getOrder, getDraft, getLatestScan],
  )

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>
}

export function useData(): DataApi {
  const ctx = useContext(DataContext)
  if (!ctx) throw new Error('useData must be used within a DataProvider')
  return ctx
}
