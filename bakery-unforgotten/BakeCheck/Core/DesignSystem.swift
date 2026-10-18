//
//  DesignSystem.swift
//  BakeCheck
//
//  The visual foundation: a warm bakery palette kept as an *accent* over native
//  system surfaces, Dynamic-Type typography, and Liquid Glass helpers.
//
//  • Every structural colour (surfaces, text, borders, status tones) is defined
//    as a light/dark pair so the app follows the system appearance automatically
//    while the brand stays warm. Pure warm accents (terra/sand/dune) sit on top.
//  • Fonts map to relative text styles, so the UI honours Dynamic Type.
//  • `bakeGlass` / `bakeGlassCard` apply real Liquid Glass on iOS/macOS 26+ and
//    fall back to `.ultraThinMaterial` everywhere older.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
#elseif canImport(AppKit)
import AppKit
private extension NSColor {
    convenience init(rgb: UInt32) {
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

extension Color {
    /// 0xRRGGBB convenience initialiser.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Appearance-aware colour: `light` in light mode, `dark` in dark mode.
    /// Falls back to the light value on platforms without a dynamic provider.
    init(hex light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
        #elseif canImport(AppKit)
        self = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(rgb: dark) : NSColor(rgb: light)
        })
        #else
        self.init(hex: light)
        #endif
    }
}

enum BakeColor {
    // Warm brand accents (used on gradients, selection, primary controls).
    static let cream = Color(hex: 0xF5EDE3, dark: 0x15110E)   // page background
    static let sand = Color(hex: 0xD8C7AE)
    static let dune = Color(hex: 0xC6AD92)
    static let terra = Color(hex: 0xB77955)                   // primary accent
    static let bark = Color(hex: 0x8D6B4F, dark: 0xD0AC85)
    static let wood = Color(hex: 0x684329, dark: 0xE6C49C)    // brand heading/number
    static let white = Color.white

    // Text
    static let text = Color(hex: 0x30251E, dark: 0xF4ECE2)
    static let muted = Color(hex: 0x786B60, dark: 0xABA091)

    // Surfaces
    static let surface = Color(hex: 0xFFFFFF, dark: 0x211C17)
    static let surfaceSunken = Color(hex: 0xFAF5EE, dark: 0x1A1510)
    static let surfaceTint = Color(hex: 0xF7EFE6, dark: 0x2A231C)

    // Borders
    static let border = Color(hex: 0xE9DFD2, dark: 0x39312A)
    static let borderSoft = Color(hex: 0xF0E8DD, dark: 0x2C251F)

    // Interactive brand states
    static let terraStrong = Color(hex: 0xA2673F, dark: 0xE0A878)
    static let terraSoft = Color(hex: 0xF3E3D7, dark: 0x3C2C21)

    // Status — appearance-aware so chips/notices read in both modes.
    static let success = Color(hex: 0x4D7A4F, dark: 0x7FB683)
    static let successStrong = Color(hex: 0x3D6440, dark: 0x9FD3A2)
    static let successBg = Color(hex: 0xE9F1E6, dark: 0x1E2A1E)
    static let successBorder = Color(hex: 0xC6DABE, dark: 0x32462F)

    static let error = Color(hex: 0xA94A3C, dark: 0xE08376)
    static let errorStrong = Color(hex: 0x8C3A2E, dark: 0xF0A79B)
    static let errorBg = Color(hex: 0xF8E8E4, dark: 0x2E1A16)
    static let errorBorder = Color(hex: 0xE6C1B9, dark: 0x4A2922)

    static let warning = Color(hex: 0xA9741F, dark: 0xD7A24C)
    static let warningStrong = Color(hex: 0x8C5F16, dark: 0xE9C27A)
    static let warningBg = Color(hex: 0xF8EFD9, dark: 0x2C2413)
    static let warningBorder = Color(hex: 0xE9D5A6, dark: 0x473A1E)

    static let info = Color(hex: 0x4A6B82, dark: 0x7FA6C0)
    static let infoBg = Color(hex: 0xE8EFF4, dark: 0x16212A)
    static let infoBorder = Color(hex: 0xC4D7E3, dark: 0x2B3C49)

    static let neutral = Color(hex: 0x786B60, dark: 0xABA091)
    static let neutralBg = Color(hex: 0xF0EAE2, dark: 0x221D18)
    static let neutralBorder = Color(hex: 0xE2D7C8, dark: 0x362E27)
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

/// Typography mapped to relative text styles so the whole UI scales with
/// Dynamic Type. Titles use the rounded design for a friendlier, Apple-like feel.
enum BakeFont {
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.headline)
    static let body = Font.system(.body)
    static let bodyStrong = Font.system(.body).weight(.semibold)
    static let small = Font.system(.subheadline)
    static let smallStrong = Font.system(.subheadline).weight(.semibold)
    static let tiny = Font.system(.footnote)
    static let smallStrongTiny = Font.system(.footnote).weight(.semibold)
    static let stat = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let mono = Font.system(.subheadline, design: .monospaced).weight(.semibold)
}

// MARK: - Liquid Glass

extension View {
    /// Real Liquid Glass on iOS/macOS 26+, `.ultraThinMaterial` as a fallback.
    @ViewBuilder
    func bakeGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    /// A tinted Liquid Glass surface (used behind filled buttons). Falls back to
    /// a solid fill of the tint on older systems.
    @ViewBuilder
    func bakeTintedGlass<S: Shape>(_ tint: Color, in shape: S, interactive: Bool = true) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(
                interactive ? .regular.tint(tint).interactive() : .regular.tint(tint),
                in: shape
            )
        } else {
            background(tint, in: shape)
        }
    }
}

// MARK: - Reusable surface

/// Rounded content card: a solid, appearance-aware surface with a hairline
/// border and soft elevation. (Liquid Glass is reserved for floating controls
/// and navigation, per Apple's guidance — not large content cards.)
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
