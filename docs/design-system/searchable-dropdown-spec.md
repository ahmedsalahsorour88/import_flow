# 🔍 Searchable Dropdown Specification

## 📌 Overview
Enforces the mandatory use of `SearchableDropdownField<T>` across all foreign key and master data selection inputs in ImportFlow ERP.

---

## 🚫 Forbidden Patterns
- ❌ Standard `DropdownButtonFormField` (unusable with >20 records).
- ❌ Plain text `TextField` for reference IDs.

---

## ✅ Mandatory Adoption Scope
1. `HS Code` (Egyptian Customs Tariff - 74+ codes)
2. `Country` & Origin (200+ countries)
3. `Transport Locations & Ports` (247+ ports)
4. `Importing Companies` (Tax ID & Commercial Reg)
5. `Foreign Suppliers`
6. `Incoterms 2020`
7. `Import Projects`
8. `Partners & Banks` (Shipping lines, brokers, banks)
9. `Purchase Orders Linkage`

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Zero instances of `DropdownButtonFormField` remain for master data selection.
- [ ] Dropdown includes live filter search bar with keyboard navigation support.
- [ ] Displays both code and localized name (e.g. `ALX - Alexandria Port (ميناء الإسكندرية)`).
