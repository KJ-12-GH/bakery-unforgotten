import { useCamera } from '../../hooks/useCamera'
import { Icon } from '../icons/Icon'
import { Button } from '../ui/Button'

interface CameraPanelProps {
  scanning: boolean
  disabled: boolean
  lastCapture: string | null
  /** image is null when the scan is simulated without a camera frame. */
  onScan: (image: string | null) => void
}

const STATUS_TEXT: Record<string, string> = {
  idle: 'กล้องยังไม่เปิด',
  requesting: 'กำลังขออนุญาตใช้กล้อง…',
  live: 'กล้องกำลังทำงาน',
  denied: 'ถูกปฏิเสธการเข้าถึงกล้อง',
  unsupported: 'เบราว์เซอร์นี้ไม่รองรับกล้อง',
  error: 'ไม่สามารถเปิดกล้องได้',
}

export function CameraPanel({ scanning, disabled, lastCapture, onScan }: CameraPanelProps) {
  const { videoRef, status, error, start, stop, capture } = useCamera()
  const live = status === 'live'

  const handleCapture = () => {
    const image = capture()
    onScan(image)
  }

  return (
    <section className="card camera-panel" aria-label="กล้องสแกนสินค้า">
      <header className="card__header">
        <div>
          <h2 className="card__title">
            <Icon name="camera" size={19} />
            กล้องสแกนสินค้า
          </h2>
          <p className="card__subtitle">วางสินค้าให้อยู่ในกรอบ แล้วสแกนเพื่อเทียบจำนวน</p>
        </div>
        <span className="sim-tag">
          <Icon name="flask" size={12} />
          โหมดสาธิต
        </span>
      </header>

      <div className="card__body stack">
        <div className="camera-viewport">
          {/* Always mounted so the stream can attach; covered by the placeholder when idle. */}
          <video ref={videoRef} muted playsInline aria-label="ภาพจากกล้อง" />
          {!live && (
            <div className="camera-placeholder">
              <span className="camera-placeholder__icon">
                <Icon name={status === 'denied' ? 'lock' : 'camera'} size={30} />
              </span>
              <p className="camera-placeholder__title">{STATUS_TEXT[status] ?? 'กล้อง'}</p>
              <p className="camera-placeholder__text">
                {status === 'denied'
                  ? 'คุณยังใช้การตรวจสอบแบบจำลองได้ตามปกติ (ไม่ต้องใช้กล้อง)'
                  : status === 'unsupported'
                    ? 'โปรดใช้การตรวจสอบแบบจำลองแทน'
                    : 'กด “เปิดกล้อง” เพื่ออนุญาตการใช้กล้อง หรือใช้การตรวจสอบแบบจำลอง'}
              </p>
              {error && <p className="meta-xs">{error}</p>}
            </div>
          )}

          {live && (
            <div className="camera-overlay" aria-hidden="true">
              <span className="camera-overlay__corner camera-overlay__corner--tl" />
              <span className="camera-overlay__corner camera-overlay__corner--tr" />
              <span className="camera-overlay__corner camera-overlay__corner--bl" />
              <span className="camera-overlay__corner camera-overlay__corner--br" />
              {scanning && <span className="camera-scanline" />}
            </div>
          )}
        </div>

        <div className="row row--between row--wrap">
          <span className="camera-status">
            <span
              className={
                live
                  ? 'camera-status__dot camera-status__dot--live'
                  : status === 'denied' || status === 'error'
                    ? 'camera-status__dot camera-status__dot--error'
                    : 'camera-status__dot'
              }
            />
            {STATUS_TEXT[status] ?? 'กล้อง'}
          </span>
          {lastCapture && <span className="meta-xs">จับภาพล่าสุดแล้ว</span>}
        </div>

        <div className="camera-controls">
          {!live && (
            <Button
              icon="camera"
              variant="secondary"
              onClick={() => void start()}
              disabled={status === 'requesting' || disabled}
              loading={status === 'requesting'}
            >
              เปิดกล้อง
            </Button>
          )}

          {live && (
            <>
              <Button
                icon="scan"
                variant="primary"
                onClick={handleCapture}
                disabled={scanning || disabled}
                loading={scanning}
              >
                จับภาพและตรวจสอบ
              </Button>
              <Button icon="x" variant="ghost" onClick={stop} disabled={scanning}>
                ปิดกล้อง
              </Button>
            </>
          )}

          <Button
            icon="flask"
            variant={live ? 'secondary' : 'primary'}
            onClick={() => onScan(null)}
            disabled={scanning || disabled}
            loading={scanning && !live}
          >
            ตรวจสอบด้วยการจำลอง
          </Button>
        </div>

        {lastCapture && (
          <div className="row" style={{ alignItems: 'flex-start', gap: 'var(--space-3)' }}>
            <img
              src={lastCapture}
              alt="ภาพที่จับได้ล่าสุด"
              style={{
                width: 96,
                height: 72,
                objectFit: 'cover',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}
            />
            <p className="meta-xs">
              ภาพนี้เป็นเพียงภาพนิ่งที่จับจากกล้อง ระบบต้นแบบยังไม่ได้วิเคราะห์ภาพด้วย AI จริง
            </p>
          </div>
        )}
      </div>
    </section>
  )
}
