import type { IconName } from '../icons/Icon'
import type { PageName, Route } from '../../types'

/** Pages that appear in the sidebar (all reachable without a route param). */
export type NavPageName = 'dashboard' | 'orders' | 'packing' | 'history' | 'settings'

export interface NavItem {
  name: NavPageName
  label: string
  icon: IconName
}

export const NAV_ITEMS: NavItem[] = [
  { name: 'dashboard', label: 'ภาพรวม', icon: 'dashboard' },
  { name: 'orders', label: 'จัดการออเดอร์', icon: 'orders' },
  { name: 'packing', label: 'ตรวจสอบสินค้า', icon: 'scan' },
  { name: 'history', label: 'ประวัติออเดอร์', icon: 'history' },
  { name: 'settings', label: 'ตั้งค่า', icon: 'settings' },
]

export const ROUTE_TITLE: Record<PageName, string> = {
  dashboard: 'ภาพรวม',
  orders: 'จัดการออเดอร์',
  packing: 'ตรวจสอบสินค้า',
  result: 'ผลการตรวจสอบ',
  handover: 'ส่งมอบสินค้า',
  history: 'ประวัติออเดอร์',
  settings: 'ตั้งค่า',
}

export const ROUTE_SUBTITLE: Partial<Record<PageName, string>> = {
  dashboard: 'ตรวจสอบความถูกต้องของออเดอร์ก่อนส่งมอบ',
  orders: 'ค้นหา ตรวจสอบ และจัดการออเดอร์ทั้งหมด',
  packing: 'สแกนเทียบจำนวนสินค้ากับออเดอร์ก่อนส่งมอบ',
  result: 'สรุปผลการตรวจสอบจำนวนสินค้า',
  handover: 'ยืนยันการส่งมอบออเดอร์ให้พนักงานขับรถ',
  history: 'บันทึกผลการตรวจสอบย้อนหลัง',
  settings: 'ข้อมูลร้าน การแจ้งเตือน และการตั้งค่า',
}

export function routeTitle(route: Route): string {
  const base = ROUTE_TITLE[route.name]
  if ('orderId' in route && route.orderId) return `${base} · ${route.orderId}`
  return base
}

/** Which sidebar entry should appear active for a given route. */
export function activeNav(route: Route): PageName {
  switch (route.name) {
    case 'result':
      return 'packing'
    case 'handover':
      return 'orders'
    default:
      return route.name
  }
}

export function isNavActive(active: PageName, item: NavPageName): boolean {
  return active === item
}
