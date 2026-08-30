# Task Specification: BP-001 - Receive Purchase Order

## 📌 Overview
استلام أمر الشراء المعتمد وربطه بالمشروع والمورد والشركة المستوردة.

## ⚙️ Task Execution Steps (خطوات التنفيذ)
1. **استلام البيانات والمدخلات**: استقبال المستندات والبيانات الأولية المطلوبة لهذه المهمة.
2. **التحقق وتطبيق قواعد العمل**: التأكد من تطبيق Validation Rules واشتراطات الـ Master Data.
3. **التوثيق وتحديث الحالة**: تسجيل البيانات الناتجة وتحديث الحالة التشغيلية للشحنة (Operational State).
4. **السجل التاريخي Audit Trail**: تسجيل اسم المستخدم وتاريخ العملية وملاحظات التعديل.

## 📑 Required Inputs & System Master Data
- **Key Fields**:
  - `po_number`: الكود/الرقم المرجعي الرسمي لأمر الشراء (Unique System Code).
  - `po_reference`: الاسم/المرجع الوصفي لأمر الشراء (Descriptive PO Name / Reference) لسهولة التمييز والربط المباشر في دراسات الشحن واستشارات الجمارك (مثل: "طلبية خامات الربع الأول - مصنع أكتوبر").
- **Master Data Dependencies**: Company (MD-001), Supplier (MD-002), Currency (MD-005), Incoterms (MD-006), Projects (MD-007).
- **Document Attachment**: إرفاق المستندات الرسمية الداعمة للمهمة.

## 🏁 Output & Next Operational Milestone
- **Task Output**: تجميع السجلات المطلوبة وتأكيد إكتمال المهمة وإتاحة أمر الشراء بالاسم والمرجع (`po_number (po_reference)`) داخل شاشات المفاضلة ودراسة الشحن والاستشارات الجمركية.
- **Next Milestone**: الانتقال للمهمة التالية في سير العمل المرن (Flexible Workflow).

---
*ImportFlow ERP Task Spec*
