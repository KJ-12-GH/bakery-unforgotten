/** Hash-route <-> Route object conversion for the lightweight router. */
import type { Route } from '../types'

export const DEFAULT_ROUTE: Route = { name: 'dashboard' }

export function routeToHash(route: Route): string {
  switch (route.name) {
    case 'dashboard':
      return '#/dashboard'
    case 'orders':
      return route.orderId ? `#/orders/${route.orderId}` : '#/orders'
    case 'packing':
      return route.orderId ? `#/packing/${route.orderId}` : '#/packing'
    case 'result':
      return `#/result/${route.orderId}`
    case 'handover':
      return route.orderId ? `#/handover/${route.orderId}` : '#/handover'
    case 'history':
      return route.orderId ? `#/history/${route.orderId}` : '#/history'
    case 'settings':
      return '#/settings'
  }
}

export function parseHash(hash: string): Route {
  const clean = hash.replace(/^#\/?/, '').trim()
  if (!clean) return DEFAULT_ROUTE

  const [segment, param] = clean.split('/')
  const orderId = param ? decodeURIComponent(param) : undefined

  switch (segment) {
    case 'dashboard':
      return { name: 'dashboard' }
    case 'orders':
      return { name: 'orders', orderId }
    case 'packing':
      return { name: 'packing', orderId }
    case 'result':
      return orderId ? { name: 'result', orderId } : { name: 'orders' }
    case 'handover':
      return { name: 'handover', orderId }
    case 'history':
      return { name: 'history', orderId }
    case 'settings':
      return { name: 'settings' }
    default:
      return DEFAULT_ROUTE
  }
}
