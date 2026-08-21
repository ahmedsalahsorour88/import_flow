"""
ImportFlow ERP — Clean Production Database Generator
Creates a pristine production database containing ONLY core standard reference tables:
- Ports & Transport Locations (MD-009)
- Currencies & Official Exchange Rates (MD-004)
- Customs Tariff & HS Codes & Nafeza Fee Codes (MD-008)
- Incoterms 2020 & Responsibility Matrix & Cost Items (MD-006 / 006A / 006B)
- Core System Users & RBAC Roles (MD-000)

All demo companies, suppliers, service providers, shipments, POs, and price lists are completely wiped.
"""
import os
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT_DIR))

from database.database import SessionLocal, Base, engine
from update_db_schema import migrate_db

# Import all Models
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.users.model import User
from modules.auth.security import hash_password
from modules.audit_logs.model import AuditLog
from modules.incoterms.model import Incoterm, CostItem, IncotermResponsibility
from modules.customs_tariff.model import CustomsTariff, FeeCode
from modules.transport_locations.model import TransportLocation
from modules.currencies.model import Currency, ExchangeRate
from modules.projects.model import Project
from modules.purchase_orders.model import POLineItem, PurchaseOrder
from modules.cbm_calculator.model import CBMCalculation, CBMCalculationItem
from modules.shipping_scenarios.model import ShippingEvaluationSession, ShippingScenarioItem
from modules.customs_consultation.model import CustomsConsultationSession, CustomsChecklistItem, ClearanceExpenseType, BrokerPriceList
from modules.freight_quotations.model import FreightRFQRequest, FreightQuotationItem
from modules.customs_clearance_quotations.model import CustomsClearanceRFQ, CustomsClearanceQuotationItem, ClearanceServicePriceListItem
from modules.financial_approval.model import PaymentRequestSession, ImportBudgetApproval
from modules.import_documentation.model import (
    AcidRegistrationSession,
    BankingDocumentSession,
    ShipmentDocumentItem,
    CustomsDeclarationDraft,
    POPackingReconciliationSession,
)
from modules.import_files.model import ImportFile
from modules.freight_booking.model import ShipmentBooking
from modules.cargo_shipping.model import CargoShippingRecord
from modules.customs_clearance.model import CustomsClearanceRecord
from modules.warehouse_receiving.model import WarehouseReceivingRecord
from modules.financial_settlement.model import LandedCostSettlementRecord
from modules.file_closure.model import ImportFileClosureRecord
from modules.notifications.model import SystemNotification
from modules.smart_tasks.model import SmartTask
from modules.shipment_updates.model import ShipmentUpdateLog
from modules.demurrage_detention.model import DemurragePolicy, DemurrageTracking
from modules.smart_document_upload.model import UploadSession
from modules.docs_customs_approval.model import CustomsDocumentApproval, DiscrepancyRectificationTicket
from modules.cargox.model import CargoXEnvelope, CargoXEnvelopeDocument, CargoXStandardInvoiceReviewSession
from modules.original_documents_collection.model import OriginalDocumentsCollectionSession


def build_clean_production_db():
    print("================================================================================")
    print("           ImportFlow ERP - Generating Clean Production Database                ")
    print("================================================================================")

    db_file = ROOT_DIR / "sorour_logistics.db"
    if db_file.exists():
        try:
            db_file.unlink()
            print(f"Removed previous database: {db_file}")
        except Exception as e:
            print(f"Could not unlink db file directly ({e}), dropping all tables instead.")
            Base.metadata.drop_all(bind=engine)

    # 1. Create all database tables
    Base.metadata.create_all(bind=engine)
    migrate_db()
    print("Database schema created and migrated.")

    db = SessionLocal()

    try:
        # ==================================================
        # 1. Seed Core System Users & Roles (RBAC)
        # ==================================================
        print("[1/5] Seeding System Users & Roles...")
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

        # ==================================================
        # 2. Seed Incoterms 2020, Cost Items & Matrix
        # ==================================================
        print("[2/5] Seeding Incoterms 2020 & Responsibility Matrix (MD-006)...")
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

        # ==================================================
        # 3. Seed Customs Tariff & HS Codes & Nafeza Codes (MD-008)
        # ==================================================
        print("[3/5] Seeding Egyptian Customs Tariff & HS Codes (MD-008)...")
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

        # Seed Nafeza Fee Codes
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

        # ==================================================
        # 4. Seed Transport Locations & Ports (MD-009)
        # ==================================================
        print("[4/5] Seeding Egyptian Ports & Transport Locations (MD-009)...")
        ports = [
            TransportLocation(un_locode="EGALY", location_name="Alexandria Port (ميناء الإسكندرية)", location_type="Port", country="Egypt", city="Alexandria", is_active=True),
            TransportLocation(un_locode="EGDKH", location_name="El-Dekheila Port (ميناء الدخيلة)", location_type="Port", country="Egypt", city="Alexandria", is_active=True),
            TransportLocation(un_locode="EGPSD", location_name="Port Said West (ميناء غرب بورسعيد)", location_type="Port", country="Egypt", city="Port Said", is_active=True),
            TransportLocation(un_locode="EGPSE", location_name="Port Said East (ميناء شرق بورسعيد)", location_type="Port", country="Egypt", city="Port Said", is_active=True),
            TransportLocation(un_locode="EGDAM", location_name="Damietta Port (ميناء دمياط)", location_type="Port", country="Egypt", city="Damietta", is_active=True),
            TransportLocation(un_locode="EGSOK", location_name="Sokhna Port (ميناء العين السخنة)", location_type="Port", country="Egypt", city="Suez", is_active=True),
            TransportLocation(un_locode="EGSUZ", location_name="Suez Port (ميناء السويس - بورتوفيق)", location_type="Port", country="Egypt", city="Suez", is_active=True),
            TransportLocation(un_locode="EGADA", location_name="Adabiya Port (ميناء الأدبية)", location_type="Port", country="Egypt", city="Suez", is_active=True),
            TransportLocation(un_locode="EGCAI", location_name="Cairo International Airport Cargo Terminal (قرية البضائع بمطار القاهرة)", location_type="Airport", country="Egypt", city="Cairo", is_active=True),
            TransportLocation(un_locode="EG6OCT", location_name="6th of October Dry Port (الميناء الجاف بمدينة 6 أكتوبر)", location_type="Dry Port", country="Egypt", city="Giza", is_active=True),
            TransportLocation(un_locode="EG10R", location_name="10th of Ramadan Dry Port (الميناء الجاف بمدينة العاشر من رمضان)", location_type="Dry Port", country="Egypt", city="Sharqia", is_active=True),
            TransportLocation(un_locode="EGSAD", location_name="Sadat City Inland Logistics Center (المركز اللوجستي بمدينة السادات)", location_type="Warehouse", country="Egypt", city="Monufia", is_active=True),
        ]
        db.add_all(ports)
        db.commit()

        # ==================================================
        # 5. Seed Currencies & Exchange Rates (MD-004)
        # ==================================================
        print("[5/5] Seeding Official Currencies & Exchange Rates (MD-004)...")
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
        # Verification Summary
        # ==================================================
        print("================================================================================")
        print("                 Clean Production Database Verification                         ")
        print("================================================================================")
        print(f" - System Users:        {db.query(User).count()} (Admin, Manager, Specialist)")
        print(f" - Ports & Locations:   {db.query(TransportLocation).count()} (MD-009)")
        print(f" - Currencies:          {db.query(Currency).count()} (MD-004)")
        print(f" - Exchange Rates:      {db.query(ExchangeRate).count()} (MD-004)")
        print(f" - Customs Tariffs:     {db.query(CustomsTariff).count()} (MD-008)")
        print(f" - Incoterms 2020:      {db.query(Incoterm).count()} (MD-006)")
        print(f" - Responsibility Rules:{db.query(IncotermResponsibility).count()} (MD-006B)")
        print("--------------------------------------------------------------------------------")
        print(f" - Import Companies:    {db.query(ImportCompany).count()} (Clean - Empty)")
        print(f" - Foreign Suppliers:   {db.query(Supplier).count()} (Clean - Empty)")
        print(f" - Partners & Banks:    {db.query(ExternalServiceProvider).count()} (Clean - Empty)")
        print(f" - Import Files:        {db.query(ImportFile).count()} (Clean - Empty)")
        print(f" - Purchase Orders:     {db.query(PurchaseOrder).count()} (Clean - Empty)")
        print(f" - Projects:            {db.query(Project).count()} (Clean - Empty)")
        print("================================================================================")
        print("[SUCCESS] Clean Production Database successfully generated!")
        print("================================================================================")
        return True

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Database creation failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = build_clean_production_db()
    sys.exit(0 if success else 1)
