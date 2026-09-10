"""
Unit tests for Smart Shipment Experience Guide (KB-GUIDE-012)
Validates CRUD, Multi-Scope AND matching engine, Acoustic validation,
actionable guidance, and dynamic Smart Reference Card generation.
"""
from datetime import datetime, date, timezone
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

    # 1. Create entry with valid scopes
    entry_in = GuideEntryCreate(
        title="صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء",
        content="يجب أن يكون ميناء الوصول الإسكندرية حصراً. مطلوب شهادة منشأ أصلية.",
        entry_type="required_document",
        severity="critical",
        created_by="Ahmed Salah",
        scopes=[
            GuideScopeCreate(scope_type="hs_code", scope_value="8520"),
            GuideScopeCreate(scope_type="destination_port", scope_value="الإسكندرية"),
        ],
    )
    created = service.create_entry(entry_in)
    assert created.entry_id is not None
    assert created.title == "صنف الأكوستيك — اشتراطات فحص وإلزامية ميناء"
    assert created.severity == "critical"
    assert len(created.scopes) == 2

    # 2. Get entry by ID
    fetched = service.get_entry(created.entry_id)
    assert fetched.entry_id == created.entry_id
    assert fetched.title == created.title

    # 3. Update entry
    update_in = GuideEntryUpdate(
        severity="warning",
        content="تحديث: يلزم فحص المعامل بالإسكندرية قبل الإفراج الجمركي.",
    )
    updated = service.update_entry(created.entry_id, update_in)
    assert updated.severity == "warning"
    assert "تحديث" in updated.content

    # 4. List entries with search and filters
    entries = service.list_entries(search="الأكوستيك")
    assert len(entries) == 1
    assert entries[0].entry_id == created.entry_id

    entries_filtered = service.list_entries(scope_type="hs_code", scope_value="8520")
    assert len(entries_filtered) == 1

    # 5. Validation errors
    from pydantic import ValidationError

    # Pydantic validates empty title
    with pytest.raises(ValidationError):
        GuideEntryCreate(
            title="",
            content="محتوى",
            entry_type="info",
            severity="info",
        )

    # Domain validator checks entry_type
    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="invalid_type",
            severity="info",
        ))
    assert exc.value.status_code == 422

    # Domain validator checks severity
    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="alert",
            severity="ultra_fatal",
        ))
    assert exc.value.status_code == 422

    # Domain validator checks scope_type
    with pytest.raises(HTTPException) as exc:
        service.create_entry(GuideEntryCreate(
            title="عنوان صالح",
            content="محتوى",
            entry_type="alert",
            severity="warning",
            scopes=[GuideScopeCreate(scope_type="unsupported_scope", scope_value="val")],
        ))
    assert exc.value.status_code == 422

    # 6. Delete entry
    deleted = service.delete_entry(created.entry_id)
    assert deleted is True

    # 7. Non-existent entry
    with pytest.raises(HTTPException) as exc:
        service.get_entry(99999)
    assert exc.value.status_code == 404


def test_multi_scope_and_matching_engine(db_session):
    service = ExperienceGuideService(db_session)

    # Seed 3 distinct entries:
    # Entry 1: Only HS Code 8520
    entry1 = service.create_entry(GuideEntryCreate(
        title="قاعدة الأكوستيك العامة",
        content="صنف الأكوستيك يحتاج شهادة منشأ أصلية وميناء الإسكندرية.",
        entry_type="required_document",
        severity="critical",
        scopes=[GuideScopeCreate(scope_type="hs_code", scope_value="8520")],
    ))

    # Entry 2: HS Code 8520 AND Destination Port Alexandria AND Supplier Pioneer
    entry2 = service.create_entry(GuideEntryCreate(
        title="أكوستيك خاص بمورد بيونير في الإسكندرية",
        content="معاملة خاصة ومستندات تأكيد مطابقة للمورد.",
        entry_type="task",
        severity="warning",
        scopes=[
            GuideScopeCreate(scope_type="hs_code", scope_value="8520"),
            GuideScopeCreate(scope_type="destination_port", scope_value="Alexandria"),
            GuideScopeCreate(scope_type="supplier", scope_value="Pioneer Corp"),
        ],
    ))

    # Entry 3: Only Shipping Line Maersk
    entry3 = service.create_entry(GuideEntryCreate(
        title="توجيه خط ميرسك",
        content="خط ميرسك يمنح 14 يوم سماح للحاويات.",
        entry_type="info",
        severity="info",
        scopes=[GuideScopeCreate(scope_type="shipping_line", scope_value="Maersk")],
    ))

    # Case A: Query with HS 8520 only -> should match Entry 1 only (Entry 2 requires Port & Supplier)
    res_a = service.match_shipment(GuideMatchRequest(hs_code="8520.10.00"))
    matched_ids_a = [e.entry_id for e in res_a.matched_entries]
    assert entry1.entry_id in matched_ids_a
    assert entry2.entry_id not in matched_ids_a
    assert entry3.entry_id not in matched_ids_a
    assert res_a.has_critical_alert is True
    assert "ميناء الإسكندرية / الدخيلة" in res_a.mandatory_ports
    assert any("COO" in doc or "منشأ" in doc for doc in res_a.required_documents)

    # Case B: Query with HS 8520, Alexandria Port, Pioneer Corp -> should match BOTH Entry 1 and Entry 2
    res_b = service.match_shipment(GuideMatchRequest(
        hs_code="8520",
        destination_port="El Dekheila (Alexandria)",
        supplier="Pioneer Corp International",
    ))
    matched_ids_b = [e.entry_id for e in res_b.matched_entries]
    assert entry1.entry_id in matched_ids_b
    assert entry2.entry_id in matched_ids_b
    assert entry3.entry_id not in matched_ids_b
    assert res_b.has_critical_alert is True
    assert res_b.has_warning_alert is True

    # Case C: Query with HS 8520 and Port Sokhna and Pioneer Corp
    # Entry 1 matches (only HS), Entry 2 fails (port does not match Alexandria)
    res_c = service.match_shipment(GuideMatchRequest(
        hs_code="8520",
        destination_port="Ain Sokhna Port",
        supplier="Pioneer Corp International",
    ))
    matched_ids_c = [e.entry_id for e in res_c.matched_entries]
    assert entry1.entry_id in matched_ids_c
    assert entry2.entry_id not in matched_ids_c

    # Case D: Query with Line Maersk
    res_d = service.match_shipment(GuideMatchRequest(shipping_line="Maersk Line"))
    matched_ids_d = [e.entry_id for e in res_d.matched_entries]
    assert entry3.entry_id in matched_ids_d
    assert entry1.entry_id not in matched_ids_d


def test_smart_reference_card_dynamic_generation(db_session):
    service = ExperienceGuideService(db_session)

    # 1. Create a guide entry for HS 8520
    service.create_entry(GuideEntryCreate(
        title="قاعدة فحص الأكوستيك",
        content="يلزم توفير شهادة منشأ أصلية وفحص بميناء الإسكندرية.",
        entry_type="required_document",
        severity="critical",
        scopes=[GuideScopeCreate(scope_type="hs_code", scope_value="8520")],
    ))

    # 2. Seed an ImportFile
    file = ImportFile(
        import_file_code="IMP-2026-9901",
        custom_file_number="6701068100",
        company_name="شركة سرور للاستيراد",
        supplier_name="Pioneer Sound Ltd",
        port_of_loading="Shanghai Port",
        port_of_discharge="Alexandria Port",
        selected_scenario="Maersk",
        hs_code="8520.20.00",
        product_category="أنظمة صوتية وأكوستيك",
        shipment_mode="Sea FCL",
        incoterm_code="FOB",
        target_free_days=14,
        file_opening_date=date(2026, 9, 1),
        cargo_ready_date=date(2026, 9, 10),
        required_eta=date(2026, 9, 25),
        estimated_cost=250000.0,
        estimated_cost_currency="EGP",
        packing_lists_data=[
            {
                "pl_no": "PL-8520-1",
                "total_packages": 1,
                "gross_weight_kg": 1250.0,
                "cbm": 4.5,
            }
        ],
        invoices_data=[
            {
                "invoice_no": "INV-8520-1",
                "amount": 240000.0,
                "currency": "EGP",
            }
        ],
        notes="تم مراجعة الفاتورة، شهادة المنشأ الأصلية مرفقة ومصدقة من الغرفة التجارية.",
        status="active",
        current_stage="Customs",
    )
    db_session.add(file)
    db_session.commit()
    db_session.refresh(file)

    # 3. Generate Smart Reference Card
    card = service.generate_smart_reference_card(file.import_file_id)

    # Assertions
    assert card.import_file_id == file.import_file_id
    assert card.import_file_code == "IMP-2026-9901"
    assert card.custom_file_number == "6701068100"
    assert card.product_summary["hs_code"] == "8520.20.00"
    assert card.product_summary["product_category"] == "أنظمة صوتية وأكوستيك"
    assert card.product_summary["total_cbm"] == 4.5
    assert card.product_summary["total_gross_weight_kg"] == 1250.0
    assert card.product_summary["packages_count"] == 1

    # Route
    assert card.route_summary["origin_port"] == "Shanghai Port"
    assert card.route_summary["destination_port"] == "Alexandria Port"
    assert card.route_summary["shipping_line"] == "Maersk"

    # Critical Dates & Demurrage
    assert card.critical_dates["target_free_days"] == 14

    # Document Status
    assert card.document_status["has_coo_attached"] is True

    # Matched Experience Guide
    assert len(card.matched_guide_entries) >= 1
    assert card.matched_guide_entries[0].severity == "critical"

    # Cost Comparison
    assert card.cost_summary["estimated_cost"] == 250000.0
    assert card.cost_summary["actual_invoiced_cost"] == 240000.0
    assert card.cost_summary["variance_amount"] == -10000.0
