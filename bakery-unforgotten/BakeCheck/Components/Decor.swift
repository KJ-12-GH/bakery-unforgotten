//
//  Decor.swift
//  BakeCheck
//
//  Visual building blocks that make the app feel native to Apple platforms:
//  an ambient page background, a layered illustrated hero card, product
//  glyphs, and an adaptive two-column container for iPad.
//

import SwiftUI

// MARK: - Ambient background

/// Warm, softly lit backdrop used behind every screen. The radial gradients
/// give the cream palette some depth without competing with the content.
struct BakeAmbientBackground: View {
    var body: some View {
        ZStack {
            BakeColor.cream
            RadialGradient(
                colors: [BakeColor.terra.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 540
            )
            RadialGradient(
                colors: [BakeColor.sand.opacity(0.40), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hero

/// Large illustrated header. Uses a warm gradient, blurred light blooms and a
/// thin SF Symbol illustration — the same visual language as Apple's own
/// editorial headers.
struct BakeHero: View {
    var title: String
    var subtitle: String? = nil
    var symbol: String
    var tag: String? = nil
    var footnote: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: BakeSpace.s2) {
            HStack(alignment: .top, spacing: BakeSpace.s3) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let subtitle {
                        Text(subtitle)
                            .font(BakeFont.small)
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                }

                Spacer(minLength: BakeSpace.s2)

                if let tag {
                    Text(tag)
                        .font(BakeFont.tiny.weight(.semibold))
                        .foregroundStyle(BakeColor.wood)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                        .fixedSize()
                }
            }

            Spacer(minLength: BakeSpace.s2)

            if let footnote {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text(footnote)
                        .font(BakeFont.tiny.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.white.opacity(0.88))
            }
        }
        .padding(BakeSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 166)
        .background { decoration }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: BakeColor.wood.opacity(0.28), radius: 18, x: 0, y: 10)
    }

    /// Drawn behind the copy so the shapes never influence the layout.
    private var decoration: some View {
        ZStack {
            LinearGradient(
                colors: [BakeColor.wood, BakeColor.bark, BakeColor.terra],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.13))
                .frame(width: 230, height: 230)
                .offset(x: 170, y: -110)
                .blur(radius: 4)

            Circle()
                .fill(BakeColor.sand.opacity(0.30))
                .frame(width: 190, height: 190)
                .offset(x: 210, y: 80)
                .blur(radius: 18)

            Image(systemName: symbol)
                .font(.system(size: 128, weight: .thin))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.22))
                .rotationEffect(.degrees(-9))
                .offset(x: 145, y: 22)
        }
    }
}

// MARK: - Product glyph

/// Circular product illustration built from the product's emoji, framed the way
/// Apple frames avatars and list artwork.
struct ProductGlyph: View {
    var productId: String
    var size: CGFloat = 42

    private var product: Product { SeedData.product(productId) }

    var body: some View {
        Text(product.emoji)
            .font(.system(size: size * 0.54))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BakeColor.surface, BakeColor.surfaceTint],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(Circle().stroke(BakeColor.borderSoft, lineWidth: 1))
            .accessibilityHidden(true)
    }
}

// MARK: - Adaptive split

/// Single column on iPhone, balanced two columns on iPad.
struct BakeSplit<Primary: View, Secondary: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var secondary: () -> Secondary

    var body: some View {
        if sizeClass == .regular {
            HStack(alignment: .top, spacing: BakeSpace.s5) {
                VStack(alignment: .leading, spacing: BakeSpace.s5) {
                    primary()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: BakeSpace.s5) {
                    secondary()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: BakeSpace.s5) {
                primary()
                secondary()
            }
        }
    }
}

// MARK: - Card shadow

extension View {
    /// Soft elevation used by cards and floating controls.
    func bakeCardShadow() -> some View {
        shadow(color: BakeColor.wood.opacity(0.07), radius: 14, x: 0, y: 6)
    }
}
