# 🧱 Component Consolidation & Density Wiring Specification

## 📌 Overview
Mandates the use of shared core widgets from `frontend/lib/core/widgets/` to eliminate fragmented, ad-hoc UI implementations across 67 screens.

---

## 🧩 Shared Core Components
1. **`PageHeader` (`page_header.dart`):**
   - Standardized app bar for Type B and Type C screens.
   - Built-in Dark Charcoal background, back navigation, and title hierarchy.
2. **`ActionToolbar` (`action_toolbar.dart`):**
   - Single-row action bar integrating primary buttons, dropdown menu, search bar, and export icons.
3. **`MetricCardStrip` (`metric_card.dart`):**
   - Unified single-row KPI strip with vertical dividers.
4. **`AppDataTable` / `EnterpriseDataTable`:**
   - Standard data table supporting density row heights, sorting, selection, and pagination.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] All list screens import and use `PageHeader` instead of custom `AppBar` or `Container` headers.
- [ ] All list screens use `ActionToolbar` instead of multi-row `Wrap` or `Column` button areas.
- [ ] All shared components consume `displayDensityProvider` dynamically.
