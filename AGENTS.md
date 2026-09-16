# 🤖 AI Agent Guidelines & Operating Instructions

# ImportFlow ERP

> **ملاحظة هامة للمساعد الذكي (AI Assistant):**
> يجب قراءة وتطبيق جميع القواعد والتعليمات الواردة في هذا الملف عند تحليل أو تطوير أو تعديل مشروع **ImportFlow ERP**.

---

## ⚡ Quick Reference — Auto-Loaded Rules (تُقرأ تلقائيًا في كل محادثة)

> الملفات التالية في `.agents/rules/` تُحمَّل تلقائيًا وتحتوي على الخلاصة العملية:
>
> | الملف | المحتوى |
> |-------|---------|
> | [`CORE_RULES.md`](.agents/rules/CORE_RULES.md) | Stack + Architecture + محظورات + Testing |
> | [`DOMAIN_RULES.md`](.agents/rules/DOMAIN_RULES.md) | Customs + Stages + Landed Cost + Soft Delete |
> | [`UI_SCREEN_STANDARDS.md`](.agents/rules/UI_SCREEN_STANDARDS.md) | هيكل كل شاشة + Widgets الجاهزة + Anti-Patterns |
>
> **هذا الملف (AGENTS.md) هو المرجع الكامل** — يُرجع إليه عند الحاجة لتفاصيل إضافية.

---

# 1. 🎯 Role & System Context

أنت المساعد الذكي المسؤول عن المساعدة في تطوير مشروع:

**ImportFlow ERP**

وهو نظام ERP متخصص في:

* Import Management
* Customs Clearance
* Freight & Logistics
* Shipping Operations
* Customs Calculations
* Landed Cost
* Document Management
* Supplier Management
* External Service Providers
* CargoX / Nafeza Integration

يجب التعامل مع المشروع كنظام **Enterprise Application** قابل للتوسع، وليس كتطبيق CRUD بسيط.

---

# 2. 🌐 Languages & Communication

## Arabic

تستخدم اللغة العربية في:

* التواصل مع المستخدم.
* شرح المشاكل والحلول.
* توثيق النظام.
* Task History.
* Architecture Decisions.
* Business Rules.

ويُفضل استخدام **اللهجة المصرية** عند التواصل غير الرسمي مع المستخدم.

## English

تستخدم اللغة الإنجليزية في:

* Python Code
* Dart / Flutter Code
* Module Names
* Class Names
* Function Names
* Variable Names
* Database Tables
* Database Columns
* API Endpoints
* Pydantic Schemas
* SQLAlchemy Models
* Flutter Widgets
* Technical Comments

### قاعدة مهمة

لا تستخدم أسماء عربية داخل:

```text
Python identifiers
Database identifiers
API identifiers
Flutter identifiers
File names
Class names
Function names
```

---

# 3. 🛠️ Required Technology Stack

## 3.1 Frontend

### Flutter Desktop

```text
Flutter 3.x
Dart 3.x
Windows Desktop
```

### Architecture

استخدام Layered Architecture:

```text
UI
 ↓
State Management
 ↓
Logic / Services
 ↓
API Client
 ↓
FastAPI
```

### State Management

يفضل:

```text
flutter_riverpod
```

ويمكن استخدام:

```text
provider
```

عند وجود سبب واضح.

### Networking

```text
dio
```

أو:

```text
http
```

### Routing

```text
go_router
```

### Desktop Window Management

```text
window_manager
```

---

# 4. 🎨 UI Design System

يجب أن تكون واجهة ImportFlow:

* Professional
* Clean
* Consistent
* Desktop-Oriented
* Enterprise-Friendly
* High Contrast
* Easy to Navigate

## Color Palette

```text
Flat Charcoal  #2C3E50
Flat Cobalt   #3498DB
Flat Emerald  #27AE60
Flat Orange   #E67E22
Flat Crimson  #C0392B
Cloud White   #ECF0F1
```

يجب عدم إدخال ألوان عشوائية داخل الواجهات.

يفضل تعريف الألوان في مكان مركزي:

```text
app_theme.dart
```

بدل تكرار قيم HEX داخل Widgets.

---

# 5. ⚙️ Backend

## Required Stack

```text
Python 3.12+
FastAPI
Uvicorn
Pydantic
SQLAlchemy 2.0
Alembic
SQLite
```

قاعدة البيانات الحالية:

```text
sorour_logistics.db (Sorour Logistics)
```

---

# 6. 🏗️ Backend Architecture

كل Business Module يجب أن يلتزم بالهيكل التالي:

```text
modules/
└── <module_name>/
    ├── model.py
    ├── schemas.py
    ├── repository.py
    ├── service.py
    ├── validators.py
    ├── router.py
    └── utils.py
```

## Responsibility Rules

### model.py

مسؤول عن:

```text
SQLAlchemy Models
Database Relationships
Indexes
Constraints
Foreign Keys
```

لا يحتوي على Business Logic المعقد.

---

### schemas.py

مسؤول عن:

```text
Pydantic Request Schemas
Pydantic Response Schemas
Validation Schemas
```

---

### repository.py

مسؤول عن:

```text
Database Queries
CRUD Operations
Filtering
Pagination
Database Retrieval
```

ولا يحتوي على Business Rules.

---

### service.py

مسؤول عن:

```text
Business Logic
Transactions
Workflow Logic
Calculations
Cross-Module Operations
```

---

### validators.py

مسؤول عن:

```text
Business Validation
Duplicate Detection
Stage Validation
Domain Rules
```

---

### router.py

مسؤول عن:

```text
FastAPI Routes
HTTP Requests
Authentication Dependencies
Calling Services
Returning Responses
```

يجب ألا يحتوي Router على Business Logic معقد.

---

# 7. 🧠 Business Domains & Logic

## 7.1 Cargo Measurement Engine

يشمل:

```text
CBM
Volumetric Weight
Chargeable Weight
Package Measurements
Container Capacity
```

يجب دعم وحدات القياس:

```text
mm
cm
m
kg
lb
```

مع توحيد الوحدات داخليًا قبل إجراء الحسابات.

---

# 7.2 Customs Calculation Engine (محرك الحساب الجمركي المصري)

> **قاعدة أساسية:** كل بند تعريفة جمركية (**HS Code**) له نسب ضرائب ورسوم مختلفة.
> لا يجوز افتراض نسبة ثابتة لأي ضريبة أو رسم — كل النسب يجب أن تُستخرج من جدول التعريفة الجمركية (MD-008) المرتبط بالـ HS Code.

## بنود الحساب الجمركي (Customs Charge Items)

يتكون الحساب الجمركي المصري من البنود التالية (كلها مرتبطة بالـ HS Code):

```text
1. ضريبة الوارد (Import Duty / Customs Duty)        → نسبة من القيمة الجمركية (CIF)
2. ضريبة القيمة المضافة (VAT)                       → نسبة من الوعاء الضريبي
3. ضريبة الجدول (Schedule Tax)                       → نسبة إضافية حسب بند التعريفة (إن وجدت)
4. رسم الوارد (Import Fee)                           → رسم ثابت أو نسبة (إن وجد)
5. رسوم الخدمات الجمركية (Customs Service Fees)      → رسوم متعددة
6. رسوم أساسية (Basic Fees)                          → رسوم ثابتة
7. رسم التنمية (Development Fee)                     → نسبة إن وجدت حسب البند
```

## تسلسل الحساب (Calculation Flow)

```text
Step 1: حساب القيمة الجمركية (Customs Value / CIF Base)
        CIF = FOB Value + Freight + Insurance

Step 2: حساب ضريبة الوارد (Import Duty)
        Import Duty = CIF × Import Duty Rate % (من HS Code)

Step 3: حساب الوعاء الضريبي لضريبة القيمة المضافة
        VAT Base = CIF + Import Duty + Freight + Other Applicable Fees

Step 4: حساب ضريبة القيمة المضافة
        VAT = VAT Base × VAT Rate % (من HS Code، وليست دائماً 14%)

Step 5: حساب ضريبة الجدول (إن وجدت)
        Schedule Tax = CIF × Schedule Tax Rate % (من HS Code)

Step 6: حساب رسوم الخدمات الجمركية والرسوم الأساسية
        Customs Service Fees = حسب جدول الرسوم المعتمد

Step 7: إجمالي الضرائب والرسوم
        Total = Import Duty + VAT + Schedule Tax + Import Fee
              + Customs Service Fees + Basic Fees + Development Fee
```

## قواعد حرجة

```text
❌ لا يجوز Hard-Code أي نسبة ضريبية (VAT ≠ 14% دائماً)
❌ لا يجوز افتراض أن كل البنود تنطبق على كل شحنة
✅ كل HS Code يحدد أي بنود تنطبق وبأي نسب
✅ يجب حفظ تاريخ سريان كل قاعدة (effective_from / effective_to)
✅ يجب استخدام سعر صرف الجمارك الرسمي في تاريخ الإقرار
✅ يجب حفظ تفاصيل كل بند منفصلاً (وليس مجرد رقم إجمالي)
```

## مثال عملي

```text
قيمة الفاتورة (FOB):              623,000 جنيه
ضريبة الوارد (10% من CIF):         62,300 جنيه
ضريبة القيمة المضافة:              95,942 جنيه
ضريبة الجدول:                       6,230 جنيه
رسم الوارد:                             0 جنيه
رسوم الخدمات الجمركية:             78,286.90 جنيه
رسوم أساسية:                        1,329.50 جنيه
─────────────────────────────────────────────
إجمالي الضرائب والرسوم:           165,801.50 جنيه
```

---

# 7.3 Landed Cost Engine

يجب أن يستطيع النظام حساب:

```text
Purchase Cost (قيمة الفاتورة FOB/CIF)
+ Freight (النولون)
+ Insurance (التأمين)
+ Import Duty (ضريبة الوارد / الجمارك)
+ VAT (ضريبة القيمة المضافة)
+ Schedule Tax (ضريبة الجدول)
+ Development Fee (رسم التنمية)
+ Customs Service Fees (رسوم الخدمات الجمركية)
+ Basic Fees (رسوم أساسية)
+ Clearance Fees (أتعاب التخليص الجمركي)
+ Local Transport (النقل الداخلي)
+ Other Import Costs (مصاريف أخرى)
= Landed Cost (تكلفة الوصول الشاملة)
```

ويجب الاحتفاظ بتفاصيل مكونات التكلفة، وليس فقط تخزين رقم نهائي.

---

# 7.4 External Integrations

يجب تصميم التكاملات بشكل مستقل وقابل للاستبدال.

يشمل ذلك:

```text
CargoX
Nafeza
Shipping Providers
Freight Forwarders
External Service Providers
```

يجب عدم ربط Business Logic مباشرة بـ API خارجي.

يفضل استخدام:

```text
Integration Layer
```

مثل:

```text
integrations/
├── cargox/
├── nafeza/
└── shipping/
```

---

# 8. 📜 Core System Rules

## GP-001 — Progressive Data Entry

يسمح النظام بإنشاء الملفات تدريجيًا.

لا يجب إجبار المستخدم على إدخال جميع البيانات منذ البداية.

يتم استكمال البيانات حسب مراحل العملية.

مثال:

```text
Draft
 ↓
Quotation
 ↓
Purchase Order
 ↓
Shipment
 ↓
Documents
 ↓
Customs
 ↓
Clearance
 ↓
Landed Cost
 ↓
Closed
```

---

# 9. GP-002 — Stage-Based Validation

كل Stage لها Validation Rules خاصة بها.

لا يجب تطبيق جميع قواعد النظام عند إنشاء السجل لأول مرة.

مثال:

```text
Draft Validation
Shipment Validation
Customs Validation
Clearance Validation
Closing Validation
```

ويجب منع الانتقال إلى Stage جديدة إذا لم تتحقق شروطها.

---

# 10. GP-003 — Master Data Integrity

يجب منع تكرار Master Data.

يجب استخدام:

```text
Unique Constraints
Foreign Keys
Database Indexes
Application Validation
```

ولا يجب تخزين Master Data كنص حر إذا كان لها جدول مرجعي.

مثال:

❌

```text
country = "Italy"
```

يفضل:

```text
country_id = 39
```

مع وجود:

```text
countries
```

---

# 11. GP-004 — Audit Trail

كل Entity مهمة يجب أن تدعم:

```text
created_at
created_by
updated_at
updated_by
```

ويجب استخدام آلية موحدة مثل:

```text
set_created_info()
set_updated_info()
```

ويجب ألا يتم تحديث بيانات Audit يدويًا من كل Router.

---

# 12. 🗑️ Soft Delete

يجب عدم حذف البيانات المهمة حذفًا نهائيًا.

استخدام:

```text
is_active
deleted_at
deleted_by
```

حسب طبيعة الـ Entity.

يجب دعم:

```text
Soft Delete
Restore
```

ويجب استبعاد السجلات المحذوفة منطقيًا من الاستعلامات العادية.

---

# 13. 🔐 Data Integrity

يجب الاعتماد على مستويين من الحماية:

```text
Application Validation
+
Database Constraints
```

مثال:

```text
Application:
Duplicate supplier detection

Database:
UNIQUE(company_name, country_id)
```

لا تعتمد على Python validation وحده.

---

# 14. 🔢 IDs & References

كل Entity رئيسية يجب أن يكون لها:

```text
Primary Key
Business Reference / Code
```

مثال:

```text
supplier_id
supplier_code
```

ويفضل عدم استخدام Database ID كرقم مرجعي للمستخدم النهائي.

مثال:

```text
supplier_id = 17
```

ليس هو نفسه:

```text
SUP-000017
```

---

# 15. 🧩 Separation of Concerns

يجب الالتزام بالقاعدة:

```text
Router
   ↓
Service
   ↓
Repository
   ↓
Database
```

وليس:

```text
Router
   ↓
Database
```

مباشرة.

وكذلك:

```text
Flutter
   ↓
API
```

ولا يجب أن يعرف Flutter تفاصيل قاعدة البيانات.

---

# 16. 🧪 Testing & Unit Test Rules (إلزامي)

كل Business Logic وموديول يتم إنشاؤه أو تعديله **يجب** أن يحتوي على Unit Tests إلكزامية لضمان سلامة العمليات وموثوقيتها (كود بدون اختبارات غير مقبول).

⚡ **قاعدة إغلاق التاسك الإلزامية (Mandatory Test Execution Rule):**
عند الانتهاء من أي موديول أو مهمة جديدة، يُحظر إغلاق المهمة أو تسليمها للمستخدم إلا بعد تشغيل كافة الـ Unit Tests الـ (Backend & Frontend) آلياً والتأكد من نجاح جميع الاختبارات بنسبة 100% ورؤية نتيجة الاختبارات الخضراء (Passing).

⚡ **قاعدة التحقق من صحة النماذج (Mandatory Form Validation Rule):**
جميع نماذج الإدخال (Forms & Dialogs) في واجهة الفلاتر يجب أن تكون محمية بـ `Form` و `validator` تفاعلي حقيقي يظهر رسائل الخطأ باللون الأحمر تحت الحقول الإلزامية عند تركها فارغة، مع إظهار أخطاء الـ Backend API (مثل تكرار السجلات) في إشعارات واضحة للمستخدم.

⚡ **قاعدة التحديث التلقائي ومؤشرات التحميل (Mandatory Loading & Auto-Refresh Rule):**
يُحظر استخدام البيانات المخزنة القديمة (Stale Cache) في سجلات التغييرات والـ Audit Logs. يجب عمل `ref.invalidate()` تلقائياً بعد كل عملية إضافة أو تعديل أو تغيير حالة لضمان جلب أحدث البيانات فورياً من السيرفر. كما يجب إظهار مؤشر تحميل (Loading Indicator) تفاعلي داخل الأزرار وواجهات التعامل أثناء تنفيذ أي عملية Async لمنع الضغط المتكرر وإعلام المستخدم بتنفيذ الطلب.

⚡ **قاعدة التحديث التلقائي الشامل لكل الشاشات (Mandatory Screen Mount Live Load Rule):**
يُحظر تماماً الاعتماد على البيانات المخزنة المؤقتة القديمة (Stale Cache) عند فتح أو التنقل بين الشاشات. يجب في كل صفحة أو شاشة يتم فتحها أو التنقل إليها في واجهة الفلاتر تضمين آلية إعادة تحميل حية تلقائية حتمية من الباك إند (`fetchCompanies`, `fetchSuppliers`, `fetchPartners`, `ref.invalidate(...)`) داخل `initState` أو عند التركيز على الشاشة، لضمان أن كل صفحة يفتحها المستخدم تعرض أحدث وأدق البيانات من قاعدة البيانات فوراً.

⚡ **قاعدة القوائم المنسدلة المزودة بشريط بحث (Mandatory Searchable Dropdown Rule):**
يُحظر في أي شاشة من شاشات النظام بالكامل استخدام `DropdownButtonFormField` الإعتيادية أو حقول النصوص الحرة (`TextField`) لاختيار البيانات المرجعية أو المعرفات. يجب حتماً ولزاماً استخدام المكون التفاعلي `SearchableDropdownField<T>` المزود بشريط بحث حي (Search Bar) لتسهيل وتسريع التحديد والوصول للاختيارات، ويشمل ذلك تحديد:
1. `HS Code` (بند التعريفة الجمركية)
2. `Country` (الدول والمنشأ)
3. `Ports` (موانئ الشحن والتفريغ)
4. `Importing Companies` (الشركات المستوردة)
5. `Supplier` (الموردون الأجانب)
7. `Incoterms` (الشروط التجارية)
8. `Projects` (المشاريع)
9. `Partners & Banks` (شركات الشحن، الناقل، المخلص الجمركي، البنوك، خطوط الشحن)
10. `Link Purchase Orders` (ربط أوامر الشراء الشحنة)

⚡ **قاعدة إنشاء حزم الإنتاج النظيفة الشاملة (Mandatory Clean Production Build Rule):**
يُحظر حظراً تاماً عند إنشاء أو تجميع أي إصدار إنتاج جديد (Production Release Package) تضمين أي سجلات تجريبية أو بيانات تشغيلية (شركات مستوردة، موردون، مشاريع، ملفات استيراد، أوامر شراء، بوالص، فواتير، تقارير، إشعارات، سجلات تغيير). يجب حتماً تفريغ كافة الجداول التشغيلية لتكون **فارغة تماماً (0 سجلات)**، مع الاحتفاظ والتثبيت الحصري لجداول البيانات المرجعية الأساسية فقط:
1. **الموانئ والمواقع اللوجستية (Ports & Transport Locations)** (يشمل كافة الموانئ البحرية، الجوية، الجافة، والمنافذ البرية والدول والمدن).
2. **جدول التعريفة الجمركية المصرية وبنود الـ HS Codes والرسوم (Customs Tariff Schedule & Fee Codes & Trade Agreements)**.
3. **الشروط التجارية الدولية ومصفوفة التكاليف (Incoterms 2020 & Responsibility Matrix & Cost Items)**.
4. **العملات وأسعار الصرف الرسمية (Currencies & Exchange Rates)**.
5. **المستخدمين الأساسيين للنظام والصلاحيات (Core System Users & RBAC Roles)**.
6. **أنواع الطرود ووحدات القياس القياسية (Package Types & Units of Measure & Clearance Expense Types)**.

⚡ **قاعدة فتح نافذة حوارية إلزامية لتحديد مكان حفظ وتنزيل الملفات (Mandatory Save File Location Dialog Rule — Task I):**
يُحظر حظراً تاماً في أي شاشة أو موديول من موديولات النظام بالكامل تنفيذ أي عملية حفظ صامت أو تحميل تلقائي للملفات (Silent Download / Auto-Save) إلى مجلدات ثابتة افتراضية (مثل مجلد التنزيلات الافتراضي Downloads أو المجلد المؤقت Temp) دون سؤال المستخدم. يجب حتماً ولزاماً في كافة عمليات التصدير وتوليد المستندات (PDF، جداول Excel، صور المخططات PNG، ملفات CSV/TSV):
1. **فتح نافذة حوارية تفاعلية للنظام (Native Modal "Save As" Dialog):**
   - **في بيئة سطح المكتب (Windows Desktop):** إظهار نافذة اختيار مكان الحفظ وتسمية الملف (`FilePicker.saveFile` مع قفل النافذة الأم `lockParentWindow: true`) لتمكين المستخدم من تحديد المجلد والقرص واسم الملف المراد الحفظ فيه بحرية تامة.
   - **في بيئة المتصفح والويب (Web - Chromium):** استخدام **File System Access API (`window.showSaveFilePicker`)** لفتح نافذة Save As النظامية لتمكين المستخدم من تحديد مجلد الحفظ واسم الملف بدلاً من التنزيل الصامت التلقائي.
2. **المعالجة الآمنة للإلغاء (Graceful Cancellation — AbortError Handling):**
   - في حال قام المستخدم بإلغاء النافذة الحوارية (`Cancel`) في المتصفح، تطلق واجهة المتصفح استثناء `AbortError` (DOMException). يجب التقاطه بهدوء تام والتوقف فوراً مع إرجاع `null` دون كتابة أي ملفات ودون الرجوع للتنزيل الصامت عبر `<a download>` ودون إظهار أي رسائل خطأ للمستخدم.
3. **التراجع التلقائي الآمن للمتصفحات غير الداعمة (Browser Fallback & Informative Toast):**
   - إذا كان المتصفح لا يدعم `showSaveFilePicker` (مثل Firefox أو Safari أو متصفحات الهواتف)، يتم التراجع التلقائي لآلية التنزيل القياسية عبر `<a download>` مع إظهار شريط إشعار توضيحي للمستخدم:
     `متصفحك لا يدعم اختيار مجلد الحفظ — تم حفظ الملف في مجلد التنزيلات (Downloads)`
4. **المرور الحصري عبر الخدمة المركزية الموحدة (`FileSaveHelper`):** استدعاء `FileSaveHelper.exportAndSaveFile` أو `FileSaveHelper.saveBytes` / `FileSaveHelper.saveText` وتمرير مصفوفة البايتس `bytes` لضمان التوافقية الكاملة عبر سطح المكتب والويب.
5. **نظام التسمية القياسي الموحد (Standardized File Naming):** الالتزام بنمط التسمية القياسي المعتمد:
   `[Stage Name] - [Import File Name or Code].[ext]`
   (مثال: `Container Load Planner - PET Stock (IMP-2026-0004) - Stacking Sim.xlsx`).
6. **إشعار الإنجاز التفاعلي مع زر "فتح المجلد":** عند اكتمال الحفظ بنجاح، يجب إظهار شريط إشعار عائم (`SnackBar`) يؤكد حفظ الملف مع حجمه ويوفر زراً تفاعلياً (`فتح المجلد`) لفتح المجلد وتحديد الملف مباشرة داخل متصفح الملفات Windows Explorer في بيئة الديسكتوب (`explorer.exe /select, <path>`).

⚡ **قاعدة شريط الأدوات المدمج ومنع تداخل القوائم المنبثقة (Mandatory Compact Toolbar & Popover Anti-Collision Rule):**
يُحظر حظراً تاماً في شاشات القوائم والجداول الرئيسية (Type B List/Index Screens) استخدام صفوف إجرائية متعددة أو حشوات ضخمة تستهلك المساحة الرأسية وتدفع جدول البيانات إلى ما تحت حافة الشاشة (Below the fold). يجب حتماً ولزاماً:
1. **شريط أدوات موحد مدمج (Single Unified Compact Toolbar):** دمج منطقة الإجراءات في سطر واحد مدمج مباشرة فوق الجدول (بارتفاع أقصى 40 بكسل، وبارتفاع إجمالي لا يتعدى 80-90 بكسل شاملاً كافة الهوامش والحشوات)، مع إظهار ما لا يقل عن 4-5 صفوف من جدول البيانات دون الحاجة للتمرير (Scrolling) على شاشات اللابتوب القياسية بدقة 1366×768.
2. **قصر الأزرار المباشرة واستخدام قائمة المزيد (Inline Buttons & More Actions Menu):** يقتصر الشريط على 3 أزرار رئيسية مرئية فقط كحد أقصى (مثل: إضافة جديد، بحث واستنساخ، قائمة إجراءات إضافية ⋮)، مع نقل كافة الإجراءات المتقدمة أو الثانوية أو التوليدية إلى قائمة منسدلة (`More actions ⋮`).
3. **أبعاد الأزرار المدمجة:** لا يتعدى ارتفاع الأزرار 32 بكسل بحشوة أفقية 10-12 بكسل وحجم خط 12.5-13 بكسل.
4. **تضمين البحث والتصفية في نفس السطر:** حقل البحث السريع (عرض 180-220 بكسل) وقائمة التصفية (عرض 100-130 بكسل) يتواجدان على اليمين داخل نفس السطر الموحد.
5. **قاعدة منع تصادم وتداخل القوائم المنبثقة (Popover Collision Avoidance):** أي قائمة منسدلة أو منبثقة تنطلق من الترويسة أو شريط الأدوات (مثل محدد الكثافة `DisplayDensitySelector`) يجب أن:
   - تفتح بدقة تحت العنصر المفعل لها (`PopupMenuPosition.under`).
   - لا تتداخل أو تحجب الأزرار المجاورة (مثل زر العودة `Back to Dashboard`)، وفي حال وجود خطر تداخل تُحاذى القائمة لليمين وتمتد لليسار (Smart Collision Flip) نحو المساحة الفارغة.
   - لا تغطي عنوان الشاشة أو أزرار التنقل الرئيسية مطلقاً، مع تقييد حدودها الرأسية.

⚡ **قاعدة توحيد المكونات المشتركة والربط الشامل للكثافة (Mandatory Component Consolidation & Global Density Wiring Rule):**
يُحظر حظراً تاماً في أي شاشة من شاشات النظام بالكامل كتابة أو تكرار كود محلي مستقل (Ad-hoc / Local Markup) لترويسة الصفحة (Header)، أو شريط الأدوات الإجرائي (Toolbar)، أو بطاقات المقاييس والإحصائيات (Metric Cards). يجب حتماً ولزاماً:
1. **استخدام المكونات المشتركة الثلاثة الموحدة فقط من `frontend/lib/core/widgets/`:**
   - **ترويسة الصفحة الموحدة (`PageHeader`):** بارتفاع موحد متوازن (54px بدون عنوان فرعي، 58px مع عنوان فرعي) بخلفية كحلية مصمتة داكنة من `AppTheme.charcoal` (تمنع التدرجات البراقة Gradient التي تهدر المساحة)، مع قفل ارتفاعها ومنع تمددها الرأسي، وترتيب أزرار التنقل والإجراءات الرئيسية يميناً.
   - **شريط الأدوات الموحد المدمج (`ActionToolbar`):** صف أفقي موحد مدمج (بارتفاع 30-40px حسب الكثافة) يدمج الأزرار الأساسية (بحد أقصى 3)، وقائمة الإجراءات الإضافية (`More actions ⋮`)، وحقل البحث السريع، وقوائم التصفية، وأيقونات البيانات السريعة (تحديث، إكسل، بي دي إف) مع التجاوب الأفقي الآمن لمنع أي تجاوز أو قص (`RenderFlex overflow`).
   - **شريط بطاقات المقاييس (`MetricCard` / `MetricCardStrip`):** بطاقات ملخص إحصائي موحدة ترتبط مباشرة بـ `MetricCardData` وتستجيب لحظياً لكثافة العرض لتتقلص من 72px في الوضع المريح إلى 42px في الوضع فائق الكثافة، مع التجاوب الذكي للشاشات المدمجة بدقة 1366×768.
2. **الربط الشامل الفعلي لكافة عناصر الشاشة بمحدد الكثافة (`displayDensityProvider`):**
   - يُحظر قصر تأثير محدد الكثافة على ارتفاع صفوف الجداول فقط.
   - يجب ربط كافة توكنز الكثافة (`density.buttonHeight`، `density.buttonPadding`، `density.buttonFontSize`، `density.headerPadding`، `density.headerTitleFontSize`، `density.toolbarHeight`، `density.metricCardHeight`) بالترويسات والأزرار وشريط الأدوات وبطاقات المقاييس وجداول البيانات معاً.
3. **منع التباين البصري بين الشاشات (Visual Consistency Guarantee):**
   - أي تعديل في مقاسات أو كثافة الواجهة يجب أن يتم مركزياً في مكونات `PageHeader` و `ActionToolbar` و `MetricCard` وتوكنز الكثافة في `DisplayDensityMode` لكي ينعكس فورياً وتلقائياً على كافة شاشات النظام دون الحاجة لتعديل شاشة تلو الأخرى.

⚡ **قاعدة شريط المؤشرات المدمج الموحد (Mandatory Compact Metric Strip Rule):**
يُحظر حظراً تاماً في أي شاشة من شاشات النظام بالكامل استخدام شبكة بطاقات إحصائية رأسية متعددة الصفوف (مثل شبكة 2×2 من البطاقات الضخمة) التي تستهلك المساحة الرأسية وتدفع الجداول لأسفل خط الطي. يجب حتماً ولزاماً:
1. **سطر واحد أفقي موحد (Single-Row Strip):** عرض كافة المؤشرات جنباً إلى جنب في سطر واحد داخل حاوية موحدة ذات إطار خفيف وفواصل رأسية بين المؤشرات (`VerticalDivider`)، بارتفاع 40-44 بكسل في الوضع المريح.
2. **التخطيط الأفقي المضمن (Inline Horizontal Layout):** عرض كل مؤشر بصيغة مضمنة في سطر واحد `[icon] Title: Value` (أيقونة 16-18 بكسل بلون المؤشر، يليها العنوان ثم القيمة البارزة في نفس السطر، بدلاً من وضع الأيقونة والعنوان والقيمة في صفوف رأسية منفصلة).
3. **الربط الحتمي برموز الكثافة (Density-Scaled Height):** يتقلص ارتفاع الشريط الموحد تلقائياً من 42 بكسل (في الوضع المريح) إلى 34 بكسل (في الوضع المدمج) و 28 بكسل (في الوضع فائق الكثافة) باستخدام الرمز المركزي `density.metricCardHeight` وبحشوات تتناسب مع كل وضع.
4. **الترتيب الرأسي القياسي لعناصر الشاشة (Target Layout Order):**
   - 1. ترويسة الصفحة الموحدة (`PageHeader`).
   - 2. شريط المؤشرات المدمج (`MetricCardStrip`).
   - 3. شريط الأدوات المدمج (`ActionToolbar`).
   - 4. جدول البيانات الرئيسي (`DataTable`).
5. **حظر التمرير الأفقي للشريط:** يُحظر جعل الشريط قابلاً للتمرير الأفقي لعرض المزيد من المؤشرات؛ ولا يُسمح بالالتفاف على صفين إلا على شاشات الموبايل الضيقة جداً (<600px).

⚡ **قاعدة مصفوفة التدرج الطباعي حسب الكثافة وقاعدة الحد الأدنى 11 بكسل (Mandatory Typography Scale & 11px Floor Rule):**
يُحظر حظراً تاماً في أي شاشة أو مكون من مكونات النظام بالكامل تقليص الخطوط عشوائياً أو مساواة كافة النصوص بحجم واحد، أو النزول بأي نص عن 11 بكسل. يجب حتماً ولزاماً:
1. **مصفوفة أحجام الخطوط المعتمدة لكل مستوى كثافة (Font-size Scale per Density Level):**

| عنصر الواجهة (UI Element) | المريح (Comfortable) | المدمج (Compact) | فائق الكثافة (Ultra-Compact) | التوكن المركزي في `DisplayDensityMode` |
|---|---|---|---|---|
| عنوان الصفحة (Page title) | 20px | 17px | 15px | `density.headerTitleFontSize` |
| العنوان الفرعي (Page subtitle) | 13px | 12px | 11px | `density.headerSubtitleFontSize` |
| عنوان وقيمة شريط المؤشرات (Metric Strip) | 14px | 13px | 12px | `density.metricTitleFontSize` / `metricValueFontSize` |
| نصوص أزرار شريط الأدوات (Button text) | 13px | 12px | 12px | `density.buttonFontSize` |
| ترويسة الجدول (Table header row) | 13px | 12px | 12px | `density.tableHeaderFontSize` |
| خلايا الجدول الأساسية (Table cell primary) | 14px | 13px | 12px | `density.tableCellPrimaryFontSize` |
| خلايا الجدول الثانوية والرموز (Table cell secondary) | 12px | 11px | 11px | `density.tableCellSecondaryFontSize` |
| حقول البحث وقوائم التصفية (Search & Filter input) | 13px | 12px | 12px | `density.inputFontSize` |
| عناصر القائمة الجانبية (Sidebar nav items) | 13px | 13px | 12px | `density.sidebarNavFontSize` |

2. **قاعدة الحد الأدنى الإلزامية 11 بكسل (Strict 11px Floor Rule):**
   - يُحظر تماماً وجود أي نص في النظام بالكامل بحجم أقل من 11 بكسل (NO text < 11px).
   - حتى في وضع `Ultra-Compact`، تُقفل كافة النصوص المساعدة (Sub-labels، Chips، Tooltips، Badges، Timestamps) عند 11 بكسل كحد أدنى للقراءة السليمة (`DisplayDensityMode.clampFontSize(size)`).
3. **التدرج الهرمي البصري ومنع التسطيح (Scale, Don't Flatten):**
   - يجب أن يظل عنوان الصفحة أكبر وأبرز بصرياً من خلايا الجدول في كافة الأوضاع.
   - خلايا الجدول الأساسية أكبر دائماً من أو تساوي النصوص الثانوية. يُمنع تحويل كل نصوص الشاشة إلى 12px بشكل عشوائي.
4. **التدرج المحافظ لحجم الأيقونات (Conservative Icon Scaling):**
   - أيقونات أزرار شريط الأدوات: 16px (Comfortable) ← 15px (Compact) ← 14px (Ultra-Compact) (`density.buttonIconSize`).
   - أيقونات شريط المؤشرات: 17px ← 15.5px ← 14px (`density.metricIconSize`).
   - أيقونة ترويسة الصفحة: 22px ← 20px ← 18px (`density.headerIconSize`).
5. **الربط المركزي الحتمي:**
   - كافة أحجام الخطوط تُجلب حصرياً من `DisplayDensityMode` عبر `ref.watch(displayDensityProvider)` ويُحظر كتابة مقاسات ثابتة (Hard-coded) مستقلة لكل شاشة.

⚡ **قاعدة التسميات المختصرة لشريط المؤشرات وعدم قص القيم (Mandatory Metric Short Labels & Value Preservation Rule):**
يُحظر حظراً تاماً قص تسميات المؤشرات في منتصف الكلمة بنقاط الحذف (`Total PI/PO Am...`، `Total Gross Wei...`) عند ضيق المساحة في شريط المقاييس والإحصائيات. يجب حتماً ولزاماً:
1. **تعريف تسمية مختصرة ثابتة لكل مؤشر (Defined Short Labels):**
   - `Total POs` → `POs`
   - `Total PI/PO Amount` → `PI/PO Amt`
   - `Total Cargo CBM` → `CBM`
   - `Total Gross Weight` → `Gross Wt`
   - تمرير `shortTitle` عبر `MetricCardData` أو الاعتماد على القاموس المركزي التلقائي `MetricCardData.defaultShortLabel(fullTitle)`.
2. **التبديل التلقائي حسب الكثافة والمساحة (Density & Space Responsive):**
   - تُفعل التسميات المختصرة في أوضاع الكثافة `Compact` و `Ultra-Compact`، أو عند ضيق العرض المتاح عن 660 بكسل.
3. **قيمة المؤشر الرقمية خط أحمر (Numeric Values Are Never Truncated):**
   - يُحظر تماماً تحت أي ظرف قص أو إخفاء أي جزء من القيمة الرقمية (مثل `$126294.00`). يُسمح فقط بتقليص التسمية إلى صيغتها المختصرة.
4. **الالتفاف الذكي لصفين عند ضيق المساحة (2-Row Responsive Wrap):**
   - في حال كانت المساحة ضيقة جداً بحيث لا تتسع حتى للتسمية المختصرة والقيمة معاً، يلتف الشريط تلقائياً إلى صفين (مؤشران لكل صف `2x2 grid`) بدلاً من اقتطاع النص أو الإخلال بتناسق الواجهة.

⚡ **قاعدة حظر التداخل الشامل للعناصر العائمة والدك الجانبي (Universal Anti-Overlap & Floating Elements Docking Rule):**
يُحظر حظراً تاماً على أي عنصر عائم في النظام بالكامل (الودجت العائم للمساعد الذكي/الدعم، القوائم المنبثقة Popovers، القوائم المنسدلة Dropdowns، التلميحات Tooltips، إشعارات التوست Toasts) أن يعلو أو يحجب أو يغطي جداول البيانات أو نماذج الإدخال أو أزرار الإجراءات. يجب حتماً ولزاماً:
1. **موضع زر ودجت المحادثة والدعم وخلوص نهاية الجدول (Launcher Positioning & 72px End Clearance):**
   - في وضع الطي (Collapsed)، يستقر الزر في زاوية الشاشة السفلية.
   - يجب أن يوفر أي جدول بيانات يُمرر أفقياً هامش أمان إضافي لا يقل عن 72 بكسل (`width: tableTotalWidth + 72`) لضمان ظهور آخر عمود وأزرار الإجراءات بوضوح تام خلف الزر العائم عند التمرير لنهاية الجدول.
2. **الدك الجانبي للوحة المحادثة (Docked Side Panel on Desktop >= 1200px):**
   - يُحظر تماماً أن تطفو لوحة المحادثة الموسعة فوق جدول البيانات.
   - على شاشات سطح المكتب (Desktop >= 1200px)، يتم دك لوحة المساعد الذكي في شريط جانبي ثابت (`AiAssistantDockedPanel` بعرض 410px أو 560px عند التوسيع) داخل الـ `Row` الرئيسي للتطبيق بجوار منطقة العمل، مما يؤدي لدفع وتقليص مساحة العرض الرئيسية (`Expanded`) ليحتفظ جدول البيانات بحدوده المستقلة وتمريره دون أي تداخل.
   - على الشاشات الأصغر (< 1200px)، تفتح اللوحة كنافذة مشروطة (Modal Overlay) مع غطاء تعتيم خلفي (`ModalBarrier`) يمنع النقر العرضي على ما خلفها.
3. **فقاعة الترحيب الذكية (Smart Greeting Bubble Auto-Dismiss):**
   - يجب أن تختفي وتنهار تلقائياً بعد 7 ثوانٍ من ظهورها (`Timer(7 seconds)`).
   - يجب أن تنهار وتختفي فورياً عند أي تفاعل أو تمرير (Scroll) في أي جدول بيانات أو قائمة داخل الشاشة عبر `NotificationListener<ScrollNotification>`.
   - يجب تزويدها بزر إغلاق صريح (X) يُلغيها فورياً.
   - يُحظر أن تحجب ترويسة الجدول أو خلاياه أو أزراره مطلقاً.
4. **الوعي بحدود الشاشة لكافة القوائم المنسدلة والمنبثقة (Boundary-Aware Positioning):**
   - يجب أن تفتح القوائم المنبثقة، منتقيات التواريخ، ومحددات البيانات مراعيةً حدود الشاشة (تنعكس لأعلى أو تتجه لليسار Smart Flip) لضمان عدم حجب الصف الفعال أو تجاوز حدود الشاشة.

---

### 🎯 المتطلبات الإلزامية للاختبارات (Mandatory Unit Testing):
1. **الـ Backend (FastAPI / pytest):**
   - إنشاء اختبارات وحدة لكل Service و Validator داخل مجلد `tests/unit/`.
   - اختبار الحالات الناجحة (Happy Path) وحالات الخطأ والـ Edge Cases.
2. **الـ Frontend (Flutter / flutter test):**
   - كتابة اختبارات للموديول والـ Providers وحسابات الأرقام والـ Models.

### 📐 العمليات الواجب اختبارها بدقة:
```text
CBM Calculations
Volumetric Weight
Chargeable Weight
Customs Calculations & Landed Cost
Stage-Based Validation
Duplicate Detection & Soft Delete Rules
Unit Conversions & Tax Calculations
```

### 📁 هيكل مجلد الاختبارات الإلزامي:
```text
tests/
├── unit/
│   ├── test_cbm_calculator.py
│   ├── test_customs_engine.py
│   ├── test_import_companies.py
│   └── test_suppliers.py
├── integration/
└── api/
```


---

# 17. 📝 Documentation Rules

قبل تنفيذ Task جديدة:

1. قراءة `doc.md`.
2. قراءة الملفات المتعلقة بالمهمة داخل `docs/`.
3. فحص Architecture الحالية.
4. فحص الملفات المتأثرة.
5. عدم إعادة كتابة ملفات غير مرتبطة بالمهمة.

بعد التنفيذ:

1. توثيق التغييرات.
2. توثيق الملفات المعدلة.
3. توثيق المشاكل التي تم حلها.
4. توثيق الخطوة التالية.

---

# 18. 📅 Daily History & Task Logging Protocol

يجب تسجيل كل Task مكتملة في:

```text
history/
```

ويكون اسم الملف:

```text
history/YYYY-MM-DD.md
```

مثال:

```text
history/2026-08-07.md
```

---

## Append-Only Rule

إذا كان ملف اليوم موجودًا:

```text
DO NOT DELETE
DO NOT REPLACE
DO NOT OVERWRITE
```

يجب إضافة Task جديدة في نهاية الملف.

---

## Task Entry Template

```markdown
## 📝 [Date & Time] - Completed Task: [Task Name]

### 📌 Overview

- **Task Code:** [BP-001 / MD-004]
- **Description:** [Short description]

### 📁 Files Changed

- `path/to/file.py` — Created
- `path/to/file.py` — Modified

### 📊 Technical Changes

- [Change 1]
- [Change 2]

### 🧪 Validation / Testing

- [Test performed]
- [Result]

### 🏁 Next Steps

- [Next task]
```

---

# 19. 🤖 AI Development Workflow

عند استلام أي Task جديدة، يجب اتباع:

```text
1. Understand
       ↓
2. Inspect
       ↓
3. Plan
       ↓
4. Implement
       ↓
5. Validate
       ↓
6. Test
       ↓
7. Document
       ↓
8. History
```

---

# 20. 🚫 Forbidden Development Practices

يمنع:

* وضع Business Logic داخل Router.
* تكرار Business Logic.
* تكرار Validation.
* Hard-Coding للقواعد المتغيرة.
* حذف بيانات Master Data نهائيًا.
* تجاهل Database Constraints.
* إنشاء Tables بدون Migration.
* تعديل Database Schema يدويًا بدون Alembic.
* إنشاء ملفات جديدة بدون سبب معماري واضح.
* تغيير Architecture أثناء تنفيذ Task صغيرة بدون مبرر.
* تعديل ملفات غير مرتبطة بالمهمة.
* تخطي FileSaveHelper أو الحفظ الصامت التلقائي لأي ملف دون فتح نافذة حوارية للمستخدم لتحديد مكان الحفظ.
* استخدام أسماء ملفات عشوائية أو عامة في عمليات التصدير (مثل export.pdf أو download.xlsx).
* استخدام أسماء غير واضحة للمتغيرات.
* إنشاء Functions ضخمة تقوم بأكثر من مسؤولية.

---

# 21. 🧹 Clean Code Rules

يجب الالتزام بمبادئ:

```text
Single Responsibility
DRY
KISS
Separation of Concerns
Explicit over Implicit
Small Functions
Meaningful Names
Type Hints
Reusable Components
```

يفضل:

```python
def calculate_cbm(...)
```

بدل:

```python
def calc(...)
```

---

# 22. 🔄 Change Management

قبل تعديل Architecture أو Database Structure يجب:

1. تحديد سبب التغيير.
2. تحديد الملفات المتأثرة.
3. تحديد تأثير التغيير.
4. تنفيذ التغيير تدريجيًا.
5. اختبار النظام.
6. تحديث Documentation.
7. تسجيل التغيير في History.

---

# 23. 🏛️ Architecture Principle

الهدف ليس فقط أن يعمل الكود.

الهدف أن يكون:

```text
Correct
Maintainable
Testable
Scalable
Auditable
Extensible
```

أي قرار معماري يجب تقييمه بناءً على تأثيره على:

```text
Future Modules
Database Integrity
Business Rules
Testing
Integration
Maintenance
```

---

# 24. 🎯 Final AI Rule

عند وجود تعارض بين:

```text
Quick Fix
```

و:

```text
Correct Architecture
```

يجب تفضيل:

**Correct Architecture**

حتى لو تطلب ذلك خطوات إضافية.

وعند وجود أكثر من حل صحيح، يجب اختيار الحل:

```text
Simpler
More Maintainable
More Testable
More Consistent
```

مع الحفاظ على Architecture الحالية للمشروع وعدم إدخال تعقيد غير ضروري.

---

# 25. 📌 Project Golden Rule

> **ImportFlow ERP is a Business System first, an API second, and a UI third.**

لذلك:

```text
Business Rules
        ↓
Domain / Services
        ↓
API
        ↓
Flutter Desktop
```

ويجب أن تظل قواعد العمل مستقلة قدر الإمكان عن واجهة المستخدم وقاعدة البيانات.
