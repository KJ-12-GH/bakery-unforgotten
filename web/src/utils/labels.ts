/** Thai labels and badge tones for domain statuses. */
import type { HandoverStatus, ItemStatus, Order, OrderStatus } from '../types'

export type BadgeTone = 'neutral' | 'info' | 'success' | 'warning' | 'error' | 'brand'

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  pending: 'รอตรวจสอบ',
  verifying: 'กำลังตรวจสอบ',
  review: 'ต้องตรวจสอบเพิ่มเติม',
  mismatch: 'พบข้อผิดพลาด',
  passed: 'ตรวจสอบผ่าน',
  handed_over: 'ส่งมอบแล้ว',
}

/** Display label; a verified order awaiting handover reads "พร้อมส่งมอบ". */
export function orderStatusLabel(order: Order): string {
  if (order.status === 'passed' && order.handover === 'ready') return 'พร้อมส่งมอบ'
  return ORDER_STATUS_LABEL[order.status]
}

export function orderStatusTone(order: Order): BadgeTone {
  if (order.status === 'passed') return 'success'
  switch (order.status) {
    case 'pending':
      return 'neutral'
    case 'verifying':
      return 'info'
    case 'review':
      return 'warning'
    case 'mismatch':
      return 'error'
    case 'handed_over':
      return 'brand'
  }
}

export const HANDOVER_LABEL: Record<HandoverStatus, string> = {
  blocked: 'ยังส่งมอบไม่ได้',
  ready: 'พร้อมส่งมอบ',
  handed_over: 'ส่งมอบแล้ว',
}

export function handoverTone(status: HandoverStatus): BadgeTone {
  switch (status) {
    case 'blocked':
      return 'neutral'
    case 'ready':
      return 'success'
    case 'handed_over':
      return 'brand'
  }
}

export const ITEM_STATUS_LABEL: Record<ItemStatus, string> = {
  pending: 'รอผล',
  match: 'ตรงกัน',
  missing: 'ขาด',
  extra: 'เกิน',
  uncertain: 'ไม่แน่ชัด',
}

export function itemStatusTone(status: ItemStatus): BadgeTone {
  switch (status) {
    case 'match':
      return 'success'
    case 'missing':
    case 'extra':
      return 'error'
    case 'uncertain':
      return 'warning'
    case 'pending':
      return 'neutral'
  }
}

/** Short Thai sentence describing a comparison result. */
export function comparisonText(status: ItemStatus, difference: number | null): string {
  switch (status) {
    case 'match':
      return 'ตรงกัน'
    case 'missing':
      return `ขาด ${Math.abs(difference ?? 0)} ชิ้น`
    case 'extra':
      return `เกิน ${difference ?? 0} ชิ้น`
    case 'uncertain':
      return 'ต้องตรวจสอบ'
    case 'pending':
      return 'รอผล'
  }
}

export function differenceText(difference: number | null): string {
  if (difference === null) return '—'
  if (difference === 0) return '0'
  return difference > 0 ? `+${difference}` : `${difference}`
}
