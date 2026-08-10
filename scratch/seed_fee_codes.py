import os
import sys
from datetime import date
from decimal import Decimal

sys.path.insert(0, ".")
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from database.database import Base, SessionLocal, engine
from modules.customs_tariff.model import FeeCode

# Create tables if not exist
Base.metadata.create_all(bind=engine)

db = SessionLocal()

fee_codes_data = [
    {
        "code": "77",
        "name_ar": "ضريبة مهن حرة (رسم مستخلص)",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("50.00"),
    },
    {
        "code": "250",
        "name_ar": "رسم طباعة بيان جمركي موحد",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("55.00"),
    },
    {
        "code": "798",
        "name_ar": "رسم نموذج 19 ك م",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("35.00"),
    },
    {
        "code": "60",
        "name_ar": "دمغة إقرار مميكن",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("4.50"),
    },
    {
        "code": "74",
        "name_ar": "رسم خدمات مميكنة",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("20.00"),
    },
    {
        "code": "107",
        "name_ar": "رسم تنمية محررات",
        "collection_group": "رسم مستخلص",
        "calculation_type": "flat",
        "flat_amount": Decimal("2.00"),
    },
    {
        "code": "1",
        "name_ar": "ضريبة الوارد",
        "collection_group": "ضريبة جمارك",
        "calculation_type": "reference",
        "reference_source": "duty_amount",
    },
    {
        "code": "3",
        "name_ar": "رسم مصاريف إدارية",
        "collection_group": "ضريبة جمارك",
        "calculation_type": "flat",
        "flat_amount": Decimal("750.00"),
    },
    {
        "code": "37",
        "name_ar": "ضريبة أ.ت.ص (رسم الخدمات 1%)",
        "collection_group": "أ.ت.ص",
        "calculation_type": "reference",
        "reference_source": "service_fee_amount",
    },
    {
        "code": "232",
        "name_ar": "تحت حساب قيمة مضافة",
        "collection_group": "ض.مبيعات",
        "calculation_type": "flat",
        "flat_amount": Decimal("100.00"),
    },
    {
        "code": "32",
        "name_ar": "ضريبة قيمة مضافة",
        "collection_group": "ض.مبيعات",
        "calculation_type": "reference",
        "reference_source": "vat_amount",
    },
    {
        "code": "397",
        "name_ar": "صندوق تكريم الشهداء",
        "collection_group": "رسوم النافذة الموحدة",
        "calculation_type": "flat",
        "flat_amount": Decimal("5.00"),
    },
    {
        "code": "390",
        "name_ar": "خدمات جمركية",
        "collection_group": "رسوم النافذة الموحدة",
        "calculation_type": "flat",
        "flat_amount": Decimal("1081.00"),
    },
    {
        "code": "392",
        "name_ar": "خدمات معلوماتية",
        "collection_group": "رسوم النافذة الموحدة",
        "calculation_type": "flat",
        "flat_amount": Decimal("3457.00"),
    },
    {
        "code": "394",
        "name_ar": "ضريبة قيمة مضافة على خدمات النافذة",
        "collection_group": "رسوم النافذة الموحدة",
        "calculation_type": "derived",
        "derived_formula_rate": Decimal("14.00"),
        "derived_formula_base_codes": "390,392",
    },
]

inserted = 0
updated = 0

for item in fee_codes_data:
    existing = db.query(FeeCode).filter(FeeCode.code == item["code"]).first()
    if existing:
        for k, v in item.items():
            setattr(existing, k, v)
        updated += 1
    else:
        fc = FeeCode(**item, effective_from=date.today(), is_active=True)
        db.add(fc)
        inserted += 1

db.commit()
print(f"✅ Fee Codes Seeding Complete: Inserted {inserted}, Updated {updated}.")
