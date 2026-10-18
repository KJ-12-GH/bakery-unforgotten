/** Derives the notification feed from current order state (no stored copy). */
import type { NotificationItem, Order } from '../types'

export function buildNotifications(orders: Order[]): NotificationItem[] {
  const items: NotificationItem[] = []

  for (const order of orders) {
    if (order.status === 'mismatch') {
      items.push({
        id: `mismatch-${order.id}`,
        title: `${order.id} พบข้อผิดพลาด`,
        detail: 'จำนวนสินค้าไม่ตรงกับออเดอร์ ต้องแก้ไขก่อนส่งมอบ',
        tone: 'error',
        at: order.updatedAt,
      })
    }

    if (order.status === 'review') {
      items.push({
        id: `review-${order.id}`,
        title: `${order.id} ต้องตรวจสอบเพิ่มเติม`,
        detail: 'ระบบไม่มั่นใจในผลการตรวจจับ กรุณาตรวจสอบด้วยตนเอง',
        tone: 'warning',
        at: order.updatedAt,
      })
    }

    if (order.status === 'passed' && order.handover === 'ready') {
      items.push({
        id: `ready-${order.id}`,
        title: `${order.id} พร้อมส่งมอบ`,
        detail: 'ตรวจสอบผ่านแล้ว รอส่งมอบให้พนักงานขับรถ',
        tone: 'success',
        at: order.verifiedAt ?? order.updatedAt,
      })
    }

    if (order.status === 'pending') {
      items.push({
        id: `pending-${order.id}`,
        title: `${order.id} รอตรวจสอบ`,
        detail: 'ยังไม่ได้สแกนตรวจสอบสินค้า',
        tone: 'info',
        at: order.updatedAt,
      })
    }
  }

  return items.sort((a, b) => b.at.localeCompare(a.at)).slice(0, 12)
}
