import { useEffect } from 'react'
import { createPortal } from 'react-dom'
import { getProduct } from '../../data/products'
import type { Order, ScanRecord } from '../../types'
import { formatDateTime, relativeTime } from '../../utils/format'
import { HANDOVER_LABEL, handoverTone, ITEM_STATUS_LABEL, itemStatusTone } from '../../utils/labels'
import { orderTotalQty } from '../../utils/order'
import { Icon } from '../icons/Icon'
import { Badge } from '../ui/Badge'
import { Button } from '../ui/Button'
import { StatusBadge } from '../ui/StatusBadge'

interface OrderDetailDrawerProps {
  order: Order | null
  latestScan?: ScanRecord
  onClose: () => void
  onVerify: (orderId: string) => void
  onHandover: (orderId: string) => void
  onViewHistory: (orderId: string) => void
}

export function OrderDetailDrawer({
  order,
  latestScan,
  onClose,
  onVerify,
  onHandover,
  onViewHistory,
}: OrderDetailDrawerProps) {
  useEffect(() => {
    if (!order) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKeyDown)
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = previousOverflow
    }
  }, [order, onClose])

  if (!order) return null

  const canHandover = order.status === 'passed' && order.handover === 'ready'
  const canVerify = order.status !== 'handed_over'
  const mismatches = latestScan?.lines.filter((line) => line.status !== 'match').length ?? 0

  return createPortal(
    <>
      <div className="drawer-backdrop" onMouseDown={onClose} />
      <aside
        className="drawer"
        role="dialog"
        aria-modal="true"
        aria-label={`รายละเอียดออเดอร์ ${order.id}`}
      >
        <header className="drawer__header">
          <div>
            <p className="meta-xs">รหัสออเดอร์</p>
            <h2 className="modal__title mono">{order.id}</h2>
            <p className="meta">{order.customer}</p>
            <div className="row" style={{ marginTop: 'var(--space-2)' }}>
              <StatusBadge order={order} />
              <Badge tone={handoverTone(order.handover)}>{HANDOVER_LABEL[order.handover]}</Badge>
            </div>
          </div>
          <button
            type="button"
            className="icon-btn modal__close"
            onClick={onClose}
            aria-label="ปิดรายละเอียด"
          >
            <Icon name="x" size={18} />
          </button>
        </header>

        <div className="drawer__body">
          <div className="def-list">
            <div className="def-row">
              <span className="def-row__key">จำนวนที่สั่งรวม</span>
              <span className="def-row__value">{orderTotalQty(order)} ชิ้น</span>
            </div>
            <div className="def-row">
              <span className="def-row__key">สร้างเมื่อ</span>
              <span className="def-row__value">
                {formatDateTime(order.createdAt)}
                <span className="meta-xs" style={{ display: 'block', fontWeight: 400 }}>
                  {relativeTime(order.createdAt)}
                </span>
              </span>
            </div>
            <div className="def-row">
              <span className="def-row__key">อัปเดตล่าสุด</span>
              <span className="def-row__value">{relativeTime(order.updatedAt)}</span>
            </div>
            {order.verifiedAt && (
              <div className="def-row">
                <span className="def-row__key">ยืนยันผลตรวจสอบ</span>
                <span className="def-row__value">{formatDateTime(order.verifiedAt)}</span>
              </div>
            )}
            {order.handedOverAt && (
              <div className="def-row">
                <span className="def-row__key">ส่งมอบเมื่อ</span>
                <span className="def-row__value">
                  {formatDateTime(order.handedOverAt)}
                  {order.driver && (
                    <span className="meta-xs" style={{ display: 'block', fontWeight: 400 }}>
                      โดย {order.driver}
                    </span>
                  )}
                </span>
              </div>
            )}
          </div>

          <h3 className="section-title" style={{ marginTop: 'var(--space-6)' }}>
            รายการสินค้า
          </h3>
          <ul className="stack stack--sm" style={{ marginTop: 'var(--space-3)' }}>
            {order.items.map((item) => {
              const product = getProduct(item.productId)
              return (
                <li
                  key={item.productId}
                  className="row row--between"
                  style={{
                    padding: 'var(--space-3)',
                    border: '1px solid var(--border-soft)',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--surface-sunken)',
                  }}
                >
                  <span className="product-cell">
                    <span className="product-thumb" aria-hidden="true">
                      {product.emoji}
                    </span>
                    <span>
                      <span className="product-cell__name">{product.name}</span>
                      <span className="product-cell__sub" style={{ display: 'block' }}>
                        {product.nameEn}
                      </span>
                    </span>
                  </span>
                  <span className="text-strong">×{item.expectedQty}</span>
                </li>
              )
            })}
          </ul>

          {latestScan && (
            <>
              <h3 className="section-title" style={{ marginTop: 'var(--space-6)' }}>
                ผลการตรวจสอบล่าสุด
              </h3>
              <div className="notice" style={{ marginTop: 'var(--space-3)' }}>
                <Icon name="shield" size={18} className="notice__icon" />
                <div style={{ width: '100%' }}>
                  <p className="text-strong">
                    {latestScan.outcome === 'passed'
                      ? 'ตรวจสอบผ่าน'
                      : latestScan.outcome === 'mismatch'
                        ? 'พบข้อผิดพลาด'
                        : 'ต้องตรวจสอบเพิ่มเติม'}
                  </p>
                  <p className="meta-xs">
                    สแกนเมื่อ {formatDateTime(latestScan.scannedAt)}
                    {latestScan.verifiedAt &&
                      ` · ยืนยันเมื่อ ${formatDateTime(latestScan.verifiedAt)}`}
                  </p>
                  <div className="row row--wrap" style={{ marginTop: 'var(--space-2)' }}>
                    <Badge tone="neutral">{latestScan.lines.length} รายการ</Badge>
                    {mismatches > 0 && <Badge tone="error">ไม่ตรง {mismatches} รายการ</Badge>}
                    {latestScan.corrected && <Badge tone="warning">มีการแก้ไขโดยพนักงาน</Badge>}
                  </div>
                  <ul className="stack stack--sm" style={{ marginTop: 'var(--space-3)' }}>
                    {latestScan.lines.map((line) => {
                      const product = getProduct(line.productId)
                      return (
                        <li key={line.productId} className="row row--between">
                          <span className="meta">
                            {product.emoji} {product.name}
                          </span>
                          <span className="row" style={{ gap: 'var(--space-2)' }}>
                            <span className="meta-xs">
                              {line.effectiveQty ?? '—'}/{line.expectedQty}
                            </span>
                            <Badge tone={itemStatusTone(line.status)}>
                              {ITEM_STATUS_LABEL[line.status]}
                            </Badge>
                          </span>
                        </li>
                      )
                    })}
                  </ul>
                </div>
              </div>
            </>
          )}
        </div>

        <footer className="drawer__footer">
          <Button
            variant="ghost"
            icon="history"
            onClick={() => onViewHistory(order.id)}
            disabled={!latestScan}
          >
            ประวัติการตรวจสอบ
          </Button>
          <div className="toolbar__spacer" />
          {canHandover ? (
            <Button variant="success" icon="truck" onClick={() => onHandover(order.id)}>
              ส่งมอบออเดอร์
            </Button>
          ) : canVerify ? (
            <Button variant="primary" icon="scan" onClick={() => onVerify(order.id)}>
              ไปตรวจสอบสินค้า
            </Button>
          ) : (
            <Button variant="secondary" onClick={onClose}>
              ปิด
            </Button>
          )}
        </footer>
      </aside>
    </>,
    document.body,
  )
}
