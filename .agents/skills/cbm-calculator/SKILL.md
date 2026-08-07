---
name: cbm-calculator
description: Calculate CBM (Cubic Meters), Volumetric Weight, and Chargeable Weight for shipments in ImportFlow ERP.
---

# Cargo Measurement Engine Skill

Use this skill when implementing or testing cargo calculations.

## Core Rules
1. Unit Normalization: Convert all input dimensions to meters (m) and weights to kilograms (kg) before performing calculations.
   - `mm` -> `m`: `/ 1000`
   - `cm` -> `m`: `/ 100`
   - `lb` -> `kg`: `* 0.45359237`

2. Formulas:
   - `CBM = Length(m) * Width(m) * Height(m) * Quantity`
   - `Air Volumetric Weight (kg) = (Length(cm) * Width(cm) * Height(cm) / 6000) * Quantity`
   - `Sea Volumetric Weight (kg) = CBM * 1000`
   - `Chargeable Weight = max(Gross Weight, Volumetric Weight)`
