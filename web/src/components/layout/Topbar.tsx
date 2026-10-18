import { useEffect, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { useData } from '../../store/DataContext'
import { useNav } from '../../store/NavContext'
import { useToast } from '../../store/ToastContext'
import { buildNotifications } from '../../utils/notifications'
import { relativeTime } from '../../utils/format'
import { Icon } from '../icons/Icon'
import type { IconName } from '../icons/Icon'
import { routeTitle, ROUTE_SUBTITLE } from './nav-config'
import { cx } from '../../utils/cx'

interface TopbarProps {
  onOpenNav: () => void
}

const TONE_ICON: Record<string, IconName> = {
  error: 'x-circle',
  warning: 'alert-triangle',
  success: 'check-circle',
  info: 'info',
}

export function Topbar({ onOpenNav }: TopbarProps) {
  const { route, navigate } = useNav()
  const { state, staff } = useData()
  const { show } = useToast()

  const [query, setQuery] = useState('')
  const [notifOpen, setNotifOpen] = useState(false)
  const [readIds, setReadIds] = useState<string[]>([])
  const notifRef = useRef<HTMLDivElement>(null)

  const notifications = buildNotifications(state.orders)
  const unread = notifications.filter((item) => !readIds.includes(item.id))

  useEffect(() => {
    if (!notifOpen) return
    const onPointerDown = (event: MouseEvent) => {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setNotifOpen(false)
      }
    }
    document.addEventListener('mousedown', onPointerDown)
    return () => document.removeEventListener('mousedown', onPointerDown)
  }, [notifOpen])

  const openNotification = (id: string) => {
    const separator = id.indexOf('-')
    const kind = id.slice(0, separator)
    const orderId = id.slice(separator + 1)
    setReadIds((prev) => (prev.includes(id) ? prev : [...prev, id]))
    setNotifOpen(false)
    navigate(kind === 'ready' ? { name: 'handover', orderId } : { name: 'packing', orderId })
  }

  const submitSearch = (event: FormEvent) => {
    event.preventDefault()
    const term = query.trim().toUpperCase()
    if (!term) return
    const match = state.orders.find((order) => order.id.toUpperCase().includes(term))
    if (match) {
      navigate({ name: 'orders', orderId: match.id })
      setQuery('')
    } else {
      show('warning', 'ไม่พบออเดอร์', `ไม่พบออเดอร์ที่ตรงกับ "${query.trim()}"`)
    }
  }

  return (
    <header className="topbar">
      <button
        type="button"
        className="icon-btn topbar__menu-btn"
        onClick={onOpenNav}
        aria-label="เปิดเมนู"
      >
        <Icon name="menu" size={19} />
      </button>

      <div className="topbar__breadcrumb">
        <nav className="topbar__crumbs" aria-label="breadcrumb">
          <span>BakeCheck</span>
          <span className="sep" aria-hidden="true">
            /
          </span>
          <span>{routeTitle(route)}</span>
        </nav>
        {ROUTE_SUBTITLE[route.name] && route.name !== 'packing' && (
          <p className="topbar__title">{ROUTE_SUBTITLE[route.name]}</p>
        )}
      </div>

      <div className="topbar__actions">
        <form className="search topbar__search" onSubmit={submitSearch} role="search">
          <Icon name="search" size={17} className="search__icon" />
          <label className="visually-hidden" htmlFor="global-search">
            ค้นหารหัสออเดอร์
          </label>
          <input
            id="global-search"
            className="input"
            type="search"
            value={query}
            placeholder="ค้นหารหัสออเดอร์ เช่น BK-1001"
            onChange={(event) => setQuery(event.target.value)}
          />
        </form>

        <div className="dropdown" ref={notifRef}>
          <button
            type="button"
            className="icon-btn"
            aria-label={`การแจ้งเตือน${unread.length ? ` (${unread.length} ใหม่)` : ''}`}
            aria-expanded={notifOpen}
            aria-haspopup="dialog"
            onClick={() => setNotifOpen((prev) => !prev)}
          >
            <Icon name="bell" size={19} />
            {unread.length > 0 && <span className="icon-btn__dot" aria-hidden="true" />}
          </button>

          {notifOpen && (
            <div className="panel" role="dialog" aria-label="การแจ้งเตือน">
              <div className="panel__header">
                <span>การแจ้งเตือน</span>
                <span className="meta-xs">{unread.length} ใหม่</span>
              </div>
              <div className="panel__list">
                {notifications.length === 0 && (
                  <p className="meta" style={{ padding: 'var(--space-4)' }}>
                    ไม่มีการแจ้งเตือน
                  </p>
                )}
                {notifications.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    className="panel__item"
                    onClick={() => openNotification(item.id)}
                  >
                    <span className={cx('panel__item-icon')}>
                      <Icon name={TONE_ICON[item.tone]} size={17} />
                    </span>
                    <span>
                      <span className="text-strong" style={{ display: 'block' }}>
                        {item.title}
                      </span>
                      <span className="meta-xs">{item.detail}</span>
                      <span className="meta-xs" style={{ display: 'block' }}>
                        {relativeTime(item.at)}
                      </span>
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        <button
          type="button"
          className="icon-btn"
          onClick={() => navigate({ name: 'settings' })}
          aria-label={`โปรไฟล์ ${staff.name}`}
          title={staff.name}
        >
          <span className="avatar" style={{ width: 26, height: 26, fontSize: 11 }}>
            {staff.initials}
          </span>
        </button>
      </div>
    </header>
  )
}
