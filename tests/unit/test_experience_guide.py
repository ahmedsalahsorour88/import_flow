"""
Unit tests for Smart Shipment Experience Guide (KB-GUIDE-012)
Validates CRUD, Multi-Dimensional Tagging (13 Dimensions), 4-Tier Severities,
Ranking Scores, Expiration Suppression, Upvoting, Similar Shipments, and Pattern Detection.
"""
from datetime import datetime, date, timezone, timedelta
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

from database.database import Base
from modules.experience_guide.model import GuideEntry, GuideEntryScope
from modules.experience_guide.schemas import (
    GuideEntryCreate,
    GuideEntryUpdate,
    GuideScopeCreate,
    GuideMatchRequest,
)
from modules.experience_guide.service import ExperienceGuideService
from modules.import_files.model import ImportFile


@pytest.fixture(scope="function")
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


def test_experience_guide_crud_and_validation(db_session):
    service = ExperienceGuideService(db_session)

    # 1. Create entry with valid scopes and positive severity
    entry_in = GuideEntryCreate(
        title="صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء",
        content="يجب أن يكون ميناء الوصول الإسكندرية حصراً. مطلوب شهادة منشأ أصلية.",
        entry_type="required_document",
        severity="critical",
        department="Clearance & Logistics",
        created_by="Ahmed Salah",
        scopes=[
            GuideScopeCreate(scope_type="hs_code", scope_value="8520"),
            GuideScopeCreate(scope_type="destination_port", scope_value="الإسكندرية"),
            GuideScopeCreate(scope_type="incoterm", scope_value="FOB"),
        ],
    )
    created = service.create_entry(entry_in)
    assert created.entry_id is not None
    assert created.title == "صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء"
    assert created.severity == "critical"
    assert created.department == "Clearance & Logistics"
    assert created.upvotes == 0
    assert len(created.scopes) == 3

    # 2. Positive Severity test
    positive_in = GuideEntryCreate(
        title="أفضل ممارسة: توفير 4 أيام عبر مسار الدخيلة",
        content="تم إنهاء التخليص في 3 أيام فقط عند استخدام رصيف الدخيلة مع هذا المورد.",
        entry_type="info",
        severity="positive",
        scopes=[GuideScopeCreate(scope_type="supplier", scope_value="Suzhou Yuheng")],
    )
    positive_created = service.create_entry(positive_in)
    assert positive_created.severity == "positive"

    # 3. Upvote test
    upvoted = service.upvote_entry(created.entry_id)
    assert upvoted.upvotes == 1
    upvoted2 = service.upvote_entry(created.entry_id)
    assert upvoted2.upvotes == 2

    # 4. Get entry by ID
    fetched = service.get_entry(created.entry_id)
    assert fetched.entry_id == created.entry_id
    assert fetched.title == created.title

    # 5. Update entry
    update_in = GuideEntryUpdate(
        severity="warning",
        content="تحديث: يلزم فحص المعامل بالإسكندرية قبل الإفراج الجمركي.",
    )
    updated = service.update_entry(created.entry_id, update_in)
    assert updated.severity == "warning"
    assert "تحديث" in updated.content

    # 6. List entries with search and filters
    entries = service.list_entries(search="الأكوستيك")
    assert len(entries) == 1
    assert entries[0].entry_id == created.entry_id

    entries_filtered = service.list_entries(scope_type="hs_code", scope_value="8520")
    assert len(entries_filtered) == 1

    # 7. Search entries across content and department
    searched = service.search_entries("Clearance")
    assert len(searched) >= 1
    assert searched[0].entry_id == created.entry_id

    # 8. Validation errors
    from pydantic import ValidationError

    with pytest.raises(ValidationError):
        GuideEntryCreate(
            title="",
            content="محتوى",
            entry_type="info",
            severity="info",
        )

    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="invalid_type",
            severity="info",
        ))
    assert exc.value.status_code == 422

    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="alert",
            severity="unknown_severity",
        ))
    assert exc.value.status_code == 422

    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="alert",
            severity="warning",
            scopes=[GuideScopeCreate(scope_type="invalid_dimension", scope_value="val")],
        ))
    assert exc.value.status_code == 422

    # 9. Delete entry
    deleted = service.delete_entry(created.entry_id)
    assert deleted is True

    # 10. Non-existent entry
    with pytest.raises(HTTPException) as exc:
        service.get_entry(99999)
    assert exc.value.status_code == 404


def test_multi_scope_and_ranking_engine(db_session):
    service = ExperienceGuideService(db_session)

    # Entry 1: Single dimension (Only HS Code 8520)
    entry1 = service.create_entry(GuideEntryCreate(
        title="قاعدة الأكوستيك العامة",
        content="صنف الأكوستيك يحتاج شهادة منشأ أصلية وميناء الإسكندرية.",
        entry_type="required_document",
        severity="warning",
        scopes=[GuideScopeCreate(scope_type="hs_code", scope_value="8520")],
    ))

    # Entry 2: Multi-dimension (HS 8520 AND Destination Port Alexandria AND Supplier Pioneer)
    entry2 = service.create_entry(GuideEntryCreate(
        title="أكوستيك خاص بمورد بيونير في الإسكندرية",
        content="معاملة خاصة ومستندات تأكيد مطابقة للمورد.",
        entry_type="task",
        severity="critical",
        scopes=[
            GuideScopeCreate(scope_type="hs_code", scope_value="8520"),
            GuideScopeCreate(scope_type="destination_port", scope_value="Alexandria"),
            GuideScopeCreate(scope_type="supplier", scope_value="Pioneer Corp"),
        ],
    ))

    # Entry 3: Shipping Line Maersk
    entry3 = service.create_entry(GuideEntryCreate(
        title="توجيه خط ميرسك",
        content="خط ميرسك يمنح 14 يوم سماح للحاويات.",
        entry_type="info",
        severity="info",
        scopes=[GuideScopeCreate(scope_type="shipping_line", scope_value="Maersk")],
    ))

    # Query with HS 8520, Alexandria Port, Pioneer Corp
    # Both Entry 1 and Entry 2 match, but Entry 2 has 3 matching dimensions + Critical severity -> should rank #1!
    res = service.match_shipment(GuideMatchRequest(
        hs_code="8520.10.00",
        destination_port="El Dekheila (Alexandria)",
        supplier="Pioneer Corp International",  # Tests fuzzy match on Pioneer Corp
    ))

    matched_ids = [e.entry_id for e in res.matched_entries]
    assert entry1.entry_id in matched_ids
    assert entry2.entry_id in matched_ids
    assert entry3.entry_id not in matched_ids

    # Ranking assertion: Multi-dimension + critical must rank FIRST
    assert res.matched_entries[0].entry_id == entry2.entry_id
    assert res.matched_entries[0].match_score > res.matched_entries[1].match_score
    assert "hs_code" in res.matched_entries[0].matched_dimensions
    assert "supplier" in res.matched_entries[0].matched_dimensions

    assert res.has_critical_alert is True
    assert res.has_blocking_critical_alert is True
    assert len(res.critical_entries) == 1
    assert len(res.warning_entries) == 1


def test_expiration_suppression(db_session):
    service = ExperienceGuideService(db_session)

    # 1. Expired note (yesterday)
    expired_date = datetime.now(timezone.utc) - timedelta(days=2)
    service.create_entry(GuideEntryCreate(
        title="لائحة قديمة ملغاة للبند 8520",
        content="هذا التعميم انتهت صلاحيته ولا يجب أن يظهر كإرشاد فعال.",
        entry_type="alert",
        severity="critical",
        expires_at=expired_date,
        scopes=[GuideScopeCreate(scope_type="hs_code", scope_value="8520")],
    ))

    # 2. Valid active note (future expiry)
    future_date = datetime.now(timezone.utc) + timedelta(days=60)
    active_entry = service.create_entry(GuideEntryCreate(
        title="لائحة سارية للبند 8520",
        content="تعميم فحص معتمد ساري حتى نهاية العام.",
        entry_type="alert",
        severity="info",
        expires_at=future_date,
        scopes=[GuideScopeCreate(scope_type="hs_code", scope_value="8520")],
    ))

    # Match shipment
    res = service.match_shipment(GuideMatchRequest(hs_code="8520"))
    matched_ids = [e.entry_id for e in res.matched_entries]

    # Expired note must NOT be surfaced
    assert active_entry.entry_id in matched_ids
    assert len(matched_ids) == 1
    assert res.has_critical_alert is False


def test_fuzzy_matching_supplier_and_product(db_session):
    service = ExperienceGuideService(db_session)

    # Tagged to "Suzhou Yuheng Textile"
    entry = service.create_entry(GuideEntryCreate(
        title="اشتراطات المورد سوزو يوهينغ",
        content="المورد يحتاج أسبوعين إضافيين لتجهيز شهادة CCPIT.",
        entry_type="alert",
        severity="warning",
        scopes=[GuideScopeCreate(scope_type="supplier", scope_value="Suzhou Yuheng Textile Ltd")],
    ))

    # Shipment created with minor name difference: "Suzhou Yuheng Textile"
    res = service.match_shipment(GuideMatchRequest(supplier="Suzhou Yuheng Textile"))
    matched_ids = [e.entry_id for e in res.matched_entries]
    assert entry.entry_id in matched_ids


def test_similar_shipments_and_pattern_detection(db_session):
    service = ExperienceGuideService(db_session)

    # Seed 3 historical ImportFiles for the same supplier with delay/variance
    file1 = ImportFile(
        import_file_code="IMP-2026-0001",
        company_name="شركة سرور للاستيراد",
        supplier_name="Suzhou Yuheng Textile",
        port_of_discharge="Alexandria Port",
        hs_code="5602.29.00",
        product_category="Acoustic Panels",
        selected_scenario="Wan Hai Lines",
        status="Closed",
        file_opening_date=date(2026, 1, 1),
        customs_released_at=datetime(2026, 1, 25, 10, 0, 0),
        estimated_cost=100000.0,
        actual_landed_cost_total_egp=115000.0,
        actual_landed_cost_variance_pct=15.0,
        notes="حدث تأخير في إصدار شهادة المنشأ من المورد.",
    )
    file2 = ImportFile(
        import_file_code="IMP-2026-0002",
        company_name="شركة سرور للاستيراد",
        supplier_name="Suzhou Yuheng Textile",
        port_of_discharge="Alexandria Port",
        hs_code="5602.29.00",
        product_category="Acoustic Panels",
        selected_scenario="Wan Hai Lines",
        status="Closed",
        file_opening_date=date(2026, 4, 1),
        customs_released_at=datetime(2026, 4, 28, 10, 0, 0),
        estimated_cost=120000.0,
        actual_landed_cost_total_egp=138000.0,
        actual_landed_cost_variance_pct=15.0,
        notes="تأخير آخر من المصنع وغرامة تخزين.",
    )
    # Current active file
    file3 = ImportFile(
        import_file_code="IMP-2026-0003",
        company_name="شركة سرور للاستيراد",
        supplier_name="Suzhou Yuheng Textile",
        port_of_discharge="Alexandria Port",
        hs_code="5602.29.00",
        product_category="Acoustic Panels",
        selected_scenario="Wan Hai Lines",
        status="Active",
        file_opening_date=date(2026, 9, 1),
        estimated_cost=130000.0,
    )
    db_session.add_all([file1, file2, file3])
    db_session.commit()
    db_session.refresh(file3)

    # 1. Test Similar Shipments for file3
    similar = service.get_similar_shipments(file3.import_file_id)
    assert len(similar) >= 2
    codes = [s.import_file_code for s in similar]
    assert "IMP-2026-0001" in codes
    assert "IMP-2026-0002" in codes
    assert similar[0].cost_variance_pct == 15.0

    # 2. Test Pattern Detection Engine
    patterns = service.get_detected_patterns()
    assert len(patterns) >= 1
    supp_pattern = next((p for p in patterns if p.dimension_type == "supplier"), None)
    assert supp_pattern is not None
    assert "Suzhou Yuheng" in supp_pattern.dimension_value
    assert supp_pattern.occurrence_count >= 2
    assert "IMP-2026-0001" in supp_pattern.evidence_shipments


def test_smart_reference_card_with_linked_pos_and_multi_hs(db_session):
    from modules.purchase_orders.model import PurchaseOrder, PackingListItem
    from modules.import_companies.model import ImportCompany
    from modules.suppliers.model import Supplier
    from modules.projects.model import Project
    from modules.incoterms.model import Incoterm
    from modules.currencies.model import Currency

    from modules.import_companies.schemas import ImportCompanyCreate
    from modules.import_companies.service import create_import_company

    # Seed required entities for foreign keys
    company = create_import_company(
        db_session,
        ImportCompanyCreate(
            importer_name="شركة سرور",
            address="Cairo",
            country="Egypt",
            importer_id="IMP-100200",
            importer_id_expiry=date.today() + timedelta(days=120),
            vat_id="VAT-998877",
            vat_id_expiry=date.today() + timedelta(days=90),
            registration_number="REG-554433",
            registration_expiry=date.today() + timedelta(days=60),
        ),
    )
    supplier = Supplier(
        supplier_id=1,
        supplier_code="SUP-001",
        company_name="Suzhou Yuheng",
        supplier_type="Manufacturer",
        registration_type="Direct",
        foreign_exporter_id="EXP-001",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Suzhou, China",
    )
    project = Project(
        project_id=1,
        project_code="PRJ-001",
        project_name="Project 1",
        project_owner="Ahmed",
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
    )
    incoterm = Incoterm(incoterm_id=1, incoterm_code="FOB", incoterm_name="Free on Board")
    currency = Currency(currency_id=1, currency_code="USD", currency_name="US Dollar", currency_symbol="$")
    db_session.add_all([company, supplier, project, incoterm, currency])
    db_session.commit()

    service = ExperienceGuideService(db_session)

    # 1. Create Guide Entry for Acoustic Panels
    entry_in = GuideEntryCreate(
        title="صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء",
        content="يجب أن يكون ميناء الوصول الإسكندرية حصراً. مطلوب شهادة منشأ أصلية.",
        entry_type="required_document",
        severity="critical",
        department="Clearance & Logistics",
        scopes=[
            GuideScopeCreate(scope_type="hs_code", scope_value="5602290000"),
            GuideScopeCreate(scope_type="product_category", scope_value="Acoustic Panels"),
        ],
    )
    service.create_entry(entry_in)

    # 2. Create Import File
    file = ImportFile(
        import_file_code="IMP-2026-0004",
        company_name="شركة سرور للاستيراد",
        supplier_name="Suzhou Yuheng",
        port_of_discharge="Alexandria Port",
        status="Active",
        file_opening_date=date(2026, 9, 20),
        estimated_cost=25000.0,
        estimated_cost_currency="USD",
    )
    db_session.add(file)
    db_session.commit()
    db_session.refresh(file)

    # 3. Create linked Purchase Order with packing list items
    po = PurchaseOrder(
        po_number="PO-2026-003",
        proforma_invoice_number="YH20260730-6",
        import_file_id=file.import_file_id,
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        total_cbm=66.3884,
        total_gross_weight_kg=10510.0,
        total_packages_count=144,
    )
    db_session.add(po)
    db_session.commit()
    db_session.refresh(po)

    pli1 = PackingListItem(
        po_id=po.po_id,
        hs_code="5602290000",
        item_code="YH-652",
        description="PET Acoustic Panels (YH-652)",
        qty_pcs=100,
        qty_pkg=20,
        total_cbm=9.2206,
        total_gross_weight_kg=1459.72,
        total_net_weight_kg=1400.0,
    )
    pli2 = PackingListItem(
        po_id=po.po_id,
        hs_code="5602290000",
        item_code="YH-610",
        description="PET Acoustic Panels (YH-610)",
        qty_pcs=120,
        qty_pkg=24,
        total_cbm=11.0648,
        total_gross_weight_kg=1751.67,
        total_net_weight_kg=1680.0,
    )
    db_session.add_all([pli1, pli2])
    db_session.commit()

    # 4. Generate Smart Reference Card
    card = service.generate_smart_reference_card(file.import_file_id)

    # Assertions
    prod = card.product_summary
    assert prod["packages_count"] == 44
    assert round(prod["total_cbm"], 2) == 20.29
    assert round(prod["total_gross_weight_kg"], 1) == 3211.4
    assert len(prod["hs_summaries"]) == 1
    assert prod["hs_summaries"][0]["hs_code"] == "5602290000"
    assert len(card.matched_guide_entries) == 1
    assert card.matched_guide_entries[0].title == "صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء"
    assert card.document_status["is_coo_required"] is True

