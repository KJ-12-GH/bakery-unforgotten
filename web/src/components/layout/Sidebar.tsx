import { useData } from '../../store/DataContext'
import { useNav } from '../../store/NavContext'
import { Icon } from '../icons/Icon'
import { activeNav, isNavActive, NAV_ITEMS } from './nav-config'
import { cx } from '../../utils/cx'

interface SidebarProps {
  open: boolean
  onClose: () => void
}

const NEEDS_CHECK = new Set(['pending', 'verifying', 'mismatch', 'review'])

export function Sidebar({ open, onClose }: SidebarProps) {
  const { route, navigate } = useNav()
  const { state, staff } = useData()
  const active = activeNav(route)

  const counts: Record<string, number> = {
    orders: state.orders.length,
    packing: state.orders.filter((order) => NEEDS_CHECK.has(order.status)).length,
  }

  return (
    <aside className={cx('sidebar', open && 'sidebar--open')} aria-label="เมนูหลัก">
      <div className="sidebar__brand">
        <span className="brand__mark" aria-hidden="true">
          <Icon name="store" size={22} />
        </span>
        <div>
          <p className="brand__name">BakeCheck</p>
          <p className="brand__tagline">ตรวจสอบออเดอร์ก่อนส่งมอบ</p>
        </div>
      </div>

      <nav aria-label="การนำทางหลัก">
        <p className="sidebar__section-label">เมนู</p>
        <ul className="nav">
          {NAV_ITEMS.map((item) => {
            const count = counts[item.name]
            return (
              <li key={item.name}>
                <button
                  type="button"
                  className="nav__item"
                  aria-current={isNavActive(active, item.name) ? 'page' : undefined}
                  onClick={() => {
                    navigate({ name: item.name })
                    onClose()
                  }}
                >
                  <Icon name={item.icon} size={19} className="nav__item-icon" />
                  <span className="nav__item-label">{item.label}</span>
                  {count !== undefined && count > 0 && (
                    <span className="nav__item-count">{count}</span>
                  )}
                </button>
              </li>
            )
          })}
        </ul>
      </nav>

      <div className="sidebar__spacer" />

      <div className="profile-card">
        <span className="avatar" aria-hidden="true">
          {staff.initials}
        </span>
        <div className="profile-card__meta">
          <p className="profile-card__name">{staff.name}</p>
          <p className="profile-card__role">{staff.role}</p>
        </div>
      </div>
    </aside>
  )
}
