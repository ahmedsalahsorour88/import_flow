# 🏛️ Baseline Stage Screen Specification (Type A Screens)

## 📌 Overview
Type A screens are **Stage / Review Screens** designed to manage a specific operational stage for an import file (e.g., Draft Documents Review, Customs Clearance, Bank Form 4, Nafeza ACID).
The official system reference baseline is **`ShipmentDraftDocumentsReviewScreen`** (`ShipmentDraftDocsScreen`).

---

## 📐 Layout & Header Structure
1. **Header Component (`DedicatedStageScaffold` / Stage Header):**
   - **Leading Area:** Screen Icon + Screen Title (e.g. 'مراجعة مسودات المستندات') + **Mandatory Stage Badge** (e.g. `PHASE-05` or `STEP_08_BL`).
   - **Trailing Action Area (Top-Right):** Standardized Stage Lifecycle Controls in strict visual order:
     1. `Skip Step` (Orange outline button `AppTheme.orange`).
     2. `Stop Shipment` (Crimson solid button `AppTheme.crimson`).
     3. `Clone Shipment` (Blue outline button).
     4. `AI Assistant` (Emerald solid button `AppTheme.emerald` + `Icons.auto_awesome`).
     5. `Refresh Data` (Icon button 🔄).
     6. `Back to Dashboard` (`BackToDashboardButton` — **Always positioned last at the far right**).

2. **Stage Progression & Automation Rules:**
   - Actions must validate stage entry prerequisites before allowing progression.
   - Successful actions automatically elevate file progress percentage and advance `current_stage` and `current_module`.
   - Downstream SmartTasks must be dispatched automatically to responsible staff.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Screen displays a distinct Stage Badge in the header.
- [ ] Top-right actions include `Skip Step` (orange), `Stop Shipment` (red), and `Back to Dashboard` at the far right.
- [ ] No table rows or body content are obstructed by the stage header.
- [ ] Automatic stage progression updates both the local screen and central `ImportFile`.
- [ ] Manual verification completed on at least 2 Type A screens.
