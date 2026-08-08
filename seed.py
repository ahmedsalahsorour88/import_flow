from datetime import datetime, timedelta, timezone
from database.database import SessionLocal, Base, engine
from update_db_schema import migrate_db

# Import models
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.users.model import User
from modules.auth.security import hash_password
from modules.incoterms.model import Incoterm, CostItem, IncotermResponsibility
from modules.customs_tariff.model import CustomsTariff
from modules.transport_locations.model import TransportLocation
from modules.currencies.model import Currency, ExchangeRate
from modules.projects.model import Project
from modules.cbm_calculator.model import CBMCalculation, CBMCalculationItem
from modules.purchase_orders.model import POLineItem, PurchaseOrder
from modules.shipping_scenarios.model import ShippingEvaluationSession, ShippingScenarioItem


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
        # 1. Seed Egyptian Import Companies (MD-001)
        # ==================================================
        if db.query(ImportCompany).count() == 0:
            print("Seeding Egyptian Import Companies (MD-001)...")
            now = datetime.now(timezone.utc)
            companies = [
                ImportCompany(
                    importer_name="Pharaohs Trading & Import LLC",
                    address="12 Ramses Square, Downtown, Cairo",
                    country="Egypt",
                    importer_id="IMP-100200",
                    importer_id_expiry=now + timedelta(days=240),
                    vat_id="VAT-998877665",
                    vat_id_expiry=now + timedelta(days=320),
                    registration_number="REG-554433221",
                    registration_expiry=now + timedelta(days=180),
                    phone="+20 2 2577 8899",
                    is_active=True,
                ),
                ImportCompany(
                    importer_name="Nile Delta Industrial Supplies S.A.E.",
                    address="Industrial Zone 3, 6th of October City, Giza",
                    country="Egypt",
                    importer_id="IMP-300400",
                    importer_id_expiry=now + timedelta(days=15),  # Triggers warning badge
                    vat_id="VAT-887766554",
                    vat_id_expiry=now + timedelta(days=400),
                    registration_number="REG-443322110",
                    registration_expiry=now + timedelta(days=90),
                    phone="+20 2 3833 1122",
                    is_active=True,
                ),
                ImportCompany(
                    importer_name="Alexandria Machinery & Spare Parts Co.",
                    address="45 El-Horreya Avenue, Alexandria",
                    country="Egypt",
                    importer_id="IMP-500600",
                    importer_id_expiry=now + timedelta(days=500),
                    vat_id="VAT-776655443",
                    vat_id_expiry=now + timedelta(days=365),
                    registration_number="REG-332211009",
                    registration_expiry=now - timedelta(days=10),  # Expired
                    phone="+20 3 488 9900",
                    is_active=True,
                ),
            ]
            db.add_all(companies)
            db.commit()
            print("Egyptian Import Companies seeded.")

        # ==================================================
        # 2. Seed Foreign Exporters & Suppliers (MD-002)
        # ==================================================
        if db.query(Supplier).count() == 0:
            print("Seeding Foreign Suppliers & Exporters (MD-002)...")
            suppliers = [
                Supplier(
                    supplier_code="SUP-000001",
                    company_name="Zhejiang Heavy Industrial Tools Co.",
                    supplier_type="Manufacturer",
                    registration_type="Factory",
                    foreign_exporter_id="EXP-CN-887744",
                    foreign_exporter_country="China",
                    foreign_exporter_country_code="CN",
                    address="No. 188 Binjiang Road, Hangzhou, Zhejiang, China",
                    phone="+86 571 8899 0011",
                    email="sales@zhejiangtools.cn",
                    brands="Zhejiang Heavy, ProPower Tools",
                    is_active=True,
                ),
                Supplier(
                    supplier_code="SUP-000002",
                    company_name="Bavaria Automotive & Motors GmbH",
                    supplier_type="Manufacturer",
                    registration_type="Company",
                    foreign_exporter_id="EXP-DE-554433",
                    foreign_exporter_country="Germany",
                    foreign_exporter_country_code="DE",
                    address="Industriestrasse 42, Munich, Germany",
                    phone="+49 89 1234 5678",
                    email="export@bavaria-motors.de",
                    brands="Bavaria Auto, German Precision",
                    is_active=True,
                ),
                Supplier(
                    supplier_code="SUP-000003",
                    company_name="Tokyo Electronics & Microchips Corp.",
                    supplier_type="Trader",
                    registration_type="Company",
                    foreign_exporter_id="EXP-JP-991122",
                    foreign_exporter_country="Japan",
                    foreign_exporter_country_code="JP",
                    address="Chiyoda-ku, Tokyo 100-0001, Japan",
                    phone="+81 3 5555 0199",
                    email="orders@tokyoelectro.jp",
                    brands="Tokyo Tech, ChipMaster",
                    is_active=True,
                ),
                Supplier(
                    supplier_code="SUP-000004",
                    company_name="Milan Fashion & Textile SRL",
                    supplier_type="Manufacturer",
                    registration_type="Factory",
                    foreign_exporter_id="EXP-IT-332211",
                    foreign_exporter_country="Italy",
                    foreign_exporter_country_code="IT",
                    address="Via Montenapoleone 15, Milan, Italy",
                    phone="+39 02 7600 1234",
                    email="contact@milantextile.it",
                    brands="Milan Luxury Fabrics",
                    is_active=True,
                ),
            ]
            db.add_all(suppliers)
            db.commit()
            print("Foreign Suppliers seeded.")

        # ==================================================
        # 3. Seed External Partners & Banks (MD-003)
        # ==================================================
        if db.query(ExternalServiceProvider).count() == 0:
            print("Seeding External Partners, Banks & Shipping Lines (MD-003)...")
            partners = [
                ExternalServiceProvider(
                    partner_code="ESP-000001",
                    partner_name="National Bank of Egypt (NBE)",
                    partner_type="Bank",
                    swift_code="NBEGEGXCAXXX",
                    bank_code="NBE",
                    branch_name="Main Treasury Branch, Cairo",
                    tax_id="TAX-NBE-100200",
                    country="Egypt",
                    payment_type="Credit",
                    rating=5.0,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000002",
                    partner_name="Commercial International Bank (CIB)",
                    partner_type="Bank",
                    swift_code="CIBEGEXX",
                    bank_code="CIB",
                    branch_name="Zamalek Corporate Center",
                    tax_id="TAX-CIB-300400",
                    country="Egypt",
                    payment_type="Credit",
                    rating=4.9,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000003",
                    partner_name="Maersk Line Shipping",
                    partner_type="Shipping Line, Freight Forwarder",
                    scac_code="MAEU",
                    tracking_url="https://www.maersk.com/tracking/",
                    country="Denmark",
                    phone="+20 2 2480 1100",
                    email="egypt.import@maersk.com",
                    payment_type="Credit",
                    rating=4.8,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000004",
                    partner_name="Mediterranean Shipping Company (MSC)",
                    partner_type="Shipping Line",
                    scac_code="MSKU",
                    tracking_url="https://www.msc.com/track/",
                    country="Switzerland",
                    phone="+20 3 4800 2200",
                    email="info@msc-egypt.com",
                    payment_type="Credit",
                    rating=4.7,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000005",
                    partner_name="El-Ahram Customs Clearance & Logistics",
                    partner_type="Customs Broker, Freight Forwarder",
                    clearance_license_number="LIC-CAI-778899",
                    commercial_register="REG-EGY-991122",
                    tax_id="TAX-EGY-445566",
                    contact_person="Eng. Ahmed El-Sayed",
                    phone="+20 100 123 4567",
                    email="clearance@elahram-logistics.com",
                    country="Egypt",
                    payment_type="Deferred",
                    rating=4.9,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000006",
                    partner_name="SGS Inspection & Testing Services Egypt",
                    partner_type="Inspection Agency",
                    commercial_register="REG-INS-5544",
                    tax_id="TAX-INS-8899",
                    contact_person="Dr. Hassan Mahmoud",
                    phone="+20 2 2735 9900",
                    email="egypt.inspection@sgs.com",
                    country="Egypt",
                    payment_type="Cash",
                    rating=5.0,
                    is_active=True,
                ),
                ExternalServiceProvider(
                    partner_code="ESP-000007",
                    partner_name="Nile Heavy Freight & Inland Transport",
                    partner_type="Inland Transport",
                    commercial_register="REG-TRN-1122",
                    phone="+20 122 333 4444",
                    email="dispatch@niletransport.com",
                    country="Egypt",
                    payment_type="Deferred",
                    rating=4.6,
                    is_active=True,
                ),
            ]
            db.add_all(partners)
            db.commit()
            print("External Partners, Banks & Shipping Lines seeded.")

        # ==================================================
        # 4. Seed Incoterms 2020 (MD-006)
        # ==================================================
        if db.query(Incoterm).count() == 0:
            print("Seeding Incoterms 2020 (MD-006)...")
            incoterms = [
                Incoterm(incoterm_code="EXW", incoterm_name="Ex Works", version="Incoterms 2020",
                         description="المشتري يتحمل كل التكاليف والمخاطر من مستودع البائع. أقل التزاماً للبائع."),
                Incoterm(incoterm_code="FCA", incoterm_name="Free Carrier", version="Incoterms 2020",
                         description="البائع يسلم البضاعة للناقل في نقطة محددة. المشتري يدفع الشحن الرئيسي."),
                Incoterm(incoterm_code="FAS", incoterm_name="Free Alongside Ship", version="Incoterms 2020",
                         description="البائع يضع البضاعة بجانب السفينة. يُستخدم في الشحن البحري فقط."),
                Incoterm(incoterm_code="FOB", incoterm_name="Free On Board", version="Incoterms 2020",
                         description="البائع يُحمّل البضاعة على السفينة. الأكثر شيوعاً في الاستيراد المصري."),
                Incoterm(incoterm_code="CFR", incoterm_name="Cost and Freight", version="Incoterms 2020",
                         description="البائع يدفع تكلفة الشحن حتى ميناء الوصول. المشتري يتحمل التأمين والمخاطر بعد الشحن."),
                Incoterm(incoterm_code="CIF", incoterm_name="Cost, Insurance and Freight", version="Incoterms 2020",
                         description="البائع يدفع الشحن والتأمين. القيمة الجمركية = CIF. الأساس في حساب الجمارك."),
                Incoterm(incoterm_code="CPT", incoterm_name="Carriage Paid To", version="Incoterms 2020",
                         description="البائع يدفع الشحن لوجهة محددة. يُستخدم في جميع وسائل النقل."),
                Incoterm(incoterm_code="CIP", incoterm_name="Carriage and Insurance Paid To", version="Incoterms 2020",
                         description="البائع يدفع الشحن والتأمين الكامل. تغطية تأمينية أعلى من CIF."),
                Incoterm(incoterm_code="DAP", incoterm_name="Delivered at Place", version="Incoterms 2020",
                         description="البائع يوصل البضاعة لمكان الوصول. المشتري يتحمل التخليص الجمركي والرسوم."),
                Incoterm(incoterm_code="DPU", incoterm_name="Delivered at Place Unloaded", version="Incoterms 2020",
                         description="البائع يوصل ويفرغ البضاعة في المكان المحدد. يحل محل DAT."),
                Incoterm(incoterm_code="DDP", incoterm_name="Delivered Duty Paid", version="Incoterms 2020",
                         description="أقصى التزام للبائع. البائع يدفع كل شيء بما فيه الجمارك والضرائب."),
            ]
            db.add_all(incoterms)
            db.commit()
            print("Incoterms 2020 seeded successfully.")

        # ==================================================
        # 5. Seed Cost Items (MD-006A)
        # ==================================================
        if db.query(CostItem).count() == 0:
            print("Seeding Cost Items (MD-006A)...")
            cost_items = [
                # Freight
                CostItem(cost_item_code="OFR", cost_item_name="Ocean Freight", cost_category="Freight",
                         description="تكلفة الشحن البحري من ميناء الشحن لميناء الوصول"),
                CostItem(cost_item_code="OTHC", cost_item_name="Origin THC (Terminal Handling)", cost_category="Port",
                         description="رسوم مناولة الحاوية في ميناء الشحن"),
                CostItem(cost_item_code="DTHC", cost_item_name="Destination THC (Terminal Handling)", cost_category="Port",
                         description="رسوم مناولة الحاوية في ميناء الوصول"),
                CostItem(cost_item_code="OTRK", cost_item_name="Origin Trucking", cost_category="Freight",
                         description="نقل البضاعة من المستودع لميناء الشحن"),
                CostItem(cost_item_code="DTRK", cost_item_name="Destination / Inland Transport", cost_category="Freight",
                         description="نقل البضاعة من ميناء الوصول للمستودع"),
                # Insurance
                CostItem(cost_item_code="INS", cost_item_name="Insurance", cost_category="Freight",
                         description="تأمين على البضاعة أثناء الشحن"),
                # Customs
                CostItem(cost_item_code="CUST", cost_item_name="Customs Clearance Fees", cost_category="Customs",
                         description="أتعاب المستخلص الجمركي"),
                CostItem(cost_item_code="DUTY", cost_item_name="Import Duties & Taxes", cost_category="Customs",
                         description="ضريبة الوارد وضريبة القيمة المضافة والضرائب الجمركية"),
                CostItem(cost_item_code="FORM4", cost_item_name="Form 4 (Bank Form)", cost_category="Bank",
                         description="رسوم نموذج 4 البنكي لتحويل قيمة البضاعة"),
                # Port
                CostItem(cost_item_code="STG", cost_item_name="Storage / Demurrage", cost_category="Port",
                         description="رسوم الأرضية والتخزين في الميناء"),
                CostItem(cost_item_code="DMRG", cost_item_name="Demurrage (Container)", cost_category="Port",
                         description="غرامة تأخير الحاوية عن الموعد المقرر"),
                CostItem(cost_item_code="PCONG", cost_item_name="Port Congestion Surcharge", cost_category="Port",
                         description="رسوم الازدحام الميناني"),
                # Other
                CostItem(cost_item_code="XINSP", cost_item_name="Origin Inspection", cost_category="Other",
                         description="تكلفة فحص البضاعة في بلد الصادر"),
                CostItem(cost_item_code="DOC", cost_item_name="Documentation Fees", cost_category="Other",
                         description="رسوم المستندات (B/L, Certificates, etc.)"),
                CostItem(cost_item_code="XCMP", cost_item_name="Compliance / Regulatory Fees", cost_category="Other",
                         description="رسوم الامتثال والجهات الرقابية"),
            ]
            db.add_all(cost_items)
            db.commit()
            print("Cost Items seeded successfully.")

        # ==================================================
        # 6. Seed Responsibility Matrix (MD-006B)
        # For FOB and CIF as the most common incoterms
        # ==================================================
        if db.query(IncotermResponsibility).count() == 0:
            print("Seeding Incoterm Responsibility Matrix (MD-006B)...")
            # Fetch seeded records
            fob = db.query(Incoterm).filter(Incoterm.incoterm_code == "FOB").first()
            cif = db.query(Incoterm).filter(Incoterm.incoterm_code == "CIF").first()
            cfr = db.query(Incoterm).filter(Incoterm.incoterm_code == "CFR").first()
            exw = db.query(Incoterm).filter(Incoterm.incoterm_code == "EXW").first()
            ddp = db.query(Incoterm).filter(Incoterm.incoterm_code == "DDP").first()

            ofr = db.query(CostItem).filter(CostItem.cost_item_code == "OFR").first()
            ins = db.query(CostItem).filter(CostItem.cost_item_code == "INS").first()
            othc = db.query(CostItem).filter(CostItem.cost_item_code == "OTHC").first()
            dthc = db.query(CostItem).filter(CostItem.cost_item_code == "DTHC").first()
            otrk = db.query(CostItem).filter(CostItem.cost_item_code == "OTRK").first()
            dtrk = db.query(CostItem).filter(CostItem.cost_item_code == "DTRK").first()
            cust = db.query(CostItem).filter(CostItem.cost_item_code == "CUST").first()
            duty = db.query(CostItem).filter(CostItem.cost_item_code == "DUTY").first()
            form4 = db.query(CostItem).filter(CostItem.cost_item_code == "FORM4").first()

            responsibilities = []

            # --- FOB: Seller pays origin; Buyer pays freight, insurance, destination ---
            if fob and ofr:
                for (inc_id, ci_id, party, included) in [
                    (fob.incoterm_id, otrk.cost_item_id, "Exporter", True),
                    (fob.incoterm_id, othc.cost_item_id, "Exporter", True),
                    (fob.incoterm_id, ofr.cost_item_id, "Importer", False),
                    (fob.incoterm_id, ins.cost_item_id, "Importer", False),
                    (fob.incoterm_id, dthc.cost_item_id, "Importer", False),
                    (fob.incoterm_id, dtrk.cost_item_id, "Importer", False),
                    (fob.incoterm_id, cust.cost_item_id, "Importer", False),
                    (fob.incoterm_id, duty.cost_item_id, "Importer", False),
                    (fob.incoterm_id, form4.cost_item_id, "Importer", False),
                ]:
                    responsibilities.append(IncotermResponsibility(
                        incoterm_id=inc_id, cost_item_id=ci_id,
                        responsible_party=party, included_in_incoterm=included
                    ))

            # --- CIF: Seller pays freight + insurance; Buyer pays destination + customs ---
            if cif and ofr:
                for (inc_id, ci_id, party, included) in [
                    (cif.incoterm_id, otrk.cost_item_id, "Exporter", True),
                    (cif.incoterm_id, othc.cost_item_id, "Exporter", True),
                    (cif.incoterm_id, ofr.cost_item_id, "Exporter", True),
                    (cif.incoterm_id, ins.cost_item_id, "Exporter", True),
                    (cif.incoterm_id, dthc.cost_item_id, "Importer", False),
                    (cif.incoterm_id, dtrk.cost_item_id, "Importer", False),
                    (cif.incoterm_id, cust.cost_item_id, "Importer", False),
                    (cif.incoterm_id, duty.cost_item_id, "Importer", False),
                    (cif.incoterm_id, form4.cost_item_id, "Importer", False),
                ]:
                    responsibilities.append(IncotermResponsibility(
                        incoterm_id=inc_id, cost_item_id=ci_id,
                        responsible_party=party, included_in_incoterm=included
                    ))

            # --- EXW: Buyer pays everything ---
            if exw and ofr:
                for (inc_id, ci_id, party, included) in [
                    (exw.incoterm_id, otrk.cost_item_id, "Importer", False),
                    (exw.incoterm_id, othc.cost_item_id, "Importer", False),
                    (exw.incoterm_id, ofr.cost_item_id, "Importer", False),
                    (exw.incoterm_id, ins.cost_item_id, "Importer", False),
                    (exw.incoterm_id, dthc.cost_item_id, "Importer", False),
                    (exw.incoterm_id, cust.cost_item_id, "Importer", False),
                    (exw.incoterm_id, duty.cost_item_id, "Importer", False),
                ]:
                    responsibilities.append(IncotermResponsibility(
                        incoterm_id=inc_id, cost_item_id=ci_id,
                        responsible_party=party, included_in_incoterm=included
                    ))

            # --- DDP: Seller pays everything including duties ---
            if ddp and ofr:
                for (inc_id, ci_id, party, included) in [
                    (ddp.incoterm_id, otrk.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, othc.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, ofr.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, ins.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, dthc.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, dtrk.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, cust.cost_item_id, "Exporter", True),
                    (ddp.incoterm_id, duty.cost_item_id, "Exporter", True),
                ]:
                    responsibilities.append(IncotermResponsibility(
                        incoterm_id=inc_id, cost_item_id=ci_id,
                        responsible_party=party, included_in_incoterm=included
                    ))

            if responsibilities:
                db.add_all(responsibilities)
                db.commit()
            print("Incoterm Responsibility Matrix seeded successfully.")

        # ==================================================
        # 7. Seed Customs Tariff / HS Codes (MD-008)
        # ==================================================
        if db.query(CustomsTariff).count() == 0:
            print("Seeding Customs Tariff / HS Codes (MD-008)...")
            from datetime import date
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
                    notes="يتطلب موافقة الجهاز القومي لتنظيم الاتصالات (NTRA)",
                ),
                CustomsTariff(
                    hs_code="8517.13.00",
                    hs_description="Smartphones and cellular devices",
                    customs_category="Electronics",
                    customs_duty_rate=10.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=10.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="NTRA",
                    effective_from=date(2024, 1, 1),
                    notes="رسم تنمية 10% بموجب تعديلات القانون الجمركي",
                ),
                CustomsTariff(
                    hs_code="8471.70.00",
                    hs_description="Storage units for data processing machines (SSD & Hard Drives)",
                    customs_category="Electronics",
                    customs_duty_rate=2.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=False,
                    requires_acid=True,
                    regulatory_authority=None,
                    effective_from=date(2023, 6, 1),
                ),
                CustomsTariff(
                    hs_code="8703.23.90",
                    hs_description="Motor vehicles with spark-ignition internal combustion engine (>1500cc <=3000cc)",
                    customs_category="Automotive",
                    customs_duty_rate=40.00,
                    vat_rate=14.00,
                    schedule_tax_rate=15.00,
                    development_fee_rate=8.00,
                    import_fee_rate=3.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="Ministry of Industry & Trade, GOEIC",
                    effective_from=date(2024, 1, 1),
                    notes="خاضع لضريبة الجدول 15% ورسم التنمية 8%",
                ),
                CustomsTariff(
                    hs_code="8708.29.90",
                    hs_description="Other parts and accessories of motor vehicle bodies",
                    customs_category="Automotive Parts",
                    customs_duty_rate=12.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC (General Organization for Export & Import Control)",
                    effective_from=date(2024, 1, 1),
                ),
                CustomsTariff(
                    hs_code="3004.90.90",
                    hs_description="Medicaments consisting of mixed or unmixed products for therapeutic uses",
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
                    effective_from=date(2023, 1, 1),
                    notes="معفى من ضريبة الوارد والقيمة المضافة لتشجيع القطاع الطبي",
                ),
                CustomsTariff(
                    hs_code="1001.99.00",
                    hs_description="Wheat and meslin (Other than durum wheat)",
                    customs_category="Agriculture & Food",
                    customs_duty_rate=0.00,
                    vat_rate=0.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="Quarantine, GOEIC, Food Safety Authority",
                    effective_from=date(2023, 1, 1),
                    notes="سلعة استراتيجية أساسية — معفاة من الرسوم الجمركية",
                ),
                CustomsTariff(
                    hs_code="1701.99.90",
                    hs_description="Cane or beet sugar in solid form (Refined sugar)",
                    customs_category="Agriculture & Food",
                    customs_duty_rate=20.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="National Food Safety Authority (NFSA)",
                    effective_from=date(2024, 1, 1),
                ),
                CustomsTariff(
                    hs_code="5208.11.00",
                    hs_description="Plain weave woven fabrics of cotton, containing >= 85% cotton",
                    customs_category="Textiles & Apparel",
                    customs_duty_rate=15.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2024, 1, 1),
                ),
                CustomsTariff(
                    hs_code="6203.42.00",
                    hs_description="Men's or boys' trousers and shorts of cotton",
                    customs_category="Textiles & Apparel",
                    customs_duty_rate=30.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC (Factory Registration Decree 43 Required)",
                    effective_from=date(2024, 1, 1),
                    notes="يتطلب تسجيل المصنع في الهيئة العامة للرقابة على الصادرات والواردات (قرار 43)",
                ),
                CustomsTariff(
                    hs_code="7208.39.00",
                    hs_description="Flat-rolled products of iron or non-alloy steel, hot-rolled (Thickness < 3mm)",
                    customs_category="Metals & Industrial",
                    customs_duty_rate=5.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="Industrial Development Authority (IDA)",
                    effective_from=date(2023, 6, 1),
                ),
                CustomsTariff(
                    hs_code="3901.10.00",
                    hs_description="Polyethylene having a specific gravity of less than 0.94 (Primary forms)",
                    customs_category="Chemicals & Plastics",
                    customs_duty_rate=2.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=False,
                    requires_acid=True,
                    regulatory_authority="Egyptian Environmental Affairs Agency (EEAA)",
                    effective_from=date(2023, 1, 1),
                ),
                CustomsTariff(
                    hs_code="8418.10.00",
                    hs_description="Combined refrigerator-freezers, fitted with separate external doors",
                    customs_category="Home Appliances",
                    customs_duty_rate=60.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=5.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="EOS (Egyptian Organization for Standardization), GOEIC",
                    effective_from=date(2024, 1, 1),
                    notes="حمائية للصناعة الوطنية — رسم صادر وجمرك مرتفع 60%",
                ),
                CustomsTariff(
                    hs_code="2208.30.00",
                    hs_description="Whiskies",
                    customs_category="Luxury Goods",
                    customs_duty_rate=300.00,
                    vat_rate=14.00,
                    schedule_tax_rate=150.00,
                    development_fee_rate=10.00,
                    import_fee_rate=5.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="Ministry of Finance & Tax Authority",
                    effective_from=date(2024, 1, 1),
                    notes="سلعة كمالية — فئات جمركية استثنائية (300% جمرك + 150% جدول)",
                ),
                CustomsTariff(
                    hs_code="8409.91.00",
                    hs_description="Parts suitable for use solely or principally with spark-ignition engines",
                    customs_category="Machinery & Industrial Parts",
                    customs_duty_rate=5.00,
                    vat_rate=14.00,
                    schedule_tax_rate=0.00,
                    development_fee_rate=0.00,
                    import_fee_rate=0.00,
                    requires_coo=True,
                    requires_inspection=True,
                    requires_acid=True,
                    regulatory_authority="GOEIC",
                    effective_from=date(2023, 1, 1),
                ),
            ]
            db.add_all(tariffs)
            db.commit()
            print("Customs Tariff / HS Codes seeded successfully.")

        # ==================================================
        # 8. Seed MD-009: Transport Locations
        # ==================================================
        from modules.transport_locations.model import TransportLocation
        if db.query(TransportLocation).count() == 0:
            print("Seeding Transport Locations (MD-009)...")
            locations = [
                # Egyptian Sea Ports
                TransportLocation(un_locode="EGALY", location_name="Alexandria Port", location_type="Sea Port", country="Egypt", city="Alexandria", notes="Main Egyptian Mediterranean Port"),
                TransportLocation(un_locode="EGSOK", location_name="Ain Sokhna Port", location_type="Sea Port", country="Egypt", city="Ain Sokhna", notes="Red Sea Deepwater Hub"),
                TransportLocation(un_locode="EGPSD", location_name="Port Said West Port", location_type="Sea Port", country="Egypt", city="Port Said"),
                TransportLocation(un_locode="EGPSE", location_name="Port Said East Container Terminal", location_type="Sea Port", country="Egypt", city="Port Said"),
                TransportLocation(un_locode="EGDAM", location_name="Damietta Port", location_type="Sea Port", country="Egypt", city="Damietta"),
                TransportLocation(un_locode="EGDKH", location_name="El Dekheila Port", location_type="Sea Port", country="Egypt", city="Alexandria"),
                TransportLocation(un_locode="EGSGA", location_name="Safaga Port", location_type="Sea Port", country="Egypt", city="Red Sea"),
                TransportLocation(un_locode="EGADB", location_name="Adabiya Port", location_type="Sea Port", country="Egypt", city="Suez"),
                # Egyptian Airports
                TransportLocation(un_locode="EGCAI", location_name="Cairo International Airport", location_type="Airport", country="Egypt", city="Cairo", notes="Primary Air Cargo Hub"),
                TransportLocation(un_locode="EGHBE", location_name="Borg El Arab International Airport", location_type="Airport", country="Egypt", city="Alexandria"),
                TransportLocation(un_locode="EGLXU", location_name="Luxor International Airport", location_type="Airport", country="Egypt", city="Luxor"),
                TransportLocation(un_locode="EGSSH", location_name="Sharm El Sheikh International Airport", location_type="Airport", country="Egypt", city="Sharm El Sheikh"),
                # Egyptian Dry Ports & Land Borders
                TransportLocation(un_locode="EG6OCT", location_name="6th of October Dry Port", location_type="Dry Port", country="Egypt", city="6th of October", notes="First inland dry port in Egypt"),
                TransportLocation(un_locode="EGSLM", location_name="Salloum Land Border Port", location_type="Land Border", country="Egypt", city="Matrouh", notes="Libya Border Gate"),
                TransportLocation(un_locode="EGARG", location_name="Argeen Land Border Port", location_type="Land Border", country="Egypt", city="Aswan", notes="Sudan Border Crossing"),
                TransportLocation(un_locode="EGQAS", location_name="Qastal Land Border Port", location_type="Land Border", country="Egypt", city="Aswan", notes="Sudan Border Crossing"),
                # Major International Hubs
                TransportLocation(un_locode="CNSHA", location_name="Shanghai Port", location_type="Sea Port", country="China", city="Shanghai", notes="World's Busiest Container Port"),
                TransportLocation(un_locode="CNNGB", location_name="Ningbo-Zhoushan Port", location_type="Sea Port", country="China", city="Ningbo"),
                TransportLocation(un_locode="CNSZX", location_name="Shenzhen Port", location_type="Sea Port", country="China", city="Shenzhen"),
                TransportLocation(un_locode="CNCAN", location_name="Guangzhou Port", location_type="Sea Port", country="China", city="Guangzhou"),
                TransportLocation(un_locode="NLRTM", location_name="Rotterdam Port", location_type="Sea Port", country="Netherlands", city="Rotterdam", notes="Europe's Largest Port"),
                TransportLocation(un_locode="DEHAM", location_name="Hamburg Port", location_type="Sea Port", country="Germany", city="Hamburg"),
                TransportLocation(un_locode="AEJEA", location_name="Jebel Ali Port", location_type="Sea Port", country="United Arab Emirates", city="Dubai", notes="Middle East Logistics Hub"),
                TransportLocation(un_locode="USNYC", location_name="Port of New York & New Jersey", location_type="Sea Port", country="United States", city="New York"),
                TransportLocation(un_locode="GBLON", location_name="London Gateway Port", location_type="Sea Port", country="United Kingdom", city="London"),
                TransportLocation(un_locode="GBLHR", location_name="London Heathrow Airport", location_type="Airport", country="United Kingdom", city="London"),
                TransportLocation(un_locode="USJFK", location_name="New York JFK International Airport", location_type="Airport", country="United States", city="New York"),
                TransportLocation(un_locode="DEFRA", location_name="Frankfurt Airport Cargo City", location_type="Airport", country="Germany", city="Frankfurt"),
                TransportLocation(un_locode="AEDXB", location_name="Dubai International Airport", location_type="Airport", country="United Arab Emirates", city="Dubai"),
            ]
            db.add_all(locations)
            db.commit()
            print("Transport Locations (MD-009) seeded successfully.")

        # ==================================================
        # 9. Seed MD-004: Currencies & Exchange Rates
        # ==================================================
        from modules.currencies.model import Currency, ExchangeRate
        from datetime import date
        if db.query(Currency).count() == 0:
            print("Seeding Currencies & Exchange Rates (MD-004)...")
            currencies_data = [
                Currency(currency_code="EGP", currency_name="Egyptian Pound", currency_symbol="E£", is_base_currency=True, decimal_places=2),
                Currency(currency_code="USD", currency_name="US Dollar", currency_symbol="$", is_base_currency=False, decimal_places=2),
                Currency(currency_code="EUR", currency_name="Euro", currency_symbol="€", is_base_currency=False, decimal_places=2),
                Currency(currency_code="GBP", currency_name="British Pound", currency_symbol="£", is_base_currency=False, decimal_places=2),
                Currency(currency_code="CNY", currency_name="Chinese Yuan (Renminbi)", currency_symbol="¥", is_base_currency=False, decimal_places=2),
                Currency(currency_code="JPY", currency_name="Japanese Yen", currency_symbol="¥", is_base_currency=False, decimal_places=2),
                Currency(currency_code="SAR", currency_name="Saudi Riyal", currency_symbol="ر.س", is_base_currency=False, decimal_places=2),
                Currency(currency_code="AED", currency_name="UAE Dirham", currency_symbol="د.إ", is_base_currency=False, decimal_places=2),
                Currency(currency_code="CHF", currency_name="Swiss Franc", currency_symbol="CHF", is_base_currency=False, decimal_places=2),
            ]
            db.add_all(currencies_data)
            db.commit()

            # Seed initial rates against EGP
            curr_map = {c.currency_code: c.currency_id for c in db.query(Currency).all()}
            today = date.today()
            rates_data = [
                ExchangeRate(currency_id=curr_map["USD"], commercial_rate=50.25, customs_rate=50.10, effective_date=today),
                ExchangeRate(currency_id=curr_map["EUR"], commercial_rate=54.80, customs_rate=54.65, effective_date=today),
                ExchangeRate(currency_id=curr_map["GBP"], commercial_rate=63.90, customs_rate=63.75, effective_date=today),
                ExchangeRate(currency_id=curr_map["CNY"], commercial_rate=6.95, customs_rate=6.90, effective_date=today),
                ExchangeRate(currency_id=curr_map["JPY"], commercial_rate=0.34, customs_rate=0.33, effective_date=today),
                ExchangeRate(currency_id=curr_map["SAR"], commercial_rate=13.40, customs_rate=13.35, effective_date=today),
                ExchangeRate(currency_id=curr_map["AED"], commercial_rate=13.68, customs_rate=13.64, effective_date=today),
                ExchangeRate(currency_id=curr_map["CHF"], commercial_rate=56.70, customs_rate=56.55, effective_date=today),
            ]
            db.add_all(rates_data)
            db.commit()
            print("Currencies & Exchange Rates (MD-004) seeded successfully.")

        # ==================================================
        # 10. Seed Projects Module
        # ==================================================
        if db.query(Project).count() == 0:
            print("Seeding Projects Module...")
            c1 = db.query(ImportCompany).first()
            s1 = db.query(Supplier).first()
            i1 = db.query(Incoterm).first()

            if c1 and s1 and i1:
                projects = [
                    Project(
                        project_code="PRJ-2026-001",
                        project_name="Ain Sokhna Industrial Solar Power Expansion",
                        project_owner="Eng. Hassan Mahmoud",
                        company_id=c1.company_id,
                        supplier_id=s1.supplier_id,
                        incoterm_id=i1.incoterm_id,
                        import_type="Project Equipment / معدات مشروعات",
                        priority="High",
                        shipment_category="Multimodal (Sea + Inland)",
                        allow_multi_shipment=True,
                        allow_multi_company=True,
                        total_budget_usd=1500000.00,
                        status="Open",
                        notes="مشروع توريد وتدشين محطة طاقة شمسية — شحن على عدة دفعات ومستندات مستقلة لكل شحنة.",
                    ),
                    Project(
                        project_code="PRJ-2026-002",
                        project_name="6th October Factory Raw Materials Supply Q3",
                        project_owner="Sara Al-Sayed",
                        company_id=c1.company_id,
                        supplier_id=s1.supplier_id,
                        incoterm_id=i1.incoterm_id,
                        import_type="Direct Commercial",
                        priority="Medium",
                        shipment_category="FCL Container",
                        allow_multi_shipment=True,
                        allow_multi_company=True,
                        total_budget_usd=450000.00,
                        status="Open",
                        notes="توريد المواد الخام لمصنع 6 أكتوبر على 4 شحنات حاويات خلال الربع الثالث.",
                    ),
                ]
                db.add_all(projects)
                db.commit()
                print("Projects Module seeded successfully.")

        # ==================================================
        # 10. Seed Purchase Orders (BP-001 / BP-002)
        # ==================================================
        from modules.purchase_orders.model import POLineItem, PurchaseOrder

        if db.query(PurchaseOrder).count() == 0:
            print("Seeding Purchase Orders...")
            proj = db.query(Project).first()
            comp = db.query(ImportCompany).first()
            supp = db.query(Supplier).first()
            inco = db.query(Incoterm).first()
            curr = db.query(Currency).filter(Currency.currency_code == "USD").first() or db.query(Currency).first()
            tariff = db.query(CustomsTariff).first()

            if proj and comp and supp and inco and curr:
                po1 = PurchaseOrder(
                    po_number="PO-2026-001",
                    proforma_invoice_number="PI-EUR-99823",
                    project_id=proj.project_id,
                    company_id=comp.company_id,
                    supplier_id=supp.supplier_id,
                    incoterm_id=inco.incoterm_id,
                    currency_id=curr.currency_id,
                    order_date=datetime.now(timezone.utc),
                    exchange_rate=50.25,
                    payment_terms="LC at Sight 100%",
                    status="Approved",
                    total_amount_fob=125000.00,
                    total_cbm=45.5,
                    total_gross_weight_kg=12500.00,
                    total_net_weight_kg=11800.00,
                    total_packages_count=200,
                    notes="أمر شراء توريد الألواح الشمسية ومحولات الطاقة لمشروع السخنة",
                )
                item1 = POLineItem(
                    item_code="SOLAR-PANEL-550W",
                    description_ar="ألواح طاقة شمسية 550 واط عالية الكفاءة",
                    description_en="High Efficiency 550W Monocrystalline Solar Panels",
                    tariff_id=tariff.tariff_id if tariff else None,
                    quantity=200.0,
                    unit_of_measure="PCS",
                    unit_price=625.00,
                    total_price=125000.00,
                    cbm_per_unit=0.2275,
                    total_cbm=45.5,
                    gross_weight_kg=12500.00,
                    net_weight_kg=11800.00,
                )
                po1.line_items.append(item1)
                db.add(po1)
                db.commit()
                print("Purchase Orders seeded successfully.")

        # ==================================================
        # 10. Seed CBM Calculation Sessions
        # ==================================================
        if db.query(CBMCalculation).count() == 0:
            print("Seeding CBM Calculation Sessions...")
            po = db.query(PurchaseOrder).first()
            proj = db.query(Project).first()

            calc1 = CBMCalculation(
                calc_code="CALC-2026-001",
                title="حساب قياسات شحنة المحولات والألواح الشمسية - ميعاد الشحن الأسبوع القادم",
                project_id=proj.project_id if proj else None,
                po_id=po.po_id if po else None,
                total_qty=110,
                total_cbm=45.5,
                total_gross_weight_kg=12500.0,
                total_volumetric_weight_kg=7583.33,
                air_chargeable_weight_kg=12500.0,
                recommended_shipping_method="FCL Container (حاوية كاملة بحرية)",
                recommended_container_type="40FT Standard Container (40' ST)",
                recommended_container_count=1,
                notes="تم حساب الأبعاد الكلية وفق مواصفات المصنع بالصين للمجموعة الأولى",
            )
            item_cbm1 = CBMCalculationItem(
                package_type="Pallet",
                quantity=100,
                length_cm=120.0,
                width_cm=100.0,
                height_cm=160.0,
                gross_weight_per_unit_kg=110.0,
                total_cbm=30.72,
                volumetric_weight_kg=5120.0,
                total_gross_weight_kg=11000.0,
            )
            item_cbm2 = CBMCalculationItem(
                package_type="Wooden Crate",
                quantity=10,
                length_cm=150.0,
                width_cm=110.0,
                height_cm=90.0,
                gross_weight_per_unit_kg=150.0,
                total_cbm=14.85,
                volumetric_weight_kg=2475.0,
                total_gross_weight_kg=1500.0,
            )
            calc1.items.append(item_cbm1)
            calc1.items.append(item_cbm2)
            db.add(calc1)
            db.commit()
            print("CBM Calculation Sessions seeded successfully.")

        # ==================================================
        # Seed Shipping Scenarios Evaluation (BP-007)
        # ==================================================
        if db.query(ShippingEvaluationSession).count() == 0:
            print("Seeding Shipping Scenario Evaluation Studies...")
            po = db.query(PurchaseOrder).first()
            proj = db.query(Project).first()
            pol = db.query(TransportLocation).filter(TransportLocation.un_locode == "CNSHA").first()
            pod = db.query(TransportLocation).filter(TransportLocation.un_locode == "EGALY").first()

            crd = datetime.now().date() + timedelta(days=5)

            sce1 = ShippingEvaluationSession(
                session_code="SCE-2026-001",
                title="دراسة مقارنة خيارات وسيناريوهات شحن محولات محطة الإسماعيلية - Shanghai to Alexandria",
                cargo_ready_date=crd,
                port_of_loading_id=pol.location_id if pol else None,
                port_of_discharge_id=pod.location_id if pod else None,
                avg_form4_days=5,
                avg_clearance_days=7,
                po_id=po.po_id if po else None,
                project_id=proj.project_id if proj else None,
                notes="دراسة مقارنة الخطوط الملاحية المتاحة لشهر أغسطس 2026 لمراعاة مواعيد التسليم بالموقع",
            )

            item1 = ShippingScenarioItem(
                provider_name="COSCO Shipping",
                vessel_name="COSCO SHIPPING UNIVERSE",
                voyage_number="042E",
                sailing_date=crd + timedelta(days=2),
                estimated_arrival_date=crd + timedelta(days=26),
                expected_line_delay_days=2,
                is_recommended=True,
                risk_level="Low",
                notes="أقرب موعد إبحار وتوافر حاويات HQ في ميناء شنغهاي",
            )

            item2 = ShippingScenarioItem(
                provider_name="Maersk Line",
                vessel_name="MAERSK MC-KINNEY MOLLER",
                voyage_number="2608W",
                sailing_date=crd + timedelta(days=5),
                estimated_arrival_date=crd + timedelta(days=32),
                expected_line_delay_days=4,
                is_recommended=False,
                risk_level="Medium",
                notes="ترانزيت في بيرايوس مع تكلفة شحن أقل بمقدار $300",
            )

            item3 = ShippingScenarioItem(
                provider_name="CMA CGM",
                vessel_name="CMA CGM JACQUES SAADE",
                voyage_number="8819X",
                sailing_date=crd + timedelta(days=12),
                estimated_arrival_date=crd + timedelta(days=48),
                expected_line_delay_days=7,
                is_excluded_from_average=True,
                is_recommended=False,
                risk_level="High",
                notes="تاريخ إبحار متأخر جداً ومخاطرة عالية بالتأخير بالميناء الوسيط - مستبعد من المتوسط",
            )

            sce1.items.append(item1)
            sce1.items.append(item2)
            sce1.items.append(item3)
            db.add(sce1)
            db.commit()
            print("Shipping Scenario Evaluation Studies seeded successfully.")

        print("All Database Seeder Data populated successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_data()
