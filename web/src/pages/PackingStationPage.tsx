import { useEffect, useMemo, useRef, useState } from 'react'
import { getProduct } from '../data/products'
import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import { useToast } from '../store/ToastContext'
import { formatDateTime } from '../utils/format'
import { needsVerification, orderTotalQty } from '../utils/order'
import { compareOrder, outcomeOf, summarize } from '../utils/verification'
import { simulateScan } from '../utils/scan'
import { Icon } from '../components/icons/Icon'
import { Button } from '../components/ui/Button'
import { Card, CardBody, CardHeader } from '../components/ui/Card'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { EmptyState } from '../components/ui/EmptyState'
import { StatusBadge } from '../components/ui/StatusBadge'
import { CameraPanel } from '../components/verification/CameraPanel'
import { ComparisonList } from '../components/verification/ComparisonList'
import { EditQuantityDialog } from '../components/verification/EditQuantityDialog'
import { ResultBanner } from '../components/verification/ResultBanner'

const SCAN_DURATION_MS = 1600

export function PackingStationPage({ orderId }: { orderId?: string }) {
  const { state, getOrder, getDraft, recordScan, setManualQty, confirmVerification } = useData()
  const { navigate } = useNav()
  const { show } = useToast()

  const [scanning, setScanning] = useState(false)
  const [lastCapture, setLastCapture] = useState<string | null>(null)
  const [editingProductId, setEditingProductId] = useState<string | null>(null)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const timerRef = useRef<number | null>(null)

  // Default to the first order that still needs verification.
  useEffect(() => {
    if (orderId) return
    const candidate =
      state.orders.find((order) => order.status === 'pending') ??
      state.orders.find(needsVerification) ??
      state.orders[0]
    if (candidate) navigate({ name: 'packing', orderId: candidate.id })
  }, [orderId, state.orders, navigate])

  // Cancel any pending scan timer on unmount.
  useEffect(
    () => () => {
      if (timerRef.current !== null) window.clearTimeout(timerRef.current)
    },
    [],
  )

  const order = orderId ? getOrder(orderId) : undefined
  const draft = order ? getDraft(order.id) : undefined
  const rows = useMemo(
    () => (order && draft ? compareOrder(order, draft) : []),
    [order, draft],
  )
  const outcome = draft ? outcomeOf(rows) : null
  const summary = summarize(rows)

  const selectableOrders = state.orders.filter(
    (item) => needsVerification(item) || item.id === order?.id,
  )

  const locked = order?.handover === 'handed_over'

  const runScan = (image: string | null) => {
    if (!order || scanning) return
    if (locked) {
      show('warning', 'ออเดอร์นี้ส่งมอบแล้ว', 'ไม่สามารถสแกนซ้ำได้')
      return
    }

    setScanning(true)
    setLastCapture(image)

    timerRef.current = window.setTimeout(() => {
      const lines = simulateScan(order)
      recordScan(order.id, lines)
      setScanning(false)
      timerRef.current = null

      const result = outcomeOf(
        compareOrder(order, { orderId: order.id, scannedAt: new Date().toISOString(), lines }),
      )
      if (result === 'passed') {
        show('success', 'ตรวจสอบผ่าน', `${order.id} จำนวนสินค้าตรงกับออเดอร์`)
      } else if (result === 'mismatch') {
        show('error', 'พบข้อผิดพลาด', 'มีสินค้าไม่ตรงจำนวน ต้องแก้ไขก่อนส่งมอบ')
      } else {
        show('warning', 'ต้องตรวจสอบเพิ่มเติม', 'มีรายการที่ระบบไม่มั่นใจ กรุณาตรวจสอบ')
      }
    }, SCAN_DURATION_MS)
  }

  const handleConfirmVerification = () => {
    if (!order || !draft) return
    confirmVerification(order.id)
    setConfirmOpen(false)
    show('success', 'ยืนยันผลตรวจสอบเรียบร้อย', `${order.id} พร้อมส่งมอบ`)
    navigate({ name: 'result', orderId: order.id })
  }

  const editingRow = editingProductId
    ? rows.find((row) => row.productId === editingProductId)
    : undefined
  const editingProduct = editingProductId ? getProduct(editingProductId) : undefined

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ตรวจสอบสินค้า</h1>
          <p className="page-header__subtitle">
            เทียบจำนวนสินค้าจริงกับออเดอร์ของลูกค้าก่อนส่งมอบให้พนักงานขับรถ
          </p>
        </div>
        <div className="page-header__actions">
          <span className="sim-tag">
            <Icon name="flask" size={12} />
            ผลการตรวจจับเป็นข้อมูลจำลอง ไม่ใช่ AI จริง
          </span>
        </div>
      </header>

      {!order ? (
        <Card>
          <CardBody>
            <EmptyState
              icon="inbox"
              title="ยังไม่มีออเดอร์ให้ตรวจสอบ"
              text="เมื่อมีออเดอร์ใหม่ ระบบจะแสดงที่นี่เพื่อให้สแกนตรวจสอบ"
              action={
                <Button variant="primary" icon="orders" onClick={() => navigate({ name: 'orders' })}>
                  ไปที่จัดการออเดอร์
                </Button>
              }
            />
          </CardBody>
        </Card>
      ) : (
        <div className="packing-grid">
          {/* ---------- Left column: camera ---------- */}
          <div className="packing-col">
            <CameraPanel
              scanning={scanning}
              disabled={locked || !order}
              lastCapture={lastCapture}
              onScan={runScan}
            />

            <Card>
              <CardHeader title="วิธีใช้งาน" icon={<Icon name="info" size={18} />} />
              <CardBody>
                <div className="instructions">
                  <div className="instruction">
                    <span className="instruction__num">1</span>
                    <span>เลือกออเดอร์ที่ต้องการตรวจสอบจากรายการด้านขวา</span>
                  </div>
                  <div className="instruction">
                    <span className="instruction__num">2</span>
                    <span>วางสินค้าแต่ละชนิดให้อยู่ในกรอบกล้อง แล้วกด “จับภาพและตรวจสอบ”</span>
                  </div>
                  <div className="instruction">
                    <span className="instruction__num">3</span>
                    <span>หากไม่สะดวกใช้กล้อง กด “ตรวจสอบด้วยการจำลอง” เพื่อสาธิตขั้นตอน</span>
                  </div>
                  <div className="instruction">
                    <span className="instruction__num">4</span>
                    <span>แก้ไขรายการที่ไม่ตรง แล้วกด “ยืนยันผลตรวจสอบ” เมื่อจำนวนครบถ้วน</span>
                  </div>
                </div>
              </CardBody>
            </Card>
          </div>

          {/* ---------- Right column: order + comparison ---------- */}
          <div className="packing-col">
            <Card>
              <CardHeader
                title="ออเดอร์ที่ตรวจสอบ"
                icon={<Icon name="orders" size={18} />}
                actions={<StatusBadge order={order} />}
              />
              <CardBody>
                <div className="order-pick">
                  <div className="field">
                    <label className="field__label" htmlFor="packing-order">
                      เลือกออเดอร์
                    </label>
                    <select
                      id="packing-order"
                      className="select"
                      value={order.id}
                      onChange={(event) => {
                        setLastCapture(null)
                        navigate({ name: 'packing', orderId: event.target.value })
                      }}
                    >
                      {selectableOrders.map((item) => (
                        <option key={item.id} value={item.id}>
                          {item.id} — {item.customer} ({item.items.length} รายการ)
                        </option>
                      ))}
                    </select>
                  </div>
                  <Button
                    variant="ghost"
                    icon="orders"
                    onClick={() => navigate({ name: 'orders', orderId: order.id })}
                  >
                    รายละเอียด
                  </Button>
                </div>

                <div className="def-list" style={{ marginTop: 'var(--space-4)' }}>
                  <div className="def-row">
                    <span className="def-row__key">ลูกค้า</span>
                    <span className="def-row__value">{order.customer}</span>
                  </div>
                  <div className="def-row">
                    <span className="def-row__key">จำนวนที่สั่งรวม</span>
                    <span className="def-row__value">
                      {orderTotalQty(order)} ชิ้น · {order.items.length} รายการ
                    </span>
                  </div>
                  <div className="def-row">
                    <span className="def-row__key">เวลาที่อัปเดต</span>
                    <span className="def-row__value">{formatDateTime(order.updatedAt)}</span>
                  </div>
                </div>
              </CardBody>
            </Card>

            <Card>
              <CardHeader
                title="ผลการเปรียบเทียบ"
                icon={<Icon name="shield" size={18} />}
                subtitle={
                  draft
                    ? `สแกนเมื่อ ${formatDateTime(draft.scannedAt)} · ผลจำลอง`
                    : 'ยังไม่ได้สแกนออเดอร์นี้'
                }
                actions={
                  scanning ? (
                    <span className="camera-status">
                      <span className="spinner spinner--brand" aria-hidden="true" />
                      กำลังประมวลผล…
                    </span>
                  ) : undefined
                }
              />
              <CardBody>
                <ResultBanner outcome={outcome} summary={summary} />

                {draft && (
                  <div className="summary-strip" style={{ marginTop: 'var(--space-4)' }}>
                    <div className="summary-tile">
                      <p className="summary-tile__label">สั่งรวม</p>
                      <p className="summary-tile__value">{summary.totalExpected}</p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">ตรวจพบรวม</p>
                      <p className="summary-tile__value">{summary.totalEffective}</p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">ขาด</p>
                      <p className="summary-tile__value" style={{ color: 'var(--error-strong)' }}>
                        {summary.missing}
                      </p>
                    </div>
                    <div className="summary-tile">
                      <p className="summary-tile__label">เกิน</p>
                      <p className="summary-tile__value" style={{ color: 'var(--warning-strong)' }}>
                        {summary.extra}
                      </p>
                    </div>
                  </div>
                )}

                {draft ? (
                  <div style={{ marginTop: 'var(--space-4)' }}>
                    <ComparisonList rows={rows} onEdit={locked ? undefined : setEditingProductId} />
                  </div>
                ) : (
                  <div className="notice" style={{ marginTop: 'var(--space-4)' }}>
                    <Icon name="scan" size={17} className="notice__icon" />
                    <span>
                      กด “ตรวจสอบด้วยการจำลอง” เพื่อจำลองผลการตรวจจับสินค้า
                      ระบบจะเทียบจำนวนให้อัตโนมัติ
                    </span>
                  </div>
                )}
              </CardBody>

              <footer className="card__footer">
                <div className="row row--wrap" style={{ justifyContent: 'flex-end' }}>
                  <Button
                    variant="ghost"
                    icon="refresh"
                    onClick={() => runScan(null)}
                    disabled={scanning || locked}
                  >
                    ตรวจสอบอีกครั้ง
                  </Button>

                  {(order.status === 'passed' || order.status === 'handed_over') &&
                  !draft &&
                  !scanning ? (
                    <>
                      <Button
                        variant="secondary"
                        icon="shield"
                        onClick={() => navigate({ name: 'result', orderId: order.id })}
                      >
                        ดูผลการตรวจสอบ
                      </Button>
                      {order.handover === 'ready' && (
                        <Button
                          variant="success"
                          icon="truck"
                          onClick={() => navigate({ name: 'handover', orderId: order.id })}
                        >
                          ไปส่งมอบ
                        </Button>
                      )}
                    </>
                  ) : (
                    <Button
                      variant="success"
                      icon="shield"
                      onClick={() => setConfirmOpen(true)}
                      disabled={!draft || outcome !== 'passed' || scanning}
                    >
                      ยืนยันผลตรวจสอบ
                    </Button>
                  )}
                </div>
              </footer>
            </Card>
          </div>
        </div>
      )}

      {/* Manual correction dialog */}
      {editingRow && editingProduct && (
        <EditQuantityDialog
          open
          productName={editingProduct.name}
          expected={editingRow.expectedQty}
          detected={editingRow.detectedQty}
          value={editingRow.manualQty}
          onClose={() => setEditingProductId(null)}
          onSave={(qty) => {
            setManualQty(order!.id, editingRow.productId, qty)
            setEditingProductId(null)
            show('info', 'บันทึกการแก้ไขแล้ว', 'ระบบคำนวณผลเปรียบเทียบใหม่ให้อัตโนมัติ')
          }}
          onRevert={() => {
            setManualQty(order!.id, editingRow.productId, null)
            setEditingProductId(null)
          }}
        />
      )}

      {/* Verification confirmation */}
      <ConfirmDialog
        open={confirmOpen}
        tone="success"
        icon="shield"
        title="ยืนยันผลการตรวจสอบ"
        description={`ยืนยันว่าออเดอร์ ${order?.id ?? ''} มีจำนวนสินค้าตรงตามรายการครบทุกรายการ`}
        confirmLabel="ยืนยันผลตรวจสอบ"
        confirmVariant="success"
        onConfirm={handleConfirmVerification}
        onCancel={() => setConfirmOpen(false)}
      >
        <div className="def-list">
          <div className="def-row">
            <span className="def-row__key">ออเดอร์</span>
            <span className="def-row__value mono">{order?.id}</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">จำนวนรวม</span>
            <span className="def-row__value">{summary.totalEffective} ชิ้น</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">รายการที่แก้ไขโดยพนักงาน</span>
            <span className="def-row__value">{summary.corrected} รายการ</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">ผลรวม</span>
            <span className="def-row__value" style={{ color: 'var(--success-strong)' }}>
              ตรงกันครบทุกรายการ
            </span>
          </div>
        </div>
        {draft && summary.corrected > 0 && (
          <p className="meta-xs" style={{ marginTop: 'var(--space-3)' }}>
            หมายเหตุ: บางรายการใช้จำนวนที่พนักงานแก้ไขแทนผลการตรวจจับของระบบ
          </p>
        )}
      </ConfirmDialog>
    </>
  )
}
