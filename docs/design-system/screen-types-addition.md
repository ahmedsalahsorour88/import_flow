# 🎨 Screen Types Classification & Button Color Palette Matrix

## 📌 Overview
Enforces strict visual distinction between screen types across ImportFlow ERP to prevent UI bleed and inconsistent styling.

---

## 🏛️ Screen Types
1. **Type A — Stage / Review Screens (شاشات المراحل والمراجعة):**
   - Centered on managing a specific import lifecycle stage for a shipment.
   - Header contains Stage Badge + full lifecycle controls.
2. **Type B — List / Index Screens (شاشات الجداول والقوائم الرئيسية):**
   - Baseline: `ImportFilesScreen`.
   - Header contains Icon + Title ONLY (**❌ No Stage Badge**).
   - Max 2 header actions: Primary Action (e.g. `Add New`) + `Back to Dashboard`.
   - Compact single-row toolbar immediately above the data table.
3. **Type C — Utility / Dashboard Screens (الشاشات الخدمية ولوحات القيادة):**
   - Examples: `OperationalDashboardScreen`, `LifecycleBoardScreen`, `CbmCalculatorScreen`.
   - Customized analytics and workflow visualizations.

---

## 🎨 Mandatory Button Color Palette Matrix

| Purpose / Action Type | Approved Color | Example | Style / Variant |
|:---|:---|:---|:---|
| **Primary Action** | Cobalt Solid (`#3498DB`) | `Add New Import File`, `Upload Document` | `ElevatedButton` / `AppButtonVariant.primary` |
| **Secondary Action** | Blue Outline / White BG | `Search & Clone`, `Back to Dashboard` | `OutlinedButton` / `AppButtonVariant.outline` |
| **Neutral Utility Action** | Charcoal Solid (`#2C3E50`) | `Generate Report`, Refresh 🔄 | `AppTheme.charcoal` |
| **AI Feature** | Emerald Solid (`#27AE60`) | `Smart Invoice Extractor`, `AI Suggest` | `AppTheme.emerald` + `Icons.auto_awesome` |
| **Destructive / Stop Action** | Crimson Solid (`#C0392B`) | `Stop Shipment`, `Delete Record` | `AppButtonVariant.danger` |
| **Warning / Skip Action** | Orange Outline (`#E67E22`) | `Skip Step`, `Revert Action` | `AppTheme.orange` Outlined |
| **Export to Excel** | Emerald Solid (`#27AE60`) | `Export Excel`, `Export CSV` | `Icons.table_chart` + Green |
| **Export to PDF** | Crimson Solid (`#C0392B`) | `Export PDF`, `Print PDF` | `Icons.picture_as_pdf` + Red |

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] No Type B list screen displays a Stage Badge in its header.
- [ ] All primary buttons use Cobalt `#3498DB`, never random greens or purples.
- [ ] All AI buttons use Emerald `#27AE60` with sparkle icon.
- [ ] All destructive/delete buttons use Crimson `#C0392B`.
- [ ] All Excel export buttons use Emerald green; PDF export buttons use Crimson red.
