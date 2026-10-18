/** Locale-aware formatting helpers (Thai). */

const TIME_FMT = new Intl.DateTimeFormat('th-TH', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})

const DATE_FMT = new Intl.DateTimeFormat('th-TH', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
})

const DATE_TIME_FMT = new Intl.DateTimeFormat('th-TH', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})

const FULL_DATE_FMT = new Intl.DateTimeFormat('th-TH', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
})

export function formatTime(iso: string): string {
  return TIME_FMT.format(new Date(iso))
}

export function formatDate(iso: string): string {
  return DATE_FMT.format(new Date(iso))
}

export function formatDateTime(iso: string): string {
  return DATE_TIME_FMT.format(new Date(iso))
}

/** e.g. "วันอาทิตย์ที่ 18 ตุลาคม 2569" */
export function formatFullDate(date: Date): string {
  return FULL_DATE_FMT.format(date)
}

/** Human, Thai-language relative time. */
export function relativeTime(iso: string, now: number = Date.now()): string {
  const diff = now - new Date(iso).getTime()
  const minutes = Math.round(diff / 60000)

  if (minutes < 0) return 'กำลังจะถึง'
  if (minutes < 1) return 'เมื่อสักครู่'
  if (minutes < 60) return `${minutes} นาทีที่แล้ว`

  const hours = Math.round(minutes / 60)
  if (hours < 24) return `${hours} ชั่วโมงที่แล้ว`

  const days = Math.round(hours / 24)
  if (days === 1) return 'เมื่อวาน'
  if (days < 7) return `${days} วันก่อน`
  return formatDate(iso)
}

export function formatQty(value: number | null): string {
  if (value === null) return '—'
  return `${value} ชิ้น`
}

export function formatPercent(value: number | null): string {
  if (value === null) return '—'
  return `${Math.round(value * 100)}%`
}
