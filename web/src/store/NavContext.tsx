/* eslint-disable react/only-export-components -- context module exports its provider and hook together */
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import type { Route } from '../types'
import { parseHash, routeToHash } from '../utils/route'

interface NavApi {
  route: Route
  navigate: (route: Route) => void
}

const NavContext = createContext<NavApi | null>(null)

export function NavProvider({ children }: { children: ReactNode }) {
  const [route, setRoute] = useState<Route>(() => parseHash(window.location.hash))

  useEffect(() => {
    const onHashChange = () => setRoute(parseHash(window.location.hash))
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  const navigate = useCallback((next: Route) => {
    const hash = routeToHash(next)
    if (window.location.hash !== hash) {
      window.location.hash = hash
    }
    setRoute(next)
  }, [])

  const value = useMemo(() => ({ route, navigate }), [route, navigate])

  return <NavContext.Provider value={value}>{children}</NavContext.Provider>
}

export function useNav(): NavApi {
  const ctx = useContext(NavContext)
  if (!ctx) throw new Error('useNav must be used within a NavProvider')
  return ctx
}
