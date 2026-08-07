dBusiness Vision & System Philosophy:
جميع جداول الـ Master Data تمثل البيانات المرجعية للنظام، ويتم إدخالها مرة واحدة وإعادة استخدامها في جميع مراحل دورة الاستيراد. يهدف هذا التصميم إلى منع تكرار البيانات، تقليل أخطاء الإدخال، ضمان توحيد المعلومات، ودعم إنشاء المستندات الرسمية والتقارير بشكل آلي. لا يجوز إدخال بيانات مرجعية مباشرة داخل المعاملات (Transactions)، بل يجب اختيارها من جداول الـ Master Data.
General System Principles
هذه القواعد تطبق على جميع العمليات داخل النظام.
2. System Design Philosophy
Purpose
يهدف هذا الفصل إلى توضيح المبادئ الأساسية التى تم بناء النظام عليها لضمان المرونة، وقابلية التوسع، ودعم الاختلافات التشغيلية التى تحدث فى بيئة الاستيراد الفعلية، دون الحاجة إلى تعديل تصميم النظام أو قاعدة البيانات مع تغير إجراءات العمل.
________________________________________
2.1 Flexible Workflow
Description
يعتمد النظام على مفهوم Flexible Workflow، حيث لا يشترط المرور بجميع مراحل التشغيل بنفس الترتيب أو استكمالها بالكامل قبل الانتقال إلى مرحلة أخرى.
قد تختلف دورة العمل من شحنة لأخرى حسب:
•	نوع الشحنة. 
•	متطلبات المورد. 
•	تعليمات البنك. 
•	اشتراطات الجهات الحكومية. 
•	قرارات الإدارة. 
•	الظروف التشغيلية. 
لذلك لا يعتبر النظام أن جميع المراحل إلزامية، وإنما يتعامل معها كمحطات تشغيلية (Operational Milestones) يمكن تجاوز بعضها أو التوقف عندها وفقًا لاحتياجات العمل.
________________________________________
Business Rules
•	يسمح بإيقاف الشحنة عند أى مرحلة. 
•	يسمح بتجاوز مرحلة إذا لم تكن مطلوبة. 
•	يسمح بالرجوع إلى مرحلة سابقة عند الحاجة. 
•	يتم تسجيل جميع الانتقالات داخل سجل تاريخى. 
•	لا يؤثر تجاوز مرحلة اختيارية على باقى دورة التشغيل. 
•	يمنع تجاوز المراحل الإلزامية إلا بصلاحيات خاصة مع تسجيل سبب التجاوز. 
•	•  يسمح بربط أكثر من فاتورة تجارية بالشحنة الواحدة وكل فاتوره من الممكن ان تمثل مشروع مختلف. 
•	•  يشترط وجود فاتورة تجارية واحدة على الأقل لكل شحنة. 
•	•  لا يوجد حد أقصى لعدد الفواتير المرتبطة بالشحنة.
________________________________________
2.2 Operational State Management
Description
يعتمد النظام على الحالة التشغيلية الحالية للشحنة (Current Operational State) بدلاً من الاعتماد على الشاشة التى يعمل عليها المستخدم.
كل شحنة تمتلك حالة تشغيلية واحدة تمثل موقعها الحالى داخل دورة العمل.
ويتم تحديث هذه الحالة تلقائياً عند اكتمال كل مرحلة أو عند انتقال الشحنة إلى مرحلة جديدة.
________________________________________
Examples
Current Stage
Booking Confirmed
Waiting For
Draft Bill of Lading
________________________________________
Benefits
•	معرفة مكان توقف كل شحنة. 
•	سهولة البحث والمتابعة. 
•	تحسين التقارير. 
•	دعم لوحات المتابعة التشغيلية. 
________________________________________
2.3 Operational Workspace
Description
يحتوى النظام على شاشة تشغيل رئيسية تمثل مركز العمل اليومى لجميع المستخدمين.
تعرض هذه الشاشة جميع العناصر التى تحتاج إلى متابعة دون الحاجة إلى الدخول لكل ملف استيراد على حدة.
وتعتبر نقطة البداية اليومية لجميع موظفى التشغيل.
________________________________________
Workspace Components
Today's Tasks
المهام المطلوب تنفيذها اليوم.
________________________________________
Pending Tasks
المهام التى لم يتم الانتهاء منها.
________________________________________
Upcoming Shipments
الشحنات المتوقع وصولها خلال الأيام القادمة.
________________________________________
Arriving This Week
الشحنات المتوقع وصولها خلال الأسبوع الحالى.
________________________________________
ETA Changes
الشحنات التى تم تعديل موعد وصولها.
________________________________________
Waiting For Payment
الشحنات المتوقفة بسبب المدفوعات.
________________________________________
Waiting For Form 4
الشحنات التى لم يتم الانتهاء من إجراءات Form 4 الخاصة بها.
________________________________________
Pending Requirements
الشحنات التى يوجد بها متطلبات أو موافقات أو مستندات غير مكتملة.
________________________________________
High Priority Alerts
التنبيهات ذات الأولوية المرتفعة.
________________________________________
2.4 Smart Task Management
Description
يوفر النظام نظاماً متكاملاً لإدارة المهام، ويقسمها إلى نوعين رئيسيين لضمان الفصل بين المهام الناتجة عن دورة العمل والمهام الشخصية للمستخدمين.
________________________________________
A. System Generated Tasks
يقوم النظام بإنشاء المهام تلقائياً بناءً على:
•	انتقال الشحنة بين المراحل. 
•	المتطلبات الإلزامية. 
•	المواعيد. 
•	التغييرات التشغيلية. 
•	التنبيهات. 
أمثلة:
•	متابعة Draft B/L. 
•	متابعة Form 4. 
•	استلام Commercial Invoice. 
•	مراجعة Arrival Notice. 
•	تحديث ETA. 
•	تنفيذ ملاحظات المخلص الجمركى. 
________________________________________
B. Manual To-Do List
يسمح النظام للمستخدم بإنشاء مهام أو تذكيرات خاصة لا ترتبط مباشرة بقواعد التشغيل.
تستخدم هذه المهام لتنظيم الأعمال اليومية ومتابعة الإجراءات الداخلية.
________________________________________
Task Information
•	Title 
•	Description 
•	Related Import File 
•	Related Shipment 
•	Assigned User 
•	Priority 
•	Due Date 
•	Reminder Date 
•	Status 
•	Notes 
________________________________________
Business Rules
•	يسمح بإضافة عدد غير محدود من المهام. 
•	يمكن إنشاء المهام على مستوى ملف الاستيراد أو الشحنة أو المرحلة. 
•	لا يؤثر حذف المهام اليدوية على حالة الشحنة. 
•	يتم إغلاق المهام التلقائية تلقائياً عند اكتمال المرحلة المرتبطة بها. 
•	يمكن إرفاق ملفات أو ملاحظات بكل مهمة. 
________________________________________
2.5 Reminder Engine
Description
يمكن ربط أى مهمة أو متابعة بتاريخ ووقت للتذكير.
يقوم النظام بعرض التنبيهات تلقائياً عند حلول موعدها.
________________________________________
Supported Reminders
•	متابعة المورد. 
•	متابعة البنك. 
•	متابعة شركة الشحن. 
•	متابعة المخلص الجمركى. 
•	مراجعة مستند. 
•	متابعة موعد الوصول. 
•	أى تذكير آخر يضيفه المستخدم. 
________________________________________
2.6 Milestone Progress Tracking
Description
يعرض النظام تقدم كل شحنة باستخدام مخطط مرئى يوضح جميع مراحل التشغيل، مع إبراز المرحلة الحالية ونسبة الإنجاز.
يهدف هذا العرض إلى توفير رؤية سريعة عن حالة كل شحنة دون الحاجة إلى استعراض تفاصيلها.
________________________________________
Benefits
•	تحديد مكان توقف الشحنة. 
•	معرفة المراحل المكتملة. 
•	معرفة المراحل المتبقية. 
•	تسهيل متابعة عدد كبير من الشحنات. 
________________________________________
2.7 Dynamic Reporting
Description
لا يعتمد النظام على مجموعة ثابتة من التقارير، وإنما يوفر أداة لإنشاء تقارير مخصصة (Dynamic Report Builder) تمكن المستخدم من تصميم التقرير وفقاً لاحتياجاته.
________________________________________
Supported Features
•	اختيار الأعمدة. 
•	ترتيب الأعمدة. 
•	تطبيق الفلاتر. 
•	التجميع. 
•	الفرز. 
•	حفظ تصميم التقرير. 
•	إعادة استخدام التقرير. 
•	تصدير إلى Excel أو PDF. 
________________________________________
Example Fields
•	Booking No 
•	AWB / MBL 
•	ACID 
•	Customs Broker 
•	Shipping Provider 
•	Supplier 
•	Project 
•	PI Value 
•	Shipping Mode 
•	Incoterm 
•	Container Details 
•	Cargo Ready Date 
•	Shipping Date 
•	ETA 
•	Arrival at Warehouse 
•	Current Status 
________________________________________
Business Rules
•	يمكن لكل مستخدم إنشاء عدد غير محدود من التقارير. 
•	يمكن مشاركة التقارير مع مستخدمين آخرين. 
•	يمكن حفظ التقرير كقالب (Template). 
•	تعتمد جميع التقارير على البيانات الحية للنظام. 
________________________________________
2.8 Audit & Traceability
Description
لضمان الشفافية وسهولة المراجعة، يحتفظ النظام بسجل كامل لجميع العمليات التشغيلية والتعديلات التى تتم على ملفات الاستيراد والشحنات.
يشمل ذلك:
•	انتقالات المراحل. 
•	التعديلات على البيانات. 
•	إنشاء أو إغلاق المهام. 
•	تغيير المواعيد (مثل ETD وETA). 
•	إضافة أو إزالة المتطلبات. 
•	تعديل بنود التكلفة. 
•	تنفيذ أو تجاوز المراحل. 
•	تسجيل أسباب التعديل أو التجاوز عند الحاجة. 


2.9 Template-Based Data Import
Description
يدعم النظام الاستيراد الجماعي للبيانات من خلال قوالب (Templates) موحدة يتم توفيرها لكل جدول رئيسي أو تشغيلي. وتهدف هذه الآلية إلى تسهيل إدخال البيانات بكميات كبيرة، وتقليل الإدخال اليدوي، وضمان توافق البيانات مع هيكل النظام وقواعد العمل قبل اعتمادها.
Business Rules
•	يوفر النظام قالبًا قياسيًا لكل جدول يدعم الاستيراد. 
•	يمكن تنزيل أحدث إصدار من القالب مباشرة من داخل النظام. 
•	يلتزم المستخدم باستخدام القالب المعتمد دون تعديل هيكله. 
•	يتحقق النظام من صحة البيانات قبل بدء عملية الاستيراد. 
•	يعرض النظام تقريرًا تفصيليًا بجميع الأخطاء مع تحديد الصف والحقل ووصف الخطأ. 
•	لا يتم حفظ أي بيانات لا تستوفي قواعد التحقق. 
•	يسمح بإعادة رفع الملف بعد تصحيح الأخطاء دون الحاجة إلى إعادة إدخال جميع البيانات. 
•	تخضع عمليات تنزيل ورفع القوالب لصلاحيات المستخدمين (Role-Based Access Control). 
•	يجب أن تتوافق جميع القوالب مع أحدث إصدار من هيكل قاعدة البيانات.

________________________________________
2.10 Master Data Integrity
Description
يعتمد النظام على مفهوم Master Data Management بحيث يتم تعريف البيانات المرجعية مرة واحدة فقط وإعادة استخدامها في جميع العمليات التشغيلية. يهدف هذا النهج إلى منع تكرار البيانات، وتحسين جودة المعلومات، وضمان توحيد البيانات المستخدمة في جميع المستندات والتقارير.
Business Rules
•	يتم إنشاء البيانات المرجعية مرة واحدة فقط. 
•	يمنع إدخال البيانات المرجعية مباشرة داخل المعاملات. 
•	يتم اختيار البيانات المرجعية من القوائم المعتمدة. 
•	تعتمد جميع المستندات والتقارير على البيانات المرجعية. 
•	يسمح بتحديث البيانات المرجعية وفقًا لصلاحيات المستخدم دون التأثير على السجلات التاريخية. 
•	يدعم النظام الاستيراد الجماعي لبيانات الـ Master Data باستخدام القوالب المعتمدة.

2.11 Configuration Over Customization
Description
يعتمد النظام على مبدأ Configuration Over Customization، بحيث يتم التحكم في سلوك النظام من خلال الإعدادات وقواعد العمل بدلاً من تعديل الكود البرمجي. ويضمن ذلك سهولة التطوير المستقبلي وتقليل تكلفة الصيانة.
Business Rules
•	يمكن تفعيل أو تعطيل المراحل التشغيلية من خلال الإعدادات. 
•	يمكن تحديد الحقول الإلزامية حسب نوع العملية. 
•	يمكن تعديل قوائم المتطلبات دون الحاجة إلى تطوير برمجي. 
•	يمكن تخصيص سير العمل وفقًا لسياسات الشركة.
________________________________________
GP-001 Progressive Data Entry
Purpose
يسمح النظام بإنشاء ملف الاستيراد حتى فى حالة عدم اكتمال جميع البيانات، مع استكمال البيانات تدريجيًا خلال مراحل العمل المختلفة.
Rules
•	لا يشترط اكتمال جميع الحقول عند إنشاء ملف الاستيراد. 
•	يتم إدخال البيانات حسب المستندات المتوفرة فى كل مرحلة. 
•	لا يمنع النظام حفظ البيانات بسبب حقول غير مطلوبة فى المرحلة الحالية. 
•	يمنع النظام فقط تنفيذ العمليات التى تعتمد على بيانات غير مكتملة. 
Example
يمكن إنشاء Packing List بدون:
•	Length 
•	Width 
•	Height 
•	Unit Price 
ولكن لا يمكن تنفيذ Calculate CBM قبل استكمال الأبعاد.
________________________________________
GP-002 Stage-Based Validation
Purpose
تطبيق التحقق من صحة البيانات بناءً على المرحلة الحالية وليس عند إدخال البيانات فقط.
Rules
•	لكل عملية متطلبات خاصة بها. 
•	يتم التحقق من البيانات عند تنفيذ العملية. 
•	لا يتم إجبار المستخدم على إدخال بيانات غير مطلوبة فى المرحلة الحالية. 
________________________________________
GP-003 Editable Import Files
Purpose
السماح بتعديل ملفات الاستيراد طوال دورة العمل مع الاحتفاظ بسجل كامل لجميع التعديلات لضمان المرونة وإمكانية المراجعة.
Rules
•	يمكن فتح أى Import File فى أى وقت. 
•	يمكن تعديل البيانات طالما أن الملف لم يتم إغلاقه (Closed). 
•	يسمح بتعديل بيانات الفاتورة أو الباكينج ليست أو بيانات الشحنة عند استلام مستندات محدثة من المورد. 
•	لا يتم حذف البيانات السابقة، وإنما يتم تسجيل عملية التعديل. 
•	يجب أن يحتفظ النظام بآخر نسخة من البيانات مع إمكانية معرفة أن الملف تم تعديله. 
Audit Information
يعرض النظام دائمًا معلومات آخر تعديل داخل كل ملف:
Field	Description
Last Modified By	آخر مستخدم قام بالتعديل
Last Modified Date	تاريخ ووقت آخر تعديل
Version Number	رقم الإصدار (اختيارى إذا تم تطبيق نظام الإصدارات)
Modification Notes	سبب التعديل (اختيارى أو إلزامى حسب نوع التعديل)
________________________________________
GP-004 Audit Trail
Purpose
توفير سجل تاريخى لجميع العمليات التى تمت على ملف الاستيراد.
Rules
يقوم النظام بتسجيل جميع الأحداث المهمة مثل:
•	إنشاء الملف. 
•	تعديل البيانات. 
•	اعتماد المستندات. 
•	تغيير حالة العملية. 
•	إضافة أو حذف بنود. 
•	رفع مستند جديد. 
•	اعتماد أو رفض مستند. 
•	إغلاق ملف الاستيراد. 
ويحتوى كل سجل على:
•	التاريخ والوقت. 
•	المستخدم. 
•	نوع العملية. 
•	اسم الشاشة أو العملية. 
وصف مختصر للتغيير.

Master Data Specification
MD-001 Company (Egyptian Importers)
1. Purpose
يستخدم هذا الجدول لإدارة جميع الشركات المصرية التي يتم الاستيراد باسمها.
يسمح النظام بإدارة أكثر من شركة داخل نفس قاعدة البيانات، حيث تمتلك كل شركة بياناتها القانونية ومستنداتها الخاصة.
يعتبر هذا الجدول المرجع الرئيسي (Master Data) لجميع عمليات الاستيراد، ولا يمكن إنشاء أي مشروع أو ملف استيراد بدون اختيار شركة.
________________________________________
2. Business Objective
الغرض من هذا الجدول هو:
•	تخزين البيانات القانونية للشركات. 
•	متابعة صلاحية المستندات الرسمية. 
•	إعادة استخدام بيانات الشركة داخل جميع أجزاء النظام. 
•	منع إدخال نفس البيانات فى كل عملية استيراد. 
•	تقليل الأخطاء الناتجة عن الإدخال اليدوي. 
________________________________________
3. System Usage
يستخدم النظام بيانات هذا الجدول فى العمليات التالية:
•	إنشاء Project جديد. 
•	إنشاء Import File. 
•	إنشاء طلب ACID. 
•	تجهيز المراسلات الرسمية. 
•	إنشاء النماذج الحكومية. 
•	تعبئة بيانات المستورد تلقائياً داخل المستندات. 
•	متابعة انتهاء المستندات القانونية وإظهار التنبيهات. 
________________________________________
4. Main Fields


Egyptian Importer Name	Text	
Address	Text	
Country	Text	
Foreign Exporter Registration Type	Text	
Importer ID	Num	
Importer ID Expiration date	Date	
Importer ID days to renew	Num	TODAYS-Importer ID Expiration date
VAT ID	Num	
VAT ID Expiration date	Date	
VAT ID days to renew	Num	TODAYS-VAT ID Expiration date
Reg. no	Num	
Reg. no Expiration date	Date	
Reg. no days to renew	Num	TODAYS-Reg. no days to renew

Field	Type	Required	Description
Company ID	Auto Number	Yes	Primary Key
Egyptian Importer Name	Text	Yes	Legal Company Name
Address	Text	Yes	Registered Address
Country	Text	Yes	Country
Importer ID	Text	Yes	Import License Number
Importer ID Expiration Date	Date	Yes	License Expiry Date
VAT ID	Text	Yes	Tax Registration Number
VAT ID Expiration Date	Date	Yes	Tax Registration Expiry
Commercial Registration No	Text	Yes	Commercial Registration
Commercial Registration Expiration Date	Date	Yes	Registration Expiry
________________________________________
5. Business Rules
•	لا يسمح بإنشاء Import File بدون اختيار شركة. 
•	لا يسمح بحذف شركة مرتبطة بمشروعات أو ملفات استيراد. 
•	يجب أن تكون بيانات الشركة مطابقة للمستندات الرسمية. 
•	النظام يحسب عدد الأيام المتبقية لانتهاء كل مستند تلقائياً. 
•	إذا انتهى أحد المستندات القانونية يتم إصدار تنبيه. 
•	يمكن تعطيل الشركة (Inactive) دون حذفها من النظام. 
________________________________________
6. Relationships
Company
→ Projects
→ Import Files
→ ACID Requests
→ Official Documents
________________________________________
7. Notes for Developer
•	لا تقم بحفظ حقول "Days to Renew" داخل قاعدة البيانات، بل يتم حسابها ديناميكياً. 
•	استخدم Soft Delete بدلاً من الحذف النهائي. 
•	جميع الحقول القانونية يجب أن تدعم البحث (Searchable). 
________________________________________
MD-002 Supplier

Vendor  Company Name 	Registration Type	Foreign Exporter ID	Foreign Exporter Country	Foreign Exporter Country Code	Address	Phone Number	E-Mail	Brands
Text	Text	Text	Text	Text	Text	Text	Text	Text

Purpose
يستخدم هذا الجدول لتخزين جميع بيانات الموردين الأجانب (Foreign Exporters).
تستخدم هذه البيانات فى جميع عمليات الاستيراد لتجنب إعادة إدخال بيانات المورد فى كل شحنة.
________________________________________
Business Objective
•	إنشاء قاعدة بيانات موحدة للموردين. 
•	ضمان تطابق بيانات المورد مع المستندات الرسمية. 
•	إعادة استخدام البيانات فى جميع مراحل النظام. 
•	تقليل أخطاء الإدخال اليدوي. 
________________________________________
System Usage
يتم استخدام بيانات المورد فى:
•	إنشاء Project. 
•	إنشاء Import File. 
•	إصدار ACID. 
•	إنشاء مستندات CargoX. 
•	تجهيز الفواتير. 
•	تجهيز المستندات الجمركية. 
•	تعبئة بيانات المصدر فى جميع المراسلات. 
________________________________________
Important Note
يجب أن تكون بيانات المورد مطابقة تماماً للمستندات الرسمية.
أى اختلاف فى:
•	Registration Type 
•	Foreign Exporter ID 
•	Country Code 
•	Company Name 
قد يؤدى إلى رفض طلب ACID أو تأخير إجراءات التخليص الجمركى.
لهذا السبب تعتبر بيانات المورد بيانات قانونية (Legal Master Data) ويجب مراجعتها بدقة قبل استخدامها.
________________________________________
Business Rules
•	لا يسمح بتكرار المورد بنفس Registration Type و Foreign Exporter ID. 
•	لا يسمح بحذف مورد مرتبط بأى Import File. 
•	يمكن تعديل بيانات المورد مع الاحتفاظ بسجل التعديلات (Audit Log). 
________________________________________

MD-003 External Service Providers

Purpose
يستخدم هذا الجدول لإدارة جميع مقدمى الخدمات الخارجيين الذين يشاركون فى دورة الاستيراد.
بدلاً من إنشاء جدول مستقل لكل نوع من مقدمى الخدمة، يتم تخزين جميع الشركات داخل جدول واحد مع تحديد نوع الخدمة التى تقدمها.
يسمح هذا التصميم بإضافة أنواع جديدة من مقدمى الخدمات مستقبلاً دون الحاجة إلى تعديل قاعدة البيانات.
________________________________________
Business Objective
•	إنشاء قاعدة بيانات موحدة لجميع مقدمى الخدمات. 
•	إعادة استخدام بيانات الشركات فى جميع الشحنات. 
•	منع تكرار إدخال نفس البيانات. 
•	تسهيل عمليات البحث والتقارير. 
•	إمكانية إضافة أنواع خدمات جديدة مستقبلاً. 
________________________________________
System Usage
يستخدم هذا الجدول فى:
•	اختيار Freight Forwarder للشحنة. 
•	اختيار Customs Broker. 
•	اختيار Inspection Company (عند الحاجة). 
•	متابعة بيانات الاتصال. 
•	إصدار طلبات عروض الأسعار. 
•	إنشاء تقارير الأداء لكل مقدم خدمة. 
________________________________________
Supported Partner Types
•	Freight Forwarder 
•	Customs Broker 
•	Inspection Company 
•	Insurance Company 
•	Courier Company 
•	Shipping Agent 
•	Trucking Company 
________________________________________
Main Fields
Field	Type	Required	Notes
Partner ID	Auto Number	Yes	Primary Key
Partner Name	Text	Yes	Company Legal Name
Partner Type	Lookup	Yes	Freight Forwarder / Customs Broker / Inspection ...
Contact Person	Text	No	Main Contact
Phone Number	Text	No	
Mobile Number	Text	No	
Email	Text	No	
Address	Text	No	
Country	Lookup	No	
Payment Type	Lookup	No	Cash / Credit
Credit Limit	Decimal	No	
Notes	Long Text	No	
Status	Lookup	Yes	Active / Inactive
________________________________________
Relationships
External Service Provider
↓
Shipping Quotations
↓
Import Files
↓
Financial Requests
↓
Performance Reports
________________________________________
Business Rules
•	كل شحنة يجب أن تحتوي على Freight Forwarder. 
•	كل شحنة يجب أن تحتوي على Customs Broker. 
•	شركة الفحص اختيارية حسب نوع الشحنة. 
•	لا يسمح بحذف مقدم خدمة مرتبط بشحنات سابقة. 
•	يمكن تعطيل مقدم الخدمة دون حذف بياناته. 
________________________________________
Validation
•	Partner Name يجب أن يكون فريداً داخل نفس Partner Type. 
•	Email إن وجد يجب أن يكون بصيغة صحيحة. 
•	Credit Limit يجب ألا يكون أقل من صفر. 
________________________________________
Edge Cases
•	بعض الشحنات لا تحتاج Inspection Company. 
•	يمكن أن تكون نفس الشركة Freight Forwarder و Customs Broker فى نفس الوقت. 
________________________________________
Notes for Developer
•	استخدم Lookup Table منفصل لـ Partner Types. 
•	استخدم Soft Delete. 
________________________________________
MD-004 Shipping Lines
Purpose
يستخدم هذا الجدول كمرجع لجميع الخطوط الملاحية المستخدمة فى النظام.
________________________________________
Business Objective
•	توحيد أسماء الخطوط الملاحية. 
•	منع اختلاف كتابة نفس الخط. 
•	دعم البحث والتقارير. 
________________________________________
System Usage
•	Shipping Quotations 
•	Booking 
•	Shipment Tracking 
•	Transit Time Reports 
________________________________________
Main Fields
Field	Type	Required	Notes
Shipping Line ID	Auto Number	Yes	Primary Key
Shipping Line Name	Text	Yes	
SCAC Code	Text	No	إذا كان متاحاً
Country	Lookup	No	
Website	Text	No	
Status	Lookup	Yes	Active / Inactive
________________________________________
Relationships
Shipping Line
↓
Shipping Quotations
↓
Bookings
↓
Import Files
________________________________________
Business Rules
•	لا يسمح بتكرار اسم الخط. 
•	لا يسمح بحذف خط مستخدم فى شحنات سابقة. 
________________________________________
Validation
•	Shipping Line Name Required. 
•	SCAC Code اختياري. 
________________________________________
Edge Cases
•	بعض الخطوط تعمل كشركات تشغيل فقط وليس لديها موقع إلكترونى. 
________________________________________
Notes for Developer
•	يدعم البحث (Autocomplete). 
________________________________________
MD-005 Currency
Purpose
يستخدم كمرجع لجميع العملات المستخدمة داخل النظام.
________________________________________
Business Objective
•	توحيد العملات. 
•	منع كتابة العملات يدوياً. 
•	دعم الحسابات المالية. 
________________________________________
System Usage
•	PI 
•	Final Invoice 
•	Freight Quotations 
•	Customs Estimate 
•	Supplier Invoice 
•	Service Provider Invoice 
________________________________________
Main Fields
Field	Type	Required	Notes
Currency ID	Auto Number	Yes	
ISO Code	Text	Yes	USD / EUR / EGP
Currency Name	Text	Yes	
Symbol	Text	No	$, €, £
Decimal Places	Number	Yes	غالباً 2
Status	Lookup	Yes	Active / Inactive
________________________________________
Relationships
Currency
↓
Invoices
↓
Shipping Quotations
↓
Payment Requests
________________________________________
Business Rules
•	لا يسمح بتكرار ISO Code. 
•	لا يسمح بحذف عملة مستخدمة. 
________________________________________
Validation
ISO Code يجب أن يتكون من 3 أحرف.
________________________________________
Edge Cases
قد توجد شحنات تحتوي على أكثر من عملة.
________________________________________
Notes for Developer
جميع القيم المالية تشير إلى Currency ID وليس إلى النص.
________________________________________
MD-006 – Incoterm Master
Purpose
يمثل هذا الجدول المرجعي جميع قواعد Incoterms المعتمدة داخل النظام وفقًا لإصدار Incoterms 2020، ويستخدم كمرجع موحد لتحديد شروط التجارة الدولية بين المستورد والمصدر، دون تخزين تفاصيل المسؤوليات أو بنود التكلفة داخل نفس الجدول.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف قواعد Incoterms داخل النظام. 
•	منع تكرار تعريف نفس الـ Incoterm. 
•	دعم عمليات إنشاء المشاريع وملفات الاستيراد. 
•	توفير مرجع موحد لجميع العمليات التشغيلية والمالية. 
•	تمكين تحديث إصدارات Incoterms مستقبلاً دون التأثير على البيانات التاريخية. 
________________________________________
System Usage
يستخدم هذا الجدول في:
•	Projects 
•	Import Files 
•	Shipping Cost Estimation 
•	Landed Cost Calculation 
•	Financial Analysis 
•	Reports 
________________________________________
Main Fields
Field	Type	Required	Description
Incoterm ID	Auto Number	Yes	Primary Key
Incoterm Code	Text	Yes	EXW / FOB / CIF
Incoterm Name	Text	Yes	Full Name
Version	Text	Yes	Incoterms 2020
Description	Long Text	No	Description
Status	Lookup	Yes	Active / Inactive
________________________________________
Business Rules
•	لا يسمح بتكرار Incoterm Code. 
•	لا يجوز حذف Incoterm مستخدم في معاملات سابقة. 
•	يمكن تعطيل الـ Incoterm دون حذفه. 
•	لا يحتوي هذا الجدول على بنود التكلفة أو المسؤوليات. 
________________________________________
MD-006A – Cost Item Master
Purpose
يمثل هذا الجدول المرجعي جميع بنود التكلفة المحتملة خلال دورة الاستيراد، ويستخدم كمرجع موحد لتصنيف جميع المصروفات المرتبطة بالشحن والتخليص الجمركي والخدمات اللوجستية.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	إنشاء قائمة موحدة لبنود التكلفة. 
•	منع تكرار تعريف نفس البند. 
•	دعم احتساب التكلفة المتوقعة والفعلية. 
•	دعم التقارير المالية وتحليل التكاليف. 
________________________________________
System Usage
يستخدم هذا الجدول في:
•	Shipping Cost Estimation 
•	Freight Quotations 
•	Customs Estimation 
•	Landed Cost 
•	Financial Reports 
________________________________________
Main Fields
Field	Type	Required	Description
Cost Item ID	Auto Number	Yes	Primary Key
Cost Item Code	Text	Yes	Unique Code
Cost Item Name	Text	Yes	Cost Name
Cost Category	Lookup	Yes	Freight / Customs / Port / Bank / Other
Description	Long Text	No	Description
Status	Lookup	Yes	Active / Inactive
________________________________________
Business Rules
•	لا يسمح بتكرار Cost Item. 
•	يمكن إضافة بنود تكلفة جديدة دون تعديل قاعدة البيانات. 
•	يستخدم كمرجع فقط ولا يحتوي على قيم مالية. 
________________________________________
MD-006B – Incoterm Responsibility
Purpose
يمثل هذا الجدول العلاقة بين Incoterms وبنود التكلفة، ويحدد الطرف المسؤول عن كل بند تكلفة وفقًا لقواعد التجارة الدولية، دون الحاجة إلى تخزين أعمدة ثابتة لكل Incoterm.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	تطبيق قواعد Incoterms بصورة مرنة. 
•	تحديد مسؤولية كل بند تكلفة. 
•	دعم احتساب التكلفة المتوقعة. 
•	تمكين إضافة بنود تكلفة جديدة دون تعديل هيكل قاعدة البيانات. 
________________________________________
System Usage
يستخدم هذا الجدول في:
•	Shipping Cost Estimation 
•	Landed Cost Calculation 
•	Cost Analysis 
Financial Reports 

Examples
•	Origin Trucking 
•	Export Clearance 
•	OTHC 
•	Ocean Freight 
•	Insurance 
•	Origin Inspection 
•	Documentation 
•	DTHC 
•	Customs Clearance 
•	Form 4 
•	Duties 
•	Storage 
•	Demurrage 
•	Port Congestion 
•	Compliance Fees 

________________________________________
Main Fields
Field	Type	Required	Description
Responsibility ID	Auto Number	Yes	Primary Key
Incoterm ID	FK	Yes	Incoterm
Cost Item ID	FK	Yes	Cost Item
Responsible Party	Lookup	Yes	Importer / Exporter / Shared
Included in Incoterm	Boolean	Yes	Included
Notes	Text	No	Notes
________________________________________
Business Rules
•	لا يسمح بتكرار نفس Cost Item لنفس Incoterm. 
•	يمكن عمل Override على مستوى الشحنة مع الاحتفاظ بالقيمة الأصلية. 
•	يعتمد النظام على البيانات (Data-Driven) وليس على أعمدة ثابتة. 
________________________________________
MD-009 – Transport Location Master
Purpose
يمثل هذا الجدول المرجعي جميع مواقع النقل المستخدمة في النظام، سواء كانت موانئ بحرية، أو مطارات، أو موانئ جافة، أو مستودعات حاويات داخلية (ICD)، أو محطات سكك حديدية، ويستخدم كمرجع موحد لجميع نقاط الانطلاق والوصول.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف جميع مواقع النقل. 
•	منع تكرار أسماء المنافذ. 
•	دعم جميع وسائل النقل الحالية والمستقبلية. 
•	استخدام نفس المرجع في جميع العمليات والمستندات. 
________________________________________
Supported Location Types
•	Sea Port 
•	Airport 
•	Dry Port 
•	Inland Container Depot (ICD) 
•	Rail Terminal 
•	Logistics Hub 
________________________________________
System Usage
يستخدم هذا الجدول في:
•	Import Files 
•	ACID 
•	Freight Quotations 
•	Booking 
•	Bill of Lading 
•	Air Waybill 
•	Shipment Tracking 
•	Customs Clearance 
________________________________________
Main Fields
Field	Type	Required	Description
Location ID	Auto Number	Yes	Primary Key
Location Name	Text	Yes	Name
UN/LOCODE	Text	Yes	International Code
Location Type	Lookup	Yes	Sea Port / Airport / ICD / etc.
Country	FK	Yes	Country
City	Text	Yes	City
Status	Lookup	Yes	Active / Inactive
________________________________________
Business Rules
•	لا يسمح بتكرار UN/LOCODE. 
•	لا يجوز حذف موقع مستخدم في معاملات سابقة. 
•	يمكن تعطيل الموقع دون حذفه. 
•	يستخدم نفس الجدول لجميع أنواع المنافذ.

________________________________________
Relationships
Incoterms
↓
Projects
↓
Import Files
↓
Shipping Cost Estimation
↓
Cost Analysis
↓
Financial Reports
________________________________________
Business Rules
•	كل مشروع يجب أن يحتوى على Incoterm واحد. 
•	لا يسمح بتكرار نفس Cost Item لنفس Incoterm. 
•	المسؤول عن بند التكلفة يجب أن يكون: 
o	Importer 
o	Exporter 
o	Shared 
________________________________________
Validation
•	Incoterm Code Unique. 
•	Cost Item Unique داخل نفس Incoterm. 
________________________________________
Edge Cases
•	قد يتفق الطرفان تعاقدياً على توزيع مختلف لبعض البنود، لذلك يجب أن يسمح النظام بعمل Override على مستوى الشحنة مع الاحتفاظ بالقيمة الأصلية الخاصة بالـ Incoterm. 
________________________________________
Notes for Developer
لا تعتمد على أعمدة Yes/No.
اعتمد على العلاقة بين:
•	Incoterms 
•	Cost Items 
•	Responsibilities 
حتى يصبح النظام قابلاً للتوسع دون تعديل هيكل قاعدة البيانات.
________________________________________
MD-007 Projects
Purpose
يمثل هذا الجدول نقطة البداية لكل عملية استيراد.
كل مشروع يحدد الإطار العام الذى سيتم تنفيذ عمليات الاستيراد داخله، ويربط بين الشركة المستوردة، المورد، نوع الاستيراد، والأولوية.
________________________________________
Business Objective
•	تجميع الشحنات تحت مشروع واحد. 
•	ربط العمليات بالمورد والشركة. 
•	تسهيل متابعة الأداء والتكاليف على مستوى المشروع. 
________________________________________
Main Fields
Field	Type	Required	Notes
Project ID	Auto Number	Yes	Primary Key
Project Code	Text	Yes	Unique
Project Name	Text	Yes	
Project Owner	Text	Yes	
Company ID	FK	Yes	Company
Supplier ID	FK	Yes	Supplier
Incoterm ID	FK	Yes	Incoterm
Import Type ID	FK	Yes	Import Type
Priority ID	FK	Yes	Priority
Shipment Category ID	FK	Yes	Shipment Category
Status	Lookup	Yes	Open / Closed / On Hold
Notes	Long Text	No	
________________________________________
Relationships
Project
↓
Import Files
↓
Purchase Orders
↓
Financial Requests
↓
Reports
________________________________________
Business Rules
•	لا يمكن إنشاء مشروع بدون Company وSupplier. 
•	كل مشروع يرتبط بـ Incoterm واحد كإعداد افتراضي، مع إمكانية تغييره على مستوى الشحنة إذا استدعت الحاجة. 
•	لا يسمح بحذف مشروع يحتوي على ملفات استيراد. 
•	يمكن إغلاق المشروع بعد انتهاء جميع الشحنات المرتبطة به. 
________________________________________
Validation
•	Project Code يجب أن يكون فريداً. 
•	جميع المفاتيح الخارجية (FK) يجب أن تشير إلى سجلات نشطة. 
________________________________________
Edge Cases
•	قد يحتوي المشروع على عدة ملفات استيراد (Import Files). 
•	قد يستخدم المشروع أكثر من عملة أو أكثر من شركة شحن، لكن تظل هوية المشروع ثابتة.
Import Business Process (As-Is Process)
Purpose
تهدف هذه الوثيقة إلى توثيق دورة العمل الحالية الخاصة بعمليات الاستيراد كما يتم تنفيذها داخل الشركة، دون إجراء أي تعديل أو تحسين على الإجراءات الحالية.
ستكون هذه الوثيقة المرجع الأساسي لفهم النظام قبل البدء في تصميم قاعدة البيانات أو واجهات المستخدم أو منطق النظام.
________________________________________
Business Objective
•	توثيق جميع خطوات دورة الاستيراد الفعلية. 
•	تحديد ترتيب العمليات والعلاقات بينها. 
•	تحديد جميع الجهات المشاركة في كل مرحلة. 
•	تحديد المستندات المستخدمة في كل عملية. 
•	تحديد نقاط اتخاذ القرار (Decision Points). 
•	تحديد المدخلات والمخرجات لكل خطوة. 
•	اكتشاف العمليات المتكررة والاعتمادات المتبادلة. 
•	تجهيز الأساس الذي سيتم بناء النظام عليه. 
________________________________________
Scope
تبدأ دورة العمل من:
استلام Purchase Order (PO)
وتنتهي عند:
إغلاق ملف الاستيراد بعد الانتهاء من جميع الإجراءات التشغيلية والمالية واستلام البضاعة بالمخزن.
________________________________________
Workflow Approach
سيتم شرح كل عملية داخل دورة الاستيراد بشكل مستقل، وسيتم توثيقها باستخدام القالب التالي:
________________________________________

MD-008 Customs Tariff (HS Code Master)
Purpose

يستخدم هذا الجدول لإدارة جميع البنود الجمركية (HS Codes) والتعريفة الجمركية الخاصة بكل بند، بحيث يكون المرجع الأساسي لحساب الرسوم والضرائب ومتطلبات الاستيراد، دون الحاجة لإدخال هذه البيانات مع كل شحنة.

Business Objective
إنشاء قاعدة بيانات موحدة لجميع HS Codes.
تخزين التعريفة الجمركية لكل بند.
تخزين الضرائب والرسوم الحكومية.
تحديد الجهات الرقابية والموافقات المطلوبة.
دعم عملية Estimate Duties.
منع تكرار إدخال بيانات التعريفة.
System Usage

يستخدم هذا الجدول فى:

Review Proforma Invoice
Customs Consultation
Estimate Duties
Landed Cost Calculation
Cost Analysis
Customs Clearance
Financial Reports
Main Fields
Field	Type	Required	Description
Tariff ID	Auto Number	Yes	Primary Key
HS Code	Text	Yes	البند الجمركى
HS Description	Text	Yes	وصف البند
Customs Duty %	Decimal	Yes	نسبة الرسوم الجمركية
VAT %	Decimal	Yes	ضريبة القيمة المضافة
Development Tax %	Decimal	No	رسم التنمية
Additional Fees	Decimal	No	رسوم إضافية
Customs Category	Lookup	No	نوع البند
Requires COO	Boolean	No	شهادة منشأ
Requires Inspection	Boolean	No	شهادة فحص
Requires ACID	Boolean	Yes	يتطلب ACID
Regulatory Authority	Lookup	No	الجهات الرقابية
Notes	Long Text	No	ملاحظات
Status	Lookup	Yes	Active / Inactive
Relationships
Customs Tariff
        │
        ▼
Shipment Items
        │
        ▼
Estimate Duties
        │
        ▼
Customs Clearance
Business Rules
لا يسمح بتكرار HS Code.
يمكن ربط أكثر من جهة رقابية بنفس HS Code.
يحتفظ النظام بتاريخ تعديل التعريفة.
لا يتم حذف HS Code المستخدم فى شحنات سابقة.
يتم استخدام التعريفة السارية وقت إنشاء التقدير مع حفظ Snapshot داخل ملف الاستيراد.
MD-009 Ports & Airports
Purpose

يستخدم هذا الجدول كمرجع موحد لجميع الموانئ البحرية والمطارات المستخدمة فى عمليات الاستيراد والتصدير، لضمان توحيد أسماء المنافذ ومنع اختلاف طرق كتابتها داخل النظام.

Business Objective
توحيد أسماء الموانئ والمطارات.
دعم إنشاء ملفات الاستيراد.
استخدام نفس البيانات فى ACID وBooking وBL.
دعم البحث والتقارير.
منع الإدخال اليدوى لأسماء المنافذ.
System Usage

يستخدم هذا الجدول فى:

Import File
ACID
Booking
Freight Quotations
Bill of Lading
Shipment Tracking
Customs Clearance
Main Fields
Field	Type	Required	Description
Port ID	Auto Number	Yes	Primary Key
Port Name	Text	Yes	اسم المنفذ
UN/LOCODE	Text	Yes	الكود الدولى
Port Type	Lookup	Yes	Sea Port / Airport / Dry Port
Country	Lookup	Yes	الدولة
City	Text	Yes	المدينة
Status	Lookup	Yes	Active / Inactive
Notes	Long Text	No	ملاحظات
Relationships
Ports & Airports
        │
        ├──────── Import File
        ├──────── ACID
        ├──────── Freight Quotations
        ├──────── Booking
        ├──────── Bill of Lading
        └──────── Shipment Tracking
Business Rules
لا يسمح بتكرار UN/LOCODE.
لا يسمح بحذف منفذ مستخدم فى شحنات سابقة.
يسمح بتعطيل المنفذ دون حذفه.
يستخدم النظام اسم المنفذ والكود الدولى فى جميع المستندات الرسمية.
Validation
Port Name مطلوب.
Country مطلوب.
Port Type مطلوب.
UN/LOCODE يجب أن يكون فريدًا.
اقتراح إضافى

بدلاً من إنشاء جدولين منفصلين للموانئ والمطارات، أنصح باستخدام جدول واحد باسم Transport Locations، بحيث يحتوى على جميع أنواع المنافذ:

Sea Port
Airport
Dry Port
Inland Container Depot (ICD)
Rail Terminal

بهذا يصبح النظام أكثر مرونة، وإذا احتجت مستقبلاً لإضافة منفذ جديد (مثل ميناء جاف أو محطة سكة حديد)، فلن تحتاج إلى تعديل قاعدة البيانات أو الكود، بل يكفى إضافة نوع جديد إلى جدول Location Type. وهذا يتماشى مع فلسفة التصميم المرنة (Data-Driven) التى اعتمدتها فى باقى الـ Master Data.
MD-010 – Container Type Master
Purpose
يمثل هذا الجدول المرجعي تصنيف أنواع الحاويات المستخدمة داخل النظام، ويستخدم لتوحيد أسماء وأنواع الحاويات دون تخزين المواصفات الفنية أو الأبعاد.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف أنواع الحاويات. 
•	منع تكرار التصنيفات. 
•	دعم تخطيط التحميل والتسعير. 
•	تسهيل إضافة أنواع جديدة. 
________________________________________
Main Fields
Field	Type	Required	Description
Container Type ID	Auto Number	Yes	Primary Key
Container Code	Text	Yes	20GP / 40HC
Container Name	Text	Yes	Description
ISO Code	Text	No	ISO Container Code
Status	Lookup	Yes	Active / Inactive
________________________________________
Business Rules
•	لا يسمح بتكرار نوع الحاوية. 
•	لا يحتوي هذا الجدول على الأبعاد أو الأوزان. 
________________________________________
MD-011 – Container Specification Master
Purpose
يمثل هذا الجدول المرجعي المواصفات الفنية لأنواع الحاويات، ويستخدم لتخزين الأبعاد الداخلية والخارجية، والأوزان، والسعة الحجمية، والقيود التشغيلية، ويستند إلى Container Type Master.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	تخزين المواصفات الفنية للحاويات. 
•	دعم عمليات تخطيط التحميل. 
•	دعم احتساب السعة والوزن. 
•	توفير مرجع موحد لجميع الحسابات اللوجستية. 
________________________________________
System Usage
يستخدم هذا الجدول في:
•	BP-005 – Plan Cargo Loading 
•	Freight Rate Management 
•	Capacity Validation 
•	Loading Validation 
________________________________________
Main Fields
Field	Type	Required	Description
Specification ID	Auto Number	Yes	Primary Key
Container Type ID	FK	Yes	Container Type
Internal Length	Decimal	Yes	Internal Length
Internal Width	Decimal	Yes	Internal Width
Internal Height	Decimal	Yes	Internal Height
Door Width	Decimal	No	Door Width
Door Height	Decimal	No	Door Height
Internal Volume (CBM)	Decimal	Yes	Capacity
Tare Weight	Decimal	Yes	Empty Weight
Maximum Payload	Decimal	Yes	Maximum Cargo Weight
Maximum Gross Weight	Decimal	Yes	Maximum Total Weight
Supports Stacking	Boolean	No	Stacking Support
Status	Lookup	Yes	Active / Inactive
________________________________________
Business Rules
•	ترتبط كل مواصفة بنوع حاوية واحد. 
•	يمكن الاحتفاظ بأكثر من إصدار للمواصفات عند الحاجة. 
•	تعتمد جميع عمليات تخطيط التحميل على هذا الجدول. 
•	لا يجوز تعديل المواصفات القياسية المستخدمة تاريخيًا، ويُفضل إنشاء إصدار جديد عند تغييرها. 
________________________________________
النتيجة المعمارية
بعد هذه التعديلات تصبح طبقة Master Data أكثر تنظيمًا، بحيث يكون لكل جدول مسؤولية واحدة فقط:
________________________________________
MD-012 – Package Type
Purpose
تعريف أنواع الطرود.
Business Objective
•	توحيد تصنيف العبوات.
System Usage
•	Carton
•	Pallet
•	Crate
•	Drum
•	Bag
Business Rules
•	يستخدم فى جميع الشحنات.
Validation
•	Unique Package Type
Edge Cases
•	Custom Package Types
Deliverables
•	Package Type Master
Notes for Developer
•	ربطه بقيود التحميل.
________________________________________
MD-013 – Handling Instruction
Purpose
تعريف تعليمات المناولة.
Business Objective
•	تطبيق قواعد السلامة.
System Usage
•	Fragile
•	Keep Dry
•	Do Not Tilt
•	This Side Up
Business Rules
•	يسمح بربط عدة تعليمات بالطرد.
Validation
•	Active Instruction Only
Edge Cases
•	تعليمات متعارضة.
Deliverables
•	Handling Instruction Master
Notes for Developer
•	Many-to-Many مع Package.
________________________________________
MD-014 – Loading Constraint
Purpose
إدارة قيود التحميل.
Business Objective
•	فرض متطلبات التحميل الخاصة.
System Usage
•	Dangerous Goods
•	Temperature Controlled
•	Non Stackable
Business Rules
•	تطبق أثناء التخطيط والتحقق.
Validation
•	Constraint Compatibility
Edge Cases
•	قيود متعددة لنفس الطرد.
Deliverables
•	Loading Constraint Master
Notes for Developer
•	يستخدم بواسطة Validation Engine.
MD-015 – Loading Strategy
Purpose
تعريف استراتيجيات التحميل المعتمدة داخل النظام والتي يتم استخدامها لتوجيه عملية تخطيط وتحسين تحميل البضائع وفقاً للأهداف التشغيلية والتجارية.
Business Objective
تهدف إلى:
1.	توحيد أساليب تخطيط التحميل.
2.	تحسين استغلال المساحة.
3.	تحسين استغلال الحمولة.
4.	تقليل تكلفة النقل.
5.	دعم اتخاذ القرار أثناء التخطيط.
6.	تحديد الاستراتيجية المناسبة حسب نوع الشحنة.
System Usage
يقوم النظام باستخدام استراتيجية التحميل في:
•	إنشاء سيناريوهات التحميل.
•	ترتيب البضائع داخل الحاويات.
•	المقارنة بين البدائل.
•	اختيار الخطة المثلى.
•	تشغيل محركات التحسين.
Inputs
•	Cargo Type
•	Cargo Dimensions
•	Cargo Weight
•	Container Type
•	Shipping Method
•	Loading Constraints
Possible Shipping Methods
•	Sea Freight
•	Air Freight
•	Land Freight
•	Multimodal Transport
Business Rules
1.	يجب اختيار استراتيجية تحميل واحدة على الأقل لكل خطة تحميل.
2.	يمكن تغيير الاستراتيجية قبل اعتماد الخطة.
3.	يتم تسجيل الاستراتيجية المستخدمة ضمن الخطة المعتمدة.
4.	يمكن إضافة استراتيجيات جديدة مستقبلاً.
Validation
•	Unique Strategy Code
•	Mandatory Strategy Name
•	Active Status Validation
Edge Cases
•	تعارض أكثر من استراتيجية.
•	اختلاف نتائج التقييم بين الاستراتيجيات.
•	عدم وجود استراتيجية مناسبة لنوع الشحنة.
Deliverables
•	Loading Strategy Master
•	Strategy Assignment Reference
Notes for Developer
•	يفضل تصميم الاستراتيجيات بشكل Configurable.
•	يجب دعم إضافة Optimization Strategies مستقبلاً.
•	يمكن ربط الاستراتيجية بخوارزميات مختلفة داخل Calculation Engine.
________________________________________
MD-016 – Validation Rule
Purpose
تعريف جميع قواعد التحقق المستخدمة أثناء تقييم خطط التحميل لضمان الالتزام بالقيود التشغيلية والفنية.
Business Objective
تهدف إلى:
1.	منع اعتماد خطط غير قابلة للتنفيذ.
2.	توحيد معايير التحقق.
3.	تقليل الأخطاء التشغيلية.
4.	زيادة موثوقية نتائج التخطيط.
5.	دعم الامتثال لمتطلبات السلامة.
System Usage
يقوم النظام باستخدام قواعد التحقق في:
•	Validation Engine
•	Loading Plan Validation
•	Cargo Assessment
•	Container Assessment
•	Decision Support
Inputs
•	Loading Plan
•	Loading Scenario
•	Container Specification
•	Cargo Information
•	Loading Constraints
Possible Shipping Methods
•	Sea Freight
•	Air Freight
•	Land Freight
•	Rail Freight
Business Rules
1.	جميع قواعد التحقق تتم إدارتها مركزياً.
2.	يسمح بإضافة أو تعطيل القواعد دون تعديل النظام.
3.	يمكن تصنيف القواعد إلى Warning أو Blocking.
4.	لا يمكن اعتماد خطة تفشل في قواعد Blocking Validation.
Validation
•	Unique Rule Code
•	Rule Category Mandatory
•	Rule Status Validation
•	Duplicate Rule Validation
Edge Cases
•	تعارض أكثر من قاعدة.
•	تغيير قواعد التحقق بعد اعتماد الخطة.
•	وجود استثناءات تشغيلية لبعض العملاء.
Deliverables
•	Validation Rule Master
•	Validation Configuration
Notes for Developer
•	يفضل تنفيذ القواعد باستخدام Rule Engine.
•	دعم Versioning لقواعد التحقق.
•	تخزين نتائج التحقق للرجوع إليها تاريخياً.
________________________________________
MD-017 – Decision Status
Purpose
تعريف الحالات القياسية الناتجة عن تقييم خطط التحميل وقرارات النظام.
Business Objective
تهدف إلى:
1.	توحيد نتائج التقييم.
2.	تسهيل اتخاذ القرار.
3.	دعم التقارير ولوحات المعلومات.
4.	توحيد حالات سير العمل.
System Usage
يستخدم النظام الحالات في:
•	Loading Validation
•	Workflow Management
•	Dashboard KPIs
•	Notifications
•	Reporting
Inputs
•	Validation Results
•	Scenario Evaluation Results
•	Business Rules
Possible Shipping Methods
•	Sea Freight
•	Air Freight
•	Land Freight
•	Rail Freight
Business Rules
1.	يتم اختيار الحالة تلقائياً بواسطة النظام.
2.	يمكن لبعض الحالات أن تتطلب موافقة يدوية.
3.	لا يسمح بتعديل الحالات القياسية إلا بواسطة المسؤولين.
Validation
•	Unique Status Code
•	Active Status Check
•	Duplicate Status Validation
Edge Cases
•	وجود أكثر من حالة لنفس الخطة.
•	تعارض نتائج التقييم.
•	انتقال الخطة بين أكثر من حالة خلال دورة حياتها.
Deliverables
•	Decision Status Master
•	Decision Reference List
Notes for Developer
أمثلة للحالات:
•	Fit
•	Partial Fit
•	Overweight
•	Oversized
•	Rejected
•	Approved
•	Manual Review Required
يجب أن يدعم النظام إضافة حالات جديدة مستقبلاً دون إعادة تطوير.
________________________________________
MD-018 – Unit Of Measure
Purpose
إدارة جميع وحدات القياس المستخدمة داخل النظام لضمان توحيد الحسابات والعمليات التشغيلية.
Business Objective
تهدف إلى:
1.	توحيد القياسات.
2.	منع أخطاء التحويل.
3.	دعم العمليات الدولية.
4.	توحيد الحسابات والتقارير.
System Usage
تستخدم وحدات القياس في:
•	إدخال البيانات.
•	الحسابات.
•	التقارير.
•	الاستيراد والتصدير.
•	التحويل بين الوحدات.
Inputs
•	Measurement Type
•	Unit Name
•	Conversion Factor
•	Unit Category
Possible Shipping Methods
•	Sea Freight
•	Air Freight
•	Land Freight
•	Rail Freight
Business Rules
1.	كل وحدة تنتمي إلى فئة قياس محددة.
2.	يجب تحديد وحدة قياس افتراضية لكل فئة.
3.	يتم إجراء التحويلات باستخدام عوامل التحويل المعتمدة.
4.	لا يسمح بحذف وحدة مستخدمة في بيانات تشغيلية.
Validation
•	Unique Unit Code
•	Valid Conversion Factor
•	Mandatory Measurement Category
Edge Cases
•	اختلاف وحدات البيانات الموردة من العملاء.
•	اختلاف الأنظمة المترية والإمبريالية.
•	أخطاء التحويل الناتجة عن بيانات غير صحيحة.
Deliverables
•	Unit Of Measure Master
•	Conversion Reference Table
Notes for Developer
أمثلة:
Weight
•	KG
•	Ton
•	LB
Length
•	MM
•	CM
•	M
•	FT
Volume
•	CBM
•	CFT
يجب أن يدعم النظام التحويل التلقائي بين الوحدات.
________________________________________
MD-019 – Calculation Formula
Purpose
إدارة وتوثيق المعادلات الحسابية المستخدمة في عمليات التخطيط والتحقق والتحليل داخل النظام.
Business Objective
تهدف إلى:
1.	توحيد العمليات الحسابية.
2.	تقليل الأخطاء اليدوية.
3.	دعم الشفافية في النتائج.
4.	تبسيط صيانة المعادلات وتطويرها.
System Usage
تستخدم المعادلات في:
•	Calculation Engine
•	Container Utilization
•	Payload Analysis
•	Cost Estimation
•	Scenario Evaluation
Inputs
•	Formula Definition
•	Formula Type
•	Variables
•	Measurement Units
Possible Shipping Methods
•	Sea Freight
•	Air Freight
•	Land Freight
•	Rail Freight
Business Rules
1.	جميع المعادلات تدار مركزياً.
2.	يتم استخدام المعادلات المعتمدة فقط.
3.	يمكن إصدار نسخ جديدة من المعادلات.
4.	يجب الاحتفاظ بالنسخ السابقة لأغراض المراجعة.
Validation
•	Unique Formula Code
•	Formula Syntax Validation
•	Variable Validation
•	Version Validation
Edge Cases
•	تغيير المعادلة بعد اعتماد خطة تحميل.
•	اختلاف وحدات الإدخال.
•	وجود معادلات بديلة لنفس الغرض.
Deliverables
•	Calculation Formula Master
•	Formula Version History
•	Formula Configuration Repository
Notes for Developer
أمثلة للمعادلات:
CBM Formula
Length × Width × Height × Quantity
Payload Utilization %
(Total Cargo Weight ÷ Maximum Payload) × 100
Space Utilization %
(Used Volume ÷ Container Capacity) × 100
Remaining Payload
Maximum Payload − Total Cargo Weight
يوصى بفصل Calculation Formula Master عن Calculation Engine بحيث يمكن تعديل المعادلات دون التأثير على تصميم النظام أو إعادة نشر التطبيق.
MD-020– Shipping Method Master
Purpose
يمثل هذا الجدول المرجعي جميع وسائل النقل التي يدعمها النظام، ويستخدم كمرجع موحد لتصنيف نوع وسيلة الشحن داخل جميع العمليات التشغيلية، دون تخزين أي بيانات تتعلق بالمسارات أو شركات الشحن أو الأسعار.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف وسائل النقل داخل النظام. 
•	منع تكرار تعريف وسائل الشحن. 
•	دعم عمليات اختيار وسيلة الشحن. 
•	توفير مرجع موحد للتقارير والتحليلات. 
________________________________________
System Usage
يستخدم في:
•	BP-006 – Determine Shipping Method 
•	BP-007 – Shipping Scenarios Evaluation 
•	BP-008 – Freight Quotation Management 
•	BP-016 – Shipment Booking Management 
________________________________________
Fields
Field	Description
Shipping Method Code	كود وسيلة الشحن
Shipping Method Name	اسم وسيلة الشحن
Transport Mode	Sea / Air / Road / Rail / Courier
Description	وصف وسيلة الشحن
Active	حالة التفعيل
________________________________________
Business Rules
•	لكل وسيلة شحن كود فريد. 
•	لا يجوز حذف وسيلة مستخدمة في معاملات سابقة. 
•	يمكن إيقاف الوسيلة دون حذفها. 
•	لا يحتوي هذا الجدول على بيانات المسارات أو الأسعار أو شركات الشحن. 
________________________________________
MD-021 – Service Level Master
Purpose
يمثل هذا الجدول المرجعي مستويات الخدمة التي يمكن تطبيقها على عمليات الشحن، ويستخدم كمرجع موحد لتحديد مستوى الخدمة المطلوب بغض النظر عن وسيلة النقل أو شركة الشحن.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف مستويات الخدمة. 
•	دعم المقارنة بين البدائل التشغيلية. 
•	دعم التقارير وتحليل الأداء. 
•	تمكين إضافة مستويات خدمة جديدة دون تعديل النظام. 
________________________________________
System Usage
يستخدم في:
•	BP-006 – Determine Shipping Method 
•	BP-007 – Shipping Scenarios Evaluation 
•	MD-015 – Carrier Service Master 
•	MD-018 – Freight Rate Master 
________________________________________
Fields
Field	Description
Service Level Code	كود مستوى الخدمة
Service Level Name	اسم مستوى الخدمة
Description	وصف مستوى الخدمة
Priority Level	مستوى الأولوية
Active	حالة التفعيل
________________________________________
Business Rules
•	لكل مستوى خدمة كود فريد. 
•	لا يرتبط هذا الجدول مباشرة بأي وسيلة شحن أو شركة شحن. 
•	يمنع إدخال مستويات الخدمة داخل المعاملات التشغيلية. 
________________________________________
MD-022 – Shipping Route Master
Purpose
يمثل هذا الجدول المرجعي جميع مسارات الشحن المعتمدة داخل النظام، ويستخدم لتعريف نقاط الانطلاق والوصول فقط، دون ربطها بوسيلة النقل أو شركة الشحن.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	توحيد تعريف المسارات. 
•	منع تكرار تعريف نفس المسار. 
•	دعم عمليات التسعير والتقارير. 
•	تسهيل إضافة مسارات جديدة. 
________________________________________
System Usage
يستخدم في:
•	MD-015 – Carrier Service Master 
•	MD-018 – Freight Rate Master 
•	التقارير التشغيلية 
________________________________________
Fields
Field	Description
Route Code	كود المسار
Origin Country	دولة الانطلاق
Origin Port / Airport	ميناء أو مطار المغادرة
Destination Country	دولة الوصول
Destination Port / Airport	ميناء أو مطار الوصول
Default Transit Time	مدة النقل القياسية
Active	حالة التفعيل
________________________________________
Business Rules
•	لكل مسار كود فريد. 
•	يمنع تكرار نفس المسار. 
•	لا يرتبط هذا الجدول بوسيلة النقل أو شركة الشحن. 
________________________________________
MD-023 – Carrier Service Master
Purpose
يمثل هذا الجدول المرجعي الخدمات التشغيلية التي تقدمها شركات الشحن، من خلال ربط شركة الشحن بمسار الشحن ومستوى الخدمة، ويستخدم كمرجع موحد للخدمات المتاحة دون احتواء أي بيانات تعاقدية أو أسعار.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	تعريف الخدمات التي يقدمها كل ناقل. 
•	ربط الخدمة بالمسار ومستوى الخدمة. 
•	دعم عمليات طلب عروض الأسعار. 
•	دعم الحجز واختيار الخدمة المناسبة. 
________________________________________
System Usage
يستخدم في:
•	BP-007 – Shipping Scenarios Evaluation 
•	BP-008 – Freight Quotation Management 
•	BP-016 – Shipment Booking Management 
•	MD-018 – Freight Rate Master 
________________________________________
Related Master Data
•	Carrier Master 
•	Shipping Route Master 
•	Service Level Master 
________________________________________
Fields
Field	Description
Carrier Service Code	كود الخدمة
Carrier	شركة الشحن
Shipping Route	المسار
Service Level	مستوى الخدمة
Transit Time	مدة النقل المتوقعة
Service Status	حالة الخدمة
Notes	ملاحظات
________________________________________
Business Rules
•	ترتبط كل خدمة بشركة شحن واحدة. 
•	ترتبط كل خدمة بمسار واحد. 
•	ترتبط كل خدمة بمستوى خدمة واحد. 
•	لا يحتوي هذا الجدول على بيانات العقود أو الأسعار. 
________________________________________
MD-024 – Carrier Master
Purpose
يمثل هذا الجدول المرجعي جميع شركات الشحن ومقدمي الخدمات اللوجستية المعتمدين داخل النظام، ويستخدم كمصدر موحد لبيانات الناقلين دون تخزين بيانات الخدمات أو العقود أو الأسعار.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	إنشاء سجل موحد لكل شركة شحن. 
•	دعم إدارة الناقلين. 
•	دعم عمليات الحجز والتقارير. 
•	تسهيل التكامل مع الأنظمة الخارجية. 
________________________________________
System Usage
يستخدم في:
•	MD-015 – Carrier Service Master 
•	MD-017 – Carrier Contract Master 
•	BP-016 – Shipment Booking Management 
________________________________________
Fields
Field	Description
Carrier Code	كود الشركة
Carrier Name	الاسم التجاري
Legal Name	الاسم القانوني
Carrier Type	نوع شركة الشحن
Country	الدولة
Contact Person	مسؤول التواصل
Email	البريد الإلكتروني
Phone	الهاتف
Website	الموقع الإلكتروني
Active	حالة التفعيل
________________________________________
Business Rules
•	لكل شركة كود فريد. 
•	يمنع حذف الشركات المستخدمة. 
•	لا يحتوي هذا الجدول على بيانات العقود أو الخدمات أو الأسعار. 
________________________________________
MD-025 – Carrier Contract Master
Purpose
يمثل هذا الجدول المرجعي العقود والاتفاقيات التجارية المبرمة مع شركات الشحن، ويستخدم لإدارة شروط التعاقد وفترات السريان دون تخزين بيانات الخدمات التشغيلية أو أسعار الشحن.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	إدارة العقود التجارية. 
•	متابعة صلاحية العقود. 
•	إدارة شروط الدفع. 
•	توفير مرجع للعقود المستخدمة في التسعير والحجز. 
________________________________________
System Usage
يستخدم في:
•	MD-018 – Freight Rate Master 
•	BP-008 – Freight Quotation Management 
•	BP-016 – Shipment Booking Management 
________________________________________
Related Master Data
•	Carrier Master 
•	Payment Terms Master 
•	Currency Master 
________________________________________
Fields
Field	Description
Contract Code	كود العقد
Carrier	شركة الشحن
Contract Name	اسم العقد
Effective Date	تاريخ البداية
Expiry Date	تاريخ الانتهاء
Currency	العملة
Payment Terms	شروط الدفع
Credit Period	فترة الائتمان
Contract Status	حالة العقد
Renewal Type	نوع التجديد
Notes	ملاحظات
________________________________________
Business Rules
•	يرتبط كل عقد بشركة شحن واحدة. 
•	لا يحتوي هذا الجدول على بيانات الخدمات أو الأسعار. 
•	يمكن وجود عدة عقود لنفس شركة الشحن. 
•	لا يجوز حذف العقود المستخدمة. 
________________________________________
MD-026 – Freight Rate Master
Purpose
يمثل هذا الجدول المرجعي تعريفات وأسعار الشحن المعتمدة، ويعد المرجع الرئيسي الذي يربط بين العقود والخدمات التشغيلية ووسيلة الشحن ونوع الحاوية أو أساس احتساب التكلفة، ويستخدم في عمليات طلب عروض الأسعار، والمقارنة، والحجز.
________________________________________
Business Objective
يهدف هذا الجدول إلى:
•	إدارة أسعار الشحن. 
•	دعم احتساب تكلفة الشحن. 
•	تطبيق الأسعار التعاقدية. 
•	دعم مقارنة عروض الأسعار. 
•	الاحتفاظ بالسجل التاريخي للأسعار. 
________________________________________
System Usage
يستخدم في:
•	BP-008 – Freight Quotation Management 
•	BP-015 – Freight Quotation Comparison 
•	BP-016 – Shipment Booking Management 
________________________________________
Related Master Data
•	Carrier Contract Master 
•	Carrier Service Master 
•	Shipping Method Master 
•	Container Type Master 
•	Charge Basis Master 
•	Currency Master 
________________________________________
Fields
Field	Description
Freight Rate Code	كود التعريفة
Carrier Contract	العقد
Carrier Service	الخدمة
Shipping Method	وسيلة الشحن
Container Type	نوع الحاوية (اختياري حسب وسيلة النقل)
Charge Basis	أساس احتساب التكلفة (CBM، KG، Container، Shipment...)
Currency	العملة
Unit Rate	سعر الوحدة
Minimum Charge	الحد الأدنى
Maximum Charge	الحد الأقصى (اختياري)
Valid From	تاريخ بداية السريان
Valid To	تاريخ نهاية السريان
Active	حالة التفعيل
________________________________________
Business Rules
•	ترتبط كل تعريفة بعقد واحد وخدمة واحدة. 
•	يمكن أن توجد عدة تعريفات لنفس العقد حسب نوع الحاوية أو أساس الاحتساب أو فترة السريان. 
•	لا يجوز تداخل فترات السريان لنفس العقد والخدمة ونوع الحاوية وأساس الاحتساب. 
•	لا يجوز تعديل تعريفة مستخدمة في معاملة مكتملة؛ ويجب إنشاء إصدار جديد عند الحاجة. 
________________________________________
Architecture Overview
                     Carrier Master
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
     Carrier Contract          Carrier Service
              │                         │
              └────────────┬────────────┘
                           ▼
                  Freight Rate Master
                           ▲
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
 Shipping Method   Shipping Route   Service Level
Operation Template
Operation Name
اسم العملية.
________________________________________
Purpose
ما الهدف من هذه العملية؟
________________________________________
Trigger
ما الذي يبدأ هذه العملية؟
________________________________________
Prerequisites
ما المتطلبات التي يجب توفرها قبل تنفيذها؟
________________________________________
Inputs
ما البيانات أو المستندات المطلوبة لتنفيذ العملية؟
________________________________________
Process Description
شرح تفصيلي لما يحدث داخل هذه العملية خطوة بخطوة.
________________________________________
Outputs
ما النتائج أو المستندات الناتجة عن العملية؟
________________________________________
Related Documents
ما المستندات المستخدمة أو الناتجة؟
________________________________________
Related Master Data
ما الجداول المرجعية المستخدمة أثناء تنفيذ العملية؟
________________________________________
Business Rules
القواعد المنظمة لهذه العملية.
________________________________________
Validation
ما الذي يجب أن يتحقق منه النظام قبل اعتماد العملية؟
________________________________________
Exception Cases (Edge Cases)
الحالات غير المعتادة أو الاستثنائية وكيفية التعامل معها.
________________________________________
Dependencies
ما العمليات السابقة التي تعتمد عليها هذه العملية؟
وما العمليات التالية التي تعتمد عليها؟
________________________________________
Notifications
هل ينتج عن هذه العملية أي إشعارات أو تنبيهات؟
________________________________________
Dashboard Impact
كيف تؤثر هذه العملية على لوحة المتابعة؟
•	هل تغير المرحلة الحالية؟ 
•	هل تحدث مؤشرات الأداء (KPIs)؟ 
•	هل تنقل الشحنة إلى مرحلة جديدة؟ 
________________________________________
Notes for Developer
أي ملاحظات تقنية أو اعتبارات يجب مراعاتها عند تنفيذ هذه العملية داخل النظام.
________________________________________
Implementation Methodology
سيتم توثيق جميع عمليات الاستيراد بنفس الأسلوب وبالترتيب الفعلي لتنفيذها داخل الشركة، بدءًا من استلام أمر الشراء وحتى إغلاق ملف الاستيراد.
كل عملية سيتم تحليلها ومراجعتها بشكل مستقل قبل الانتقال إلى العملية التالية، لضمان أن يكون النظام النهائي مطابقًا لطريقة العمل الفعلية وقابلًا للتطوير والتوسع مستقبلاً.
Import Operations Workflow
Phase 1 – Import Planning & Feasibility
الهدف: دراسة عملية الاستيراد قبل اتخاذ قرار الشحن.
Code	Business Process
BP-001	Receive Purchase Order
BP-002	Review Proforma Invoice
BP-003	Review Packing List
BP-004	Calculate Cargo Volume (CBM) & Chargeable Weight
BP-005	Plan Cargo Loading
BP-006	Determine Shipping Method
BP-007	Evaluate Shipping Scenarios
BP-008	Manage Freight Quotations
BP-009	Consult Customs Broker
BP-010	Estimate Customs Duties & Taxes
BP-011	Assess Import Requirements
________________________________________
Phase 2 – Financial & Management Approval
الهدف: الحصول على الموافقات المالية والإدارية قبل بدء التنفيذ.
Code	Business Process
BP-012	Create Payment Request
BP-013	Approve Import Budget (New)
________________________________________
Phase 3 – Import Documentation
الهدف: إدارة جميع مستندات الشحنة منذ إصدارها وحتى اعتمادها.
Code	Business Process
BP-014	Manage Shipment Documents
BP-015	Request & Verify ACID
BP-016	Process Letter of Credit (L/C) or Form 4
________________________________________
Phase 4 – Freight Booking
الهدف: التعاقد مع شركة الشحن وحجز الشحنة.
Code	Business Process
BP-017	Select Freight Provider (New)
BP-018	Create Shipment Booking
BP-019	Confirm Shipment Booking (New)
________________________________________
Phase 5 – Cargo Preparation & Shipping
الهدف: تجهيز البضاعة للشحن حتى مغادرتها.
Code	Business Process
BP-020	Coordinate Cargo Readiness (New)
BP-021	Execute Cargo Loading
BP-022	Review & Approve Shipping Documents
BP-023	Collect Original Shipping Documents
BP-024	Exchange Electronic Shipping Documents
BP-025	Link Shipping Documents to ETMS
________________________________________
Phase 6 – Customs Clearance Preparation
الهدف: تجهيز جميع متطلبات التخليص الجمركى.
Code	Business Process
BP-026	Review Final Shipment Documents
BP-027	Prepare Customs Clearance (New)
BP-028	Submit Customs Declaration (New)
________________________________________
Phase 7 – Customs Clearance
الهدف: إنهاء الإجراءات الجمركية والإفراج عن الشحنة.
Code	Business Process
BP-029	Follow Up Customs Clearance
BP-030	Request Customs Duty Payment
BP-031	Record Customs Duty Payment (New)
BP-032	Complete Customs Release
________________________________________
Phase 8 – Warehouse Receiving
الهدف: استلام الشحنة داخل المخزن.
Code	Business Process
BP-033	Receive Goods at Warehouse
BP-034	Verify Received Quantities (New)
BP-035	Report Receiving Discrepancies (New)
________________________________________
Phase 9 – Financial Settlement
الهدف: تسجيل جميع التكاليف وإقفالها.
Code	Business Process
BP-036	Record Shipping Invoices
BP-037	Record Customs Invoices
BP-038	Allocate Import Costs (New)
BP-039	Calculate Final Landed Cost (New)
________________________________________
Phase 10 – Import File Closure
الهدف: مراجعة العملية بالكامل وإغلاق ملف الاستيراد.
Code	Business Process
BP-040	Close Import File


Phase 1 – Import Planning & Feasibility

BP-001 – Receive Purchase Order
Purpose
استلام أمر الشراء (Purchase Order) والـ Proforma Invoice من المورد، وإنشاء ملف استيراد جديد يمثل نقطة البداية لجميع عمليات الاستيراد داخل النظام.
________________________________________
Business Objective
•	إنشاء Import File جديد. 
•	تسجيل بيانات المورد والفاتورة المبدئية. 
•	تسجيل جميع أصناف الشحنة. 
•	مراجعة القيم الأساسية قبل بدء إجراءات الاستيراد. 
•	تجهيز البيانات اللازمة للمراحل التالية. 
________________________________________
System Usage
تستخدم هذه العملية فى:
•	إنشاء Import File. 
•	مراجعة Proforma Invoice. 
•	مراجعة Packing List. 
•	حساب CBM. 
•	تحديد طريقة الشحن. 
•	طلب عروض أسعار الشحن. 
•	حساب الرسوم الجمركية. 
•	إنشاء ACID. 
•	إصدار Form 4. 
________________________________________
Inputs
Header Information
Field	Type	Required	Notes
Egyptian Importer Name	Text	Yes	اسم الشركة المستوردة
Egyptian Importer Tax ID	Text	Yes	الرقم الضريبى
Foreign Exporter Name	Text	Yes	المورد
Registration Type	Lookup	Yes	Company / Individual
Foreign Exporter ID	Text	Yes	رقم التسجيل
Country	Lookup	Yes	دولة المورد
Country Code	Text	Yes	ISO Country Code
Address	Text	Yes	عنوان المورد
Proforma Invoice No	Text	Yes	رقم الفاتورة
Proforma Invoice Date	Date	Yes	
Invoice Date	Date	Yes	
Invoice Type	Lookup	Yes	PI / Sample / Replacement
Purchase Order No	Text	Yes	
Purchase Order Date	Date	Yes	
Shipping Port	Lookup	Yes	
Destination Port	Lookup	Yes	
________________________________________
Shipment Items
Field	Type	Required	Notes
HS Code	Text	Yes	
Item Code	Text	Yes	
Description	Text	No	
Quantity	Decimal	Yes	PCS
Unit Price	Decimal	Yes	
Amount	Calculated	Yes	Qty × Unit Price
________________________________________
Outputs
•	إنشاء Import File. 
•	حفظ بيانات Proforma Invoice. 
•	حفظ جميع الأصناف. 
•	حساب إجمالى قيمة الفاتورة. 
•	تجهيز البيانات للمراجعة. 
________________________________________
Business Rules
•	إجمالى Amount لكل سطر = Qty × Unit Price. 
•	إجمالى الفاتورة = مجموع جميع Amount. 
•	لا يسمح بتكرار نفس Item داخل نفس الفاتورة إلا إذا اختلفت بياناته الفعلية. 
•	يجب ربط كل Item بـ HS Code. 
•	لا يسمح بحفظ فاتورة بدون أصناف. 
________________________________________
Validation
•	مراجعة حاصل الضرب لكل سطر. 
•	مراجعة إجمالى الفاتورة. 
•	التأكد من وجود HS Code. 
•	التأكد من صحة التواريخ. 
•	التأكد من عدم تكرار رقم الفاتورة لنفس المورد. 
________________________________________
Edge Cases
•	قد يحتوى نفس الـ HS Code على أكثر من Item. 
•	قد يتكرر نفس Item بأسعار مختلفة. 
•	قد تكون الفاتورة بدون Packing List فى هذه المرحلة. 
•	قد تكون الفاتورة قابلة للتعديل قبل اعتمادها.
BP-002 – Review Proforma Invoice
Purpose
مراجعة الفاتورة المبدئية (Proforma Invoice) والتأكد من صحة جميع بياناتها قبل بدء إجراءات الاستيراد، مع إنشاء ملخص حسب البند الجمركي (HS Code) ليكون الأساس لجميع المراحل التالية.
________________________________________
Business Objective
•	مراجعة صحة بيانات الفاتورة. 
•	التأكد من صحة الكميات والأسعار. 
•	مراجعة إجمالي قيمة الفاتورة. 
•	تجميع البيانات حسب HS Code. 
•	تجهيز البيانات لمراجعة الجمارك. 
•	تجهيز البيانات لتقدير الرسوم الجمركية. 
•	تجهيز البيانات لطلب عروض أسعار الشحن. 
________________________________________
System Usage
تستخدم هذه العملية فى:
•	Customs Consultation 
•	Estimate Duties 
•	Freight Quotations 
•	ACID 
•	Final Invoice Review 
________________________________________
Inputs
•	Import File 
•	Proforma Invoice 
•	Shipment Items 
________________________________________
Generated Summary
Field	Type	Notes
HS Code	Text	Unique
Total Qty	Decimal	Sum(Qty)
Total Amount	Decimal	Sum(Amount)
________________________________________
Outputs
•	HS Code Summary 
•	Invoice Validation Report 
•	Total Invoice Amount 
•	HS Code Analysis Report 
________________________________________
Business Rules
•	تجميع جميع الأصناف التى تحمل نفس HS Code. 
•	مراجعة إجمالى قيمة كل HS Code. 
•	مراجعة إجمالى الفاتورة. 
•	مراجعة عدم وجود HS Code مفقود. 
•	مراجعة عدم وجود Item بدون قيمة. 
________________________________________
Validation
•	Qty > 0 
•	Price > 0 
•	Amount = Qty × Price 
•	Invoice Total = Sum(All Amount) 
________________________________________
Edge Cases
•	أكثر من Item بنفس HS Code. 
•	نفس الصنف بأكثر من سعر. 
•	HS Code جديد غير مستخدم سابقاً. 
•	اختلاف إجمالى الفاتورة عن مجموع البنود. 
________________________________________
Deliverables
•	HS Code Summary 
•	Invoice Summary 
•	Validation Report 
________________________________________
Next Operation
➡ BP-003 Review Packing List
________________________________________
BP-003 – Review Packing List
Purpose
مراجعة Packing List والتأكد من صحة بيانات التعبئة والأوزان والأبعاد قبل احتساب حجم الشحنة واختيار وسيلة النقل.
________________________________________
Business Objective
•	مراجعة الكميات. 
•	مراجعة عدد الطرود. 
•	مراجعة الأوزان. 
•	مراجعة أبعاد الطرود. 
•	احتساب إجمالى الأوزان. 
•	تجهيز البيانات لحساب CBM. 
________________________________________
System Usage
تستخدم هذه العملية فى:
•	Calculate CBM 
•	Determine Shipping Method 
•	Freight Quotations 
•	Draft BL Review 
•	Warehouse Receiving 
________________________________________
Inputs
•	Packing List 
•	Shipment Items 
________________________________________
Required Fields
Field	Type	Required	Notes
HS Code	Text	Yes	
Item Code	Text	Yes	
Qty PCS	Decimal	Yes	
Qty PKG	Decimal	Yes	
Package Type	Lookup	No	Carton / Pallet / Bag
Length	Decimal	No	cm
Width	Decimal	No	cm
Height	Decimal	No	cm
Net Weight / Unit	Decimal	Yes	kg
Gross Weight / Unit	Decimal	Yes	kg
________________________________________
Generated Values
•	Total Net Weight 
•	Total Gross Weight 
•	Total Packages 
•	CBM 
•	Chargeable Weight 
________________________________________
Reports
Packing List Summary By HS Code
| HS Code | Qty PCS | Qty PKG | Total Net | Total Gross |
________________________________________
Business Rules
•	Total Net = Qty × Net Weight. 
•	Total Gross = Qty × Gross Weight. 
•	Gross Weight ≥ Net Weight. 
•	Qty PCS و Qty PKG يجب أن تتطابق مع الفاتورة. 
________________________________________
Validation
•	عدم وجود أوزان سالبة. 
•	عدم وجود أبعاد صفرية عند الحاجة لحساب CBM. 
•	مطابقة إجمالى الكميات مع الفاتورة. 
________________________________________
Edge Cases
•	المورد لا يرسل أبعاد الطرود. 
•	المورد لا يرسل عدد البالتات. 
•	المورد لا يذكر الأسعار داخل Packing List. 
•	اختلاف Packing List عن الفاتورة. 
________________________________________
Deliverables
•	Packing List Validation Report 
•	Packing List Summary 
•	Shipment Items Details 
________________________________________
Next Operation
BP-004	Calculate Cargo Volume (CBM) & Chargeable Weight

________________________________________
BP-004	Calculate Cargo Volume (CBM) & Chargeable Weight
BP-004 – Calculate Shipment Measurements
Purpose
احتساب القياسات الأساسية للشحنة، بما في ذلك الحجم الفعلي (CBM) والوزن المحاسبي (Chargeable Weight)، لتوفير البيانات اللازمة لتحديد وسيلة الشحن، وطلب عروض الأسعار، وتخطيط التحميل.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	احتساب الحجم الفعلي للشحنة (CBM). 
•	احتساب الوزن المحاسبي للشحن الجوي (Chargeable Weight). 
•	احتساب إجمالي الوزن الفعلي (Gross Weight). 
•	إنشاء بيانات قياسية موحدة تستخدم في جميع المراحل اللاحقة. 
•	تخزين نتائج الحساب لاستخدامها دون إعادة احتسابها. 
________________________________________
System Usage
تستخدم نتائج هذه العملية في:
•	BP-005 – Plan Cargo Loading 
•	BP-006 – Determine Shipping Method 
•	BP-008 – Manage Freight Quotations 
•	تقارير التكلفة والشحن 
________________________________________
Inputs
Shipment Items
•	Quantity 
•	Package Type 
•	Length 
•	Width 
•	Height 
•	Gross Weight 
________________________________________
Required Fields
Field	Type	Required	Notes
Qty	Number	Yes	
Length	Decimal	Yes	cm
Width	Decimal	Yes	cm
Height	Decimal	Yes	cm
Gross Weight	Decimal	Yes	kg
________________________________________
Calculations
Cargo Volume (CBM)
CBM = Qty × Length × Width × Height ÷ 1,000,000
Air Chargeable Weight
Chargeable Weight = Qty × Length × Width × Height ÷ 6000
Total Shipment Volume
Sum(Item CBM)
Total Gross Weight
Sum(Item Gross Weight)
________________________________________
Outputs
•	Total CBM 
•	Total Gross Weight 
•	Total Chargeable Weight 
ملاحظة: يتم حفظ هذه النتائج داخل ملف الشحنة لإعادة استخدامها في جميع العمليات اللاحقة دون إعادة احتسابها.
________________________________________
Business Rules
•	يتم الحساب لكل بند ثم تجميع النتائج على مستوى الشحنة. 
•	تعتمد جميع الحسابات على وحدة السنتيمتر (cm) والكيلوجرام (kg). 
•	يتم الاحتفاظ بنتائج الحساب حتى في حالة تعديل خطة التحميل. 
________________________________________
Validation
•	جميع الأبعاد أكبر من صفر. 
•	الوزن أكبر من صفر. 
•	الكمية أكبر من صفر. 
________________________________________
Edge Cases
•	اختلاف أبعاد الطرود. 
•	اختلاف أنواع التغليف. 
•	وجود أكثر من نوع Package داخل نفس الشحنة. 
________________________________________
Deliverables
•	Shipment Measurements Summary 
•	CBM Summary 
•	Chargeable Weight Summary 
________________________________________
Next Operation
➡ BP-005 – Plan Cargo Loading
________________________________________
BP-005 – Plan Cargo Loading
Purpose
إعداد واعتماد خطة تحميل الشحنة باستخدام نتائج القياسات المحسوبة مسبقًا، للتحقق من توافق الشحنة مع وسيلة النقل أو الحاوية المختارة قبل تنفيذ الحجز.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	اختيار نوع الحاوية أو وسيلة النقل المناسبة. 
•	التحقق من توافق الشحنة مع السعة المتاحة. 
•	التحقق من توافق الوزن مع الحمولة القصوى. 
•	التحقق من القيود التشغيلية الخاصة بالتحميل. 
•	إعداد واعتماد خطة تحميل أولية تستخدم أثناء الحجز. 
لا تقوم هذه المرحلة بإجراء أي عمليات حسابية للأحجام أو الأوزان، وإنما تعتمد بالكامل على نتائج BP-004.
________________________________________
System Usage
يقوم النظام بما يلي:
•	استرجاع نتائج القياسات من BP-004. 
•	تحميل مواصفات الحاويات من Master Data. 
•	مقارنة بيانات الشحنة مع مواصفات الحاويات. 
•	التحقق من جميع قيود التحميل. 
•	إنشاء خطة التحميل. 
•	اعتماد أو رفض خطة التحميل. 
________________________________________
Inputs
Shipment Measurements
•	Total CBM 
•	Total Gross Weight 
•	Total Chargeable Weight 
Shipment Information
•	Shipping Method 
•	Shipment Type 
•	Origin 
•	Destination 
Master Data
•	Container Type 
•	Container Specification 
•	Loading Constraints 
•	Package Type 
•	Handling Instructions 
________________________________________
Business Flow
1.	استرجاع نتائج BP-004. 
2.	تحميل مواصفات الحاويات المناسبة. 
3.	مقارنة حجم الشحنة مع السعة الداخلية للحاوية. 
4.	مقارنة الوزن مع الحمولة القصوى. 
5.	التحقق من قيود التحميل والمناولة. 
6.	تحديد الحاوية أو وسيلة النقل المناسبة. 
7.	إنشاء خطة التحميل. 
8.	اعتماد أو رفض الخطة. 
________________________________________
Outputs
•	Approved Loading Plan 
•	Selected Container Type 
•	Loading Validation Result 
•	Loading Notes 
________________________________________
Business Rules
•	تعتمد جميع المقارنات على نتائج BP-004. 
•	لا يجوز تعديل مواصفات الحاويات داخل خطة التحميل. 
•	لا يمكن اعتماد خطة تحميل تتجاوز حدود الوزن أو الحجم. 
•	يسمح بإنشاء أكثر من خطة تحميل لنفس الشحنة مع اعتماد نسخة واحدة فقط. 
•	يتم تسجيل جميع التعديلات داخل سجل المراجعة (Audit Trail). 
________________________________________
Validation
يتحقق النظام من:
•	توافق الحجم مع سعة الحاوية. 
•	توافق الوزن مع الحمولة القصوى. 
•	توافق نوع الحاوية مع نوع البضاعة. 
•	توافق تعليمات المناولة. 
•	توافق قيود التحميل. 
________________________________________
Edge Cases
•	عدم وجود حاوية مناسبة. 
•	الحاجة إلى أكثر من حاوية. 
•	تجاوز الحمولة القصوى. 
•	تجاوز السعة الحجمية. 
•	وجود قيود خاصة بالبضائع (Hazardous، Fragile، Temperature Controlled). 
________________________________________
Deliverables
•	Approved Loading Plan 
•	Container Selection Report 
•	Loading Validation Report 
________________________________________
Related Master Data
•	Container Type 
•	Container Specification 
•	Package Type 
•	Handling Instructions 
•	Loading Constraints 
•	Cargo Categories 
•	Unit of Measure 
________________________________________
Next Operation
➡ BP-006 – Determine Shipping Method
Shipment
   │
   │
   ▼
BP-004
   │
   ├── Calculate CBM
   ├── Calculate Gross Weight
   ├── Calculate Chargeable Weight
   │
   ▼
Store Shipment Measurements
   │
   ▼
BP-005
   │
   ├── Read Measurements
   ├── Read Container Master
   ├── Validate Capacity
   ├── Validate Weight
   ├── Validate Constraints
   │
   ▼
Create Loading Plan
   │
   ▼
Shipment Booking
________________________________________
BP-006 – Determine Shipping Method
Purpose
تحديد وسيلة الشحن المناسبة للشحنة بالاعتماد على نتائج قياسات الشحنة وخطة التحميل المعتمدة، مع مراعاة متطلبات التسليم، والتكلفة، ومدة النقل، والسياسات التشغيلية للشركة.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	اختيار وسيلة الشحن المناسبة. 
•	مطابقة متطلبات الشحنة مع وسائل النقل المتاحة. 
•	تحقيق التوازن بين التكلفة ومدة النقل. 
•	دعم مرحلة طلب عروض الأسعار (Freight Quotations). 
•	تجهيز الشحنة لمرحلة الحجز (Booking). 
________________________________________
System Usage
يقوم النظام بما يلي:
•	استرجاع نتائج قياسات الشحنة من BP-004. 
•	استرجاع خطة التحميل المعتمدة من BP-005. 
•	تحميل وسائل الشحن المتاحة من البيانات المرجعية. 
•	استبعاد وسائل الشحن غير المتوافقة. 
•	اقتراح وسيلة الشحن المناسبة. 
•	حفظ قرار وسيلة الشحن داخل ملف الشحنة. 
________________________________________
Inputs
Shipment Measurements
•	Total CBM 
•	Total Gross Weight 
•	Total Chargeable Weight 
Approved Loading Plan
•	Selected Container Type 
•	Number of Containers 
•	Loading Validation Status 
Shipment Information
•	Cargo Ready Date 
•	Origin 
•	Destination 
•	Required Delivery Date 
•	Shipment Priority 
________________________________________
Business Flow
1.	استرجاع نتائج BP-004. 
2.	استرجاع خطة التحميل المعتمدة من BP-005. 
3.	تحميل وسائل الشحن المفعلة من Shipping Method Master. 
4.	استبعاد وسائل الشحن غير المتوافقة مع بيانات الشحنة. 
5.	تقييم الوسائل المتبقية وفقًا لقواعد العمل. 
6.	اختيار وسيلة الشحن المناسبة. 
7.	حفظ القرار داخل ملف الشحنة. 
________________________________________
Business Rules
•	تعتمد جميع القرارات على نتائج BP-004 وBP-005. 
•	لا يسمح باختيار وسيلة شحن غير مفعلة. 
•	يجب أن تكون وسيلة الشحن متوافقة مع نوع الحاوية أو البضاعة. 
•	يمكن تغيير وسيلة الشحن قبل تنفيذ الحجز فقط. 
•	يتم تسجيل جميع التعديلات داخل سجل المراجعة (Audit Trail). 
________________________________________
Validation
يتحقق النظام من:
•	توافق وسيلة الشحن مع نوع الشحنة. 
•	توافق وسيلة الشحن مع خطة التحميل. 
•	توافق وسيلة الشحن مع الوجهة. 
•	توافق وسيلة الشحن مع سياسة الشركة. 
•	تفعيل وسيلة الشحن. 
________________________________________
Edge Cases
•	عدم توفر وسيلة شحن مناسبة. 
•	تغيير موعد جاهزية الشحنة. 
•	تغيير الوجهة. 
•	تغيير أولوية الشحنة. 
•	الحاجة إلى إعادة تقييم وسيلة الشحن بعد تعديل خطة التحميل. 
________________________________________
Outputs
•	Selected Shipping Method 
•	Shipping Method Decision 
•	Decision Reason 
•	Available Alternatives 
________________________________________
Deliverables
•	Shipping Method Decision Report 
•	Shipment Transportation Profile 
________________________________________
Related Master Data
•	Shipping Method 
•	Shipping Route 
•	Transit Service Level 
•	Incoterms 
•	Carrier Capability 
________________________________________
Next Operation
➡ BP-007 – Shipping Scenarios Evaluation
BP-006 – Determine Shipping Method
Purpose
تحديد وسيلة الشحن المناسبة للشحنة بالاعتماد على نتائج قياسات الشحنة وخطة التحميل المعتمدة، مع مراعاة متطلبات التسليم، والتكلفة، ومدة النقل، والسياسات التشغيلية للشركة.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	اختيار وسيلة الشحن المناسبة. 
•	مطابقة متطلبات الشحنة مع وسائل النقل المتاحة. 
•	تحقيق التوازن بين التكلفة ومدة النقل. 
•	دعم مرحلة طلب عروض الأسعار (Freight Quotations). 
•	تجهيز الشحنة لمرحلة الحجز (Booking). 
________________________________________
System Usage
يقوم النظام بما يلي:
•	استرجاع نتائج قياسات الشحنة من BP-004. 
•	استرجاع خطة التحميل المعتمدة من BP-005. 
•	تحميل وسائل الشحن المتاحة من البيانات المرجعية. 
•	استبعاد وسائل الشحن غير المتوافقة. 
•	اقتراح وسيلة الشحن المناسبة. 
•	حفظ قرار وسيلة الشحن داخل ملف الشحنة. 
________________________________________
Inputs
Shipment Measurements
•	Total CBM 
•	Total Gross Weight 
•	Total Chargeable Weight 
Approved Loading Plan
•	Selected Container Type 
•	Number of Containers 
•	Loading Validation Status 
Shipment Information
•	Cargo Ready Date 
•	Origin 
•	Destination 
•	Required Delivery Date 
•	Shipment Priority 
________________________________________
Business Flow
8.	استرجاع نتائج BP-004. 
9.	استرجاع خطة التحميل المعتمدة من BP-005. 
10.	تحميل وسائل الشحن المفعلة من Shipping Method Master. 
11.	استبعاد وسائل الشحن غير المتوافقة مع بيانات الشحنة. 
12.	تقييم الوسائل المتبقية وفقًا لقواعد العمل. 
13.	اختيار وسيلة الشحن المناسبة. 
14.	حفظ القرار داخل ملف الشحنة. 
________________________________________
Business Rules
•	تعتمد جميع القرارات على نتائج BP-004 وBP-005. 
•	لا يسمح باختيار وسيلة شحن غير مفعلة. 
•	يجب أن تكون وسيلة الشحن متوافقة مع نوع الحاوية أو البضاعة. 
•	يمكن تغيير وسيلة الشحن قبل تنفيذ الحجز فقط. 
•	يتم تسجيل جميع التعديلات داخل سجل المراجعة (Audit Trail). 
________________________________________
Validation
يتحقق النظام من:
•	توافق وسيلة الشحن مع نوع الشحنة. 
•	توافق وسيلة الشحن مع خطة التحميل. 
•	توافق وسيلة الشحن مع الوجهة. 
•	توافق وسيلة الشحن مع سياسة الشركة. 
•	تفعيل وسيلة الشحن. 
________________________________________
Edge Cases
•	عدم توفر وسيلة شحن مناسبة. 
•	تغيير موعد جاهزية الشحنة. 
•	تغيير الوجهة. 
•	تغيير أولوية الشحنة. 
•	الحاجة إلى إعادة تقييم وسيلة الشحن بعد تعديل خطة التحميل. 
________________________________________
Outputs
•	Selected Shipping Method 
•	Shipping Method Decision 
•	Decision Reason 
•	Available Alternatives 
________________________________________
Deliverables
•	Shipping Method Decision Report 
•	Shipment Transportation Profile 
________________________________________
Related Master Data
•	Shipping Method 
•	Shipping Route 
•	Transit Service Level 
•	Incoterms 
•	Carrier Capability 
________________________________________
Next Operation
➡ BP-007 – Shipping Scenarios Evaluation
________________________________________
BP-007 – Shipping Scenarios Evaluation
Purpose
يستخدم هذا الإجراء لإنشاء ومقارنة عدة سيناريوهات للشحن (Shipping Scenarios) بناءً على خيارات شركات الشحن المختلفة، بهدف اختيار أفضل رحلة من حيث موعد الإبحار، مدة الرحلة، وقت الوصول المتوقع، ومستوى المخاطرة الناتج عن التأخير المتوقع.
كما يتيح النظام حساب متوسط زمن الوصول المتوقع لجميع الخيارات المتاحة، مما يساعد فريق الاستيراد على التخطيط بدقة لموعد استلام الشحنة داخل المخزن.
________________________________________
Business Objective
•	مقارنة جميع خيارات الشحن المتاحة قبل الحجز. 
•	توقع موعد وصول الشحنة إلى المخزن قبل اتخاذ قرار الحجز. 
•	احتساب إجمالى مدة دورة الشحن بدءاً من تاريخ جاهزية الشحنة (CRD). 
•	تقليل مخاطر التأخير الناتجة عن اختيار رحلة غير مناسبة. 
•	دعم اتخاذ القرار بناءً على بيانات فعلية ومتوسطات تشغيلية. 
•	توفير تقدير واقعى لموعد وصول الشحنة يمكن الاعتماد عليه فى التخطيط والإنتاج والمبيعات. 
________________________________________
System Usage
يستخدم هذا الإجراء بعد تحديد جاهزية الشحنة وقبل تأكيد الحجز مع شركة الشحن.
يمكن للمستخدم إدخال عدد غير محدود من خيارات الشحن ومقارنتها للوصول إلى أفضل خيار أو احتساب متوسط جميع الخيارات المتاحة.
________________________________________
Inputs
Shipment Information
•	Cargo Ready Date (CRD) 
•	Port of Loading 
•	Port of Discharge 
•	Average Form 4 Processing Days 
•	Average Customs Clearance Days 
Shipping Option Information
لكل خيار شحن يتم إدخال:
•	Shipping Provider 
•	Vessel Name 
•	Sailing Date 
•	Estimated Arrival Date (ETA) 
•	Expected Shipping Line Delay (Days) 
________________________________________
Outputs
لكل خيار شحن يقوم النظام بحساب:
•	Vessel Lead Time 
•	Days Required to be Ready for Shipping 
•	Expected Total Days to Warehouse 
•	Expected Warehouse Arrival Date 
كما يقوم النظام بحساب:
•	Average Expected Transit Days 
•	Average Expected Warehouse Arrival Date 
•	Earliest Arrival Scenario 
•	Latest Arrival Scenario 
•	Recommended Shipping Scenario 
________________________________________
Business Rules
•	يمكن إضافة عدد غير محدود من خيارات الشحن. 
•	لا يشترط وجود ثلاثة خيارات، ويجوز إدخال خيار واحد أو أكثر. 
•	يتم احتساب جميع السيناريوهات باستخدام نفس بيانات الشحنة الأساسية. 
•	يتم حساب مدة الرحلة لكل خيار بصورة مستقلة. 
•	يتم احتساب متوسط جميع السيناريوهات بعد إدخالها. 
•	يعتمد متوسط الوصول المتوقع على جميع الخيارات المدخلة فقط. 
•	يمكن استبعاد أى سيناريو من حساب المتوسط إذا اعتبره المستخدم غير صالح. 
•	يحتفظ النظام بجميع السيناريوهات للمراجعة المستقبلية. 
________________________________________
Validation
يتحقق النظام من:
•	أن تاريخ الإبحار لا يسبق تاريخ جاهزية الشحنة (CRD). 
•	أن تاريخ الوصول أكبر من تاريخ الإبحار. 
•	أن جميع قيم الأيام أرقام موجبة. 
•	عدم تكرار نفس الرحلة لنفس شركة الشحن ونفس تاريخ الإبحار. 
•	إدخال جميع البيانات الأساسية قبل بدء الحسابات. 
________________________________________
Calculation Rules
Vessel Lead Time
Arrival Date - Sailing Date
________________________________________
Ready for Shipping Days
Sailing Date - Cargo Ready Date (CRD)
________________________________________
Expected Total Days to Warehouse
Average Form 4 Days
+ Average Clearance Days
+ Expected Shipping Line Delay
+ Vessel Lead Time
+ Ready for Shipping Days
________________________________________
Expected Warehouse Arrival Date
Cargo Ready Date
+ Expected Total Days to Warehouse
________________________________________
Average Expected Days to Warehouse
يتم احتساب متوسط جميع نتائج:
Expected Total Days to Warehouse
لجميع خيارات الشحن المعتمدة.
________________________________________
Average Expected Warehouse Arrival Date
يتم احتساب متوسط تاريخ الوصول المتوقع للمخزن بناءً على جميع السيناريوهات المعتمدة.
________________________________________
Edge Cases
•	وجود رحلة واحدة فقط. 
•	أكثر من رحلة لنفس شركة الشحن. 
•	اختلاف كبير بين مواعيد الإبحار. 
•	اختلاف كبير فى مدة الرحلة. 
•	تأخير متوقع مرتفع لإحدى شركات الشحن. 
•	إلغاء أحد السيناريوهات بعد إدخاله. 
•	إضافة سيناريو جديد بعد اعتماد أحد الخيارات. 
•	تعديل متوسط أيام Form 4 أو التخليص الجمركى بعد إدخال السيناريوهات. 
•	تأخر جاهزية الشحنة مما يجعل بعض الرحلات غير قابلة للحجز. 
________________________________________
Deliverables
•	Shipping Scenarios Comparison 
•	Expected Transit Time Report 
•	Expected Warehouse Arrival Report 
•	Average Transit Time 
•	Average Warehouse Arrival Date 
•	Recommended Shipping Option 
•	Shipping Risk Summary 
________________________________________
Dependencies
Previous Operations
•	Shipment Readiness Confirmation 
•	Cargo Ready Date Confirmation 
•	Port Selection 
Next Operations
•	Freight Quotation Approval 
•	Booking Confirmation 
•	Freight Cost Approval 
•	Shipment Tracking 
________________________________________
Notifications
يقوم النظام بإرسال إشعار عند:
•	إضافة سيناريو جديد. 
•	تعديل بيانات أحد السيناريوهات. 
•	تغير موعد الوصول المتوقع. 
•	تجاوز مدة الشحن الحد المقبول. 
•	وجود رحلة يغلق موعد حجزها قريباً. 
•	اختيار السيناريو النهائى للحجز. 
________________________________________
Dashboard Impact
تقوم هذه العملية بتحديث لوحة المتابعة تلقائياً وإظهار:
•	عدد خيارات الشحن المتاحة. 
•	أقرب موعد وصول متوقع. 
•	أبعد موعد وصول متوقع. 
•	متوسط مدة الشحن. 
•	متوسط موعد الوصول للمخزن. 
•	شركة الشحن الموصى بها. 
•	مستوى مخاطر التأخير لكل سيناريو. 
•	حالة الحجز لكل خيار شحن. 
________________________________________
Notes for Developer
•	يجب تصميم النظام بحيث يدعم عددًا غير محدود من خيارات الشحن دون افتراض عدد ثابت من الأعمدة أو السيناريوهات. 
•	يجب أن تكون جميع الحسابات ديناميكية وتُعاد تلقائيًا عند تعديل أى بيانات أساسية مثل CRD أو متوسط أيام Form 4 أو التخليص الجمركى. 
•	يجب توفير إمكانية استبعاد سيناريو معين من حساب المتوسط دون حذفه، مع الاحتفاظ به لأغراض المراجعة. 
•	يجب حفظ جميع السيناريوهات ضمن سجل الشحنة لإتاحة المقارنة التاريخية بين التوقعات والنتائج الفعلية، مما يسمح مستقبلًا بقياس دقة شركات الشحن وتحسين تقديرات Expected Line Delay بناءً على الأداء الفعلى.

BP-008 – Freight Quotations
Purpose
الحصول على عروض أسعار الشحن من أكثر من مقدم خدمة ومقارنة التكلفة، ومواعيد الإبحار، وموعد الوصول المتوقع لاختيار أفضل عرض.
________________________________________
Business Objective
•	مقارنة الأسعار. 
•	مقارنة Transit Time. 
•	اختيار أفضل رحلة. 
•	توقع موعد وصول البضاعة للمخزن. 
________________________________________
System Usage
تستخدم فى:
•	Booking 
•	ETA Calculation 
•	Purchase Planning 
________________________________________
Inputs
•	Shipment Summary 
•	CBM 
•	Chargeable Weight 
•	CRD 
•	Shipping Method 
________________________________________
Required Fields
Header
Field	Type	Required
CRD	Date	Yes
Port of Loading	Lookup	Yes
Port of Discharge	Lookup	Yes
Average Form 4 Days	Number	Yes
Average Clearance Days	Number	Yes
Quotation Lines
Field	Type
Shipping Provider	
Vessel	
Sailing Date	
Arrival Date	
Transit Time	
Expected Line Delay	
Freight Cost	
Free Time	
Remarks	
________________________________________
Generated Values
•	Transit Time 
•	Days Until Sailing 
•	Expected Arrival Date at Warehouse 
•	Average ETA 
•	Best Option 
________________________________________
Business Rules
•	يمكن إدخال أى عدد من عروض الأسعار. 
•	يتم حساب المتوسط تلقائياً. 
•	يمكن اختيار العرض الأفضل يدوياً. 
________________________________________
Validation
•	Arrival أكبر من Sailing. 
•	Sailing بعد CRD. 
•	جميع الأسعار مرتبطة بنفس وسيلة الشحن. 
________________________________________
Edge Cases
•	عدم توفر رحلة فى الموعد المطلوب. 
•	اختلاف Free Time. 
•	تغيير الخط الملاحى أثناء التفاوض. 
________________________________________
Deliverables
•	Freight Comparison Report 
•	ETA Report 
•	Recommended Shipping Option 
•	RFQ Email History 
________________________________________
Next Operation
➡ BP-009 Customs Consultation
________________________________________
BP-009 – Customs Consultation
Purpose
مراجعة مستندات الشحنة مع المخلص الجمركى قبل بدء الشحن للتأكد من توافقها مع متطلبات الجمارك المصرية، واعتماد البنود الجمركية، واكتشاف أى متطلبات أو مخاطر قبل تنفيذ عملية الاستيراد.
________________________________________
Business Objective
•	اعتماد HS Code. 
•	مراجعة المستندات. 
•	التأكد من استيفاء جميع المتطلبات. 
•	تقدير الرسوم والضرائب. 
•	منع أى تأخير أو غرامات بعد الشحن. 
________________________________________
System Usage
تستخدم فى:
•	Estimate Duties 
•	Payment Request 
•	ACID 
•	Booking 
•	Final Documents Review 
________________________________________
Inputs
•	Proforma Invoice 
•	Packing List 
•	HS Code Summary 
•	Freight Summary 
•	Certificate of Origin (إن وجدت) 
________________________________________
Customs Checklist
Document	Required	Responsible	Received	Verified	Approval Status	Blocking Shipment	Received Date	Verified Date	Remarks
Proforma Invoice	✔	Customs Broker							
Commercial Invoice	✔	Customs Broker							
Packing List	✔	Customs Broker							
HS Code Confirmation	✔	Customs Broker							
Gross Weight Confirmation	✔	Customs Broker							
Certificate of Origin	حسب الحالة	Customs Broker							
Inspection Certificate	حسب الحالة	Customs Broker							
ACID Information	لاحقًا	Customs Broker							
Booking Confirmation	لاحقًا	Freight Forwarder							
Insurance Certificate	حسب Incoterm	Logistics Team							
________________________________________
Business Rules
•	لا يجوز الانتقال إلى مرحلة الحجز إذا كانت هناك متطلبات جمركية إلزامية غير مستوفاة. 
•	لكل مستند حالة مستقلة (Received / Verified / Approved). 
•	يمكن للمخلص طلب تعديل المستند أكثر من مرة مع الاحتفاظ بتاريخ جميع المراجعات والملاحظات. 
•	يجب تسجيل جميع الملاحظات والطلبات الصادرة من المخلص وربطها بالمستند المعني. 
________________________________________
Validation
•	التحقق من تسجيل الـ HS Code واعتماده. 
•	التأكد من توافق بيانات الفاتورة والـ Packing List. 
•	التحقق من وجود جميع المستندات الإلزامية. 
•	التحقق من توافق أوزان وقيم الشحنة مع القيود الجمركية الخاصة بنوع البضاعة. 
________________________________________
Edge Cases
•	HS Code يحتاج إلى إعادة تصنيف. 
•	الصنف يتطلب تسجيل مصنع (قرار 43 أو غيره). 
•	الصنف يحتاج موافقات من جهات رقابية (مثل الأمن العام أو الاتصالات أو جهات فنية أخرى). 
•	اختلاف بيانات المستندات يتطلب إعادة إصدارها من المورد. 
•	اكتشاف أن الشحنة لا تستوفي شروط الاستيراد قبل السداد. 
________________________________________
Deliverables
•	Customs Review Report. 
•	Approved / Rejected Documents Checklist. 
•	HS Code Validation Report. 
•	Required Actions List. 
•	Estimated Customs Requirements. 
BP-010 – Estimate Duties
Purpose
حساب وتقدير الرسوم الجمركية والضرائب المتوقعة للشحنة قبل تنفيذ عملية الشراء أو الشحن، وذلك بناءً على البنود الجمركية (HS Code) والقيمة الواردة فى الفاتورة المبدئية (Proforma Invoice)، بهدف معرفة التكلفة الإجمالية المتوقعة للاستيراد واتخاذ قرار الاستمرار فى العملية.
________________________________________
Business Objective
•	تقدير الرسوم الجمركية قبل الشحن. 
•	حساب الضرائب المتوقعة لكل HS Code. 
•	معرفة التكلفة النهائية المتوقعة للاستيراد. 
•	دعم الإدارة فى اتخاذ قرار الشراء. 
•	تجهيز البيانات لطلب اعتماد الميزانية من الإدارة أو المالية. 
•	مقارنة التكلفة المتوقعة مع التكلفة الفعلية بعد التخليص الجمركى. 
________________________________________
System Usage
تستخدم هذه العملية فى:
•	Payment Request. 
•	Budget Approval. 
•	Landed Cost Calculation. 
•	Cost Analysis. 
•	Profitability Analysis. 
•	Customs Clearance Comparison. 
•	Financial Planning. 
________________________________________
Inputs
•	Import File. 
•	Proforma Invoice Summary. 
•	Packing List Summary. 
•	HS Code Summary. 
•	Customs Consultation Results. 
•	Customs Tariff Master Data. 
________________________________________
Required Fields
Shipment Header
Field	Type	Required	Notes
Import File ID	Lookup	Yes	
Currency	Lookup	Yes	عملة الفاتورة
Exchange Rate	Decimal	Yes	سعر الصرف المستخدم فى التقدير
Estimate Date	Date	Yes	تاريخ إعداد التقدير
Prepared By	User	Yes	
Reviewed By	User	No	
________________________________________
Estimate Details
Field	Type	Required	Notes
HS Code	Text	Yes	
Description	Text	No	
Amount	Decimal	Yes	إجمالى قيمة البند
Customs Duty %	Decimal	Yes	نسبة الرسوم الجمركية
Customs Duty Amount	Calculated	Yes	
VAT %	Decimal	Yes	غالباً 14% حسب اللوائح السارية
VAT Amount	Calculated	Yes	
Development Tax %	Decimal	No	حسب نوع الصنف
Development Tax Amount	Calculated	No	
Other Government Fees	Decimal	No	أى رسوم إضافية
Total Estimated Duties	Calculated	Yes	إجمالى الرسوم والضرائب للبند
Remarks	Text	No	
________________________________________
Outputs
•	Estimated Duties Report. 
•	Estimated Taxes Report. 
•	Total Estimated Import Cost. 
•	Duties Summary by HS Code. 
•	Budget Estimate. 
________________________________________
Reports
Estimated Duties Summary
HS Code	Amount	Customs Duties	VAT	Development Tax	Other Fees	Total Estimated Duties
________________________________________
Shipment Estimated Cost Summary
Description	Amount
Invoice Value	
Estimated Customs Duties	
Estimated VAT	
Estimated Development Tax	
Other Government Fees	
Total Estimated Import Cost	
________________________________________
Business Rules
•	يتم احتساب الرسوم لكل HS Code بشكل مستقل. 
•	تختلف نسب الرسوم والضرائب حسب التعريفة الجمركية الخاصة بكل HS Code. 
•	يمكن أن تحتوى الشحنة الواحدة على عدة بنود جمركية، ولكل بند نسب مختلفة. 
•	يتم حفظ نسب الضرائب المستخدمة وقت إعداد التقدير حتى لو تغيرت التعريفة لاحقًا. 
•	لا يجوز تعديل نسب الرسوم يدويًا إلا من مستخدم مخول، مع تسجيل سبب التعديل. 
•	هذا التقدير استرشادى ولا يمثل المطالبة الجمركية النهائية الصادرة من مصلحة الجمارك. 
________________________________________
Validation
•	يجب أن يكون لكل Item HS Code معتمد. 
•	يجب أن تكون قيمة البند أكبر من صفر. 
•	يجب وجود تعريف جمركى لكل HS Code. 
•	التحقق من صحة العملة وسعر الصرف المستخدم. 
•	مراجعة إجمالى قيمة الفاتورة مع إجمالى البنود المستخدمة فى الحساب. 
________________________________________
Edge Cases
•	وجود HS Code غير معرف فى جدول التعريفة الجمركية. 
•	وجود بند يحتاج إلى موافقات خاصة تؤثر على الرسوم. 
•	اختلاف الرسوم بين التقدير الأولى والمطالبة الجمركية النهائية. 
•	تعديل التعريفة الجمركية أثناء فترة الشحن. 
•	تطبيق إعفاءات أو اتفاقيات تجارية (مثل اتفاقيات المنشأ أو الإعفاءات الجمركية) تؤثر على الرسوم. 
•	وجود رسوم إضافية خاصة بجهات رقابية أو سلع معينة. 
________________________________________
Deliverables
•	Estimated Duties Report. 
•	Estimated Import Cost Report. 
•	HS Code Tax Analysis. 
•	Budget Approval Summary. 
•	Estimated Landed Cost. 
________________________________________
Dependencies
Previous Operations
•	BP-002 Review Proforma Invoice. 
•	BP-003 Review Packing List. 
•	BP-007 Customs Consultation. 
Next Operation

BP-011 – Import Requirements Assessment
________________________________________
Purpose
تحليل متطلبات الاستيراد الخاصة بالشحنة بعد مراجعة المستندات بواسطة المخلص الجمركى، وتحديد جميع المستندات، والموافقات، والتسجيلات، والمتطلبات الإلزامية التى يجب استكمالها قبل استكمال دورة الاستيراد.
________________________________________
Business Objective
•	تحديد جميع المتطلبات الخاصة بالشحنة. 
•	تحديد المستندات الناقصة. 
•	تحديد الموافقات الحكومية. 
•	تحديد متطلبات تسجيل المصنع. 
•	تحديد متطلبات تسجيل المنتج. 
•	تحديد الجهات الرقابية. 
•	إنشاء قائمة مهام (Action List) لمتابعة استكمال جميع المتطلبات. 
•	منع انتقال الشحنة إلى المراحل التالية قبل استيفاء المتطلبات الإلزامية. 
________________________________________
أقترح تقسيمها إلى أربعة أجزاء
أولاً: Required Documents
مثال
Document	Required	Status	Due Date
COO	✔	Pending	
Inspection Certificate	✔	Pending	
Insurance	Optional	-	
Analysis Certificate	✔	Pending	
________________________________________
ثانياً: Required Approvals
Approval	Authority	Status
GOEIC	GOEIC	Pending
NTRA	NTRA	Pending
General Security	Customs	Pending
Ministry of Health	MOH	Pending
________________________________________
ثالثاً: Required Registrations
وهذا الجزء أراه مهم جداً.
مثلاً
Requirement	Required	Status
HS Code Confirmation	✔	Pending
Factory Registration	✔	Pending
Product Registration	✔	Pending
Trademark Registration	Optional	Pending
________________________________________
رابعاً: Customs Remarks
وهذا الجزء هو الذى أراه أهم من الثلاثة السابقين.
ليس كل ملاحظة عبارة عن Approval.
قد يقول المخلص
هذا البند يحتاج تعديل الوصف.
أو
يجب تغيير HS Code.
أو
المورد لازم يصدر COO جديد.
أو
المنتج يحتاج قرار 43.
كل هذه ليست مستندات.
وليست موافقات.
بل Action Items.
________________________________________
لذلك أقترح جدول جديد
Import Requirements
Requirement Type	Description	Responsible	Due Date	Status
Document	Provide COO	Supplier		Pending
Registration	Register Factory	Import Team		Pending
Approval	GOEIC Approval	Customs Broker		Pending
Remark	Update Invoice Description	Supplier		Pending
________________________________________
ثم تتحول تلقائياً إلى Task List
كل Requirement يصبح Task داخل النظام.
مثلاً
Supplier

↓

Issue COO

↓

Pending
أو
Import Team

↓

Register Factory

↓

In Progress
________________________________________
Business Rules
•	يسمح بإضافة عدد غير محدود من المتطلبات. 
•	لكل Requirement مسئول تنفيذ. 
•	لكل Requirement تاريخ استحقاق. 
•	لكل Requirement حالة مستقلة. 
•	يمكن ربط Requirement بمستند أو بند جمركى أو منتج أو الشحنة بالكامل. 
•	لا يسمح بالانتقال إلى الحجز إذا كانت هناك متطلبات إلزامية غير مكتملة. 
•	يحتفظ النظام بتاريخ جميع التعديلات على المتطلبات. 
________________________________________
Dashboard
هذه المرحلة ستضيف Dashboard ممتازة.
مثلاً
Shipment Readiness
Documents
████████░░ 80%

Approvals
██████░░░░ 60%

Registrations
██████████ 100%

Overall Readiness

80%

➡ BP-012 – Payment Request
________________________________________
Dashboard Impact
•	تحديث حالة عملية Estimate Duties إلى Completed. 
•	إظهار إجمالى الرسوم والضرائب المتوقعة فى لوحة متابعة الشحنة. 
•	إظهار مؤشر يوضح ما إذا كانت تكلفة الاستيراد التقديرية تقع ضمن الميزانية المعتمدة للمشروع. 
•	السماح بالانتقال إلى Payment Request بعد اعتماد التقدير. 
Notes for Developer
•	لا يتم تخزين نسب الرسوم والضرائب داخل هذا الجدول بشكل ثابت؛ يجب قراءتها من Customs Tariff Master Data وقت إنشاء التقدير، ثم حفظ نسخة (Snapshot) من القيم المستخدمة داخل سجل التقدير حتى تظل مرجعًا تاريخيًا حتى إذا تغيرت التعريفة لاحقًا. 
•	يجب تصميم النظام بحيث يدعم إضافة أنواع جديدة من الرسوم أو الضرائب مستقبلًا دون الحاجة إلى تعديل هيكل قاعدة البيانات، وذلك بالاعتماد على جدول مرجعى لأنواع الرسوم (Duty & Tax Types) وربطه بتفاصيل التقدير، بدلاً من إنشاء أعمدة ثابتة لكل نوع رسم. هذا سيجعل النظام مرنًا وقابلًا للتوسع مع تغير التشريعات الجمركية.

•	________________________________________
•	Purpose
•	إصدار طلب رسمي للإدارة المالية لسداد قيمة الفاتورة المبدئية (Proforma Invoice) أو جزء منها (مثل الدفعة المقدمة Advance Payment) للمورد الأجنبي، وذلك لتأكيد الطلب وبدء عملية التصنيع أو الشحن.
•	________________________________________
•	Business Objective
•	• توثيق واعتماد طلبات السداد الموجهة للإدارة المالية.
•	• ربط الدفعات المالية بملف الاستيراد (Import File) والفاتورة المبدئية.
•	• متابعة حالة الدفع (مدفوع جزئياً، مدفوع بالكامل).
•	• دعم تخطيط التدفقات النقدية (Cash Flow Planning).
•	• ضمان عدم تجاوز إجمالي المدفوعات لقيمة الفاتورة المعتمدة.
•	________________________________________
•	System Usage
•	تستخدم هذه العملية فى:
•	• Financial Approvals.
•	• Cash Flow Management.
•	• Form 4 Preparation (نموذج 4).
•	• Supplier Account Statement.
•	Project name
•	• Cost Allocation.
•	________________________________________
•	Inputs
•	• Import File.
•	• Approved Proforma Invoice.
•	• Supplier Bank Details (من جدول Supplier Master Data).
•	• Estimated Duties (لإعطاء الإدارة المالية رؤية كاملة عن التكلفة).
•	________________________________________
•	Required Fields
•	Header Information
Field	Type	Required	Notes
Payment Request ID	Auto Number	Yes	Primary Key
Import File ID	Lookup	Yes	رقم ملف الاستيراد
Project Name	Read-Only	Yes	يسحب تلقائياً من الملف
Proforma Invoice No	Lookup	Yes	الفاتورة المرتبطة بالطلب
Supplier Name	Read-Only	Yes	يسحب تلقائياً من الملف
Payment Type	Lookup	Yes	Advance Payment / Against BL / Final Settlement
Requested Amount	Decimal	Yes	المبلغ المطلوب تحويله
Currency	Read-Only	Yes	عملة الفاتورة المبدئية
Due Date	Date	Yes	تاريخ الاستحقاق المطلوب
Request Date	Date	Yes	تاريخ إنشاء الطلب
Status	Lookup	Yes	Draft / Pending Approval / Approved / Paid / Rejected
•	Supplier Bank Details
Field	Type	Required	Notes
Bank Name	Text	Yes	بنك المورد المستفيد
Swift Code	Text	Yes	
IBAN / Account No	Text	Yes	
Beneficiary Name	Text	Yes	يجب أن يتطابق مع اسم المورد الرسمي
•	________________________________________
•	Outputs
•	• Payment Request Document (مستند طلب الدفع).
•	• Pending Payment Notification للإدارة المالية.
•	• تحديث الرصيد المتبقي (Remaining Balance) للفاتورة.
•	________________________________________
•	Business Rules
•	• لا يمكن إنشاء طلب دفع لفاتورة لم يتم اعتمادها.
•	• إجمالي مبالغ طلبات الدفع المرتبطة بفاتورة واحدة يجب ألا يتجاوز القيمة الإجمالية للـ Proforma Invoice (إلا في حدود نسبة سماحية محددة مسبقاً إذا لزم الأمر).
•	• يجب أن يتم سحب بيانات بنك المورد تلقائياً من الـ Master Data، وفي حال تغييرها يجب أن يتطلب ذلك موافقة إدارية (لأسباب أمنية لمنع الاحتيال).
•	• بمجرد تحويل حالة الطلب إلى "Paid"، يجب إرفاق مستند التحويل البنكي (Swift Copy).
•	________________________________________
•	Validation
•	• التحقق من أن (Requested Amount > 0).
•	• التحقق من أن (Requested Amount + Previous Payments ≤ Total Invoice Amount).
•	• التأكد من اكتمال بيانات البنك الخاصة بالمورد (Swift, IBAN).
•	________________________________________
•	Edge Cases
•	• تغير بيانات الحساب البنكي للمورد بناءً على تعليمات جديدة (يتطلب تحديث Master Data مع Audit Trail).
•	• دفع عمولات التحويل البنكي (Bank Charges) هل يتحملها المورد (SHA/BEN) أم المستورد (OUR)؟ يجب تحديدها في الطلب.
•	• تقلبات أسعار الصرف القوية بين تاريخ طلب الدفع وتاريخ التنفيذ الفعلي من البنك.
•	• رفض البنك للتحويل بسبب نقص المستندات أو أخطاء في الـ Swift Code.
•	________________________________________
•	Dependencies
•	Previous Operations
•	• BP-002 Review Proforma Invoice.
•	• BP-010 Estimate Duties (يفضل وجود تقدير التكلفة قبل الدفع).
•	Next Operation
•	➡ BP-014 – ACID Request (حسب الترتيب الفعلي للشركة، غالباً يتم إصدار رقم نافذة ونموذج 4 بالتزامن مع التحويل البنكي).
•	________________________________________
•	Notifications
•	• إشعار للإدارة المالية بوجود طلب دفع جديد معلق للاعتماد.
•	• إشعار لمدير المشتريات/الاستيراد عند تغيير حالة الطلب إلى "Paid" لإبلاغ المورد بالبدء.
•	________________________________________
•	Dashboard Impact
•	• تغيير حالة الشحنة المالي إلى "Payment Processing" أو "Partially Paid".
•	• ظهور المبلغ في مؤشرات "Cash Outflow" الخاصة بالشهر الحالي.
•	• تحديث شريط التقدم (Progress Bar) لملف الاستيراد للإشارة إلى تخطي مرحلة الدفع الأولي.
•	________________________________________
•	Notes for Developer
•	• يجب فصل صلاحيات إنشاء طلب الدفع (مختص الاستيراد) عن صلاحيات تغيير حالة الطلب إلى Paid (الإدارة المالية).
•	• تأكد من تطبيق Lock على حقل Requested Amount بمجرد انتقال الطلب إلى حالة Pending Approval لمنع التعديل أثناء مراجعة الحسابات.
•	• قم ببرمجة نظام تحذير (Alert) إذا كانت بيانات بنك المورد المرفقة في الفاتورة مختلفة عن تلك المسجلة في الـ Master Data.
BP-013 – Shipment Document Lifecycle Management
________________________________________
Purpose
إدارة دورة حياة جميع مستندات الشحنة منذ استلام أول نسخة من المورد وحتى تسليم النسخ الأصلية إلى المخلص الجمركى بعد الانتهاء من جميع الإجراءات البنكية والجمركية.
يهدف النظام إلى تتبع جميع عمليات إنشاء المستندات، مراجعتها، اعتمادها، إصدار النسخ النهائية، انتقال النسخ الورقية بين الجهات المختلفة، ومنع فقدان أى مستند خلال دورة الاستيراد.
________________________________________
Business Objective
•	إنشاء سجل كامل لجميع مستندات الشحنة. 
•	متابعة جميع إصدارات المستندات (Draft / Final). 
•	تسجيل جميع عمليات المراجعة والاعتماد. 
•	تتبع انتقال المستندات بين جميع الأطراف المشاركة. 
•	التأكد من اكتمال المستندات المطلوبة لكل مرحلة. 
•	منع استخدام مستند غير معتمد. 
•	منع فقد أو تأخير المستندات الأصلية. 
•	توفير سجل تاريخى كامل (Audit Trail) لجميع الأحداث التى تمت على كل مستند. 
________________________________________
System Usage
تستخدم هذه العملية فى جميع مراحل دورة الاستيراد، بما فى ذلك:
•	Review Proforma Invoice 
•	Review Packing List 
•	Customs Consultation 
•	Freight Booking 
•	CargoX Upload 
•	Form 4 Preparation 
•	Banking Process 
•	Customs Clearance 
•	Warehouse Receiving 
________________________________________
Inputs
Shipment Information
•	Import File 
•	Project 
•	Supplier 
•	Freight Forwarder 
•	Customs Broker 
Shipment Documents
•	Proforma Invoice 
•	Commercial Invoice 
•	Packing List 
•	Electronic Invoice 
•	Certificate of Origin 
•	Inspection Certificate (If Required) 
•	Booking Confirmation 
•	Draft / Final House Bill of Lading 
•	Draft / Final Master Bill of Lading 
•	ACID Information 
•	CargoX Documents 
•	Form 4 
•	Customs Assessment 
•	Disclaimer Letter 
________________________________________
Outputs
•	Shipment Document Checklist 
•	Document Review History 
•	Document Approval Status 
•	CargoX Upload Confirmation 
•	Physical Document Tracking Log 
•	Bank Submission Record 
•	Customs Submission Record 
•	Missing Documents Report 
•	Document Readiness Status 
________________________________________
Business Rules
•	لكل مستند نسخة حالية (Current Version) وحالة مستقلة. 
•	يمكن أن يمر المستند بأكثر من دورة مراجعة قبل اعتماده. 
•	لا يسمح باعتماد مستند لم تتم مراجعته. 
•	لا يسمح باستخدام النسخة Draft فى العمليات التى تتطلب النسخة النهائية. 
•	يجب تسجيل جميع عمليات المراجعة والاعتماد. 
•	يجب تسجيل الجهة المالكة للمستند فى كل مرحلة. 
•	يجب تسجيل جميع عمليات استلام وتسليم النسخ الأصلية. 
•	لا يسمح بالانتقال إلى المرحلة التالية إذا كانت هناك مستندات إلزامية غير مكتملة. 
•	يجب الاحتفاظ بجميع الإصدارات السابقة وعدم استبدالها. 
________________________________________
Validation
يتحقق النظام من:
•	اكتمال جميع المستندات المطلوبة. 
•	مطابقة بيانات المستندات لبعضها البعض. 
•	وجود نسخة نهائية للمستندات المطلوبة. 
•	اعتماد المستندات قبل استخدامها. 
•	تسجيل جميع عمليات الاستلام والتسليم. 
•	وجود Tracking Number عند استخدام Courier. 
•	عدم فقدان أى مستند أثناء انتقاله بين الجهات المختلفة. 
________________________________________
Edge Cases
•	تعديل المورد للمستند أكثر من مرة. 
•	إصدار أكثر من Draft Bill of Lading. 
•	إعادة إصدار Certificate of Origin. 
•	إعادة رفع المستندات على CargoX. 
•	إرسال المستندات مباشرة من المورد إلى الشركة. 
•	إرسال المستندات إلى Freight Forwarder Agent أولاً. 
•	استلام المستندات على دفعات. 
•	فقد أو تأخر مستند أثناء الشحن. 
•	رفض البنك أحد المستندات وإعادته للتعديل. 
•	طلب المخلص الجمركى إعادة إصدار أحد المستندات. 
•	اختلاف بيانات المستندات بين النسخة الإلكترونية والنسخة الورقية. 
•	استلام أكثر من Original Bill of Lading. 
________________________________________
Deliverables
•	Complete Shipment Document Checklist 
•	Document Review Report 
•	Missing Documents Report 
•	Document Approval Report 
•	CargoX Confirmation Report 
•	Physical Document Movement Report 
•	Bank Submission Report 
•	Customs Submission Report 
________________________________________
Dependencies
Previous Operations
•	BP-001 Receive Purchase Order 
•	BP-002 Review Proforma Invoice 
•	BP-003 Review Packing List 
Next Operations
•	BP-006 Freight Quotations 
•	BP-007 Customs Consultation 
•	BP-009 Payment Request 
•	BP-010 ACID Request 
•	Form 4 Preparation 
•	Customs Clearance 
________________________________________
Notifications
يقوم النظام بإرسال إشعارات عند:
•	استلام مستند جديد. 
•	طلب مراجعة مستند. 
•	اعتماد أو رفض مستند. 
•	إصدار نسخة جديدة من المستند. 
•	رفع المستندات على CargoX. 
•	شحن النسخ الأصلية بواسطة Courier. 
•	استلام النسخ الأصلية. 
•	تسليم المستندات للبنك. 
•	إعادة المستندات من البنك. 
•	تسليم المستندات للمخلص الجمركى. 
•	وجود مستند مفقود أو متأخر. 
•	اقتراب موعد يتطلب مستنداً غير مكتمل. 
________________________________________
Dashboard Impact
تقوم هذه العملية بتحديث لوحة المتابعة تلقائياً وتشمل:
•	نسبة اكتمال مستندات الشحنة (Document Completion %). 
•	حالة كل مستند. 
•	آخر جهة تحتفظ بالمستند الأصلى. 
•	المستندات قيد المراجعة. 
•	المستندات المعتمدة. 
•	المستندات المرفوضة. 
•	حالة رفع مستندات CargoX. 
•	حالة إرسال واستلام النسخ الأصلية. 
•	حالة إرسال المستندات إلى البنك. 
•	حالة إرسال المستندات إلى المخلص الجمركى. 
•	التنبيهات الخاصة بالمستندات الناقصة أو المتأخرة. 
________________________________________
Notes for Developer
•	يجب تصميم النظام بحيث يعتبر المستند كياناً مستقلاً (Entity) له دورة حياة كاملة، وليس مجرد ملف مرفق. 
•	يجب فصل بيانات المستند الأساسية عن سجل الأحداث (Document Event History)، بحيث يتم تسجيل كل عملية إنشاء، مراجعة، اعتماد، إرسال، استلام، أو تعديل كسجل مستقل دون فقدان البيانات السابقة. 
•	يجب دعم تعدد الإصدارات (Versioning) مع الاحتفاظ بجميع النسخ السابقة وربط كل عملية بالنسخة المستخدمة. 
•	يجب دعم تتبع حيازة المستندات الأصلية (Chain of Custody)، مع معرفة الجهة المالكة للمستند فى أى لحظة، وتسجيل جميع عمليات النقل بين المورد، ووكيل الشحن، وشركة الشحن، والشركة، والبنك، والمخلص الجمركى. 
•	يجب أن تكون جميع عمليات المراجعة، والاعتماد، واستلام النسخ الأصلية، ورفع مستندات CargoX، وإرسال المستندات للبنك أو للمخلص الجمركى قابلة للتدقيق (Auditable) مع تسجيل المستخدم، والتاريخ، والوقت، والنتيجة لكل عملية. 
________________________________________
وأقترح إضافة قاعدة تشغيلية جديدة داخل الوثيقة:
Document Lifecycle Principle
لا يعتبر المستند ملفاً ثابتاً داخل النظام، وإنما يمر بدورة حياة كاملة تشمل الإنشاء، والمراجعة، والاعتماد، وإعادة الإصدار، وتبادل النسخ الإلكترونية والورقية بين الأطراف المختلفة، مع الاحتفاظ بالسجل الكامل لجميع الإصدارات والأحداث لضمان سلامة الإجراءات التشغيلية ومنع فقدان المستندات أو استخدامها فى مرحلة غير مناسبة.
BP-014 – ACID Request & Verification
Purpose
إدارة دورة حياة رقم ACID (Advance Cargo Information Declaration) بدايةً من تجهيز وإرسال طلب الإصدار إلى المخلص الجمركى، ثم استلام رقم ACID والتحقق من صحة البيانات قبل اعتماده واستخدامه فى عمليات الحجز والشحن.
________________________________________
Business Objective
•	إنشاء طلب إصدار ACID. 
•	تسجيل بيانات الطلب. 
•	استلام بيانات ACID الصادرة. 
•	التحقق من مطابقة البيانات الصادرة مع بيانات ملف الاستيراد. 
•	متابعة صلاحية ACID. 
•	اعتماد ACID قبل استخدامه. 
•	منع تنفيذ الحجز بدون ACID صالح ومعتمد. 
________________________________________
Process Flow
Phase 1 – ACID Request
يقوم النظام بتجهيز جميع البيانات المطلوبة وإرسالها للمخلص الجمركى لإصدار رقم ACID.
Phase 2 – ACID Verification
بعد استلام بيانات ACID، يقوم النظام بمقارنتها تلقائياً مع بيانات ملف الاستيراد، ثم اعتماد الرقم فى حالة التطابق أو تسجيل الاستثناءات عند وجود اختلافات.
________________________________________
System Usage
تستخدم هذه العملية فى:
•	Booking 
•	CargoX 
•	Shipping Documents 
•	Customs Clearance 
________________________________________
Inputs
Egyptian Importer (From Import File)
•	Egyptian Importer Name 
•	Egyptian Importer Tax ID 
•	Address 
Foreign Exporter (From Import File)
•	Foreign Exporter Name 
•	Registration Type 
•	Foreign Exporter ID 
•	Country 
•	Country Code 
•	Address 
•	Telephone Number 
Shipment (From Import File)
•	Proforma Invoice Number 
•	Invoice Date 
•	Invoice Type 
•	Purchase Order Number 
•	Purchase Order Date 
•	Shipping Port 
•	Destination Port 
________________________________________
Generated Information
Field	Description
ACID Number	رقم ACID
Requested Date	تاريخ طلب الإصدار
Generated Date	تاريخ إصدار ACID
Expiry Date	تاريخ انتهاء صلاحية ACID
Status	Requested / Generated / Verified / Expired / Cancelled
________________________________________
Verification
يقوم النظام بمقارنة البيانات التالية بين Import File و ACID الصادر:
Data Group	Verification
Egyptian Importer	Name - Tax ID - Address
Foreign Exporter	Name - Registration Type - Registration ID - Country - Country Code - Address - Telephone
Shipment	Proforma Invoice - Invoice Date - Invoice Type - Purchase Order - Shipping Port - Destination Port
ثم يعرض تقرير مقارنة مثل:
Field	Import File	ACID	Status
Importer Name	✔	✔	Match
Tax ID	✔	✔	Match
Exporter Name	✔	✔	Match
Registration ID	✔	✔	Match
Proforma Invoice	✔	✔	Match
Shipping Port	✔	✔	Match
Destination Port	✔	✔	Match
________________________________________
Outputs
•	ACID Record 
•	ACID Verification Report 
•	ACID Approval Status 
•	ACID Expiry Status 
•	Ready for Booking Status 
________________________________________
Business Rules
•	لا يمكن طلب إصدار ACID إلا بعد اعتماد بيانات الشحنة. 
•	يتم إصدار ACID بواسطة المخلص الجمركى. 
•	يجب مطابقة البيانات المستلمة مع بيانات ملف الاستيراد قبل الاعتماد. 
•	لا يسمح بتنفيذ Booking بدون ACID بحالة Verified. 
•	يجب متابعة تاريخ انتهاء صلاحية ACID وإظهار التنبيهات قبل انتهائه. 
•	يجب أن يتم شحن البضاعة وإنهاء الإجراءات الجمركية قبل انتهاء صلاحية ACID. 
•	يحتفظ النظام بسجل كامل لطلبات الإصدار ونتائج التحقق. 
________________________________________
Validation
يتحقق النظام من:
•	اكتمال جميع البيانات المطلوبة قبل إرسال الطلب. 
•	وجود رقم ACID بعد الاستلام. 
•	تطابق بيانات المستورد. 
•	تطابق بيانات المصدر. 
•	تطابق بيانات الفاتورة. 
•	تطابق بيانات الموانئ. 
•	أن ACID لم تنته صلاحيته. 
________________________________________
Edge Cases
•	رفض طلب إصدار ACID. 
•	اختلاف البيانات بين الطلب والبيانات الصادرة. 
•	تعديل بيانات الفاتورة بعد إصدار ACID. 
•	إعادة إصدار ACID. 
•	انتهاء صلاحية ACID قبل الحجز. 
•	إلغاء الشحنة بعد إصدار ACID. 
________________________________________
Deliverables
•	ACID Certificate 
•	ACID Verification Report 
•	ACID Exception Report 
•	ACID Expiry Report 
________________________________________
Dependencies
Previous Operations
•	BP-002 Review Proforma Invoice 
•	BP-007 Customs Consultation 
•	BP-009 Payment Request (وفقًا لإجراءات الشركة) 
Next Operations
•	BP-011 Booking 
•	BP-012 CargoX Upload 
________________________________________
Notifications
يقوم النظام بإرسال إشعار عند:
•	إنشاء طلب ACID. 
•	إصدار رقم ACID. 
•	وجود اختلافات أثناء التحقق. 
•	اعتماد ACID. 
•	اقتراب انتهاء الصلاحية. 
•	انتهاء صلاحية ACID. 
________________________________________
Dashboard Impact
•	رقم ACID. 
•	حالة ACID (Requested / Generated / Verified). 
•	تاريخ الإصدار. 
•	تاريخ انتهاء الصلاحية. 
•	الأيام المتبقية. 
•	حالة التحقق (Matched / Mismatch). 
•	جاهزية الشحنة للحجز. 
________________________________________
Notes for Developer
•	يجب حفظ Snapshot لجميع البيانات المرسلة عند طلب إصدار ACID، وعدم الاعتماد على البيانات الحالية داخل ملف الاستيراد عند المقارنة لاحقًا، حتى إذا تم تعديل الملف بعد إرسال الطلب. 
•	يجب أن تتم المقارنة تلقائيًا بين Snapshot الطلب والبيانات المستلمة، مع إظهار الفروقات على مستوى كل حقل. 
•	لا يتم تغيير حالة ACID إلى Verified إلا بعد اكتمال المطابقة أو اعتماد الفروقات من المستخدم المخول. 
بهذا الشكل يصبح الـ ACID عملية واحدة متكاملة (Lifecycle) تبدأ بالطلب وتنتهى بالاعتماد، بدلاً من فصلها إلى عمليتين مستقلتين، وهو ما يعكس التسلسل التشغيلي الفعلي بصورة أوضح.
________________________________________
BP-015 – Freight Quotation Management
Purpose
إدارة عملية طلب واستلام ومقارنة واعتماد عروض أسعار الشحن من شركات الشحن أو مقدمي الخدمات اللوجستية، بهدف اختيار أفضل عرض من حيث التكلفة، ومدة الشحن، ووقت الوصول المتوقع، وشروط الخدمة، ليكون المرجع الرسمي لإنشاء الحجز.
________________________________________
Business Objective
•	إرسال طلبات عروض الأسعار (RFQ). 
•	استلام عدد غير محدود من عروض الأسعار. 
•	مقارنة الأسعار والخدمات. 
•	مقارنة مدة الشحن. 
•	مقارنة Free Time. 
•	مقارنة بنود التكلفة. 
•	اختيار العرض الأنسب. 
•	اعتماد عرض سعر واحد ليصبح أساس عملية الحجز. 
________________________________________
Trigger
بعد الانتهاء من:
•	Determine Shipping Method 
•	Customs Consultation 
•	Estimate Duties 
________________________________________
Prerequisites
•	Import File 
•	Shipment Summary 
•	Shipping Method 
•	Cargo Ready Date (CRD) 
•	POL 
•	POD 
________________________________________
Inputs
Shipment Information
Field	Description
Import File	ملف الاستيراد
Shipment Type	Air / Ocean LCL / Ocean FCL
Cargo Ready Date	CRD
Port of Loading	POL
Port of Discharge	POD
CBM	حجم الشحنة
Chargeable Weight	للشحن الجوي
Total Gross Weight	الوزن الإجمالي
Freight Quotations
لكل عرض سعر:
Field	Description
Service Provider	
Shipping Line	
Vessel	
ETD	
ETA	
Transit Time	
Free Time	
Currency	
Valid Until	
Remarks	
________________________________________
Process Description
1.	إنشاء RFQ. 
2.	إرسال الطلب لعدة شركات. 
3.	استلام عروض الأسعار. 
4.	إدخال بيانات كل عرض. 
5.	مقارنة جميع العروض. 
6.	اختيار العرض الأفضل. 
7.	اعتماد العرض. 
8.	قفل العرض المختار. 
9.	تحويله إلى Shipment Booking. 
________________________________________
Outputs
•	Approved Freight Quotation 
•	Freight Comparison Report 
•	Selected Service Provider 
•	Estimated Freight Cost 
•	Booking Ready 
________________________________________
Related Documents
•	RFQ 
•	Freight Quotation 
•	Comparison Report 
________________________________________
Related Master Data
•	External Service Providers 
•	Shipping Lines 
•	Currency 
•	Transport Locations 
________________________________________
Business Rules
•	يسمح بإدخال عدد غير محدود من عروض الأسعار. 
•	يسمح باعتماد عرض واحد فقط. 
•	لا يجوز تعديل العرض بعد اعتماده. 
•	يمكن رفض جميع العروض وإعادة طلب عروض جديدة. 
•	يحتفظ النظام بجميع العروض للمقارنة التاريخية. 
________________________________________
Validation
•	وجود Shipping Method. 
•	وجود POL و POD. 
•	وجود ETD و ETA. 
•	صلاحية عرض السعر. 
•	عدم انتهاء مدة صلاحية العرض. 
________________________________________
Edge Cases
•	انتهاء صلاحية العرض. 
•	انسحاب مقدم الخدمة. 
•	تعديل الأسعار. 
•	تغيير شركة الشحن. 
•	عدم وجود رحلة مناسبة. 
________________________________________
Dependencies
Previous
•	BP-005 Determine Shipping Method 
Next
➡ BP-016 Shipment Booking Management
________________________________________
Notifications
•	New RFQ 
•	New Quotation Received 
•	Quotation Approved 
•	Quotation Expired 
________________________________________
Dashboard Impact
•	عدد عروض الأسعار. 
•	أقل سعر. 
•	أسرع رحلة. 
•	أفضل عرض. 
•	حالة اعتماد العرض. 
________________________________________
Notes for Developer
لا يتم إنشاء الحجز مباشرة من شاشة المقارنة، وإنما يجب أن يقوم النظام بإنشاء Booking Draft تلقائيًا من العرض المعتمد، مع نسخ جميع البنود والأسعار كوحدة مرجعية (Snapshot) لضمان إمكانية المقارنة لاحقًا مع أي تعديلات أو فواتير فعلية.
________________________________________
BP-016 – Shipment Booking Management
Purpose
إدارة دورة حياة الحجز بالكامل بداية من تحويل عرض السعر المعتمد إلى حجز فعلي، وحتى تأكيد الإبحار، مع إدارة الحاويات، والتعديلات، والتكاليف النهائية، وإصدار بيانات الحجز الرسمية.
________________________________________
Business Objective
•	إنشاء الحجز. 
•	إدارة تفاصيل الحجز. 
•	إدارة الحاويات. 
•	تسجيل جميع التعديلات. 
•	احتساب التكلفة الأولية للشحن. 
•	تجهيز بيانات Shipment Tracking. 
•	تجهيز بيانات مستندات الشحن. 
________________________________________
Trigger
اعتماد Freight Quotation.
________________________________________
Prerequisites
•	Approved Freight Quotation. 
•	Verified ACID. 
•	Approved Shipment. 
________________________________________
Inputs
Booking Header
Field	Description
Import File	
Booking Request Date	
Booking Confirmation No	
Shipment Type	
Freight Forwarder

Vessel name	
Shipping Line	
POL	
POD	
ETD	
ETA	
________________________________________
Shipment Type
•	Air 
•	Ocean LCL 
•	Ocean FCL 
________________________________________
Booking Lifecycle
Stage
Booking Request
Booking Confirmation
Booking Amendment
Booking Cancellation
Container Allocation
Vessel Allocation
Sailing Confirmation
________________________________________
Booking Dates
Field
Booking Request Date
Booking Confirmation Date
Amendment Date
Cancellation Date
Container Allocation Date
Vessel Allocation Date
Confirmed ETD
Expected ETA
________________________________________
Calculated Fields
Field	Formula
Transit Time	ETA − ETD
________________________________________
Container Details
يسمح بإضافة عدد غير محدود من أنواع الحاويات داخل نفس الحجز.
Container Type	Qty
20GP	1
40HC	2
45HC	1
________________________________________
Booking Charges
يسحب النظام بنود التكلفة من عرض السعر المعتمد، مع السماح بتعديلها إذا لزم الأمر مع تسجيل سبب التعديل.
Charge Type	Unit	Qty	Currency	Rate	Total
Inland	Per Container	Auto	USD		
THC	Per Container	Auto	USD		
Sea Freight	Per Container	Auto	USD		
Export Customs Clearance	Per Container	Auto	USD		
VGM Fee	Per Container	Auto	USD		
VGM Notification	Per Container	Auto	USD		
BL	Per Shipment	1	USD		
COO / EUR1	Per Shipment	1	EUR		
Stamp Duty	Per Shipment	1	EUR		
TLX Release	Per Shipment	1	EUR		
Courier	Per Shipment	1	EUR		
Documentation Fees	Per Shipment	1	USD		
Disclaimer Letter	Per Shipment	1	USD		
ملاحظة: يتم تحديد Currency لكل بند بشكل مستقل، ولا يشترط أن تكون جميع البنود بنفس العملة.
________________________________________
Process Description
1.	إنشاء Booking Draft من العرض المعتمد. 
2.	إدخال أو مراجعة تفاصيل الحجز. 
3.	تحديد أنواع وأعداد الحاويات. 
4.	مراجعة بنود التكلفة. 
5.	احتساب التكلفة الأولية للشحن تلقائيًا. 
6.	تسجيل أي تعديل على الحجز. 
7.	تسجيل بيانات السفينة والحاويات. 
8.	تأكيد موعد الإبحار. 
9.	اعتماد الحجز. 
________________________________________
Outputs
•	Booking Confirmation. 
•	Preliminary Freight Invoice. 
•	Container Summary. 
•	Booking Cost Summary. 
•	Ready for Shipping Documents. 
•	Ready for Shipment Tracking. 
________________________________________
Related Documents
•	Booking Confirmation 
•	Preliminary Freight Invoice 
•	Container Allocation 
•	Vessel Allocation 
________________________________________
Related Master Data
•	Shipping Lines 
•	External Service Providers 
•	Currency 
•	Transport Locations 
•	Freight Charge Types 
•	Container Types 
________________________________________
Business Rules
•	لا يمكن إنشاء حجز بدون عرض سعر معتمد. 
•	يسمح بإضافة أكثر من نوع حاوية داخل نفس الحجز. 
•	تحسب البنود Per Container تلقائيًا بناءً على عدد الحاويات. 
•	تحسب البنود Per Shipment مرة واحدة فقط لكل حجز. 
•	يحتفظ النظام بنسخة Snapshot من الأسعار والبنود المعتمدة عند إنشاء الحجز. 
•	أي تعديل لاحق على الأسعار أو البنود يسجل في سجل تعديلات الحجز مع ذكر السبب والمستخدم. 
________________________________________
Validation
•	وجود عرض سعر معتمد. 
•	تطابق نوع الشحنة مع بيانات الحجز. 
•	وجود ETD و ETA. 
•	أن تكون أعداد الحاويات أكبر من صفر. 
•	اكتمال بيانات الأسعار لكل بند. 
________________________________________
Edge Cases
•	تغيير نوع الحاوية بعد الحجز. 
•	إضافة حاوية جديدة. 
•	إلغاء جزء من الحجز. 
•	تغيير السفينة. 
•	تغيير موعد الإبحار. 
•	تغيير شركة الشحن. 
•	اختلاف الأسعار النهائية عن العرض المعتمد. 
________________________________________
Dependencies
Previous
•	BP-006 Freight Quotation Management 
•	BP-010 ACID Request & Verification 
Next
•	BP-012 Shipping Documents Management 
•	BP-013 Shipment Tracking 
________________________________________
Notifications
•	Booking Created. 
•	Booking Confirmed. 
•	Booking Amended. 
•	Booking Cancelled. 
•	Vessel Assigned. 
•	Containers Allocated. 
•	Sailing Confirmed. 
________________________________________
Dashboard Impact
•	حالة الحجز. 
•	عدد الحاويات حسب النوع. 
•	التكلفة الأولية للشحن. 
•	موعد الإبحار. 
•	موعد الوصول المتوقع. 
•	مدة الشحن. 
•	نسبة التغير بين السعر المعتمد والسعر بعد التعديل. 
________________________________________
Notes for Developer
يجب أن يعتمد احتساب Booking Charges على Charge Unit لكل بند (Per Container / Per Shipment / وغيرها)، وليس على أسماء البنود نفسها. كما يجب إنشاء Preliminary Freight Invoice تلقائيًا من بيانات الحجز باستخدام أسعار الـ Snapshot، ليكون المرجع الأساسي عند مطابقة فواتير الشحن الفعلية لاحقًا. بهذه الطريقة يصبح النظام مرنًا لإضافة بنود تكلفة جديدة أو تغيير قواعد الاحتساب دون تعديل هيكل قاعدة البيانات.
________________________________________
BP-017 – Cargo Loading Coordination
Purpose
إدارة ومتابعة عملية تحميل البضاعة لدى المورد أو المصنع، والتأكد من تنفيذ تعليمات التحميل، وتسجيل بيانات الحاويات والأختام، ومتابعة إصدار المستندات النهائية بعد اكتمال التحميل.
________________________________________
Business Objective
•	متابعة موعد التحميل. 
•	التأكد من تنفيذ تعليمات التحميل. 
•	تسجيل بيانات الحاويات. 
•	تسجيل بيانات الأختام (Seals). 
•	متابعة اكتمال التحميل. 
•	التأكد من استلام المستندات النهائية بعد التحميل. 
•	توفير سجل كامل لعملية التحميل. 
________________________________________
Trigger
بعد اعتماد مستندات الشحن (Final Shipping Documents) أو بعد اعتماد الـ Booking، بحسب أسلوب العمل مع المورد.
________________________________________
Prerequisites
•	Approved Booking. 
•	Confirmed Loading Schedule. 
•	Ready Cargo. 
•	Approved Packing List. 
________________________________________
Loading Information
Planned Loading
Field	Description
Planned Loading Date	موعد التحميل المتفق عليه
Planned Loading Time	وقت التحميل
Loading Location	المصنع أو المخزن
Responsible Person	مسؤول التحميل
Freight Forwarder	شركة الشحن
________________________________________
Actual Loading
Field	Description
Actual Loading Date	تاريخ التحميل الفعلى
Loading Start Time	بداية التحميل
Loading Finish Time	نهاية التحميل
Loading Duration	يحسب تلقائياً
Loading Status	Planned / Loading / Completed
________________________________________
Loading Instructions
يقوم المستخدم بتسجيل جميع التعليمات الخاصة بالتحميل.
أمثلة:
•	Non-Stackable 
•	Stackable 
•	Do Not Tilt 
•	Keep Dry 
•	Fragile 
•	Top Load Only 
•	Temperature Controlled 
•	Dangerous Goods Handling 
•	Center of Gravity Notice 
•	Palletized Cargo 
•	Manual Loading Required 
________________________________________
Business Rules
•	يسمح بإضافة عدد غير محدود من تعليمات التحميل. 
•	يمكن ربط التعليمات بالشحنة بالكامل أو بحاوية محددة. 
•	يمكن اعتبار بعض التعليمات إلزامية. 
________________________________________
Container Loading Details
يسمح بإضافة عدد غير محدود من الحاويات.
Container No	Type	Seal No	Status
ABC1234567	40HC	SL987654	Loaded
XYZ7654321	20GP	SL123456	Loaded
________________________________________
لكل حاوية يمكن تسجيل
•	Container Number 
•	Container Type 
•	Seal Number 
•	Loading Date 
•	Loading Time 
•	Gross Weight 
•	Number of Packages 
•	Loaded By 
•	Remarks 
________________________________________
Cargo Verification
بعد انتهاء التحميل يتم مراجعة:
•	عدد الطرود. 
•	عدد الحاويات. 
•	أرقام الحاويات. 
•	أرقام الأختام. 
•	الوزن. 
•	مطابقة التحميل مع Packing List. 
________________________________________
Documents Received After Loading
بعد اكتمال التحميل يتم استلام النسخ النهائية من المستندات.
يشمل:
•	Final Commercial Invoice 
•	Final Packing List 
•	Certificate of Origin 
•	Inspection Certificate 
•	Fumigation Certificate 
•	Dangerous Goods Declaration 
ويتم ربط كل مستند بتاريخ الاستلام وحالته.
________________________________________
Outputs
•	Loading Report. 
•	Container Summary. 
•	Seal Summary. 
•	Final Loading Confirmation. 
•	Ready for Shipment Tracking. 
________________________________________
Business Rules
•	لا يمكن إنهاء مرحلة التحميل قبل تسجيل جميع الحاويات. 
•	يجب أن يكون لكل حاوية رقم تعريف (Container Number). 
•	يجب أن يكون لكل حاوية رقم Seal. 
•	يتم حساب مدة التحميل تلقائياً. 
•	يتم الاحتفاظ بسجل بجميع عمليات التحميل. 
________________________________________
Dashboard Impact
يعرض النظام:
•	الشحنات الجاهزة للتحميل. 
•	الشحنات قيد التحميل. 
•	الشحنات التى اكتمل تحميلها. 
•	الشحنات التى لم تصل مستنداتها النهائية. 
•	متوسط زمن التحميل. 
•	الحاويات المحملة اليوم. 
________________________________________
Related Documents
•	Loading Confirmation 
•	Container Loading Report 
•	Commercial Invoice 
•	Packing List 
•	COO 
•	Inspection Certificate 
•	Fumigation Certificate 
•	Dangerous Goods Declaration 

BP-018 – Shipping Documents Review & Dual Approval
Purpose
إدارة دورة مراجعة واعتماد مستندات الشحن، من خلال مقارنة مسودات المستندات (Draft Documents) ببيانات الشحنة المسجلة داخل النظام، وتوثيق جميع الملاحظات والتعديلات المطلوبة حتى إصدار النسخ النهائية المعتمدة، مع ضمان اعتمادها من كلٍ من مسؤول الاستيراد والمخلص الجمركي قبل استخدامها كمستندات رسمية للشحنة.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	استلام مسودات مستندات الشحن. 
•	إنشاء نموذج مراجعة تلقائي. 
•	مقارنة بيانات المستند مع بيانات الشحنة. 
•	تسجيل الملاحظات والتعديلات المطلوبة. 
•	متابعة تنفيذ التعديلات. 
•	مراجعة النسخ المعدلة. 
•	اعتماد المستندات من الجهات المسؤولة. 
•	حفظ النسخ النهائية. 
•	ضمان تطابق جميع المستندات مع بيانات الحجز وملف الاستيراد قبل الشحن أو قبل وصول البضاعة. 
________________________________________
Trigger
بعد تأكيد الحجز (Booking Confirmation).
________________________________________
Prerequisites
•	Approved Booking 
•	Approved Import File 
•	Approved Packing List 
•	Approved Commercial Invoice 
•	ACID Verified 
________________________________________
Supported Documents
•	Commercial Invoice 
•	Final Packing List 
•	Draft House Bill of Lading (HBL) 
•	Draft Master Bill of Lading (MBL) 
•	Draft Air Waybill (AWB) 
•	Certificate of Origin (COO) 
•	Inspection Certificate 
•	Insurance Certificate 
•	Fumigation Certificate 
•	Dangerous Goods Declaration 
________________________________________
Review Workflow
Draft
   │
   ▼
Revision Required
   │
   ▼
Reviewed
   │
   ▼
Dual Approval
   │
   ▼
Final
________________________________________
Stage 1 – Draft Review
عند رفع أى نسخة Draft، يقوم النظام تلقائياً بإنشاء Document Review Sheet اعتماداً على البيانات المسجلة داخل النظام، بحيث يتمكن المستخدم من مراجعة جميع البنود دون الحاجة إلى إدخال البيانات المرجعية يدوياً.
________________________________________
Auto Generated Shipment Summary
يقوم النظام بعرض البيانات المرجعية للشحنة تلقائياً.
Field	Source
Shipper	Supplier Master
Consignee	Company Profile
Notify Party	Company Profile (Default)
Vessel	Booking
Voyage	Booking
POL	Booking
POD	Booking
Place of Delivery	Import File
Booking Number	Booking
ACID Number	ACID
Shipping Mode	Booking
Incoterm	Import File
Container Summary	Booking
Packing Summary	Final Packing List
Gross Weight	Packing List
Net Weight	Packing List
Number of Packages	Packing List
Business Rule
يتم استخراج جميع البيانات السابقة تلقائياً من النظام وتستخدم كمرجع للمراجعة، ولا يسمح بإدخالها يدوياً داخل نموذج المراجعة.
________________________________________
Review Checklist
يقوم النظام بعرض مقارنة مباشرة بين البيانات المرجعية وبيانات المستند.
Field	System Value	Draft Value	Status	Comment
Shipper	ABC Factory	ABC Factory	✅ Correct	
Vessel	MSC LUNA	MSC LANA	❌ Incorrect	Vessel Name
ACID	EG12345	EG12345	✅ Correct	
POL	Genoa	Genoa	✅ Correct	
________________________________________
Available Actions
لكل بند يمكن للمراجع اختيار إحدى الحالات التالية:
•	✅ Correct 
•	❌ Incorrect 
•	N/A (Not Applicable) 
________________________________________
فى حالة اختيار Incorrect تصبح الحقول التالية إلزامية:
•	Required Correction 
•	Reason 
•	Notes (Optional) 
________________________________________
Stage 2 – Revision Required
بعد انتهاء المراجعة يقوم النظام بإنشاء Revision Report يحتوى فقط على البنود غير المطابقة وإرسالها إلى الجهة المسؤولة عن التعديل.
مثال:
Item	Required Action	Responsible
Vessel Name	Correct Vessel Name	Shipping Provider
Consignee Address	Update Address	Supplier
BL Number	Reissue Draft	Shipping Provider
Business Rules
•	لا يمكن الانتقال إلى المرحلة التالية طالما توجد ملاحظات مفتوحة. 
•	يحتفظ النظام بجميع إصدارات الـ Draft السابقة. 
•	يتم تسجيل جميع الملاحظات والتعديلات داخل سجل المراجعة. 
________________________________________
Stage 3 – Reviewed
بعد استلام النسخة المعدلة، يعيد النظام فتح البنود التى كانت تحتوى على ملاحظات فقط، بينما تظل البنود التى سبق اعتمادها مقفلة (Locked) ما لم تتغير قيمتها فى النسخة الجديدة.
Field	Previous Status	New Status
Vessel	Incorrect	✅ Correct
Consignee	Correct	Locked
Business Rule
لا يعيد النظام مراجعة البنود التى سبق اعتمادها إلا إذا تم تعديل بياناتها فى النسخة الجديدة.
________________________________________
Stage 4 – Dual Approval
بعد انتهاء جميع المراجعات والتأكد من إغلاق جميع الملاحظات، تبدأ مرحلة الاعتماد النهائى.
يعتمد النظام مبدأ Dual Approval، بحيث لا يعتبر المستند معتمداً بمجرد موافقة مستخدم واحد، وإنما يجب الحصول على اعتمادين مستقلين.
Required Approvals
•	Importer Approval (اعتماد مسؤول الاستيراد). 
•	Customs Broker Approval (اعتماد المخلص الجمركى). 
________________________________________
Approval Status
يعرض النظام حالة الاعتماد لكل مستند كما يلى:
Reviewer	Status	Date	Notes
Import Officer	✅ Approved	15/08/2026	—
Customs Broker	⏳ Pending	—	Waiting for Final COO
________________________________________
Business Rules
•	لا يعتبر المستند معتمداً إلا بعد اكتمال الاعتمادين. 
•	يمكن لكل جهة إضافة ملاحظات قبل الاعتماد. 
•	يحتفظ النظام بتاريخ ووقت واسم المستخدم الذى قام بالاعتماد. 
•	فى حالة رفض أحد المعتمدين، يعود المستند تلقائياً إلى مرحلة Revision Required مع الاحتفاظ بسبب الرفض وسجل المراجعات. 
________________________________________
Stage 5 – Final
بعد اكتمال جميع المراجعات والحصول على جميع الاعتمادات المطلوبة:
•	يتم تغيير حالة المستند إلى Final. 
•	يتم حفظ النسخة النهائية. 
•	يتم ربطها بملف الاستيراد والشحنة. 
•	تصبح النسخة المرجعية المستخدمة فى جميع العمليات التالية. 
•	يمنع تعديل المستند إلا من خلال إصدار نسخة جديدة (New Version). 
________________________________________
Outputs
•	Approved Shipping Documents. 
•	Document Review Report. 
•	Revision Report. 
•	Dual Approval Record. 
•	Final Approved Documents. 
•	Complete Review History. 
________________________________________
Dashboard Impact
يعرض النظام مؤشرات مثل:
•	Draft Documents Waiting Review. 
•	Documents Under Revision. 
•	Documents Waiting Import Approval. 
•	Documents Waiting Customs Broker Approval. 
•	Documents Ready for Final Approval. 
•	Final Approved Documents. 
•	Documents with Pending Corrections. 
________________________________________
Business Rules
•	لكل مستند دورة مراجعة مستقلة. 
•	يحتفظ النظام بجميع الإصدارات (Version History). 
•	لا يمكن اعتماد النسخة النهائية مع وجود ملاحظات مفتوحة. 
•	جميع التعديلات والمراجعات والاعتمادات تُسجل مع اسم المستخدم والتاريخ والوقت. 
•	يدعم النظام مشاركة أكثر من مراجع أثناء مرحلة المراجعة. 
•	لا تنتقل حالة المستند إلى Final إلا بعد اكتمال Dual Approval. 
•	فى حالة إصدار نسخة جديدة من المستند، تبدأ دورة المراجعة والاعتماد من جديد مع الاحتفاظ بجميع الإصدارات السابقة وسجل الاعتمادات. 
________________________________________
BP-019 – Original Shipment Documents Collection
•	Purpose
•	إدارة عملية استلام المستندات الأصلية الخاصة بالشحنة من المورد أو وكيله، ومتابعة طريقة تسليمها (يدويًا أو عن طريق شركة شحن)، والتأكد من اكتمال جميع المستندات المطلوبة قبل بدء إجراءات التخليص الجمركي أو استلام البضاعة.
•	________________________________________
•	Business Objective
•	تهدف هذه المرحلة إلى:
•	متابعة قيام المورد بإرسال المستندات الأصلية. 
•	تسجيل طريقة التسليم (Courier / Agent / Hand Delivery). 
•	متابعة بيانات الشحنة الخاصة بالمستندات. 
•	التأكد من اكتمال جميع المستندات الأصلية المطلوبة. 
•	تسجيل تاريخ الاستلام. 
•	توثيق حالة كل مستند. 
•	ربط المستندات الأصلية بملف الاستيراد. 
•	________________________________________
•	Trigger
•	بعد:
•	BP-020 – Electronic Document Exchange. 
•	وقبل:
•	Customs Clearance Preparation. 
•	Original Documents Handover to Customs Broker. 
•	________________________________________
•	Prerequisites
•	Electronic Document Exchange Completed. 
•	Final Shipping Documents Approved. 
•	Shipment Dispatched. 
•	________________________________________
•	Delivery Methods
•	يدعم النظام طرق استلام المستندات التالية:
•	Courier Service 
•	Shipping Agent 
•	Supplier Representative 
•	Hand Delivery 
•	Other 
•	________________________________________
•	Shipment Information
•	يقوم المستخدم بتسجيل بيانات إرسال المستندات.
•	Field	•	Description
•	Dispatch Date	•	تاريخ إرسال المستندات
•	Delivery Method	•	طريقة الإرسال
•	Courier Company	•	شركة الشحن
•	Courier Tracking Number	•	رقم التتبع
•	Expected Arrival Date	•	تاريخ الوصول المتوقع
•	Actual Receipt Date	•	تاريخ الاستلام
•	Received By	•	اسم المستلم
•	Notes	•	ملاحظات
•	________________________________________
•	Original Documents Checklist
•	يقوم النظام بإنشاء قائمة تحقق للمستندات المطلوب استلامها.
•	Category	•	Document	•	Original Received	•	Received Date	•	Status	•	Notes
•	Commercial	•	Commercial Invoice	•	☐	•		•		•	
•	Commercial	•	Packing List	•	☐	•		•		•	
•	Certificate	•	Certificate of Origin (COO)	•	☐	•		•		•	
•	Certificate	•	Inspection Certificate	•	☐	•		•		•	
•	ملاحظة: يتم إنشاء هذه القائمة تلقائيًا من جدول مرجعي، بحيث يمكن إضافة أو إزالة مستندات حسب متطلبات المورد أو بلد المنشأ أو الجمارك.
•	________________________________________
•	Document Status
•	لكل مستند يمكن تحديد إحدى الحالات التالية:
•	Pending 
•	Received 
•	Missing 
•	Rejected 
•	Replaced 
•	________________________________________
•	Business Rules
•	لا تعتبر المرحلة مكتملة إلا بعد استلام جميع المستندات الإلزامية. 
•	يمكن تحديد بعض المستندات كاختيارية حسب نوع الشحنة أو متطلبات الجهة المختصة. 
•	يتم تسجيل تاريخ ووقت استلام كل مستند بشكل مستقل. 
•	فى حالة استلام نسخة بديلة، يحتفظ النظام بتاريخ جميع النسخ السابقة. 
•	يجب ربط جميع المستندات بملف الاستيراد والشحنة. 
•	________________________________________
•	Outputs
•	Original Documents Receipt Record. 
•	Courier Tracking Record. 
•	Original Documents Checklist. 
•	Missing Documents Report. 
•	Receipt History. 
•	________________________________________
•	Validation
•	يتحقق النظام من:
•	اكتمال جميع المستندات الإلزامية. 
•	وجود رقم تتبع إذا كانت طريقة التسليم Courier. 
•	تسجيل تاريخ الاستلام. 
•	تسجيل الشخص الذى استلم المستندات. 
•	تطابق المستندات مع ملف الاستيراد. 
•	________________________________________
•	Exception Cases (Edge Cases)
•	تأخر وصول المستندات. 
•	فقدان المستندات أثناء الشحن. 
•	استلام مستندات ناقصة. 
•	استلام نسخة غير أصلية. 
•	استلام نسخة معدلة. 
•	إعادة إرسال المستندات. 
•	________________________________________
•	Dependencies
•	Previous Operations
•	BP-020 – Electronic Document Exchange. 
•	Next Operations
•	Customs Clearance Preparation. 
•	Customs Broker Handover. 
•	________________________________________
•	Notifications
•	يقوم النظام بإرسال إشعارات عند:
•	إرسال المستندات من المورد. 
•	اقتراب موعد وصول المستندات. 
•	استلام المستندات. 
•	وجود مستندات ناقصة. 
•	تأخر وصول المستندات. 
•	اكتمال استلام جميع المستندات. 
•	________________________________________
•	Dashboard Impact
•	يعرض النظام مؤشرات مثل:
•	Documents In Transit. 
•	Documents Received. 
•	Pending Original Documents. 
•	Missing Documents. 
•	Delayed Courier Shipments. 
•	Ready for Customs Clearance. 
•	________________________________________
•	Notes for Developer
•	يجب أن تكون قائمة المستندات Data-Driven من خلال جدول Original Shipment Documents Master، بحيث يمكن إضافة أو حذف أو جعل المستند إلزاميًا أو اختياريًا دون تعديل الكود. 
•	يجب فصل بيانات الشحنة البريدية (Courier Shipment) عن المستندات المستلمة، لأن شحنة بريدية واحدة قد تحتوي على عدة مستندات، كما يمكن أن تُرسل المستندات على أكثر من شحنة بريدية. 
•	ينبغي دعم إمكانية تسجيل أكثر من عملية إرسال (Multiple Courier Shipments) لنفس ملف الاستيراد، مع ربط كل مستند بعملية الإرسال التي وصل من خلالها، والاحتفاظ بتاريخ كامل لجميع عمليات الإرسال والاستلام. وهذا يعكس الواقع العملي عندما يرسل المورد بعض الأصول أولاً ثم يستكمل بقية المستندات لاحقًا.
•	
BP-020 – Electronic Document Exchange
Purpose
إدارة دورة تبادل المستندات الإلكترونية الخاصة بالشحنة من خلال منصات تبادل المستندات الإلكترونية (Electronic Document Exchange Providers)، مثل CargoX، وذلك بدءًا من إرسال الدعوة وحتى اكتمال تبادل المستندات بنجاح، مع التحقق من صحة البيانات القانونية للمستندات النهائية قبل رفعها، وتوثيق جميع عمليات الإرسال والاستلام لضمان سلامة البيانات وقبولها من جميع الأطراف.
________________________________________
Business Objective
تهدف هذه المرحلة إلى:
•	إدارة دورة تبادل المستندات الإلكترونية. 
•	دعم أكثر من مزود خدمة لتبادل المستندات الإلكترونية. 
•	متابعة حالة الدعوة وقبولها. 
•	مراجعة البيانات القانونية قبل رفع المستندات. 
•	التحقق من تطابق المستندات مع بيانات النظام. 
•	منع رفع مستندات تحتوي على أخطاء. 
•	تسجيل جميع عمليات التبادل الإلكتروني. 
•	إنشاء سجل تاريخي كامل لجميع عمليات الإرسال والاستلام. 
________________________________________
Trigger
بعد:
•	BP-018 – Shipping Documents Review & Dual Approval 
وقبل:
•	Shipment Dispatch 
•	Original Documents Release 
•	Customs Clearance (عند الحاجة) 
________________________________________
Prerequisites
•	Final Commercial Invoice 
•	Final Packing List 
•	Approved Shipping Documents 
•	Dual Approval Completed 
•	Approved ACID 
•	Electronic Document Exchange Invitation Created 
________________________________________
Supported Providers
يعتمد النظام على جدول مرجعي لمزودي خدمة تبادل المستندات الإلكترونية، بحيث لا يكون CargoX جزءًا ثابتًا من النظام.
أمثلة:
•	CargoX 
•	أى مزود آخر يتم إضافته مستقبلاً 
Business Rule
لا يعتمد النظام على CargoX بشكل مباشر، وإنما يتعامل مع مزود الخدمة المختار (Provider)، مما يسمح بإضافة منصات جديدة مستقبلاً دون تعديل تصميم النظام.
________________________________________
Related Documents
قد تختلف المستندات المطلوبة حسب مزود الخدمة أو الدولة أو نوع الشحنة.
يدعم النظام رفع أى مستند معتمد مثل:
•	Commercial Invoice 
•	Packing List 
•	Certificate of Origin 
•	Bill of Lading 
•	Air Waybill 
•	Insurance Certificate 
•	Inspection Certificate 
•	أى مستند إضافى يتم تعريفه داخل النظام. 
________________________________________
Electronic Document Exchange Workflow
Invitation Sent
        │
        ▼
Invitation Accepted
        │
        ▼
Documents Ready
        │
        ▼
Verification Checklist
        │
        ▼
Ready For Upload
        │
        ▼
Uploading
        │
        ▼
Uploaded Successfully
        │
        ▼
Completed
فى حالة وجود خطأ:
Rejected
      │
      ▼
Shipping Documents Review & Approval
________________________________________
Stage 1 – Invitation Management
يقوم النظام بإدارة دورة الدعوة الخاصة بمنصة تبادل المستندات.
الحالات المدعومة:
•	Invitation Sent 
•	Invitation Accepted 
•	Invitation Expired 
•	Invitation Cancelled 
________________________________________
Stage 2 – Document Verification Checklist
قبل السماح برفع المستندات، يقوم النظام بإنشاء Verification Checklist بصورة تلقائية اعتمادًا على قواعد تحقق معرفة داخل النظام.
لا يتم تثبيت عناصر المراجعة داخل البرنامج، وإنما يتم قراءتها من جدول مرجعي يسمى:
Document Verification Rules
وبذلك يمكن إضافة أو حذف أو تعديل أى عنصر تحقق دون الحاجة إلى تعديل الكود.
________________________________________
Document Verification Rules (Master Data)
لكل قاعدة تحقق يتم تعريف:
Field	Description
Rule Name	اسم قاعدة التحقق
Document Type	نوع المستند
Field Name	اسم الحقل
Mandatory	إلزامى / اختيارى
Validation Type	Manual / Auto
Active	نعم / لا
Notes	ملاحظات
________________________________________
Auto Generated Verification Checklist
يقوم النظام بإنشاء قائمة المراجعة تلقائياً بناءً على القواعد المعرفة داخل Document Verification Rules.
Verification Item	Source Document	System Value	Document Value	Status	Notes
Shipper Name	Commercial Invoice	Auto	Auto	☐	
Egyptian Importer Name	Commercial Invoice	Auto	Auto	☐	
ACID Number	Commercial Invoice	Auto	Auto	☐	
Currency	Commercial Invoice	Auto	Auto	☐	
Number of Packages	Packing List	Auto	Auto	☐	
HS Code	Commercial Invoice	Auto	Auto	☐	
Unit Price	Commercial Invoice	Auto	Auto	☐	
Line Total	Commercial Invoice	Auto	Auto	☐	
Invoice Grand Total	Commercial Invoice	Auto	Auto	☐	
Country of Origin	COO	Auto	Auto	☐	
BL Number	Bill of Lading	Auto	Auto	☐	
________________________________________
Checklist Actions
لكل عنصر مراجعة يمكن اختيار:
•	✅ Correct 
•	❌ Incorrect 
•	N/A 
إذا كانت النتيجة Incorrect تصبح الحقول التالية إلزامية:
•	Required Correction 
•	Reason 
•	Notes 
________________________________________
Stage 3 – Upload Preparation
بعد اكتمال جميع عناصر قائمة المراجعة بنجاح، يقوم النظام تلقائياً بتغيير حالة العملية إلى:
Ready For Upload
ولا يسمح ببدء عملية الرفع إلا إذا كانت جميع عناصر المراجعة مطابقة.
________________________________________
Stage 4 – Upload Management
يقوم النظام بتسجيل جميع عمليات الرفع.
Field
Provider
Upload Date
Uploaded By
Upload Status
Upload Reference Number
Notes
________________________________________
Stage 5 – Completion
بعد نجاح عملية تبادل المستندات الإلكترونية:
•	يتم تحديث الحالة إلى Completed. 
•	يتم ربط العملية بملف الاستيراد. 
•	يتم حفظ رقم العملية المرجعي (Reference Number) إن وجد. 
•	تصبح المستندات الإلكترونية جزءًا من السجل الرسمي للشحنة. 
________________________________________
Outputs
•	Electronic Document Exchange Record. 
•	Verification Checklist. 
•	Upload History. 
•	Upload Status Report. 
•	Electronic Document Exchange Log. 
________________________________________
Business Rules
•	لا يسمح برفع المستندات قبل اكتمال Dual Approval. 
•	تعتمد جميع عمليات التحقق على المستندات النهائية المعتمدة. 
•	لا يسمح بإدخال بيانات المراجعة يدوياً. 
•	يتم إنشاء قائمة المراجعة تلقائياً من Document Verification Rules. 
•	يمكن أن تختلف عناصر المراجعة حسب نوع المستند أو مزود الخدمة. 
•	لا يسمح بالرفع إلا بعد نجاح جميع عناصر قائمة التحقق. 
•	يحتفظ النظام بجميع محاولات الرفع. 
•	عند تعديل أى مستند نهائى تتم إعادة تنفيذ عملية التحقق بالكامل. 
________________________________________
Validation
يقوم النظام بالتحقق من جميع البنود المعرفة داخل Document Verification Rules.
وقد تشمل على سبيل المثال:
•	Shipper Name 
•	Importer Name 
•	ACID Number 
•	Currency 
•	Number of Packages 
•	HS Code 
•	Unit Price 
•	Line Total 
•	Invoice Total 
•	Country of Origin 
•	BL Number 
مع إمكانية إضافة أى عنصر جديد مستقبلاً دون تعديل البرنامج.
________________________________________
Exception Cases (Edge Cases)
•	رفض الدعوة. 
•	انتهاء صلاحية الدعوة. 
•	تغيير المستندات بعد تجهيز قائمة التحقق. 
•	تعديل رقم ACID. 
•	إعادة إصدار Bill of Lading. 
•	فشل عملية الرفع. 
•	إعادة رفع المستندات. 
•	اختلاف بيانات أحد المستندات عن بيانات النظام. 
________________________________________
Dependencies
Previous Operations
•	BP-018 – Shipping Documents Review & Dual Approval. 
Next Operations
•	Shipment Dispatch. 
•	Original Documents Release. 
•	Customs Clearance. 
•	Shipment Tracking. 
________________________________________
Notifications
يقوم النظام بإرسال إشعارات عند:
•	إرسال الدعوة. 
•	قبول الدعوة. 
•	جاهزية المستندات للمراجعة. 
•	وجود أخطاء فى قائمة التحقق. 
•	نجاح عملية الرفع. 
•	فشل عملية الرفع. 
•	اكتمال عملية التبادل الإلكترونى. 
•	رفض عملية التبادل. 
________________________________________
Dashboard Impact
يعرض النظام:
•	Pending Invitations. 
•	Accepted Invitations. 
•	Documents Waiting Verification. 
•	Ready for Upload. 
•	Upload In Progress. 
•	Upload Completed. 
•	Upload Failed. 
•	Returned for Correction. 
________________________________________
Notes for Developer
•	يجب تصميم العملية باسم Electronic Document Exchange وليس باسم CargoX، ويكون CargoX مجرد Provider داخل جدول مرجعى يسمح بإضافة مزودى خدمة آخرين مستقبلاً. 
•	تعتمد عملية التحقق بالكامل على جدول Document Verification Rules، بحيث تصبح جميع عناصر قائمة التحقق Data-Driven وقابلة للإدارة دون تعديل الكود. 
•	يجب أن تدعم قواعد التحقق أكثر من نوع مستند، بحيث يحدد كل عنصر مراجعة المستند المرجعى الذى تتم المقارنة عليه (Commercial Invoice، Packing List، Certificate of Origin، Bill of Lading، Air Waybill...). 
•	يجب الاحتفاظ بسجل كامل للدعوات، وعمليات الرفع، ونتائج التحقق، وجميع الإصدارات السابقة للمستندات. 
•	إذا تم تعديل أى مستند بعد نجاح عملية التبادل الإلكترونى، يجب اعتبار عملية الرفع السابقة غير صالحة، وإجبار المستخدم على إعادة تنفيذ Verification Checklist ثم إعادة رفع المستندات، مع الاحتفاظ بالسجل التاريخى لجميع العمليات. 
هذا التصميم يجعل المرحلة مرنة، قابلة للتوسع، ومستقلة عن CargoX، كما يسمح بإضافة مستندات جديدة أو قواعد تحقق جديدة أو حتى مزود خدمة جديد بالكامل دون الحاجة إلى إعادة تصميم النظام أو تعديل قاعدة البيانات.

