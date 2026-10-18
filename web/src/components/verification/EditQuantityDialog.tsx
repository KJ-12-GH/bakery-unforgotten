import { useState } from 'react'
import { Icon } from '../icons/Icon'
import { Button } from '../ui/Button'
import { Modal } from '../ui/Modal'

interface EditQuantityDialogProps {
  open: boolean
  productName: string
  expected: number
  detected: number | null
  value: number | null
  onSave: (qty: number) => void
  onRevert: () => void
  onClose: () => void
}

const MAX_QTY = 99

export function EditQuantityDialog({
  open,
  productName,
  expected,
  detected,
  value,
  onSave,
  onRevert,
  onClose,
}: EditQuantityDialogProps) {
  // The dialog is mounted fresh for each product, so the initial value is enough.
  const [draft, setDraft] = useState(value ?? expected)

  const isReverted = value === null

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="แก้ไขจำนวนที่ตรวจพบ"
      description="ระบุจำนวนสินค้าที่นับได้จริง การแก้ไขจะถูกบันทึกว่าเป็นข้อมูลจากพนักงาน"
      icon="edit"
      tone="warning"
      footer={
        <>
          <Button variant="ghost" onClick={onRevert} disabled={isReverted}>
            ล้างการแก้ไข
          </Button>
          <Button variant="ghost" onClick={onClose}>
            ยกเลิก
          </Button>
          <Button variant="primary" onClick={() => onSave(draft)}>
            บันทึกการแก้ไข
          </Button>
        </>
      }
    >
      <div className="stack">
        <div className="notice notice--warning">
          <Icon name="alert-circle" size={17} className="notice__icon" />
          <span>
            ผลจากระบบเป็นการตรวจจับแบบจำลอง ไม่ใช่ AI จริง — ตัวเลขที่พนักงานกรอกจะถูกใช้แทนใน
            การเปรียบเทียบ
          </span>
        </div>

        <div className="def-list">
          <div className="def-row">
            <span className="def-row__key">สินค้า</span>
            <span className="def-row__value">{productName}</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">จำนวนที่สั่ง</span>
            <span className="def-row__value">{expected} ชิ้น</span>
          </div>
          <div className="def-row">
            <span className="def-row__key">ระบบตรวจพบ</span>
            <span className="def-row__value">{detected ?? 'ไม่แน่ชัด'}</span>
          </div>
        </div>

        <div className="row" style={{ justifyContent: 'center', gap: 'var(--space-4)' }}>
          <div className="stepper">
            <button
              type="button"
              className="stepper__btn"
              onClick={() => setDraft((prev) => Math.max(0, prev - 1))}
              disabled={draft <= 0}
              aria-label="ลดจำนวน"
            >
              <Icon name="minus" size={16} />
            </button>
            <span className="stepper__value" aria-live="polite">
              {draft}
            </span>
            <button
              type="button"
              className="stepper__btn"
              onClick={() => setDraft((prev) => Math.min(MAX_QTY, prev + 1))}
              disabled={draft >= MAX_QTY}
              aria-label="เพิ่มจำนวน"
            >
              <Icon name="plus" size={16} />
            </button>
          </div>
        </div>
      </div>
    </Modal>
  )
}
