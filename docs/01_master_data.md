# Master Data & General Principles (البيانات المرجعية والمبادئ العامة)

## 📌 1. General Principles (المبادئ العامة للنظام)

### GP-001 Progressive Data Entry (الإدخال التدريجي للبيانات)
- يسمح النظام بإنشاء ملف الاستيراد حتى في حالة عدم اكتمال جميع البيانات، مع استكمال البيانات تدريجيًا خلال مراحل العمل المختلفة.
- **القواعد**:
  - لا يشترط اكتمال جميع الحقول عند إنشاء ملف الاستيراد.
  - يتم إدخال البيانات حسب المستندات المتوفرة في كل مرحلة.
  - يمنع النظام فقط تنفيذ العمليات التي تعتمد مباشرة على بيانات غير مكتملة (مثال: عدم تنفيذ حساب CBM قبل إدخال الأبعاد).

### GP-002 Stage-Based Validation (التحقق المرتبط بالمرحلة)
- تطبيق التحقق من صحة البيانات بناءً على المرحلة الحالية للشحنة وليس عند إدخال البيانات فقط.
- عدم إجبار المستخدم على إدخال بيانات غير مطلوبة في المرحلة التشغيلية الحالية.

### GP-003 Editable Import Files (قابلية تعديل الملفات مع التتبع)
- السماح بتعديل ملفات الاستيراد طوال دورة العمل طالما لم يتم إغلاق الملف (`Closed`).
- الاحتفاظ بسجل كامل للتعديلات مع إظهار معلومات آخر تعديل (`Last Modified By`, `Last Modified Date`, `Modification Notes`).

### GP-004 Audit Trail (السجل التاريخي للعمليات)
- تسجبل شامل لكافة الأحداث الرئيسية (إنشاء، تعديل، اعتماد، تغيير حالة، رفع مستندات، تعديل تكاليف).
- يتضمن السجل: التاريخ والوقت، اسم المستخدم، نوع العملية، واسم الشاشة.

---

## 🗂️ 2. Master Data Specifications (مواصفات جداول البيانات المرجعية)

| Code | Entity Name | Description | Key Fields & Business Rules |
| :--- | :--- | :--- | :--- |
| **MD-001** | **Company (Egyptian Importers)** | إدارة الشركات المصرية المستوردة | Name, Address, Importer ID & Expiry, VAT ID & Expiry, Commercial Reg No & Expiry. يتم حساب الأيام المتبقية للتجديد ديناميكيًا. |
| **MD-002** | **Supplier (Foreign Exporters)** | إدارة الموردين الأجانب والمصدرين | Company Name, Registration Type, Foreign Exporter ID, Country Code, Address, Email, Brands. |
| **MD-003** | **External Service Providers** | المستخلصين الجمركيين وشركات الشحن | Service Provider Type, Commercial Reg, License Expiry, Service Rating, Tax ID. |
| **MD-004** | **Shipping Lines** | خطوط الشحن البحرية والجوية | Line Code, Name, SCAC Code, Tracking URL, Local Agent Details. |
| **MD-005** | **Currency Master** | العملات وأسعار الصرف | Currency Code (USD, EUR, EGP, etc.), Exchange Rates vs EGP, Effective Dates. |
| **MD-006** | **Incoterms Master** | شروط التجارة الدولية (FOB, CIF, CFR...) | Incoterm Code, Description, Risk Transfer Point, Freight/Insurance Responsibility Matrix (**MD-006A & MD-006B**). |
| **MD-007** | **Projects Master** | المشروعات ومراكز التكلفة المرتبطة | Project Code, Project Name, Budget, Client Name, Associated Import Files. |
| **MD-008** | **Customs Tariff (HS Code Master)** | التعريفة الجمركية وبنود HS Code | HS Code (10 digits), Duty Rate %, VAT %, Excise Duty %, Regulatory Inspection Requirements. |
| **MD-009** | **Ports & Transport Locations** | الموانئ والمطارات والمناطق اللوجستية | Port Code, Port Name, Country, Port Type (Sea / Air / Land / Dry Port). |
| **MD-010 to MD-015** | **Container & Packaging Master** | الحاويات والتعبئة والتخطيط | Container Types (20ft, 40ft, 40HQ, Reefer), Package Types, Handling Constraints, Loading Strategies (Space vs Payload Optimization). |
| **MD-016 to MD-019** | **Validation & Formula Engine** | قواعد التحقق والمعادلات | Validation Rules (Warning vs Blocking), Decision Statuses, Units of Measure (UOM) Conversion, Calculation Formulas. |
| **MD-020 to MD-026** | **Freight & Carrier Masters** | أسعار الشحن والعقود والخدمات | Shipping Methods, Service Levels, Routes, Carrier Services, Carrier Contracts & Freight Rate Cards. |

---
*مرجع البيانات المرجعية للنظام - ImportFlow ERP*
