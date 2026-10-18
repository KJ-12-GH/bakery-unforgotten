import type { ReactNode } from 'react'
import { Icon } from '../icons/Icon'
import type { IconName } from '../icons/Icon'

interface EmptyStateProps {
  icon?: IconName
  title: string
  text?: string
  action?: ReactNode
}

export function EmptyState({ icon = 'inbox', title, text, action }: EmptyStateProps) {
  return (
    <div className="empty">
      <div className="empty__icon">
        <Icon name={icon} size={30} />
      </div>
      <h3 className="empty__title">{title}</h3>
      {text && <p className="empty__text">{text}</p>}
      {action}
    </div>
  )
}
