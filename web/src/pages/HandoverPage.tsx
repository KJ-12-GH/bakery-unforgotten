import { useState } from 'react'
import { getProduct } from '../data/products'
import { DRIVERS } from '../data/staff'
import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import { useToast } from '../store/ToastContext'
import type { Order } from '../types'
import { formatDateTime, relativeTime } from '../utils/format'
import { orderTotalQty } from '../utils/order'
import { Icon } from '../components/icons/Icon'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Card, CardBody } from '../components/ui/Card'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { EmptyState } from '../components/ui/EmptyState'

function ProductLine({ order }: { order: Order }) {
  return (
    <ul className="product-list">
      {order.items.map((item) => {
        const product = getProduct(item.productId)
        return (
          <li key={item.productId} className="row row--between">
            <span className="meta">
              {product.emoji} {product.name}
            </span>
            <span className="qty">{item.expectedQty} ชิ้น</span>
          </li>
        )
      })}
    </ul>
  )
}

export function HandoverPage({ orderId }: { orderId?: string }) {
  const { state, handOver, getLatestScan } = useData()
  const { navigate } = useNav()
  const { show } = useToast()

  const [targetId, setTargetId] = useState<string | null>(null)
  const [driver, setDriver] = useState(DRIVERS[0])

  const ready = state.orders
    .filter((order) => order.status === 'passed' && order.handover === 'ready')
    .sort((a, b) => {
      if (orderId) {
        if (a.id === orderId) return -1
        if (b.id === orderId) return 1
      }
      return b.verifiedAt?.localeCompare(a.verifiedAt ?? '') ?? 0
    })

  const handedOver = state.orders
    .filter((order) => order.handover === 'handed_over')
    .sort((a, b) => (b.handedOverAt ?? '').localeCompare(a.handedOverAt ?? ''))
    .slice(0, 4)

  const target = targetId ? state.orders.find((order) => order.id === targetId) ?? null : null

  const confirmHandover = () => {
    if (!target) return
    handOver(target.id, driver)
    setTargetId(null)
    show('success', 'ส่งมอบสำเร็จ', `${target.id} ส่งมอบให้ ${driver} แล้ว`)
  }

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ส่งมอบสินค้า</h1>
          <p className="page-header__subtitle">
            ยืนยันการรับมอบออเดอร์ที่ตรวจสอบผ่านแล้วให้พนักงานขับรถ
          </p>
        </div>
        <div className="page-header__actions">
          <Button variant="ghost" icon="orders" onClick={() => navigate({ name: 'orders' })}>
            ไปที่จัดการออเดอร์
          </Button>
        </div>
      </header>

      <section>
        <div className="dashboard-section__head" style={{ marginBottom: 'var(--space-4)' }}>
          <div>
            <h2 className="section-title">พร้อมส่งมอบ</h2>
            <p className="meta">เฉพาะออเดอร์ที่ยืนยันผลตรวจสอบแล้วเท่านั้น</p>
          </div>
          <Badge tone={ready.length > 0 ? 'success' : 'neutral'} dot>
            {ready.length} ออเดอร์
          </Badge>
        </div>

        {ready.length === 0 ? (
          <Card>
            <CardBody>
              <EmptyState
                icon="truck"
                title="ยังไม่มีออเดอร์ที่พร้อมส่งมอบ"
                text="ออเดอร์จะปรากฏที่นี่หลังผ่านการยืนยันผลตรวจสอบจำนวนสินค้าแล้ว"
                action={
                  <Button
                    variant="primary"
                    icon="scan"
                    onClick={() => navigate({ name: 'packing' })}
                  >
                    ไปตรวจสอบสินค้า
                  </Button>
                }
              />
            </CardBody>
          </Card>
        ) : (
          <div className="handover-grid">
            {ready.map((order) => {
              const scan = getLatestScan(order.id)
              const isTarget = order.id === orderId
              return (
                <article
                  key={order.id}
                  className="handover-card"
                  style={isTarget ? { borderColor: 'var(--color-terra)' } : undefined}
                >
                  <div className="handover-card__head">
                    <div>
                      <p className="handover-card__id">{order.id}</p>
                      <p className="meta-xs">{order.customer}</p>
                    </div>
                    <Badge tone="success" dot>
                      พร้อมส่งมอบ
                    </Badge>
                  </div>

                  <ProductLine order={order} />

                  <div className="def-list">
                    <div className="def-row">
                      <span className="def-row__key">จำนวนรวม</span>
                      <span className="def-row__value">{orderTotalQty(order)} ชิ้น</span>
                    </div>
                    <div className="def-row">
                      <span className="def-row__key">ยืนยันผลเมื่อ</span>
                      <span className="def-row__value">
                        {order.verifiedAt ? formatDateTime(order.verifiedAt) : '—'}
                        <span className="meta-xs" style={{ display: 'block', fontWeight: 400 }}>
                          {order.verifiedAt ? relativeTime(order.verifiedAt) : ''}
                        </span>
                      </span>
                    </div>
                    <div className="def-row">
                      <span className="def-row__key">รหัสผลตรวจสอบ</span>
                      <span className="def-row__value mono">{scan?.id ?? '—'}</span>
                    </div>
                  </div>

                  <div className="row" style={{ gap: 'var(--space-2)' }}>
                    <Button
                      variant="ghost"
                      size="sm"
                      icon="shield"
                      onClick={() => navigate({ name: 'result', orderId: order.id })}
                    >
                      ดูผลตรวจสอบ
                    </Button>
                    <div className="toolbar__spacer" />
                    <Button
                      variant="success"
                      icon="truck"
                      onClick={() => {
                        setDriver(DRIVERS[0])
                        setTargetId(order.id)
                      }}
                    >
                      ยืนยันการส่งมอบ
                    </Button>
                  </div>
                </article>
              )
            })}
          </div>
        )}
      </section>

      {handedOver.length > 0 && (
        <section className="dashboard-section">
          <div className="dashboard-section__head">
            <h2 className="section-title">ส่งมอบล่าสุด</h2>
            <span className="meta">บันทึกการส่งมอบที่เสร็จสิ้นแล้ว</span>
          </div>
          <Card>
            <CardBody tight>
              <div className="table-wrap">
                <table className="table" style={{ minWidth: 640 }}>
                  <thead>
                    <tr>
                      <th scope="col">รหัสออเดอร์</th>
                      <th scope="col">ลูกค้า</th>
                      <th scope="col">จำนวนรวม</th>
                      <th scope="col">ส่งมอบเมื่อ</th>
                      <th scope="col">พนักงานขับรถ</th>
                      <th scope="col" style={{ textAlign: 'right' }}>
                        การดำเนินการ
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {handedOver.map((order) => (
                      <tr key={order.id}>
                        <td className="mono text-strong">{order.id}</td>
                        <td className="meta">{order.customer}</td>
                        <td className="table__num">{orderTotalQty(order)} ชิ้น</td>
                        <td className="meta">
                          {order.handedOverAt ? formatDateTime(order.handedOverAt) : '—'}
                        </td>
                        <td>{order.driver ?? '—'}</td>
                        <td>
                          <div className="table__actions">
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => navigate({ name: 'history', orderId: order.id })}
                            >
                              ประวัติ
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardBody>
          </Card>
        </section>
      )}

      <div className="notice" style={{ marginTop: 'var(--space-5)' }}>
        <Icon name="lock" size={17} className="notice__icon" />
        <span>
          ระบบจะไม่อนุญาตให้ส่งมอบออเดอร์ที่ยังไม่ผ่านการตรวจสอบ
          หรือที่ส่งมอบไปแล้ว เพื่อป้องกันการส่งมอบซ้ำ
        </span>
      </div>

      <ConfirmDialog
        open={!!target}
        tone="success"
        icon="truck"
        title="ยืนยันการส่งมอบออเดอร์"
        description={
          target
            ? `ยืนยันว่าพนักงานขับรถได้รับออเดอร์ ${target.id} แล้ว และจำนวนสินค้าครบถ้วน`
            : undefined
        }
        confirmLabel="ยืนยันการส่งมอบ"
        confirmVariant="success"
        onConfirm={confirmHandover}
        onCancel={() => setTargetId(null)}
      >
        {target && (
          <div className="stack">
            <div className="def-list">
              <div className="def-row">
                <span className="def-row__key">ออเดอร์</span>
                <span className="def-row__value mono">{target.id}</span>
              </div>
              <div className="def-row">
                <span className="def-row__key">ลูกค้า</span>
                <span className="def-row__value">{target.customer}</span>
              </div>
              <div className="def-row">
                <span className="def-row__key">จำนวนรวม</span>
                <span className="def-row__value">{orderTotalQty(target)} ชิ้น</span>
              </div>
            </div>

            <div className="field">
              <label className="field__label" htmlFor="driver-select">
                พนักงานขับรถผู้รับมอบ
              </label>
              <select
                id="driver-select"
                className="select"
                value={driver}
                onChange={(event) => setDriver(event.target.value)}
              >
                {DRIVERS.map((name) => (
                  <option key={name} value={name}>
                    {name}
                  </option>
                ))}
              </select>
              <span className="field__hint">
                เมื่อยืนยันแล้ว สถานะออเดอร์จะเปลี่ยนเป็น “ส่งมอบแล้ว” และไม่สามารถส่งมอบซ้ำได้
              </span>
            </div>
          </div>
        )}
      </ConfirmDialog>
    </>
  )
}
