import { useMemo, useState } from 'react'
import { getProduct } from '../data/products'
import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import type { Order } from '../types'
import { Icon } from '../components/icons/Icon'
import { Card, CardBody } from '../components/ui/Card'
import { EmptyState } from '../components/ui/EmptyState'
import { SearchInput } from '../components/ui/SearchInput'
import { Button } from '../components/ui/Button'
import { OrderTable } from '../components/orders/OrderTable'
import { OrderDetailDrawer } from '../components/orders/OrderDetailDrawer'

type FilterKey = 'all' | 'pending' | 'active' | 'passed' | 'problem' | 'handed_over'

interface FilterOption {
  key: FilterKey
  label: string
  match: (order: Order) => boolean
}

const FILTERS: FilterOption[] = [
  { key: 'all', label: 'ทั้งหมด', match: () => true },
  { key: 'pending', label: 'รอตรวจสอบ', match: (order) => order.status === 'pending' },
  { key: 'active', label: 'กำลังตรวจสอบ', match: (order) => order.status === 'verifying' },
  {
    key: 'passed',
    label: 'ตรวจสอบผ่าน',
    match: (order) => order.status === 'passed',
  },
  {
    key: 'problem',
    label: 'พบข้อผิดพลาด',
    match: (order) => order.status === 'mismatch' || order.status === 'review',
  },
  { key: 'handed_over', label: 'ส่งมอบแล้ว', match: (order) => order.status === 'handed_over' },
]

function matchesQuery(order: Order, query: string): boolean {
  const term = query.trim().toLowerCase()
  if (!term) return true
  if (order.id.toLowerCase().includes(term)) return true
  if (order.customer.toLowerCase().includes(term)) return true
  return order.items.some((item) => {
    const product = getProduct(item.productId)
    return (
      product.name.toLowerCase().includes(term) || product.nameEn.toLowerCase().includes(term)
    )
  })
}

export function OrdersPage({ orderId }: { orderId?: string }) {
  const { state, getLatestScan } = useData()
  const { navigate } = useNav()
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<FilterKey>('all')

  const activeFilter = FILTERS.find((option) => option.key === filter) ?? FILTERS[0]

  const filtered = useMemo(() => {
    return state.orders
      .filter((order) => activeFilter.match(order) && matchesQuery(order, query))
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
  }, [state.orders, activeFilter, query])

  const selectedOrder = orderId ? state.orders.find((order) => order.id === orderId) ?? null : null

  const goVerify = (id: string) => navigate({ name: 'packing', orderId: id })
  const goHandover = (id: string) => navigate({ name: 'handover', orderId: id })

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">จัดการออเดอร์</h1>
          <p className="page-header__subtitle">
            ค้นหา ตรวจสอบรายละเอียด และเลือกออเดอร์เพื่อเข้าสู่ขั้นตอนตรวจสอบสินค้า
          </p>
        </div>
        <div className="page-header__actions">
          <Button variant="primary" icon="scan" onClick={() => navigate({ name: 'packing' })}>
            เริ่มตรวจสอบออเดอร์
          </Button>
        </div>
      </header>

      <div className="orders-toolbar">
        <div className="toolbar__search">
          <SearchInput
            id="orders-search"
            label="ค้นหาออเดอร์"
            value={query}
            onChange={setQuery}
            placeholder="ค้นหารหัสออเดอร์ ลูกค้า หรือชื่อสินค้า"
          />
        </div>
        <div className="toolbar__spacer" />
        <p className="result-count">
          พบ <strong>{filtered.length}</strong> ออเดอร์
        </p>
      </div>

      <div className="chip-row" style={{ marginBottom: 'var(--space-4)' }} role="group" aria-label="กรองตามสถานะ">
        {FILTERS.map((option) => {
          const count = state.orders.filter(option.match).length
          return (
            <button
              key={option.key}
              type="button"
              className="chip"
              aria-pressed={filter === option.key}
              onClick={() => setFilter(option.key)}
            >
              {option.label}
              <span className="chip__count">{count}</span>
            </button>
          )
        })}
      </div>

      <Card>
        <CardBody tight>
          {filtered.length === 0 ? (
            <EmptyState
              icon="inbox"
              title="ไม่พบออเดอร์ที่ตรงกับเงื่อนไข"
              text="ลองล้างคำค้นหาหรือเลือกตัวกรองสถานะอื่น"
              action={
                <Button
                  variant="secondary"
                  icon="refresh"
                  onClick={() => {
                    setQuery('')
                    setFilter('all')
                  }}
                >
                  ล้างตัวกรอง
                </Button>
              }
            />
          ) : (
            <OrderTable
              orders={filtered}
              selectedId={orderId}
              onOpen={(id) => navigate({ name: 'orders', orderId: id })}
              onVerify={goVerify}
              onHandover={goHandover}
            />
          )}
        </CardBody>
      </Card>

      <div className="notice" style={{ marginTop: 'var(--space-5)' }}>
        <Icon name="info" size={17} className="notice__icon" />
        <span>
          ออเดอร์ที่ยังไม่ผ่านการตรวจสอบจะไม่สามารถส่งมอบได้ — เลือก “ตรวจสอบ” เพื่อเข้าสู่สถานีตรวจสอบสินค้า
        </span>
      </div>

      <OrderDetailDrawer
        order={selectedOrder}
        latestScan={selectedOrder ? getLatestScan(selectedOrder.id) : undefined}
        onClose={() => navigate({ name: 'orders' })}
        onVerify={(id) => goVerify(id)}
        onHandover={(id) => goHandover(id)}
        onViewHistory={(id) => navigate({ name: 'history', orderId: id })}
      />
    </>
  )
}
