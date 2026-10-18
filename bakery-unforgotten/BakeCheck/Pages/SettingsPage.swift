//
//  SettingsPage.swift
//  BakeCheck
//
//  Staff profile, store details, notification preferences and demo data.
//

import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toasts: ToastCenter

    @State private var showResetConfirm = false

    private var handedOverCount: Int {
        store.orders.filter { $0.handover == .handedOver }.count
    }

    var body: some View {
        RootPageScaffold(tab: .settings) {
            PageHeader(
                title: "ตั้งค่า",
                subtitle: "ตั้งค่าโปรไฟล์ร้าน การแจ้งเตือน และการตั้งค่าพื้นฐานของระบบ"
            )

            BakeCard {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    BakeCardHeader(title: "โปรไฟล์พนักงาน", icon: .user)

                    HStack(spacing: BakeSpace.s4) {
                        AvatarCircle(initials: store.staff.initials, size: 56)
                        VStack(alignment: .leading, spacing: BakeSpace.s1) {
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

                    Text("ระบบต้นแบบนี้ยังไม่มีระบบบัญชีหรือการยืนยันตัวตนจริง ข้อมูลพนักงานเป็นตัวอย่างสำหรับการสาธิตเท่านั้น")
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            BakeCard {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    BakeCardHeader(title: "ข้อมูลร้าน", icon: .store)

                    VStack(alignment: .leading, spacing: BakeSpace.s2) {
                        Text("ชื่อร้าน")
                            .font(BakeFont.smallStrong)
                            .foregroundStyle(BakeColor.text)
                        BakeTextField(
                            placeholder: "ระบุชื่อร้าน",
                            text: Binding(
                                get: { store.settings.storeName },
                                set: { value in store.updateSettings { $0.storeName = value } }
                            )
                        )
                        Text("ใช้แสดงในส่วนหัวของระบบ")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                    }

                    VStack(alignment: .leading, spacing: BakeSpace.s2) {
                        Text("ภาษาที่ต้องการ")
                            .font(BakeFont.smallStrong)
                            .foregroundStyle(BakeColor.text)
                        Picker("ภาษา", selection: Binding(
                            get: { store.settings.language },
                            set: { value in store.updateSettings { $0.language = value } }
                        )) {
                            ForEach(AppLanguage.allCases, id: \.self) { language in
                                Text(language.title).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("ระบบต้นแบบแสดงผลภาษาไทยเป็นหลัก การตั้งค่านี้เป็นตัวอย่างเท่านั้น")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            BakeCard {
                VStack(alignment: .leading, spacing: BakeSpace.s2) {
                    BakeCardHeader(title: "การแจ้งเตือน", icon: .bell)
                        .padding(.bottom, BakeSpace.s2)

                    BakeSwitchRow(
                        title: "แจ้งเตือนเมื่อพบข้อผิดพลาด",
                        desc: "เตือนทันทีเมื่อจำนวนสินค้าไม่ตรงกับออเดอร์",
                        isOn: Binding(
                            get: { store.settings.notifyMismatch },
                            set: { value in store.updateSettings { $0.notifyMismatch = value } }
                        )
                    )
                    BakeSeparator()
                    BakeSwitchRow(
                        title: "แจ้งเตือนเมื่อพร้อมส่งมอบ",
                        desc: "แจ้งเมื่อออเดอร์ผ่านการตรวจสอบและพร้อมส่งมอบ",
                        isOn: Binding(
                            get: { store.settings.notifyHandover },
                            set: { value in store.updateSettings { $0.notifyHandover = value } }
                        )
                    )
                    BakeSeparator()
                    BakeSwitchRow(
                        title: "สรุปภาพรวมรายวัน",
                        desc: "สรุปจำนวนออเดอร์และข้อผิดพลาดในแต่ละวัน",
                        isOn: Binding(
                            get: { store.settings.notifyDailySummary },
                            set: { value in store.updateSettings { $0.notifyDailySummary = value } }
                        )
                    )
                    BakeSeparator()
                    BakeSwitchRow(
                        title: "ไปยังหน้าผลตรวจสอบอัตโนมัติ",
                        desc: "นำทางไปหน้าผลการตรวจสอบทันทีหลังยืนยันผลสำเร็จ",
                        isOn: Binding(
                            get: { store.settings.autoAdvance },
                            set: { value in store.updateSettings { $0.autoAdvance = value } }
                        )
                    )
                }
            }

            BakeCard {
                VStack(alignment: .leading, spacing: BakeSpace.s4) {
                    BakeCardHeader(title: "ข้อมูลสาธิต", icon: .flask)

                    VStack(spacing: BakeSpace.s3) {
                        DefRow(key: "ออเดอร์ในระบบ", value: "\(store.orders.count) รายการ")
                        DefRow(key: "บันทึกการตรวจสอบ", value: "\(store.scans.count) รายการ")
                        DefRow(key: "ส่งมอบแล้ว", value: "\(handedOverCount) รายการ")
                    }

                    Notice(tone: .warning, icon: .alertTriangle) {
                        Text("ข้อมูลถูกเก็บไว้ในเครื่องของคุณ (UserDefaults) เพื่อการสาธิต การรีเซ็ตจะล้างข้อมูลทั้งหมดและคืนค่าข้อมูลตัวอย่างเริ่มต้น")
                            .font(BakeFont.small)
                            .foregroundStyle(BakeColor.warningStrong)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    BakeButton(title: "รีเซ็ตข้อมูลสาธิต", icon: .refresh, variant: .dangerOutline, block: true) {
                        showResetConfirm = true
                    }
                }
            }

            BakeCard {
                VStack(alignment: .leading, spacing: BakeSpace.s3) {
                    BakeCardHeader(title: "เกี่ยวกับต้นแบบ", icon: .info)

                    Text("BakeCheck เป็นต้นแบบสำหรับสาธิตขั้นตอนตรวจสอบจำนวนสินค้าก่อนส่งมอบ โดยใช้ผลการตรวจจับแบบจำลอง (ไม่ใช่ AI จริง) ทุกจุดที่ใช้ข้อมูลจำลองจะมีป้าย “โหมดสาธิต” หรือ “ผลจำลอง” กำกับไว้เสมอ")
                        .font(BakeFont.small)
                        .foregroundStyle(BakeColor.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: BakeSpace.s2) {
                        Badge(text: "ต้นแบบ", tone: .brand)
                        Badge(text: "ผลจำลอง", tone: .warning)
                        Badge(text: "ไม่มีการวิเคราะห์ภาพจริง", tone: .neutral)
                    }
                }
            }
        }
        .sheet(isPresented: $showResetConfirm) {
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
}
