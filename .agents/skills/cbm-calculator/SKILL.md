---
name: cbm-calculator
description: Calculate CBM (Cubic Meters), Volumetric Weight, Air Chargeable Weight, Container Recommendations, and standalone calculation sessions for shipments in ImportFlow ERP.
---

# Cargo Measurement Engine Skill (BP-004)

Use this skill when implementing, calculating, or testing cargo measurements and container allocation in ImportFlow ERP.

## Core Calculation Rules

### 1. Unit Normalization
Convert all input dimensions and weights before performing calculations:
- `mm` -> `cm`: `/ 10`
- `m` -> `cm`: `* 100`
- `lb` -> `kg`: `* 0.45359237`

### 2. Standard Formulas
- **Cargo Volume (CBM):**
  $$\text{CBM} = \frac{\text{Length (cm)} \times \text{Width (cm)} \times \text{Height (cm)}}{1,000,000} \times \text{Quantity}$$
- **Air Volumetric Weight (kg):**
  $$\text{Air Volumetric Wt} = \frac{\text{Length (cm)} \times \text{Width (cm)} \times \text{Height (cm)}}{6,000} \times \text{Quantity}$$
- **Air Chargeable Weight (kg):**
  $$\text{Chargeable Weight} = \max(\text{Total Gross Weight (kg)}, \text{Total Air Volumetric Weight (kg)})$$

### 3. Shipping Method & Container Recommendation Rules
- **Air Freight:** Total CBM $\le 1.5 \text{ m}^3$ and Gross Weight $\le 300 \text{ kg}$.
- **LCL Ocean Freight:** Total CBM $\le 15.0 \text{ m}^3$.
- **FCL Ocean Freight:** Total CBM $> 15.0 \text{ m}^3$:
  - `20FT Standard Container (20' ST)`: Volume up to $33.0 \text{ m}^3$.
  - `40FT Standard Container (40' ST)`: Volume up to $67.0 \text{ m}^3$.
  - `40FT High Cube Container (40' HC)`: Volume up to $76.0 \text{ m}^3$.
  - Multi-container allocation: $\lceil \text{Total CBM} / 76.0 \rceil \times \text{40' HC Containers}$.

### 4. Operational Standalone & Session Persistence
- Calculation sessions can run as an interactive standalone tool before shipment assignment (`CALC-YYYY-XXX`).
- Saved calculation logs can be linked/bound to Purchase Orders (`po_id`) or Projects (`project_id`) at any time.
