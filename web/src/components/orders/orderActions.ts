import type { Order } from '../../types'

export type OrderActionKind = 'verify' | 'handover' | 'details'

export interface OrderPrimaryAction {
  kind: OrderActionKind
  label: string
}

/** The single most useful next action for an order. */
export function primaryActionFor(order: Order): OrderPrimaryAction {
  if (order.status === 'handed_over') return { kind: 'details', label: 'ดูรายละเอียด' }
  if (order.status === 'passed' && order.handover === 'ready') {
    return { kind: 'handover', label: 'ส่งมอบ' }
  }
  return { kind: 'verify', label: 'ตรวจสอบ' }
}
