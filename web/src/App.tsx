import { DataProvider } from './store/DataContext'
import { NavProvider } from './store/NavContext'
import { AppShell } from './components/layout/AppShell'

export default function App() {
  return (
    <NavProvider>
      <DataProvider>
        <AppShell />
      </DataProvider>
    </NavProvider>
  )
}
