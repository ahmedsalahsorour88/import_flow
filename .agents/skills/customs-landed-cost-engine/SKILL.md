---
name: customs-landed-cost-engine
description: Calculate Customs Duties, Taxes (VAT, WHT), Fees, and Landed Cost breakdown for imported goods.
---

# Customs & Landed Cost Engine Skill

Use this skill when implementing calculation logic for customs duties, taxes, and landed cost.

## Calculation Formula

`Landed Cost = Purchase Cost + Freight + Insurance + Customs Duty + VAT + WHT + Clearance Fees + Local Logistics + Other Import Expenses`

## Key Principles
1. Cost Breakdown Integrity: System MUST preserve each cost component line item, not just store a single aggregated total sum.
2. Dynamic Tax Rules: Never hardcode rates (e.g. VAT = 14%). Fetch active rates based on effective date range (`effective_from`, `effective_to`).
3. Currency Conversion: Apply the official customs exchange rate valid at the declaration date.
