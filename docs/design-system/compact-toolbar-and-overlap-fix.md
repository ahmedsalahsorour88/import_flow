# 🗜️ Single Unified Compact Toolbar & Popover Anti-Collision Rule

## 📌 Overview
Eliminates vertical bloat and UI overlaps on Type B list screens to ensure maximum visible data rows on standard 1366x768 laptop displays.

---

## 📏 Compact Toolbar Specifications
1. **Single Unified Row (`ActionToolbar`):**
   - Height: Max 40px (Comfortable: 40px, Compact: 34px, Ultra-Compact: 30px).
   - Total Action Area Height: Max 80-90px including all margins and padding.
2. **Visible Action Limit:**
   - Max 3 visible primary/secondary buttons.
   - All secondary, batch, and AI actions moved into `More actions ⋮` dropdown menu.
3. **Inline Search & Filters:**
   - Search text input (width 180-220px, height 32px) and filter dropdowns placed on the opposite side within the **same single row**.
4. **Data Visibility Mandate:**
   - At least **4 to 5 full data rows** must be visible above the fold on 1366x768 displays without scrolling.

---

## 🪟 Popover Anti-Collision Rules
1. **Strictly Under Trigger:** Popups must specify `position: PopupMenuPosition.under`.
2. **Smart Flip (Right-to-Left):** When triggered near the right edge of the screen, popups must extend leftward into empty space rather than clipping offscreen or covering navigation buttons.
3. **Solid Background:** Non-transparent background with `elevation: 6` and `BorderRadius.circular(8)`.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Toolbar height does not exceed 40px in comfortable mode.
- [ ] At least 4-5 table rows are visible on a 1366x768 viewport upon initial load.
- [ ] Popup menus open underneath triggers and never cover the header title or Back button.
- [ ] Verified across `ImportFilesScreen`, `PurchaseOrdersScreen`, and `CustomsTariffScreen`.
