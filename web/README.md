# BakeCheck 🥐

**ระบบตรวจสอบจำนวนสินค้าเบเกอรีก่อนส่งมอบ** — a front-end prototype for a Hackathon project.

Bakery staff sometimes pack the wrong number of items. When delivery drivers collect the
order and the customer finds the mistake, the driver gets the complaint even though the
error happened during packing. **BakeCheck** verifies the actual products against the
customer's order **before** the order leaves the shop.

Core workflow:

```
เลือกออเดอร์ → จัดเตรียมสินค้า → สแกนสินค้า → เทียบจำนวน
→ แก้ไขข้อผิดพลาด → ยืนยันผล → ส่งมอบให้พนักงานขับรถ
```

---

## ⚠️ What is simulated

This is a **frontend prototype only**. There is no backend, database, or AI model.

| Area | Status |
| --- | --- |
| Order data | Mock data in `src/data/` (kept in `localStorage` for the session) |
| Product detection | **Simulated** — scripted results in `src/data/simulations.ts` |
| Camera | Real `getUserMedia` stream, but the captured frame is **not analysed** |
| Persistence | Browser `localStorage` only — does not sync across devices |
| Authentication | None — a sample staff profile is hard-coded |

The UI labels every simulated result as `โหมดสาธิต` / `ผลจำลอง` so nothing implies that a
real AI model produced it.

---

## Getting started

```bash
cd web
npm install
npm run dev        # http://localhost:5173
```

Other commands:

```bash
npm run build      # type-check (tsc -b) + production build
npm run lint       # oxlint
npm run check      # logic smoke test for the verification workflow
npm run preview    # preview the production build
```

> The camera requires a secure context. `localhost` works; a plain-HTTP LAN address
> does not. If the camera is blocked or unavailable, use **“ตรวจสอบด้วยการจำลอง”**.

---

## Pages

| Route | Page | Purpose |
| --- | --- | --- |
| `#/dashboard` | ภาพรวม | Order statistics, quick actions, recent orders |
| `#/orders` | จัดการออเดอร์ | Search / filter orders, open order detail drawer |
| `#/packing` | ตรวจสอบสินค้า | **Packing Station** — camera + scan + quantity comparison |
| `#/result/:orderId` | ผลการตรวจสอบ | Verification result, re-check, confirm |
| `#/handover` | ส่งมอบสินค้า | Confirm handover to a delivery driver |
| `#/history` | ประวัติออเดอร์ | Verification history with filters |
| `#/settings` | ตั้งค่า | Store profile, language, notification preferences |

---

## Business rules enforced

- An order **cannot** be confirmed while any line is mismatched or uncertain.
- An uncertain detection always requires manual review (it is never treated as correct).
- A staff correction **re-runs the comparison** but does **not** auto-verify the order —
  an explicit confirmation is required.
- An unverified order **cannot** be handed over.
- An order **cannot** be handed over twice.
- Dashboard metrics and history are derived from the same order state (single source of truth).

---

## Project structure

```
src/
  components/
    icons/         Inline SVG icon set (no icon dependency)
    layout/        AppShell, Sidebar, Topbar, PageRouter, nav config
    orders/        Order table, detail drawer, action helpers
    ui/            Button, Card, Badge, Modal, ConfirmDialog, Toast, ...
    verification/  CameraPanel, ComparisonList, ResultBanner, EditQuantityDialog
  data/            Mock orders, products, staff, simulations, history
  hooks/           useCamera (lifecycle-managed MediaStream)
  pages/           One component per route
  store/           DataContext (reducer + localStorage), NavContext, ToastContext
  styles/          Design tokens + base/layout/components/pages CSS
  types/           Domain types
  utils/           verification, scan (mock detector), format, labels, route, order
scripts/
  logic-check.ts   Runnable smoke test of the verification rules
```

State lives in a single reducer (`src/store/DataContext.tsx`). Pages never duplicate order
data — they read from the store and dispatch actions.

---

## Design system

Earth-tone palette defined as CSS variables in `src/styles/tokens.css`
(`--color-cream`, `--color-sand`, `--color-dune`, `--color-terra`, `--color-bark`,
`--color-wood`) with muted semantic status colors for success / error / warning / neutral.
Typography uses **Noto Sans Thai** with system sans-serif fallbacks.

---

## Integrating real AI product detection

The mock detector is isolated on purpose. To use a real model:

1. Replace `simulateScan()` in `src/utils/scan.ts` with a call to your service. It only
   needs to return `ScanLine[]`:
   ```ts
   { productId: string; detectedQty: number | null; confidence: number | null }
   ```
   Return `detectedQty: null` when the model is not confident — the UI already routes
   those lines to manual review.
2. Delete `src/data/simulations.ts`.
3. Everything else — comparison rules (`src/utils/verification.ts`), verification gating,
   handover rules and the whole UI — keeps working unchanged.
4. For production, move order state from `localStorage` to a real backend and add the
   capture upload in `CameraPanel`.

**Recommended next steps:** object detection / counting model (e.g. a fine-tuned YOLO or
RT-DETR) behind an HTTP endpoint, a barcode/SKU fallback for packaged items, server-side
order storage, and an audit log of who verified and handed over each order.
