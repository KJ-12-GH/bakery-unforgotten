//
//  VerificationResultPage.swift
//  BakeCheck
//
//  Confirmed (or in-progress) verification result for a single order.
//

import SwiftUI

struct VerificationResultPage: View {
    var orderId: String

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter

    @State private var isScanning = false
    @State private var showConfirm = false
    @State private var scanTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let order = store.order(orderId) {
                content(for: order)
            } else {
                PushedPageScaffold {
                    BakeCard {
                        EmptyState(
                            icon: .inbox,
                            title: "ไม่พบออเดอร์นี้",
                            text: "ออเดอร์อาจถูกลบหรือรหัสไม่ถูกต้อง",
                            actionTitle: "กลับไปยังออเดอร์",
                            actionIcon: .arrowLeft
                        ) { router.select(.orders) }
                    }
                }
            }
        }
        .navigationTitle("ผลการตรวจสอบ")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            scanTask?.cancel()
            scanTask = nil
            isScanning = false
        }
        .sheet(isPresented: $showConfirm) { confirmDialog }
    }

    @ViewBuilder
    private func content(for order: Order) -> some View {
        let draft = store.draft(order.id)
        let record = store.latestScan(order.id)
        let rows = draft == nil ? [] : store.comparisons(forOrder: order.id)
        let outcome: ScanOutcome? = draft != nil ? Verification.outcome(rows: rows) : record?.outcome
        let summary = Verification.summarize(rows: rows)
        let isVerified = draft == nil && record != nil

        PushedPageScaffold {
            PageHeader(
                title: "ผลการตรวจสอบ",
                subtitle: "ออเดอร์ \(order.id) · \(order.customer)",
                note: record?.verifiedAt.map { "ยืนยันเมื่อ \(BakeFormat.dateTime($0))" }
                    ?? draft.map { "สแกนเมื่อ \(BakeFormat.dateTime($0.scannedAt))" }
                    ?? "ยังไม่มีการตรวจสอบ",
                accessory: AnyView(StatusBadge(order: order))
            )

            if draft == nil && record == nil {
                BakeCard {
                    EmptyState(
                        icon: .scan,
                        title: "ยังไม่มีผลการตรวจสอบสำหรับออเดอร์นี้",
                        text: "เข้าสู่สถานีตรวจสอบสินค้าเพื่อสแกนเทียบจำนวนก่อนส่งมอบ",
                        actionTitle: "ไปตรวจสอบสินค้า",
                        actionIcon: .scan
                    ) { router.go(.packing(order.id), in: .packing) }
                }
            } else {
                BakeCard {
                    VStack(alignment: .leading, spacing: BakeSpace.s4) {
                        BakeCardHeader(
                            title: "สรุปผลการตรวจสอบ",
                            subtitle: isVerified ? "ผลที่ยืนยันแล้ว" : "ผลจากการสแกนล่าสุด (ยังไม่ยืนยัน)",
                            icon: .shield
                        )

                        ResultBanner(outcome: outcome, summary: summary, verified: isVerified)

                        if draft != nil {
                            SummaryStrip(tiles: [
                                ("รายการทั้งหมด", "\(rows.count)", BakeColor.text),
                                ("ตรงกัน", "\(summary.matched)", BakeColor.successStrong),
                                ("ไม่ตรง", "\(rows.count - summary.matched - summary.uncertain)", BakeColor.errorStrong),
                                ("แก้ไขโดยพนักงาน", "\(summary.corrected)", BakeColor.warningStrong),
                            ])

                            ComparisonList(rows: rows)
                        } else if let record {
                            ComparisonList(rows: Verification.rows(from: record))
                        }
                    }
                }

                BakeCard {
                    VStack(alignment: .leading, spacing: BakeSpace.s4) {
                        BakeCardHeader(title: "ข้อมูลออเดอร์", icon: .orders)

                        VStack(spacing: BakeSpace.s3) {
                            DefRow(key: "รหัสออเดอร์", value: order.id, mono: true)
                            DefRow(key: "ลูกค้า", value: order.customer)
                            DefRow(key: "จำนวนที่สั่งรวม", value: "\(OrderMath.totalQty(order)) ชิ้น")
                            if let record {
                                DefRow(key: "สแกนเมื่อ", value: BakeFormat.dateTime(record.scannedAt))
                                DefRow(key: "รหัสผลตรวจสอบ", value: record.id, mono: true)
                                DefRow(key: "มีการแก้ไข", value: record.corrected ? "มี" : "ไม่มี")
                            }
                        }

                        if isVerified {
                            Notice(tone: .success, icon: .checkCircle) {
                                Text("ออเดอร์นี้ยืนยันผลแล้ว และพร้อมส่งมอบให้พนักงานขับรถ")
                                    .font(BakeFont.small)
                                    .foregroundStyle(BakeColor.successStrong)
                            }
                        }
                    }
                }

                BakeCard {
                    VStack(alignment: .leading, spacing: BakeSpace.s4) {
                        BakeCardHeader(title: "การดำเนินการ", icon: .settings)

                        VStack(spacing: BakeSpace.s2) {
                            if draft != nil {
                                BakeButton(
                                    title: "ตรวจสอบอีกครั้ง",
                                    icon: .refresh,
                                    variant: .secondary,
                                    block: true,
                                    isLoading: isScanning
                                ) { rescan(order) }

                                BakeButton(title: "กลับไปแก้ไข", icon: .edit, variant: .ghost, block: true, isEnabled: !isScanning) {
                                    router.go(.packing(order.id), in: .packing)
                                }

                                BakeButton(
                                    title: "ยืนยันผลตรวจสอบ",
                                    icon: .shield,
                                    variant: .success,
                                    block: true,
                                    isEnabled: outcome == .passed && !isScanning
                                ) { showConfirm = true }

                                if outcome != .passed {
                                    Text("ต้องให้ทุกรายการตรงกันก่อนจึงจะยืนยันผลได้ (ปัจจุบัน: \(Labels.outcome(outcome ?? .uncertain)))")
                                        .font(BakeFont.tiny)
                                        .foregroundStyle(BakeColor.muted)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            if isVerified {
                                if order.handover == .ready {
                                    BakeButton(title: "ไปหน้าส่งมอบสินค้า", icon: .truck, variant: .success, block: true) {
                                        router.go(.handover(order.id), in: .orders)
                                    }
                                } else {
                                    Notice(tone: .success, icon: .checkCircle) {
                                        Text("ส่งมอบแล้ว" + (order.driver.map { " โดย \($0)" } ?? ""))
                                            .font(BakeFont.small)
                                            .foregroundStyle(BakeColor.successStrong)
                                    }
                                }

                                BakeButton(title: "ดูประวัติการตรวจสอบ", icon: .history, variant: .ghost, block: true) {
                                    router.go(.history(order.id))
                                }
                            }

                            BakeButton(title: "กลับไปยังออเดอร์", icon: .arrowLeft, variant: .ghost, block: true) {
                                router.go(.orderDetail(order.id), in: .orders)
                            }
                        }
                    }
                }

                Notice(tone: .warning, icon: .flask) {
                    Text("ผลการตรวจจับในหน้านี้เป็นข้อมูลจำลอง สำหรับการสาธิต ยังไม่ได้วิเคราะห์ภาพด้วยโมเดล AI จริง")
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.warningStrong)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func rescan(_ order: Order) {
        guard !isScanning else { return }
        isScanning = true
        scanTask?.cancel()
        scanTask = Task {
            try? await Task.sleep(for: .milliseconds(1300))
            guard !Task.isCancelled else { return }
            store.recordScan(orderId: order.id, lines: ScanService.simulate(order: order))
            isScanning = false
            scanTask = nil
            toasts.show(.info, "ตรวจสอบอีกครั้งแล้ว", "ผลการเปรียบเทียบถูกอัปเดตแล้ว")
        }
    }

    @ViewBuilder
    private var confirmDialog: some View {
        if let order = store.order(orderId) {
            let rows = store.comparisons(forOrder: order.id)
            let summary = Verification.summarize(rows: rows)

            ConfirmDialogContent(
                icon: .shield,
                tone: .success,
                title: "ยืนยันผลการตรวจสอบ",
                message: "ยืนยันว่าออเดอร์ \(order.id) มีจำนวนสินค้าครบทุกรายการ",
                confirmTitle: "ยืนยันผลตรวจสอบ",
                confirmVariant: .success,
                detail: {
                    BakeCard {
                        VStack(spacing: BakeSpace.s3) {
                            DefRow(key: "จำนวนรวมที่นับได้", value: "\(summary.totalEffective) ชิ้น")
                            DefRow(key: "รายการที่ตรงกัน", value: "\(summary.matched)/\(rows.count)")
                            if summary.corrected > 0 {
                                DefRow(key: "แก้ไขโดยพนักงาน", value: "\(summary.corrected) รายการ")
                            }
                        }
                    }
                },
                onConfirm: {
                    if store.confirmVerification(orderId: order.id) {
                        toasts.show(.success, "ยืนยันผลตรวจสอบเรียบร้อย", "\(order.id) พร้อมส่งมอบ")
                    }
                },
                onCancel: {}
            )
        }
    }
}
