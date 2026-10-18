import type { ReactNode } from 'react'
import { Button } from './Button'
import type { ButtonVariant } from './Button'
import { Modal } from './Modal'
import type { DialogTone } from './Modal'
import type { IconName } from '../icons/Icon'

interface ConfirmDialogProps {
  open: boolean
  title: string
  description?: string
  icon?: IconName
  tone?: DialogTone
  confirmLabel: string
  confirmVariant?: ButtonVariant
  cancelLabel?: string
  confirmDisabled?: boolean
  busy?: boolean
  onConfirm: () => void
  onCancel: () => void
  children?: ReactNode
}

export function ConfirmDialog({
  open,
  title,
  description,
  icon = 'alert-circle',
  tone = 'neutral',
  confirmLabel,
  confirmVariant = 'primary',
  cancelLabel = 'ยกเลิก',
  confirmDisabled = false,
  busy = false,
  onConfirm,
  onCancel,
  children,
}: ConfirmDialogProps) {
  return (
    <Modal
      open={open}
      onClose={onCancel}
      title={title}
      description={description}
      icon={icon}
      tone={tone}
      footer={
        <>
          <Button variant="ghost" onClick={onCancel} disabled={busy}>
            {cancelLabel}
          </Button>
          <Button
            variant={confirmVariant}
            onClick={onConfirm}
            disabled={confirmDisabled}
            loading={busy}
          >
            {confirmLabel}
          </Button>
        </>
      }
    >
      {children}
    </Modal>
  )
}
