import { useMemo, useState } from 'react'
import { getProduct } from '../data/products'
import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import type { Order, ScanOutcome, ScanRecord } from '../types'
import { formatDate, formatDateTime } from '../utils/format'
import { HANDOVER_LABEL, handoverTone, itemStatusTone, ITEM_STATUS_LABEL } from '../utils/labels'
import { orderTotalQty } from '../utils/order'
import { cx } from '../utils/cx'
import { Icon } from '../components/icons/Icon'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Card, CardBody } from '../components/ui/Card'
import { EmptyState } from '../components/ui/EmptyState'
import { Modal } from '../components/ui/Modal'
import { SearchInput } from '../components/ui/SearchInput'

interface HistoryRow {
  record: ScanRecord
  order: Order | undefined
  mismatchCount: number
}

const OUTCOME_LABEL: Record<ScanOutcome, string> = {
  passed: 'ตรวจสอบผ่าน',
  mismatch: 'พบข้อผิดพลาด',
  uncertain: 'ต้องตรวจสอบเพิ่มเติม',
}

const OUTCOME_TONE: Record<ScanOutcome, 'success' | 'error' | 'warning'> = {
  passed: 'success',
  mismatch: 'error',
  uncertain: 'warning',
}

export function HistoryPage({ orderId }: { orderId?: string }) {
  const { state } = useData()
  const { navigate } = useNav()

  const [query, setQuery] = useState('')
  const [outcome, setOutcome] = useState<'all' | ScanOutcome>('all')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const rows = useMemo<HistoryRow[]>(() => {
    return state.scans
      .map((record) => ({
        record,
        order: state.orders.find((order) => order.id === record.orderId),
        mismatchCount: record.lines.filter((line) => line.status !== 'match').length,
      }))
      .filter((row) => {
        const term = query.trim().toLowerCase()
        if (term) {
          const productMatch = row.record.lines.some((line) =>
            getProduct(line.productId).name.toLowerCase().includes(term),
          )
          if (!row.record.orderId.toLowerCase().includes(term) && !productMatch) return false
        }
        if (outcome !== 'all' && row.record.outcome !== outcome) return false

        const day = row.record.scannedAt.slice(0, 10)
        if (from && day < from) return false
        if (to && day > to) return false

        return true
      })
      .sort((a, b) => b.record.scannedAt.localeCompare(a.record.scannedAt))
  }, [state.scans, state.orders, query, outcome, from, to])

  const selected = selectedId
    ? rows.find((row) => row.record.id === selectedId) ?? null
    : null

  const filterActive = Boolean(query || outcome !== 'all' || from || to)

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ประวัติออเดอร์</h1>
          <p className="page-header__subtitle">บันทึกผลการตรวจสอบจำนวนสินค้าย้อนหลัง</p>
        </div>
        <div className="page-header__actions">
          <Button variant="primary" icon="scan" onClick={() => navigate({ name: 'packing' })}>
            เริ่มตรวจสอบออเดอร์
          </Button>
        </div>
      </header>

      <Card>
        <CardBody>
          <div className="history-filters">
            <div className="field" style={{ flex: '1 1 240px' }}>
              <label className="field__label" htmlFor="history-search">
                ค้นหา
              </label>
              <SearchInput
                id="history-search"
                label="ค้นหาประวัติการตรวจสอบ"
                value={query}
                onChange={setQuery}
                placeholder="ค้นหารหัสออเดอร์ หรือชื่อสินค้า"
              />
            </div>

            <div className="field">
              <label className="field__label" htmlFor="history-outcome">
                ผลการตรวจสอบ
              </label>
              <select
                id="history-outcome"
                className="select"
                value={outcome}
                onChange={(event) => setOutcome(event.target.value as 'all' | ScanOutcome)}
              >
                <option value="all">ทั้งหมด</option>
                <option value="passed">ตรวจสอบผ่าน</option>
                <option value="mismatch">พบข้อผิดพลาด</option>
                <option value="uncertain">ต้องตรวจสอบเพิ่มเติม</option>
              </select>
            </div>

            <div className="field">
              <label className="field__label" htmlFor="history-from">
                ตั้งแต่วันที่
              </label>
              <input
                id="history-from"
                type="date"
                className="input"
                value={from}
                onChange={(event) => setFrom(event.target.value)}
              />
            </div>

            <div className="field">
              <label className="field__label" htmlFor="history-to">
                ถึงวันที่
              </label>
              <input
                id="history-to"
                type="date"
                className="input"
                value={to}
                onChange={(event) => setTo(event.target.value)}
              />
            </div>

            {filterActive && (
              <Button
                variant="ghost"
                icon="refresh"
                onClick={() => {
                  setQuery('')
                  setOutcome('all')
                  setFrom('')
                  setTo('')
                }}
              >
                ล้างตัวกรอง
              </Button>
            )}
          </div>
        </CardBody>
      </Card>

      <div className="orders-toolbar" style={{ marginTop: 'var(--space-4)' }}>
        <p className="result-count">
          พบ <strong>{rows.length}</strong> บันทึกการตรวจสอบ
        </p>
        {orderId && rows.some((row) => row.record.orderId === orderId) && (
          <span className="meta-xs">กรองจากออเดอร์ {orderId} (กดที่แถวเพื่อดูรายละเอียด)</span>
        )}
      </div>

      <Card>
        <CardBody tight>
          {rows.length === 0 ? (
            <EmptyState
              icon="history"
              title="ไม่พบประวัติการตรวจสอบ"
              text="ลองปรับตัวกรองหรือล้างคำค้นหาเพื่อดูบันทึกทั้งหมด"
              action={
                filterActive ? (
                  <Button
                    variant="secondary"
                    icon="refresh"
                    onClick={() => {
                      setQuery('')
                      setOutcome('all')
                      setFrom('')
                      setTo('')
                    }}
                  >
                    ล้างตัวกรอง
                  </Button>
                ) : undefined
              }
            />
          ) : (
            <div className="table-wrap">
              <table className="table" style={{ minWidth: 940 }}>
                <caption className="visually-hidden">ประวัติการตรวจสอบออเดอร์</caption>
                <thead>
                  <tr>
                    <th scope="col">รหัสออเดอร์</th>
                    <th scope="col">วันที่ตรวจสอบ</th>
                    <th scope="col">ผลลัพธ์</th>
                    <th scope="col">จำนวนสินค้า</th>
                    <th scope="col">ไม่ตรง</th>
                    <th scope="col">แก้ไข</th>
                    <th scope="col">การส่งมอบ</th>
                    <th scope="col" style={{ textAlign: 'right' }}>
                      การดำเนินการ
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row) => (
                    <tr
                      key={row.record.id}
                      className={cx(orderId === row.record.orderId && 'is-selected')}
                    >
                      <td>
                        <span className="mono text-strong">{row.record.orderId}</span>
                        {row.order && <div className="meta-xs">{row.order.customer}</div>}
                      </td>
                      <td className="meta">
                        {formatDateTime(row.record.scannedAt)}
                        {row.record.verifiedAt && (
                          <div className="meta-xs">
                            ยืนยัน {formatDate(row.record.verifiedAt)}
                          </div>
                        )}
                      </td>
                      <td>
                        <Badge tone={OUTCOME_TONE[row.record.outcome]} dot>
                          {OUTCOME_LABEL[row.record.outcome]}
                        </Badge>
                      </td>
                      <td className="table__num">
                        {row.order ? orderTotalQty(row.order) : row.record.lines.reduce((sum, line) => sum + line.expectedQty, 0)}{' '}
                        ชิ้น
                        <div className="meta-xs">{row.record.lines.length} รายการ</div>
                      </td>
                      <td className="table__num">
                        {row.mismatchCount > 0 ? (
                          <span style={{ color: 'var(--error-strong)', fontWeight: 700 }}>
                            {row.mismatchCount}
                          </span>
                        ) : (
                          <span className="meta">0</span>
                        )}
                      </td>
                      <td>
                        {row.record.corrected ? (
                          <Badge tone="warning">มีการแก้ไข</Badge>
                        ) : (
                          <span className="meta">—</span>
                        )}
                      </td>
                      <td>
                        {row.order ? (
                          <Badge tone={handoverTone(row.order.handover)}>
                            {HANDOVER_LABEL[row.order.handover]}
                          </Badge>
                        ) : (
                          <span className="meta">—</span>
                        )}
                      </td>
                      <td>
                        <div className="table__actions">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => setSelectedId(row.record.id)}
                          >
                            รายละเอียด
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardBody>
      </Card>

      <Modal
        open={!!selected}
        onClose={() => setSelectedId(null)}
        title={selected ? `ผลการตรวจสอบ ${selected.record.orderId}` : ''}
        description={
          selected
            ? `สแกนเมื่อ ${formatDateTime(selected.record.scannedAt)}${
                selected.record.verifiedAt
                  ? ` · ยืนยันเมื่อ ${formatDateTime(selected.record.verifiedAt)}`
                  : ''
              }`
            : undefined
        }
        icon="history"
        footer={
          <>
            <Button variant="ghost" onClick={() => setSelectedId(null)}>
              ปิด
            </Button>
            {selected && (
              <>
                <Button
                  variant="secondary"
                  icon="orders"
                  onClick={() => navigate({ name: 'orders', orderId: selected.record.orderId })}
                >
                  ดูออเดอร์
                </Button>
                <Button
                  variant="primary"
                  icon="shield"
                  onClick={() => navigate({ name: 'result', orderId: selected.record.orderId })}
                >
                  ดูผลการตรวจสอบ
                </Button>
              </>
            )}
          </>
        }
      >
        {selected && (
          <div className="stack">
            <div className="row row--wrap">
              <Badge tone={OUTCOME_TONE[selected.record.outcome]} dot>
                {OUTCOME_LABEL[selected.record.outcome]}
              </Badge>
              <Badge tone="neutral">{selected.record.lines.length} รายการ</Badge>
              {selected.record.corrected && <Badge tone="warning">มีการแก้ไขโดยพนักงาน</Badge>}
            </div>

            <div className="def-list">
              <div className="def-row">
                <span className="def-row__key">รหัสผลตรวจสอบ</span>
                <span className="def-row__value mono">{selected.record.id}</span>
              </div>
              {selected.order && (
                <div className="def-row">
                  <span className="def-row__key">ลูกค้า</span>
                  <span className="def-row__value">{selected.order.customer}</span>
                </div>
              )}
            </div>

            <div className="compare-list">
              <div className="compare-row compare-row--head">
                <span className="compare-head">สินค้า</span>
                <span className="compare-head" style={{ textAlign: 'center' }}>
                  สั่ง
                </span>
                <span className="compare-head" style={{ textAlign: 'center' }}>
                  นับได้
                </span>
                <span className="compare-head compare-head--diff" style={{ textAlign: 'center' }}>
                  ต่าง
                </span>
                <span className="compare-head">ผล</span>
                <span className="compare-head" />
              </div>
              {selected.record.lines.map((line) => {
                const product = getProduct(line.productId)
                const difference =
                  line.effectiveQty === null ? null : line.effectiveQty - line.expectedQty
                return (
                  <div
                    key={line.productId}
                    className={cx('compare-row', `compare-row--${line.status}`)}
                  >
                    <div className="product-cell">
                      <span className="product-thumb" aria-hidden="true">
                        {product.emoji}
                      </span>
                      <span className="product-cell__name">{product.name}</span>
                    </div>
                    <div className="compare-qty compare-qty--expected">{line.expectedQty}</div>
                    <div className="compare-qty compare-qty--detected">
                      {line.effectiveQty ?? '—'}
                      {line.corrected && (
                        <span className="manual-tag" style={{ display: 'block', marginTop: 4 }}>
                          แก้ไข
                        </span>
                      )}
                    </div>
                    <div className="compare-qty compare-qty--diff">
                      {difference === null ? '—' : difference > 0 ? `+${difference}` : difference}
                    </div>
                    <div>
                      <Badge tone={itemStatusTone(line.status)}>
                        {ITEM_STATUS_LABEL[line.status]}
                      </Badge>
                    </div>
                    <div />
                  </div>
                )
              })}
            </div>

            <div className="notice">
              <Icon name="flask" size={17} className="notice__icon" />
              <span>บันทึกนี้มาจากผลการตรวจจับแบบจำลอง ไม่ใช่การวิเคราะห์ด้วย AI จริง</span>
            </div>
          </div>
        )}
      </Modal>
    </>
  )
}
