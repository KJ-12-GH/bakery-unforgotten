//
//  Router.swift
//  BakeCheck
//
//  The app has two top-level areas:
//    • ตรวจสอบสินค้า — the packing station, which is where the app opens
//    • ตั้งค่า — settings, which also holds the entrance to the dashboard
//
//  Everything else (dashboard, order list, order detail, results, handover,
//  history) is pushed on top of whichever area is active, so there is never a
//  crowded tab bar on iPhone or iPad.
//

import Combine
import SwiftUI

/// Top-level areas shown in the tab bar.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case packing
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .packing: "ตรวจสอบสินค้า"
        case .settings: "ตั้งค่า"
        }
    }

    var icon: IconName {
        switch self {
        case .packing: .scan
        case .settings: .settings
        }
    }

    var subtitle: String {
        switch self {
        case .packing: "สแกนเทียบจำนวนสินค้ากับออเดอร์ก่อนส่งมอบ"
        case .settings: "ข้อมูลร้าน การแจ้งเตือน และภาพรวมร้าน"
        }
    }
}

/// Screens that can be pushed on top of an area.
enum Destination: Hashable {
    case dashboard
    case orders
    case orderDetail(String)
    case packing(String)
    case result(String)
    case handover(String?)
    case history(String?)

    var title: String {
        switch self {
        case .dashboard: "ภาพรวม"
        case .orders: "จัดการออเดอร์"
        case .orderDetail: "รายละเอียดออเดอร์"
        case .packing: "ตรวจสอบสินค้า"
        case .result: "ผลการตรวจสอบ"
        case .handover: "ส่งมอบสินค้า"
        case .history: "ประวัติออเดอร์"
        }
    }
}

@MainActor
final class Router: ObservableObject {
    /// The app opens straight into the verification station.
    @Published var tab: AppTab = .packing
    @Published private(set) var paths: [AppTab: [Destination]] = [:]

    func path(for tab: AppTab) -> [Destination] { paths[tab] ?? [] }

    func binding(for tab: AppTab) -> Binding<[Destination]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }

    /// Push a screen inside the currently selected area.
    func go(_ destination: Destination) {
        paths[tab, default: []].append(destination)
    }

    /// Switch area first, then push.
    func go(_ destination: Destination, in tab: AppTab) {
        self.tab = tab
        paths[tab, default: []].append(destination)
    }

    func select(_ tab: AppTab) {
        self.tab = tab
    }

    func popToRoot(_ tab: AppTab) {
        paths[tab] = []
    }

    /// Jump to the packing station. Clears pushed screens so "back" always
    /// returns to a meaningful place.
    func startScanning(orderId: String? = nil) {
        paths[.settings] = []
        paths[.packing] = []
        tab = .packing
        if let orderId {
            paths[.packing] = [.packing(orderId)]
        }
    }

    /// Open the dashboard (reached from the bottom of the settings screen).
    func openDashboard() {
        tab = .settings
        paths[.settings] = [.dashboard]
    }

    /// Order list, reachable from the dashboard and from the station.
    func openOrders() {
        go(.orders)
    }
}
