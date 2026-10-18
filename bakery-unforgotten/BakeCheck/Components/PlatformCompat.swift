//
//  PlatformCompat.swift
//  BakeCheck
//
//  The Xcode target supports both iOS and macOS, but the screens are designed
//  for iOS. A handful of SwiftUI modifiers exist only on iOS
//  (`navigationBarTitleDisplayMode`, `toolbar(_:for: .navigationBar)`,
//  `ToolbarItemPlacement.topBarLeading/.topBarTrailing`,
//  `textInputAutocapitalization`).
//
//  Rather than scattering `#if os(iOS)` through every page, the shared screens
//  use the helpers below. On macOS they degrade to the closest native
//  equivalent (or a no-op), so the exact same layout code compiles everywhere.
//

import SwiftUI

extension View {

    /// The root screens draw their own `TopBar`, so the native navigation bar is
    /// hidden on iOS. On macOS the navigation title bar is part of the window
    /// chrome and is left untouched.
    @ViewBuilder
    func bakeHidesNavigationBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// Compact inline title for pushed screens. macOS has no display modes.
    @ViewBuilder
    func bakeInlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Disable auto-capitalisation (used for search fields and the store name).
    @ViewBuilder
    func bakeNoAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Force upper-case input (used for the order-code field).
    @ViewBuilder
    func bakeUppercaseAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.characters)
        #else
        self
        #endif
    }
}

extension ToolbarItemPlacement {

    /// Leading slot for sheet actions (close / cancel).
    static var bakeLeading: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .cancellationAction
        #endif
    }

    /// Trailing slot for sheet actions (save / confirm).
    static var bakeTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .confirmationAction
        #endif
    }
}
