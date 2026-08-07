from datetime import datetime, timedelta, timezone
from database.database import SessionLocal, Base, engine
from update_db_schema import migrate_db

# Import models
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.users.model import User
from modules.auth.security import hash_password


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

        print("All Database Seeder Data populated successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding data: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_data()
