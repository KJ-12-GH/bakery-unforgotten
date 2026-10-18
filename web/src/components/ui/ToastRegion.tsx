import { Icon } from '../icons/Icon'
import type { IconName } from '../icons/Icon'
import { useToast } from '../../store/ToastContext'
import type { ToastTone } from '../../store/ToastContext'

const TONE_ICON: Record<ToastTone, IconName> = {
  success: 'check-circle',
  error: 'x-circle',
  warning: 'alert-triangle',
  info: 'info',
}

export function ToastRegion() {
  const { toasts, dismiss } = useToast()

  if (toasts.length === 0) return null

  return (
    <div className="toast-region" role="status" aria-live="polite">
      {toasts.map((toast) => (
        <div key={toast.id} className={`toast toast--${toast.tone}`}>
          <span className="toast__icon">
            <Icon name={TONE_ICON[toast.tone]} size={18} />
          </span>
          <div>
            <p className="toast__title">{toast.title}</p>
            {toast.text && <p className="toast__text">{toast.text}</p>}
          </div>
          <button
            type="button"
            className="toast__close"
            onClick={() => dismiss(toast.id)}
            aria-label="ปิดการแจ้งเตือน"
          >
            <Icon name="x" size={15} />
          </button>
        </div>
      ))}
    </div>
  )
}
