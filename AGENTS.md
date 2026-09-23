# 🤖 AI Agent Guidelines — ImportFlow ERP

> **للمساعد الذكي:** هذا الملف هو نقطة الدخول فقط.
> القواعد التفصيلية الكاملة موجودة في `.agents/rules/` والـ Skills.
> لا تعيد قراءة هذا الملف بالكامل — الـ rules files تُحمَّل تلقائياً.

---

## ⚡ Auto-Loaded Rules (تُحمَّل تلقائياً في كل محادثة)

| الملف | المحتوى | الحجم |
|-------|---------|-------|
| [`CORE_RULES.md`](.agents/rules/CORE_RULES.md) | Stack + Architecture + Testing + Forbidden | ~8 KB |
| [`DOMAIN_RULES.md`](.agents/rules/DOMAIN_RULES.md) | Customs + Stages + Landed Cost + Soft Delete | ~5 KB |
| [`UI_SCREEN_STANDARDS.md`](.agents/rules/UI_SCREEN_STANDARDS.md) | Quick Reference فقط — التفاصيل في الـ Skill | ~1 KB |

## 🔧 On-Demand Skills (تُفعَّل عند الحاجة فقط)

| الـ Skill | متى تُفعّله |
|-----------|------------|
| [`ui-screen-standards`](.agents/skills/ui-screen-standards/SKILL.md) | أي مهمة تذكر شاشة / UI / Flutter / Widget / Form |
| [`erp-module-generator`](.agents/skills/erp-module-generator/SKILL.md) | إنشاء Backend Module جديد |
| [`customs-landed-cost-engine`](.agents/skills/customs-landed-cost-engine/SKILL.md) | حسابات جمركية أو Landed Cost |
| [`cbm-calculator`](.agents/skills/cbm-calculator/SKILL.md) | حسابات CBM أو أوزان شحن |
| [`history-logger`](.agents/skills/history-logger/SKILL.md) | تسجيل Task مكتمل في السجل اليومي |
| [`screen-audit`](.agents/skills/screen-audit/SKILL.md) | مراجعة اتساق الشاشات |

---

## 🎯 System Context

**ImportFlow ERP** — نظام Enterprise لـ:
Import Management · Customs Clearance · Freight & Logistics · Landed Cost · Document Management · CargoX/Nafeza Integration

> تعامل معه كـ **Enterprise Application** قابل للتوسع — ليس CRUD بسيط.

---

## 🌐 Language Rule (ملخص)

| السياق | اللغة |
|--------|-------|
| التواصل مع المستخدم | **العربية** (لهجة مصرية مفضلة) |
| Code / DB / API / Files | **English only** |

```text
❌ country = "مصر"          ✅ country_id = 64
❌ def حساب_الجمارك():     ✅ def calculate_customs_duties():
```

---

## 🛠️ Technology Stack (ثابت لا يتغير)

```
Backend:  Python 3.12+ | FastAPI | Uvicorn | Pydantic v2 | SQLAlchemy 2.0 | Alembic | SQLite
Frontend: Flutter 3.x | Dart 3.x | Windows Desktop
State:    flutter_riverpod | Networking: dio | Routing: go_router
DB:       sorour_logistics.db
```

---

## 🏗️ Architecture (إلزامي)

```
Router → Service → Repository → Database
Flutter → API (لا تعرف Flutter تفاصيل DB)
```

**Module Structure (6 ملفات فقط):**
```
modules/<name>/
├── model.py       → SQLAlchemy models
├── schemas.py     → Pydantic schemas
├── repository.py  → DB queries only
├── service.py     → Business logic
├── validators.py  → Business validation
└── router.py      → HTTP routes only
```

---

## 🎨 UI Quick Reference

```dart
// ألوان: AppTheme فقط
AppTheme.cobalt / emerald / crimson / orange / charcoal / cloudWhite

// أزرار: AppButton فقط — ❌ ElevatedButton / Colors.xxx
// Dropdowns: SearchableDropdownField<T> — ❌ DropdownButtonFormField
// Scaffold: VerticalStageScaffold (Type A) | PageHeader (Type B/C)
// File Save: FileSaveHelper.exportAndSaveFile(...) — ❌ Silent Download
```

> للتفاصيل الكاملة للـ UI: اقرأ `.agents/skills/ui-screen-standards/SKILL.md`

---

## ⚡ Mandatory Rules (ملخص — التفاصيل في CORE_RULES.md)

```text
✅ Unit Tests إلزامية — كود بدون tests = مرفوض
✅ Form validation حقيقي + رسائل خطأ Backend كـ SnackBar
✅ ref.invalidate() بعد كل Add/Edit/Delete/Status Change
✅ initState يجلب بيانات جديدة — لا Stale Cache
✅ FileSaveHelper.exportAndSaveFile لكل تصدير ملف
✅ Alembic migration لكل تغيير في DB Schema
✅ Soft Delete — لا حذف نهائي للبيانات المهمة
✅ Audit Trail: created_at/by, updated_at/by لكل Entity مهمة
```

```text
❌ Hard-Code أي نسبة ضريبية أو رسم جمركي
❌ Business Logic داخل router.py
❌ API Keys أو Secrets في الكود أو الـ Repo
❌ تعديل ملفات غير مرتبطة بالمهمة الحالية
❌ إنشاء ملفات جديدة بدون سبب معماري واضح
```

---

## 📋 Task Completion Protocol

بعد إنهاء أي Task:
1. ✅ تشغيل Unit Tests → 100% passing
2. ✅ توثيق التغييرات في `docs/` إن لزم
3. ✅ تسجيل في `history/YYYY-MM-DD.md` (Append-only)
