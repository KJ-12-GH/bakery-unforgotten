import type { ScanOutcome } from '../../types'
import type { ComparisonSummary } from '../../utils/verification'
import { Icon } from '../icons/Icon'

interface ResultBannerProps {
  outcome: ScanOutcome | null
  summary?: ComparisonSummary
  /** True when the order has already been confirmed. */
  verified?: boolean
}

export function ResultBanner({ outcome, summary, verified = false }: ResultBannerProps) {
  if (!outcome) {
    return (
      <div className="result-banner result-banner--idle">
        <span className="result-banner__icon">
          <Icon name="scan" size={24} />
        </span>
        <div>
          <p className="result-banner__title">ยังไม่มีผลการตรวจสอบ</p>
          <p className="result-banner__text text-muted">
            เริ่มสแกนสินค้าเพื่อเทียบจำนวนกับออเดอร์
          </p>
        </div>
      </div>
    )
  }

  if (outcome === 'passed') {
    return (
      <div className="result-banner result-banner--passed" role="status">
        <span className="result-banner__icon">
          <Icon name="check-circle" size={26} />
        </span>
        <div>
          <p className="result-banner__title">ตรวจสอบผ่าน</p>
          <p className="result-banner__text">
            จำนวนสินค้าตรงกับออเดอร์ครบทุกรายการ
            {summary && summary.corrected > 0 && ' (มีการแก้ไขโดยพนักงาน)'}
            {verified
              ? ' · ยืนยันผลแล้ว'
              : ' — กด “ยืนยันผลตรวจสอบ” เพื่อยืนยันก่อนส่งมอบ'}
          </p>
        </div>
      </div>
    )
  }

  if (outcome === 'mismatch') {
    return (
      <div className="result-banner result-banner--mismatch" role="alert">
        <span className="result-banner__icon">
          <Icon name="x-circle" size={26} />
        </span>
        <div>
          <p className="result-banner__title">พบข้อผิดพลาด</p>
          <p className="result-banner__text">
            {summary && summary.missing > 0 && `ขาดสินค้า ${summary.missing} ชิ้น`}
            {summary && summary.missing > 0 && summary.extra > 0 && ' · '}
            {summary && summary.extra > 0 && `เกินสินค้า ${summary.extra} ชิ้น`}
            {' — กรุณาแก้ไขและตรวจสอบอีกครั้งก่อนส่งมอบ'}
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="result-banner result-banner--uncertain" role="alert">
      <span className="result-banner__icon">
        <Icon name="alert-triangle" size={26} />
      </span>
      <div>
        <p className="result-banner__title">ต้องตรวจสอบเพิ่มเติม</p>
        <p className="result-banner__text">
          {summary ? `${summary.uncertain} รายการที่ระบบไม่มั่นใจ` : 'ระบบไม่มั่นใจในบางรายการ'}
          {' — กรุณาตรวจสอบด้วยตนเองและระบุจำนวนที่ถูกต้อง'}
        </p>
      </div>
    </div>
  )
}
