import math
from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.cbm_calculator.model import CBMCalculation
from modules.cbm_calculator.repository import CBMRepository
from modules.cbm_calculator.schemas import (
    CBMCalculationCreate,
    CBMCalculationResponse,
    CBMCalculationUpdate,
    CBMItemCreate,
    CBMQuickCalcRequest,
    CBMQuickCalcResponse,
)
from modules.cbm_calculator.validators import CBMValidator
from modules.projects.model import Project
from modules.purchase_orders.model import PurchaseOrder


class CBMService:

    @staticmethod
    def convert_to_meter(length: float, width: float, height: float, unit: str) -> Tuple[float, float, float]:
        u = (unit or "cm").lower().strip()
        if u == "mm":
            return length / 1000.0, width / 1000.0, height / 1000.0
        elif u == "cm":
            return length / 100.0, width / 100.0, height / 100.0
        elif u == "m":
            return length, width, height
        return length / 100.0, width / 100.0, height / 100.0

    @staticmethod
    def calculate_cbm(length_m: float, width_m: float, height_m: float, qty: int) -> float:
        return qty * length_m * width_m * height_m

    @staticmethod
    def calculate_volumetric_weight(length_m: float, width_m: float, height_m: float, qty: int) -> float:
        length_cm = length_m * 100.0
        width_cm = width_m * 100.0
        height_cm = height_m * 100.0
        return (qty * length_cm * width_cm * height_cm) / 6000.0

    @staticmethod
    def compute_items_and_totals(items: List[CBMItemCreate]) -> Tuple[List[dict], dict]:
        """
        Calculates line item measurements, volumetric weight, total CBM,
        air chargeable weight, and container recommendations.
        """
        CBMValidator.validate_items(items)

        computed_items = []
        total_qty = 0
        sum_cbm = 0.0
        sum_gross_wt = 0.0
        sum_volumetric_wt = 0.0

        for item in items:
            line_qty = item.quantity
            unit = getattr(item, "unit", "cm") or "cm"
            l_m, w_m, h_m = CBMService.convert_to_meter(item.length, item.width, item.height, unit)

            line_cbm = CBMService.calculate_cbm(l_m, w_m, h_m, line_qty)
            line_volumetric_wt = CBMService.calculate_volumetric_weight(l_m, w_m, h_m, line_qty)
            line_gross_wt = line_qty * item.gross_weight_per_unit_kg

            sum_cbm += line_cbm
            sum_gross_wt += line_gross_wt
            sum_volumetric_wt += line_volumetric_wt
            total_qty += line_qty

            computed_items.append({
                "package_type": item.package_type,
                "quantity": line_qty,
                "length": item.length,
                "width": item.width,
                "height": item.height,
                "unit": unit,
                "length_cm": round(l_m * 100.0, 2),
                "width_cm": round(w_m * 100.0, 2),
                "height_cm": round(h_m * 100.0, 2),
                "gross_weight_per_unit_kg": item.gross_weight_per_unit_kg,
                "total_cbm": round(line_cbm, 4),
                "volumetric_weight_kg": round(line_volumetric_wt, 2),
                "total_gross_weight_kg": round(line_gross_wt, 2),
                "is_stackable": getattr(item, "is_stackable", True),
            })

        total_cbm = round(sum_cbm, 4)
        total_gross_weight_kg = round(sum_gross_wt, 2)
        total_volumetric_weight_kg = round(sum_volumetric_wt, 2)

        # Air Chargeable Weight = max(Gross Weight, Volumetric Weight)
        air_chargeable_weight_kg = round(max(total_gross_weight_kg, total_volumetric_weight_kg), 2)

        # Recommendation Logic
        if total_cbm <= 1.5 and total_gross_weight_kg <= 300.0:
            rec_method = "Air Freight (شحن جوي)"
            rec_container_type = "N/A (Air Freight Cargo)"
            rec_container_count = 0
        elif total_cbm <= 15.0:
            rec_method = "LCL Ocean Freight (شحن بحري تجميعي)"
            rec_container_type = "LCL Consolidation Container"
            rec_container_count = 1
        else:
            rec_method = "FCL Container (حاوية كاملة بحرية)"
            if total_cbm <= 33.0:
                rec_container_type = "20FT Standard Container (20' ST)"
                rec_container_count = 1
            elif total_cbm <= 67.0:
                rec_container_type = "40FT Standard Container (40' ST)"
                rec_container_count = 1
            elif total_cbm <= 76.0:
                rec_container_type = "40FT High Cube Container (40' HC)"
                rec_container_count = 1
            else:
                rec_container_count = math.ceil(total_cbm / 76.0)
                rec_container_type = f"40FT High Cube Containers (40' HC)"

        summary_totals = {
            "total_qty": total_qty,
            "total_cbm": total_cbm,
            "total_gross_weight_kg": total_gross_weight_kg,
            "total_volumetric_weight_kg": total_volumetric_weight_kg,
            "air_chargeable_weight_kg": air_chargeable_weight_kg,
            "recommended_shipping_method": rec_method,
            "recommended_container_type": rec_container_type,
            "recommended_container_count": rec_container_count,
        }

        return computed_items, summary_totals

    @staticmethod
    def quick_calculate(request: CBMQuickCalcRequest) -> CBMQuickCalcResponse:
        computed_items, summary = CBMService.compute_items_and_totals(request.items)
        return CBMQuickCalcResponse(
            total_qty=summary["total_qty"],
            total_cbm=summary["total_cbm"],
            total_gross_weight_kg=summary["total_gross_weight_kg"],
            total_volumetric_weight_kg=summary["total_volumetric_weight_kg"],
            air_chargeable_weight_kg=summary["air_chargeable_weight_kg"],
            recommended_shipping_method=summary["recommended_shipping_method"],
            recommended_container_type=summary["recommended_container_type"],
            recommended_container_count=summary["recommended_container_count"],
            items=computed_items,
        )

    @staticmethod
    def create_calculation_service(db: Session, payload: CBMCalculationCreate) -> CBMCalculationResponse:
        CBMValidator.validate_fk_references(db, project_id=payload.project_id, po_id=payload.po_id)
        computed_items, summary = CBMService.compute_items_and_totals(payload.items)

        calc_data = {
            "title": payload.title,
            "import_file_id": payload.import_file_id,
            "project_id": payload.project_id,
            "po_id": payload.po_id,
            "notes": payload.notes,
            "is_stackable": payload.is_stackable if payload.is_stackable is not None else True,
            **summary,
        }

        calc = CBMRepository.create(db, calc_data, computed_items)
        return CBMService._to_response(db, calc)

    @staticmethod
    def get_calculation_service(db: Session, calc_id: int) -> CBMCalculationResponse:
        calc = CBMRepository.get_by_id(db, calc_id)
        if not calc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"CBM Calculation record #{calc_id} not found.",
            )
        return CBMService._to_response(db, calc)

    @staticmethod
    def list_calculations_service(
        db: Session,
        include_inactive: bool = False,
        import_file_id: Optional[int] = None,
        project_id: Optional[int] = None,
        po_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[CBMCalculationResponse]:
        records = CBMRepository.get_all(
            db,
            include_inactive=include_inactive,
            import_file_id=import_file_id,
            project_id=project_id,
            po_id=po_id,
            search=search,
        )
        return [CBMService._to_response(db, r) for r in records]

    @staticmethod
    def update_calculation_service(
        db: Session, calc_id: int, payload: CBMCalculationUpdate
    ) -> CBMCalculationResponse:
        calc = CBMRepository.get_by_id(db, calc_id)
        if not calc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"CBM Calculation record #{calc_id} not found.",
            )

        CBMValidator.validate_fk_references(db, project_id=payload.project_id, po_id=payload.po_id)

        calc_data = {}
        if payload.title is not None:
            calc_data["title"] = payload.title
        if payload.import_file_id is not None:
            calc_data["import_file_id"] = payload.import_file_id
        if payload.project_id is not None:
            calc_data["project_id"] = payload.project_id
        if payload.po_id is not None:
            calc_data["po_id"] = payload.po_id
        if payload.notes is not None:
            calc_data["notes"] = payload.notes
        if payload.is_stackable is not None:
            calc_data["is_stackable"] = payload.is_stackable

        computed_items = None
        if payload.items is not None:
            computed_items, summary = CBMService.compute_items_and_totals(payload.items)
            calc_data.update(summary)

        updated_calc = CBMRepository.update(db, calc, calc_data, computed_items)
        return CBMService._to_response(db, updated_calc)

    @staticmethod
    def link_to_po_service(
        db: Session, calc_id: int, po_id: Optional[int] = None, project_id: Optional[int] = None
    ) -> CBMCalculationResponse:
        calc = CBMRepository.get_by_id(db, calc_id)
        if not calc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"CBM Calculation record #{calc_id} not found.",
            )

        CBMValidator.validate_fk_references(db, project_id=project_id, po_id=po_id)

        calc_data = {}
        if po_id is not None:
            calc_data["po_id"] = po_id
            po = db.query(PurchaseOrder).filter(PurchaseOrder.po_id == po_id).first()
            if po and po.project_id:
                calc_data["project_id"] = po.project_id

        if project_id is not None:
            calc_data["project_id"] = project_id

        updated = CBMRepository.update(db, calc, calc_data)
        return CBMService._to_response(db, updated)

    @staticmethod
    def soft_delete_service(db: Session, calc_id: int) -> dict:
        calc = CBMRepository.get_by_id(db, calc_id)
        if not calc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"CBM Calculation record #{calc_id} not found.",
            )
        CBMRepository.soft_delete(db, calc)
        return {"message": f"Calculation record '{calc.calc_code}' soft deleted successfully."}

    @staticmethod
    def restore_service(db: Session, calc_id: int) -> CBMCalculationResponse:
        calc = CBMRepository.get_by_id(db, calc_id)
        if not calc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"CBM Calculation record #{calc_id} not found.",
            )
        restored = CBMRepository.restore(db, calc)
        return CBMService._to_response(db, restored)

    @staticmethod
    def _to_response(db: Session, calc: CBMCalculation) -> CBMCalculationResponse:
        project_name = None
        if calc.project_id:
            prj = db.query(Project).filter(Project.project_id == calc.project_id).first()
            if prj:
                project_name = f"{prj.project_code} - {prj.project_name}"

        po_number = None
        if calc.po_id:
            po = db.query(PurchaseOrder).filter(PurchaseOrder.po_id == calc.po_id).first()
            if po:
                po_number = po.po_number

        import_file_code = None
        if calc.import_file_id:
            from modules.import_files.model import ImportFile
            imp = db.query(ImportFile).filter(ImportFile.import_file_id == calc.import_file_id).first()
            if imp:
                import_file_code = imp.import_file_code or imp.custom_file_number

        resp = CBMCalculationResponse.model_validate(calc)
        resp.project_name = project_name
        resp.po_number = po_number
        resp.import_file_code = import_file_code
        return resp
