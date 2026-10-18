//
//  RootView.swift
//  BakeCheck
//
//  App shell: two areas only — the packing station (the default screen) and
//  settings. Everything else is pushed on top. Each area is a native
//  `NavigationStack`, so screens get real large titles and (on iOS/macOS 26)
//  Liquid Glass navigation bars and a minimizing tab bar for free.
//

import SwiftUI

struct BakeCheckRootView: View {
    @StateObject private var store = AppStore()
    @StateObject private var router = Router()
    @StateObject private var toasts = ToastCenter()

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $router.tab) {
                area(.packing) { PackingStationPage(orderId: nil) }
                area(.settings) { SettingsPage() }
            }
            .tint(BakeColor.terra)
            .bakeMinimizingTabBar()

            ToastOverlay()
        }
        .environmentObject(store)
        .environmentObject(router)
        .environmentObject(toasts)
    }

    private func area<Content: View>(
        _ tab: AppTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .navigationDestination(for: Destination.self) { destination in
                    DestinationView(destination: destination)
                }
        }
        .tabItem {
            Label(tab.title, systemImage: tab.icon.rawValue)
        }
        .tag(tab)
    }
}

private extension View {
    /// iOS/macOS 26 collapse-on-scroll tab bar; no-op on older systems.
    @ViewBuilder
    func bakeMinimizingTabBar() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// Renders any pushed screen. Shared by both areas so a destination can be
/// reached from wherever it makes sense.
struct DestinationView: View {
    var destination: Destination

    var body: some View {
        switch destination {
        case .dashboard:
            DashboardPage()
        case .orders:
            OrdersPage()
        case .orderDetail(let id):
            OrderDetailPage(orderId: id)
        case .packing(let id):
            PackingStationPage(orderId: id)
        case .result(let id):
            VerificationResultPage(orderId: id)
        case .handover(let id):
            HandoverPage(orderId: id)
        case .history(let id):
            HistoryPage(orderId: id)
        }
    }
}

// MARK: - Shared page scaffold

/// Root-screen layout: a scrolling content column under a native large-title
/// navigation bar. The column widens on iPad but keeps a readable line length.
struct RootPageScaffold<Content: View>: View {
    var tab: AppTab
    /// Overrides the default reading width (settings prefers a narrower column).
    var maxContentWidth: CGFloat? = nil
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder var content: () -> Content

    private var width: CGFloat {
        maxContentWidth ?? (sizeClass == .regular ? 1080 : 820)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BakeSpace.s5) {
                content()
            }
            .padding(.horizontal, BakeSpace.s4)
            .padding(.top, BakeSpace.s3)
            .padding(.bottom, BakeSpace.s10)
            .frame(maxWidth: width)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(BakeAmbientBackground())
    }
}

/// Pushed-screen layout: native navigation bar plus the same readable width.
struct PushedPageScaffold<Content: View>: View {
    var maxContentWidth: CGFloat? = nil
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder var content: () -> Content

    private var width: CGFloat {
        maxContentWidth ?? (sizeClass == .regular ? 1080 : 820)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BakeSpace.s5) {
                content()
            }
            .padding(.horizontal, BakeSpace.s4)
            .padding(.top, BakeSpace.s3)
            .padding(.bottom, BakeSpace.s10)
            .frame(maxWidth: width)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(BakeAmbientBackground())
    }
}
