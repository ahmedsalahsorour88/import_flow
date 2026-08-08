from datetime import datetime
from typing import List, Optional
from sqlalchemy import or_
from sqlalchemy.orm import Session

from modules.cbm_calculator.model import CBMCalculation, CBMCalculationItem


class CBMRepository:

    @staticmethod
    def generate_calc_code(db: Session) -> str:
        year = datetime.now().year
        prefix = f"CALC-{year}-"
        last_record = (
            db.query(CBMCalculation)
            .filter(CBMCalculation.calc_code.like(f"{prefix}%"))
            .order_by(CBMCalculation.calc_id.desc())
            .first()
        )
        if last_record and last_record.calc_code:
            try:
                seq = int(last_record.calc_code.split("-")[-1]) + 1
            except ValueError:
                seq = 1
        else:
            seq = 1
        return f"{prefix}{seq:03d}"

    @staticmethod
    def create(db: Session, calc_data: dict, items_data: list[dict]) -> CBMCalculation:
        calc_code = CBMRepository.generate_calc_code(db)
        calc = CBMCalculation(
            calc_code=calc_code,
            title=calc_data.get("title"),
            project_id=calc_data.get("project_id"),
            po_id=calc_data.get("po_id"),
            total_qty=calc_data.get("total_qty", 0),
            total_cbm=calc_data.get("total_cbm", 0.0),
            total_gross_weight_kg=calc_data.get("total_gross_weight_kg", 0.0),
            total_volumetric_weight_kg=calc_data.get("total_volumetric_weight_kg", 0.0),
            air_chargeable_weight_kg=calc_data.get("air_chargeable_weight_kg", 0.0),
            recommended_shipping_method=calc_data.get("recommended_shipping_method"),
            recommended_container_type=calc_data.get("recommended_container_type"),
            recommended_container_count=calc_data.get("recommended_container_count", 0),
            notes=calc_data.get("notes"),
            is_active=True,
        )
        db.add(calc)
        db.flush()

        for item_dict in items_data:
            item = CBMCalculationItem(
                calc_id=calc.calc_id,
                package_type=item_dict.get("package_type", "Carton"),
                quantity=item_dict.get("quantity", 1),
                length_cm=item_dict.get("length_cm", 0.0),
                width_cm=item_dict.get("width_cm", 0.0),
                height_cm=item_dict.get("height_cm", 0.0),
                gross_weight_per_unit_kg=item_dict.get("gross_weight_per_unit_kg", 0.0),
                total_cbm=item_dict.get("total_cbm", 0.0),
                volumetric_weight_kg=item_dict.get("volumetric_weight_kg", 0.0),
                total_gross_weight_kg=item_dict.get("total_gross_weight_kg", 0.0),
            )
            db.add(item)

        db.commit()
        db.refresh(calc)
        return calc

    @staticmethod
    def get_by_id(db: Session, calc_id: int) -> Optional[CBMCalculation]:
        return (
            db.query(CBMCalculation)
            .filter(CBMCalculation.calc_id == calc_id)
            .first()
        )

    @staticmethod
    def get_all(
        db: Session,
        include_inactive: bool = False,
        project_id: Optional[int] = None,
        po_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[CBMCalculation]:
        query = db.query(CBMCalculation)

        if not include_inactive:
            query = query.filter(CBMCalculation.is_active.is_(True))

        if project_id is not None:
            query = query.filter(CBMCalculation.project_id == project_id)

        if po_id is not None:
            query = query.filter(CBMCalculation.po_id == po_id)

        if search and search.strip():
            term = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    CBMCalculation.calc_code.ilike(term),
                    CBMCalculation.title.ilike(term),
                    CBMCalculation.notes.ilike(term),
                    CBMCalculation.recommended_shipping_method.ilike(term),
                )
            )

        return query.order_by(CBMCalculation.calc_id.desc()).all()

    @staticmethod
    def update(db: Session, calc: CBMCalculation, calc_data: dict, items_data: Optional[list[dict]] = None) -> CBMCalculation:
        for key, value in calc_data.items():
            if hasattr(calc, key) and value is not None:
                setattr(calc, key, value)

        if items_data is not None:
            # Delete old items and insert updated items
            db.query(CBMCalculationItem).filter(CBMCalculationItem.calc_id == calc.calc_id).delete()
            for item_dict in items_data:
                item = CBMCalculationItem(
                    calc_id=calc.calc_id,
                    package_type=item_dict.get("package_type", "Carton"),
                    quantity=item_dict.get("quantity", 1),
                    length_cm=item_dict.get("length_cm", 0.0),
                    width_cm=item_dict.get("width_cm", 0.0),
                    height_cm=item_dict.get("height_cm", 0.0),
                    gross_weight_per_unit_kg=item_dict.get("gross_weight_per_unit_kg", 0.0),
                    total_cbm=item_dict.get("total_cbm", 0.0),
                    volumetric_weight_kg=item_dict.get("volumetric_weight_kg", 0.0),
                    total_gross_weight_kg=item_dict.get("total_gross_weight_kg", 0.0),
                )
                db.add(item)

        db.commit()
        db.refresh(calc)
        return calc

    @staticmethod
    def soft_delete(db: Session, calc: CBMCalculation) -> CBMCalculation:
        calc.is_active = False
        db.commit()
        db.refresh(calc)
        return calc

    @staticmethod
    def restore(db: Session, calc: CBMCalculation) -> CBMCalculation:
        calc.is_active = True
        db.commit()
        db.refresh(calc)
        return calc
