import { useEffect, useRef, useState } from 'react'
import { getProduct } from '../data/products'
import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import { useToast } from '../store/ToastContext'
import type { ScanRecord } from '../types'
import { formatDateTime } from '../utils/format'
import { itemStatusTone, comparisonText } from '../utils/labels'
import { orderTotalQty } from '../utils/order'
import { compareOrder, outcomeOf, summarize } from '../utils/verification'
import { simulateScan } from '../utils/scan'
import { differenceText } from '../utils/labels'
import { cx } from '../utils/cx'
import { Icon } from '../components/icons/Icon'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Card, CardBody, CardHeader } from '../components/ui/Card'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { EmptyState } from '../components/ui/EmptyState'
import { ComparisonList } from '../components/verification/ComparisonList'
import { ResultBanner } from '../components/verification/ResultBanner'

const RESCAN_MS = 1300

function RecordLines({ record }: { record: ScanRecord }) {
  return (
    <div className="compare-list" role="table" aria-label="รายการผลการตรวจสอบ">
      <div className="compare-row compare-row--head" role="row">
        <span className="compare-head" role="columnheader">
          สินค้า
        </span>
        <span className="compare-head" role="columnheader" style={{ textAlign: 'center' }}>
          สั่ง
        </span>
        <span className="compare-head" role="columnheader" style={{ textAlign: 'center' }}>
          นับได้
        </span>
        <span
          className="compare-head compare-head--diff"
          role="columnheader"
          style={{ textAlign: 'center' }}
        >
          ต่าง
        </span>
        <span className="compare-head" role="columnheader">
          ผล
        </span>
        <span className="compare-head" role="columnheader" />
      </div>

      {record.lines.map((line) => {
        const product = getProduct(line.productId)
        const difference =
          line.effectiveQty === null ? null : line.effectiveQty - line.expectedQty

        return (
          <div key={line.productId} className={cx('compare-row', `compare-row--${line.status}`)} role="row">
            <div className="product-cell" role="cell">
              <span className="product-thumb" aria-hidden="true">
                {product.emoji}
              </span>
              <span>
                <span className="product-cell__name">{product.name}</span>
                <span className="product-cell__sub" style={{ display: 'block' }}>
                  {product.nameEn}
                </span>
              </span>
            </div>
            <div className="compare-qty compare-qty--expected" role="cell">
              {line.expectedQty}
            </div>
            <div className="compare-qty compare-qty--detected" role="cell">
              {line.effectiveQty ?? '—'}
              {line.corrected && (
                <span className="manual-tag" style={{ display: 'block', marginTop: 4 }}>
                  แก้ไขโดยพนักงาน
                </span>
              )}
            </div>
            <div
              className={cx(
                'compare-qty',
                'compare-qty--diff',
                difference !== null && difference < 0 && 'is-negative',
                difference !== null && difference > 0 && 'is-positive',
              )}
              role="cell"
            >
              {differenceText(difference)}
            </div>
            <div role="cell">
              <Badge tone={itemStatusTone(line.status)}>
                {comparisonText(line.status, difference)}
              </Badge>
            </div>
            <div role="cell" />
          </div>
        )
      })}
    </div>
  )
}

export function VerificationResultPage({ orderId }: { orderId: string }) {
  const { getOrder, getDraft, getLatestScan, recordScan, confirmVerification } = useData()
  const { navigate } = useNav()
  const { show } = useToast()

  const [scanning, setScanning] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const timerRef = useRef<number | null>(null)

  useEffect(
    () => () => {
      if (timerRef.current !== null) window.clearTimeout(timerRef.current)
    },
    [],
  )

  const order = getOrder(orderId)

  if (!order) {
    return (
      <>
        <header className="page-header">
          <div className="page-header__text">
            <h1 className="page-title">ผลการตรวจสอบ</h1>
          </div>
        </header>
        <Card>
          <CardBody>
            <EmptyState
              icon="inbox"
              title="ไม่พบออเดอร์นี้"
              text="ออเดอร์อาจถูกลบหรือรหัสไม่ถูกต้อง"
              action={
                <Button variant="primary" onClick={() => navigate({ name: 'orders' })}>
                  กลับไปยังออเดอร์
                </Button>
              }
            />
          </CardBody>
        </Card>
      </>
    )
  }

  const draft = getDraft(orderId)
  const record = getLatestScan(orderId)
  const rows = draft ? compareOrder(order, draft) : []
  const outcome = draft ? outcomeOf(rows) : (record?.outcome ?? null)
  const summary = summarize(rows)
  const isVerified = !draft && !!record

  const rescan = () => {
    if (scanning || !draft) return
    setScanning(true)
    timerRef.current = window.setTimeout(() => {
      recordScan(order.id, simulateScan(order))
      setScanning(false)
      timerRef.current = null
      show('info', 'ตรวจสอบอีกครั้งแล้ว', 'ผลการเปรียบเทียบถูกอัปเดตแล้ว')
    }, RESCAN_MS)
  }

  const handleConfirm = () => {
    confirmVerification(order.id)
    setConfirmOpen(false)
    show('success', 'ยืนยันผลตรวจสอบเรียบร้อย', `${order.id} พร้อมส่งมอบ`)
  }

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ผลการตรวจสอบ</h1>
          <p className="page-header__subtitle">
            ออเดอร์ <span className="mono text-strong">{order.id}</span> · {order.customer}
          </p>
          <p className="page-header__date">
            {record?.verifiedAt
              ? `ยืนยันเมื่อ ${formatDateTime(record.verifiedAt)}`
              : draft
                ? `สแกนเมื่อ ${formatDateTime(draft.scannedAt)}`
                : 'ยังไม่มีการตรวจสอบ'}
          </p>
        </div>
        <div className="page-header__actions">
          <Button
            variant="ghost"
            icon="arrow-left"
            onClick={() => navigate({ name: 'orders', orderId: order.id })}
          >
            กลับไปยังออเดอร์
          </Button>
        </div>
      </header>

      {!draft && !record ? (
        <Card>
          <CardBody>
            <EmptyState
              icon="scan"
              title="ยังไม่มีผลการตรวจสอบสำหรับออเดอร์นี้"
              text="เข้าสู่สถานีตรวจสอบสินค้าเพื่อสแกนเทียบจำนวนก่อนส่งมอบ"
              action={
                <Button
                  variant="primary"
                  icon="scan"
                  onClick={() => navigate({ name: 'packing', orderId: order.id })}
                >
                  ไปตรวจสอบสินค้า
                </Button>
              }
            />
          </CardBody>
        </Card>
      ) : (
        <div className="result-layout">
          <div className="stack">
            <Card>
              <CardHeader
                title="สรุปผลการตรวจสอบ"
                icon={<Icon name="shield" size={18} />}
                subtitle={isVerified ? 'ผลที่ยืนยันแล้ว' : 'ผลจากการสแกนล่าสุด (ยังไม่ยืนยัน)'}
              />
              <CardBody>
                <ResultBanner outcome={outcome} summary={summary} verified={isVerified} />

                {draft && (
                  <div className="summary-strip" style={{ marginTop: 'var(--space-4)' }}>
                    <div className="summary-tile">
                      <p className="summary-tile__label">รายการทั้งหมด</p>
                      <p className="summary-tile__value">{rows.length}</p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">ตรงกัน</p>
                      <p className="summary-tile__value" style={{ color: 'var(--success-strong)' }}>
                        {summary.matched}
                      </p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">ไม่ตรง</p>
                      <p className="summary-tile__value" style={{ color: 'var(--error-strong)' }}>
                        {rows.length - summary.matched - summary.uncertain}
                      </p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">แก้ไขโดยพนักงาน</p>
                      <p className="summary-tile__value" style={{ color: 'var(--warning-strong)' }}>
                        {summary.corrected}
                      </p>
                    </div>
                  </div>
                )}

                <div style={{ marginTop: 'var(--space-4)' }}>
                  {draft ? (
                    <ComparisonList rows={rows} onEdit={undefined} />
                  ) : (
                    record && <RecordLines record={record} />
                  )}
                </div>
              </CardBody>
            </Card>
          </div>

          <div className="stack">
            <Card>
              <CardHeader title="ข้อมูลออเดอร์" icon={<Icon name="orders" size={18} />} />
              <CardBody>
                <div className="def-list">
                  <div className="def-row">
                    <span className="def-row__key">รหัสออเดอร์</span>
                    <span className="def-row__value mono">{order.id}</span>
                  </div>
                  <div className="def-row">
                    <span className="def-row__key">ลูกค้า</span>
                    <span className="def-row__value">{order.customer}</span>
                  </div>
                  <div className="def-row">
                    <span className="def-row__key">จำนวนที่สั่งรวม</span>
                    <span className="def-row__value">{orderTotalQty(order)} ชิ้น</span>
                  </div>
                  {record && (
                    <>
                      <div className="def-row">
                        <span className="def-row__key">สแกนเมื่อ</span>
                        <span className="def-row__value">{formatDateTime(record.scannedAt)}</span>
                      </div>
                      <div className="def-row">
                        <span className="def-row__key">รหัสผลตรวจสอบ</span>
                        <span className="def-row__value mono">{record.id}</span>
                      </div>
                      <div className="def-row">
                        <span className="def-row__key">มีการแก้ไข</span>
                        <span className="def-row__value">
                          {record.corrected ? 'มี' : 'ไม่มี'}
                        </span>
                      </div>
                    </>
                  )}
                </div>

                {isVerified && (
                  <div className="notice notice--success" style={{ marginTop: 'var(--space-4)' }}>
                    <Icon name="check-circle" size={17} className="notice__icon" />
                    <span>ออเดอร์นี้ยืนยันผลแล้ว และพร้อมส่งมอบให้พนักงานขับรถ</span>
                  </div>
                )}
              </CardBody>
            </Card>

            <Card>
              <CardHeader title="การดำเนินการ" icon={<Icon name="settings" size={18} />} />
              <CardBody>
                <div className="stack stack--sm">
                  {draft && (
                    <>
                      <Button
                        variant="secondary"
                        icon="refresh"
                        block
                        onClick={rescan}
                        disabled={scanning}
                        loading={scanning}
                      >
                        ตรวจสอบอีกครั้ง
                      </Button>
                      <Button
                        variant="ghost"
                        icon="edit"
                        block
                        onClick={() => navigate({ name: 'packing', orderId: order.id })}
                        disabled={scanning}
                      >
                        กลับไปแก้ไข
                      </Button>
                      <Button
                        variant="success"
                        icon="shield"
                        block
                        onClick={() => setConfirmOpen(true)}
                        disabled={outcome !== 'passed' || scanning}
                      >
                        ยืนยันผลตรวจสอบ
                      </Button>
                      {outcome !== 'passed' && (
                        <p className="meta-xs">
                          ต้องให้ทุกรายการตรงกันก่อนจึงจะยืนยันผลได้
                          (ปัจจุบัน: {outcome === 'mismatch' ? 'พบข้อผิดพลาด' : 'ต้องตรวจสอบเพิ่มเติม'})
                        </p>
                      )}
                    </>
                  )}

                  {isVerified && (
                    <>
                      {order.handover === 'ready' ? (
                        <Button
                          variant="success"
                          icon="truck"
                          block
                          onClick={() => navigate({ name: 'handover', orderId: order.id })}
                        >
                          ไปหน้าส่งมอบสินค้า
                        </Button>
                      ) : (
                        <div className="notice notice--success">
                          <Icon name="check-circle" size={17} className="notice__icon" />
                          <span>
                            ส่งมอบแล้ว
                            {order.driver ? ` โดย ${order.driver}` : ''}
                          </span>
                        </div>
                      )}
                      <Button
                        variant="ghost"
                        icon="history"
                        block
                        onClick={() => navigate({ name: 'history', orderId: order.id })}
                      >
                        ดูประวัติการตรวจสอบ
                      </Button>
                    </>
                  )}

                  <Button
                    variant="ghost"
                    icon="arrow-left"
                    block
                    onClick={() => navigate({ name: 'orders', orderId: order.id })}
                  >
                    กลับไปยังออเดอร์
                  </Button>
                </div>
              </CardBody>
            </Card>

            <div className="notice">
              <Icon name="flask" size={17} className="notice__icon" />
              <span>
                ผลการตรวจจับในหน้านี้เป็น <strong>ข้อมูลจำลอง</strong> สำหรับการสาธิต
                ยังไม่ได้วิเคราะห์ภาพด้วยโมเดล AI จริง
              </span>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmOpen}
        tone="success"
        icon="shield"
        title="ยืนยันผลการตรวจสอบ"
        description={`ยืนยันว่าออเดอร์ ${order.id} มีจำนวนสินค้าครบทุกรายการ`}
        confirmLabel="ยืนยันผลตรวจสอบ"
        confirmVariant="success"
        onConfirm={handleConfirm}
        onCancel={() => setConfirmOpen(false)}
      >
        <div className="def-list">
          <div className="def-row">
            <span className="def-row__key">จำนวนรวมที่นับได้</span>
            <span className="def-row__value">{summary.totalEffective} ชิ้น</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">รายการที่ตรงกัน</span>
            <span className="def-row__value">
              {summary.matched}/{rows.length}
            </span>
          </div>
          {summary.corrected > 0 && (
            <div className="def-row">
              <span className="def-row__key">แก้ไขโดยพนักงาน</span>
              <span className="def-row__value">{summary.corrected} รายการ</span>
            </div>
          )}
        </div>
      </ConfirmDialog>
    </>
  )
}
