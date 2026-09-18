# 📋 Row & Entity Cloning Specification

## 📌 Overview
Provides standard workflow for duplicating complex transactions (Import Files, Purchase Orders, RFQ Scenarios) while guaranteeing data integrity.

---

## ⚙️ Cloning Engine Rules
1. **Key & Reference Generation:**
   - Primary keys (`id`, `import_file_id`, `po_id`) are cleared.
   - New business reference code generated with `-CLONE` suffix or sequential counter (e.g. `IMP-2026-0089-CLONE`).
2. **Lifecycle Reset:**
   - `status` reset to `"Draft"`.
   - Stage reset to `STEP_01` (0% progress).
   - Clear all approvals (`form4_no`, `acid_number`, `cargox_envelope_id`, `customs_released`).
3. **Preserved Master Data:**
   - Preserve supplier, importer company, line items, HS codes, packaging, quantities, and unit prices.
4. **Modal Review:**
   - Always open `CloneEntityReviewDialog` allowing operator to adjust parameters before saving.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Clone action prompts operator with review modal.
- [ ] Duplicated record generates unique business code with 0 collision risk.
- [ ] Approvals and customs release flags are completely reset to Draft.
