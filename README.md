# BakeCheck 🥐

**ระบบตรวจสอบจำนวนสินค้าเบเกอรีก่อนส่งมอบ** — a Swift hackathon prototype (SwiftUI, iOS).

Bakery staff sometimes pack the wrong number of items. When the delivery driver collects the
order and the customer finds the mistake, the driver gets the complaint even though the error
happened during packing. **BakeCheck** verifies the actual products against the customer's order
**before** the order leaves the shop.

Core workflow:

```
เลือกออเดอร์ → จัดเตรียมสินค้า → สแกนสินค้า → เทียบจำนวน
→ แก้ไขข้อผิดพลาด → ยืนยันผล → ส่งมอบให้พนักงานขับรถ
```

---

## Run it

A native SwiftUI app targeting **iOS 27** (also builds for macOS). No third-party dependencies.

> **Requires Xcode 26 or newer** (iOS 26 SDK) — the UI uses Liquid Glass APIs
> (`glassEffect`, `tabBarMinimizeBehavior`). They are gated behind `#available`,
> but the SDK must know them at compile time, so an older Xcode will not build.

```bash
open bakery-unforgotten.xcodeproj     # then ⌘R in Xcode
```

Or from the command line:

```bash
xcodebuild -project bakery-unforgotten.xcodeproj \
           -scheme bakery-unforgotten \
           -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
           -configuration Debug build
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so any `.swift` file added under
`bakery-unforgotten/` is picked up automatically — no `project.pbxproj` edits are needed.

---

## ⚠️ What is simulated

The app has no backend, database, or AI service — it is a **UI prototype**.

| Area | Status |
| --- | --- |
| Order data | Mock data, kept on-device in `UserDefaults` |
| Product detection | **Simulated** — scripted, deterministic per-order results |
| Camera | Real `AVCaptureSession` capture, but the frame is **not analysed** |
| Persistence | Device-local only — does not sync across devices |
| Authentication | None — a sample staff profile is hard-coded |

Every simulated result is labelled `โหมดสาธิต` / `ผลจำลอง` in the UI, so nothing implies that a
real AI model produced it. `ScanService.simulate(order:)` is the only place that knows about the
fake detector — swapping it for a real vision service does not touch the rules, store or views.

---

## Design

The UI is built to feel native to modern iOS, not ported from the web:

- **Liquid Glass** (iOS/macOS 26+) on the primary buttons, navigation bars and the minimizing
  tab bar, with an `.ultraThinMaterial` fallback on older systems (gated by `#available`).
- **Native navigation** — real large titles + toolbars (no custom header bar).
- **Native Settings** built on `Form` (grouped sections, system toggles and pickers).
- **Dark Mode** support throughout: every surface/text/status colour is an appearance-aware
  light/dark pair, while the warm bakery palette stays as the accent.
- **Dynamic Type** — typography maps to relative text styles so it scales with the system.
- Decluttered for a 5-minute pitch: the packing station is just **capture → compare → confirm**.

### Screens

Two tabs; everything else is pushed on top so the tab bar stays calm.

| Tab | Screen | Notes |
| --- | --- | --- |
| ตรวจสอบสินค้า | **Packing Station** | Default screen. Order picker lives in the toolbar. |
| ตั้งค่า | Settings | Store details, notifications, demo data, entrance to the dashboard |

Pushed: ภาพรวม (Dashboard), จัดการออเดอร์, รายละเอียดออเดอร์, ผลการตรวจสอบ, ส่งมอบสินค้า, ประวัติออเดอร์.

### Business rules (enforced in the store, not the views)

| Rule | Where |
| --- | --- |
| Scan a missing/extra/uncertain product → order becomes `พบข้อผิดพลาด` / `ต้องตรวจสอบเพิ่มเติม` | `AppStore.recordScan` |
| Cannot verify while any line is missing, extra or uncertain | `Verification.isVerifiable`, `AppStore.confirmVerification` |
| Uncertain detection → human manual review | `Verification.outcome` |
| Mismatch blocks handover | `AppStore.handOver` |
| Staff correction re-runs the whole comparison immediately | `AppStore.setManualQty` |
| A corrected line is flagged `แก้ไขโดยพนักงาน` in history | `ComparisonRow.corrected` |
| An order can be handed over exactly once | `AppStore.handOver` |
| Handed-over orders are frozen | `AppStore.recordScan` |

---

## Layout

- `Core/` — models, design system (colours, type, Liquid Glass helpers), SF Symbol mapping,
  `Verification` rules, simulated scanner, Thai formatters
- `Data/SeedData.swift` — products, staff, drivers, settings, seed orders and scan records
- `State/` — `AppStore` (single source of truth + persistence), `Router`, `ToastCenter`
- `Components/` — buttons, cards, comparison list, result banner, sheets, camera panel, decor
- `Pages/` — one file per screen
- `RootView.swift` — `TabView` shell, navigation stacks, destination routing

---

## Business-rule check

A CLI harness compiles the app's *real* `Core`/`Data`/`State` sources and exercises the rules —
no duplicate implementation, no simulator needed (requires a Mac with a Swift toolchain):

```bash
./ios-scripts/logic-check.sh
```

It covers classification, comparison rows, outcome precedence, verification gating, summary
arithmetic, the simulated detector profiles, seed-data integrity, the full store lifecycle
(scan → correct → confirm → hand over → frozen), notifications, settings and Thai label/format text.

---

## Next steps for real detection

1. Replace `ScanService.simulate(order:)` with a call to a vision service.
2. Return the same shape (`[ScanLine]` with `productId`, `detectedQty`, `confidence`).
3. Keep `confidence` below the threshold for anything uncertain — the store already routes those to
   manual review.
4. Drop the `โหมดสาธิต` label once results are real.
