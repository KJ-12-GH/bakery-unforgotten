//
//  CameraPanel.swift
//  BakeCheck
//
//  Live camera panel for the packing station.
//
//  ⚠️ The captured frame is NOT analysed. The prototype only demonstrates the
//  capture step; detection comes from `ScanService` (mock, see Scanner.swift).
//
//  Note: the iOS Simulator has no camera, so this panel degrades to the
//  "ใช้การตรวจสอบแบบจำลอง" path there — which is the documented demo path.
//

import AVFoundation
import Combine
import SwiftUI

// MARK: - Delegate proxy

/// Bridges the nonisolated AVFoundation callback back onto the main actor.
private nonisolated final class PhotoCaptureProxy: NSObject, AVCapturePhotoCaptureDelegate {
    private let handler: @MainActor (Data?) -> Void

    init(handler: @escaping @MainActor (Data?) -> Void) {
        self.handler = handler
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        let handler = self.handler
        Task { @MainActor in handler(data) }
    }
}

// MARK: - Controller

@MainActor
final class CameraController: NSObject, ObservableObject {
    enum Status: Equatable {
        case idle
        case requesting
        case live
        case denied
        case unsupported
        case failed

        var label: String {
            switch self {
            case .idle: "กล้องยังไม่เปิด"
            case .requesting: "กำลังขออนุญาตใช้กล้อง…"
            case .live: "กล้องกำลังทำงาน"
            case .denied: "ถูกปฏิเสธการเข้าถึงกล้อง"
            case .unsupported: "อุปกรณ์นี้ไม่รองรับกล้อง"
            case .failed: "ไม่สามารถเปิดกล้องได้"
            }
        }
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastImageData: Data?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var proxy: PhotoCaptureProxy?
    private var captureCompletion: (@MainActor (Data?) -> Void)?

    var isLive: Bool { status == .live }

    func start() async {
        guard status != .requesting, status != .live else { return }
        status = .requesting
        errorMessage = nil

        guard AVCaptureDevice.default(for: .video) != nil else {
            status = .unsupported
            errorMessage = "อุปกรณ์นี้ไม่มีกล้องให้ใช้งาน"
            return
        }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            status = .denied
            return
        }

        configureIfNeeded()

        guard isConfigured else {
            status = .failed
            return
        }

        session.startRunning()
        status = .live
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        status = .idle
    }

    func capture(completion: @escaping @MainActor (Data?) -> Void) {
        guard isConfigured, session.isRunning else {
            completion(nil)
            return
        }

        let settings = AVCapturePhotoSettings()
        let proxy = PhotoCaptureProxy { [weak self] data in
            guard let self else { return }
            self.lastImageData = data
            self.captureCompletion?(data)
            self.captureCompletion = nil
            self.proxy = nil
        }
        self.proxy = proxy
        self.captureCompletion = completion
        photoOutput.capturePhoto(with: settings, delegate: proxy)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            errorMessage = "ไม่สามารถเชื่อมต่อกล้องได้"
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            errorMessage = "ไม่สามารถตั้งค่ากล้องได้"
            return
        }

        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        isConfigured = true
    }
}

// MARK: - Preview layer

#if canImport(UIKit)
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer {
            // Safe: `layerClass` guarantees the type.
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
#endif

// MARK: - Panel

struct CameraPanel: View {
    var isScanning: Bool
    var isDisabled: Bool
    var lastCapture: Data?
    /// `image == nil` when the scan is simulated without a camera frame.
    var onScan: (Data?) -> Void

    @StateObject private var camera = CameraController()

    var body: some View {
        BakeCard(padding: BakeSpace.s4) {
            VStack(alignment: .leading, spacing: BakeSpace.s4) {
                BakeCardHeader(
                    title: "กล้องสแกนสินค้า",
                    subtitle: "วางสินค้าให้อยู่ในกรอบ แล้วสแกนเพื่อเทียบจำนวน",
                    icon: .camera,
                    accessory: AnyView(SimTag(text: "โหมดสาธิต"))
                )

                viewport

                HStack(spacing: BakeSpace.s2) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                    Text(camera.status.label)
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.muted)
                    Spacer(minLength: 0)
                    if lastCapture != nil {
                        Text("จับภาพล่าสุดแล้ว")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                    }
                }

                controls

                if let data = lastCapture, let image = capturedImage(from: data) {
                    HStack(alignment: .top, spacing: BakeSpace.s3) {
                        Image(platformImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous)
                                    .stroke(BakeColor.border, lineWidth: 1)
                            )
                        Text("ภาพนี้เป็นเพียงภาพนิ่งที่จับจากกล้อง ระบบต้นแบบยังไม่ได้วิเคราะห์ภาพด้วย AI จริง")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var dotColor: Color {
        switch camera.status {
        case .live: BakeColor.success
        case .denied, .failed: BakeColor.error
        default: BakeColor.dune
        }
    }

    private var viewport: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .fill(Color.black)

            if camera.isLive {
                #if canImport(UIKit)
                CameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                #endif
                frameOverlay
            } else {
                placeholder
            }

            if isScanning {
                scanline
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(BakeColor.border, lineWidth: 1)
        )
    }

    private var placeholder: some View {
        VStack(spacing: BakeSpace.s2) {
            Icon(name: camera.status == .denied ? .lock : .camera, size: 30)
                .foregroundStyle(BakeColor.sand)
            Text(camera.status.label)
                .font(BakeFont.bodyStrong)
                .foregroundStyle(.white)
            Text(placeholderHint)
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.sand)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BakeSpace.s6)
            if let error = camera.errorMessage {
                Text(error)
                    .font(BakeFont.tiny)
                    .foregroundStyle(BakeColor.dune)
            }
        }
    }

    private var placeholderHint: String {
        switch camera.status {
        case .denied:
            "คุณยังใช้การตรวจสอบแบบจำลองได้ตามปกติ (ไม่ต้องใช้กล้อง)"
        case .unsupported:
            "โปรดใช้การตรวจสอบแบบจำลองแทน"
        default:
            "กด “เปิดกล้อง” เพื่ออนุญาตการใช้กล้อง หรือใช้การตรวจสอบแบบจำลอง"
        }
    }

    private var frameOverlay: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 26
            let length: CGFloat = 30
            let rect = CGRect(
                x: inset, y: inset,
                width: geometry.size.width - inset * 2,
                height: geometry.size.height - inset * 2
            )
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

                path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

                path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
            }
            .stroke(BakeColor.terra, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .allowsHitTesting(false)
    }

    private var scanline: some View {
        TimelineView(.animation) { timeline in
            let period = 1.1
            let progress = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: period) / period

            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, BakeColor.terra, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .offset(y: geometry.size.height * progress)
            }
            .allowsHitTesting(false)
        }
    }

    private var controls: some View {
        VStack(spacing: BakeSpace.s2) {
            if camera.isLive {
                HStack(spacing: BakeSpace.s2) {
                    BakeButton(
                        title: "จับภาพและตรวจสอบ",
                        icon: .scan,
                        variant: .primary,
                        block: true,
                        isEnabled: !isDisabled,
                        isLoading: isScanning
                    ) {
                        camera.capture { data in
                            onScan(data)
                        }
                    }
                    BakeButton(title: "ปิดกล้อง", icon: .xmark, variant: .ghost) {
                        camera.stop()
                    }
                    .disabled(isScanning)
                }
            } else {
                BakeButton(
                    title: "เปิดกล้อง",
                    icon: .camera,
                    variant: .secondary,
                    block: true,
                    isEnabled: !isDisabled,
                    isLoading: camera.status == .requesting
                ) {
                    Task { await camera.start() }
                }
            }

            BakeButton(
                title: "ตรวจสอบด้วยการจำลอง",
                icon: .flask,
                variant: camera.isLive ? .secondary : .primary,
                block: true,
                isEnabled: !isDisabled,
                isLoading: isScanning && !camera.isLive
            ) {
                onScan(nil)
            }
        }
    }
}
