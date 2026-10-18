//
//  UIKit.swift
//  BakeCheck
//
//  Small reusable building blocks (buttons, badges, cards, fields).
//

import SwiftUI

// MARK: - Button

enum BakeButtonVariant: Hashable {
    case primary
    case secondary
    case ghost
    case success
    case dangerOutline
}

enum BakeButtonSize: Hashable {
    case small
    case medium
}

struct BakeButton: View {
    var title: String
    var icon: IconName? = nil
    var iconAfter: IconName? = nil
    var variant: BakeButtonVariant = .primary
    var size: BakeButtonSize = .medium
    var block: Bool = false
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var action: () -> Void

    private var foreground: Color {
        switch variant {
        case .primary, .success: .white
        case .secondary: BakeColor.text
        case .ghost: BakeColor.bark
        case .dangerOutline: BakeColor.errorStrong
        }
    }

    private var background: Color {
        switch variant {
        case .primary: BakeColor.terra
        case .secondary: BakeColor.surface
        case .ghost: .clear
        case .success: BakeColor.success
        case .dangerOutline: .clear
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: BakeColor.border
        case .dangerOutline: BakeColor.errorBorder
        default: .clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .secondary, .dangerOutline: 1
        default: 0
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foreground)
                } else if let icon {
                    Icon(name: icon, size: size == .small ? 14 : 16)
                }

                Text(title)
                    .font(size == .small ? BakeFont.smallStrong : BakeFont.bodyStrong)
                    .lineLimit(1)

                if let iconAfter {
                    Icon(name: iconAfter, size: size == .small ? 14 : 15)
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, size == .small ? 12 : 16)
            .frame(height: size == .small ? 34 : 44)
            .frame(maxWidth: block ? CGFloat.infinity : nil)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// Circular icon-only button (web `.icon-btn`).
struct IconButton: View {
    var icon: IconName
    var size: CGFloat = 38
    var iconSize: CGFloat = 17
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Icon(name: icon, size: iconSize)
                .foregroundStyle(BakeColor.bark)
                .frame(width: size, height: size)
                .background(BakeColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                        .stroke(BakeColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat card

struct StatCard: View {
    var label: String
    var value: Int
    var icon: IconName
    var tone: BadgeTone
    var support: String

    var body: some View {
        BakeCard(padding: BakeSpace.s4) {
            HStack(alignment: .top, spacing: BakeSpace.s3) {
                VStack(alignment: .leading, spacing: BakeSpace.s1) {
                    Text(label)
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.muted)
                    Text("\(value)")
                        .font(BakeFont.stat)
                        .foregroundStyle(BakeColor.text)
                    Text(support)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Icon(name: icon, size: 19)
                    .foregroundStyle(tone.foreground)
                    .padding(9)
                    .background(tone.background)
                    .clipShape(RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous))
            }
        }
    }
}

// MARK: - Empty state

struct EmptyState: View {
    var icon: IconName
    var title: String
    var text: String
    var actionTitle: String? = nil
    var actionIcon: IconName? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: BakeSpace.s3) {
            Icon(name: icon, size: 26)
                .foregroundStyle(BakeColor.dune)
                .padding(BakeSpace.s4)
                .background(BakeColor.surfaceSunken)
                .clipShape(Circle())

            Text(title)
                .font(BakeFont.cardTitle)
                .foregroundStyle(BakeColor.text)
                .multilineTextAlignment(.center)

            Text(text)
                .font(BakeFont.small)
                .foregroundStyle(BakeColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                BakeButton(title: actionTitle, icon: actionIcon, variant: .secondary, action: action)
                    .padding(.top, BakeSpace.s1)
            }
        }
        .padding(.vertical, BakeSpace.s8)
        .padding(.horizontal, BakeSpace.s4)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter chip

struct Chip: View {
    var title: String
    /// Optional counter badge; hidden when nil or zero-free usage is preferred.
    var count: Int? = nil
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(BakeFont.small.weight(.semibold))
                if let count {
                    Text("\(count)")
                        .font(BakeFont.tiny.weight(.bold))
                        .foregroundStyle(isOn ? .white : BakeColor.muted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(isOn ? BakeColor.terraStrong.opacity(0.35) : BakeColor.surfaceSunken)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isOn ? .white : BakeColor.text)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isOn ? BakeColor.terra : BakeColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isOn ? BakeColor.terra : BakeColor.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text field

struct BakeTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: IconName? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: BakeSpace.s2) {
            if let icon {
                Icon(name: icon, size: 15)
                    .foregroundStyle(BakeColor.dune)
            }
            TextField(placeholder, text: $text)
                .font(BakeFont.body)
                .foregroundStyle(BakeColor.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
            if !text.isEmpty, isFocused {
                Button {
                    text = ""
                } label: {
                    Icon(name: .xmark, size: 13)
                        .foregroundStyle(BakeColor.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, BakeSpace.s3)
        .frame(height: 44)
        .background(BakeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(BakeColor.border, lineWidth: 1)
        )
    }
}

// MARK: - Section head

struct SectionHead: View {
    var title: String
    var meta: String? = nil
    var accessoryTitle: String? = nil
    var accessoryIcon: IconName? = nil
    var accessory: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: BakeSpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BakeFont.sectionTitle)
                    .foregroundStyle(BakeColor.text)
                if let meta {
                    Text(meta)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                }
            }
            Spacer(minLength: 0)
            if let accessoryTitle, let accessory {
                BakeButton(
                    title: accessoryTitle,
                    iconAfter: accessoryIcon,
                    variant: .ghost,
                    size: .small,
                    action: accessory
                )
            }
        }
    }
}

// MARK: - Switch row

struct BakeSwitchRow: View {
    var title: String
    var desc: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BakeFont.bodyStrong)
                    .foregroundStyle(BakeColor.text)
                Text(desc)
                    .font(BakeFont.tiny)
                    .foregroundStyle(BakeColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(BakeColor.terra)
        .padding(.vertical, BakeSpace.s2)
    }
}

// MARK: - Quantity stepper

struct QuantityStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...99

    var body: some View {
        HStack(spacing: BakeSpace.s4) {
            stepButton(.minus, enabled: value > range.lowerBound) {
                value = max(range.lowerBound, value - 1)
            }

            Text("\(value)")
                .font(.system(size: 30, weight: .bold).monospacedDigit())
                .foregroundStyle(BakeColor.text)
                .frame(minWidth: 64)
                .contentTransition(.numericText())

            stepButton(.plus, enabled: value < range.upperBound) {
                value = min(range.upperBound, value + 1)
            }
        }
    }

    private func stepButton(_ icon: IconName, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Icon(name: icon, size: 18)
                .foregroundStyle(enabled ? BakeColor.bark : BakeColor.dune)
                .frame(width: 48, height: 48)
                .background(BakeColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                        .stroke(BakeColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Avatar

struct AvatarCircle: View {
    var initials: String
    var size: CGFloat = 38

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [BakeColor.terra, BakeColor.bark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

// MARK: - Product summary

/// Compact "🥐 ครัวซองต์ ×4" list used inside order rows.
struct ProductSummaryList: View {
    var order: Order
    var max: Int = 3

    var body: some View {
        let shown = Array(order.items.prefix(max))
        let rest = order.items.count - shown.count

        VStack(alignment: .leading, spacing: 5) {
            ForEach(shown) { item in
                let product = SeedData.product(item.productId)
                HStack(spacing: BakeSpace.s2) {
                    Text(product.emoji)
                        .font(.system(size: 14))
                    Text(product.name)
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.text)
                        .lineLimit(1)
                    Spacer(minLength: BakeSpace.s2)
                    Text("×\(item.expectedQty)")
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.wood)
                }
            }
            if rest > 0 {
                Text("และอีก \(rest) รายการ")
                    .font(BakeFont.tiny)
                    .foregroundStyle(BakeColor.muted)
            }
        }
    }
}

/// Card-shaped order row. Used by the dashboard and the orders list so the
/// two screens can never drift apart.
struct OrderRow: View {
    var order: Order
    var isSelected: Bool = false
    var onOpen: () -> Void
    var onPrimary: () -> Void

    private var action: (kind: String, label: String, icon: IconName) {
        if order.status == .handedOver { return ("details", "ดูรายละเอียด", .info) }
        if order.status == .passed && order.handover == .ready {
            return ("handover", "ส่งมอบ", .truck)
        }
        return ("verify", "ตรวจสอบ", .scan)
    }

    private var variant: BakeButtonVariant {
        switch action.kind {
        case "handover": .success
        case "verify": .primary
        default: .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BakeSpace.s3) {
            HStack(alignment: .top, spacing: BakeSpace.s2) {
                VStack(alignment: .leading, spacing: 2) {
                    Button(action: onOpen) {
                        Text(order.id)
                            .font(BakeFont.mono)
                            .foregroundStyle(BakeColor.wood)
                    }
                    .buttonStyle(.plain)

                    Text(order.customer)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                }
                Spacer(minLength: 0)
                StatusBadge(order: order)
            }

            ProductSummaryList(order: order, max: 3)

            BakeSeparator()

            HStack(alignment: .top, spacing: BakeSpace.s4) {
                metric("จำนวนที่สั่ง", "\(OrderMath.totalQty(order)) ชิ้น")
                metric("รายการ", "\(order.items.count) รายการ")
                metric("อัปเดต", BakeFormat.relative(order.updatedAt))
            }

            HStack(spacing: BakeSpace.s2) {
                BakeButton(title: "รายละเอียด", variant: .ghost, size: .small, block: true, action: onOpen)
                BakeButton(
                    title: action.label,
                    icon: action.icon,
                    variant: variant,
                    size: .small,
                    block: true,
                    action: onPrimary
                )
            }
        }
        .padding(BakeSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BakeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.lg, style: .continuous)
                .stroke(isSelected ? BakeColor.terra : BakeColor.border, lineWidth: isSelected ? 1.5 : 1)
        )
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(BakeFont.tiny)
                .foregroundStyle(BakeColor.muted)
            Text(value)
                .font(BakeFont.smallStrong)
                .foregroundStyle(BakeColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
