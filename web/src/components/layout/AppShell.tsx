import { useEffect, useState } from 'react'
import { useNav } from '../../store/NavContext'
import { ToastRegion } from '../ui/ToastRegion'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { PageRouter } from './PageRouter'

export function AppShell() {
  const { route } = useNav()
  const [navOpen, setNavOpen] = useState(false)

  // Reset scroll whenever the route changes. (The mobile drawer is already
  // closed by the navigation handlers that triggered the route change.)
  useEffect(() => {
    window.scrollTo({ top: 0 })
  }, [route])

  return (
    <div className="app-shell">
      <a className="skip-link" href="#main-content">
        ข้ามไปยังเนื้อหาหลัก
      </a>

      <Sidebar open={navOpen} onClose={() => setNavOpen(false)} />

      {navOpen && (
        <button
          type="button"
          className="nav-overlay"
          aria-label="ปิดเมนู"
          onClick={() => setNavOpen(false)}
        />
      )}

      <div className="main">
        <Topbar onOpenNav={() => setNavOpen(true)} />
        <main className="content" id="main-content">
          <PageRouter />
        </main>
      </div>

      <ToastRegion />
    </div>
  )
}
