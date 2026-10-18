//
//  Router.swift
//  BakeCheck
//
//  Lightweight in-app router. Each of the five top-level areas owns its own
//  navigation stack so a push inside one area never leaks into another.
//

import Combine
import SwiftUI

/// Top-level areas shown in the tab bar / sidebar.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case orders
    case packing
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "ภาพรวม"
        case .orders: "จัดการออเดอร์"
        case .packing: "ตรวจสอบสินค้า"
        case .history: "ประวัติออเดอร์"
        case .settings: "ตั้งค่า"
        }
    }

    var icon: IconName {
        switch self {
        case .dashboard: .dashboard
        case .orders: .orders
        case .packing: .scan
        case .history: .history
        case .settings: .settings
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: "ตรวจสอบความถูกต้องของออเดอร์ก่อนส่งมอบ"
        case .orders: "ค้นหา ตรวจสอบ และจัดการออเดอร์ทั้งหมด"
        case .packing: "สแกนเทียบจำนวนสินค้ากับออเดอร์ก่อนส่งมอบ"
        case .history: "บันทึกผลการตรวจสอบย้อนหลัง"
        case .settings: "ข้อมูลร้าน การแจ้งเตือน และการตั้งค่า"
        }
    }
}

/// Screens that can be pushed on top of an area.
enum Destination: Hashable {
    case orderDetail(String)
    case packing(String)
    case result(String)
    case handover(String?)
    case history(String?)

    var title: String {
        switch self {
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
    @Published var tab: AppTab = .dashboard
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
}
