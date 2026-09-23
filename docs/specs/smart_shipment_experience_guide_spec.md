# Product & Technical Spec: Smart Shipment Experience Guide — Institutional Knowledge Engine

## 1. Purpose & Reframing

This feature must not be built as a simple note-taking widget attached to one shipment. It is architected as an **institutional knowledge base**: a system that captures operational experience from every past shipment (supplier delays, port requirements, documentation pitfalls, carrier performance, etc.) as a permanent, taggable asset, and automatically resurfaces the relevant pieces of that knowledge in every future shipment that shares similar conditions — without the user having to remember to search for it.

### Core Problem Being Solved
Shipping and customs knowledge currently lives in individual employees' memory or scattered chat threads. When staff turn over or simply forget, new shipments repeat mistakes that were already solved before. This system systematically links **current shipment conditions** to **relevant past lessons** and learns from historical data.

---

## 2. Core Data Model: Multi-Dimensional Tagging

A note is not attached to a shipment. It is attached to a **combination of conditions (dimensions)**:

1. `supplier_id` / `supplier_name`: Experience specific to a supplier.
2. `country_of_origin`: Experience specific to a country.
3. `shipping_line`: Experience specific to an ocean or air carrier.
4. `port_of_loading`: POL-specific insights.
5. `port_of_discharge`: POD-specific insights.
6. `hs_code`: HS-code specific regulatory hurdles, inspections, or tax anomalies.
7. `product_category`: Broader product group insights.
8. `incoterm`: Terms-specific lessons (e.g., FOB vs. CIF insurance traps).
9. `customs_regime`: Import regime nuances.
10. `stage`: Lifecycle stage where note is most actionable.
11. `department`: Originating operational unit.
12. `severity`: Severity classification (`info`, `warning`, `critical`, `positive`).
13. `expires_at`: Expiration or validity cutoff date.

---

## 3. The Surfacing Engine (Contextual Injection)

Whenever a shipment screen or lifecycle dialog loads, the engine evaluates active shipment attributes and matches reference entries based on multi-dimensional specificity scoring.

### Severity Tiers & Behavior
- 🔴 **Critical:** Hard blocker banner. Requires explicit acknowledgment or resolution checkbox before proceeding with critical operations (like generating ACID or releasing payments).
- 🟡 **Warning:** Amber banner or badge. Highlighted operational reminder with actionable mitigations.
- 🔵 **Info:** Blue insight chip or collapsible drawer. Informational operational reference.
- 🟢 **Positive:** Emerald badge. Highlights verified best practices, reliable partners, or green-lane expedited routing.

---

## 4. Lifecycle Injection Points (Stages 1–8)

1. **Stage 1 (PO Creation):** Supplier reliability, payment terms pitfalls, lead time adjustments.
2. **Stage 2 (ACID / Nafeza):** HS Code regulatory holds, prior approval certificates, Nafeza tariff changes.
3. **Stage 3 (Freight Booking):** Carrier transit delays, free-time demurrage rules, POL congestion.
4. **Stage 4 (Draft Documents Review):** Mandatory invoice wording, packing list layout discrepancies, COO legalization.
5. **Stage 5 (Customs Clearance):** Inspection committee criteria, sample testing delays, customs valuation disputes.
6. **Stage 6 (Supplier Payment Release):** Discrepancy deductions, banking compliance requirements.
7. **Stage 7 (Shipment Closure):** Reflection prompt capturing final landed cost variances and lessons learned.
8. **Stage 8 (Import File 360 View):** Comprehensive reference card and similar shipment benchmarks.

---

## 5. Semi-Structured Knowledge Capture

- `lesson_learned`: Free text describing the issue and root cause.
- `recommended_action`: Concrete actionable advice.
- `consequence_if_ignored`: Explicit operational or financial risk.

---

## 5A. Autonomous Learning & Self-Building Reference Engine

### 1. Objective
The engine should not only store what users tell it — it should independently observe outcomes across all Import Files and derive operational knowledge from the data itself, turning every closed shipment into a training signal for future guidance without human note entry.

### 2. Autonomous Learning Dimensions (6 Categories)
1. **Delivery Reliability per Supplier (`DELIVERY_RELIABILITY`):**
   - Compares PO cargo ready date / delivery date against actual shipment and clearance dates.
   - Computes average delay in days, on-time percentage, and sample size.
2. **Transit Time Accuracy per Carrier & Route (`TRANSIT_TIME_ACCURACY`):**
   - Compares quoted booking transit days vs. actual POL-to-POD voyage time.
   - Identifies chronic carrier delays per port pair.
3. **Recurring Reconciliation Failures (`RECONCILIATION_FAILURES`):**
   - Aggregates PO vs. Packing List vs. BL discrepancies.
   - Detects repeated supplier documentation patterns (weight variations, missing details).
4. **Cost Variance Patterns (`COST_VARIANCE`):**
   - Compares estimated landed and freight cost against actual audited expenditures.
   - Identifies systemic budget under-estimations per route or product group.
5. **Seasonal & Timing Effects (`SEASONAL_EFFECTS`):**
   - Correlates transit and clearance durations with calendar months and holiday cycles (Q3 peak, Ramadan, Chinese New Year).
6. **Documentation Risk & Regulatory Holds (`DOCUMENTATION_RISK`):**
   - Correlates customs holds, physical inspections, and fine records with specific HS codes and categories.

### 3. Confidence Scoring & Surfacing Thresholds
- **Sample Size ($N$):** Number of observed shipments supporting the pattern.
- **Minimum Threshold:** At least $N \ge 2$ shipments exhibiting the pattern.
- **Confidence Metric:** Dynamic score between $0.00$ and $1.00$. Notes with confidence $< 0.60$ are automatically retired to `ARCHIVED`.
- **Confidence Formula:**
  $$\text{Confidence} = \min\left(0.99, \frac{N}{N + 1.5} \times \text{ConsistencyRatio}\right)$$

### 4. Provenance & Evidence Trail
Every system-inferred note provides a transparent evidence trail:
- Contributing Import Files (IDs, file numbers, dates, measured variances).
- Statistical comparison metrics (e.g., Contractual 30 days vs. Observed 42 days).
- Explanation of trigger criteria ("Why am I seeing this note?").
- Timestamps: `first_detected_at`, `last_recalculated_at`.

### 5. Visual & UX Distinction Everywhere
- 👤 **Human-authored:** Distinct badge with user avatar, name, and department.
- 🤖 **System-inferred:** AI chip with confidence percentage, sample size, and clickable `مسار الأدلة (Evidence Trail)`.

### 6. Human Promotion & Rejection Workflow
- **Promote (`CONFIRMED`):** Converts an AI inference into an institutional standard locked against automated demotion.
- **Reject (`REJECTED`):** Suppresses the pattern with user feedback, excluding it from future active surfacing.

### 7. Continuous Learning Loop
- Automatically re-evaluates and updates affected pattern notes upon formal shipment closure (`modules/file_closure/service.py`).
- Creates an immutable entry in `AutonomousPatternAuditLog`.

---

## 6. Audit & Quality Assurance

- All pattern changes, confidence recalculations, and human promotions/rejections are logged in `AutonomousPatternAuditLog`.
- Inactive or low-confidence patterns are safely archived without permanent data loss (Soft Retirement).
