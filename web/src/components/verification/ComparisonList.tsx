import { getProduct } from '../../data/products'
import { comparisonText, differenceText, itemStatusTone } from '../../utils/labels'
import { formatPercent } from '../../utils/format'
import type { ComparisonRow } from '../../utils/verification'
import { cx } from '../../utils/cx'
import { Icon } from '../icons/Icon'
import { Badge } from '../ui/Badge'

interface ComparisonListProps {
  rows: ComparisonRow[]
  onEdit?: (productId: string) => void
}

/** Per-product expected vs detected comparison with options to correct. */
export function ComparisonList({ rows, onEdit }: ComparisonListProps) {
  return (
    <div className="compare-list" role="table" aria-label="ตารางเปรียบเทียบจำนวนสินค้า">
      <div className="compare-row compare-row--head" role="row">
        <span className="compare-head" role="columnheader">
          สินค้า
        </span>
        <span className="compare-head" role="columnheader" style={{ textAlign: 'center' }}>
          สั่ง
        </span>
        <span className="compare-head" role="columnheader" style={{ textAlign: 'center' }}>
          ตรวจพบ
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
        <span className="compare-head" role="columnheader" style={{ textAlign: 'right' }}>
          <span className="visually-hidden">แก้ไข</span>
        </span>
      </div>

      {rows.map((row) => {
        const product = getProduct(row.productId)
        const corrected = row.manualQty !== null && row.manualQty !== row.detectedQty

        return (
          <div key={row.productId} className={cx('compare-row', `compare-row--${row.status}`)} role="row">
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

            <div
              className="compare-qty compare-qty--expected"
              role="cell"
              aria-label={`สั่ง ${row.expectedQty} ชิ้น`}
            >
              {row.expectedQty}
            </div>

            <div
              className="compare-qty compare-qty--detected"
              role="cell"
              aria-label={`ตรวจพบ ${row.detectedQty ?? 'ไม่แน่ชัด'} ชิ้น`}
            >
              {row.detectedQty ?? '—'}
              {corrected && (
                <span className="manual-tag" style={{ display: 'block', marginTop: 4 }}>
                  แก้ไขเป็น {row.manualQty}
                </span>
              )}
            </div>

            <div
              className={cx(
                'compare-qty',
                'compare-qty--diff',
                row.difference !== null && row.difference < 0 && 'is-negative',
                row.difference !== null && row.difference > 0 && 'is-positive',
              )}
              role="cell"
            >
              {differenceText(row.difference)}
            </div>

            <div role="cell">
              <Badge tone={itemStatusTone(row.status)}>
                {comparisonText(row.status, row.difference)}
              </Badge>
              {row.confidence !== null && (
                <span className="meta-xs" style={{ display: 'block', marginTop: 4 }}>
                  ความมั่นใจ {formatPercent(row.confidence)}
                </span>
              )}
            </div>

            <div className="compare-actions" role="cell">
              {onEdit && (
                <button
                  type="button"
                  className="icon-btn"
                  style={{ width: 34, height: 34 }}
                  onClick={() => onEdit(row.productId)}
                  aria-label={`แก้ไขจำนวน ${product.name}`}
                >
                  <Icon name="edit" size={16} />
                </button>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
