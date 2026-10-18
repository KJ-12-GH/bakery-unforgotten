import { Icon } from '../icons/Icon'
import type { IconName } from '../icons/Icon'

export type StatTone = 'brand' | 'pending' | 'success' | 'error'

interface StatCardProps {
  label: string
  value: number | string
  icon: IconName
  tone?: StatTone
  support?: string
}

export function StatCard({ label, value, icon, tone = 'brand', support }: StatCardProps) {
  return (
    <article className={`stat-card stat-card--${tone}`}>
      <span className="stat-card__accent" aria-hidden="true" />
      <div className="stat-card__top">
        <p className="stat-card__label">{label}</p>
        <span className="stat-card__icon">
          <Icon name={icon} size={20} />
        </span>
      </div>
      <p className="stat-card__value">{value}</p>
      {support && <p className="stat-card__support">{support}</p>}
    </article>
  )
}
