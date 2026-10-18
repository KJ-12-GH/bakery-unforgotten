//
//  DesignSystem.swift
//  BakeCheck
//
//  Earth-tone bakery palette + spacing/typography tokens.
//  Hex values are carried over 1:1 from the web prototype's tokens.css.
//

import SwiftUI

extension Color {
    /// 0xRRGGBB convenience initialiser.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum BakeColor {
    // Brand palette (as specified in the brief)
    static let cream = Color(hex: 0xF5EDE3)
    static let sand = Color(hex: 0xD8C7AE)
    static let dune = Color(hex: 0xC6AD92)
    static let terra = Color(hex: 0xB77955)
    static let bark = Color(hex: 0x8D6B4F)
    static let wood = Color(hex: 0x684329)
    static let white = Color.white
    static let text = Color(hex: 0x30251E)
    static let muted = Color(hex: 0x786B60)

    // Derived surfaces
    static let surface = Color.white
    static let surfaceSunken = Color(hex: 0xFAF5EE)
    static let surfaceTint = Color(hex: 0xF7EFE6)

    // Borders
    static let border = Color(hex: 0xE9DFD2)
    static let borderSoft = Color(hex: 0xF0E8DD)

    // Interactive brand states
    static let terraStrong = Color(hex: 0xA2673F)
    static let terraSoft = Color(hex: 0xF3E3D7)

    // Status — muted, readable variants
    static let success = Color(hex: 0x4D7A4F)
    static let successStrong = Color(hex: 0x3D6440)
    static let successBg = Color(hex: 0xE9F1E6)
    static let successBorder = Color(hex: 0xC6DABE)

    static let error = Color(hex: 0xA94A3C)
    static let errorStrong = Color(hex: 0x8C3A2E)
    static let errorBg = Color(hex: 0xF8E8E4)
    static let errorBorder = Color(hex: 0xE6C1B9)

    static let warning = Color(hex: 0xA9741F)
    static let warningStrong = Color(hex: 0x8C5F16)
    static let warningBg = Color(hex: 0xF8EFD9)
    static let warningBorder = Color(hex: 0xE9D5A6)

    static let info = Color(hex: 0x4A6B82)
    static let infoBg = Color(hex: 0xE8EFF4)
    static let infoBorder = Color(hex: 0xC4D7E3)

    static let neutral = Color(hex: 0x786B60)
    static let neutralBg = Color(hex: 0xF0EAE2)
    static let neutralBorder = Color(hex: 0xE2D7C8)
}

extension BadgeTone {
    var foreground: Color {
        switch self {
        case .neutral: BakeColor.neutral
        case .info: BakeColor.info
        case .success: BakeColor.successStrong
        case .warning: BakeColor.warningStrong
        case .error: BakeColor.errorStrong
        case .brand: BakeColor.terraStrong
        }
    }

    var background: Color {
        switch self {
        case .neutral: BakeColor.neutralBg
        case .info: BakeColor.infoBg
        case .success: BakeColor.successBg
        case .warning: BakeColor.warningBg
        case .error: BakeColor.errorBg
        case .brand: BakeColor.terraSoft
        }
    }

    var border: Color {
        switch self {
        case .neutral: BakeColor.neutralBorder
        case .info: BakeColor.infoBorder
        case .success: BakeColor.successBorder
        case .warning: BakeColor.warningBorder
        case .error: BakeColor.errorBorder
        case .brand: BakeColor.sand
        }
    }

    /// Matching SF Symbol used in notice rows / notification feed.
    var symbol: IconName {
        switch self {
        case .success: .checkCircle
        case .error: .xCircle
        case .warning: .alertTriangle
        case .info: .info
        case .neutral: .info
        case .brand: .store
        }
    }
}

enum BakeRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 9
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 22
    static let card: CGFloat = 20
    static let pill: CGFloat = 999
}

enum BakeSpace {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
}

enum BakeFont {
    static let title = Font.system(size: 27, weight: .bold)
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    static let cardTitle = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15)
    static let bodyStrong = Font.system(size: 15, weight: .semibold)
    static let small = Font.system(size: 13)
    static let smallStrong = Font.system(size: 13, weight: .semibold)
    static let tiny = Font.system(size: 12)
    static let stat = Font.system(size: 27, weight: .bold)
    static let mono = Font.system(size: 14, weight: .semibold, design: .monospaced)
}

// MARK: - Reusable surface

/// Rounded white card with a soft border and gentle elevation, matching the
/// web `Card` but with the depth Apple surfaces use.
struct BakeCard<Content: View>: View {
    var padding: CGFloat = BakeSpace.s4
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BakeRadius.card, style: .continuous)
                .fill(BakeColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.card, style: .continuous)
                .stroke(BakeColor.borderSoft, lineWidth: 1)
        )
        .bakeCardShadow()
    }
}

/// Section heading used inside cards.
struct BakeCardHeader: View {
    var title: String
    var subtitle: String? = nil
    var icon: IconName? = nil
    var accessory: AnyView? = nil

    var body: some View {
        HStack(alignment: .top, spacing: BakeSpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: BakeSpace.s2) {
                    if let icon {
                        Icon(name: icon, size: 17)
                            .foregroundStyle(BakeColor.bark)
                    }
                    Text(title)
                        .font(BakeFont.cardTitle)
                        .foregroundStyle(BakeColor.text)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let accessory {
                accessory
            }
        }
    }
}

/// Thin separator matching the web `--border-soft`.
struct BakeSeparator: View {
    var body: some View {
        Rectangle()
            .fill(BakeColor.borderSoft)
            .frame(height: 1)
    }
}

/// Key/value definition row (web `.def-row`).
struct DefRow: View {
    var key: String
    var value: String
    var valueColor: Color = BakeColor.text
    var mono: Bool = false
    var footnote: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: BakeSpace.s3) {
            Text(key)
                .font(BakeFont.small)
                .foregroundStyle(BakeColor.muted)
            Spacer(minLength: BakeSpace.s2)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(mono ? BakeFont.mono : BakeFont.smallStrong)
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
                if let footnote, !footnote.isEmpty {
                    Text(footnote)
                        .font(BakeFont.tiny)
                        .fontWeight(.regular)
                        .foregroundStyle(BakeColor.muted)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Small coloured pill (web `.badge`).
struct Badge: View {
    var text: String
    var tone: BadgeTone = .neutral
    var dot: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if dot {
                Circle()
                    .fill(tone.foreground)
                    .frame(width: 6, height: 6)
            }
            Text(text)
                .font(BakeFont.tiny.weight(.semibold))
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(tone.background)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(tone.border, lineWidth: 1))
    }
}

/// Badge that renders an order's derived status.
struct StatusBadge: View {
    var order: Order

    var body: some View {
        Badge(text: Labels.orderStatus(order), tone: Labels.orderTone(order), dot: true)
    }
}

/// Inline notice strip (web `.notice`).
struct Notice: View {
    var tone: BadgeTone = .neutral
    var icon: IconName? = nil
    @ViewBuilder var content: () -> AnyView

    init(tone: BadgeTone = .neutral, icon: IconName? = nil, @ViewBuilder content: @escaping () -> some View) {
        self.tone = tone
        self.icon = icon
        self.content = { AnyView(content()) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: BakeSpace.s3) {
            Icon(name: icon ?? tone.symbol, size: 16)
                .foregroundStyle(tone.foreground)
                .padding(.top, 1)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(BakeSpace.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(tone.border, lineWidth: 1)
        )
    }
}

/// "โหมดสาธิต" style chip marking simulated behaviour.
struct SimTag: View {
    var text: String

    var body: some View {
        HStack(spacing: 5) {
            Icon(name: .flask, size: 11)
            Text(text)
                .font(BakeFont.tiny.weight(.semibold))
        }
        .foregroundStyle(BakeColor.warningStrong)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(BakeColor.warningBg)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(BakeColor.warningBorder, lineWidth: 1))
    }
}

/// Page-level title block (web `.page-header`).
struct PageHeader: View {
    var title: String
    var subtitle: String? = nil
    var note: String? = nil
    var accessory: AnyView? = nil

    var body: some View {
        HStack(alignment: .top, spacing: BakeSpace.s3) {
            VStack(alignment: .leading, spacing: BakeSpace.s1) {
                Text(title)
                    .font(BakeFont.title)
                    .foregroundStyle(BakeColor.text)
                if let subtitle {
                    Text(subtitle)
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let note {
                    Text(note)
                        .font(BakeFont.tiny.weight(.semibold))
                        .foregroundStyle(BakeColor.bark)
                }
            }
            Spacer(minLength: 0)
            if let accessory {
                accessory
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Screen background used by every page.
struct BakeScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(BakeColor.cream.ignoresSafeArea())
    }
}

extension View {
    func bakeScreen() -> some View { modifier(BakeScreenBackground()) }
}
