# 📊 Compact Metric Card Strip Specification

## 📌 Overview
Replaces scattered 2x2 metric card grids with a unified, single-row metric strip (`MetricCardStrip`) that preserves vertical space.

---

## 📐 Layout Rules
1. **Single-Row Container:**
   - All key metrics rendered horizontally inside one bordered container with `VerticalDivider` separators.
2. **Inline Layout:**
   - Format: `[16px Icon] Title: Value` in one line.
3. **Adaptive Density Heights:**
   - Comfortable mode: `42px`
   - Compact mode: `34px`
   - Ultra-Compact mode: `28px`
4. **Value Preservation:**
   - Numeric values are NEVER truncated (`$126,294.00` must always be 100% visible).
   - When horizontal space is tight (<660px), titles switch to short aliases (e.g. `POs`, `Amt`, `CBM`, `Wt`).

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Metric cards render in a single horizontal row, not a multi-row grid.
- [ ] Height scales accurately across Comfortable (42px), Compact (34px), and Ultra-Compact (28px).
- [ ] Numeric values are completely visible with zero ellipsis truncation.
- [ ] Tested on `PurchaseOrdersScreen` and `OperationalDashboardScreen`.
