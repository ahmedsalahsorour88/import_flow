# Phase 4: Freight Booking & Carrier Allocation (حجز الشحن والتخصيص)

## 📌 Overview
تهدف المرحلة الرابعة إلى تحويل نتائج عروض الأسعار والدراسات اللوجستية إلى حجز مؤكد وموثق على خطوط الشحن (Shipping Lines / Freight Forwarders). تشمل هذه المرحلة اختيار مزود الخدمة، مسودة الحجز، تثبيت مواعيد الإبحار والوصول المتوقعة (ETD / ETA)، وتحديد الحاويات ومراكز الشحن.

---

## ⚙️ Business Processes Breakdown (العمليات التفصيلية)

### BP-017: Select Freight Provider (اختيار مزود خدمة الشحن)
- **الغرض**: الاعتماد الرسمي لشركة الشحن أو وكيل الشحن (Freight Forwarder / Shipping Line) من بين عروض الأسعار المسجلة في BP-008.
- **قواعد الاختيار**:
  - التكلفة الإجمالية (Freight Rate Card MD-026).
  - مدة الترانزيت المباشرة وغير المباشرة (Transit Time).
  - الفترات المجانية المعروضة في ميناء التفريغ (Free Demurrage & Detention Days).
  - التقييم وسابقة الأعمال الخاصة بمزود الخدمة (MD-003).

### BP-018: Create Shipment Booking (إنشاء وتجهيز طلب حجز الشحن)
- **الغرض**: إدخال وتوثيق كافة تفاصيل مسودة حجز الشحن (**Booking Draft**).
- **البيانات المسجلة في الحجز**:
  - Booking Number.
  - Shipper / Foreign Exporter (MD-002).
  - Consignee (Egyptian Importer MD-001).
  - Port of Loading (POL) & Port of Discharge (POD) (MD-009).
  - Container Specifications & Quantities (MD-010, MD-011).
  - Cargo Cut-off Date & SI Cut-off Date.
  - Freight Payment Terms (Prepaid / Collect).

### BP-019: Confirm Shipment Booking & Vessel Allocation (تأكيد الحجز وتثبيت المواعيد)
- **الغرض**: استقبال وتأكيد تأكيد الحجز الرسمي (**Booking Confirmation**) المسلم من الخط الملاحي وتحديث المواعيد التشغيلية.
- **الحقول المحينة**:
  - Vessel Name & Voyage Number (اسم السفينة ورقم الرحلة).
  - Estimated Time of Departure (ETD).
  - Estimated Time of Arrival (ETA).
  - Container Release Orders (أوامر صرف الحاويات الفارغة).
- **إدارة التغييرات والتنبيهات**:
  - في حال تغيير تاريخ الوصول (ETA Change)، يقوم النظام بتحديث لوحة متابعة التعديلات (**ETA Changes Workspace**) وتعديل المهام التلقائية المترتبة على موعد الوصول.

---
*توثيق المرحلة الرابعة - ImportFlow ERP*
