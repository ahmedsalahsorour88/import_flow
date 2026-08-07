# Phase 5: Cargo Preparation & Shipping (تجهيز الشحنة والتبادل الإلكتروني للمستندات)

## 📌 Overview
تعتبر المرحلة الخامسة من أهم مراحل التشغيل اللوجستي والمستندي. تشمل متابعة جاهزية البضائع لدى المصنع، تنفيذ التحميل والشحن الفعلي، التعيين والتدقيق الثنائي لمستندات الشحن الصادرة (Dual Approval)، استلام واستبدال المستندات الأصلية، وإدارة التبادل الإلكتروني عبر المنصات الرقمية الدولية (**Electronic Document Exchange / CargoX**).

---

## ⚙️ Business Processes Breakdown (العمليات التفصيلية)

### BP-020: Coordinate Cargo Readiness (تنسيق جاهزية البضاعة Cargo Readiness)
- **الغرض**: متابعة جدول الإنتاج والتعبئة في مصنع المورد وتوثيق تاريخ جاهزية البضاعة (**Cargo Ready Date - CRD**).
- **التنبيهات**: مطابقة CRD مع موعد قطع البضاعة في الحجز (Cargo Cut-off) لتجنب غرامات تأخير التجميع أو فقدان حجز السفينة.

### BP-021: Execute Cargo Loading (تنفيذ التحميل والشحن)
- **الغرض**: تسجيل إتمام تحميل الحاويات/الشحنة، وتوثيق أرقام الحاويات والرصاص الأمني (**Container & Seal Numbers**).
- **البيانات المسجلة**:
  - Container No (مثال: `MSKU1234567`).
  - Seal No (رقم الختم الرصاصي).
  - Tare Weight, Net Weight, Gross Weight per container.
  - VGM (Verified Gross Mass) Submission Record.

### BP-022: Review & Dual Approval of Shipping Documents (المراجعة الثنائية لمستندات الشحن)
- **الغرض**: تطبيق آلية الاعتماد الثنائي للمستندات الصادرة قبل اعتمادها نهائيًا، لضمان منع الأخطاء في بوالص الشحن والفواتير.
- **مراحل Dual Approval**:
  - **Level 1 Approval (Operational Review)**: مراجعة موظف التشغيل للبيانات الفنية (أرقام الحاويات، ACID، الأوزان، Incoterms).
  - **Level 2 Approval (Management/Customs Review)**: مراجعة مدير الاستيراد أو المستخلص الجمركي للبيانات القانونية والجمالية.

### BP-023: Collect Original Shipping Documents (تجمع واستلام المستندات الأصلية)
- **الغرض**: تتبع حركة المستندات الورقية الأصلية (Original B/L, Commercial Invoice, Certificate of Origin) الصادرة من المورد عبر شركات البريد السريع (DHL, FedEx, Aramex) وتوثيق استلامها بالبنك أو المقر.

### BP-024: Electronic Document Exchange - CargoX Integration (التبادل الإلكتروني للمستندات)
- **فلسفة التصميم البرمجي**: تصميم الخدمة باسم **Electronic Document Exchange** بشكل مستقل مرن (Platform-Agnostic)، ويكون CargoX عبارة عن Provider داخل جدول مرجعي يسمح بإضافة مزودي خدمة آخرين مستقبلاً.
- **مراحل العملية التشغيلية**:
  - **Stage 1 - Envelope Creation & Invitation**: إنشاء مظروف التبادل الإلكتروني وإرسال الدعوة للمورد/المصدر الأجنبي.
  - **Stage 2 - Verification Checklist Execution**: إنشاء قائمة مراجعة تلقائية مستخرجة من جدول `Document Verification Rules` واشتراط اجتياز جميع البنود بنجاح.
  - **Stage 3 - Upload Preparation**: تحويل الحالة إلى `Ready for Upload` عند اجتياز قائمة التحقق 100%.
  - **Stage 4 - Upload Execution & Status Tracking**: رفع الملفات وتسجيل الاستجابة والرقم المرجعي (Reference Number).
  - **Stage 5 - Completion & Audit**: توثيق إتمام عملية التبادل وربطها بالسجل التاريخي للشحنة.

### BP-025: Link Shipping Documents to ETMS & Tracking (ربط المستندات والتتبع)
- **الغرض**: ربط كافة المستندات والمعاملات بسجل التتبع الحقيقي ومتابعة موقع السفينة في البحر عبر رابط التتبع الخاص بالخط الملاحي.

---
*توثيق المرحلة الخامسة - ImportFlow ERP*
