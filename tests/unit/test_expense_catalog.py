"""
Unit tests for Coded Reference Expense Catalog (AI-EXPENSE-CATALOG-002)
Tests CRUD operations, validation rules, pattern matching engine,
seed data integrity, and golden ACC quotation enrichment.
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

import main
from database.database import Base
from modules.expense_catalog.model import ExpenseCatalog
from modules.expense_catalog.schemas import ExpenseCatalogCreate, ExpenseCatalogUpdate
from modules.expense_catalog.service import ExpenseCatalogService, normalize_text
from modules.expense_catalog.seed_data import EXPENSE_CATALOG_SEED_DATA
from modules.smart_document_upload.extractors.customs_broker_quotation import CustomsBrokerQuotationExtractor
from tests.unit.test_customs_broker_quotation_extractor import test_golden_acc_quotation_completeness_and_validation
import inspect


@pytest.fixture(scope="function")
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


def test_expense_catalog_crud_and_validation(db_session):
    # 1. Successful creation
    schema = ExpenseCatalogCreate(
        code="TEST-FEE-01",
        canonical_name_ar="رسوم اختبار جمركية",
        canonical_name_en="Customs Test Fee",
        category="Clearance Fees",
        unit_type="fixed",
        allow_composite=False,
        recognition_patterns=["رسوم اختبار", "اختبار جمركي"],
    )
    created = ExpenseCatalogService.create_item(db_session, schema)
    assert created.code == "TEST-FEE-01"
    assert created.canonical_name_ar == "رسوم اختبار جمركية"
    assert created.category == "Clearance Fees"
    assert created.is_active is True

    # 2. Get item
    fetched = ExpenseCatalogService.get_item(db_session, "TEST-FEE-01")
    assert fetched.code == "TEST-FEE-01"

    # 3. 404 for non-existent item
    with pytest.raises(HTTPException) as exc_info:
        ExpenseCatalogService.get_item(db_session, "NON-EXISTENT")
    assert exc_info.value.status_code == 404

    # 4. Invalid code format (no hyphen / lowercase)
    with pytest.raises(HTTPException) as exc_info:
        bad_code_schema = ExpenseCatalogCreate(
            code="invalidcode",
            canonical_name_ar="بند غير صالح",
            category="Clearance Fees",
            unit_type="fixed",
        )
        ExpenseCatalogService.create_item(db_session, bad_code_schema)
    assert exc_info.value.status_code in (400, 422)

    # 5. Invalid category
    with pytest.raises(HTTPException) as exc_info:
        bad_cat_schema = ExpenseCatalogCreate(
            code="TEST-FEE-02",
            canonical_name_ar="بند غير صالح",
            category="Invalid Category",
            unit_type="fixed",
        )
        ExpenseCatalogService.create_item(db_session, bad_cat_schema)
    assert exc_info.value.status_code in (400, 422)

    # 6. Invalid unit type
    with pytest.raises(HTTPException) as exc_info:
        bad_unit_schema = ExpenseCatalogCreate(
            code="TEST-FEE-03",
            canonical_name_ar="بند غير صالح",
            category="Clearance Fees",
            unit_type="invalid_unit",
        )
        ExpenseCatalogService.create_item(db_session, bad_unit_schema)
    assert exc_info.value.status_code in (400, 422)

    # 7. Duplicate code rejection
    with pytest.raises(HTTPException) as exc_info:
        dup_schema = ExpenseCatalogCreate(
            code="TEST-FEE-01",
            canonical_name_ar="تكرار رسوم",
            category="Clearance Fees",
            unit_type="fixed",
        )
        ExpenseCatalogService.create_item(db_session, dup_schema)
    assert exc_info.value.status_code in (400, 409)

    # 8. Update item
    update_schema = ExpenseCatalogUpdate(
        canonical_name_en="Updated Test Fee",
        unit_type="per_invoice",
    )
    updated = ExpenseCatalogService.update_item(db_session, "TEST-FEE-01", update_schema)
    assert updated.canonical_name_en == "Updated Test Fee"
    assert updated.unit_type == "per_invoice"

    # 9. Deactivate (soft delete)
    deactivated = ExpenseCatalogService.deactivate_item(db_session, "TEST-FEE-01")
    assert deactivated.is_active is False


def test_expense_catalog_add_pattern(db_session):
    schema = ExpenseCatalogCreate(
        code="CLR-TEST-PAT",
        canonical_name_ar="أتعاب اختبارية",
        category="Clearance Fees",
        unit_type="fixed",
        recognition_patterns=["أتعاب اختبارية"],
    )
    ExpenseCatalogService.create_item(db_session, schema)

    # Add a new recognition pattern
    updated = ExpenseCatalogService.add_pattern(db_session, "CLR-TEST-PAT", "رسوم تجريبية جديدة")
    assert "رسوم تجريبية جديدة" in updated.recognition_patterns

    # Adding duplicate pattern should not create duplicate entries
    updated2 = ExpenseCatalogService.add_pattern(db_session, "CLR-TEST-PAT", "رسوم تجريبية جديدة")
    assert updated2.recognition_patterns.count("رسوم تجريبية جديدة") == 1


def test_expense_catalog_text_normalization():
    assert normalize_text("أتعاب التخليص الجمركي!") == "اتعاب التخليص الجمركي"
    assert normalize_text("إفراج  نهائي (كيمياء)") == "افراج نهائي كيمياء"
    assert normalize_text("بياتة الحاوية 1×20") == "بياته الحاويه 1 20"
    assert normalize_text("LCL Clearance Fee (Per Ton)") == "lcl clearance fee per ton"


def test_expense_catalog_matching_engine(db_session):
    # Seed 20ft, 40ft, and LCL items
    items = [
        ExpenseCatalogCreate(
            code="CLR-FCL20-CONT",
            canonical_name_ar="تخليص حاوية 20 قدم (1 حاوية)",
            category="Clearance Fees",
            unit_type="per_container",
            recognition_patterns=["مصاريف تخليص ١ حاوية 20", "مصاريف تخليص أول حاوية 20 قدم"],
        ),
        ExpenseCatalogCreate(
            code="CLR-FCL40-CONT",
            canonical_name_ar="تخليص حاوية 40 قدم (1 حاوية)",
            category="Clearance Fees",
            unit_type="per_container",
            recognition_patterns=["مصاريف تخليص ١ حاوية 40", "مصاريف تخليص أول حاوية 40 قدم"],
        ),
        ExpenseCatalogCreate(
            code="CLR-LCL-INV",
            canonical_name_ar="اتعاب تخليص LCL (فاتورة)",
            category="Clearance Fees",
            unit_type="per_invoice",
            recognition_patterns=["اتعاب تخليص LCL (فاتورة)", "LCL Clearance Fee"],
        ),
    ]
    for it in items:
        ExpenseCatalogService.create_item(db_session, it)

    # 1. Exact match
    matched = ExpenseCatalogService.find_matching_item(db_session, "مصاريف تخليص أول حاوية 20 قدم")
    assert matched is not None
    assert matched.code == "CLR-FCL20-CONT"

    # 2. Strict isolation: 20ft input must NOT match 40ft
    matched_20 = ExpenseCatalogService.find_matching_item(db_session, "تخليص حاوية 20 قدم")
    assert matched_20 is not None
    assert matched_20.code == "CLR-FCL20-CONT"

    # 3. Strict isolation: 40ft input must NOT match 20ft
    matched_40 = ExpenseCatalogService.find_matching_item(db_session, "تخليص حاوية 40 قدم")
    assert matched_40 is not None
    assert matched_40.code == "CLR-FCL40-CONT"

    # 4. Strict isolation: LCL input must NOT match FCL
    matched_lcl = ExpenseCatalogService.find_matching_item(db_session, "اتعاب تخليص LCL")
    assert matched_lcl is not None
    assert matched_lcl.code == "CLR-LCL-INV"


def test_expense_catalog_seed_data_integrity():
    assert len(EXPENSE_CATALOG_SEED_DATA) == 53
    codes = set()
    for item in EXPENSE_CATALOG_SEED_DATA:
        code = item["code"]
        assert code not in codes, f"Duplicate seed code detected: {code}"
        codes.add(code)
        assert item["canonical_name_ar"]
        assert item["category"] in (
            "Clearance Fees",
            "Procedures & Approvals",
            "Inland Transport",
            "Port & Handling",
            "Other Fees",
        )
        assert item["unit_type"] in (
            "fixed",
            "per_container",
            "per_invoice",
            "per_ton",
            "per_vehicle",
            "per_night",
            "per_shipment",
            "range",
        )


def test_golden_acc_quotation_100_percent_coded():
    source = inspect.getsource(test_golden_acc_quotation_completeness_and_validation)
    start = source.find('full_acc_text = """') + len('full_acc_text = """')
    end = source.find('"""', start)
    text = source[start:end]

    extractor = CustomsBrokerQuotationExtractor()
    result = extractor.extract(text, {})

    catalog = result.get("expenses_catalog", [])
    assert len(catalog) >= 50, f"Expected 50+ items, got {len(catalog)}"

    uncoded_items = [it for it in catalog if it.get("is_uncoded")]
    coded_items = [it for it in catalog if not it.get("is_uncoded")]

    assert len(coded_items) >= 50
    assert len(uncoded_items) == 0, f"Expected 0 uncoded items, got {len(uncoded_items)}: {[u['item_name'] for u in uncoded_items]}"

    # Check validation report mathematical consistency
    val_report = result.get("validation_report", {})
    assert val_report.get("gap_count") == 0
    assert val_report.get("gap_percentage") == 0.0
    assert val_report.get("uncoded_items_count") == 0
