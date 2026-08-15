"""
Seed script for Clearance Expense Catalog and 2026 Broker Price Lists
"""

from datetime import date
from database.database import SessionLocal
from modules.customs_consultation.model import (
    ClearanceExpenseType,
    BrokerPriceList,
    BrokerPriceListItem,
)
from modules.external_service_providers.model import ExternalServiceProvider


def seed_clearance_data():
    db = SessionLocal()
    try:
        # 1. Define standard expense types based on Egyptian Customs & Logistics tariff
        expense_catalog = [
            # ================= FCL / LCL Clearance Fees =================
            {
                "code": "EXP-CLR-001",
                "name_ar": "أتعاب تخليص LCL (لكل فاتورة)",
                "name_en": "LCL Clearance Fee (Per Invoice)",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Invoice (لكل فاتورة)",
                "currency": "EGP",
                "order": 1,
                "default_price": 1250.0,
            },
            {
                "code": "EXP-CLR-002",
                "name_ar": "مصاريف تخليص LCL واحد طن",
                "name_en": "LCL Clearance Expenses (1 Ton)",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Ton (لكل طن)",
                "currency": "EGP",
                "order": 2,
                "default_price": 4750.0,
            },
            {
                "code": "EXP-CLR-003",
                "name_ar": "مصاريف تخليص LCL لكل طن زيادة",
                "name_en": "LCL Extra Ton Clearance Expenses",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Ton (لكل طن إضافي)",
                "currency": "EGP",
                "order": 3,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-CLR-004",
                "name_ar": "أتعاب تخليص حاوية 20 قدم (فاتورة)",
                "name_en": "20ft FCL Clearance Fee (Per Invoice)",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Invoice (لكل فاتورة)",
                "currency": "EGP",
                "order": 4,
                "default_price": 2500.0,
            },
            {
                "code": "EXP-CLR-005",
                "name_ar": "مصاريف تخليص أول حاوية 20 قدم",
                "name_en": "20ft First Container Clearance Expenses",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 5,
                "default_price": 7500.0,
            },
            {
                "code": "EXP-CLR-006",
                "name_ar": "مصاريف تخليص كل حاوية 20 قدم زيادة",
                "name_en": "20ft Extra Container Clearance Expenses",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Container (لكل حاوية إضافية)",
                "currency": "EGP",
                "order": 6,
                "default_price": 1500.0,
            },
            {
                "code": "EXP-CLR-007",
                "name_ar": "أتعاب تخليص حاوية 40 قدم (فاتورة)",
                "name_en": "40ft FCL Clearance Fee (Per Invoice)",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Invoice (لكل فاتورة)",
                "currency": "EGP",
                "order": 7,
                "default_price": 2500.0,
            },
            {
                "code": "EXP-CLR-008",
                "name_ar": "مصاريف تخليص أول حاوية 40 قدم",
                "name_en": "40ft First Container Clearance Expenses",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 8,
                "default_price": 7500.0,
            },
            {
                "code": "EXP-CLR-009",
                "name_ar": "مصاريف تخليص كل حاوية 40 قدم زيادة",
                "name_en": "40ft Extra Container Clearance Expenses",
                "category": "Clearance Fees (أتعاب ومصاريف تخليص)",
                "unit": "Per Container (لكل حاوية إضافية)",
                "currency": "EGP",
                "order": 9,
                "default_price": 2000.0,
            },

            # ================= Procedures, Approvals & Inspections =================
            {
                "code": "EXP-PRC-010",
                "name_ar": "بريد - دمغات",
                "name_en": "Mail & Stamps Fees",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Fixed (مبلغ ثابت)",
                "currency": "EGP",
                "order": 10,
                "default_price": 250.0,
            },
            {
                "code": "EXP-PRC-011",
                "name_ar": "عرض الواردات + اعتماد الإيلاك",
                "name_en": "Import Inspection & ILAC Endorsement",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 11,
                "default_price": 3000.0,
                "min_price": 2500.0,
                "max_price": 3500.0,
            },
            {
                "code": "EXP-PRC-012",
                "name_ar": "رسوم استخراج وإصدار ACID",
                "name_en": "ACID Processing Fee",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Shipment (لكل إقرار)",
                "currency": "EGP",
                "order": 12,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-013",
                "name_ar": "زراعة ومهمل وسيل",
                "name_en": "Agriculture, Neglected & Customs Seal Fees",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Fixed (مبلغ ثابت)",
                "currency": "EGP",
                "order": 13,
                "default_price": 1150.0,
            },
            {
                "code": "EXP-PRC-014",
                "name_ar": "أمن عام + مندوب الأمن العام + سحب العينات",
                "name_en": "Public Security + Delegate + Sampling",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Sample (لكل إجراء)",
                "currency": "EGP",
                "order": 14,
                "default_price": 1500.0,
            },
            {
                "code": "EXP-PRC-015",
                "name_ar": "عرض أمن عام للقاهرة",
                "name_en": "Cairo Public Security Inspection",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Case (لكل عرض)",
                "currency": "EGP",
                "order": 15,
                "default_price": 5000.0,
            },
            {
                "code": "EXP-PRC-016",
                "name_ar": "وثيقة تأمين",
                "name_en": "Insurance Policy / Document",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Fixed (مبلغ ثابت)",
                "currency": "EGP",
                "order": 16,
                "default_price": 500.0,
            },
            {
                "code": "EXP-PRC-017",
                "name_ar": "عرض إكس راي (X-Ray)",
                "name_en": "X-Ray Inspection Fee",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 17,
                "default_price": 250.0,
            },
            {
                "code": "EXP-PRC-018",
                "name_ar": "تطبيق الاتفاقيات التجارية",
                "name_en": "Trade Agreements Application",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Invoice (لكل فاتورة)",
                "currency": "EGP",
                "order": 18,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-019",
                "name_ar": "الإفراج تحت التحفظ",
                "name_en": "Release Under Custody Clearance",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Shipment (لكل شحنة)",
                "currency": "EGP",
                "order": 19,
                "default_price": 350.0,
            },
            {
                "code": "EXP-PRC-020",
                "name_ar": "غسيل جمركي",
                "name_en": "Customs Wash Fee",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Fixed (مبلغ ثابت)",
                "currency": "EGP",
                "order": 20,
                "default_price": 250.0,
            },
            {
                "code": "EXP-PRC-021",
                "name_ar": "مطافئ",
                "name_en": "Fire Department Inspection Fee",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 21,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-022",
                "name_ar": "دمغة وموازين",
                "name_en": "Weights & Measures Department",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 22,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-023",
                "name_ar": "مفرقعات",
                "name_en": "Explosives Department Clearance",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 23,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-024",
                "name_ar": "إفراج نهائي",
                "name_en": "Final Customs Release Fee",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Shipment (لكل شحنة)",
                "currency": "EGP",
                "order": 24,
                "default_price": 500.0,
            },
            {
                "code": "EXP-PRC-025",
                "name_ar": "إشعاع وهيئة الطاقة الذرية",
                "name_en": "Radiation & Atomic Energy Authority",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 25,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-026",
                "name_ar": "عرض زراعة مشمول",
                "name_en": "Agricultural Quarantine Inspection",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 26,
                "default_price": 1500.0,
            },
            {
                "code": "EXP-PRC-027",
                "name_ar": "عرض على مصلحة الكيمياء",
                "name_en": "Chemistry Department Laboratory Analysis",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Sample (لكل عينة)",
                "currency": "EGP",
                "order": 27,
                "default_price": 1500.0,
            },
            {
                "code": "EXP-PRC-028",
                "name_ar": "سحب إذن / ثمن التصوير / مصاريف تعديل منافستو",
                "name_en": "Delivery Order Pull, Photocopy & Manifest Amendment",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Fixed (مبلغ ثابت)",
                "currency": "EGP",
                "order": 28,
                "default_price": 750.0,
            },
            {
                "code": "EXP-PRC-029",
                "name_ar": "عرض جهات إضافية أخرى",
                "name_en": "Other Miscellaneous Regulatory Inspection",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Inspection (لكل عرض)",
                "currency": "EGP",
                "order": 29,
                "default_price": 1000.0,
            },
            {
                "code": "EXP-PRC-030",
                "name_ar": "مصاريف وزن قماش داخل الميناء",
                "name_en": "Fabric Weight Scale Port Inspection",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Shipment (لكل وزن)",
                "currency": "EGP",
                "order": 30,
                "default_price": 1500.0,
            },
            {
                "code": "EXP-PRC-031",
                "name_ar": "إنهاء إجراءات زيادة الوزن",
                "name_en": "Weight Discrepancy Clearance Procedures",
                "category": "Procedures & Approvals (إجراءات وموافقات وفحص)",
                "unit": "Per Case (لكل حالة)",
                "currency": "EGP",
                "order": 31,
                "default_price": 750.0,
            },

            # ================= Inland Transport & Trucking =================
            {
                "code": "EXP-TRN-032",
                "name_ar": "نقل سيارة 1 طن دبابة (إسكندرية - قاهرة)",
                "name_en": "1 Ton Pickup Transport (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Vehicle (لكل سيارة)",
                "currency": "EGP",
                "order": 32,
                "default_price": 6150.0,
            },
            {
                "code": "EXP-TRN-033",
                "name_ar": "نقل سيارة جامبو حتى 4 طن (إسكندرية - قاهرة)",
                "name_en": "Jumbo Truck Up to 4 Ton (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Vehicle (لكل سيارة)",
                "currency": "EGP",
                "order": 33,
                "default_price": 8200.0,
            },
            {
                "code": "EXP-TRN-034",
                "name_ar": "نقل سيارة فرداني حتى 7 طن (إسكندرية - قاهرة)",
                "name_en": "Single Heavy Truck Up to 7 Ton (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Vehicle (لكل سيارة)",
                "currency": "EGP",
                "order": 34,
                "default_price": 14150.0,
            },
            {
                "code": "EXP-TRN-035",
                "name_ar": "نقل حاوية 20 قدم حتى 10 طن (إسكندرية - قاهرة)",
                "name_en": "20ft Container Trucking <= 10 Ton (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 35,
                "default_price": 14800.0,
            },
            {
                "code": "EXP-TRN-036",
                "name_ar": "نقل حاوية 20 قدم أكثر من 10 طن (إسكندرية - قاهرة)",
                "name_en": "20ft Container Trucking > 10 Ton (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 36,
                "default_price": 18400.0,
            },
            {
                "code": "EXP-TRN-037",
                "name_ar": "نقل حاويتين 20 قدم معاً (20*2) (إسكندرية - قاهرة)",
                "name_en": "Dual 20ft Containers Trucking (2x20ft) (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Trailer (لكل تريلا)",
                "currency": "EGP",
                "order": 37,
                "default_price": 23300.0,
            },
            {
                "code": "EXP-TRN-038",
                "name_ar": "نقل حاوية 40 قدم (إسكندرية - قاهرة)",
                "name_en": "40ft Container Trucking (Alex - Cairo)",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Container (لكل حاوية)",
                "currency": "EGP",
                "order": 38,
                "default_price": 18400.0,
            },
            {
                "code": "EXP-TRN-039",
                "name_ar": "بياتة حاويتين 20*2 (Overnight Demurrage)",
                "name_en": "2x20ft Truck Overnight Demurrage",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Night (لكل ليلة)",
                "currency": "EGP",
                "order": 39,
                "default_price": 4200.0,
            },
            {
                "code": "EXP-TRN-040",
                "name_ar": "بياتة حاوية 40*1 (Overnight Demurrage)",
                "name_en": "1x40ft Truck Overnight Demurrage",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Night (لكل ليلة)",
                "currency": "EGP",
                "order": 40,
                "default_price": 3600.0,
            },
            {
                "code": "EXP-TRN-041",
                "name_ar": "بياتة حاوية 20*1 (Overnight Demurrage)",
                "name_en": "1x20ft Truck Overnight Demurrage",
                "category": "Inland Transport (نقل بري وشاحنات)",
                "unit": "Per Night (لكل ليلة)",
                "currency": "EGP",
                "order": 41,
                "default_price": 3000.0,
            },
            {
                "code": "EXP-TRN-042",
                "name_ar": "تعتيق ميناء أبوقير",
                "name_en": "Abu Qir Port Stevedoring / Unloading",
                "category": "Port & Handling (موانئ وتعتيق وتفريغ)",
                "unit": "Per Shipment (لكل تعتيق)",
                "currency": "EGP",
                "order": 42,
                "default_price": 4250.0,
            },
            {
                "code": "EXP-TRN-043",
                "name_ar": "قيمة نقل الحاوية للوزن داخل الميناء",
                "name_en": "Internal Port Shifting for Weighing",
                "category": "Port & Handling (موانئ وتعتيق وتفريغ)",
                "unit": "Per Container (لكل نقلة وزن)",
                "currency": "EGP",
                "order": 43,
                "default_price": 3500.0,
            },
            {
                "code": "EXP-OTH-044",
                "name_ar": "مصاريف كشف العمال واستخدام الكلارك",
                "name_en": "Inspection Labor & Forklift Handling",
                "category": "Other Fees (مصاريف أخرى)",
                "unit": "Per Inspection (لكل كشف)",
                "currency": "EGP",
                "order": 44,
                "default_price": 1250.0,
                "min_price": 1000.0,
                "max_price": 1500.0,
            },
        ]

        created_expense_types = {}
        for exp in expense_catalog:
            existing = (
                db.query(ClearanceExpenseType)
                .filter(ClearanceExpenseType.expense_code == exp["code"])
                .first()
            )
            if not existing:
                existing = ClearanceExpenseType(
                    expense_code=exp["code"],
                    name_ar=exp["name_ar"],
                    name_en=exp["name_en"],
                    category=exp["category"],
                    default_unit=exp["unit"],
                    default_currency=exp["currency"],
                    display_order=exp["order"],
                    is_active=True,
                )
                db.add(existing)
                db.flush()
            created_expense_types[exp["code"]] = existing

        db.commit()
        print(f"Seeded {len(created_expense_types)} clearance expense catalog items.")

        # 2. Seed active Price List for Alexandria Broker (Nabil Naseef or default broker)
        brokers = (
            db.query(ExternalServiceProvider)
            .filter(ExternalServiceProvider.partner_type.ilike("%Customs Broker%"))
            .all()
        )

        for broker in brokers:
            existing_pl = (
                db.query(BrokerPriceList)
                .filter(
                    BrokerPriceList.broker_id == broker.provider_id,
                    BrokerPriceList.is_active == True,
                )
                .first()
            )
            if not existing_pl:
                pl = BrokerPriceList(
                    price_list_code=f"PL-{broker.provider_id}-2026-001",
                    title=f"بيان أسعار التخليص والنقل لميناء الإسكندرية والدخيلة لعام 2026 - {broker.partner_name}",
                    broker_id=broker.provider_id,
                    broker_name=broker.partner_name,
                    port_name="ميناء الإسكندرية والدخيلة",
                    effective_from=date(2026, 1, 1),
                    effective_to=date(2026, 12, 31),
                    version=1,
                    is_active=True,
                    notes="الأسعار سارية لعام 2026 بخلاف مصاريف الكشف المؤداة بمعرفة العميل وأي إيصالات رسمية للتوكيلات الملاحية.",
                )
                db.add(pl)
                db.flush()

                for exp in expense_catalog:
                    db_exp = created_expense_types.get(exp["code"])
                    item = BrokerPriceListItem(
                        price_list_id=pl.price_list_id,
                        expense_type_id=db_exp.expense_id if db_exp else None,
                        expense_name=exp["name_ar"],
                        category=exp["category"],
                        unit_type=exp["unit"],
                        standard_price=exp.get("default_price", 0.0),
                        currency=exp.get("currency", "EGP"),
                        min_price=exp.get("min_price"),
                        max_price=exp.get("max_price"),
                        is_active=True,
                    )
                    db.add(item)

                db.commit()
                print(f"Created active 2026 price list for broker '{broker.partner_name}' with {len(expense_catalog)} items.")

    finally:
        db.close()


if __name__ == "__main__":
    seed_clearance_data()
