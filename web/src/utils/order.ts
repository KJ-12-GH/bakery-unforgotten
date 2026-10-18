import type { Order } from '../types'

export function orderTotalQty(order: Order): number {
  return order.items.reduce((sum, item) => sum + item.expectedQty, 0)
}

export function orderItemCount(order: Order): number {
  return order.items.length
}

/** Orders that still need packing verification work. */
export function needsVerification(order: Order): boolean {
  return (
    order.status === 'pending' ||
    order.status === 'verifying' ||
    order.status === 'mismatch' ||
    order.status === 'review'
  )
}
