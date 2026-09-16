# 🖥️ ImportFlow ERP — UI Screen Standards

> تُحمَّل تلقائيًا مع كل محادثة. تحتوي على معايير UI الثابتة لكل شاشة في النظام.
> الـ Widgets الجاهزة موجودة في: `frontend/lib/core/widgets/`

---

## 0. 🏛️ Screen Types & Baseline Definitions (تصنيف الشاشات والمعايير المرجعية)

> **قاعدة حتمية:** يجب أولاً تحديد نوع الشاشة (**Type A** أو **Type B** أو **Type C**) قبل إجراء أي فحص اتساق أو مراجعة للتصميم. يُحظر تماماً تطبيق معيار شاشات المراحل (Stage Screen) على شاشات القوائم (List Screen) أو العكس.

### Type A — شاشات المراحل والمراجعة (Stage / Review Screens)
* **الشاشة المرجعية القياسية (Baseline Screen):** شاشة مراجعة مسودات المستندات (`ShipmentDraftDocumentsReviewScreen`).
* **الغرض:** إدارة مرحلة تشغيلية لشحنة استيرادية معينة (مثل الفحص، الإفراج، التخليص الجمركي، الفاتورة 4، نموذج 46).
* **هيكل الـ Header:**
  - أيقونة + عنوان الشاشة + **شارة المرحلة (Stage Badge مثل `PHASE-X` أو `STAGE_CODE`)**.
  - شريط الأزرار العلوي (Top-Right): أزرار دورة حياة الشحنة (`Skip Step` باللون البرتقالي، `Stop Shipment` باللون الأحمر، `Clone`، `AI Assistant`، `Refresh`، وزر العودة `Back to Dashboard` دائماً في النهاية).

### Type B — شاشات الجداول والقوائم الرئيسية (List / Index Screens)
* **الشاشة المرجعية القياسية (Baseline Screen):** شاشة إدارة ملفات الاستيراد والشحنات (`ImportFilesScreen`).
* **الغرض:** عرض وإدارة السجلات العامة والبيانات المرجعية (مثل ملفات الاستيراد، أوامر الشراء، الموردين، الشركات، الشركاء، المواقع، العملات).
* **هيكل الـ Header:**
  - أيقونة + عنوان الشاشة فقط (**❌ بدون شارة مرحلة Stage Badge** — لأنها تمثل جدولاً عاماً وليس مرحلة لشحنة محددة).
  - أعلى اليمين (Top-Right Actions): **بحد أقصى إجراءان اثنان فقط (Max 2 Actions)**:
    1. الإجراء الرئيسي للشاشة (مثل: زر رفع مستند جديد `Upload Import Document` أو إضافة سجل جديد `Add New`).
    2. زر العودة للرئيسية (`Back to Dashboard` / `BackToDashboardButton`).
    *(أي أزرار أخرى تُنقل إجبارياً إلى صف الإجراءات أسفل الترويسة وليس داخل الـ Header).*
* **هيكل جسم الشاشة (Body Structure) — قاعدة شريط الأدوات المدمج (Compact Toolbar Rule):**
  > **قاعدة الكثافة الرأسية الإلزامية:** يُحظر تماماً استخدام صفوف متعددة أو بطاقات متتالية لمنطقة الإجراءات مما يدفع الجدول لأسفل (Below the fold). يجب دمج منطقة الإجراءات بالكامل في **سطر واحد موحد مدمج (Single Unified Row)** مباشرة فوق الجدول:
  1. **شريط الأدوات الموحد (Single Toolbar Row — Max 40px):**
     - **الأزرار المرئية الأساسية (Max 3 Primary Buttons):** بحد أقصى 3 أزرار رئيسية مرئية فقط (مثل: زر الإضافة الرئيسي مصمت `Add New`، زر مفرغ `Search & Clone`، وزر قائمة `More actions ⋮`).
     - **قائمة الإجراءات الإضافية (`More actions ⋮` Menu):** نقل كافة الإجراءات الثانوية والتقارير المتقدمة وميزات الذكاء الاصطناعي واستيراد/نسخ البيانات إلى القائمة المنسدلة لمنع الازدحام الأفقي.
     - **شريط أيقونات البيانات السريعة:** أيقونات مدمجة (32x32px) للوظائف الحيوية: التحديث الفوري 🔄، وتصدير إكسل 📗، وتصدير بي دي إف 📕.
     - **حقل البحث والتصفية المدمج في نفس السطر (Inline Search & Filter):** حقل البحث النصي (عرض 180-220px بارتفاع 32px) وقائمة تصفية الحالة (عرض 100-130px بارتفاع 32px) على الجانب المقابل داخل نفس السطر.
     - **أبعاد الأزرار القياسية:** ارتفاع 32px كحد أقصى، حشوة أفقية 10-12px، وحجم خط 12.5-13px.
     - **إجمالي ارتفاع منطقة الإجراءات:** 80-90px كحد أقصى شاملاً كافة الحواف والفواصل والهوامش (مع استهداف 44-48px لشريط الأدوات نفسه).
  2. **جدول البيانات الرئيسي (Data Table):**
     - يبدأ مباشرة أسفل الشريط الموحد دون بطاقات إضافية فاصلة.
     - **قاعدة الرؤية الإلزامية (Visibility Rule):** يجب أن يظهر ما لا يقل عن **4 إلى 5 صفوف كاملة** من جدول البيانات للمستخدم فور فتح الشاشة دون الحاجة لأي تمرير (Scrolling) على شاشات اللابتوب القياسية بدقة `1366x768`.

### Type C — الشاشات الخدمية ولوحات القيادة (Utility / Dashboard Screens)
* **أمثلة:** لوحة المتابعة التشغيلية (`OperationalDashboardScreen`)، لوحة دورة الحياة (`LifecycleBoardScreen`)، حاسبة الأحجام (`CbmCalculatorScreen`)، مصمم التقارير الديناميكي (`DynamicReportBuilderScreen`).
* **الهيكل:** مصممة خصيصاً لوظائف التفاعل والتحليل البياني وحسابات الشحن، بدون جدول CRUD قياسي أو مسار مرحلة مفرد.

---

## 🎨 Button Color Palette Matrix (مصفوفة ألوان الأزرار الإلزامية)

> **قاعدة حتمية:** يُحظر تماماً تعيين ألوان الأزرار عشوائياً. يجب الالتزام الصارم بالمصفوفة التالية لكل زرار في النظام:

| الغرض والوظيفة (Purpose) | اللون المعتمد (Color) | مثال عملي (Example) | النمط (Style) |
|---|---|---|---|
| **الإجراء الرئيسي للشاشة (Primary Action)** | أزرق مصمت (`AppTheme.cobalt`) | `Add New Import File`, `Upload Import Document` | `ElevatedButton` / `AppButtonVariant.primary` |
| **إجراء ثانوي هام (Secondary Action)** | أزرق محدد بإطار (`Blue outline / white bg`) | `Search & Clone Shipment`, `Back to Dashboard` | `OutlinedButton` / `AppButtonVariant.outline` |
| **إجراء خدمي حيادي (Neutral Utility Action)** | كحلي داكن مصمت (`AppTheme.charcoal`) | `Generate Report`, أيقونات التحديث والأدوات | `AppTheme.charcoal` / رمادي داكن |
| **ميزات الذكاء الاصطناعي (AI Feature)** | أخضر زمردي مصمت مع أيقونة بريق (`AppTheme.emerald` + Sparkle Icon) | `Smart Invoice & B/L Extractor`, `AI Suggestion` | `AppTheme.emerald` + `Icons.auto_awesome` |
| **إجراء مدمر أو إيقاف (Destructive / Stop Action)** | أحمر قرمزي مصمت (`AppTheme.crimson`) | `Stop Shipment at this Stage`, `Delete Record` | `AppButtonVariant.danger` / أحمر مصمت |
| **تحذير أو تخطي مرحلة (Warning / Skip Action)** | برتقالي محدد بإطار (`Orange outline`) | `Skip Step`, `Revert Action` | `AppTheme.orange` Outlined |
| **تصدير إلى إكسل (Export to Excel)** | أخضر مصمت (`AppTheme.emerald` / `Colors.green.shade700`) | `Export Excel`, `Export CSV` | `Icons.table_chart` + أخضر |
| **تصدير إلى بي دي إف (Export to PDF)** | أحمر بي دي إف قياسي (`AppTheme.crimson` / `Colors.red.shade700`) | `Export PDF`, `Print PDF` | `Icons.picture_as_pdf` + أحمر |

> ⚠️ **تنبيه:** إذا كان هناك إجراء جديد لا يندرج بوضوح تحت هذه الفئات، يجب الاستفسار وتوضيحه وتصنيفه، ويُحظر تماماً ابتكار ألوان عشوائية جديدة.

---

## 📐 Density Control Placement Rule (موقع ومحدد كثافة العرض)

1. **إعداد عام مركزي فقط (Global Persistent Setting):**
   * التحكم في كثافة العرض (`Comfortable` / `Compact` / `Ultra-Compact`) هو إعداد عام يخص تجربة المستخدم على مستوى التطبيق بالكامل.
   * يجب أن يتواجد في **مكان مركزي واحد فقط** (مثل قائمة الإعدادات العلوية أو شريط أدوات النافذة أو قائمة المستخدم)، **ولا يجوز أبداً وضعه كزر منفرد داخل صف إجراءات البيانات (Data Actions Row) في كل شاشة**.
   * ظهوره داخل شاشة معينة (مثل شاشة ملفات الاستيراد `ImportFilesScreen`) يُعتبر **خطأ تكرار وتعارض (Duplication Bug)** ويجب حذفه من الشاشة وتوحيده مركزياً.
2. **عزل التراكب ومنع تغطية الجداول:**
   * يجب ألا تظهر أي قائمة منسدلة أو نافذة منبثقة تابعة لكثافة العرض أو غيرها فوق بيانات الجدول بدون خلفية مصمتة عازلة (`solid background`) ومستوى طبقي صحيح (`proper z-index / elevation`).

---

## 🪟 General Overlay & Popover Rules (قواعد النوافذ المنبثقة وحظر التداخل الشامل)

> **قاعدة حظر التداخل الشامل ومنع تصادم العناصر العائمة (Universal Anti-Overlap & Collision Avoidance Rule):**
> يُحظر حظراً تاماً على أي عنصر عائم (ودجت المساعد الذكي/الدعم، القوائم المنبثقة، القوائم المنسدلة، التلميحات، إشعارات التوست) أن يعلو أو يحجب بيانات الجداول أو نماذج الإدخال أو أزرار الإجراءات:
1. **التموضع أسفل الزرار المنشط حصراً (`Strictly Under Trigger`):** يجب ضبط `position: PopupMenuPosition.under` حتى لا تقفز القائمة وتغطي العنصر نفسه أو الترويسة.
2. **المحاذاة الذكية ومنع حجب أزرار التنقل (Smart Collision Flip):** إذا كان فتح القائمة للأسفل والمحاذاة الطبيعية سيؤدي إلى حجب أو قص زر العودة للرئيسية (`Back to Dashboard`) أو أي عنصر تحكم ملاصق، يجب محاذاة القائمة إلى اليمين والامتداد نحو **اليسار** (Right-aligned to trigger, extending leftward into empty header space) بدلاً من التمدد يميناً فوق عناصر التحكم.
3. **حظر حجب عنوان الشاشة وأزرار التنقل:** يُحظر تماماً أن تغطي أي نافذة منبثقة عنوان الشاشة أو أزرار التنقل الرئيسية.
4. **تقييد الحدود الرأسية (Explicit Bounding Box):** يجب تقييد الارتفاع بحيث لا تغطي القائمة أكثر من سطر أدوات واحد رأسياً، مع توفير سكرول داخلي عند كثرة العناصر.
5. **الخلفية المصمتة والارتفاع الطبقي (Solid Background & Elevation):** خلفية مصمتة غير شفافة بـ `elevation: 6` وحواف دائرية `BorderRadius.circular(8)` لمنع تسرب العناصر الخلفية.
6. **الدك الجانبي لودجت المساعد والدعم (Chat/Support Side Docking on Desktop >= 1200px):**
   - في وضع الطي، يستقر الزر في زاوية الشاشة السفلية مع توفير هامش أمان إضافي `+ 72px` لنهاية الجداول لمنع حجب البيانات.
   - عند التوسيع على سطح المكتب (Desktop >= 1200px)، يُدك في شريط جانبي ثابت (`AiAssistantDockedPanel` بعرض 410px أو 560px) داخل الـ `Row` الرئيسي للتطبيق لتقليص مساحة المحتوى (`Expanded`) ومنع تغطية الجداول إطلاقاً.
   - على الشاشات الأصغر (< 1200px)، يفتح كنافذة مشروطة مع غطاء تعتيم خلفي (`ModalBarrier`).
7. **الانهيار التلقائي لفقاعة الترحيب (Greeting Bubble Auto-Collapse):**
   - تنهار تلقائياً بعد 7 ثوانٍ، أو فورياً عند أي تمرير (Scroll) في أي جدول، أو بالنقر على زر الإغلاق (X).
8. **الاختبار الإلزامي على شاشة 1366x768:** التأكد عملياً من فتح كافة القوائم المنبثقة دون أي حجب لأزرار الترويسة على هذه الدقة.

---

## 🧱 Component Consolidation & Global Density Wiring (توحيد المكونات المشتركة والربط الشامل للكثافة)

> **قاعدة حتمية معمارية:** يُحظر تماماً كتابة كود محلي (Ad-hoc) للترويسة أو شريط الأدوات أو بطاقات المقاييس داخل أي شاشة. يجب استخدام المكونات المشتركة الموحدة حصرياً من `frontend/lib/core/widgets/`:

1. **ترويسة الصفحة الموحدة (`PageHeader`):**
   * تُستخدم حصرياً في شاشات القوائم (Type B) والشاشات الخدمية (Type C) عبر `appBar: PageHeader(...)`.
   * ارتفاع ثابت موحد (`54px` بدون عنوان فرعي، `58px` مع عنوان فرعي) يمنع التمدد الرأسي نهائياً.
   * خلفية كحلية مصمتة داكنة (`AppTheme.charcoal`) بدلاً من التدرجات الضخمة (Gradient Banners).
   * صف أفقي موحد (`Row`) يوزع العنوان والأيقونة يساراً وأزرار الإجراءات يميناً، مع عزل أزرار إنشاء واستنساخ السجلات ونقلها لشريط الأدوات منعاً لحجب زر العودة `Back to Dashboard`.

2. **شريط الأدوات الموحد المدمج (`ActionToolbar`):**
   * صف أفقي مدمج واحد مباشرة فوق الجداول بارتفاع أقصى `30-40px` حسب الكثافة.
   * يدمج بحد أقصى 3 أزرار رئيسية مرئية مصمتة/مفرغة، وقائمة `More actions ⋮` للأدوات الإضافية، وحقل البحث السريع (عرض `180-210px`)، وقوائم التصفية `SearchableDropdownField` (عرض `100-125px`)، وأيقونات البيانات السريعة المدمجة `32x32px` (تحديث، إكسل، بي دي إف).
   * يعتمد على التمرير الأفقي الآمن الداخلي (`SingleChildScrollView` أفقي بدون أشرطة تمرير ظاهرة) مع `MainAxisAlignment.spaceBetween` لضمان عدم حدوث أي تجاوز أو خطأ في المحاذاة (`RenderFlex overflow`) على الشاشات من دقة `1024px` وحتى الشاشات العريضة.

3. **شريط المؤشرات المدمج الموحد (`MetricCard` / `MetricCardStrip`):**
   * **شريط موحد بسطر واحد (Single-Row Strip):** عرض كافة المؤشرات جنباً إلى جنب في سطر واحد داخل حاوية موحدة ذات إطار خفيف وفواصل رأسية بين المؤشرات (`VerticalDivider`) بدلاً من شبكة 2×2 من البطاقات المنفصلة.
   * **التخطيط المضمن (`[icon] Title: Value`):** أيقونة صغيرة (16-18px) بلون المؤشر مباشرة، يليها العنوان ثم القيمة البارزة في سطر واحد.
   * **التكيف مع الكثافة:** يتقلص ارتفاع الشريط الموحد آلياً عبر `density.metricCardHeight` من `42px` (الوضع المريح) إلى `34px` (الوضع المدمج) و `28px` (الوضع فائق الكثافة).
   * **التسميات المختصرة الإلزامية وعدم قص القيم (Short Labels & Value Preservation):**
     - يُحظر تماماً قطع التسميات بنقاط الحذف (`Total PI/PO Am...`).
     - يجب تحديد صيغة مختصرة لكل مؤشر (`POs`، `PI/PO Amt`، `CBM`، `Gross Wt`).
     - تُفعل الصيغ المختصرة في أوضاع `Compact` و `Ultra-Compact` أو عند ضيق العرض المتاح (<660px).
     - القيمة الرقمية (`$126294.00`) لا تُقتطع ولا تُحذف مطلقاً.
   * **ترتيب العناصر المستهدف:** 1. الترويسة (`PageHeader`) ← 2. شريط المؤشرات (`MetricCardStrip`) ← 3. شريط الأدوات (`ActionToolbar`) ← 4. جدول البيانات (`DataTable`).
   * **الالتفاف الذكي لصفين عند ضيق المساحة (2-Row Responsive Wrap):** يُحظر التمرير الأفقي للشريط؛ وعند ضيق المساحة (<660px) يلتف الشريط تلقائياً إلى صفين متناسقين (مؤشران لكل صف) بدلاً من قص أو تشويه النصوص.

4. **الربط الشامل والفعلي للكثافة (Full Global Density Wiring):**
   * كافة عناصر الشاشات (ترويسات، أزرار، حقول بحث، بطاقات، صفوف الجداول، حشوات) تستمع لحظياً وتستجيب لـ `ref.watch(displayDensityProvider)`.
   * تغيير وضع الكثافة إلى فائق الكثافة (`Ultra-Compact`) يُقلص ارتفاع الترويسة والأزرار والبطاقات والجداول معاً بنسب موحدة ومتناغمة في كل النظام.

5. **مصفوفة التدرج الطباعي حسب الكثافة وقاعدة الحد الأدنى 11 بكسل (Typography Scale per Density Level & 11px Floor Rule):**
   * **مصفوفة أحجام الخطوط الإلزامية:**
     - **عنوان الصفحة (`Page title`):** Comfortable: 20px | Compact: 17px | Ultra-Compact: 15px (`density.headerTitleFontSize`).
     - **العنوان الفرعي (`Page subtitle`):** Comfortable: 13px | Compact: 12px | Ultra-Compact: 11px (`density.headerSubtitleFontSize`).
     - **شريط المؤشرات (`Metric strip label + value`):** Comfortable: 14px | Compact: 13px | Ultra-Compact: 12px (`density.metricTitleFontSize` / `metricValueFontSize`).
     - **نصوص أزرار شريط الأدوات (`Button text`):** Comfortable: 13px | Compact: 12px | Ultra-Compact: 12px (`density.buttonFontSize`).
     - **ترويسة الجدول (`Table header row`):** Comfortable: 13px | Compact: 12px | Ultra-Compact: 12px (`density.tableHeaderFontSize`).
     - **نصوص خلايا الجدول الأساسية (`Table cell primary`):** Comfortable: 14px | Compact: 13px | Ultra-Compact: 12px (`density.tableCellPrimaryFontSize`).
     - **نصوص خلايا الجدول الثانوية والرموز (`Table cell secondary`):** Comfortable: 12px | Compact: 11px | Ultra-Compact: 11px (`density.tableCellSecondaryFontSize`).
     - **حقول البحث وقوائم التصفية (`Search & Filter inputs`):** Comfortable: 13px | Compact: 12px | Ultra-Compact: 12px (`density.inputFontSize`).
     - **عناصر القائمة الجانبية (`Sidebar nav items`):** Comfortable: 13px | Compact: 13px | Ultra-Compact: 12px (`density.sidebarNavFontSize`).
   * **قاعدة الحد الأدنى الإلزامية 11 بكسل (Strict 11px Floor Rule):** يُحظر تماماً وجود أي نص في النظام بحجم أقل من 11px. يتم تطبيق `DisplayDensityMode.clampFontSize(size)` لحماية كافة الشارات والأختام والملاحظات المساعدة من النزول تحت 11 بكسل.
   * **التدرج الهرمي (Scale, Don't Flatten):** الحفاظ على التسلسل البصري: عنوان الصفحة أكبر من خلايا الجدول، وخلايا الجدول الأساسية أكبر من أو تساوي النصوص الثانوية. يُمنع تحويل كل شيء إلى 12px.
   * **تدرج الأيقونات المحافظ (Conservative Icon Scaling):**
     - أزرار شريط الأدوات: 16px ← 15px ← 14px (`density.buttonIconSize`).
     - شريط المؤشرات: 17px ← 15.5px ← 14px (`density.metricIconSize`).
     - ترويسة الصفحة: 22px ← 20px ← 18px (`density.headerIconSize`).

---

## 1. 📐 Screen Anatomy — هيكل كل شاشة

```
┌────────────────────────────────────────────────────────────────────────┐
│  ZONE A — Header & Action Bar (أول سطر في الشاشة)                      │
│  [Icon + Title + Stage Badge]  [Skip] [Stop] [Clone] [AI] [🔄] [← Dash] │
├──────────────┬─────────────────────────────────────────────────────────┤
│  ZONE B      │  ZONE C — Main Content Area                             │
│  Sidebar     │  ┌─────────────────────────────────────────────────┐   │
│  Nav         │  │ Toolbar: [🔄 Refresh] [📥 Excel] [📄 PDF]        │   │
│  (Stages /   │  ├─────────────────────────────────────────────────┤   │
│   Steps)     │  │ Cards / Body: [PDF] [Excel] [Print] [Save Draft]│   │
│              │  └─────────────────────────────────────────────────┘   │
└──────────────┴─────────────────────────────────────────────────────────┘
```

---

## 2. 🏗️ Zone A — Page Header & Action Bar

> **الـ Widget الجاهز:** `VerticalStageScaffold` → يتولى الـ Header والـ Lifecycle تلقائيًا.

### أ. عناصر الـ Page Header الإلزامية:
- **Icon:** أيقونة المرحلة أو الشاشة.
- **Page Title:** عنوان الشاشة باللغة الإنجليزية وبصيغة Title Case (مثل: `Customs Clearance Details`).
- **Stage Badge:** شارة المرحلة بصيغة كودية موحدة (مثل: `PHASE-3` أو `STAGE_CUSTOMS`).
- **Header Color:** لون موحد للـ Header من `AppTheme` عبر كافة الشاشات (افتراضي `AppTheme.charcoal` أو `AppTheme.cobalt`).

### ب. شريط الإجراءات العلوي — الترتيب الإلزامي الصارم (Action Bar Order):
يجب الالتزام بالترتيب التالي حرفياً من اليسار لليمين (أو بترتيب الـ Action Bar في أقصى اليمين):

| # | العنصر | النمط / الـ Widget | متى يظهر |
|---|--------|-------------------|----------|
| 1 | ⏭ **Skip Step** | Outline Style (`AppButtonVariant.outline` / `ShipmentStageLifecycleControl`) | شاشات المراحل |
| 2 | 🛑 **Stop Shipment at this Stage** | Filled Danger Style (`AppButtonVariant.danger` / `ShipmentStageLifecycleControl`) | شاشات المراحل |
| 3 | 📋 **Duplicate / Clone icon** | `IconButton(icon: Icon(Icons.copy_rounded))` | عند انطباقه على الشاشة |
| 4 | 🤖 **AI Assistant** | Contextual Action / Assistant Button | عند انطباقه |
| 5 | 🔄 **Live Refresh icon** | `IconButton(icon: Icon(Icons.refresh))` | **إلزامي في كل الشاشات** |
| 6 | ← **Back to Dashboard** | `BackToDashboardButton()` | **دايمًا آخر زرار إلزامي** |

### مثال الكود:
```dart
VerticalStageScaffold(
  stageCode: 'PHASE-3: DRAFT_DOCUMENTS',
  titleAr: 'مراجعة مسودات المستندات',
  titleEn: 'Shipment Draft Documents Review',
  headerIcon: Icons.description_outlined,
  headerColor: AppTheme.cobalt,
  selectedImportFileId: importFileId,
  showStageLifecycleControls: true,  // ← Skip Step + Stop Shipment تلقائياً
  onShipmentStatusChanged: () => ref.invalidate(provider),
  headerActions: [
    // 3. Clone (إن وجد)
    IconButton(
      icon: const Icon(Icons.copy_rounded),
      tooltip: 'Duplicate / Clone',
      onPressed: () => _handleClone(),
    ),
    // 4. AI contextual action (إن وجد)
    // 5. Refresh icon (دايمًا)
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh',
      onPressed: () => ref.invalidate(provider),
    ),
    // 6. Back to Dashboard (دايمًا آخر زرار)
    const BackToDashboardButton(),
  ],
  tabs: [...],
  selectedIndex: _tab,
  onTabSelected: (i) => setState(() => _tab = i),
  body: _buildBody(),
)
```

---

## 3. 📑 Zone B — Sidebar Navigation

> **الـ Widget الجاهز:** `AdaptiveTabScaffold` أو `VerticalStageScaffold` (tabs)

### هيكل الـ Sidebar:
1. **Left Sidebar (Module-Level Nav):** شريط "Operations & Stages" للتنقل بين المراحل والعمليات الرئيسية.
2. **Sub-Sidebar (Screen Steps Nav):** تابات مرقمة (Numbered Tabs) للخطوات التفصيلية داخل نفس الشاشة.

### قواعد التبديل التلقائي للـ Tabs:
```text
< 4 tabs  → Horizontal TabBar (افتراضي للشاشات البسيطة)
≥ 4 tabs  → Vertical Sidebar تلقائي (عبر AdaptiveTabScaffold)
ضيق جداً → Dropdown selector تلقائي في الشاشات الصغيرة
```

---

## 4. 🔧 Zone C — Toolbar & Content Actions

### أ. للشاشات القائمة على بيانات (Lists / Tables):
> **الـ Widget الجاهز:** `MasterDataToolbarWidget`

```dart
MasterDataToolbarWidget(
  moduleEndpoint: 'your-module',   // e.g. 'suppliers'
  title: context.l10n.screenTitle,
  onRefreshNeeded: () => ref.invalidate(yourProvider),
  // onExportExcel → تلقائي (endpoint/export-excel)
  // onExportPdf   → تلقائي (endpoint/export-pdf)
  onImportExcel: () => ...,        // اختياري
  extraTrailing: yourExtraButton,  // اختياري
)
```

### ب. للشاشات القائمة على نماذج (Forms / Edit Dialogs):
> **الـ Widget الجاهز:** `StandardFormActionBar`

```dart
StandardFormActionBar(
  onRefresh: () => _reload(),         // 🔄 Live Refresh
  onSaveDraft: () => _saveDraft(),    // 💾 حفظ مؤقت (إلزامي لأي Form)
  onResetForm: () => _reset(),        // 🧹 إعادة تعيين (اختياري)
  onSubmit: () => _submit(),          // ✅ حفظ نهائي
  onClose: () => Navigator.pop(ctx),  // ✕ إغلاق
  isSaving: _isSaving,
  isEditing: isEditMode,
)
```

### ج. إجراءات المستندات داخل كروت المحتوى (Document Actions inside Content Cards):
في كروت المحتوى التي تحتوي على مستندات أو مخرجات قابلة للتصدير:
- 📄 **Download PDF:** تصدير PDF (`AppButtonVariant.primary` / cobalt)
- 📊 **Download Excel:** تصدير إكسيل (`AppButtonVariant.success` / emerald)
- 🖨️ **Print:** طباعة مباشرة (`IconButton` أو `AppButtonVariant.secondary`)
- 💾 **Save Draft (حفظ مؤقت):** إلزامي في **أي شاشة نموذج (Form) أو قابلة للتحرير (Editable Screen)** وليس فقط شاشات المراجعة (قاعدة GP-001)

> **قواعد التصدير والحفظ الموحد (Task I):**
> 1. كافة أزرار التحميل والتصدير تستخدم حصرياً `FileSaveHelper.exportAndSaveFile(bytes: ..., fileName: ..., mimeType: ...)` لتفعيل نافذة Save As التفاعلية على Desktop و Web (مع تمرير `bytes` صراحة).
> 2. تسمية الملفات الموحدة إجبارية عبر `FileSaveHelper.buildExportFileName`: `[Stage Name] - [Import File Name or Code].[extension]`.
> 3. أزرار PDF / Excel تظهر فقط عند وجود مستند فعلي للتصدير. لا تضع أزرار تصدير وهمية في شاشات لا تحتوي على مستندات.

---

## 5. 🌐 Language & Casing Rules — قواعد اللغة وحالة الأحرف

### قواعد حالة الأحرف (Title Case إلزامي):
- **يجب استخدام Title Case** لجميع أزرار الواجهة والعناوين وشارات المراحل:
  - ✅ `Skip Step` (وليس `skip step` أو `SKIP STEP`)
  - ✅ `Stop Shipment at this Stage`
  - ✅ `Save Draft`
  - ✅ `Download Excel`
  - ✅ `Back to Dashboard`

### قواعد اللغة والترجمة:
- ✅ جميع الـ Labels في كود الواجهة مكتوبة بالإنجليزية وتُستدعى عبر `context.l10n`.
- ❌ **أي نصوص عربية Hard-coded داخل ملفات UI تُعتبر Bug ومخالفة صريحة (Violation)** يجب رصدها في الـ Audit وإصلاحها.
- ❌ يُمنع تماماً خلط اللغتين (Mixed Language) داخل الـ Label الواحد (مثل: "Save حفظ" أو "Export إكسيل").

### قاعدة RTL:
```text
✅ AppTheme يدعم RTL تلقائياً — لا تتدخل يدوياً
✅ Directionality يُعيَّن مرة واحدة في المشروع
❌ لا تضبط TextDirection يدوياً في كل Widget
```

---

## 6. 🎨 Color & Styling Rules

```dart
// ✅ دايمًا من AppTheme — Single Source of Truth
AppTheme.cobalt      // #3498DB → Primary / Download PDF
AppTheme.emerald     // #27AE60 → Success / Export Excel / Save
AppTheme.crimson     // #C0392B → Danger / Stop / Delete
AppTheme.orange      // #E67E22 → Warning / Skip Step
AppTheme.charcoal    // #2C3E50 → Header Bar Background
AppTheme.cloudWhite  // #ECF0F1 → Page Background

// ✅ الأزرار دايمًا بـ AppButton
AppButton(
  label: context.l10n.exportExcel,
  variant: AppButtonVariant.success,
  size: AppButtonSize.small,
  icon: Icons.description,
  isLoading: _isLoading,
  onPressed: _onExport,
)

// ❌ ممنوع
Color(0xFF3498DB)              // Hard-coded hex
Colors.blue / Colors.red       // Material colors
ElevatedButton.styleFrom(...)  // Manual styling
OutlinedButton.styleFrom(...)  // Manual styling
```

---

## 7. 📋 Searchable Dropdown / Combobox — Reusable Component Spec

> **الـ Widget الموحد:** `SearchableDropdownField<T>` (`frontend/lib/core/widgets/searchable_dropdown_field.dart`)
> يُستخدم هذا النمط حصرياً لأي حقل اختيار يسحب خياراته من جدول قاعدة بيانات أو API (مثل: Import File, Supplier, Customer, Warehouse, Country, Port, Currency, Bank, Partner, HS Code, PO).
> ❌ يُمنع تماماً استخدام `<select>` عادي أو `DropdownButtonFormField` أو حقول نصية حرة `TextField` لهذه الحقول.

### أ. متى ينطبق هذا المعيار (When this applies):
- أي قائمة منسدلة تأتي خياراتها من جدول داتابيز أو API (وليس enum ثابت صغير جداً مثل "Yes/No" أو حالة "Active/Inactive").
- أي قائمة يمكن أن تتجاوز منطقياً 8 إلى 10 عناصر.

### ب. السلوك والمواصفات التفصيلية (Component Behavior):
1. **طريقة الفتح (Trigger):**
   - النقر على الحقل يفتح نافذة منبثقة تفاعلية (Modal / Popover Dialog) تحتوي على ترويسة + شريط بحث + قائمة قابلة للتمرير (وليس مجرد قائمة منسدلة داخلية تنفتح للأسفل).
2. **الترويسة (Header):**
   - عنوان النافذة يوضح الغرض من الحقل بالصيغة الثنائية الموحدة:
     `[Field Label in English] ([Arabic label between parentheses])`
     مثال: `Import File (ملف الشحنة الاستيرادية)` أو `Foreign Supplier (المورد الأجنبي)`.
   - أيقونة إغلاق (X) في أعلى يمين/يسار النافذة.
3. **شريط البحث الفوري (Search Bar):**
   - دائماً العنصر الأول داخل المودال، بعرض كامل (Full width) مع أيقونة بحث وأيقونة مسح (Clear X).
   - نص تلميح البحث (Placeholder) يتطابق مع لغة الشاشة الحالية (بالعربية إذا كانت الشاشة عربية، بالإنجليزية إذا كانت إنجليزية).
   - البحث فوري وتفاعلي أثناء الكتابة (Filter-as-you-type) دون اشتراط الضغط على Enter.
   - البحث يطابق الحقول التعريفية المركبة للسجل (`searchValue`: الكود، الاسم، المشروع، الـ UN/LOCODE) وليس فقط العمود الأول.
4. **قائمة الخيارات (Options List):**
   - كل خيار يمثل سطراً مستقلاً مسحوباً حياً من الجدول/الـ API المرتبط.
   - **التسمية المركبة (Composite Label):** إذا كانت البيانات تحتوي على كود + اسم + سياق (مثل: `PET Stock -YH20260901-3 (IMP-2026-0005) - SCAS For Construction`)، تُعرض في سطر واضح وقابل للالتفاف إلى سطر ثانٍ بدلاً من القص الصامت للنص.
   - **خيار الإلغاء والتفريغ:** خيار `-- None / لا يوجد --` يظهر دائماً في بداية القائمة (خارج نتائج الفلترة) عندما يكون الحقل اختيارياً (Clearable/Optional).
   - **تمييز العنصر المختار:** تظليل السجل المختار حالياً بخلفية ملونة هادئة (`AppTheme.cobalt.withOpacity(0.08)`) مع أيقونة علامة صح (Checkmark) على الطرف.
   - خط فاصل رفيع (`Divider`) بين كل سطر والآخر بدون كروت أو ظلال لكل سطر.
5. **حالات التحميل والفراغ (Empty & Loading States):**
   - مؤشر تحميل خفيف أثناء جلب البيانات من الـ API.
   - حالة "لا توجد نتائج" واضحة ومصممة عند عدم مطابقة البحث (`Icons.search_off` مع نص توضيحي).
6. **سلوك الاختيار (Selection Behavior):**
   - اختيار أي عنصر يغلق المودال فوراً ويملأ الحقل بالقيمة.
   - اختيار "None / لا يوجد" يفرغ الحقل إلى `null` (في الحقول الاختيارية).

### ج. ما لا يجوز تغييره لكل شاشة (What NOT to change per screen):
- هيكل المودال، موقع شريط البحث، نمط التمييز، وخيار "None" كلها ثابتة وموحدة في الـ Core Component.
- فقط عنوان الحقل، ومصدر البيانات المرتبط، والأعمدة المبحوث فيها هي التي تتغير حسب الاستخدام.

### د. مثال الاستخدام القياسي:
```dart
SearchableDropdownField<int?>(
  value: _selectedSupplierId,
  items: suppliers.map((s) => SearchableDropdownItem<int?>(
    value: s.supplierId,
    label: '${s.companyName} (${s.supplierCode})',
    searchValue: '${s.companyName} ${s.supplierCode} ${s.countryName ?? ''}',
    subtitle: s.countryName,
  )).toList(),
  labelText: 'Foreign Supplier (المورد الأجنبي)',
  hintText: context.l10n.selectSupplierHint,
  onChanged: (val) => setState(() => _selectedSupplierId = val),
)
```

---

## 8. ♻️ Auto-Refresh — التحديث التلقائي

```dart
// بعد كل عملية (Add / Edit / Delete / Status Change):
ref.invalidate(yourProvider);  // ← إلزامي دايمًا

// عند فتح الشاشة في initState:
@override
void initState() {
  super.initState();
  Future.microtask(() => ref.invalidate(yourProvider));
}

// أثناء العمليات Async — مؤشر تحميل إلزامي:
AppButton(
  isLoading: _isSaving,  // ← يمنع الضغط المتكرر
  onPressed: _isSaving ? null : _save,
)
```

---

## 9. 🚫 Anti-Patterns — ممنوع في أي شاشة

```text
❌ AppBar عادي بدلاً من VerticalStageScaffold Header
❌ TabBar أفقي عند عدد tabs ≥ 4
❌ Text عربي/إنجليزي Hard-coded بدلاً من l10n
❌ ElevatedButton / OutlinedButton بدلاً من AppButton
❌ Colors.xxx أو Color(0xFF...) بدلاً من AppTheme
❌ إنشاء Download/Export logic خاص بدلاً من MasterDataToolbarWidget
❌ إنشاء Save Draft/Submit بدلاً من StandardFormActionBar
❌ DropdownButtonFormField بدلاً من SearchableDropdownField
❌ شاشة Stage بدون Back to Dashboard button
❌ شاشة Stage بدون showStageLifecycleControls: true
❌ بيانات Stale Cache عند فتح الشاشة (لا initState refresh)
❌ زرار بدون isLoading أثناء عملية Async
```

---

---

## 10. 📊 Data Table UX Standards — معايير تجربة جداول البيانات

> **القاعدة:** كل جدول بيانات في النظام (PO Line Items, Packing List, Registries, إلخ) يجب أن يوفر تجربة تصفح احترافية تتناسب مع كثرة السجلات والأعمدة.

### أ. Sticky Header (الترويسة الثابتة أثناء التمرير الرأسي):
- يجب أن تظل ترويسة الجدول مرئية أثناء التمرير الرأسي للسجلات (`position: sticky` أو عبر حاوية تمرير مستقلة `SingleChildScrollView`).
- خلفية الترويسة يجب أن تكون مصمتة وثابتة بلون `AppTheme.darkSurface` في الوضع الداكن أو رمادي محايد (`AppTheme.charcoal.withOpacity(0.06)`) في الوضع الفاتح لمنع تداخل أرقام ونصوص الصفوف مع العناوين أثناء السكرول.
- يجب وجود حد سفلي رفيع أو ظل خفيف تحت الترويسة لتوضيح الفصل البصري.

### ب. Sticky Actions / Selection Column (تثبيت عمود الإجراءات/التحديد):
- في الجداول التي تدعم التمرير الأفقي (Horizontal Scroll):
  - يجب تثبيت عمود الاختيار (Checkbox) وعمود الإجراءات (Actions) على الطرف بحيث تظل أيقونات التعديل والنسخ والحذف مرئية ومتاحة دون الحاجة للتمرير لآخر الجدول.

### ج. استقلالية حاويات التمرير (Independent Scroll Containers):
- يجب ألا يعتمد الجدول أو النموذج على ارتفاع الصفحة بالكامل (`full-page height`).
- كل جدول يحصل على حاوية تمرير رأسية وأفقية مستقلة مع شريط تمرير واضح (`Scrollbar` تفاعلي)، بحيث يظل الهيدر وشريط التبويبات العلوي ثابتين تماماً.

---

## 11. 🖥️ Responsive Breakpoints & Display Density — التجاوب وكثافة العرض

> **الهدف:** توفير تجربة استخدام مثالية على شاشات سطح المكتب واللابتوب والتابلت في بيئة الـ ERP مع منع كسر التجاوب.

### أ. نقاط التوقف المعتمدة (Target Breakpoints):
- **Desktop / Laptop (الحد الأدنى المدعوم):** $1366 \times 768\text{px}$
- **Tablet Landscape:** $1366 \times 1024\text{px}$
- **Large Desktop / Monitor:** $\ge 1440\text{px}$
- **Mobile / Narrow Viewports:** $< 768\text{px}$ (يتحول الجدول تلقائياً لكروت متراصة `Card List`).

### ب. دعم مستويات كثافة العرض (Display Density):
- تدعم واجهات النظام 3 مستويات للكثافة دون الاعتماد على تكبير المتصفح (Browser Zoom):
  1. **Comfortable (مريح):** ارتفاع السطر 52px، الحشوات 16px (الافتراضي).
  2. **Compact (مدمج):** ارتفاع السطر 44px، الحشوات 10px.
  3. **Ultra Compact (فائق الضغط):** ارتفاع السطر 36px، الحشوات 6px (للشاشات كثيفة البيانات).
- يجب تجنب القيم الثابتة بالبكسل (`fixed px`) في الارتفاعات الإجمالية ومربعات النصوص التي تمنع ضبط الـ Density.

---

## 12. 📋 Row Clone / Duplicate — Reusable Feature Spec (Task E)

> **القاعدة:** يُستخدم هذا المعيار لأي قسم يحتوي على بنود أو صفوف متكررة يتم إدخالها يدوياً (مثل: بنود أمر الشراء PO Line Items، أسطر قائمة التعبئة Packing List Entries، بنود الفواتير التجارية Invoice Lines، بنود الفحص والمعاينة Inspection Items، بنود شهادة المنشأ COO items، إلخ).
> **الهدف:** تقليل الإدخال المتكرر للبيانات بالسماح للمستخدم بتكرار بند موجود والتعديل عليه بدلاً من ملء بند فارغ من الصفر.

### أ. متى ينطبق (When this applies):
- الصفوف تضاف ديناميكياً (يوجد زر "إضافة بند / Add Item" أو أيقونة `+`).
- تشترك الصفوف في نفس الهيكل والحقول تقريباً.
- يقوم المستخدم عادةً بإدخال عدة صفوف متتالية تختلف فقط في حقل أو حقلين (مثل نفس الصنف مع اختلاف الكمية أو الأوزان أو الأبعاد).

### ب. السلوك والتنفيذ المعتمد (Behavior & UX Standards):

1. **أيقونة التكرار (Clone Icon):**
   - يحصل كل صف على أيقونة نسخ/تكرار مخصصة توضع مباشرة بجوار أيقونة الحذف (`–` / `Delete`) في نفس الترتيب والموقع بكل الجداول:
     `[... row fields ...] [Copy icon] [Remove icon]`
   - الأيقونة موحدة عبر النظام (`Icons.copy_rounded`) وبنفس حجم ونمط أيقونة الحذف.
   - التلميح عند التحويم (Tooltip): `"Duplicate this row (تكرار هذا البند)"`.

2. **موقع الصف المكرر (Position of Cloned Row):**
   - يُدرج الصف المكرر **مباشرة تحت الصف الأصلي المنسوخ منه** (عند `index + 1`)، ويُمنع منعاً باتاً إضافته في نهاية القائمة.
   - **السبب:** إذا كان المستخدم يكرر السطر 2 من أصل 15 سطراً، فإن ظهوره في السطر 16 يشتت السياق؛ المتوقع ظهوره ملاصقاً للسطر المصدر فوراً.

3. **البيانات المنسوخة والمستثناة (Data Copied vs Excluded):**
   - **يتم نسخ جميع قيم الحقول المدخلة:**
     - النصوص الحرة (الوصف Description، رقم القطعة Part No، الأبعاد Dimensions، إلخ).
     - القوائم المنسدلة (نوع الطرد Package Type، وحدة القياس UOM، بند التعريفة HS Code، إلخ).
     - الحقول الرقمية (الكمية Qty، سعر الوحدة Unit Price، الوزن Weight، الحجم CBM، إلخ).
   - **الاستثناء الحتمي:** المعرفات الفريدة الداخلية المولدة من النظام (`item_id` أو `row_id` الفريد) **لا يتم نسخها نهائياً** — يتم تعيين معرف فريد جديد أو تركه فارغاً ليتم إنشاؤه عند الحفظ في قاعدة البيانات.
   - **الترقيم التسلسلي:** إذا كان الجدول يحتوي على رقم تسلسلي مرئي للمستخدم (`# 1`, `# 2`, ...)، تتم إعادة ترقيم القائمة بالكامل تلقائياً وبشكل نظيف بعد عملية الإدراج.

4. **التركيز البصري بعد النسخ (UI Focus & Highlighting):**
   - بعد التكرار مباشرة، ينتقل التركيز التلقائي (`FocusScope`) إلى أول حقل قابل للتعديل في الصف الجديد (أو حقل الكمية إذا كان الحقل الأكثر تغييراً).
   - وميض أو تمييز لوني خفيف ومؤقت (`subtle highlight flash / border color`) على الصف الجديد ليرى المستخدم أين ظهر الصف المنسوخ بدقة.

5. **التحقق وإعادة حساب الإجماليات (Validation & Instant Recompute):**
   - يخضع الصف الجديد لنفس قواعد الـ Validation بدقة كأي صف آخر (لا تجاوز للقواعد).
   - يعاد احتساب كافة المجاميع الإجمالية المعروضة (إجمالي الكميات، الوزن الإجمالي، إجمالي CBM، إجمالي قيمة أمر الشراء أو الفاتورة) **فورياً ولحظياً** بمجرد الضغط على زر التكرار دون الحاجة لحفظ أو إعادة تحميل.

### ج. ثبات التجربة (Consistency Invariant):
- إذا كانت الشاشة أ تحتوي على 10 صفوف والشاشة ب تحتوي على 5 صفوف، فإن أيقونة التكرار متطابقة شكلاً، تقع في نفس المكان نسبة لزر الحذف، تدرج الصف عند `index + 1`، وتعيد حساب الإجماليات فوراً.
- المستخدم الذي يتعلم التكرار في PO Line Items يجب أن يجده يعمل بنفس المنطق تماماً في Packing List و Invoice Lines و COO.

---

## 13. 📋 Complete Screen Template (للنسخ المباشر)

```dart
class YourStageScreen extends ConsumerStatefulWidget {
  final int importFileId;
  const YourStageScreen({super.key, required this.importFileId});
  
  @override
  ConsumerState<YourStageScreen> createState() => _YourStageScreenState();
}

class _YourStageScreenState extends ConsumerState<YourStageScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // ← Auto-refresh on mount
    Future.microtask(() => ref.invalidate(yourDataProvider));
  }

  @override
  Widget build(BuildContext context) {
    return VerticalStageScaffold(
      stageCode: 'STAGE_CODE',          // e.g. 'CUSTOMS'
      titleAr: 'اسم المرحلة',
      titleEn: 'Stage Name',
      headerIcon: Icons.your_icon,
      headerColor: AppTheme.cobalt,
      selectedImportFileId: widget.importFileId,
      showStageLifecycleControls: true,  // Skip + Stop تلقائياً
      onShipmentStatusChanged: () => ref.invalidate(yourDataProvider),
      tabs: [
        VerticalNavTabItem(
          icon: Icons.list_alt,
          titleAr: 'القائمة',
          titleEn: 'List',
        ),
        // ... تابات إضافية
      ],
      selectedIndex: _selectedTab,
      onTabSelected: (i) => setState(() => _selectedTab = i),
      headerActions: [
        // أزرار إضافية (AI، إلخ)
        const BackToDashboardButton(),  // ← دايمًا الأخير
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ← Toolbar أول عنصر دايمًا
        MasterDataToolbarWidget(
          moduleEndpoint: 'your-endpoint',
          title: context.l10n.screenTitle,
          onRefreshNeeded: () => ref.invalidate(yourDataProvider),
        ),
        // ← المحتوى
        Expanded(child: _buildContent()),
      ],
    );
  }
}
```

---

## 14. 🔍 Screen Consistency Audit Checklist (Pass 1 Checklist)

عند مراجعة أي شاشة ومقارنتها بالشاشة المرجعية (`ShipmentDraftDocumentsReviewScreen`)، يجب التأكد من النقاط التالية قبل اعتماد الشاشة:

| # | العنصر المفحوص | المتوقع (حسب الـ Baseline) | المخالفة المحتملة | الإجراء التصحيحي |
|---|----------------|---------------------------|-------------------|------------------|
| 1 | **Page Header** | Icon + Title (Title Case) + Stage Badge (`PHASE-X`) | نقص البادج أو الأيقونة | استخدام `VerticalStageScaffold` وتمرير `stageCode` |
| 2 | **Action Bar Order** | `[Skip] [Stop] [Clone] [AI] [Refresh] [Dashboard]` | ترتيب عشوائي أو أزرار ناقصة | ترتيب الـ Widgets وفق الجدول الصارم في Zone A |
| 3 | **Back to Dashboard** | موجود ويكون دائماً آخر عنصر في الـ Header | مفقود أو في المنتصف | وضع `const BackToDashboardButton()` في نهاية `headerActions` |
| 4 | **Live Refresh** | زرار تحديث `IconButton(Icons.refresh)` بالهيدر والـ Toolbar | مفقود | إضافة زر Refresh يعمل `ref.invalidate()` |
| 5 | **Save Draft** | زر حفظ مؤقت في كل شاشة نموذج أو شاشة قابلة للتحرير | مفقود في Forms | تفعيل `onSaveDraft` في `StandardFormActionBar` |
| 6 | **Document Actions** | PDF / Excel / Print بكروت المحتوى التي بها مستندات | تصدير ناقص أو أزرار غير متناسقة | استخدام ألوان `AppTheme` ونمط `AppButton` الموحد |
| 7 | **Sidebar Navigation** | Left Sidebar للمراحل + Sub-Sidebar للخطوات (عند ≥4 tabs) | TabBar أفقي مزدحم | استخدام `AdaptiveTabScaffold` أو تابات `VerticalStageScaffold` |
| 8 | **Language & Casing** | English labels فقط في الكود + استدعاء `context.l10n` + Title Case | نصوص hardcoded عربي أو lowercase | استبدال النصوص بـ l10n واستخدام Title Case |
| 9 | **Dropdowns** | `SearchableDropdownField` حصرياً للبيانات المرجعية | `DropdownButtonFormField` | استبداله بـ `SearchableDropdownField` فوراً |
| 10 | **Loading State** | `isLoading` مفعل في الأزرار لمنع الضغط المتكرر | أزرار بدون Loading Indicator | تمرير `isLoading: _isSaving` لـ `AppButton` |
| 11 | **Table Sticky Header** | ترويسة الجدول ثابتة بخلفية مصمتة أثناء السكرول | ترويسة تختفي أو نصوص تتداخل | تفعيل `stickyHeader` وخلفية مصمتة |
| 12 | **Sticky Actions Col** | عمود الإجراءات والتحديد ثابت أثناء السكرول الأفقي | ضياع أزرار الإجراءات يميناً/يساراً | تثبيت عمود الإجراءات على الطرف |
| 13 | **Responsive Bounds** | عدم وجود RenderFlex overflow عند 1366x768 و 1366x1024 | أخطاء Overflow صفراء/حمراء | استبدال الأبعاد الثابتة بـ `Flexible/Expanded/Wrap` |

### صيغة تقرير الفحص (Audit Report Table Format):
```markdown
| Screen | Missing/Inconsistent Element | Expected (per baseline) | Found | Fix |
|--------|------------------------------|-------------------------|-------|-----|
| ...    | ...                          | ...                     | ...   | ... |
```

