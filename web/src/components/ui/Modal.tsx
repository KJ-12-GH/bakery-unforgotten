import { useEffect, useId } from 'react'
import type { ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { Icon } from '../icons/Icon'
import type { IconName } from '../icons/Icon'
import { cx } from '../../utils/cx'

export type DialogTone = 'neutral' | 'warning' | 'success' | 'error'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  description?: string
  icon?: IconName
  tone?: DialogTone
  footer?: ReactNode
  children?: ReactNode
}

export function Modal({
  open,
  onClose,
  title,
  description,
  icon,
  tone = 'neutral',
  footer,
  children,
}: ModalProps) {
  const titleId = useId()

  useEffect(() => {
    if (!open) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKeyDown)
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = previousOverflow
    }
  }, [open, onClose])

  if (!open) return null

  return createPortal(
    <div
      className="modal-backdrop"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose()
      }}
    >
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby={titleId}>
        <header className="modal__header">
          {icon && (
            <div className={cx('modal__icon', tone !== 'neutral' && `modal__icon--${tone}`)}>
              <Icon name={icon} size={22} />
            </div>
          )}
          <div>
            <h2 className="modal__title" id={titleId}>
              {title}
            </h2>
            {description && <p className="modal__desc">{description}</p>}
          </div>
          <button
            type="button"
            className="icon-btn modal__close"
            onClick={onClose}
            aria-label="ปิดหน้าต่าง"
          >
            <Icon name="x" size={18} />
          </button>
        </header>
        {children && <div className="modal__body">{children}</div>}
        {footer && <footer className="modal__footer">{footer}</footer>}
      </div>
    </div>,
    document.body,
  )
}
