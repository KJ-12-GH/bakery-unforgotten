import type { ReactNode } from 'react'
import { cx } from '../../utils/cx'

interface CardProps {
  children: ReactNode
  className?: string
  as?: 'section' | 'article' | 'div'
}

export function Card({ children, className, as: Tag = 'section' }: CardProps) {
  return <Tag className={cx('card', className)}>{children}</Tag>
}

interface CardHeaderProps {
  title: ReactNode
  subtitle?: ReactNode
  icon?: ReactNode
  actions?: ReactNode
  plain?: boolean
}

export function CardHeader({ title, subtitle, icon, actions, plain = false }: CardHeaderProps) {
  return (
    <header className={cx('card__header', plain && 'card__header--plain')}>
      <div>
        <h2 className="card__title">
          {icon}
          {title}
        </h2>
        {subtitle && <p className="card__subtitle">{subtitle}</p>}
      </div>
      {actions && <div className="row">{actions}</div>}
    </header>
  )
}

export function CardBody({
  children,
  tight = false,
  className,
}: {
  children: ReactNode
  tight?: boolean
  className?: string
}) {
  return <div className={cx('card__body', tight && 'card__body--tight', className)}>{children}</div>
}

export function CardFooter({ children }: { children: ReactNode }) {
  return <footer className="card__footer">{children}</footer>
}
