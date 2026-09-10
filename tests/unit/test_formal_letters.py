"""
Unit Tests for AI Formal Letter Drafting (AI-DRAFT-014)
"""

import pytest
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.external_service_providers.model import ExternalServiceProvider
from modules.import_files.model import ImportFile
from modules.freight_booking.model import ShipmentBooking
from modules.import_documentation.model import CustomsDeclarationDraft
from modules.formal_letters.schemas import FormalLetterGenerateRequest
from modules.formal_letters.service import (
    get_available_templates_service,
    generate_formal_letter_service,
    get_file_letter_history_service,
)
import modules.formal_letters.repository as repo


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    company = ImportCompany(
        importer_name="شركة النيل الدولية للمعدات الصناعية",
        country="Egypt",
        address="المنطقة الصناعية، العاشر من رمضان، مصر",
        importer_id="IMP-EG-8822",
        importer_id_expiry=date(2030, 1, 1),
        vat_id="300-400-500",
        vat_id_expiry=date(2030, 1, 1),
        registration_number="CR-774411",
        registration_expiry=date(2030, 1, 1),
    )
    supplier = Supplier(
        company_name="Shanghai Heavy Machinery Co.",
        supplier_code="SUP-SH-001",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="EXP-CN-5544",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Pudong, Shanghai, China",
    )
    broker = ExternalServiceProvider(
        partner_code="BRK-ALX-01",
        partner_name="مكتب الصفا للخدمات الجمركية",
        partner_type="Customs Broker",
        clearance_license_number="LIC-ALX-9944",
    )
    session.add_all([company, supplier, broker])
    session.commit()

    import_file = ImportFile(
        import_file_code="IMP-2026-00999",
        company_id=company.company_id,
        company_name=company.importer_name,
        supplier_id=supplier.supplier_id,
        supplier_name=supplier.company_name,
        broker_id=broker.provider_id,
        broker_name=broker.partner_name,
        po_number="PO-2026-5501",
        acid_number="9876543210123456789",
        port_of_discharge="ميناء الإسكندرية البحري",
        estimated_cost=85000.0,
        estimated_cost_currency="USD",
        status="Open",
        current_stage="Phase 4 - Customs Clearance",
        required_eta=date(2026, 9, 25),
    )
    session.add(import_file)
    session.commit()

    booking = ShipmentBooking(
        booking_code="BKG-2026-999",
        import_file_id=import_file.import_file_id,
        vessel_name="COSCO SHIPPING TAURUS",
        voyage_number="044E",
        shipping_line_name="COSCO Shipping Lines",
    )
    decl = CustomsDeclarationDraft(
        declaration_code="DEC-2026-999",
        import_file_id=import_file.import_file_id,
        acid_number=import_file.acid_number,
        bl_number="COSU9876543210",
        declaration_status="Draft Prepared",
    )
    session.add_all([booking, decl])
    session.commit()

    yield session
    session.close()


class TestFormalLetterDrafting:
    def test_get_available_templates(self):
        templates = get_available_templates_service()
        assert len(templates) == 4
        types = [t.template_type for t in templates]
        assert "demurrage_extension" in types
        assert "bank_delegation" in types
        assert "bank_form4" in types
        assert "customs_broker_mandate" in types

    def test_generate_demurrage_extension_letter(self, db_session):
        file = db_session.query(ImportFile).first()
        req = FormalLetterGenerateRequest(
            import_file_id=file.import_file_id,
            template_type="demurrage_extension",
            recipient_name="توكيل كوسكو شيبنج مصر",
            extension_days=28,
            custom_notes="نظراً لتأخر صدور نتائج عينات الإشعاع",
        )
        res = generate_formal_letter_service(db_session, req, user="LogisticsManager")

        assert res.letter_id is not None
        assert res.letter_code.startswith("LTR-")
        assert res.import_file_code == "IMP-2026-00999"
        assert "COSU9876543210" in res.letter_body
        assert "COSCO SHIPPING TAURUS" in res.letter_body
        assert "شركة النيل الدولية للمعدات الصناعية" in res.letter_body
        assert "28" in res.letter_body
        assert "نظراً لتأخر صدور نتائج عينات الإشعاع" in res.letter_body

        # Verify saved in history
        history = repo.get_letters_by_file(db_session, file.import_file_id)
        assert len(history) == 1
        assert history[0].letter_code == res.letter_code

    def test_generate_bank_delegation_letter(self, db_session):
        file = db_session.query(ImportFile).first()
        req = FormalLetterGenerateRequest(
            import_file_id=file.import_file_id,
            template_type="bank_delegation",
            bank_name="البنك الأهلي المصري",
            bank_branch="فرع مصطفى النحاس",
            broker_name="أحمد فتحي الدسوقي",
            broker_license="LIC-ALX-9944",
        )
        res = generate_formal_letter_service(db_session, req, user="FinanceManager")

        assert "البنك الأهلي المصري" in res.letter_body
        assert "فرع مصطفى النحاس" in res.letter_body
        assert "أحمد فتحي الدسوقي" in res.letter_body
        assert "LIC-ALX-9944" in res.letter_body
        assert "9876543210123456789" in res.letter_body
        assert "COSU9876543210" in res.letter_body

    def test_generate_bank_form4_letter(self, db_session):
        file = db_session.query(ImportFile).first()
        req = FormalLetterGenerateRequest(
            import_file_id=file.import_file_id,
            template_type="bank_form4",
            bank_name="بنك مصر",
            bank_branch="فرع طلعت حرب",
        )
        res = generate_formal_letter_service(db_session, req)

        assert "طلب استخراج نموذج (4) جمركي" in res.letter_title_ar
        assert "بنك مصر" in res.letter_body
        assert "85,000.00" in res.letter_body
        assert "USD" in res.letter_body
        assert "PO-2026-5501" in res.letter_body
        assert "CR-774411" in res.letter_body

    def test_generate_customs_broker_mandate_letter(self, db_session):
        file = db_session.query(ImportFile).first()
        req = FormalLetterGenerateRequest(
            import_file_id=file.import_file_id,
            template_type="customs_broker_mandate",
            broker_name="مكتب الصفا للخدمات الجمركية",
            broker_license="LIC-ALX-9944",
        )
        res = generate_formal_letter_service(db_session, req)

        assert "خطاب تفويض وتوكيل مخلص جمركي" in res.letter_title_ar
        assert "تفويض وتوكيل رسمي بالسير في إجراءات التخليص الجمركي" in res.letter_body
        assert "ميناء الإسكندرية البحري" in res.letter_body
        assert "مكتب الصفا للخدمات الجمركية" in res.letter_body
        assert "LIC-ALX-9944" in res.letter_body
        assert "شركة النيل الدولية للمعدات الصناعية" in res.letter_body

    def test_invalid_template_type(self, db_session):
        file = db_session.query(ImportFile).first()
        req = FormalLetterGenerateRequest(
            import_file_id=file.import_file_id,
            template_type="invalid_template",
        )
        with pytest.raises(HTTPException) as exc_info:
            generate_formal_letter_service(db_session, req)
        assert exc_info.value.status_code == 400
