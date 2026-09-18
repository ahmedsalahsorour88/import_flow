# 📐 Typography & Display Density Scale Specification

## 📌 Overview
Defines application-wide typography, font scaling, and density modes (`Comfortable`, `Compact`, `Ultra-Compact`).

---

## 🎚️ Density Scaling Matrix

| Metric / Property | Comfortable (Default) | Compact | Ultra-Compact |
|:---|:---:|:---:|:---:|
| **Target Viewport** | 1920x1080 & 4K | 1366x768 Laptops | High-Density Data Work |
| **Page Header Height** | 54-58 px | 48-52 px | 42-46 px |
| **Toolbar Height** | 40 px | 34 px | 30 px |
| **Metric Strip Height** | 42 px | 34 px | 28 px |
| **Table Row Height** | 44 px | 36 px | 30 px |
| **Base Font Scale** | 1.0 (13-14 pt) | 0.92 (12-12.5 pt) | 0.85 (11-11.5 pt) |
| **Form Field Padding** | 12x12 px | 10x8 px | 8x6 px |

---

## 🔒 Central Placement Rule
- Density control is a **global persistent preference** located in the top application bar or settings menu.
- It is strictly forbidden to embed independent density toggle buttons inside individual screen action toolbars.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Changing density adjusts headers, toolbars, metric strips, form inputs, and table rows simultaneously.
- [ ] Ultra-Compact mode increases visible table rows by >= 30% without text clipping.
- [ ] No duplicate per-screen density buttons exist.
