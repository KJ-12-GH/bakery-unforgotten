import { useData } from '../store/DataContext'
import { useNav } from '../store/NavContext'
import { formatFullDate, relativeTime } from '../utils/format'
import { needsVerification } from '../utils/order'
import { Icon } from '../components/icons/Icon'
import type { IconName } from '../components/icons/Icon'
import { Button } from '../components/ui/Button'
import { Card, CardBody } from '../components/ui/Card'
import { StatCard } from '../components/ui/StatCard'
import { OrderTable } from '../components/orders/OrderTable'

interface QuickAction {
  icon: IconName
  title: string
  desc: string
  onClick: () => void
}

/** Today's date in Thai formatting — computed once when the module loads. */
const TODAY_LABEL = formatFullDate(new Date())

export function DashboardPage() {
  const { state } = useData()
  const { navigate } = useNav()

  const orders = state.orders
  const pending = orders.filter((order) => order.status === 'pending').length
  const passed = orders.filter((order) => order.status === 'passed').length
  const problems = orders.filter(
    (order) => order.status === 'mismatch' || order.status === 'review',
  ).length
  const readyToHandOver = orders.filter(
    (order) => order.status === 'passed' && order.handover === 'ready',
  ).length
  const inProgress = orders.filter(needsVerification).length

  const recent = [...orders]
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    .slice(0, 5)

  const lastUpdated = recent[0]?.updatedAt

  const openOrder = (id: string) => {
    const order = orders.find((item) => item.id === id)
    if (order?.status === 'passed' && order.handover === 'ready') {
      navigate({ name: 'handover', orderId: id })
      return
    }
    navigate({ name: 'packing', orderId: id })
  }

  const quickActions: QuickAction[] = [
    {
      icon: 'scan',
      title: 'ตรวจสอบออเดอร์',
      desc: 'สแกนเทียบจำนวนสินค้าก่อนส่งมอบ',
      onClick: () => navigate({ name: 'packing' }),
    },
    {
      icon: 'orders',
      title: 'ดูออเดอร์ทั้งหมด',
      desc: `ทั้งหมด ${orders.length} ออเดอร์`,
      onClick: () => navigate({ name: 'orders' }),
    },
    {
      icon: 'history',
      title: 'ดูประวัติการตรวจสอบ',
      desc: `${state.scans.length} บันทึกการตรวจสอบ`,
      onClick: () => navigate({ name: 'history' }),
    },
  ]

  return (
    <>
      <header className="page-header">
        <div className="page-header__text">
          <h1 className="page-title">ภาพรวม</h1>
          <p className="page-header__subtitle">ตรวจสอบความถูกต้องของออเดอร์ก่อนส่งมอบ</p>
          <p className="page-header__date">{TODAY_LABEL}</p>
        </div>
        <div className="page-header__actions">
          <Button variant="primary" icon="scan" onClick={() => navigate({ name: 'packing' })}>
            เริ่มตรวจสอบออเดอร์
          </Button>
        </div>
      </header>

      {problems > 0 && (
        <div className="notice notice--error" role="alert" style={{ marginBottom: 'var(--space-5)' }}>
          <Icon name="alert-triangle" size={18} className="notice__icon" />
          <div className="row row--between row--wrap" style={{ width: '100%' }}>
            <span>
              มี <strong>{problems}</strong> ออเดอร์ที่พบข้อผิดพลาดหรือต้องตรวจสอบเพิ่มเติม
              ซึ่งยังส่งมอบไม่ได้
            </span>
            <Button
              size="sm"
              variant="danger-outline"
              onClick={() => navigate({ name: 'orders' })}
            >
              ดูออเดอร์ที่ต้องแก้ไข
            </Button>
          </div>
        </div>
      )}

      <div className="stat-grid">
        <StatCard
          label="ออเดอร์ทั้งหมด"
          value={orders.length}
          icon="package"
          tone="brand"
          support={lastUpdated ? `อัปเดตล่าสุด ${relativeTime(lastUpdated)}` : 'ยังไม่มีออเดอร์'}
        />
        <StatCard
          label="รอตรวจสอบ"
          value={pending}
          icon="clock"
          tone="pending"
          support="ต้องสแกนก่อนส่งมอบ"
        />
        <StatCard
          label="ตรวจสอบผ่าน"
          value={passed}
          icon="check-circle"
          tone="success"
          support={readyToHandOver > 0 ? `พร้อมส่งมอบ ${readyToHandOver} ออเดอร์` : 'ยืนยันผลแล้ว'}
        />
        <StatCard
          label="พบข้อผิดพลาด"
          value={problems}
          icon="alert-triangle"
          tone="error"
          support="ต้องแก้ไขก่อนส่งมอบ"
        />
      </div>

      <section className="dashboard-section">
        <div className="dashboard-section__head">
          <h2 className="section-title">ทางลัด</h2>
          <span className="meta">เหลืออีก {inProgress} ออเดอร์ที่ต้องตรวจสอบ</span>
        </div>
        <div className="quick-grid">
          {quickActions.map((action) => (
            <button key={action.title} type="button" className="quick-action" onClick={action.onClick}>
              <span className="quick-action__icon">
                <Icon name={action.icon} size={22} />
              </span>
              <span>
                <span className="quick-action__title">{action.title}</span>
                <span className="quick-action__desc" style={{ display: 'block' }}>
                  {action.desc}
                </span>
              </span>
              <Icon name="arrow-right" size={18} style={{ marginLeft: 'auto', color: 'var(--color-dune)' }} />
            </button>
          ))}
        </div>
      </section>

      <section className="dashboard-section">
        <div className="dashboard-section__head">
          <div>
            <h2 className="section-title">ออเดอร์ล่าสุด</h2>
            <p className="meta">อัปเดตล่าสุด 5 รายการ</p>
          </div>
          <Button variant="ghost" iconAfter="arrow-right" onClick={() => navigate({ name: 'orders' })}>
            ดูทั้งหมด
          </Button>
        </div>

        <Card>
          <CardBody tight>
            <OrderTable
              orders={recent}
              onOpen={(id) => navigate({ name: 'orders', orderId: id })}
              onVerify={openOrder}
              onHandover={(id) => navigate({ name: 'handover', orderId: id })}
            />
          </CardBody>
        </Card>
      </section>
    </>
  )
}
