import { useCallback, useEffect, useRef, useState } from 'react'

export type CameraStatus = 'idle' | 'requesting' | 'live' | 'denied' | 'unsupported' | 'error'

function cameraSupported(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    typeof navigator.mediaDevices !== 'undefined' &&
    typeof navigator.mediaDevices.getUserMedia === 'function'
  )
}

interface UseCameraResult {
  videoRef: React.RefObject<HTMLVideoElement | null>
  status: CameraStatus
  error: string | null
  start: () => Promise<void>
  stop: () => void
  capture: () => string | null
}

/**
 * Minimal camera lifecycle helper.
 * The camera is only started by an explicit user action and every track is
 * stopped on stop() and on unmount.
 */
export function useCamera(): UseCameraResult {
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [status, setStatus] = useState<CameraStatus>(() =>
    cameraSupported() ? 'idle' : 'unsupported',
  )
  const [error, setError] = useState<string | null>(null)

  const stopStream = useCallback(() => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    streamRef.current = null
    if (videoRef.current) videoRef.current.srcObject = null
  }, [])

  const stop = useCallback(() => {
    stopStream()
    setStatus((prev) => (prev === 'live' ? 'idle' : prev))
  }, [stopStream])

  const start = useCallback(async () => {
    if (!cameraSupported()) {
      setStatus('unsupported')
      return
    }

    setStatus('requesting')
    setError(null)

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment' },
        audio: false,
      })
      streamRef.current = stream

      if (videoRef.current) {
        videoRef.current.srcObject = stream
        await videoRef.current.play().catch(() => undefined)
      }
      setStatus('live')
    } catch (caught) {
      stopStream()
      const name = caught instanceof DOMException ? caught.name : ''
      if (name === 'NotAllowedError' || name === 'SecurityError') {
        setStatus('denied')
      } else {
        setStatus('error')
      }
      setError(caught instanceof Error ? caught.message : 'ไม่สามารถเข้าถึงกล้องได้')
    }
  }, [stopStream])

  const capture = useCallback((): string | null => {
    const video = videoRef.current
    if (!video || video.videoWidth === 0) return null

    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    const context = canvas.getContext('2d')
    if (!context) return null

    context.drawImage(video, 0, 0, canvas.width, canvas.height)
    return canvas.toDataURL('image/jpeg', 0.8)
  }, [])

  // Always release the camera when the component unmounts.
  useEffect(() => stopStream, [stopStream])

  return { videoRef, status, error, start, stop, capture }
}
