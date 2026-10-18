import { useState } from 'react'
import { useData } from '../store/DataContext'
import { useToast } from '../store/ToastContext'
import { Icon } from '../components/icons/Icon'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Card, CardBody, CardHeader } from '../components/ui/Card'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { Switch } from '../components/ui/Switch'

export function SettingsPage() {
  const { state, staff, updateSettings, resetDemo } = useData()
  const { show } = useToast()
  const [resetOpen, setResetOpen] = useState(false)

  const settings = state.settings
  const handedOver = state.orders.filter((order) => order.handover === 'handed_over').length

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ตั้งค่า</h1>
          <p className="page-header__subtitle">
            ตั้งค่าโปรไฟล์ร้าน การแจ้งเตือน และการตั้งค่าพื้นฐานของระบบ
          </p>
        </div>
      </header>

      <div className="settings-layout">
        <div className="stack">
          <Card>
            <CardHeader title="โปรไฟล์พนักงาน" icon={<Icon name="user" size={18} />} />
            <CardBody>
              <div className="row" style={{ gap: 'var(--space-4)' }}>
                <span className="avatar" style={{ width: 56, height: 56, fontSize: 18 }} aria-hidden="true">
                  {staff.initials}
                </span>
                <div>
                  <p className="section-title">{staff.name}</p>
                  <p className="meta">{staff.role}</p>
                  <div className="row" style={{ marginTop: 'var(--space-2)' }}>
                    <Badge tone="brand">{staff.store}</Badge>
                  </div>
                </div>
              </div>
              <p className="meta-xs" style={{ marginTop: 'var(--space-4)' }}>
                ระบบต้นแบบนี้ยังไม่มีระบบบัญชีหรือการยืนยันตัวตนจริง
                ข้อมูลพนักงานเป็นตัวอย่างสำหรับการสาธิตเท่านั้น
              </p>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="ข้อมูลร้าน" icon={<Icon name="store" size={18} />} />
            <CardBody>
              <div className="stack">
                <div className="field">
                  <label className="field__label" htmlFor="store-name">
                    ชื่อร้าน
                  </label>
                  <input
                    id="store-name"
                    className="input"
                    value={settings.storeName}
                    onChange={(event) => updateSettings({ storeName: event.target.value })}
                    placeholder="ระบุชื่อร้าน"
                  />
                  <span className="field__hint">ใช้แสดงในส่วนหัวของระบบ</span>
                </div>

                <div className="field">
                  <label className="field__label" htmlFor="language">
                    ภาษาที่ต้องการ
                  </label>
                  <select
                    id="language"
                    className="select"
                    value={settings.language}
                    onChange={(event) =>
                      updateSettings({ language: event.target.value as 'th' | 'en' })
                    }
                  >
                    <option value="th">ไทย (ค่าเริ่มต้น)</option>
                    <option value="en">English</option>
                  </select>
                  <span className="field__hint">
                    ระบบต้นแบบแสดงผลภาษาไทยเป็นหลัก การตั้งค่านี้เป็นตัวอย่างเท่านั้น
                  </span>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>

        <div className="stack">
          <Card>
            <CardHeader title="การแจ้งเตือน" icon={<Icon name="bell" size={18} />} />
            <CardBody>
              <div className="switch-row">
                <div className="switch-row__text">
                  <p className="switch-row__title">แจ้งเตือนเมื่อพบข้อผิดพลาด</p>
                  <p className="switch-row__desc">เตือนทันทีเมื่อจำนวนสินค้าไม่ตรงกับออเดอร์</p>
                </div>
                <Switch
                  checked={settings.notifyMismatch}
                  onChange={(checked) => updateSettings({ notifyMismatch: checked })}
                  label="แจ้งเตือนเมื่อพบข้อผิดพลาด"
                />
              </div>

              <div className="switch-row">
                <div className="switch-row__text">
                  <p className="switch-row__title">แจ้งเตือนเมื่อพร้อมส่งมอบ</p>
                  <p className="switch-row__desc">แจ้งเมื่อออเดอร์ผ่านการตรวจสอบและพร้อมส่งมอบ</p>
                </div>
                <Switch
                  checked={settings.notifyHandover}
                  onChange={(checked) => updateSettings({ notifyHandover: checked })}
                  label="แจ้งเตือนเมื่อพร้อมส่งมอบ"
                />
              </div>

              <div className="switch-row">
                <div className="switch-row__text">
                  <p className="switch-row__title">สรุปภาพรวมรายวัน</p>
                  <p className="switch-row__desc">สรุปจำนวนออเดอร์และข้อผิดพลาดในแต่ละวัน</p>
                </div>
                <Switch
                  checked={settings.notifyDailySummary}
                  onChange={(checked) => updateSettings({ notifyDailySummary: checked })}
                  label="สรุปภาพรวมรายวัน"
                />
              </div>

              <div className="switch-row">
                <div className="switch-row__text">
                  <p className="switch-row__title">ไปยังหน้าส่งมอบอัตโนมัติ</p>
                  <p className="switch-row__desc">
                    นำทางไปหน้าส่งมอบทันทีหลังยืนยันผลตรวจสอบสำเร็จ
                  </p>
                </div>
                <Switch
                  checked={settings.autoAdvance}
                  onChange={(checked) => updateSettings({ autoAdvance: checked })}
                  label="ไปยังหน้าส่งมอบอัตโนมัติ"
                />
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="ข้อมูลสาธิต" icon={<Icon name="flask" size={18} />} />
            <CardBody>
              <div className="def-list">
                <div className="def-row">
                  <span className="def-row__key">ออเดอร์ในระบบ</span>
                  <span className="def-row__value">{state.orders.length} รายการ</span>
                </div>
                <div className="def-row">
                  <span className="def-row__key">บันทึกการตรวจสอบ</span>
                  <span className="def-row__value">{state.scans.length} รายการ</span>
                </div>
                <div className="def-row">
                  <span className="def-row__key">ส่งมอบแล้ว</span>
                  <span className="def-row__value">{handedOver} รายการ</span>
                </div>
              </div>

              <div className="notice notice--warning" style={{ marginTop: 'var(--space-4)' }}>
                <Icon name="alert-triangle" size={17} className="notice__icon" />
                <span>
                  ข้อมูลถูกเก็บไว้ในเบราว์เซอร์ของคุณ (localStorage) เพื่อการสาธิต
                  การรีเซ็ตจะล้างข้อมูลทั้งหมดและคืนค่าข้อมูลตัวอย่างเริ่มต้น
                </span>
              </div>

              <Button
                variant="danger-outline"
                icon="refresh"
                block
                style={{ marginTop: 'var(--space-4)' }}
                onClick={() => setResetOpen(true)}
              >
                รีเซ็ตข้อมูลสาธิต
              </Button>
            </CardBody>
          </Card>
        </div>
      </div>

      <ConfirmDialog
        open={resetOpen}
        tone="warning"
        icon="alert-triangle"
        title="ยืนยันการรีเซ็ตข้อมูลสาธิต"
        description="การดำเนินการนี้จะล้างออเดอร์และประวัติการตรวจสอบทั้งหมด แล้วคืนค่าข้อมูลตัวอย่างเริ่มต้น"
        confirmLabel="รีเซ็ตข้อมูล"
        confirmVariant="danger"
        onConfirm={() => {
          resetDemo()
          setResetOpen(false)
          show('info', 'รีเซ็ตข้อมูลแล้ว', 'ระบบกลับสู่ข้อมูลตัวอย่างเริ่มต้น')
        }}
        onCancel={() => setResetOpen(false)}
      />
    </>
  )
}
