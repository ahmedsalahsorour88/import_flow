from datetime import timedelta, date
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.shipping_scenarios.model import ShippingEvaluationSession
from modules.shipping_scenarios.repository import ShippingScenarioRepository
from modules.shipping_scenarios.schemas import (
    ShippingEvaluationCreate,
    ShippingEvaluationUpdate,
    ShippingEvaluationResponse,
    ShippingScenarioItemCalculated,
)
from modules.shipping_scenarios.validators import ShippingScenarioValidator


class ShippingScenarioService:
    """
    Business Logic & Calculation Engine for BP-007 Shipping Scenarios Evaluation
    """

    @staticmethod
    def _enrich_session_response(
        db: Session, session_obj: ShippingEvaluationSession
    ) -> ShippingEvaluationResponse:
        crd = session_obj.cargo_ready_date
        form4_days = session_obj.avg_form4_days
        clearance_days = session_obj.avg_clearance_days

        calculated_items: List[ShippingScenarioItemCalculated] = []
        valid_transit_days: List[int] = []
        valid_arrival_dates: List[date] = []

        earliest_item: Optional[ShippingScenarioItemCalculated] = None
        latest_item: Optional[ShippingScenarioItemCalculated] = None
        recommended_provider: Optional[str] = None
        min_days = 999999

        for item in session_obj.items:
            vessel_lead_time = (item.estimated_arrival_date - item.sailing_date).days
            ready_for_shipping = (item.sailing_date - crd).days
            expected_total_days = (
                vessel_lead_time
                + ready_for_shipping
                + form4_days
                + clearance_days
                + item.expected_line_delay_days
            )
            expected_wh_date = crd + timedelta(days=expected_total_days)

            calc_item = ShippingScenarioItemCalculated(
                item_id=item.item_id,
                provider_id=item.provider_id,
                provider_name=item.provider_name,
                vessel_name=item.vessel_name,
                voyage_number=item.voyage_number,
                sailing_date=item.sailing_date,
                estimated_arrival_date=item.estimated_arrival_date,
                expected_line_delay_days=item.expected_line_delay_days,
                is_excluded_from_average=item.is_excluded_from_average,
                is_recommended=item.is_recommended,
                is_selected=item.is_selected,
                risk_level=item.risk_level,
                notes=item.notes,
                vessel_lead_time_days=vessel_lead_time,
                ready_for_shipping_days=ready_for_shipping,
                expected_total_days_to_warehouse=expected_total_days,
                expected_warehouse_arrival_date=expected_wh_date,
            )
            calculated_items.append(calc_item)

            if item.is_recommended:
                recommended_provider = f"{item.provider_name} ({item.vessel_name})"

            if not item.is_excluded_from_average:
                valid_transit_days.append(expected_total_days)
                valid_arrival_dates.append(expected_wh_date)

                if earliest_item is None or expected_wh_date < earliest_item.expected_warehouse_arrival_date:
                    earliest_item = calc_item
                if latest_item is None or expected_wh_date > latest_item.expected_warehouse_arrival_date:
                    latest_item = calc_item

                if expected_total_days < min_days and recommended_provider is None:
                    min_days = expected_total_days

        avg_transit = (
            sum(valid_transit_days) / len(valid_transit_days)
            if valid_transit_days
            else 0.0
        )
        avg_wh_date = (
            crd + timedelta(days=round(avg_transit))
            if valid_transit_days
            else None
        )

        if not recommended_provider and earliest_item:
            recommended_provider = f"{earliest_item.provider_name} ({earliest_item.vessel_name})"

        # Fetch names for linked entities if present
        po_num = session_obj.po.po_number if getattr(session_obj, "po", None) else None
        prj_name = session_obj.project.project_name if getattr(session_obj, "project", None) else None

        return ShippingEvaluationResponse(
            session_id=session_obj.session_id,
            session_code=session_obj.session_code,
            title=session_obj.title,
            cargo_ready_date=session_obj.cargo_ready_date,
            port_of_loading_id=session_obj.port_of_loading_id,
            port_of_discharge_id=session_obj.port_of_discharge_id,
            avg_form4_days=session_obj.avg_form4_days,
            avg_clearance_days=session_obj.avg_clearance_days,
            po_id=session_obj.po_id,
            project_id=session_obj.project_id,
            notes=session_obj.notes,
            is_active=session_obj.is_active,
            created_at=session_obj.created_at,
            updated_at=session_obj.updated_at,
            po_number=po_num,
            project_name=prj_name,
            items=calculated_items,
            avg_expected_transit_days=round(avg_transit, 1),
            avg_expected_warehouse_arrival_date=avg_wh_date,
            earliest_arrival_scenario_provider=earliest_item.provider_name if earliest_item else None,
            earliest_arrival_date=earliest_item.expected_warehouse_arrival_date if earliest_item else None,
            latest_arrival_scenario_provider=latest_item.provider_name if latest_item else None,
            latest_arrival_date=latest_item.expected_warehouse_arrival_date if latest_item else None,
            recommended_scenario_provider=recommended_provider,
        )

    @staticmethod
    def create_session_service(
        db: Session, payload: ShippingEvaluationCreate
    ) -> ShippingEvaluationResponse:
        ShippingScenarioValidator.validate_evaluation_create(payload)
        session_obj = ShippingScenarioRepository.create(db, payload)
        return ShippingScenarioService._enrich_session_response(db, session_obj)

    @staticmethod
    def get_session_service(
        db: Session, session_id: int
    ) -> ShippingEvaluationResponse:
        session_obj = ShippingScenarioRepository.get_by_id(db, session_id)
        if not session_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Shipping evaluation session with ID {session_id} not found.",
            )
        return ShippingScenarioService._enrich_session_response(db, session_obj)

    @staticmethod
    def list_sessions_service(
        db: Session,
        include_inactive: bool = False,
        project_id: Optional[int] = None,
        po_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[ShippingEvaluationResponse]:
        sessions = ShippingScenarioRepository.list_sessions(
            db,
            include_inactive=include_inactive,
            project_id=project_id,
            po_id=po_id,
            search=search,
        )
        return [
            ShippingScenarioService._enrich_session_response(db, s) for s in sessions
        ]

    @staticmethod
    def update_session_service(
        db: Session, session_id: int, payload: ShippingEvaluationUpdate
    ) -> ShippingEvaluationResponse:
        session_obj = ShippingScenarioRepository.get_by_id(db, session_id)
        if not session_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Shipping evaluation session with ID {session_id} not found.",
            )

        effective_crd = payload.cargo_ready_date or session_obj.cargo_ready_date
        if payload.items:
            ShippingScenarioValidator.validate_scenario_items(
                effective_crd, payload.items
            )

        updated_obj = ShippingScenarioRepository.update(db, session_obj, payload)
        return ShippingScenarioService._enrich_session_response(db, updated_obj)

    @staticmethod
    def soft_delete_service(db: Session, session_id: int) -> dict:
        session_obj = ShippingScenarioRepository.get_by_id(db, session_id)
        if not session_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Shipping evaluation session with ID {session_id} not found.",
            )
        ShippingScenarioRepository.soft_delete(db, session_obj)
        return {
            "message": f"Shipping evaluation session {session_obj.session_code} deactivated successfully."
        }

    @staticmethod
    def restore_service(db: Session, session_id: int) -> ShippingEvaluationResponse:
        session_obj = ShippingScenarioRepository.get_by_id(db, session_id)
        if not session_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Shipping evaluation session with ID {session_id} not found.",
            )
        restored_obj = ShippingScenarioRepository.restore(db, session_obj)
        return ShippingScenarioService._enrich_session_response(db, restored_obj)
