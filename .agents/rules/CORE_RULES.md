# ⚡ ImportFlow ERP — Core Rules (Always Active)

> هذا الملف يُحمَّل تلقائيًا في كل محادثة. يحتوي على القواعد الصارمة غير القابلة للتفاوض.
> للمرجع الكامل: `AGENTS.md` | للـ Business Domain: `DOMAIN_RULES.md` | للـ UI: `UI_SCREEN_STANDARDS.md`

---

## 1. 🌐 Languages — قاعدة اللغة

| السياق | اللغة |
|--------|-------|
| التواصل مع المستخدم | العربية (لهجة مصرية مفضلة) |
| Python / Dart identifiers | English only |
| DB tables / columns / API endpoints | English only |
| Class / Function / Variable names | English only |
| File names | English only |

```text
❌ country = "مصر"        ✅ country_id = 64
❌ def حساب_الجمارك():   ✅ def calculate_customs_duties():
❌ Text('حفظ')           ✅ Text(context.l10n.save)
```

---

## 2. 🛠️ Technology Stack — ثابت لا يتغير

### Backend
```
Python 3.12+ | FastAPI | Uvicorn | Pydantic v2
SQLAlchemy 2.0 | Alembic | SQLite (sorour_logistics.db)
```

### Frontend
```
Flutter 3.x | Dart 3.x | Windows Desktop
State: flutter_riverpod (preferred) | provider (with justification)
Networking: dio | Routing: go_router | Window: window_manager
```

---

## 3. 🏗️ Backend Architecture — الترتيب إلزامي

```
Router → Service → Repository → Database
```

**كل Module = 6 ملفات فقط:**
```
modules/<name>/
├── model.py       → SQLAlchemy models, FK, indexes
├── schemas.py     → Pydantic request/response
├── repository.py  → DB queries, CRUD, filtering
├── service.py     → Business logic, transactions
├── validators.py  → Business validation, duplicates
└── router.py      → FastAPI routes, HTTP only
```

**مسؤوليات صارمة:**
- `router.py` → يستدعي Service فقط، لا يحتوي Business Logic
- `repository.py` → لا يحتوي Business Rules
- `service.py` → البيزنس لوجيك والـ Transactions فقط

---

## 4. 🎨 UI Stack — Flutter

```dart
// ✅ الألوان دايمًا من AppTheme
AppTheme.cobalt    // #3498DB — Primary actions
AppTheme.emerald   // #27AE60 — Success / confirm
AppTheme.crimson   // #C0392B — Danger / delete
AppTheme.orange    // #E67E22 — Warning / skip
AppTheme.charcoal  // #2C3E50 — Headers
AppTheme.cloudWhite // #ECF0F1 — Backgrounds

// ❌ ممنوع
Color(0xFF3498DB) | Colors.blue | Colors.red
```

---

## 5. ⚡ Mandatory Rules — قواعد إلزامية فورية

### 🔴 Testing (لا تسلّم Task بدون اختبارات)
```text
✅ Unit tests في tests/unit/ لكل Service و Validator (pytest)
✅ Flutter tests للـ Providers والـ Models (flutter test)
✅ كل Task = تشغيل الاختبارات + رؤية نتائج خضراء 100%
❌ كود بدون اختبارات = مرفوض
```

### 🔴 Forms Validation
```text
✅ كل Form محمية بـ Form + validator حقيقي
✅ أخطاء Backend API تظهر كـ SnackBar للمستخدم
✅ رسائل خطأ باللون الأحمر تحت الحقول الإلزامية
```

### 🔴 Auto-Refresh بعد كل عملية
```dart
// بعد كل Add / Edit / Delete / Status Change:
ref.invalidate(yourProvider); // إلزامي
```

### 🔴 Screen Mount Live Load
```dart
// في initState أو عند فتح كل شاشة:
// يجب جلب بيانات جديدة من Backend — لا Stale Cache
```

### 🔴 Searchable Dropdown — لا DropdownButtonFormField
```dart
// ✅ إلزامي لـ: HS Code, Country, Port, Company, Supplier,
//    Incoterms, Project, Partner, Bank, Purchase Orders
SearchableDropdownField<T>(...)

// ❌ ممنوع تماماً
DropdownButtonFormField(...)  // لا
TextField(...)  // لاختيار Reference data: لا
```

### 🔴 Security & Secret Management (Task G — فحص أمني إلزامي)
```text
✅ أسرار Backend في .env مع توفير .env.example بقيم تجريبية وهمية
✅ توكنز ومفاتيح Frontend في flutter_secure_storage (ممنوع SharedPreferences)
✅ Auth checks إلزامية على كل Endpoint، وتحديداً endpoints الـ Clone/Duplicate
✅ فحص الأمان (Step 0) إلزامي قبل البدء في تعديل الـ Layout لأي شاشة
❌ ممنوع طباعة أو تسجيل (Log) أو تخزين التوكنز أو أرقام ACID كـ Plaintext
```

### 🔴 Mandatory Save File Location Dialog (Task I — حفظ وتنزيل الملفات الموحد)
```text
✅ فتح نافذة حوارية تفاعلية إلزامية (Native "Save As" Dialog) لتحديد مكان الحفظ واسم الملف:
   - ديسكتوب (Desktop): FilePicker.saveFile مع lockParentWindow: true
   - متصفح ويب (Web - Chromium): File System Access API (window.showSaveFilePicker)
✅ معالجة الإلغاء الآمن (AbortError): التقاط DOMException بهدوء دون حفظ ملف ودون خطأ
✅ متصفحات غير داعمة (Firefox/Safari/Mobile): تراجع لـ <a download> مع SnackBar توضيحي
✅ كافة عمليات التصدير والتحميل (PDF, Excel, PNG, CSV) تمر حصرياً عبر FileSaveHelper.exportAndSaveFile
✅ تمرير مصفوفة bytes لضمان التوافق التام عبر سطح المكتب (Windows Desktop) ومتصفح الويب (Web)
✅ الالتزام بنظام التسمية القياسي: [Stage Name] - [Import File Name/Code].[ext]
✅ إظهار إشعار عائم SnackBar مع زر "فتح المجلد" لفتح مسار الملف في Windows Explorer فور الحفظ
❌ حظر الحفظ الصامت التلقائي (Silent Download) في مسار ثابت أو مجلد افتراضي دون سؤال المستخدم
❌ حظر الأسماء العامة أو العشوائية (مثل export.pdf أو download.xlsx)
```

---

## 6. 🚫 Forbidden Practices — المحظورات المطلقة

```text
❌ وجود API Keys أو Secrets أو Passwords في الكود أو الـ Repo
❌ تخزين Tokens في SharedPreferences أو Plaintext
❌ إنشاء Endpoints للـ Clone تتجاوز الـ Auth Checks للأصل
❌ تخطي FileSaveHelper أو الحفظ الصامت التلقائي لأي ملف
❌ استخدام أسماء ملفات عشوائية أو عامة في عمليات التصدير
❌ Business Logic داخل router.py
❌ Hard-Code أي نسبة ضريبية أو رسم جمركي
❌ حذف نهائي لأي بيانات مهمة (استخدم Soft Delete)
❌ تعديل DB Schema بدون Alembic migration
❌ تكرار Business Logic في أكثر من مكان
❌ تخزين Master Data كنص حر بدلاً من FK
❌ عرض Database ID للمستخدم بدلاً من Business Code
❌ تجاهل Database Constraints (اعتمد على مستويين: App + DB)
❌ إنشاء ملفات جديدة بدون سبب معماري واضح
❌ تعديل ملفات غير مرتبطة بالمهمة الحالية
```

---

## 7. 📋 Audit Trail — إلزامي لكل Entity مهمة

```python
created_at   | created_by
updated_at   | updated_by
# تحديث عبر: set_created_info() / set_updated_info()
# لا يُحدَّث يدويًا من Router
```

## 8. 🔑 IDs & References

```python
# كل Entity الرئيسية:
supplier_id   # Primary Key (داخلي)
supplier_code # Business Reference (SUP-000017) ← للمستخدم
```

---

## 9. 📅 Task Completion Protocol

بعد إنهاء أي Task:
1. ✅ تشغيل Unit Tests → 100% passing
2. ✅ توثيق التغييرات في `docs/` إن لزم
3. ✅ تسجيل في `history/YYYY-MM-DD.md` (Append-only)

---

## 10. 🏛️ Architecture First

```
Quick Fix < Correct Architecture
```
عند التعارض: اختر دايمًا الـ Architecture الصحيح حتى لو أخذ وقت أطول.
