//
//  ToastCenter.swift
//  BakeCheck
//
//  Transient confirmations, mirroring the web prototype's toast region.
//

import Combine
import SwiftUI

enum ToastTone: Hashable {
    case success
    case error
    case warning
    case info

    var tone: BadgeTone {
        switch self {
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let tone: ToastTone
    let title: String
    let detail: String
}

@MainActor
final class ToastCenter: ObservableObject {
    @Published private(set) var toasts: [ToastMessage] = []

    func show(_ tone: ToastTone, _ title: String, _ detail: String = "") {
        let toast = ToastMessage(tone: tone, title: title, detail: detail)
        toasts.append(toast)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.6))
            toasts.removeAll { $0.id == toast.id }
        }
    }
}

struct ToastOverlay: View {
    @EnvironmentObject private var toasts: ToastCenter

    var body: some View {
        VStack(spacing: BakeSpace.s2) {
            ForEach(toasts.toasts) { toast in
                HStack(alignment: .top, spacing: BakeSpace.s3) {
                    Icon(name: toast.tone.tone.symbol, size: 17)
                        .foregroundStyle(toast.tone.tone.foreground)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(toast.title)
                            .font(BakeFont.smallStrong)
                            .foregroundStyle(BakeColor.text)
                        if !toast.detail.isEmpty {
                            Text(toast.detail)
                                .font(BakeFont.tiny)
                                .foregroundStyle(BakeColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(BakeSpace.s3)
                .frame(maxWidth: 420, alignment: .leading)
                .background(BakeColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                        .stroke(toast.tone.tone.border, lineWidth: 1)
                )
                .shadow(color: BakeColor.text.opacity(0.18), radius: 18, y: 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, BakeSpace.s4)
        .padding(.top, BakeSpace.s2)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toasts.toasts)
        .allowsHitTesting(false)
    }
}
