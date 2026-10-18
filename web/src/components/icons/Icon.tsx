import type { ReactNode, SVGProps } from 'react'

export type IconName =
  | 'dashboard'
  | 'orders'
  | 'scan'
  | 'history'
  | 'settings'
  | 'search'
  | 'bell'
  | 'plus'
  | 'minus'
  | 'arrow-right'
  | 'arrow-left'
  | 'chevron-right'
  | 'chevron-down'
  | 'check'
  | 'check-circle'
  | 'x'
  | 'alert-triangle'
  | 'alert-circle'
  | 'info'
  | 'x-circle'
  | 'camera'
  | 'refresh'
  | 'edit'
  | 'package'
  | 'truck'
  | 'menu'
  | 'lock'
  | 'user'
  | 'store'
  | 'clock'
  | 'eye'
  | 'shield'
  | 'flask'
  | 'inbox'

const PATHS: Record<IconName, ReactNode> = {
  dashboard: (
    <>
      <rect x="3" y="3" width="7.5" height="9" rx="2" />
      <rect x="13.5" y="3" width="7.5" height="5.5" rx="2" />
      <rect x="13.5" y="12" width="7.5" height="9" rx="2" />
      <rect x="3" y="15.5" width="7.5" height="5.5" rx="2" />
    </>
  ),
  orders: (
    <>
      <rect x="4" y="5" width="16" height="16" rx="2.5" />
      <path d="M9 5V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1" />
      <path d="M9 12h6" />
      <path d="M9 16h4" />
    </>
  ),
  scan: (
    <>
      <path d="M4 8V6.5A2.5 2.5 0 0 1 6.5 4H8" />
      <path d="M16 4h1.5A2.5 2.5 0 0 1 20 6.5V8" />
      <path d="M20 16v1.5a2.5 2.5 0 0 1-2.5 2.5H16" />
      <path d="M8 20H6.5A2.5 2.5 0 0 1 4 17.5V16" />
      <path d="M7 12h10" />
      <path d="M12 7v10" />
    </>
  ),
  history: (
    <>
      <path d="M3.5 12a8.5 8.5 0 1 0 2.8-6.3" />
      <path d="M3.5 4v4.5H8" />
      <path d="M12 8v4.5l3 1.8" />
    </>
  ),
  settings: (
    <>
      <path d="M4 21v-6" />
      <path d="M4 11V3" />
      <path d="M12 21v-8" />
      <path d="M12 9V3" />
      <path d="M20 21v-5" />
      <path d="M20 12V3" />
      <path d="M1.5 15h5" />
      <path d="M9.5 9h5" />
      <path d="M17.5 16h5" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="7" />
      <path d="m20 20-3.6-3.6" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8.5a6 6 0 1 0-12 0c0 6.5-2.5 8.5-2.5 8.5h17S18 15 18 8.5" />
      <path d="M13.7 20.5a2 2 0 0 1-3.4 0" />
    </>
  ),
  plus: (
    <>
      <path d="M12 5v14" />
      <path d="M5 12h14" />
    </>
  ),
  minus: <path d="M5 12h14" />,
  'arrow-right': (
    <>
      <path d="M4 12h15" />
      <path d="m13 6 6 6-6 6" />
    </>
  ),
  'arrow-left': (
    <>
      <path d="M20 12H5" />
      <path d="m11 18-6-6 6-6" />
    </>
  ),
  'chevron-right': <path d="m9 5.5 6.5 6.5L9 18.5" />,
  'chevron-down': <path d="m5.5 9 6.5 6.5L18.5 9" />,
  check: <path d="M20 6.5 9.5 17 4 11.5" />,
  'check-circle': (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m8.2 12.4 2.6 2.6 5-5.4" />
    </>
  ),
  x: (
    <>
      <path d="M18 6 6 18" />
      <path d="m6 6 12 12" />
    </>
  ),
  'alert-triangle': (
    <>
      <path d="M10.3 3.9 1.9 18a2 2 0 0 0 1.7 3h16.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
      <path d="M12 9.5v4" />
      <path d="M12 17.2h.01" />
    </>
  ),
  'alert-circle': (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.8v5" />
      <path d="M12 16.2h.01" />
    </>
  ),
  info: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5.2" />
      <path d="M12 7.8h.01" />
    </>
  ),
  'x-circle': (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m15 9-6 6" />
      <path d="m9 9 6 6" />
    </>
  ),
  camera: (
    <>
      <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8.5a2 2 0 0 1 2-2h3l1.8-2.5h6.4L17 6.5h3a2 2 0 0 1 2 2Z" />
      <circle cx="12" cy="13" r="4" />
    </>
  ),
  refresh: (
    <>
      <path d="M20.5 11a8.5 8.5 0 1 0-2.4 6.1" />
      <path d="M20.5 4.5V11H14" />
    </>
  ),
  edit: (
    <>
      <path d="M12.5 20H21" />
      <path d="M16.6 3.6a2.1 2.1 0 0 1 3 3L7.5 18.6 3.5 20l1.4-4Z" />
    </>
  ),
  package: (
    <>
      <path d="m12 2.5 8.5 4.7v9.6L12 21.5l-8.5-4.7V7.2Z" />
      <path d="m3.5 7.2 8.5 4.8 8.5-4.8" />
      <path d="M12 21.5v-9.5" />
    </>
  ),
  truck: (
    <>
      <path d="M3 16.5V6.5A1.5 1.5 0 0 1 4.5 5H14v11.5" />
      <path d="M14 9h3.6l3.4 3.4v4.1h-7" />
      <circle cx="7.5" cy="18" r="2" />
      <circle cx="17" cy="18" r="2" />
    </>
  ),
  menu: (
    <>
      <path d="M4 7h16" />
      <path d="M4 12h16" />
      <path d="M4 17h16" />
    </>
  ),
  lock: (
    <>
      <rect x="4" y="10.5" width="16" height="10.5" rx="2.5" />
      <path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8" r="4" />
      <path d="M4.5 21a7.5 7.5 0 0 1 15 0" />
    </>
  ),
  store: (
    <>
      <path d="M3.5 9.5 5.2 4h13.6l1.7 5.5" />
      <path d="M4.5 9.5V20h15V9.5" />
      <path d="M9.5 20v-6h5v6" />
    </>
  ),
  clock: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.2V12l3.2 2" />
    </>
  ),
  eye: (
    <>
      <path d="M2.5 12S6 6.2 12 6.2 21.5 12 21.5 12 18 17.8 12 17.8 2.5 12 2.5 12Z" />
      <circle cx="12" cy="12" r="3" />
    </>
  ),
  shield: (
    <>
      <path d="M12 3 5 5.8v6c0 4.4 2.9 7.6 7 9.2 4.1-1.6 7-4.8 7-9.2v-6Z" />
      <path d="m9 12 2 2 4.2-4.4" />
    </>
  ),
  flask: (
    <>
      <path d="M9.5 3h5" />
      <path d="M10.5 3v6.2L5.4 18.3A2 2 0 0 0 7.2 21.2h9.6a2 2 0 0 0 1.8-2.9L13.5 9.2V3" />
      <path d="M7.6 15h8.8" />
    </>
  ),
  inbox: (
    <>
      <path d="M4 13.5h4l1.6 2.5h4.8l1.6-2.5H20" />
      <path d="M6.2 4.5h11.6L20 13.5V19a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 19v-5.5Z" />
    </>
  ),
}

interface IconProps extends Omit<SVGProps<SVGSVGElement>, 'name'> {
  name: IconName
  size?: number
}

export function Icon({ name, size = 20, ...rest }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      {...rest}
    >
      {PATHS[name]}
    </svg>
  )
}
