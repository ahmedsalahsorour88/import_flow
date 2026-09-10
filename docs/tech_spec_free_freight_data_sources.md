# 📦 المواصفة التقنية — ربط مصادر بيانات الشحن البحري المجانية
## (shaq-freight + ShippingRates.org)
### Task Code: `INT-DATA-015`

> **المرجع المعماري:** امتداد لمهام الذكاء اللوجستي وحسابات الغرامات:
> - `AI-ROUTE-006` (بطاقة ذكاء المسار والمورد والتاريخ التفاوضي)
> - `AI-BENCH-007` (محرك مفاضلة وترتيب عروض الشحن بالأوزان المعتمدة)
> - `LOG-DUAL-001` (رادار عداد أرضيات الميناء وغرامات التوكيل المنفصلين)
> 
> **الوثائق المرجعية:** `docs/future_logistics_and_ai_roadmap.md` و `docs/task_specifications_advanced_logistics.md`

---

## 1. 🎯 ملخص تنفيذي (Executive Overview)

الهدف من هذه المواصفة هو ربط نظام **ImportFlow ERP** بمصدرين مجانيين لتغذية ميزات الذكاء اللوجستي وإدارة الغرامات البحرية دون أي تكلفة اشتراك مالي في مرحلة التشغيل الحالية (MVP)، مع هندسة طبقة وسيطة موحدة (**Freight Data Service**) تفصل كود النظام الداخلي عن تفاصيل المزودين الخارجيين، مما يتيح الترقية مستقبلاً إلى مزودين مدفوعين مثل (SeaRates أو Freightos) باستبدال المحولات (Adapters) دون المساس بالواجهات أو منطق العمل الداخلي.

### جدول مقارنة مصادر البيانات:

| المصدر | نوع التكامل | الاستخدام في النظام | نموذج التسعير والحدود | متطلبات المصادقة |
|---|---|---|---|---|
| **`shaq-freight`** | مكتبة Python محلية مفتوحة المصدر | مؤشر أسعار النولون الأسبوعي (SFX) — يغطي 20+ خط تجاري عالمي رئيسي | مجاني 100% بدون سقف استدعاءات | لا يتطلب مفتاح API ولا تسجيل حساب |
| **`ShippingRates.org` API** | واجهة برمجية RESTful خارجية | جداول وقواعد غرامات تأخير الحاويات (Detention) وفترات السماح الممنوحة من الخطوط الملاحية | 25 استدعاء شهرياً مجاناً + 4 نقاط نهاية استعلامية مجانية دائمة | مفتاح API مجاني (Bearer Token) |
| **`port_demurrage_tariff`** | جدول محلي مؤرّخ (Versioned) | تعريفات أرضيات ساحات هيئات الموانئ المصرية الرسمية (بالجنيه EGP) | محلي بالكامل — إدخال بشري معتمد من القرارات الرسمية | غير منطبق (إدارة محلية) |

---

## 2. 🏛️ البنية التقنية والهندسة المعمارية (Architecture Design)

تعتمد المعمارية على نمط **المحول الموحد (Adapter / Facade Pattern)** لضمان عدم ربط أي منطق تشغيلي مباشر بمصدر خارجي محدد (تطبيقاً للبند 7.4 و 25 في `AGENTS.md`):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ImportFlow ERP Core Modules                     │
│   [AI-ROUTE-006]           [AI-BENCH-007]            [LOG-DUAL-001]   │
│ (Route Intelligence)    (Forwarder Benchmark)       (Demurrage Radar)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             Freight Data Service Layer (موزع البيانات الوسيط)           │
│                    modules/freight_data_connector/                     │
│  ├── service.py          (المنسق العام وجدولة التحديثات)                │
│  ├── shaq_adapter.py     (محول مكتبة shaq-freight)                    │
│  └── shippingrates_client.py (عميل ومحول ShippingRates.org API)        │
└──────────────────┬────────────────────────────────┬────────────────────┘
                   │                                │
                   ▼                                ▼
       ┌──────────────────────┐         ┌────────────────────────┐
       │   shaq-freight Lib   │         │ ShippingRates.org REST │
       │  (Local Python Lib)  │         │  (Quota Guard: <=10/mo)│
       └───────────┬──────────┘         └───────────┬────────────┘
                   │                                │
                   └───────────────┬────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   Local SQLite Cache & Persistence                     │
│      ├── freight_index_snapshots (تحديث أسبوعي تلقائي للمؤشر)         │
│      ├── demurrage_rules         (تحديث شهري لغرامات التوكيل بالدولار) │
│      └── port_demurrage_tariff   (جدول مؤرّخ لأرضيات الموانئ بالجنيه)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 🚢 التكامل الأول: `shaq-freight` (مؤشر أسعار النولون SFX)

### 3.1 التثبيت والاعتماديات
- إضافة الحزمة إلى بيئة بايثون:
  ```bash
  pip install shaq-freight
  ```
- لا توجد أي متطلبات شبكية خاصة ولا مفاتيح تشفير.

### 3.2 نمط الاستخدام البرمجي
```python
from shaq_freight import SHAQFreight

client = SHAQFreight()
index = client.get_freight_index()

# هيكل البيانات المستلم:
# index = {
#     'updated_at': '2026-09-08',
#     'routes': [
#         {
#             'route': 'China to Mediterranean',
#             'rates': {
#                 'fcl_20gp': {'rate_usd': 2150.0},
#                 'fcl_40hq': {'rate_usd': 3800.0}
#             },
#             'transit_days': 28
#         }, ...
#     ]
# }
```

### 3.3 سياسة الجدولة والتخزين المحلي
- مؤشر SFX يصدر بصورة **أسبوعية** (كل يوم اثنين).
- يتم تشغيل مهمة غير متزامنة (Scheduled Task / Cron) صباح كل يوم اثنين لجلب المؤشر الأحدث وتخزينه في جدول `freight_index_snapshots`.
- لا يجوز استدعاء المكتبة بشكل حي عند كل طلب مستخدم لتفادي إبطاء استجابة واجهة المستخدم وتكرار العمليات الحسابية.

### 3.4 مخطط قاعدة البيانات المقترح (SQLAlchemy Model)
```python
class FreightIndexSnapshot(Base):
    __tablename__ = "freight_index_snapshots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    route_name = Column(String(150), nullable=False, index=True)
    origin_region = Column(String(100), nullable=True)
    destination_region = Column(String(100), nullable=True)
    fcl_20gp_usd = Column(Numeric(10, 2), nullable=True)
    fcl_40hq_usd = Column(Numeric(10, 2), nullable=False)
    transit_time_days = Column(Integer, nullable=True)
    source = Column(String(50), default="shaq-freight", nullable=False)
    snapshot_date = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
```

### 3.5 نقاط الربط التشغيلي
- **الربط مع `AI-ROUTE-006`:** عند استعراض بطاقة ذكاء المسار، يستعلم الموديول عن أحدث مؤشر مسجل للمسار المختار (مثال: مسارات شرق آسيا إلى الموانئ المصرية/المتوسط).
- **الربط مع `AI-BENCH-007`:** يُستخدم مؤشر SFX كسعر مرجعي استرشادي (Market Benchmark) لقياس مدى عدالة وتنافسية عروض الأسعار المقدمة من شركات الشحن (RFQ Quotes) واكتشاف المبالغة في الأسعار.
- **سياسة عدم التطابق:** في حال عدم توفر خط ملاحي مطابق في المؤشر المجاني، يعرض النظام:
  `'مؤشر الأسعار العالمي غير متوفر لهذا المسار حالياً'` مع استبعاد المؤشر دون تعطيل عرض البيانات التاريخية الداخلية للمورد.

---

## 4. ⏱️ التكامل الثاني: `ShippingRates.org API` (غرامات الحاويات وفترات السماح)

### 4.1 إدارة الحساب والمصادقة
- إنشاء حساب مطور مجاني وتوليد مفتاح `SHIPPINGRATES_API_KEY`.
- تخزين المفتاح في إعدادات البيئة الآمنة (`.env`) أو `SystemConfig`.
- نقاط النهاية الأربعة المجانية الدائمة (لا تستهلك من رصيد الـ 25 طلب/شهر):
  1. `GET /api/stats` — إحصائيات عامة عن تغطية المنصة.
  2. `GET /api/lines` — قائمة الخطوط الملاحية المدعومة (Maersk, MSC, CMA CGM, Hapag-Lloyd, ONE, Evergreen, Yang Ming, ZIM, COSCO).
  3. `GET /api/search` — البحث عن المسارات والموانئ المدعومة.
  4. `GET /api/health` — فحص حالة وتوافر الخادم.

### 4.2 نمط الاستخدام (حساب الغرامة)
```bash
curl -X POST https://shippingrates.org/api/dd/calculate \
  -H "Authorization: Bearer {API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "line": "maersk",
    "country": "EG",
    "container_type": "40HC",
    "days": 10,
    "free_days": 4
  }'
```

### 4.3 استراتيجية ترشيد وتوفير حصة الـ 25 طلب/شهر (Quota Guard: <= 10 طلبات شهرياً)
> **قاعدة أمان صارمة:** يُحظر تماماً استدعاء API الخارجي بصورة حية عند حساب غرامة كل حاوية أو عند تصفح شاشات العمليات من قبل المستخدمين.

- **آلية العمل المؤتمتة:**
  1. تحديث جدول القواعد المحلي `demurrage_rules` **مرة واحدة فقط في أول كل شهر ميلادي**.
  2. التحديث يقتصر حصراً على الخطوط الملاحية النشطة في الشركة (3 إلى 5 خطوط رئيسية فقط).
  3. استهلاك الحصة: 5 خطوط × 1 استدعاء شهرياً = **5 استدعاءات فقط** من أصل 25 (استهلاك 20% وتوفير 80% كهامش أمان ضد أي أخطاء أو إعادة محاولات).
  4. حساب الغرامة الفعلي (لأي شحنة) يتم **محلياً** بمعادلة رياضية بسيطة باستخدام القواعد المخزّنة، وليس باستدعاء API لكل شحنة في زمن استجابة أقل من 5ms.

### 4.4 مخطط قاعدة البيانات المقترح (SQLAlchemy Model)
```python
class DemurrageRule(Base):
    __tablename__ = "demurrage_rules"

    rule_id = Column(Integer, primary_key=True, autoincrement=True)
    shipping_line = Column(String(50), nullable=False, index=True) # e.g. maersk, msc, cma_cgm
    country_code = Column(String(5), default="EG", nullable=False)
    container_type = Column(String(20), nullable=False)            # 20GP, 40HC, 40RF
    default_free_days = Column(Integer, default=14, nullable=False)
    rate_slabs = Column(JSON, nullable=False)                      # شرائح الغرامة كاملة كما ترجع من الـ API
    source = Column(String(50), default="shippingrates.org", nullable=False)
    last_synced_at = Column(DateTime, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
```

نموذج شرائح الغرامات (`rate_slabs` JSON Structure):
```json
[
  {"from_day": 1, "to_day": 7, "rate_usd_per_day": 0.0},
  {"from_day": 8, "to_day": 14, "rate_usd_per_day": 0.0},
  {"from_day": 15, "to_day": 21, "rate_usd_per_day": 40.0},
  {"from_day": 22, "to_day": 28, "rate_usd_per_day": 80.0},
  {"from_day": 29, "to_day": null, "rate_usd_per_day": 140.0}
]
```

### 4.5 نقطة الربط بـ `LOG-DUAL-001`
- عند تفعيل عداد **"غرامات التوكيل الملاحي (Detention)"** لحاوية معيّنة، يستعلم النظام محلياً من جدول `demurrage_rules` بدلاً من نداء الـ API، ويحسب الغرامة المتوقعة تلقائياً حسب عدد الأيام المنقضية.
- **ملحوظة مهمة:** هذا الجدول يغطي **غرامات التوكيل (Detention/USD)** فقط. أما **أرضيات ساحة الميناء المصرية (EGP)** فمصدرها مختلف تماماً (تعريفة هيئة الميناء المحلية) ولازم تُدخل يدوياً أو تُربط بمصدر محلي منفصل، لأن الـ API الأجنبي مش هيغطيها.

---

### 4.6 الشق المصري: أرضيات ساحة الميناء (Port Demurrage / EGP)

لا يوجد API مجاني أو مدفوع يغطي تعريفة هيئات الموانئ المصرية — القرارات تُنشر بشكل دوري (تقريباً كل 6 أشهر) كملفات PDF رسمية من الهيئة/شركة تداول الحاويات. الحل هنا إداري بمعاونة تقنية، وليس ربط API:

#### أ) جدول تعريفة مُؤرَّخ (Versioned Tariff Table):

```sql
CREATE TABLE port_demurrage_tariff (
    id SERIAL PRIMARY KEY,
    port_authority VARCHAR(50),        -- مثال: 'Alexandria', 'Damietta', 'Sokhna', 'Port Said'
    container_type VARCHAR(10),        -- 20ft, 40ft, 40HC, Reefer
    free_days INT,                     -- عادة 3 إلى 5 أيام
    rate_slabs JSONB,                  -- شرائح تصاعدية بالجنيه المصري، مُدخلة يدوياً
    tariff_version VARCHAR(50),        -- رقم/سنة القرار الرسمي، مثال: 'Decision-554-2024'
    effective_from DATE,
    effective_to DATE,                 -- NULL لو لسه سارية
    source_document VARCHAR(255),      -- رابط أو اسم ملف الـ PDF المرجعي
    entered_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);
```

تمثيل النموذج عبر SQLAlchemy:
```python
class PortDemurrageTariff(Base):
    __tablename__ = "port_demurrage_tariff"

    id = Column(Integer, primary_key=True, autoincrement=True)
    port_authority = Column(String(50), nullable=False, index=True) # Alexandria, Damietta, Sokhna, etc.
    container_type = Column(String(20), nullable=False)             # 20ft, 40ft, 40HC, Reefer
    free_days = Column(Integer, default=4, nullable=False)          # مهلة السماح الرسمية
    rate_slabs = Column(JSON, nullable=False)                       # شرائح تصاعدية بالجنيه EGP
    tariff_version = Column(String(50), nullable=False, index=True) # القرار الرسمي e.g. Decision-554-2024
    effective_from = Column(Date, nullable=False)
    effective_to = Column(Date, nullable=True)                      # None if currently active
    source_document = Column(String(255), nullable=True)            # PDF reference file name
    entered_by = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
```

> **قاعدة تاريخية حاسمة:** أي حاوية تُحسب بالنسخة (`tariff_version`) الفعّالة **بتاريخ تخليصها/صرفها**، لا بأحدث نسخة دائماً — لضمان صحة المراجعات المالية اللاحقة والتدقيق المحاسبي حتى بعد تغيّر التعريفة بقرار وزاري جديد.

#### ب) عملية الإدخال والمتابعة:
1. **إدخال يدوي أولي:** إدخال أولي من أحدث قرار منشور حالياً لكل ميناء (نقطة بداية لمرة واحدة).
2. **المتابعة البشرية الدورية:** تكليف مسؤول عمليات/تخليص بمراجعة موقع الهيئة أو الجريدة الرسمية شهرياً، وإدخال أي قرار جديد عبر لوحة تحكم بسيطة (Admin Panel) — لا حاجة لأتمتة قراءة موقع حكومي، لأن وتيرة التغيير بطيئة والتصنيف الصحيح للشرائح يحتاج مراجعة بشرية متخصصة.
3. **مراقب التنبيهات (اختياري لاحقاً):** مهمة مجدولة شهرياً تتحقق فقط من وجود ملف جديد بعنوان يحتوي "تعريفة/أرضيات" على صفحة الهيئة وترسل تنبيهاً للمسؤول — تنبيه فقط، لا قراءة أو تفسير آلي للقرار.

#### ج) دور `INT-NAFEZA-008` (توضيح هام):
مهمة مزامنة أسعار الصرف `INT-NAFEZA-008` مخصصة لتحويل قيم البضاعة والإقرارات الجمركية، وتُستخدم هنا فقط لعرض المجموع الكلي (Detention بالدولار محوّلاً + Demurrage بالجنيه) كرقم واحد مفهوم في تقرير موحّد للمستخدم — وليست بديلاً عن `port_demurrage_tariff` ولا وسيلة لحساب الأرضيات بالتحويل من الدولار.

---

## 5. 🛡️ سياسات معالجة الأخطاء والبدائل (Fallback & Resilience Strategy)

| السيناريو | السلوك التلقائي للنظام | أثر التجربة على المستخدم |
|---|---|---|
| **فشل استدعاء `shaq-freight`** | استخدام آخر Snapshot مخزّن + عرض تاريخه للمستخدم | استمرار عمل النظام دون انقطاع مع إظهار تاريخ المؤشر الأخير. |
| **تجاوز حصة `ShippingRates.org` الشهرية** | الاعتماد على `demurrage_rules` المخزّنة محلياً (أصلاً هي المصدر الأساسي للحسابات اليومية وليس الـ API نفسه) | عدم تأثر أي شحنة لأن الحسابات تتم محلياً بالأصل. |
| **عدم تطابق المسار مع أي مصدر مجاني** | عرض "غير متوفر مجاناً — يتطلب إدخال يدوي أو ترقية للخطة المدفوعة" بدلاً من رقم تخميني | وضوح كامل وشفافية دون إعطاء بيانات مضللة. |
| **غياب تعريفة الميناء المصري لتاريخ معين** | استخدام أقرب تعريفة سارية مع تنبيه مسؤول النظام لتحديث قرار الميناء. | احتساب تقديري واضح مع طلب مراجعة الاعتماد المالي. |

---

## 6. ✅ معايير القبول والجاهزية للتنفيذ (Acceptance Criteria)

- [ ] **AC-1:** `freight_index_snapshot` يتحدث أسبوعياً تلقائياً دون تدخل يدوي عبر `shaq-freight`.
- [ ] **AC-2:** `demurrage_rules` يتحدث شهرياً، ولا يتجاوز 10 استدعاءات API شهرياً (هامش أمان تحت حد الـ 25).
- [ ] **AC-3:** حساب غرامة أي حاوية يتم محلياً في أقل من 200ms دون انتظار استجابة خارجية.
- [ ] **AC-4:** عند غياب البيانات لمسار/خط غير مغطى، يظهر تنبيه واضح للمستخدم بدلاً من قيمة فارغة أو خاطئة.
- [ ] **AC-5:** لوحة تحكم بسيطة (Admin) تعرض تاريخ آخر تحديث لكل مصدر، لتسهيل المتابعة والتحكم.
- [ ] **AC-6:** `port_demurrage_tariff` يحسب أي حاوية بالنسخة الفعّالة بتاريخ تخليصها، وليس بأحدث نسخة دائماً — حتى بعد صدور قرار تعريفة جديد.
- [ ] **AC-7:** عدم وجود أي خلط حسابي أو عملاتي بين غرامات التوكيل (USD) وأرضيات الموانئ المصرية (EGP) مع استخدام سعر صرف `INT-NAFEZA-008` للعرض الإجمالي الموحد فقط.

---

## 7. 🚀 مسار الترقية المستقبلي (Extensibility Roadmap)

عند نمو العمليات التشغيلية والحاجة لتغطية خطوط وتحديثات لحظية مدفوعة:
1. التبديل من `ShippingRates.org` إلى خطة مدفوعة من نفس المزود، أو **SeaRates API** كما نوقش سابقاً — دون تعديل في طبقة `AI-ROUTE-006` أو `AI-BENCH-007` أو `LOG-DUAL-001` نفسها، لأن الاستبدال يتم فقط داخل `Freight Data Service`.
2. الحفاظ على المخططات وقواعد البيانات المحلية لتعمل كطبقة Caching مستقلة وموفرة للتكاليف.
