# Phase 9: Comprehensive Landed Cost Engine (محرك التكلفة الشاملة والتسوية المالية)

## 📌 Overview
تغطي المرحلة التاسعة المحرك المالي الرئيسي لحساب تكلفة وصول الشحنة الإجمالية (**Comprehensive Landed Cost Engine**). يقوم المحرك بالتجميع التلقائي لكافة التكاليف والمصروفات الفعلية المسجلة عبر دورة الاستيراد (فواتير المورد، النولون، الرسوم والضرائب الجمركية من **سجل نافذة النهائي**، الأرضيات، أتعاب التخليص، النقل الداخلي، الفحص المسبق، المصروفات البنكية)، وتوزيعها بدقة ومرونة على بنود وأصناف الشحنة لاحتساب تكلفة الوحدة النهائية بالجنيه ومعامل التضخيم (**Markup Factor**).

---

## ⚙️ Business Processes Breakdown (العمليات التفصيلية)

### BP-036 & BP-037: Automatic Actual Expense Aggregation (تجميع المصروفات الفعلية آلياً)
- **الغرض**: جمع كافة فواتير ومطالبات المصروفات الفعلية المسددة في المراحل السابقة دون إدخال يدوي مكرر:
  1. قيمة البضاعة الموردة (**FOB Value**).
  2. نولون ومصاريف الشحن الدولي (**Freight & Carrier Charges**).
  3. الرسوم والضرائب الجمركية الفعلية المستخلصة من **سجل نافذة النهائي** (Import Duty, VAT, Schedule Tax, WHT 1%, Lab/Service Fees).
  4. مصاريف الأرضيات وغرامات التأخير إن وجدت (**Port Demurrage / Storage**).
  5. أتعاب التخليص الجمركي ومصروفات الدائرة (**Clearance Broker Fees**).
  6. النقل الداخلي والتعتيق والتخزين (**Inland Transport & Handling**).
  7. شهادات المنشأ والفحص والجودة (**Inspection & Certificates**).
  8. العمولات والمصروفات البنكية ونموذج 4 (**Bank Charges & Form 4**).

### BP-038: Smart Multi-Criteria Cost Allocation Engine (محرك التوزيع الذكي)
- **الغرض**: توزيع كل فئة مصروف على الأصناف بالمعيار الأنسب لطبيعتها:
  - **حسب القيمة (FOB Value-Based):** للجمارك، التأمين، المصروفات البنكية.
  - **حسب الوزن الإجمالي (Gross Weight-Based):** للشحن الجوي والنقل البري الداخلي.
  - **حسب الحجم (CBM-Based):** للشحن البحري FCL/LCL ورسوم التخزين.
  - **حسب عدد القطع / بالتساوي (Quantity / Equal-Based):** للمصاريف الإدارية والرسوم الثابتة.

### BP-039: Itemized Landed Cost & Markup Factor Sheet (شيت تكلفة البند النهائي)
- **الغرض**: حساب التكلفة المحاسبية الدقيقة للوحدة الواصلة لكل صنف بالجنيه:
  $$\text{Unit Landed Cost (EGP)} = \text{FOB Unit} + \sum \text{Allocated Expenses per Unit}$$
  $$\text{Markup Factor} = \frac{\text{Unit Landed Cost (EGP)}}{\text{FOB Unit Cost (EGP)}}$$
- توفير مقارنة فورية بين الميزانية التقديرية (Estimated Budget) والتكلفة الفعلية المحققة (Actual Landed Cost).

---
*توثيق المرحلة التاسعة - ImportFlow ERP*
