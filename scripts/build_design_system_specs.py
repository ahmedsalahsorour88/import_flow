import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
out_dir = ROOT / "docs" / "design-system"
out_dir.mkdir(parents=True, exist_ok=True)

specs = {
    "baseline-stage-screen.md": """# 🏛️ Baseline Stage Screen Specification (Type A Screens)

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
""",

    "screen-types-addition.md": """# 🎨 Screen Types Classification & Button Color Palette Matrix

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
""",

    "compact-toolbar-and-overlap-fix.md": """# 🗜️ Single Unified Compact Toolbar & Popover Anti-Collision Rule

## 📌 Overview
Eliminates vertical bloat and UI overlaps on Type B list screens to ensure maximum visible data rows on standard 1366x768 laptop displays.

---

## 📏 Compact Toolbar Specifications
1. **Single Unified Row (`ActionToolbar`):**
   - Height: Max 40px (Comfortable: 40px, Compact: 34px, Ultra-Compact: 30px).
   - Total Action Area Height: Max 80-90px including all margins and padding.
2. **Visible Action Limit:**
   - Max 3 visible primary/secondary buttons.
   - All secondary, batch, and AI actions moved into `More actions ⋮` dropdown menu.
3. **Inline Search & Filters:**
   - Search text input (width 180-220px, height 32px) and filter dropdowns placed on the opposite side within the **same single row**.
4. **Data Visibility Mandate:**
   - At least **4 to 5 full data rows** must be visible above the fold on 1366x768 displays without scrolling.

---

## 🪟 Popover Anti-Collision Rules
1. **Strictly Under Trigger:** Popups must specify `position: PopupMenuPosition.under`.
2. **Smart Flip (Right-to-Left):** When triggered near the right edge of the screen, popups must extend leftward into empty space rather than clipping offscreen or covering navigation buttons.
3. **Solid Background:** Non-transparent background with `elevation: 6` and `BorderRadius.circular(8)`.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Toolbar height does not exceed 40px in comfortable mode.
- [ ] At least 4-5 table rows are visible on a 1366x768 viewport upon initial load.
- [ ] Popup menus open underneath triggers and never cover the header title or Back button.
- [ ] Verified across `ImportFilesScreen`, `PurchaseOrdersScreen`, and `CustomsTariffScreen`.
""",

    "compact-metric-strip.md": """# 📊 Compact Metric Card Strip Specification

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
""",

    "typography-density-scale.md": """# 📐 Typography & Display Density Scale Specification

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
""",

    "component-consolidation-and-density-wiring.md": """# 🧱 Component Consolidation & Density Wiring Specification

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
""",

    "row-clone-spec.md": """# 📋 Row & Entity Cloning Specification

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
""",

    "searchable-dropdown-spec.md": """# 🔍 Searchable Dropdown Specification

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
""",

    "export-save-dialog-fix.md": """# 💾 Native "Save As" File Location Dialog Specification

## 📌 Overview
Prohibits silent/automatic downloads to default temp or downloads folders. Enforces native modal Save As file dialogs.

---

## 🖥️ Platform Implementation Rules
1. **Windows Desktop:**
   - Must use `FilePicker.saveFile` with `lockParentWindow: true` to prevent background window desync.
2. **Web Browser (Chromium):**
   - Must use File System Access API (`window.showSaveFilePicker`).
   - Must gracefully catch `AbortError` on user cancel without throwing errors or fallback auto-download.
3. **Browser Fallback:**
   - Fall back to `<a download>` only if `showSaveFilePicker` is unsupported, with an informative toast notice.
4. **Standard File Naming:**
   - Format: `[Stage Name] - [Import File Code or Name].[ext]`
5. **Interactive Completion Toast:**
   - Shows SnackBar on desktop with 'Open Folder' button (`explorer.exe /select, <path>`).

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Exporting PDF/Excel opens native Windows Save As dialog.
- [ ] Canceling dialog halts export quietly with 0 errors.
- [ ] Saving file triggers SnackBar with functioning 'Open Folder' button.
""",

    "pre-launch-security-checklist.md": """# 🛡️ Pre-Launch Security Checklist (12 Verification Items)

## 📌 Overview
Senior security audit checklist governing application lockdown before production deployment.

---

## 📋 The 12 Verification Items
1. **`.env` in `.gitignore` & No History Secrets:** Verified clean.
2. **SSL / HTTPS Enforced:** HSTS enabled; optional `ENFORCE_HTTPS` redirect.
3. **Dependency Vulnerabilities:** `pip-audit` zero CVEs policy.
4. **Database Connection Security:** Strict ORM AST parameterization; no raw SQL formatting.
5. **Authentication & Session Security:** PBKDF2-HMAC-SHA256 (600,000 rounds), HS256 JWT (24h TTL), secure storage.
6. **Role-Based Access Control (RBAC):** Hybrid RBAC on all endpoints via `require_permission`.
7. **Input Validation & Sanitisation:** Pydantic v2 schemas on all incoming payloads; path traversal defense.
8. **Rate Limiting:** `LoginRateLimiter` (5 attempts/min) on sensitive auth endpoints.
9. **Error Handling:** `DEBUG=false` in production; zero stack trace leakage to clients.
10. **CORS Configuration:** Strictly restricted to localhost and private enterprise LAN CIDRs.
11. **Security Headers:** HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Permissions-Policy.
12. **Audit Logging:** Comprehensive event trail in `audit_logs` table.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Pass 1 audit report documented and presented to user.
- [ ] Pass 2 fixes applied only upon explicit confirmation.
- [ ] All 853 automated tests pass with 100% success rate.
""",

    "performance-improvement-phase.md": """# ⚡ Phase 2 Performance Improvement Specification

## 📌 Overview
High-confidence performance optimizations to accelerate multi-user concurrency and response latency.

---

## 🛠️ Step-by-Step Architecture
- **Step 0:** Baseline capture (RPS, P50/P95 latency, payload size).
- **Step 1:** Database B-Tree indexes on high-frequency filters (`current_stage`, `acid_number`, `is_active`).
- **Step 2:** In-memory RAM caching (`InMemoryCache`, 300s TTL, auto-invalidation on write).
  - *Strict Rule:* Never cache live financial calculations or exchange rates.
- **Step 3:** GZip response compression (`GZipMiddleware`, minimum 1000 bytes) reducing wire transfer by >= 85%.
- **Step 4:** Frontend Dio network tuning (`Accept-Encoding: gzip`).
- **Step 5:** Session identity map resolution (`db.get(User, user_id)`) + auth active-state cache.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Measured concurrent throughput improves by >= 100% over baseline.
- [ ] Network payload sizes for master data decrease by >= 80%.
- [ ] Zero regression across test suite (853 tests passing).
""",

    "logistics-workflow-architecture-audit.md": """# 🚢 Logistics Workflow Architecture & Continuity Audit

## 📌 Overview
Audits full 10-stage import lifecycle continuity, ACID radar tracking, customs release hard-blocks, and landed cost integrity.

---

## 🔄 Lifecycle Stages (1..10)
1. Import Planning & PO Creation (`STEP_01` - `STEP_04`)
2. Advance Payment & Financing (`STEP_05`)
3. Nafeza ACID Issuance & Tracking (`STEP_06`)
4. Freight Booking & Free Days Agreement (`STEP_07`)
5. Sailing, B/L Review & CargoX Sealing (`STEP_08` - `STEP_10`)
6. Original Documents Receipt (`STEP_11`)
7. Bank Form 4 & Customs Declaration 46 (`STEP_12` - `STEP_13`)
8. Inspection, Port Charges & Release Order (`STEP_14` - `STEP_16`)
9. Inland Transport & Warehouse GRN (`STEP_17` - `STEP_19`)
10. Final Landed Cost & Dossier Closure (`STEP_20` - `STEP_21`)

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Two-way synchronization between stage records and `ImportFile` is verified.
- [ ] Expired ACID strictly halts final customs release.
- [ ] Landed cost accurately reflects all 12 cost components without discrepancy.
""",

    "metric-label-and-overlap-extension.md": """# 🏷️ Metric Card Labeling, Bounding Box & Overlay Extension Specification

## 📌 Overview
Specifies label alias mapping, value preservation, and desktop side-docking for chat/support overlays.

---

## 📏 Core Rules
1. **Short Label Mapping:**
   - When container width < 660px or in Compact modes, labels must shorten gracefully (e.g. `Total Purchase Orders` -> `POs`).
2. **Value Preservation:**
   - Numerical values must never be clipped or truncated with ellipsis.
3. **Side Docking on Desktop (>=1200px):**
   - Chat and AI assistant panel docks into the main layout `Row` (`AiAssistantDockedPanel` 410px/560px), shifting the content area rather than floating over tables.
4. **Greeting Bubble Auto-Collapse:**
   - Bubble automatically collapses after 7 seconds or upon any table scroll.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] No metric label displays truncation dots (`...`).
- [ ] Chat panel docks cleanly on screens >= 1200px without obscuring tables.
- [ ] Greeting bubble collapses after 7 seconds or on scroll.
"""
}

for filename, content in specs.items():
    file_path = out_dir / filename
    file_path.write_text(content.strip() + "\n", encoding="utf-8")
    print(f"Generated: {filename} ({len(content)} bytes)")

print(f"Successfully generated all {len(specs)} specification files!")
