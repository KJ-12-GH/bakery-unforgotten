//
//  Notifications.swift
//  BakeCheck
//
//  Derives the notification feed from current order state (nothing is stored).
//

import Foundation

enum NotificationBuilder {
    static func build(orders: [Order]) -> [NotificationItem] {
        var items: [NotificationItem] = []

        for order in orders {
            switch order.status {
            case .mismatch:
                items.append(NotificationItem(
                    id: "mismatch-\(order.id)",
                    orderId: order.id,
                    title: "\(order.id) พบข้อผิดพลาด",
                    detail: "จำนวนสินค้าไม่ตรงกับออเดอร์ ต้องแก้ไขก่อนส่งมอบ",
                    tone: .error,
                    at: order.updatedAt,
                    opensHandover: false
                ))
            case .review:
                items.append(NotificationItem(
                    id: "review-\(order.id)",
                    orderId: order.id,
                    title: "\(order.id) ต้องตรวจสอบเพิ่มเติม",
                    detail: "ระบบไม่มั่นใจในผลการตรวจจับ กรุณาตรวจสอบด้วยตนเอง",
                    tone: .warning,
                    at: order.updatedAt,
                    opensHandover: false
                ))
            case .passed where order.handover == .ready:
                items.append(NotificationItem(
                    id: "ready-\(order.id)",
                    orderId: order.id,
                    title: "\(order.id) พร้อมส่งมอบ",
                    detail: "ตรวจสอบผ่านแล้ว รอส่งมอบให้พนักงานขับรถ",
                    tone: .success,
                    at: order.verifiedAt ?? order.updatedAt,
                    opensHandover: true
                ))
            case .pending:
                items.append(NotificationItem(
                    id: "pending-\(order.id)",
                    orderId: order.id,
                    title: "\(order.id) รอตรวจสอบ",
                    detail: "ยังไม่ได้สแกนตรวจสอบสินค้า",
                    tone: .info,
                    at: order.updatedAt,
                    opensHandover: false
                ))
            default:
                break
            }
        }

        return Array(items.sorted { $0.at > $1.at }.prefix(12))
    }
}
