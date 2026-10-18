import type { Settings, Staff } from '../types'

/** Sample signed-in staff member (prototype only — no real authentication). */
export const STAFF: Staff = {
  name: 'ณัฐนนท์ รัตนโชติ',
  role: 'พนักงานตรวจสอบออเดอร์',
  initials: 'ณร',
  store: 'ครัวอบอุ่น เบเกอรี่',
}

export const DEFAULT_SETTINGS: Settings = {
  storeName: 'ครัวอบอุ่น เบเกอรี่',
  language: 'th',
  notifyMismatch: true,
  notifyHandover: true,
  notifyDailySummary: false,
  autoAdvance: true,
}

/** Sample delivery drivers available for handover. */
export const DRIVERS: string[] = ['พี่สมพงษ์', 'พี่วิชัย', 'พี่อาร์ต', 'พี่นัท']
