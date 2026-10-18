/**
 * BakeCheck — shared domain types.
 * Status values are explicit so business state is never inferred from labels.
 */

/** Lifecycle of an order's verification. */
export type OrderStatus =
  | 'pending' // รอตรวจสอบ
  | 'verifying' // กำลังตรวจสอบ
  | 'review' // ต้องตรวจสอบเพิ่มเติม (uncertain detection)
  | 'mismatch' // พบข้อผิดพลาด
  | 'passed' // ตรวจสอบผ่าน
  | 'handed_over' // ส่งมอบแล้ว

/** Whether an order may be handed to a delivery driver. */
export type HandoverStatus = 'blocked' | 'ready' | 'handed_over'

/** Per-product verification result. */
export type ItemStatus = 'pending' | 'match' | 'missing' | 'extra' | 'uncertain'

/** Where a detected quantity came from. */
export type DetectionSource = 'simulated' | 'manual'

/** Overall outcome of a scan. */
export type ScanOutcome = 'passed' | 'mismatch' | 'uncertain'

export interface Product {
  id: string
  /** Thai display name. */
  name: string
  /** Latin name for secondary display. */
  nameEn: string
  emoji: string
}

export interface OrderItem {
  productId: string
  expectedQty: number
}

export interface Order {
  id: string
  customer: string
  items: OrderItem[]
  createdAt: string
  updatedAt: string
  status: OrderStatus
  handover: HandoverStatus
  verifiedAt: string | null
  handedOverAt: string | null
  driver: string | null
}

/**
 * One line produced by the scanner for an order.
 * `detectedQty === null` means the detector could not identify the product
 * confidently, so the line must be reviewed by a staff member.
 */
export interface ScanLine {
  productId: string
  detectedQty: number | null
  confidence: number | null
  /** Staff correction. When set, it takes precedence over the detection. */
  manualQty: number | null
}

/** An in-progress packing session for an order. */
export interface ScanDraft {
  orderId: string
  scannedAt: string
  lines: ScanLine[]
}

/** A committed verification result, persisted to history. */
export interface ScanRecordLine {
  productId: string
  expectedQty: number
  effectiveQty: number | null
  status: ItemStatus
  corrected: boolean
}

export interface ScanRecord {
  id: string
  orderId: string
  scannedAt: string
  verifiedAt: string | null
  outcome: ScanOutcome
  corrected: boolean
  lines: ScanRecordLine[]
}

export interface Staff {
  name: string
  role: string
  initials: string
  store: string
}

export interface Settings {
  storeName: string
  language: 'th' | 'en'
  notifyMismatch: boolean
  notifyHandover: boolean
  notifyDailySummary: boolean
  autoAdvance: boolean
}

export interface NotificationItem {
  id: string
  title: string
  detail: string
  tone: 'info' | 'warning' | 'error' | 'success'
  at: string
}

/** Application route (lightweight hash router). */
export type Route =
  | { name: 'dashboard' }
  | { name: 'orders'; orderId?: string }
  | { name: 'packing'; orderId?: string }
  | { name: 'result'; orderId: string }
  | { name: 'handover'; orderId?: string }
  | { name: 'history'; orderId?: string }
  | { name: 'settings' }

export type PageName = Route['name']
