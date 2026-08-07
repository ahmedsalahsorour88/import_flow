# 🤖 AI Agent Guidelines & Operating Instructions

# ImportFlow ERP

> **ملاحظة هامة للمساعد الذكي (AI Assistant):**
> يجب قراءة وتطبيق جميع القواعد والتعليمات الواردة في هذا الملف عند تحليل أو تطوير أو تعديل مشروع **ImportFlow ERP**.

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
importflow.db
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

# 7.2 Customs Calculation Engine

يشمل:

```text
Customs Valuation
CIF
Customs Duty
VAT
WHT
Exchange Rate
Customs Fees
Government Fees
Other Charges
```

> **ملاحظة:** نسب الضرائب والرسوم لا يجب Hard-Code داخل Business Logic إذا كانت قابلة للتغيير تشريعيًا.

بدلًا من:

```python
VAT_RATE = 0.14
```

يفضل أن تكون البيانات قابلة للإدارة من:

```text
Tax Rules
Customs Rules
Duty Rates
Government Fees
```

مع حفظ تاريخ سريان القاعدة:

```text
effective_from
effective_to
```

---

# 7.3 Landed Cost Engine

يجب أن يستطيع النظام حساب:

```text
Purchase Cost
+ Freight
+ Insurance
+ Customs Duty
+ VAT
+ WHT
+ Customs Fees
+ Clearance Fees
+ Local Charges
+ Other Import Costs
= Landed Cost
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
