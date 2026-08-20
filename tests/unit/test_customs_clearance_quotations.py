"""
Unit Tests for Customs Clearance Quotations & Price Lists Engine and Extractor
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import main  # noqa: F401 - registers all SQLAlchemy models
from database.database import Base
from modules.customs_clearance_quotations.schemas import (
    CustomsClearanceRFQCreate,
    CustomsClearanceRFQUpdate,
    CustomsClearanceQuotationCreate,
    ClearancePriceListItemCreate,
)
from modules.customs_clearance_quotations.service import (
    create_rfq_service,
    get_rfqs_service,
    get_rfq_by_id_service,
    add_quotation_service,
    award_quotation_service,
    create_price_item_service,
    get_price_list_service,
)
from modules.smart_document_upload.extractors.customs_broker_quotation import CustomsBrokerQuotationExtractor


@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_customs_broker_quotation_extractor_text_parsing():
    extractor = CustomsBrokerQuotationExtractor()
    sample_text = """
    السادة شركة النور للاستيراد والتصدير
    عرض أسعار وتخليص جمركي مقدم من: مكتب الأهرام للخدمات اللوجستية والتخليص الجمركي
    ميناء الوصول: ميناء الإسكندرية (Alexandria Port)
    نوع الحاوية: 40HQ
    
    1. أتعاب التخليص الجمركي: 3,500 EGP
    2. النقل الداخلي لمصنع العميل: 8,000 EGP
    3. مصاريف فحص وعرض هيئة الرقابة: 2,200 EGP
    4. رسوم موانئ وخدمات ساحات: 4,300 EGP
    5. نثريات ومصروفات إدارية: 500 EGP
    
    الإجمالي التقديري للمقايسة: 18,500 EGP
    مدة التخليص المتوقعة: 4 أيام عمل
    صلاحية العرض: 2026-12-31
    شروط السداد: 50% سلفة نثريات و 50% عند استلام الفاتورة النهائية
    """

    res = extractor.extract(sample_text, {})
    assert "الأهرام" in res["broker_name"] or "تخليص" in res["broker_name"]
    assert "Alexandria" in res["port_name"] or "الإسكندرية" in res["port_name"]
    assert res["container_type"] == "40HQ"
    assert res["clearance_fee"] == 3500.0
    assert res["inland_transport_fee"] == 8000.0
    assert res["inspection_fee"] == 2200.0
    assert res["port_expenses"] == 4300.0
    assert res["miscellaneous_fee"] == 500.0
    assert res["total_estimated_clearance_cost"] == 18500.0
    assert res["transit_clearance_days"] == 4
    assert res["currency"] == "EGP"


def test_create_clearance_rfq_and_add_quotation(db_session):
    rfq_data = CustomsClearanceRFQCreate(
        title="طلب عروض أسعار تخليص ونقل شحنة خط إنتاج",
        port_name="Alexandria Port",
        commodity_description="Industrial Production Line Spare Parts",
        hs_code="8479.89.90",
        shipment_type="Ocean FCL (40HQ)",
        containers_count=2,
        packages_count=10,
        gross_weight_kg=15000.0,
        cbm=45.0,
    )
    rfq = create_rfq_service(db_session, rfq_data)
    assert rfq.rfq_id is not None
    assert rfq.rfq_code.startswith("CRFQ-")
    assert rfq.status == "Draft"

    # Add competing broker quote 1
    q1 = add_quotation_service(
        db_session,
        rfq.rfq_id,
        CustomsClearanceQuotationCreate(
            provider_id=1,
            provider_name="مكتب الأهرام للتخليص الجمركي",
            license_number="LIC-2024-001",
            clearance_fee=3500.0,
            inland_transport_fee=7000.0,
            inspection_fee=1500.0,
            port_expenses=2000.0,
            miscellaneous_fee=500.0,
            estimated_turnaround_days=3,
        ),
    )
    assert q1.total_cost == 14500.0

    # Add competing broker quote 2 (cheaper)
    q2 = add_quotation_service(
        db_session,
        rfq.rfq_id,
        CustomsClearanceQuotationCreate(
            provider_id=2,
            provider_name="النسر للخدمات اللوجستية",
            license_number="LIC-2024-002",
            clearance_fee=3000.0,
            inland_transport_fee=6500.0,
            inspection_fee=1200.0,
            port_expenses=1800.0,
            miscellaneous_fee=500.0,
            estimated_turnaround_days=4,
        ),
    )
    assert q2.total_cost == 13000.0

    # Check RFQ metrics
    rfqs = get_rfqs_service(db_session)
    assert len(rfqs) == 1
    loaded_rfq = rfqs[0]
    assert loaded_rfq.lowest_clearance_cost == 13000.0
    assert loaded_rfq.fastest_turnaround_days == 3
    assert len(loaded_rfq.quotations) == 2

    # Award the best quote
    awarded_rfq = award_quotation_service(db_session, loaded_rfq.rfq_id, q2.quotation_id, notes="تم اختيار العرض الأقل تكلفة")
    assert awarded_rfq.status == "Awarded"
    assert awarded_rfq.awarded_provider_id == 2
    assert awarded_rfq.awarded_provider_name == "النسر للخدمات اللوجستية"
    assert awarded_rfq.awarded_quotation_id == q2.quotation_id


def test_clearance_price_list_master(db_session):
    price_item = create_price_item_service(
        db_session,
        ClearancePriceListItemCreate(
            provider_id=1,
            provider_name="مكتب الأهرام للتخليص الجمركي",
            port_name="Alexandria Port",
            service_category="Agency Fee",
            container_type="40HQ",
            unit_price=3500.0,
            currency="EGP",
        ),
    )
    assert price_item.price_item_id is not None
    assert price_item.unit_price == 3500.0

    items = get_price_list_service(db_session, port_name="Alexandria")
    assert len(items) == 1
    assert items[0].provider_name == "مكتب الأهرام للتخليص الجمركي"
