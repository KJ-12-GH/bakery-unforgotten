//
//  RootView.swift
//  BakeCheck
//
//  App shell: a five-area tab bar (which adapts to a sidebar on iPad) where
//  every area owns its own navigation stack, plus the shared toast overlay.
//

import SwiftUI

struct BakeCheckRootView: View {
    @StateObject private var store = AppStore()
    @StateObject private var router = Router()
    @StateObject private var toasts = ToastCenter()

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $router.tab) {
                area(.dashboard) { DashboardPage() }
                area(.orders) { OrdersPage() }
                area(.packing) { PackingStationPage(orderId: nil) }
                area(.history) { HistoryPage() }
                area(.settings) { SettingsPage() }
            }
            .tint(BakeColor.terra)

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

/// Renders any pushed screen. Shared by all five areas so a destination can be
/// reached from wherever it makes sense.
struct DestinationView: View {
    var destination: Destination

    var body: some View {
        switch destination {
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

/// Root-screen layout: fixed custom top bar + scrolling content that stays
/// readable on iPad thanks to a max content width.
struct RootPageScaffold<Content: View>: View {
    var tab: AppTab
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            TopBar(tab: tab)
            ScrollView {
                VStack(alignment: .leading, spacing: BakeSpace.s5) {
                    content()
                }
                .padding(.horizontal, BakeSpace.s4)
                .padding(.top, BakeSpace.s4)
                .padding(.bottom, BakeSpace.s8)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
        }
        .background(BakeColor.cream.ignoresSafeArea())
        .bakeHidesNavigationBar()
    }
}

/// Pushed-screen layout: native navigation bar plus the same readable width.
struct PushedPageScaffold<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BakeSpace.s5) {
                content()
            }
            .padding(.horizontal, BakeSpace.s4)
            .padding(.top, BakeSpace.s4)
            .padding(.bottom, BakeSpace.s8)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .background(BakeColor.cream.ignoresSafeArea())
    }
}
