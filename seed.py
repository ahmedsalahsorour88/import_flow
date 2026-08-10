from datetime import datetime, timedelta, timezone
from database.database import SessionLocal, Base, engine
from update_db_schema import migrate_db

# Import models
from modules.import_files.model import ImportFile
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
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord


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
        # 5. Seed Cost Items (MD-006A)
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
        # 6. Seed Responsibility Matrix (MD-006B)
        # ==================================================
        if db.query(IncotermResponsibility).count() == 0:
            print("Seeding Incoterm Responsibility Matrix (MD-006B)...")
            cost_item_map = {ci.cost_item_code: ci.cost_item_id for ci in db.query(CostItem).all()}
            incoterm_map = {inc.incoterm_code: inc.incoterm_id for inc.incoterm_id, inc.incoterm_code in db.query(Incoterm.incoterm_id, Incoterm.incoterm_code).all()}

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
        # 7.1 Seed Nafeza Fee Codes Registry (FeeCode)
        # ==================================================
        from modules.customs_tariff.model import FeeCode
        FEE_CODES_SEED = [
            {"code": "77",  "name_ar": "ضريبة مهن حرة",            "collection_group": "رسم مستخلص",      "calculation_type": "flat", "flat_amount": 50.00},
            {"code": "250", "name_ar": "رسم طباعة بيان جمركي موحد", "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 55.00},
            {"code": "798", "name_ar": "رسم نموذج 19 ك م",          "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 35.00},
            {"code": "60",  "name_ar": "دمغة إقرار مميكن",          "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 4.50},
            {"code": "74",  "name_ar": "رسم خدمات مميكنة",          "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 20.00},
            {"code": "107", "name_ar": "رسم تنمية محررات",          "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 2.00},
            {"code": "1",   "name_ar": "ضريبة الوارد",              "collection_group": "ضريبة جمارك",      "calculation_type": "reference", "reference_source": "duty_amount"},
            {"code": "3",   "name_ar": "رسم مصاريف إدارية",         "collection_group": "ضريبة جمارك",      "calculation_type": "flat", "flat_amount": 750.00},
            {"code": "37",  "name_ar": "ضريبة أ.ت.ص",               "collection_group": "أ.ت.ص",           "calculation_type": "reference", "reference_source": "service_fee_amount"},
            {"code": "232", "name_ar": "تحت حساب قيمة مضافة",       "collection_group": "ض.مبيعات",         "calculation_type": "flat", "flat_amount": 100.00},
            {"code": "32",  "name_ar": "ضريبة قيمة مضافة",          "collection_group": "ض.مبيعات",         "calculation_type": "reference", "reference_source": "vat_amount"},
            {"code": "397", "name_ar": "صندوق تكريم الشهداء",       "collection_group": "رسوم النافذة الموحدة", "calculation_type": "flat", "flat_amount": 5.00},
            {"code": "390", "name_ar": "خدمات جمركية",              "collection_group": "رسوم النافذة الموحدة", "calculation_type": "flat", "flat_amount": 1081.00},
            {"code": "392", "name_ar": "خدمات معلوماتية",           "collection_group": "رسوم النافذة الموحدة", "calculation_type": "flat", "flat_amount": 3457.00},
            {"code": "394", "name_ar": "ضريبة قيمة مضافة على خدمات", "collection_group": "رسوم النافذة الموحدة", "calculation_type": "derived", "derived_formula_rate": 14.00, "derived_formula_base_codes": "390,392"},
        ]
        for seed_item in FEE_CODES_SEED:
            existing = db.query(FeeCode).filter(FeeCode.code == seed_item["code"]).first()
            if existing:
                existing.name_ar = seed_item["name_ar"]
                existing.collection_group = seed_item["collection_group"]
                existing.calculation_type = seed_item["calculation_type"]
                existing.flat_amount = seed_item.get("flat_amount", 0.00)
                existing.reference_source = seed_item.get("reference_source")
                existing.derived_formula_rate = seed_item.get("derived_formula_rate")
                existing.derived_formula_base_codes = seed_item.get("derived_formula_base_codes")
            else:
                db.add(FeeCode(**seed_item))
        db.commit()
        print("Nafeza Fee Codes synced successfully.")

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

        if db.query(ExchangeRate).count() == 0:
            print("Seeding Exchange Rates (MD-004)...")
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
        # 10. Seed Projects Module (Optional Demo Data)
        # ==================================================
        if SEED_OPERATIONAL_DEMO_DATA and db.query(Project).count() == 0:
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

        if SEED_OPERATIONAL_DEMO_DATA and db.query(PurchaseOrder).count() == 0:
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
        if SEED_OPERATIONAL_DEMO_DATA and db.query(CBMCalculation).count() == 0:
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
        if SEED_OPERATIONAL_DEMO_DATA and db.query(ShippingEvaluationSession).count() == 0:
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

        # ==================================================
        # 12. Customs Consultation Studies (BP-009)
        # ==================================================
        from modules.customs_consultation.model import CustomsConsultationSession, CustomsChecklistItem

        if SEED_OPERATIONAL_DEMO_DATA and db.query(CustomsConsultationSession).count() == 0:
            print("Seeding Customs Consultation Studies (BP-009)...")
            broker = db.query(ExternalServiceProvider).filter(ExternalServiceProvider.partner_type.like("%Customs Broker%")).first()
            broker_id = broker.provider_id if broker else 1
            broker_name = broker.partner_name if broker else "El-Ahram Customs Clearance"

            cus1 = CustomsConsultationSession(
                consultation_code="CUS-2026-001",
                title="دراسة المراجعة الجمركية الأولية لخط إنتاج الآلات الصناعية (شحنة شنغهاي)",
                broker_id=broker_id,
                broker_name=broker_name,
                broker_contact_person="أستاذ محمود عبد العال (مستخلص جمركي قدير)",
                overall_status="In Progress",
                estimated_duties_egp=165801.50,
                notes="تطلب مراجعة شهادة الفحص المسبق وهيئة الصادرات والواردات قبل إصدار ACID وقبل الفاتورة النهائية.",
                is_active=True,
            )

            c_items = [
                CustomsChecklistItem(
                    document_type="Proforma Invoice",
                    hs_code="8479.89.90",
                    is_required=True,
                    is_blocking_shipment=True,
                    responsible_party="Supplier / Exporter",
                    status="Approved",
                    received_date=date(2026, 8, 1),
                    verified_date=date(2026, 8, 2),
                    remarks="الفاتورة المبدئية معتمدة ومطابقة لأسعار البند الجمركي.",
                ),
                CustomsChecklistItem(
                    document_type="Packing List",
                    hs_code="8479.89.90",
                    is_required=True,
                    is_blocking_shipment=True,
                    responsible_party="Supplier / Exporter",
                    status="Approved",
                    received_date=date(2026, 8, 1),
                    verified_date=date(2026, 8, 2),
                    remarks="قائمة التعبئة تحتوي على صافي الإجمالي وإجمالي القائم والأحجام بالـ CBM.",
                ),
                CustomsChecklistItem(
                    document_type="Certificate of Origin (COO)",
                    hs_code="8479.89.90",
                    is_required=True,
                    is_blocking_shipment=True,
                    responsible_party="Customs Broker",
                    status="Verified",
                    received_date=date(2026, 8, 4),
                    verified_date=date(2026, 8, 5),
                    remarks="مطلوب تصديق الغرفة التجارية والسفارة المصرية في شنغهاي.",
                ),
                CustomsChecklistItem(
                    document_type="Inspection Certificate (GOEIC)",
                    hs_code="8479.89.90",
                    is_required=True,
                    is_blocking_shipment=True,
                    responsible_party="Customs Broker",
                    status="Pending",
                    regulatory_agency="GOEIC (هيئة الرقابة على الصادرات والواردات)",
                    remarks="بانتظار الفحص الظاهري وعينات المعمل الجمركي فور الوصول.",
                    corrective_action_required="تجهيز الكتالوجات الفنية والرسم التخطيطي للآلات.",
                ),
            ]

            cus1.checklist_items.extend(c_items)
            db.add(cus1)
            db.commit()
            print("Customs Consultation Studies seeded successfully.")

        # ==================================================
        # 13. Freight Quotations RFQ (BP-008)
        # ==================================================
        from modules.freight_quotations.model import FreightRFQRequest, FreightQuotationItem

        if SEED_OPERATIONAL_DEMO_DATA and db.query(FreightRFQRequest).count() == 0:
            print("Seeding Freight RFQ Requests (BP-008)...")
            maersk = db.query(ExternalServiceProvider).filter(ExternalServiceProvider.partner_name.like("%Maersk%")).first()
            msc = db.query(ExternalServiceProvider).filter(ExternalServiceProvider.partner_name.like("%MSC%")).first()

            maersk_id = maersk.provider_id if maersk else 1
            msc_id = msc.provider_id if msc else 2

            crd = date(2026, 8, 25)

            rfq1 = FreightRFQRequest(
                rfq_code="RFQ-2026-001",
                title="طلب عرض سعر شحن 2 حاويات 40ft High Cube من شنغهاي إلى الإسكندرية",
                shipping_method="Ocean FCL",
                crd_date=crd,
                pol_name="Shanghai Port (CN SHA), China",
                pod_name="Alexandria Port (EG ALX), Egypt",
                total_cbm=128.5,
                total_gross_weight_kg=48500.0,
                chargeable_weight_kg=48500.0,
                status="Awarded",
                notes="طلب مقارنة وتثبيت أسعار النولون البحري لشحنة معدات النسيج.",
                is_active=True,
            )

            q1 = FreightQuotationItem(
                provider_id=maersk_id,
                provider_name="Maersk Line Shipping",
                vessel_name="MAERSK MC-KINNEY MOLLER",
                voyage_number="2608W",
                currency_code="USD",
                ocean_freight_cost=3400.0,
                local_charges_cost=450.0,
                inland_cost=300.0,
                total_cost=4150.0,
                sailing_date=crd + timedelta(days=4),
                estimated_arrival_date=crd + timedelta(days=28),
                transit_days=24,
                free_days_at_pod=14,
                is_awarded=True,
                remarks="العرض الأسرع ترانزيت مع 14 يوم سماح بميناء الإسكندرية.",
            )

            q2 = FreightQuotationItem(
                provider_id=msc_id,
                provider_name="Mediterranean Shipping Company (MSC)",
                vessel_name="MSC ISABELLA",
                voyage_number="9904A",
                currency_code="USD",
                ocean_freight_cost=3200.0,
                local_charges_cost=500.0,
                inland_cost=350.0,
                total_cost=4050.0,
                sailing_date=crd + timedelta(days=8),
                estimated_arrival_date=crd + timedelta(days=36),
                transit_days=28,
                free_days_at_pod=21,
                is_awarded=False,
                remarks="نولون أقل بـ $100 مع 21 يوم سماح بالجمارك.",
            )

            rfq1.quotations.extend([q1, q2])
            db.add(rfq1)
            db.commit()

            rfq1.selected_quotation_id = q1.quotation_id
            db.commit()
            print("Freight RFQ Requests seeded successfully.")

        # ==================================================
        # 16. Seed Phase 2 Financial Approval (BP-012 & BP-013)
        # ==================================================
        from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval

        if SEED_OPERATIONAL_DEMO_DATA and db.query(PaymentRequestSession).count() == 0:
            print("Seeding Payment Requests & Import Budgets (BP-012 & BP-013)...")
            pay1 = PaymentRequestSession(
                payment_code="PAY-2026-001",
                title="طلب صرف دفعة مقدمة (Advance Payment 30%) للمورد الأجنبي",
                supplier_name="Shanghai Machinery & Textile Exports Ltd.",
                payment_type="Advance Payment",
                requested_amount=18690.0,
                currency_code="USD",
                exchange_rate=50.0,
                requested_amount_egp=934500.0,
                due_date=date(2026, 8, 20),
                request_date=date(2026, 8, 8),
                status="Approved",
                beneficiary_name="Shanghai Machinery Exports Ltd.",
                bank_name="Bank of China Shanghai Branch",
                swift_code="BKCHCN2SXXX",
                iban_account_no="CN980100987654321",
                bank_country="China",
                notes="دفعة مقدمة 30% لبدء تجهيز الشحنة وتثبيت طلب الشراء.",
                is_active=True,
            )
            db.add(pay1)

            bgt1 = ImportBudgetApproval(
                budget_code="BGT-2026-001",
                title="اعتماد الميزانية الاستيرادية الكلية لشحنة آلات ومعدات النسيج",
                invoice_amount_egp=3115000.0,
                freight_cost_egp=207500.0,
                customs_duties_egp=829000.0,
                clearance_inland_egp=75000.0,
                total_budget_egp=4226500.0,
                budget_status="Budget Approved",
                approved_by="Finance Director",
                approved_date=date(2026, 8, 8),
                notes="اعتماد كافة مكونات التكلفة وتغطية السيولة النقدية بالشامل.",
                is_active=True,
            )
            db.add(bgt1)
            db.commit()
            print("Phase 2 Financial Approval seeded successfully.")

        # ==================================================
        # 17. Seed Phase 3 Import Documentation (BP-014 to BP-019)
        # ==================================================
        from modules.import_documentation.model import (
            AcidRegistrationSession,
            BankingDocumentSession,
            ShipmentDocumentItem,
            CustomsDeclarationDraft,
        )

        if SEED_OPERATIONAL_DEMO_DATA and db.query(AcidRegistrationSession).count() == 0:
            print("Seeding Import Documentation & Nafeza ACI (BP-014 to BP-019)...")
            acid1 = AcidRegistrationSession(
                acid_code="ACID-2026-001",
                acid_number="1987654321098765432",
                importer_name="المصرية الحديثة للتنسيج والغزل ش.م.م",
                importer_tax_id="100-200-300",
                exporter_name="Shanghai Machinery & Textile Exports Ltd.",
                exporter_reg_id="CN-SH-987654",
                exporter_country="China",
                proforma_invoice_no="PI-2026-SH09",
                pol_name="Shanghai Port (CN SHA), China",
                pod_name="Alexandria Port (EG ALX), Egypt",
                requested_date=date(2026, 8, 1),
                generated_date=date(2026, 8, 2),
                expiry_date=date(2026, 11, 2),
                is_importer_matched=True,
                is_exporter_matched=True,
                is_invoice_matched=True,
                is_ports_matched=True,
                verification_notes="تمت المطابقة التلقائية 100% ورقم الـ ACID صالح ومطابق على منصة نافذة.",
                status="Verified",
                is_active=True,
            )
            db.add(acid1)

            bdoc1 = BankingDocumentSession(
                bank_doc_code="FORM4-2026-001",
                doc_type="Form 4",
                bank_name="National Bank of Egypt (NBE)",
                doc_reference_number="F4-2026-99081",
                amount=62300.0,
                currency_code="USD",
                issue_date=date(2026, 8, 5),
                expiry_date=date(2026, 12, 31),
                status="Form Issued",
                notes="تم إصدار نموذج 4 بنكي معتمد للتحويل السريع وصحيفة السداد.",
                is_active=True,
            )
            db.add(bdoc1)

            sdoc1 = ShipmentDocumentItem(
                document_code="DOC-2026-001",
                doc_name="Commercial Invoice (الفاتورة التجارية)",
                doc_number="INV-2026-SH990",
                issue_date=date(2026, 8, 6),
                received_date=date(2026, 8, 7),
                status="Approved",
                is_cargox_uploaded=True,
                cargox_envelope_id="ENV-CGX-2026-887766",
                is_bl_endorsed=False,
                notes="تم الرفع وتأكيد الغلاف الرقمي على منصة CargoX.",
                is_active=True,
            )

            sdoc2 = ShipmentDocumentItem(
                document_code="DOC-2026-002",
                doc_name="Bill of Lading (بوليصة الشحن)",
                doc_number="MAEU987654321",
                issue_date=date(2026, 8, 8),
                received_date=date(2026, 8, 8),
                status="Endorsed",
                is_cargox_uploaded=True,
                cargox_envelope_id="ENV-CGX-2026-887766",
                is_bl_endorsed=True,
                endorsement_number="END-BL-2026-112233",
                notes="تم التظهير الملاحي لبوليصة الشحن الأصلية بنجاح.",
                is_active=True,
            )
            db.add_all([sdoc1, sdoc2])

            dec1 = CustomsDeclarationDraft(
                declaration_code="DEC46-2026-001",
                acid_number="1987654321098765432",
                form4_number="F4-2026-99081",
                bl_number="MAEU987654321",
                total_cif_val_egp=3322500.0,
                total_customs_duties_egp=332250.0,
                total_vat_egp=511665.0,
                declaration_status="Draft Prepared",
                is_active=True,
            )
            db.add(dec1)

            db.commit()
            print("Phase 3 Import Documentation seeded successfully.")

        # ==================================================
        # 18. Seed Import Files Master & Tracking (6701068100)
        # ==================================================
        from modules.import_files.model import ImportFile

        if SEED_OPERATIONAL_DEMO_DATA and db.query(ImportFile).count() == 0:
            print("Seeding Import Files Master & Tracking...")
            file1 = ImportFile(
                import_file_code="IMP-2026-0001",
                custom_file_number="6701068100",
                company_name="المصرية الحديثة للتنسيج والغزل ش.م.م",
                supplier_name="ABC China",
                po_number="PO-1001",
                pi_number="PI-889",
                invoices_data=[
                    {"invoice_no": "PI-889", "invoice_type": "Proforma Invoice", "date": "2026-08-01", "amount": 24500.0, "currency": "USD"},
                    {"invoice_no": "INV-2026-SH990", "invoice_type": "Commercial Invoice", "date": "2026-08-06", "amount": 24500.0, "currency": "USD"}
                ],
                packing_lists_data=[
                    {"pl_no": "PL-889", "date": "2026-08-01", "total_packages": 50, "gross_weight_kg": 12000.0, "cbm": 35.5}
                ],
                shipment_mode="Sea",
                incoterm_code="FOB",
                priority="High",
                shipment_category="New Purchase",
                required_eta=date(2026, 8, 15),
                selected_scenario="MSC Option",
                form4_no="F4-2026-99081",
                swift_no="SW-NBE-887711",
                form46_no="DEC46-2026-001",
                estimated_cost=24500.0,
                current_module="BP-019 Prepare Customs Declaration 46",
                current_stage="Phase 3: Import Documentation & ACI",
                progress_percent=65.0,
                next_action="Customs Inspection & Duty Settlement (Phase 6/7)",
                status="Open",
                owner="Kamal",
                notes="ملف استيراد شحنة معدات وآلات غزل مبدئي من الصين عبر مسار MSC.",
                is_active=True,
            )
            db.add(file1)
            db.commit()
            print("Import Files Master seeded successfully.")

        # ==================================================
        # 19. Seed Phase 4 Freight Booking & Container Allocation
        # ==================================================
        from modules.freight_booking.model import ShipmentBooking

        if SEED_OPERATIONAL_DEMO_DATA and db.query(ShipmentBooking).count() == 0:
            print("Seeding Phase 4 Freight Booking...")
            bkg1 = ShipmentBooking(
                booking_code="BKG-2026-0001",
                booking_confirmation_no="MSC-CN-889001",
                freight_forwarder_name="El-Ahram Logistics",
                shipping_line_name="Mediterranean Shipping Company (MSC)",
                shipment_type="Ocean FCL",
                pol_name="Shanghai Port (CNSHA)",
                pod_name="Alexandria Port (EGALY)",
                etd=datetime(2026, 8, 10, 10, 0, tzinfo=timezone.utc),
                eta=datetime(2026, 8, 28, 14, 0, tzinfo=timezone.utc),
                transit_time_days=18,
                free_demurrage_days=14,
                vessel_name="MSC Oscar",
                voyage_number="VY-2026-X8",
                container_release_order_no="RO-MSC-9912",
                freight_terms="Collect",
                containers_data=[
                    {
                        "container_type": "40HC",
                        "quantity": 2,
                        "container_numbers": ["MSCU1234567", "MSCU7654321"],
                        "seal_numbers": ["SL-99001", "SL-99002"],
                        "vgm_weight_kg": 24500.0
                    }
                ],
                cost_charges_data=[
                    {"charge_type": "Sea Freight", "unit": "Per Container", "quantity": 2, "currency": "USD", "rate": 2200.0, "total": 4400.0},
                    {"charge_type": "THC", "unit": "Per Container", "quantity": 2, "currency": "USD", "rate": 350.0, "total": 700.0},
                    {"charge_type": "BL Fee", "unit": "Per Shipment", "quantity": 1, "currency": "USD", "rate": 80.0, "total": 80.0}
                ],
                total_freight_cost_usd=5180.0,
                status="Confirmed",
                owner="Kamal",
                notes="حجز مؤكد على MSC من ميناء شانغهاي لميناء الإسكندرية.",
                is_active=True,
            )
            db.add(bkg1)
            db.commit()
            print("Phase 4 Freight Booking seeded successfully.")

        # Seed Phase 5 Cargo Shipping
        if SEED_OPERATIONAL_DEMO_DATA and db.query(CargoShippingRecord).count() == 0:
            imp = db.query(ImportFile).filter(ImportFile.is_active == True).first()
            bkg = db.query(ShipmentBooking).filter(ShipmentBooking.is_active == True).first()
            imp_id = imp.import_file_id if imp else 1
            bkg_id = bkg.booking_id if bkg else 1

            shp1 = CargoShippingRecord(
                cargo_shipping_code="SHP-2026-0001",
                import_file_id=imp_id,
                booking_id=bkg_id,
                crd_date=datetime(2026, 8, 8, 12, 0, tzinfo=timezone.utc),
                cargo_cutoff_date=datetime(2026, 8, 10, 18, 0, tzinfo=timezone.utc),
                is_crd_validated=True,
                containers_loading_data=[
                    {
                        "container_no": "MSCU1234567",
                        "seal_no": "SL-99001",
                        "tare_weight_kg": 3800.0,
                        "net_weight_kg": 20700.0,
                        "gross_weight_kg": 24500.0,
                        "vgm_status": "Submitted",
                        "vgm_ref_no": "VGM-MSC-9901"
                    },
                    {
                        "container_no": "MSCU7654321",
                        "seal_no": "SL-99002",
                        "tare_weight_kg": 3800.0,
                        "net_weight_kg": 20700.0,
                        "gross_weight_kg": 24500.0,
                        "vgm_status": "Submitted",
                        "vgm_ref_no": "VGM-MSC-9902"
                    }
                ],
                level1_approval_status="Approved",
                level1_approved_by="Operational Lead",
                level1_approved_at=datetime(2026, 8, 9, 10, 0, tzinfo=timezone.utc),
                level1_notes="تمت مراجعة أرقام الحاويات، ACID، والأوزان الفنية ومطابقتها.",
                level2_approval_status="Approved",
                level2_approved_by="Import Manager",
                level2_approved_at=datetime(2026, 8, 9, 11, 30, tzinfo=timezone.utc),
                level2_notes="اعتماد ثنائي نهائي مأذون به للشحن.",
                dual_approval_status="Dual Approved",
                courier_tracking_data={
                    "courier_provider": "DHL Express",
                    "tracking_number": "DHL-9876543210",
                    "dispatch_date": "2026-08-09T08:00:00Z",
                    "receipt_status": "Received at Office",
                    "received_at": "2026-08-09T14:00:00Z",
                    "received_by": "Kamal"
                },
                cargox_exchange_data={
                    "platform_provider": "CargoX Platform",
                    "envelope_id": "ENV-CGX-2026-0001",
                    "envelope_status": "Checklist Passed",
                    "blockchain_tx_hash": "0xBC7789A990001FA88321",
                    "verification_checklist": [
                        {"rule_name": "ACID Number Validity & Verification", "passed": True, "details": "Verified on Nafeza"},
                        {"rule_name": "Commercial Invoice & Consignee Match", "passed": True, "details": "Matched"},
                        {"rule_name": "Bill of Lading (BL) & Container List Match", "passed": True, "details": "Matched"},
                        {"rule_name": "Dual Approval Level 1 & Level 2 Status", "passed": True, "details": "Dual Approved"}
                    ]
                },
                live_tracking_url="https://www.msc.com/track/?number=MSCU1234567",
                status="Dual Approved",
                owner="Kamal",
                notes="سجل تجهيز الشحنة والتحميل مراجَع ومُعتمد ثنائياً.",
                is_active=True,
            )
            db.add(shp1)
            db.commit()
            print("Phase 5 Cargo Shipping seeded successfully.")

        print("All Database Seeder Data populated successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_data()
