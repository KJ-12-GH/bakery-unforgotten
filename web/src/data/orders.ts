import type { HandoverStatus, Order, OrderItem, OrderStatus } from '../types'
import { daysAgo, hoursAgo, minutesAgo } from './time'

const item = (productId: string, expectedQty: number): OrderItem => ({ productId, expectedQty })

interface OrderSeed {
  id: string
  customer: string
  createdAt: string
  updatedAt: string
  status: OrderStatus
  handover?: HandoverStatus
  verifiedAt?: string
  handedOverAt?: string
  driver?: string
  items: OrderItem[]
}

/**
 * Mock order book.
 * Times are relative to app load so the dashboard always looks "live".
 */
const ORDER_SEEDS: OrderSeed[] = [
  {
    id: 'BK-1001',
    customer: 'ร้านกาแฟบ้านสวน',
    createdAt: minutesAgo(42),
    updatedAt: minutesAgo(12),
    status: 'pending',
    items: [item('croissant', 4), item('milk-bread', 3), item('donut', 2)],
  },
  {
    id: 'BK-1002',
    customer: 'คุณมานะ ใจดี',
    createdAt: minutesAgo(33),
    updatedAt: minutesAgo(30),
    status: 'pending',
    items: [item('choc-bread', 6), item('almond-croissant', 2)],
  },
  {
    id: 'BK-1003',
    customer: 'ร้านขนมปังปิ้งสุขใจ',
    createdAt: minutesAgo(26),
    updatedAt: minutesAgo(24),
    status: 'pending',
    items: [item('donut', 12), item('mochi-bread', 4), item('butter-cake', 2)],
  },
  {
    id: 'BK-1004',
    customer: 'บริษัทอรุณเบเกอรี่ จำกัด',
    createdAt: minutesAgo(18),
    updatedAt: minutesAgo(15),
    status: 'pending',
    items: [
      item('croissant', 6),
      item('milk-bread', 6),
      item('choc-bread', 4),
      item('donut', 3),
    ],
  },
  {
    id: 'BK-1005',
    customer: 'คุณปิยะ ศรีสุข',
    createdAt: minutesAgo(58),
    updatedAt: minutesAgo(9),
    status: 'verifying',
    items: [item('walnut-bread', 5), item('butter-cake', 3)],
  },
  {
    id: 'BK-1006',
    customer: 'ร้านกาแฟบ้านสวน',
    createdAt: hoursAgo(2),
    updatedAt: minutesAgo(22),
    status: 'passed',
    handover: 'ready',
    verifiedAt: minutesAgo(22),
    items: [item('croissant', 8), item('donut', 4)],
  },
  {
    id: 'BK-1007',
    customer: 'คุณสมชาย ตั้งใจ',
    createdAt: minutesAgo(80),
    updatedAt: minutesAgo(35),
    status: 'mismatch',
    items: [item('milk-bread', 10), item('choc-bread', 2)],
  },
  {
    id: 'BK-1008',
    customer: 'ร้านขนมอบเช้า',
    createdAt: hoursAgo(4),
    updatedAt: hoursAgo(2.5),
    status: 'handed_over',
    handover: 'handed_over',
    verifiedAt: hoursAgo(3),
    handedOverAt: hoursAgo(2.5),
    driver: 'พี่สมพงษ์',
    items: [item('croissant', 3), item('butter-cake', 1)],
  },
  {
    id: 'BK-1009',
    customer: 'คุณนภา พรหมมา',
    createdAt: hoursAgo(6),
    updatedAt: hoursAgo(5),
    status: 'handed_over',
    handover: 'handed_over',
    verifiedAt: hoursAgo(5.17),
    handedOverAt: hoursAgo(5),
    driver: 'พี่วิชัย',
    items: [item('donut', 6), item('mochi-bread', 2), item('choc-bread', 3)],
  },
  {
    id: 'BK-1010',
    customer: 'ร้านกาแฟบ้านสวน',
    createdAt: daysAgo(1.08),
    updatedAt: daysAgo(1),
    status: 'handed_over',
    handover: 'handed_over',
    verifiedAt: daysAgo(1.04),
    handedOverAt: daysAgo(1),
    driver: 'พี่สมพงษ์',
    items: [item('almond-croissant', 4), item('walnut-bread', 2)],
  },
  {
    id: 'BK-1011',
    customer: 'คุณธนา รักดี',
    createdAt: daysAgo(1.25),
    updatedAt: daysAgo(1.17),
    status: 'handed_over',
    handover: 'handed_over',
    verifiedAt: daysAgo(1.21),
    handedOverAt: daysAgo(1.17),
    driver: 'พี่อาร์ต',
    items: [item('croissant', 5), item('milk-bread', 2)],
  },
]

export function createInitialOrders(): Order[] {
  return ORDER_SEEDS.map((seed) => ({
    id: seed.id,
    customer: seed.customer,
    items: seed.items,
    createdAt: seed.createdAt,
    updatedAt: seed.updatedAt,
    status: seed.status,
    handover: seed.handover ?? 'blocked',
    verifiedAt: seed.verifiedAt ?? null,
    handedOverAt: seed.handedOverAt ?? null,
    driver: seed.driver ?? null,
  }))
}
