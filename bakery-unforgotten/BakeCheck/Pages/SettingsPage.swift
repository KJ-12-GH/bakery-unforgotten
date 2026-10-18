//
//  SettingsPage.swift
//  BakeCheck
//
//  Staff profile, store details, notification preferences and demo data —
//  built on a native `Form` so it reads exactly like a system settings screen
//  (grouped sections, native toggles and pickers, Dynamic Type), with the warm
//  bakery backdrop showing through.
//

import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toasts: ToastCenter

    @State private var showResetConfirm = false

    private var handedOverCount: Int {
        store.orders.filter { $0.handover == .handedOver }.count
    }

    var body: some View {
        Form {
            profileSection
            storeSection
            notificationsSection
            dashboardSection
            demoSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(BakeAmbientBackground())
        .tint(BakeColor.terra)
        .navigationTitle("ตั้งค่า")
        .sheet(isPresented: $showResetConfirm) { resetDialog }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            HStack(spacing: BakeSpace.s4) {
                AvatarCircle(initials: store.staff.initials, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.staff.name)
                        .font(BakeFont.cardTitle)
                        .foregroundStyle(BakeColor.text)
                    Text(store.staff.role)
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.muted)
                    Badge(text: store.staff.store, tone: .brand)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        } footer: {
            Text("ระบบต้นแบบนี้ยังไม่มีการยืนยันตัวตนจริง ข้อมูลพนักงานเป็นตัวอย่างสำหรับการสาธิต")
        }
        .listRowBackground(BakeColor.surface)
    }

    // MARK: - Store

    private var storeSection: some View {
        Section("ข้อมูลร้าน") {
            LabeledContent("ชื่อร้าน") {
                TextField("ระบุชื่อร้าน", text: Binding(
                    get: { store.settings.storeName },
                    set: { value in store.updateSettings { $0.storeName = value } }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(BakeColor.text)
            }

            Picker("ภาษาที่ต้องการ", selection: Binding(
                get: { store.settings.language },
                set: { value in store.updateSettings { $0.language = value } }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.title).tag(language)
                }
            }
        }
        .listRowBackground(BakeColor.surface)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("การแจ้งเตือน") {
            toggle(
                "แจ้งเตือนเมื่อพบข้อผิดพลาด",
                "เตือนทันทีเมื่อจำนวนสินค้าไม่ตรงกับออเดอร์",
                get: { store.settings.notifyMismatch },
                set: { $0.notifyMismatch = $1 }
            )
            toggle(
                "แจ้งเตือนเมื่อพร้อมส่งมอบ",
                "แจ้งเมื่อออเดอร์ผ่านการตรวจสอบและพร้อมส่งมอบ",
                get: { store.settings.notifyHandover },
                set: { $0.notifyHandover = $1 }
            )
            toggle(
                "สรุปภาพรวมรายวัน",
                "สรุปจำนวนออเดอร์และข้อผิดพลาดในแต่ละวัน",
                get: { store.settings.notifyDailySummary },
                set: { $0.notifyDailySummary = $1 }
            )
            toggle(
                "ไปหน้าผลตรวจสอบอัตโนมัติ",
                "นำทางไปหน้าผลการตรวจสอบทันทีหลังยืนยันผลสำเร็จ",
                get: { store.settings.autoAdvance },
                set: { $0.autoAdvance = $1 }
            )
        }
        .listRowBackground(BakeColor.surface)
    }

    private func toggle(
        _ title: String,
        _ desc: String,
        get: @escaping () -> Bool,
        set: @escaping (inout AppSettings, Bool) -> Void
    ) -> some View {
        Toggle(isOn: Binding(
            get: get,
            set: { value in store.updateSettings { set(&$0, value) } }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BakeFont.body)
                    .foregroundStyle(BakeColor.text)
                Text(desc)
                    .font(BakeFont.tiny)
                    .foregroundStyle(BakeColor.muted)
            }
        }
    }

    // MARK: - Dashboard entrance

    /// The dashboard lives in settings so the tab bar only holds the two areas
    /// staff touch every day.
    private var dashboardSection: some View {
        Section {
            Button {
                router.go(.dashboard)
            } label: {
                HStack(spacing: BakeSpace.s3) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BakeColor.bark)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ศูนย์ควบคุมร้าน")
                            .font(BakeFont.body)
                            .foregroundStyle(BakeColor.text)
                        Text("ภาพรวม ออเดอร์ และประวัติการตรวจสอบ")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BakeColor.dune)
                }
            }
        }
        .listRowBackground(BakeColor.surface)
    }

    // MARK: - Demo data

    private var demoSection: some View {
        Section("ข้อมูลสาธิต") {
            LabeledContent("ออเดอร์ในระบบ", value: "\(store.orders.count) รายการ")
            LabeledContent("บันทึกการตรวจสอบ", value: "\(store.scans.count) รายการ")
            LabeledContent("ส่งมอบแล้ว", value: "\(handedOverCount) รายการ")

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("รีเซ็ตข้อมูลสาธิต", systemImage: "arrow.clockwise")
            }
        } footer: {
            Text("ข้อมูลถูกเก็บในเครื่องนี้ (UserDefaults) เพื่อการสาธิต การรีเซ็ตจะล้างข้อมูลทั้งหมดและคืนค่าตัวอย่างเริ่มต้น")
        }
        .listRowBackground(BakeColor.surface)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("เกี่ยวกับต้นแบบ") {
            Text("BakeCheck เป็นต้นแบบสำหรับสาธิตขั้นตอนตรวจสอบจำนวนสินค้าก่อนส่งมอบ โดยใช้ผลการตรวจจับแบบจำลอง (ไม่ใช่ AI จริง) ทุกจุดที่ใช้ข้อมูลจำลองจะมีป้าย “โหมดสาธิต” หรือ “ผลจำลอง” กำกับเสมอ")
                .font(BakeFont.small)
                .foregroundStyle(BakeColor.muted)

            HStack(spacing: BakeSpace.s2) {
                Badge(text: "ต้นแบบ", tone: .brand)
                Badge(text: "ผลจำลอง", tone: .warning)
            }
        }
        .listRowBackground(BakeColor.surface)
    }

    // MARK: - Reset confirmation

    private var resetDialog: some View {
        ConfirmDialogContent(
            icon: .alertTriangle,
            tone: .warning,
            title: "ยืนยันการรีเซ็ตข้อมูลสาธิต",
            message: "การดำเนินการนี้จะล้างออเดอร์และประวัติการตรวจสอบทั้งหมด แล้วคืนค่าข้อมูลตัวอย่างเริ่มต้น",
            confirmTitle: "รีเซ็ตข้อมูล",
            confirmVariant: .dangerOutline,
            detail: {
                BakeCard {
                    VStack(spacing: BakeSpace.s3) {
                        DefRow(key: "ออเดอร์ที่จะถูกล้าง", value: "\(store.orders.count) รายการ")
                        DefRow(key: "ประวัติที่จะถูกล้าง", value: "\(store.scans.count) รายการ")
                    }
                }
            },
            onConfirm: {
                store.resetDemo()
                toasts.show(.info, "รีเซ็ตข้อมูลแล้ว", "ระบบกลับสู่ข้อมูลตัวอย่างเริ่มต้น")
            },
            onCancel: {}
        )
    }
}
