# ⏭️ Shipment Lifecycle Operations Board — Skip Stage Review Log

> **Document Status:** Active / Phase 0: Discovery & Critical Architectural Decisions  
> **Initial Date:** 2026-09-07  
> **Governing Security Principle:** Backend-First Enforcement & Business Integrity. The "Skip Stage" feature is a deliberate, documented, human business decision — **NOT** a workaround for synchronization glitches or technical defects.

---

## 📌 1. Feature Definition & Strategic Intent

Not every shipment in ImportFlow ERP follows an identical sequential path across all 21 steps. In real-world enterprise logistics, client contracts vary significantly:
- **Example:** A client like **Eco Trading Co.** may handle customs clearance and brokerage expenses independently under their service agreement. In such cases, internal steps such as *STEP_02 (Customs Studies)* or *STEP_14 (Clearance Follow-up)* are completely out of scope for our operational team.
- **The Solution:** A secure, authorized user can execute **"Skip Stage" (تخطي المرحلة)** for that specific shipment, providing a **mandatory business justification**, allowing downstream steps to continue smoothly.

### ⚠️ Essential Operational Boundary (تنبيه حاسم)
- **Auto-Sync Mechanism (المزامنة التلقائية):** Handles cases where an action was *actually executed* in a module (e.g. Booking confirmed in `freight_booking`), and automatically moves the lifecycle card.
- **Skip Stage (تخطي المرحلة):** Handles cases where an action *will never be executed* for this shipment due to valid business reasons.
- **Strict Rule:** Skip Stage is **strictly prohibited** from being used as a quick fix for broken synchronization or technical defects. Technical bugs must be solved in the synchronization engine itself.

---

## 🔍 2. Phase 0: Codebase Exploration & Technical Audit

### 2.1 Current Lifecycle Board Architecture
1. **Database Models (`modules/lifecycle_board/model.py` & `modules/import_files/model.py`)**:
   - `ShipmentStageActivity`:
     - `status`: String(50) — Already supports `"Skipped"` in addition to `"In-Progress"`, `"Completed"`, `"On-Hold"`.
     - `notes`: Stores skip justifications.
     - `completed_at`: Records timestamp of skip.
   - `ImportFile`:
     - `skipped_stages`: Column `JSON` storing array of skipped step codes (e.g. `["STEP_02", "STEP_06"]`).
     - `current_stage` & `progress_percent`: Dynamically reflect current active phase.

2. **Synchronization Engine (`advance_lifecycle_step_service` & `skip_step_service`)**:
   - The engine calculates progress percentage based on the target active step:
     $$\text{progress\_percent} = \text{round}\left(\frac{\text{step\_idx}}{21} \times 100\%, 1\right)$$
   - A prototype `skip_step_service` exists in `modules/lifecycle_board/service.py`, but has the following critical architectural and security gaps:
     - ❌ **No RBAC Security:** Endpoints in `router.py` lack token or permission verification (`Depends(get_db)` only).
     - ❌ **No Classification Guard:** Any step (even mandatory legal steps like Final Closure or Customs Release) could theoretically be requested to be skipped.
     - ❌ **Weak Reason Validation:** `skip_reason` validation accepts only `min_length=2` (allows meaningless text like "ok").
     - ❌ **Missing Audit Trail:** Does not write permanent audit entries into the central `AuditLog` table.
     - ❌ **No Reusable Frontend Component:** No unified dialog or button widget exists in Flutter Desktop.

3. **Permissions System Compatibility**:
   - ImportFlow ERP's newly implemented central RBAC system (`modules/auth/permissions.py`) provides the `require_permission(...)` dependency.
   - We will define and seed the dedicated permission: **`lifecycle.skip_stage`** (or `lifecycle_board.skip_stage`), ensuring backend rejection (`403 Forbidden`) for any unauthorized user.

---

## 🏛️ 3. Architecture Decision Records (ADRs)

### ADR-001: Centralized Backend Enforcement via `lifecycle.skip_stage`
- **Decision:** The Skip Stage endpoint (`POST /api/v1/lifecycle-board/stages/skip`) will be strictly protected by:
  ```python
  Depends(require_permission("lifecycle.skip_stage"))
  ```
- **Access Policy:**
  - `ADMIN`: Full unrestricted bypass.
  - `GENERAL_MANAGER`: Granted by default.
  - Other roles (`LOGISTICS_OPERATOR`, `CUSTOMS_OFFICER`): **Denied by default**, unless granted an explicit direct exception by the administrator.

### ADR-002: Mandatory Business Justification Contract
- **Decision:** Skipping any step requires an explicit, structured justification:
  1. Selected predefined reason category (`Client Agreement / العميل يتولى الإجراء حسب الاتفاقية`, `Not Applicable to Shipment Mode / لا تنطبق على نمط الشحن`, `Exempted by Regulation / إعفاء رسمي أو رقابي`, `Other / أخرى`).
  2. Free text explanation with a **minimum length of 10 characters** (e.g. "Per Eco Trading contract annex B, clearance is handled by their internal broker").
  3. Empty or short justifications will be immediately rejected with `422 Unprocessable Entity` / `400 Bad Request`.

### ADR-003: Step Classification & Backend Guard (Non-Skippable Step Protection)
- **Decision:** A centralized, server-side dictionary `STEP_SKIPPABILITY_CONFIG` will govern every step. If an API call attempts to skip a step classified as **[غير قابلة للتخطي نهائياً]**, the backend immediately returns:
  ```json
  {
    "detail": "الخطوة 'STEP_21' خطوة إلزامية نهائية ولا يجوز تخطيها برمجياً أو إدارياً."
  }
  ```
  with HTTP `400 Bad Request`, regardless of the user's role.

### ADR-004: Permanent Audit Trail Logging
- **Decision:** Every skip action will record an immutable record in `audit_logs`:
  - `entity_type="LifecycleStep"`
  - `entity_id=import_file.import_file_id`
  - `action="SKIP_STAGE"`
  - `user_id` and `username` of the skipping authority
  - `new_data={"step_code": ..., "reason": ..., "reason_category": ...}`

---

## 📊 4. Proposed 21-Step Skippability Classification Matrix (جدول قابلية التخطي للخطوات الـ 21)

> **تنبيه:** هذا التصنيف مقترح بناءً على دراسة الأنظمة الجمركية واللوجستية المصرية، وهو معروض على المستخدم للمراجعة والاعتماد النهائي:

| Phase | Step Code | Step Name (En / Ar) | Proposed Classification | Rationale & Business Conditions |
|---|---|---|---|---|
| **Phase 1: Pre-Planning** | `STEP_01` | Freight Studies<br>(دراسات نولون الشحن) | **قابلة للتخطي** | إذا كانت الشحنة CIF / CFR على حساب المورد أو شحن بري بسيارات العميل. |
| **Phase 1: Pre-Planning** | `STEP_02` | Customs Studies<br>(الدراسات والاستشارات الجمركية) | **قابلة للتخطي** | إذا كان العميل يتولى التخليص بنفسه (مثل Eco) أو أصناف مكررة لها فحص سابق. |
| **Phase 1: Pre-Planning** | `STEP_03` | Regulatory Requirements<br>(الاشتراطات والموافقات الرقابية) | **قابلة للتخطي بموافقة إضافية** | تجنباً لرفض الشحنة، لا تُتخطى إلا بإقرار من الإدارة بتحمل العميل المسؤولية الرقابية. |
| **Phase 2: Initiation** | `STEP_04` | Finance Approvals & Budget<br>(اعتمادات الميزانية وسداد المورد) | **قابلة للتخطي بموافقة إضافية** | للشحنات ذات الدفع الآجل (Credit) بعد الاستلام أو التحويلات الخارجية المباشرة. |
| **Phase 2: Initiation** | `STEP_05` | ACID Operations<br>(الرقم التعريفي المبدئي نافذة) | **غير قابلة للتخطي نهائياً**<br>*(إلا للشحن البري/المناطق الحرة)* | إلزامي قانوناً بنص المادة 39 من قانون الجمارك 207 لسنة 2020، الشحن بدونه مخالفة جسيمة. |
| **Phase 3: Booking** | `STEP_06` | Freight Booking<br>(حجز النولون وتأكيد الخط) | **قابلة للتخطي** | للشحنات بنظام CIF/DDP حيث المورد هو الحاجز للنولون والناقل. |
| **Phase 3: Booking** | `STEP_07` | Freight Allocations<br>(تخصيص وتوزيع الحاويات) | **قابلة للتخطي** | الشحنات المجزأة LCL أو الشحن الجوي والطرود لا تتطلب تخصيص حاويات. |
| **Phase 3: Booking** | `STEP_08` | Draft Docs Review<br>(مراجعة وتدقيق مسودات الشحن) | **قابلة للتخطي** | إذا كان العميل يدقق المستندات بمعرفته وفريقه المستندي الخاص. |
| **Phase 3: Booking** | `STEP_09` | Docs Customs Approval<br>(الاعتماد النهائي للمستندات) | **قابلة للتخطي بموافقة إضافية** | يتطلب موافقة إذا كان التخليص المستندي خارجياً بالكامل. |
| **Phase 4: Digital & Banking** | `STEP_10` | CargoX Follow-up / Upload<br>(رفع ومتابعة مستندات كارجو إكس) | **قابلة للتخطي بموافقة إضافية** | إلزامي بحرياً؛ يُتخطى للشحن البري والطرود الجوية المعفاة رسمياً أو إرسال المورد المباشر. |
| **Phase 4: Digital & Banking** | `STEP_11` | Originals Collection<br>(تحصيل واستلام أصول المستندات) | **قابلة للتخطي** | في حال الاعتماد الكامل على بوالص إلكترونية (Telex Release / Sea Waybill). |
| **Phase 4: Digital & Banking** | `STEP_12` | Bank Form 4<br>(استخراج واعتماد نموذج 4 البنكي) | **قابلة للتخطي بموافقة إضافية** | إلزامي بنكياً إلا للشحنات المعفاة قانوناً (الشحنات المؤقتة، عينات دون حد القيمة). |
| **Phase 5: Port & Clearance** | `STEP_13` | Customs Declaration 46<br>(قيد ومطابقة إقرار 46 ك.م) | **قابلة للتخطي** | إذا كان التخليص الجمركي يتم بالكامل بمعرفة مستخلص العميل الخارجي. |
| **Phase 5: Port & Clearance** | `STEP_14` | Clearance Follow-up<br>(متابعة الكشف والتثمين) | **قابلة للتخطي** | إذا كان التخليص والنزول الميداني بالميناء يتولاه العميل مباشرة. |
| **Phase 5: Port & Clearance** | `STEP_15` | Drawing Samples / Shortage<br>(سحب العينات ومحاضر الفحص) | **قابلة للتخطي** | شحنات المسار الأخضر (Green Channel) أو الأصناف التي لا تخضع لسحب عينات معملية. |
| **Phase 5: Port & Clearance** | `STEP_16` | Cargo Discrepancy / Damage<br>(محاضر المعاينة والأضرار) | **قابلة للتخطي تلقائياً** | الوضع الطبيعي هو سلامة البضاعة وعدم وجود أضرار أو عجز، لذا تتخطى افتراضياً. |
| **Phase 5: Port & Clearance** | `STEP_17` | Final Customs Calculation<br>(الحساب والسداد الجمركي النهائي) | **قابلة للتخطي** | إذا كان العميل يسدد الرسوم الجمركية والضرائب من حسابه البنكي مباشرة دون تدخلنا. |
| **Phase 5: Port & Clearance** | `STEP_18` | Demurrage & Detention<br>(إدارة غرامات وفترات السماح) | **قابلة للتخطي** | في حال الإفراج المبكر دون غرامات، أو شحنات الشحن الجوي والبري. |
| **Phase 6: Inbound & Closure** | `STEP_19` | Warehouse Receiving GRN<br>(إذن الإضافة والاستلام المخزني) | **قابلة للتخطي** | إذا كان التسليم مباشرة للعميل أو موقع المشروع دون دخول مستودعاتنا. |
| **Phase 6: Inbound & Closure** | `STEP_20` | Landed Cost Settlement<br>(تسوية التكلفة الشاملة) | **قابلة للتخطي بموافقة إضافية** | إذا كان العميل يحسب تكلفته النهائية في نظامه الخاص دون حاجة لدراسة وصولنا. |
| **Phase 6: Inbound & Closure** | `STEP_21` | Import File Final Closure<br>(الإغلاق النهائي للملف الاستيرادي) | **غير قابلة للتخطي نهائياً** | الخاتمة الحتمية لغلق أي ملف تشغيلي وأرشفته. لا يمكن إنهاء ملف دون إغلاقه. |

---

## ❓ 5. قرارات عمل حرجة معروضة على المستخدم للحسم (Phase 0 Critical Inquiries)

1. **اعتماد تصنيف الخطوات الـ 21:**
   - هل تعتمد جدول التصنيف أعلاه، أم هناك خطوات معينة ترغب في تغيير تصنيفها (مثلاً تحويل خطوة من "قابلة للتخطي" إلى "غير قابلة للتخطي نهائياً" أو العكس)؟
2. **قابلية التراجع عن التخطي (Reversibility / Un-skip):**
   - هل التخطي نهائي بمجرد حفظه؟
   - أم يدعم النظام **"إلغاء التخطي" (Un-skip)** وإعادة الخطوة إلى `In-Progress` إذا تبين أن القرار اتُّخذ بالخطأ (مع اشتراط ألا تكون المرحلة قد أُغلقت بالكامل وتسجيل سبب التراجع في الـ Audit Log)؟
   *(التوصية المعمارية: دعم إلغاء التخطي Un-skip للمدير العام فقط مع توثيق السبب).*
3. **طريقة احتساب نسبة الإنجاز للشحنة (Progress Calculation):**
   - هل الخطوة المتخطاة تُحسب كـ منجزة بنسبة 100% لتلك الخطوة لدفع مؤشر إنجاز الشحنة للأمام نحو الخطوة النشطة التالية، أم تُعامل بنسبة 0% أو بمعامل جزئي؟
   *(التوصية المعمارية: تُحسب الخطوة المتخطاة كمنجزة لدفع المؤشر وفق تسلسل الخطوة النشطة الحالية، مع إبراز شارة "متخطاة" بلون مميز في بطاقة الشحنة لمنع أي التباس).*

---

## 🚀 6. سجل تفعيل الخطوات في الواجهات (Sessions Progress)

- **آخر خطوة تم تفعيل وتأمين الزرار فيها بالكامل:** لم تبدأ بعد (بانتظار حسم قرارات المرحلة 0).
- **الخطوة التالية المخططة للجلسة القادمة:** `STEP_02` (Customs Studies & Consultation) أو الخطوة المحددة من المستخدم.
