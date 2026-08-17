import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

import main  # Ensures all SQLAlchemy models are registered in Base.metadata
from database.database import SessionLocal, Base, engine
from modules.cbm_calculator.schemas import (
    CBMCalculationCreate,
    CBMCalculationUpdate,
    CBMItemCreate,
    CBMQuickCalcRequest,
    LinkToPORequest,
)
from modules.cbm_calculator.service import CBMService
from modules.projects.model import Project
from modules.purchase_orders.model import PurchaseOrder
from seed import seed_data


import modules.customs_consultation.model
import modules.import_requirements.model

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="module")
def db():
    test_engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=test_engine)
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=test_engine)


class TestCBMCalculatorBackend:

    def test_quick_calculate_cbm_and_air_chargeable_weight(self):
        # 10 Cartons: 100 x 50 x 40 cm, 15 kg each
        item1 = CBMItemCreate(
            package_type="Carton",
            quantity=10,
            length_cm=100.0,
            width_cm=50.0,
            height_cm=40.0,
            gross_weight_per_unit_kg=15.0,
        )
        req = CBMQuickCalcRequest(items=[item1])
        res = CBMService.quick_calculate(req)

        assert res.total_qty == 10
        assert res.total_cbm == 2.0  # 10 * 100 * 50 * 40 / 1,000,000
        assert res.total_gross_weight_kg == 150.0  # 10 * 15
        assert res.total_volumetric_weight_kg == 333.33  # 10 * 100 * 50 * 40 / 6000
        assert res.air_chargeable_weight_kg == 333.33  # max(150, 333.33)
        assert "LCL Ocean Freight" in res.recommended_shipping_method

    def test_container_recommendation_logic(self):
        # 1. Small volume -> 20FT Container (e.g. 20 CBM)
        item_20ft = CBMItemCreate(
            package_type="Pallet",
            quantity=10,
            length_cm=120.0,
            width_cm=100.0,
            height_cm=160.0,
            gross_weight_per_unit_kg=100.0,
        )
        res_20ft = CBMService.quick_calculate(CBMQuickCalcRequest(items=[item_20ft]))
        assert res_20ft.total_cbm == 19.2
        assert "20FT Standard Container" in res_20ft.recommended_container_type
        assert res_20ft.recommended_container_count == 1

        # 2. Large volume -> 40FT High Cube Container (e.g. 70 CBM)
        item_40ft_hc = CBMItemCreate(
            package_type="Pallet",
            quantity=35,
            length_cm=120.0,
            width_cm=100.0,
            height_cm=160.0,
            gross_weight_per_unit_kg=100.0,
        )
        res_hc = CBMService.quick_calculate(CBMQuickCalcRequest(items=[item_40ft_hc]))
        assert res_hc.total_cbm == 67.2
        assert "40FT High Cube" in res_hc.recommended_container_type
        assert res_hc.recommended_container_count == 1

        # 3. Extra Large volume -> Multiple 40FT HC Containers (e.g. 150 CBM)
        item_multi = CBMItemCreate(
            package_type="Wooden Crate",
            quantity=80,
            length_cm=120.0,
            width_cm=100.0,
            height_cm=160.0,
            gross_weight_per_unit_kg=100.0,
        )
        res_multi = CBMService.quick_calculate(CBMQuickCalcRequest(items=[item_multi]))
        assert res_multi.total_cbm == 153.6
        assert res_multi.recommended_container_count == 3  # ceil(153.6 / 76) = 3

    def test_create_and_link_cbm_calculation(self, db: Session):
        # Create standalone calculation session
        item = CBMItemCreate(
            package_type="Carton",
            quantity=5,
            length_cm=80.0,
            width_cm=60.0,
            height_cm=50.0,
            gross_weight_per_unit_kg=10.0,
        )
        create_payload = CBMCalculationCreate(
            title="حساب شحنة التجربة الأولية",
            notes="حساب قبل طلب عروض الأسعار",
            items=[item],
        )
        calc = CBMService.create_calculation_service(db, create_payload)
        assert calc.calc_id is not None
        assert calc.calc_code.startswith("CALC-")
        assert calc.po_id is None

        # Link calculation session to an existing PO
        po = db.query(PurchaseOrder).first()
        if not po:
            po = PurchaseOrder(
                po_number="PO-TEST-001",
                project_id=1,
                company_id=1,
                supplier_id=1,
                incoterm_id=1,
                currency_id=1,
                exchange_rate=50.0,
                total_amount_fob=1000.0,
                status="Draft",
            )
            db.add(po)
            db.commit()
            db.refresh(po)
        assert po is not None

        linked_calc = CBMService.link_to_po_service(db, calc.calc_id, po_id=po.po_id)
        assert linked_calc.po_id == po.po_id
        assert linked_calc.po_number == po.po_number

    def test_invalid_dimensions_raises_error(self):
        from pydantic import ValidationError

        with pytest.raises(ValidationError) as exc_info:
            CBMItemCreate(
                package_type="Carton",
                quantity=1,
                length_cm=0.0,  # Invalid
                width_cm=50.0,
                height_cm=40.0,
                gross_weight_per_unit_kg=10.0,
            )
        assert "length" in str(exc_info.value) or "length_cm" in str(exc_info.value)

    def test_soft_delete_and_restore_cbm_calculation(self, db: Session):
        item = CBMItemCreate(
            package_type="Drum",
            quantity=2,
            length_cm=60.0,
            width_cm=60.0,
            height_cm=90.0,
            gross_weight_per_unit_kg=50.0,
        )
        calc = CBMService.create_calculation_service(
            db, CBMCalculationCreate(title="Test Soft Delete", items=[item])
        )

        # Soft Delete
        res = CBMService.soft_delete_service(db, calc.calc_id)
        assert "soft deleted" in res["message"]

        # Verify inactive
        inactive_calc = CBMService.get_calculation_service(db, calc.calc_id)
        assert inactive_calc.is_active is False

        # Restore
        restored = CBMService.restore_service(db, calc.calc_id)
        assert restored.is_active is True

    def test_is_stackable_persistence_and_update(self, db: Session):
        # 1. Create with mixed stackability
        item_stackable = CBMItemCreate(
            package_type="Carton",
            quantity=10,
            length_cm=50.0,
            width_cm=40.0,
            height_cm=30.0,
            gross_weight_per_unit_kg=5.0,
            is_stackable=True,
        )
        item_non_stackable = CBMItemCreate(
            package_type="Pallet",
            quantity=2,
            length_cm=200.0,
            width_cm=150.0,
            height_cm=100.0,
            gross_weight_per_unit_kg=200.0,
            is_stackable=False,
        )

        calc = CBMService.create_calculation_service(
            db,
            CBMCalculationCreate(
                title="Stacking Verification Test",
                is_stackable=False,
                items=[item_stackable, item_non_stackable],
            ),
        )

        assert calc.is_stackable is False
        assert len(calc.items) == 2
        assert calc.items[0].is_stackable is True
        assert calc.items[1].is_stackable is False

        # 2. Retrieve from DB and verify stackability is preserved
        fetched = CBMService.get_calculation_service(db, calc.calc_id)
        assert fetched.is_stackable is False
        assert fetched.items[0].is_stackable is True
        assert fetched.items[1].is_stackable is False

        # 3. Update calculation and change stackability
        updated_item = CBMItemCreate(
            package_type="Pallet",
            quantity=4,
            length_cm=200.0,
            width_cm=150.0,
            height_cm=100.0,
            gross_weight_per_unit_kg=250.0,
            is_stackable=False,
        )
        updated = CBMService.update_calculation_service(
            db,
            calc.calc_id,
            CBMCalculationUpdate(
                title="Updated Stacking Session",
                is_stackable=False,
                items=[updated_item],
            ),
        )
        assert updated.title == "Updated Stacking Session"
        assert len(updated.items) == 1
        assert updated.items[0].is_stackable is False
