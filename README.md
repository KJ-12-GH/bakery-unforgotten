# BakeCheck 🥐

**ระบบตรวจสอบจำนวนสินค้าเบเกอรีก่อนส่งมอบ** — a Hackathon prototype.

Bakery staff sometimes pack the wrong number of items. When the delivery driver collects the
order and the customer finds the mistake, the driver gets the complaint even though the error
happened during packing. **BakeCheck** verifies the actual products against the customer's order
**before** the order leaves the shop.

Core workflow:

```
เลือกออเดอร์ → จัดเตรียมสินค้า → สแกนสินค้า → เทียบจำนวน
→ แก้ไขข้อผิดพลาด → ยืนยันผล → ส่งมอบให้พนักงานขับรถ
```

There are two implementations of the same product in this repository:

| | Folder | Stack | Status |
| --- | --- | --- | --- |
| Web app | `web/` | React + TypeScript + Vite | Runs in the browser (`npm run dev`) |
| iOS app | `bakery-unforgotten/` | SwiftUI (iOS 27 SDK) | Runs in the Xcode Simulator |

Both share the same design tokens, seed data, business rules and Thai-first copy. Each has its
own README-style notes: see `web/README.md` for the web build, and the **iOS app** section below.

---

## ⚠️ What is simulated

Neither app has a backend, database, camera model or AI service. Both are UI prototypes.

| Area | Status |
| --- | --- |
| Order data | Mock data, kept in `localStorage` (web) / `UserDefaults` (iOS) |
| Product detection | **Simulated** — scripted per-order results |
| Camera | Real capture, but the captured frame is **not analysed** |
| Persistence | Device-local only — does not sync across devices |
| Authentication | None — a sample staff profile is hard-coded |

Every simulated result is labelled `โหมดสาธิต` / `ผลจำลอง` in the UI, so nothing implies that a
real AI model produced it.

---

## iOS app (SwiftUI)

The iOS app is a port of the web app. It targets **iOS 27** and is written in SwiftUI only —
no third-party dependencies.

### Run it

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

The target lists macOS as a supported platform, so **My Mac** also builds and runs. iOS-only APIs
(`navigationBarTitleDisplayMode`, `toolbar(_:for: .navigationBar)`,
`ToolbarItemPlacement.topBarLeading/.topBarTrailing`, `textInputAutocapitalization`) are wrapped in
`Components/PlatformCompat.swift`; on macOS each helper falls back to its native equivalent or a
no-op. Both platforms build cleanly for Debug and Release.

### Screens

The app has **two areas**, and it opens straight into the verification station:

| Tab | Screen | Notes |
| --- | --- | --- |
| ตรวจสอบสินค้า | **Smart Packing Station** | Default screen: capture → compare → correct → confirm |
| ตั้งค่า | Settings | Store details, notifications, demo data, and the entrance to the dashboard |

Everything else is pushed on top of the active area, so the tab bar stays quiet:

| Pushed screen | Reached from |
| --- | --- |
| ภาพรวม (Dashboard) | **the bottom of Settings** — "เปิดหน้า Dashboard" |
| จัดการออเดอร์ | Dashboard → ดูออเดอร์ทั้งหมด, or the station's empty state |
| รายละเอียดออเดอร์ | Order rows, search results, notifications |
| ผลการตรวจสอบ | Packing station, order detail, history |
| ส่งมอบสินค้า | Dashboard, order rows, the result screen |
| ประวัติออเดอร์ | Dashboard → ดูประวัติการตรวจสอบ |

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

### Layout

- `Core/` — models, design tokens, SF Symbol mapping, `Verification` rules, simulated scanner
- `Data/SeedData.swift` — products, staff, drivers, settings, 11 orders, 6 scan records
- `State/` — `AppStore` (single source of truth + persistence), `Router` (2 areas + destinations), `ToastCenter`
- `Components/` — buttons, chips, cards, comparison list, result banner, sheets, camera panel,
  and `Decor.swift` (ambient background, illustrated hero, product glyphs, iPad split layout)
- `Pages/` — one file per screen
- `RootView.swift` — `TabView` shell, scaffolds, destination routing

### Visual language

The UI leans on native Apple patterns rather than the web prototype's flat panels:

- Illustrated gradient hero on every primary screen, with a thin SF Symbol illustration
- Cards with continuous 20pt corners and soft elevation instead of 1px borders
- Product artwork (`ProductGlyph`) in order rows, item lists and the station
- Rounded, `.snappy` numeric transitions on dashboard metrics
- Large in-page titles with a floating back button (native navigation bar kept empty)
- Adaptive layouts: single column on iPhone, balanced two columns on iPad
  (`BakeSplit`), 2–4 stat columns, and a narrower reading column for Settings

`ScanService.simulate` is the only place that knows about the fake detector, so replacing it with
a real computer-vision service does not touch the rules, the store or the views.

### Business-rule check

A CLI harness compiles the app's *real* `Core`/`Data`/`State` sources and exercises the rules —
no duplicate implementation, no simulator needed:

```bash
./ios-scripts/logic-check.sh
```

Latest run: **96 checks, 96 passed, 0 failed** (exit code 0). It covers classification, comparison
rows, outcome precedence, verification gating, summary arithmetic, the simulated detector
profiles, seed-data integrity, the full store lifecycle (scan → correct → confirm → hand over →
frozen), notifications, settings round-trip and Thai label/format text.

---

## Differences from the web app

| Area | Web | iOS |
| --- | --- | --- |
| Navigation | 5-area sidebar | 2 tabs + pushed screens |
| Icons | hand-rolled SVG set | SF Symbols + product emoji glyphs |
| Font | Noto Sans Thai (bundled) | system Thai font (rounded for titles) |
| History date range | from/to date pickers | period chips (ทั้งหมด / วันนี้ / 7 วัน / 30 วัน) |
| Camera | `getUserMedia` | `AVCaptureSession` (`unsupported` on the Simulator, falls back to a simulated scan) |

Everything else — tokens, seed data, wording and rules — is identical.

---

## Next steps for real detection

1. Replace `ScanService.simulate(order:)` with a call to a vision service.
2. Return the same shape (`[ScanLine]` with `productId`, `detectedQty`, `confidence`).
3. Keep `confidence` below the threshold for anything uncertain — the store already routes those to
   manual review.
4. Drop the `โหมดสาธิต` label once results are real.
