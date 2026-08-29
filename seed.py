"""
ImportFlow ERP — Database Seeder (Production Ready)
Seeds ONLY core reference tables:
- Ports & Transport Locations (MD-009)
- Currencies & Exchange Rates (MD-004)
- Customs Tariff & HS Codes & Nafeza Fee Codes (MD-008)
- Incoterms 2020 & Responsibility Matrix & Cost Items (MD-006 / 006A / 006B)
- System Users (Admin / Manager / Specialist)

Demo data (companies, suppliers, partners, files, POs) is strictly disabled in production.
"""
from datetime import datetime, timedelta, timezone, date
from database.database import SessionLocal, Base, engine
from update_db_schema import migrate_db

# Import models
from modules.users.model import User
from modules.auth.security import hash_password
from modules.incoterms.model import Incoterm, CostItem, IncotermResponsibility
from modules.customs_tariff.model import CustomsTariff, FeeCode
from modules.transport_locations.model import TransportLocation
from modules.currencies.model import Currency, ExchangeRate
from modules.external_service_providers.model import ExternalServiceProvider

SEED_OPERATIONAL_DEMO_DATA = False

def seed_data():
    Base.metadata.create_all(bind=engine)
    migrate_db()

    db = SessionLocal()

    try:
        # ==================================================
        # 0. Seed System Users & Roles (RBAC)
        # ==================================================
        if db.query(User).count() == 0:
            print("Seeding System Users & Roles...")
            users = [
                User(
                    username="admin",
                    email="admin@importflow.com",
                    full_name="System Admin",
                    hashed_password=hash_password("admin123"),
                    role="ADMIN",
                    is_active=True,
                ),
                User(
                    username="manager",
                    email="manager@importflow.com",
                    full_name="General Logistics Manager",
                    hashed_password=hash_password("manager123"),
                    role="MANAGER",
                    is_active=True,
                ),
                User(
                    username="operator1",
                    email="operator1@importflow.com",
                    full_name="Ahmed Import Specialist",
                    hashed_password=hash_password("operator123"),
                    role="OPERATOR",
                    is_active=True,
                ),
                User(
                    username="operator2",
                    email="operator2@importflow.com",
                    full_name="Sara Customs Operator",
                    hashed_password=hash_password("operator123"),
                    role="OPERATOR",
                    is_active=True,
                ),
            ]
            db.add_all(users)
            db.commit()
            print("System Users seeded successfully.")

        # ==================================================
        # 1. Seed Incoterms 2020 (MD-006)
        # ==================================================
        if db.query(Incoterm).count() == 0:
            print("Seeding Incoterms 2020 (MD-006)...")
            incoterms = [
                Incoterm(incoterm_code="EXW", incoterm_name="Ex Works (تسليم المصنع)", version="Incoterms 2020",
                         description="الحد الأدنى من الالتزامات للبائع؛ حيث تقع المسؤولية والتكلفة على المشتري لاستلام البضائع من مستودع البائع."),
                Incoterm(incoterm_code="CFR", incoterm_name="Cost and Freight (التكلفة والشحن)", version="Incoterms 2020",
                         description="يدفع البائع تكاليف الشحن لميناء الوجهة، ولكن المخاطر تنتقل للمشتري بمجرد تحميل البضائع على السفينة."),
                Incoterm(incoterm_code="CIF", incoterm_name="Cost, Insurance and Freight (التكلفة والتأمين والشحن)", version="Incoterms 2020",
                         description="نفس قواعد CFR، ولكن يُطلب من البائع أيضاً توفير الحد الأدنى من التأمين على البضائع للمشتري."),
                Incoterm(incoterm_code="CIP", incoterm_name="Carriage and Insurance Paid To (الرسوم والتأمين المدفوعان إلى)", version="Incoterms 2020",
                         description="يشبه CPT، ولكن يُلزم البائع أيضاً بدفع ثمن التأمين على البضائع."),
                Incoterm(incoterm_code="CPT", incoterm_name="Carriage Paid To (أجور النقل المدفوعة إلى)", version="Incoterms 2020",
                         description="يدفع البائع تكاليف نقل البضائع إلى الوجهة المتفق عليها."),
                Incoterm(incoterm_code="DAP", incoterm_name="Delivered at Place (تسليم في المكان)", version="Incoterms 2020",
                         description="يُسلم البائع البضائع ويتحمل المخاطر حتى وصولها إلى المكان المتفق عليه (دون تفريغها)."),
                Incoterm(incoterm_code="DDP", incoterm_name="Delivered Duty Paid (التسليم مدفوع الرسوم)", version="Incoterms 2020",
                         description="الحد الأقصى من الالتزامات للبائع؛ حيث يدفع جميع التكاليف والرسوم الجمركية"),
                Incoterm(incoterm_code="DPU", incoterm_name="Delivered at Place Unloaded (تسليم في المكان المفرغ)", version="Incoterms 2020",
                         description="يُسلم البائع البضائع ويتحمل المخاطر حتى يتم تفريغها في الوجهة المحددة."),
                Incoterm(incoterm_code="FAS", incoterm_name="Free Alongside Ship (التسليم بجانب السفينة)", version="Incoterms 2020",
                         description="يضع البائع البضائع بجانب السفينة في ميناء الشحن المحدد، وتنتقل المسؤولية بعدها للمشتري."),
                Incoterm(incoterm_code="FCA", incoterm_name="Free Carrier (الناقل الحر)", version="Incoterms 2020",
                         description="يُسلم البائع البضائع إلى الناقل أو شخص آخر يسميه المشتري في مكان مسمى."),
                Incoterm(incoterm_code="FOB", incoterm_name="Free On Board (تسليم على متن السفينة)", version="Incoterms 2020",
                         description="يتحمل البائع تكاليف ومخاطر وضع البضائع على متن السفينة، ثم تنتقل للمشتري بمجرد عبورها حاجز السفينة."),
            ]
            db.add_all(incoterms)
            db.commit()
            print("Incoterms 2020 seeded successfully.")

        # ==================================================
        # 2. Seed Cost Items (MD-006A)
        # ==================================================
        if db.query(CostItem).count() == 0:
            print("Seeding Cost Items (MD-006A)...")
            cost_items_data = [
                ("OTRK", "Trucking Origin fees", "Freight", "نقل البضاعة من مستودع البائع إلى ميناء/نقطة الشحن في بلد المنشأ"),
                ("XCLR", "Export Clearance fees", "Customs", "التخليص الجمركي ورسوم التصدير في بلد المنشأ"),
                ("OTHC", "OTHC fees", "Port", "رسوم مناولة الحاويات في ميناء الشحن الأصلي (Origin Terminal Handling Charge)"),
                ("INS", "Insurance fees", "Freight", "تكلفة التأمين البحري/الجوي على البضاعة أثناء النقل الدولي"),
                ("XINSP", "Origin Inspection", "Other", "تكاليف الفحص والتفتيش والمعاينة في بلد المنشأ قبل الشحن"),
                ("OFR", "O/F fees", "Freight", "رسوم الشحن الدولي (Ocean Freight / Air Freight)"),
                ("DTRK", "Trucking Destination fees", "Freight", "النقل الداخلي من ميناء الوصول إلى مستودع المشتري النهائي"),
                ("DTHC", "DTHC fees", "Port", "رسوم تفريغ ومناولة الحاويات في ميناء الوصول (Destination Terminal Handling Charge)"),
                ("DOC", "Documentation fees", "Other", "رسوم إصدار ومعالجة المستندات التجارية وبوالص الشحن"),
                ("DISC", "Disclaim letter", "Other", "خطابات التنازل وإجراءات نقل ملكية الشحنة (Disclaim / Delivery Order)"),
                ("ICLR", "Import Clearance fees", "Customs", "أتعاب التخليص الجمركي والإفراج عن الشحنة في ميناء الوصول"),
                ("PCONG", "Port Congestion", "Port", "علاوات ورسوم الازدحام والتأخير في الموانئ (Port Congestion Surcharge)"),
                ("DMRG", "Demurrage & Detention", "Port", "غرامات تأخير الحاويات وعوائد الميناء وخطوط الشحن"),
                ("XCMP", "Compliance Fees", "Other", "رسوم الامتثال والفحص الفني والجهات الرقابية الجمركية"),
                ("FORM4", "L/C Or Form 4 fees", "Bank", "مصاريف ودمغات الاعتماد المستندي ونموذج 4 البنكي لاستيراد البضائع"),
                ("DUTY", "Tax & Customs Duties", "Customs", "الضرائب والرسوم الجمركية ورسم التنمية وضريبة القيمة المضافة الجمركية"),
                ("STG", "Storage/Warehousing", "Port", "رسوم الأرضيات والتخزين وإيداعات الموانئ والمستودعات الجمركية"),
            ]
            cost_items = [
                CostItem(cost_item_code=code, cost_item_name=name, cost_category=cat, description=desc)
                for code, name, cat, desc in cost_items_data
            ]
            db.add_all(cost_items)
            db.commit()
            print("Cost Items seeded successfully.")

        # ==================================================
        # 3. Seed Responsibility Matrix (MD-006B)
        # ==================================================
        if db.query(IncotermResponsibility).count() == 0:
            print("Seeding Incoterm Responsibility Matrix (MD-006B)...")
            cost_item_map = {ci.cost_item_code: ci.cost_item_id for ci in db.query(CostItem).all()}
            incoterm_map = {inco_code: inco_id for inco_id, inco_code in db.query(Incoterm.incoterm_id, Incoterm.incoterm_code).all()}

            matrix_rules = {
                "EXW": {code: "Importer" for code in cost_item_map.keys()},
                "CFR": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter",
                    "INS": "Importer", "XINSP": "Importer", "OFR": "Importer", "DTRK": "Importer",
                    "DTHC": "Importer", "DOC": "Importer", "DISC": "Importer", "ICLR": "Importer",
                    "PCONG": "Importer", "DMRG": "Importer", "XCMP": "Importer", "FORM4": "Importer",
                    "DUTY": "Importer", "STG": "Importer"
                },
                "CIF": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter", "INS": "Exporter",
                    "XINSP": "Importer", "OFR": "Importer", "DTRK": "Importer", "DTHC": "Importer",
                    "DOC": "Importer", "DISC": "Importer", "ICLR": "Importer", "PCONG": "Importer",
                    "DMRG": "Importer", "XCMP": "Importer", "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "CIP": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter", "INS": "Exporter",
                    "XINSP": "Importer", "OFR": "Importer", "DTRK": "Importer", "DTHC": "Importer",
                    "DOC": "Importer", "DISC": "Importer", "ICLR": "Importer", "PCONG": "Importer",
                    "DMRG": "Importer", "XCMP": "Importer", "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "CPT": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter",
                    "INS": "Importer", "XINSP": "Importer", "OFR": "Importer", "DTRK": "Importer",
                    "DTHC": "Importer", "DOC": "Importer", "DISC": "Importer", "ICLR": "Importer",
                    "PCONG": "Importer", "DMRG": "Importer", "XCMP": "Importer", "FORM4": "Importer",
                    "DUTY": "Importer", "STG": "Importer"
                },
                "DAP": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter", "INS": "Exporter",
                    "XINSP": "Exporter", "OFR": "Exporter", "DTRK": "Exporter", "DTHC": "Exporter", "DOC": "Exporter",
                    "DISC": "Importer", "ICLR": "Importer", "PCONG": "Importer", "DMRG": "Importer",
                    "XCMP": "Importer", "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "DDP": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter", "INS": "Exporter",
                    "XINSP": "Exporter", "OFR": "Exporter", "DTRK": "Exporter", "DTHC": "Exporter",
                    "DOC": "Exporter", "DISC": "Exporter", "ICLR": "Exporter", "PCONG": "Exporter",
                    "DMRG": "Exporter", "XCMP": "Exporter", "DUTY": "Exporter",
                    "FORM4": "Importer", "STG": "Importer"
                },
                "DPU": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter", "INS": "Exporter",
                    "XINSP": "Exporter", "OFR": "Exporter", "DTRK": "Exporter", "DTHC": "Exporter", "DOC": "Exporter",
                    "DISC": "Importer", "ICLR": "Importer", "PCONG": "Importer", "DMRG": "Importer",
                    "XCMP": "Importer", "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "FAS": {
                    "OTRK": "Exporter", "XCLR": "Exporter",
                    "OTHC": "Importer", "INS": "Importer", "XINSP": "Importer", "OFR": "Importer",
                    "DTRK": "Importer", "DTHC": "Importer", "DOC": "Importer", "DISC": "Importer",
                    "ICLR": "Importer", "PCONG": "Importer", "DMRG": "Importer", "XCMP": "Importer",
                    "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "FCA": {
                    "OTRK": "Exporter", "XCLR": "Exporter",
                    "OTHC": "Importer", "INS": "Importer", "XINSP": "Importer", "OFR": "Importer",
                    "DTRK": "Importer", "DTHC": "Importer", "DOC": "Importer", "DISC": "Importer",
                    "ICLR": "Importer", "PCONG": "Importer", "DMRG": "Importer", "XCMP": "Importer",
                    "FORM4": "Importer", "DUTY": "Importer", "STG": "Importer"
                },
                "FOB": {
                    "OTRK": "Exporter", "XCLR": "Exporter", "OTHC": "Exporter",
                    "INS": "Importer", "XINSP": "Importer", "OFR": "Importer", "DTRK": "Importer",
                    "DTHC": "Importer", "DOC": "Importer", "DISC": "Importer", "ICLR": "Importer",
                    "PCONG": "Importer", "DMRG": "Importer", "XCMP": "Importer", "FORM4": "Importer",
                    "DUTY": "Importer", "STG": "Importer"
                },
            }

            responsibilities = []
            for inco_code, rules in matrix_rules.items():
                if inco_code in incoterm_map:
                    inc_id = incoterm_map[inco_code]
                    for item_code, party in rules.items():
                        if item_code in cost_item_map:
                            ci_id = cost_item_map[item_code]
                            is_included = (party == "Exporter")
                            responsibilities.append(IncotermResponsibility(
                                incoterm_id=inc_id,
                                cost_item_id=ci_id,
                                responsible_party=party,
                                included_in_incoterm=is_included,
                            ))

            if responsibilities:
                db.add_all(responsibilities)
                db.commit()
            print("Incoterm Responsibility Matrix seeded successfully.")

        # ==================================================
        # 4. Seed Customs Tariff / HS Codes (MD-008)
        # ==================================================
        if db.query(CustomsTariff).count() == 0:
            print("Seeding Customs Tariff / HS Codes (MD-008)...")
            tariffs = [
                CustomsTariff(
                    hs_code="8471.30.00",
                    hs_description="Portable automatic data processing machines (Laptops & Notebooks)",
                    customs_category="Electronics",
                    customs_duty_rate=5.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=5.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="NTRA (National Telecom Regulatory Authority)",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="8703.23.90",
                    hs_description="Motor cars and other motor vehicles (1500cc - 3000cc)",
                    customs_category="Automotive",
                    customs_duty_rate=40.00,
                    vat_rate=14.00,
                    schedule_tax_rate=15.00,
                    development_fee_rate=5.00,
                    import_fee_rate=3.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="Egyptian Customs Authority & Ministry of Industry",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="8517.13.00",
                    hs_description="Smartphones and cellular mobile devices",
                    customs_category="Telecommunications",
                    customs_duty_rate=10.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=5.00,
                    import_fee_rate=5.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="NTRA",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="8481.80.00",
                    hs_description="Taps, cocks, valves and similar appliances for pipes",
                    customs_category="Industrial Machinery",
                    customs_duty_rate=2.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=False,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="5208.11.00",
                    hs_description="Woven fabrics of cotton, unbleached plain weave",
                    customs_category="Textiles",
                    customs_duty_rate=10.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC & Ministry of Trade",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="7210.49.00",
                    hs_description="Flat-rolled products of iron or non-alloy steel, plated/coated with zinc",
                    customs_category="Raw Materials & Metals",
                    customs_duty_rate=5.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="3004.90.00",
                    hs_description="Medicaments consisting of mixed/unmixed products for therapeutic uses",
                    customs_category="Pharmaceuticals",
                    customs_duty_rate=0.00,
                    vat_rate=0.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="EDA (Egyptian Drug Authority)",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="1001.99.00",
                    hs_description="Wheat and meslin, other than durum wheat (Food Security)",
                    customs_category="Food & Agricultural",
                    customs_duty_rate=0.00,
                    vat_rate=0.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="NFSA (National Food Safety Authority)",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="8421.23.00",
                    hs_description="Oil or petrol-filters for internal combustion engines",
                    customs_category="Automotive Spare Parts",
                    customs_duty_rate=5.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
                CustomsTariff(
                    hs_code="3901.10.00",
                    hs_description="Polyethylene having a specific gravity of less than 0.94 in primary forms",
                    customs_category="Plastics & Polymers",
                    customs_duty_rate=2.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=False,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2024, 1, 1),
                    is_active=True,
                ),
            ]
            db.add_all(tariffs)
            db.commit()
            print("Customs Tariff / HS Codes (MD-008) seeded successfully.")

        # Seed Nafeza Fee Codes
        if db.query(FeeCode).count() == 0:
            nafeza_fees = [
                FeeCode(code="001", name_ar="ضريبة الوارد الجمركية (Customs Duty)", collection_group="ضريبة جمارك", calculation_type="reference", reference_source="duty_amount", is_active=True),
                FeeCode(code="002", name_ar="ضريبة القيمة المضافة (VAT)", collection_group="ضريبة مبيعات", calculation_type="reference", reference_source="vat_amount", is_active=True),
                FeeCode(code="003", name_ar="ضريبة الجدول (Schedule Tax)", collection_group="ضريبة مبيعات", calculation_type="reference", reference_source="vat_amount", is_active=True),
                FeeCode(code="004", name_ar="رسم تنمية الموارد المالية للدولة", collection_group="رسم تنمية", calculation_type="flat", flat_amount=0.00, is_active=True),
                FeeCode(code="005", name_ar="رسم وارد إضافي (Import Surcharge)", collection_group="ضريبة جمارك", calculation_type="flat", flat_amount=0.00, is_active=True),
                FeeCode(code="006", name_ar="رسوم الخدمات الإدارية والجمركية", collection_group="رسوم النافذة الموحدة", calculation_type="flat", flat_amount=150.00, is_active=True),
                FeeCode(code="007", name_ar="أتعاب الفحص والمعاينة وتثمين الميناء", collection_group="رسوم النافذة الموحدة", calculation_type="flat", flat_amount=300.00, is_active=True),
            ]
            db.add_all(nafeza_fees)
            db.commit()
            print("Nafeza Fee Codes synced successfully.")

        # ==================================================
        # 5. Seed Transport Locations (MD-009)
        # ==================================================
        print("Seeding Transport Locations (MD-009)...")
        ports_data = [
            # Egyptian Ports & Logistics Nodes
            ("EGALY", "Alexandria Port", "Port", "Egypt", "Alexandria"),
            ("EGDKH", "El-Dekheila Port", "Port", "Egypt", "Alexandria"),
            ("EGPSD", "Port Said West", "Port", "Egypt", "Port Said"),
            ("EGPSE", "Port Said East", "Port", "Egypt", "Port Said"),
            ("EGDAM", "Damietta Port", "Port", "Egypt", "Damietta"),
            ("EGSOK", "Sokhna Port", "Port", "Egypt", "Suez"),
            ("EGSUZ", "Suez Port", "Port", "Egypt", "Suez"),
            ("EGADA", "Adabiya Port", "Port", "Egypt", "Suez"),
            ("EGCAI", "Cairo International Airport Cargo Terminal", "Airport", "Egypt", "Cairo"),
            ("EG6OCT", "6th of October Dry Port", "Dry Port", "Egypt", "Giza"),
            ("EG10R", "10th of Ramadan Dry Port", "Dry Port", "Egypt", "Sharqia"),
            ("EGSAD", "Sadat City Inland Logistics Center", "Warehouse", "Egypt", "Monufia"),
            
            # Global International Ports (POL departure ports)
            # Italy
            ("ITGOA", "Genoa Port", "Port", "Italy", "Genoa"),
            ("ITSPE", "La Spezia Port", "Port", "Italy", "La Spezia"),
            ("ITTRS", "Trieste Port", "Port", "Italy", "Trieste"),
            ("ITVCE", "Venice Port", "Port", "Italy", "Venice"),
            ("ITNAP", "Naples Port", "Port", "Italy", "Naples"),
            ("ITUDI", "Udine Inland Cargo Terminal", "Dry Port", "Italy", "Udine"),
            
            # China
            ("CNSHA", "Shanghai Port", "Port", "China", "Shanghai"),
            ("CNNGB", "Ningbo-Zhoushan Port", "Port", "China", "Ningbo"),
            ("CNSZX", "Shenzhen Yantian Port", "Port", "China", "Shenzhen"),
            ("CNTAO", "Qingdao Port", "Port", "China", "Qingdao"),
            ("CNCAN", "Guangzhou Nansha Port", "Port", "China", "Guangzhou"),
            ("CNTSN", "Tianjin Port", "Port", "China", "Tianjin"),
            ("CNDLC", "Dalian Port", "Port", "China", "Dalian"),
            ("CNXMN", "Xiamen Port", "Port", "China", "Xiamen"),

            # Germany & Western Europe
            ("DEHAM", "Hamburg Port", "Port", "Germany", "Hamburg"),
            ("DEBRV", "Bremerhaven Port", "Port", "Germany", "Bremerhaven"),
            ("DEFRA", "Frankfurt Airport Cargo Terminal", "Airport", "Germany", "Frankfurt"),
            ("NLRTM", "Rotterdam Port", "Port", "Netherlands", "Rotterdam"),
            ("BEANR", "Antwerp Port", "Port", "Belgium", "Antwerp"),
            
            # United Kingdom
            ("GBLGW", "London Gateway Port", "Port", "United Kingdom", "London"),
            ("GBFXT", "Felixstowe Port", "Port", "United Kingdom", "Felixstowe"),
            ("GBSOU", "Southampton Port", "Port", "United Kingdom", "Southampton"),
            
            # Turkey & Mediterranean
            ("TRAMB", "Istanbul Ambarli Port", "Port", "Turkey", "Istanbul"),
            ("TRMER", "Mersin Port", "Port", "Turkey", "Mersin"),
            ("TRIZM", "Izmir Port", "Port", "Turkey", "Izmir"),
            ("TRGEB", "Gebze Logistics Port", "Dry Port", "Turkey", "Gebze"),
            
            # Middle East & Gulf
            ("AEJEA", "Jebel Ali Port", "Port", "United Arab Emirates", "Dubai"),
            ("AEKHF", "Khalifa Port Abu Dhabi", "Port", "United Arab Emirates", "Abu Dhabi"),
            ("SAJED", "Jeddah Islamic Port", "Port", "Saudi Arabia", "Jeddah"),
            ("SADMM", "King Abdulaziz Port Dammam", "Port", "Saudi Arabia", "Dammam"),

            # Americas & Asia Pacific
            ("USLAX", "Los Angeles Port", "Port", "United States", "Los Angeles"),
            ("USNYC", "New York / New Jersey Port", "Port", "United States", "New York"),
            ("USSAV", "Savannah Port", "Port", "United States", "Savannah"),
            ("ESVLC", "Valencia Port", "Port", "Spain", "Valencia"),
            ("ESBCN", "Barcelona Port", "Port", "Spain", "Barcelona"),
            ("FRLEH", "Le Havre Port", "Port", "France", "Le Havre"),
            ("INNSA", "Nhava Sheva JNPT Port", "Port", "India", "Mumbai"),
            ("INMUN", "Mundra Port", "Port", "India", "Gujarat"),
            ("JPTYO", "Tokyo Port", "Port", "Japan", "Tokyo"),
            ("JPYOK", "Yokohama Port", "Port", "Japan", "Yokohama"),
            ("KRPUS", "Busan Port", "Port", "South Korea", "Busan"),
            ("SGSIN", "Singapore Port", "Port", "Singapore", "Singapore"),
        ]

        existing_locodes = {loc.un_locode for loc in db.query(TransportLocation.un_locode).all()}
        new_ports = [
            TransportLocation(un_locode=code, location_name=name, location_type=ltype, country=country, city=city, is_active=True)
            for code, name, ltype, country, city in ports_data
            if code not in existing_locodes
        ]
        if new_ports:
            db.add_all(new_ports)
            db.commit()
            print(f"Added {len(new_ports)} international transport locations to DB.")

        # ==================================================
        # 6. Seed Currencies & Exchange Rates (MD-004)
        # ==================================================
        if db.query(Currency).count() == 0:
            print("Seeding Currencies & Exchange Rates (MD-004)...")
            currencies_data = [
                ("EGP", "Egyptian Pound", "EGP", True, 2),
                ("USD", "US Dollar", "$", False, 2),
                ("EUR", "Euro", "€", False, 2),
                ("CNY", "Chinese Yuan", "¥", False, 2),
                ("GBP", "British Pound", "£", False, 2),
                ("JPY", "Japanese Yen", "¥", False, 0),
                ("SAR", "Saudi Riyal", "SAR", False, 2),
                ("AED", "UAE Dirham", "AED", False, 2),
            ]
            curr_objs = {}
            for code, name, sym, is_base, dec in currencies_data:
                c = Currency(currency_code=code, currency_name=name, currency_symbol=sym, is_base_currency=is_base, decimal_places=dec, is_active=True)
                db.add(c)
                curr_objs[code] = c
            db.commit()

            rates_data = [
                ("USD", 48.50, 48.40),
                ("EUR", 52.80, 52.70),
                ("CNY", 6.70, 6.68),
                ("GBP", 61.90, 61.75),
                ("SAR", 12.92, 12.88),
                ("AED", 13.20, 13.18),
                ("JPY", 0.32, 0.318),
            ]
            rates = []
            for code, comm, cust in rates_data:
                if code in curr_objs:
                    rates.append(ExchangeRate(
                        currency_id=curr_objs[code].currency_id,
                        commercial_rate=comm,
                        customs_rate=cust,
                        effective_date=date(2026, 8, 1),
                        is_active=True,
                    ))
            if rates:
                db.add_all(rates)
                db.commit()
            print("Currencies & Exchange Rates (MD-004) seeded successfully.")

        # ==================================================
        # 7. Seed Core International Shipping Lines (MD-009B)
        # ==================================================
        shipping_lines_data = [
            ("MSC (Mediterranean Shipping Company) / شركة البحر الأبيض المتوسط للملاحة", "MSCU", "https://www.msc.com/en/track-a-shipment", "https://www.msc.com", "egy-info@msc.com", None, "+20 2 2414 8000 / +20 3 488 4000", "Heliopolis, Cairo / Sultan Hussein St., Alexandria", "Egypt"),
            ("Maersk Line (A.P. Moller – Maersk) / ميرسك إيجيبت", "MAEU", "https://www.maersk.com/tracking/", "https://www.maersk.com", "egycs@maersk.com", None, "+20 2 2413 8000 / +20 3 487 0000", "Cairo / Alexandria / Port Said", "Egypt"),
            ("CMA CGM Group / سي إم إيه سي جي إم", "CMDU", "https://www.cma-cgm.com/ebusiness/tracking", "https://www.cma-cgm.com", "cai.genmbox@cma-cgm.com", None, "+20 2 2269 5000 / +20 3 488 2000", "Heliopolis, Cairo / Alexandria", "Egypt"),
            ("Hapag-Lloyd AG / هاباج لويد مصر", "HLCU", "https://www.hapag-lloyd.com/en/online-business/track/track-by-booking-solution.html", "https://www.hapag-lloyd.com", "egypt@hlag.com", None, "+20 2 2696 4500", "Citystars Complex, Building 3, Heliopolis, Cairo", "Egypt"),
            ("Ocean Network Express (ONE) / أوشن نتورك إكسبريس", "ONEY", "https://ecomm.one-line.com/one-ecom/manage-shipment/cargo-tracking", "https://www.one-line.com", "eg.customercare@one-line.com", None, "+20 2 2413 5400", "94 Al Marghany St., Heliopolis, Cairo", "Egypt"),
            ("COSCO SHIPPING Lines / كوسكو شيبنج", "COSU", "https://elines.coscoshipping.com/ebusiness/cargoTracking", "https://lines.coscoshipping.com", "cs.egypt@coscon.com", None, "+20 2 2417 8100 / +20 3 487 5500", "47 Ramsis St., Downtown / 27 Sultan Hussein St., Alexandria", "Egypt"),
            ("China United Lines Ltd. (CULines)", "CULI", "https://www.culines.com/en/site/tracking", "https://www.culines.com", "booking@culines.com", None, None, "Shanghai Head Office / Local Liner Agent Egypt", "Egypt"),
            ("Emirates Shipping Line (ESL) / إميريتس شيبنج لاين", "ESLU", "https://www.emiratesline.com/tracking/", "https://www.emiratesline.com", "egypt.sales@emiratesline.com", None, "+20 2 2418 0700", "Heliopolis, Cairo", "Egypt"),
            ("Evergreen Marine Corp. / إيفرجرين إيجيبت", "EGLV", "https://www.shipmentlink.com/servlet/TTrk_Show", "https://www.evergreen-marine.com", "egyn-biz@evergreen-shipping.com.eg", None, "+20 2 2268 4000 / +20 3 487 7700", "11 El-Bustan St., Downtown, Cairo / Sultan Hussein St., Alexandria", "Egypt"),
            ("Yang Ming Marine Transport Corp. / يانج مينج إيجيبت", "YMLU", "https://www.yangming.com/e-service/Track_Trace/track_trace.aspx", "https://www.yangming.com", "cs@yangming.com.eg", None, "+20 2 2414 7700 / +20 3 484 2200", "Heliopolis, Cairo / Alexandria", "Egypt"),
            ("ZIM Integrated Shipping Services Ltd.", "ZIMU", "https://www.zim.com/tools/track-a-shipment", "https://www.zim.com", "customer-service@zim.com", None, "+20 3 481 1200", "Alexandria / Cairo (Liner Agency Representation)", "Egypt"),
            ("Wan Hai Lines Ltd. / وان هاي لاينز", "WHLC", "https://www.wanhai.com/views/cargoTrack/CargoTracking.xhtml", "https://www.wanhai.com", "egypt_sales@wanhai.com", None, "+20 2 2269 0000", "Heliopolis, Cairo", "Egypt"),
            ("Pacific International Lines (Pte) Ltd / بي آي إل إيجيبت", "PCIU", "https://www.pilship.com/en-our-track-and-trace/120.html", "https://www.pilship.com", "egypt.cs@cai.pilship.com", None, "+20 2 2268 9000 / +20 3 487 0000", "Nasr City, Cairo / Alexandria", "Egypt"),
            ("HMM Co., Ltd. (Hyundai Merchant Marine) / هيونداي مارين", "HDMU", "https://www.hmm21.com/cms/business/ebiz/trackTrace/trackTrace/index.jsp", "https://www.hmm21.com", "egycs@hmm21.com", None, "+20 2 2418 8800", "Sheraton Heliopolis, Cairo", "Egypt"),
            ("Tarros Line (Tarros Egypt Shipping Agency) / تاروس شيبنج", "GETU", "https://www.tarros.it/en/shipment-tracking/", "https://www.tarros.it", "info@tarros.com.eg", None, "+20 3 487 9000 / +20 2 2417 5000", "12 Salah Salem St., Alexandria / Heliopolis, Cairo", "Egypt"),
            ("Arkas Line (Arkas Egypt S.A.E.) / أركاس إيجيبت", "ARKU", "https://www.arkasline.com.tr/en/tracking", "https://www.arkasline.com.tr", "egypt.cs@arkas-egypt.com", None, "+20 2 2269 8888 / +20 3 488 5555", "47 Ramses St., Heliopolis, Cairo / 22 Dr. Mostafa Mosharafa St., Alexandria", "Egypt"),
            ("Orient Overseas Container Line (OOCL) / أو أو سي إل مصر", "OOLU", "https://www.oocl.com/eng/ourservices/eservices/cargotracking/Pages/cargotracking.aspx", "https://www.oocl.com", "caiibcsv@oocl.com", "alexibcsv@oocl.com", "+20 2 2414 4000 / +20 3 487 3500", "12 Hassan Allam St., Heliopolis, Cairo / Alexandria", "Egypt"),
            ("Korea Marine Transport Co., Ltd. (KMTC Line) / كي إم تي سي", "KMTC", "https://www.ekmtc.com/", "https://www.ekmtc.com", "kmtcegypt@kmtc.co.kr", None, "+20 2 2269 1100", "Heliopolis, Cairo", "Egypt"),
            ("SeaLead Shipping / سي ليد شيبنج", "SEAU", "https://sea-lead.com/tracking/", "https://sea-lead.com", "egypt@sea-lead.com", None, "+20 2 2417 6000", "Sheraton, Cairo", "Egypt"),
            ("Grimaldi Group (Grimaldi Lines) / جريمالدي لاينز", "GRIU", "https://www.grimaldi.napoli.it/en/cargo_tracking.html", "https://www.grimaldi.napoli.it", "info@grimaldi.napoli.it", None, "+20 3 487 1234", "Alexandria Port Area / Cairo Office", "Egypt"),
            ("SITC International Holdings Co., Ltd. / إس آي تي سي", "SITC", "https://www.sitc.com/en/tracking.html", "https://www.sitc.com", "info@sitc.com", None, "+20 2 2268 7700", "Cairo / Alexandria", "Egypt"),
            ("Ignazio Messina & C. S.p.A. / ميسينا لاين", "LMCU", "https://www.messinaline.it/tracking/", "https://www.messinaline.it", "egypt@messinaline.com", None, "+20 3 486 9900", "El-Sultan Hussein St., Alexandria", "Egypt"),
        ]

        existing_providers = db.query(ExternalServiceProvider).all()
        existing_scacs = {p.scac_code for p in existing_providers if p.scac_code}
        max_partner_idx = len(existing_providers)

        for name, scac, track_url, web, mail, sec_mail, ph, addr, ctry in shipping_lines_data:
            if scac not in existing_scacs:
                max_partner_idx += 1
                db.add(ExternalServiceProvider(
                    partner_code=f"ESP-{max_partner_idx:06d}",
                    partner_name=name,
                    partner_type="Shipping Line",
                    scac_code=scac,
                    tracking_url=track_url,
                    website=web,
                    email=mail,
                    secondary_email=sec_mail,
                    phone=ph,
                    address=addr,
                    country=ctry,
                    payment_type="Credit",
                    credit_limit=0.0,
                    rating=5.0,
                    is_active=True,
                    created_by="SYSTEM_SEED",
                ))
        db.commit()
        print("Core International Shipping Lines (MD-009B) seeded successfully.")

        print("Core Reference Tables populated successfully.")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_data()
