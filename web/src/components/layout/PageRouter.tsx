import { useNav } from '../../store/NavContext'
import { DashboardPage } from '../../pages/DashboardPage'
import { OrdersPage } from '../../pages/OrdersPage'
import { PackingStationPage } from '../../pages/PackingStationPage'
import { VerificationResultPage } from '../../pages/VerificationResultPage'
import { HandoverPage } from '../../pages/HandoverPage'
import { HistoryPage } from '../../pages/HistoryPage'
import { SettingsPage } from '../../pages/SettingsPage'

export function PageRouter() {
  const { route } = useNav()

  switch (route.name) {
    case 'dashboard':
      return <DashboardPage />
    case 'orders':
      return <OrdersPage orderId={route.orderId} />
    case 'packing':
      return <PackingStationPage orderId={route.orderId} />
    case 'result':
      return <VerificationResultPage orderId={route.orderId} />
    case 'handover':
      return <HandoverPage orderId={route.orderId} />
    case 'history':
      return <HistoryPage orderId={route.orderId} />
    case 'settings':
      return <SettingsPage />
    default:
      return <DashboardPage />
  }
}
