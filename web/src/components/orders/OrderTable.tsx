import { getProduct } from '../../data/products'
import type { Order } from '../../types'
import { relativeTime } from '../../utils/format'
import { orderTotalQty } from '../../utils/order'
import { Button } from '../ui/Button'
import { StatusBadge } from '../ui/StatusBadge'
import { primaryActionFor } from './orderActions'

export function ProductSummary({ order, max = 3 }: { order: Order; max?: number }) {
  const shown = order.items.slice(0, max)
  const rest = order.items.length - shown.length

  return (
    <ul className="product-list">
      {shown.map((item) => {
        const product = getProduct(item.productId)
        return (
          <li key={item.productId}>
            <span aria-hidden="true">{product.emoji}</span>
            <span className="product-cell__name" style={{ fontSize: 'var(--text-sm)' }}>
              {product.name}
            </span>
            <span className="qty">×{item.expectedQty}</span>
          </li>
        )
      })}
      {rest > 0 && <li className="meta-xs">และอีก {rest} รายการ</li>}
    </ul>
  )
}

interface OrderListProps {
  orders: Order[]
  onOpen: (orderId: string) => void
  onVerify: (orderId: string) => void
  onHandover: (orderId: string) => void
  selectedId?: string
}

export function OrderTable({
  orders,
  onOpen,
  onVerify,
  onHandover,
  selectedId,
}: OrderListProps) {
  const runAction = (order: Order, onOpenRow: boolean) => {
    if (onOpenRow) {
      onOpen(order.id)
      return
    }
    const action = primaryActionFor(order)
    if (action.kind === 'verify') {
      onVerify(order.id)
    } else if (action.kind === 'handover') {
      onHandover(order.id)
    } else {
      onOpen(order.id)
    }
  }

  return (
    <div className="table-wrap table-wrap--cards">
      <table className="table">
        <caption className="visually-hidden">รายการออเดอร์ทั้งหมด</caption>
        <thead>
          <tr>
            <th scope="col">รหัสออเดอร์</th>
            <th scope="col">รายการสินค้า</th>
            <th scope="col">จำนวนที่สั่ง</th>
            <th scope="col">สถานะ</th>
            <th scope="col">เวลาที่อัปเดต</th>
            <th scope="col" style={{ textAlign: 'right' }}>
              การดำเนินการ
            </th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => {
            const action = primaryActionFor(order)
            const total = orderTotalQty(order)
            return (
              <tr key={order.id} className={selectedId === order.id ? 'is-selected' : undefined}>
                <td>
                  <button
                    type="button"
                    className="mono text-strong"
                    style={{
                      border: 0,
                      background: 'transparent',
                      padding: 0,
                      color: 'var(--color-wood)',
                    }}
                    onClick={() => onOpen(order.id)}
                  >
                    {order.id}
                  </button>
                  <div className="meta-xs">{order.customer}</div>
                </td>
                <td>
                  <ProductSummary order={order} max={2} />
                </td>
                <td className="table__num">
                  <strong>{total}</strong> <span className="meta-xs">ชิ้น</span>
                  <div className="meta-xs">{order.items.length} รายการ</div>
                </td>
                <td>
                  <StatusBadge order={order} />
                </td>
                <td className="meta">{relativeTime(order.updatedAt)}</td>
                <td>
                  <div className="table__actions">
                    <Button size="sm" variant="ghost" onClick={() => onOpen(order.id)}>
                      รายละเอียด
                    </Button>
                    <Button
                      size="sm"
                      variant={
                        action.kind === 'handover'
                          ? 'success'
                          : action.kind === 'verify'
                            ? 'primary'
                            : 'secondary'
                      }
                      onClick={() => runAction(order, action.kind === 'details')}
                    >
                      {action.label}
                    </Button>
                  </div>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>

      <div className="order-cards">
        {orders.map((order) => {
          const action = primaryActionFor(order)
          const total = orderTotalQty(order)
          return (
            <article key={order.id} className="order-card">
              <div className="order-card__top">
                <div>
                  <p className="order-card__id">{order.id}</p>
                  <p className="meta-xs">{order.customer}</p>
                </div>
                <StatusBadge order={order} />
              </div>

              <ProductSummary order={order} max={4} />

              <div className="order-card__grid">
                <div>
                  <p className="order-card__label">จำนวนที่สั่ง</p>
                  <p className="order-card__value">{total} ชิ้น</p>
                </div>
                <div>
                  <p className="order-card__label">เวลาที่อัปเดต</p>
                  <p className="order-card__value">{relativeTime(order.updatedAt)}</p>
                </div>
                <div>
                  <p className="order-card__label">จำนวนสินค้า</p>
                  <p className="order-card__value">{order.items.length} รายการ</p>
                </div>
                <div>
                  <p className="order-card__label">การส่งมอบ</p>
                  <p className="order-card__value">
                    {order.handover === 'handed_over'
                      ? 'ส่งมอบแล้ว'
                      : order.handover === 'ready'
                        ? 'พร้อมส่งมอบ'
                        : 'ยังไม่พร้อม'}
                  </p>
                </div>
              </div>

              <div className="row" style={{ gap: 'var(--space-2)' }}>
                <Button size="sm" variant="ghost" block onClick={() => onOpen(order.id)}>
                  รายละเอียด
                </Button>
                <Button
                  size="sm"
                  block
                  variant={
                    action.kind === 'handover'
                      ? 'success'
                      : action.kind === 'verify'
                        ? 'primary'
                        : 'secondary'
                  }
                  onClick={() => runAction(order, action.kind === 'details')}
                >
                  {action.label}
                </Button>
              </div>
            </article>
          )
        })}
      </div>
    </div>
  )
}
