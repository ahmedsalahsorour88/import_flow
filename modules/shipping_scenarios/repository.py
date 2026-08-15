from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc

from modules.shipping_scenarios.model import (
    ShippingEvaluationSession,
    ShippingScenarioItem,
)
from modules.shipping_scenarios.schemas import (
    ShippingEvaluationCreate,
    ShippingEvaluationUpdate,
)


class ShippingScenarioRepository:
    """
    Database queries & persistence layer for BP-007 Shipping Scenarios Evaluation
    """

    @staticmethod
    def generate_session_code(db: Session) -> str:
        current_year = datetime.now().year
        prefix = f"SCE-{current_year}-"
        last_session = (
            db.query(ShippingEvaluationSession)
            .filter(ShippingEvaluationSession.session_code.like(f"{prefix}%"))
            .order_by(desc(ShippingEvaluationSession.session_id))
            .first()
        )
        if not last_session:
            return f"{prefix}001"
        try:
            last_num = int(last_session.session_code.split("-")[-1])
            return f"{prefix}{last_num + 1:03d}"
        except ValueError:
            return f"{prefix}{datetime.now().strftime('%m%d%H%M')}"

    @staticmethod
    def create(db: Session, payload: ShippingEvaluationCreate) -> ShippingEvaluationSession:
        code = ShippingScenarioRepository.generate_session_code(db)

        session_obj = ShippingEvaluationSession(
            session_code=code,
            title=payload.title,
            cargo_ready_date=payload.cargo_ready_date,
            pick_up_address=payload.pick_up_address,
            port_of_loading_id=payload.port_of_loading_id,
            port_of_discharge_id=payload.port_of_discharge_id,
            avg_form4_days=payload.avg_form4_days,
            avg_clearance_days=payload.avg_clearance_days,
            import_file_id=payload.import_file_id,
            po_id=payload.po_id,
            project_id=payload.project_id,
            notes=payload.notes,
            is_active=True,
        )
        db.add(session_obj)
        db.flush()

        for item_data in payload.items:
            item_obj = ShippingScenarioItem(
                session_id=session_obj.session_id,
                provider_id=item_data.provider_id,
                provider_name=item_data.provider_name.strip(),
                customs_broker_id=item_data.customs_broker_id,
                customs_broker_name=item_data.customs_broker_name.strip() if item_data.customs_broker_name else None,
                vessel_name=item_data.vessel_name.strip(),
                voyage_number=item_data.voyage_number.strip() if item_data.voyage_number else None,
                port_of_loading_id=item_data.port_of_loading_id,
                port_of_discharge_id=item_data.port_of_discharge_id,
                pol_name=item_data.pol_name.strip() if item_data.pol_name else None,
                pod_name=item_data.pod_name.strip() if item_data.pod_name else None,
                sailing_date=item_data.sailing_date,
                estimated_arrival_date=item_data.estimated_arrival_date,
                expected_line_delay_days=item_data.expected_line_delay_days,
                is_excluded_from_average=item_data.is_excluded_from_average,
                is_recommended=item_data.is_recommended,
                is_selected=item_data.is_selected,
                risk_level=item_data.risk_level,
                notes=item_data.notes,
                # Quotation fields mapping
                free_time_days=item_data.free_time_days,
                quotation_currency=item_data.quotation_currency,
                total_quotation_amount=item_data.total_quotation_amount,
                container_40ft_applicable=item_data.container_40ft_applicable,
                container_40ft_price=item_data.container_40ft_price,
                container_40ft_currency=item_data.container_40ft_currency,
                container_40ft_qty=item_data.container_40ft_qty,
                container_20ft_applicable=item_data.container_20ft_applicable,
                container_20ft_price=item_data.container_20ft_price,
                container_20ft_currency=item_data.container_20ft_currency,
                container_20ft_qty=item_data.container_20ft_qty,
                lcl_cbm_applicable=item_data.lcl_cbm_applicable,
                lcl_cbm_price=item_data.lcl_cbm_price,
                lcl_cbm_currency=item_data.lcl_cbm_currency,
                lcl_cbm_qty=item_data.lcl_cbm_qty,
                express_courier_applicable=item_data.express_courier_applicable,
                express_courier_price=item_data.express_courier_price,
                express_courier_currency=item_data.express_courier_currency,
                eur_atr_applicable=item_data.eur_atr_applicable,
                eur_atr_price=item_data.eur_atr_price,
                eur_atr_currency=item_data.eur_atr_currency,
                solas_vgm_applicable=item_data.solas_vgm_applicable,
                solas_vgm_price=item_data.solas_vgm_price,
                solas_vgm_currency=item_data.solas_vgm_currency,
                vgm_notification_applicable=item_data.vgm_notification_applicable,
                vgm_notification_price=item_data.vgm_notification_price,
                vgm_notification_currency=item_data.vgm_notification_currency,
                telex_release_applicable=item_data.telex_release_applicable,
                telex_release_price=item_data.telex_release_price,
                telex_release_currency=item_data.telex_release_currency,
                insurance_applicable=item_data.insurance_applicable,
                insurance_price=item_data.insurance_price,
                insurance_currency=item_data.insurance_currency,
                booking_cancellation_applicable=item_data.booking_cancellation_applicable,
                booking_cancellation_price=item_data.booking_cancellation_price,
                booking_cancellation_currency=item_data.booking_cancellation_currency,
                ics2_filing_fee_applicable=item_data.ics2_filing_fee_applicable,
                ics2_filing_fee_price=item_data.ics2_filing_fee_price,
                ics2_filing_fee_currency=item_data.ics2_filing_fee_currency,
                others_fee_applicable=item_data.others_fee_applicable,
                others_fee_price=item_data.others_fee_price,
                others_fee_currency=item_data.others_fee_currency,
                document_fees_applicable=item_data.document_fees_applicable,
                document_fees_price=item_data.document_fees_price,
                document_fees_currency=item_data.document_fees_currency,
                waiver_letter_fee_applicable=item_data.waiver_letter_fee_applicable,
                waiver_letter_fee_price=item_data.waiver_letter_fee_price,
                waiver_letter_fee_currency=item_data.waiver_letter_fee_currency,
                dthc_applicable=item_data.dthc_applicable,
                dthc_price=item_data.dthc_price,
                dthc_currency=item_data.dthc_currency,
                storage_per_week_applicable=item_data.storage_per_week_applicable,
                storage_per_week_price=item_data.storage_per_week_price,
                storage_per_week_currency=item_data.storage_per_week_currency,
                extra_day_storage_applicable=item_data.extra_day_storage_applicable,
                extra_day_storage_price=item_data.extra_day_storage_price,
                extra_day_storage_currency=item_data.extra_day_storage_currency,
            )
            db.add(item_obj)

        db.commit()
        db.refresh(session_obj)
        return session_obj

    @staticmethod
    def get_by_id(db: Session, session_id: int) -> Optional[ShippingEvaluationSession]:
        return (
            db.query(ShippingEvaluationSession)
            .filter(ShippingEvaluationSession.session_id == session_id)
            .first()
        )

    @staticmethod
    def list_sessions(
        db: Session,
        include_inactive: bool = False,
        import_file_id: Optional[int] = None,
        project_id: Optional[int] = None,
        po_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[ShippingEvaluationSession]:
        query = db.query(ShippingEvaluationSession)
        if not include_inactive:
            query = query.filter(ShippingEvaluationSession.is_active.is_(True))
        if import_file_id:
            query = query.filter(ShippingEvaluationSession.import_file_id == import_file_id)
        if project_id:
            query = query.filter(ShippingEvaluationSession.project_id == project_id)
        if po_id:
            query = query.filter(ShippingEvaluationSession.po_id == po_id)
        if search:
            pattern = f"%{search}%"
            query = query.filter(
                or_(
                    ShippingEvaluationSession.session_code.ilike(pattern),
                    ShippingEvaluationSession.title.ilike(pattern),
                    ShippingEvaluationSession.notes.ilike(pattern),
                )
            )
        return query.order_by(desc(ShippingEvaluationSession.session_id)).all()

    @staticmethod
    def update(
        db: Session, session_obj: ShippingEvaluationSession, payload: ShippingEvaluationUpdate
    ) -> ShippingEvaluationSession:
        if payload.title is not None:
            session_obj.title = payload.title
        if payload.cargo_ready_date is not None:
            session_obj.cargo_ready_date = payload.cargo_ready_date
        if payload.pick_up_address is not None:
            session_obj.pick_up_address = payload.pick_up_address
        if payload.port_of_loading_id is not None:
            session_obj.port_of_loading_id = payload.port_of_loading_id
        if payload.port_of_discharge_id is not None:
            session_obj.port_of_discharge_id = payload.port_of_discharge_id
        if payload.avg_form4_days is not None:
            session_obj.avg_form4_days = payload.avg_form4_days
        if payload.avg_clearance_days is not None:
            session_obj.avg_clearance_days = payload.avg_clearance_days
        if payload.import_file_id is not None:
            session_obj.import_file_id = payload.import_file_id
        if payload.po_id is not None:
            session_obj.po_id = payload.po_id
        if payload.project_id is not None:
            session_obj.project_id = payload.project_id
        if payload.notes is not None:
            session_obj.notes = payload.notes

        if payload.items is not None:
            # Re-replace items
            db.query(ShippingScenarioItem).filter(
                ShippingScenarioItem.session_id == session_obj.session_id
            ).delete()
            for item_data in payload.items:
                item_obj = ShippingScenarioItem(
                    session_id=session_obj.session_id,
                    provider_id=item_data.provider_id,
                    provider_name=item_data.provider_name.strip(),
                    customs_broker_id=item_data.customs_broker_id,
                    customs_broker_name=item_data.customs_broker_name.strip() if item_data.customs_broker_name else None,
                    vessel_name=item_data.vessel_name.strip(),
                    voyage_number=item_data.voyage_number.strip() if item_data.voyage_number else None,
                    port_of_loading_id=item_data.port_of_loading_id,
                    port_of_discharge_id=item_data.port_of_discharge_id,
                    pol_name=item_data.pol_name.strip() if item_data.pol_name else None,
                    pod_name=item_data.pod_name.strip() if item_data.pod_name else None,
                    sailing_date=item_data.sailing_date,
                    estimated_arrival_date=item_data.estimated_arrival_date,
                    expected_line_delay_days=item_data.expected_line_delay_days,
                    is_excluded_from_average=item_data.is_excluded_from_average,
                    is_recommended=item_data.is_recommended,
                    is_selected=item_data.is_selected,
                    risk_level=item_data.risk_level,
                    notes=item_data.notes,
                    # Quotation fields mapping
                    free_time_days=item_data.free_time_days,
                    quotation_currency=item_data.quotation_currency,
                    total_quotation_amount=item_data.total_quotation_amount,
                    container_40ft_applicable=item_data.container_40ft_applicable,
                    container_40ft_price=item_data.container_40ft_price,
                    container_40ft_currency=item_data.container_40ft_currency,
                    container_40ft_qty=item_data.container_40ft_qty,
                    container_20ft_applicable=item_data.container_20ft_applicable,
                    container_20ft_price=item_data.container_20ft_price,
                    container_20ft_currency=item_data.container_20ft_currency,
                    container_20ft_qty=item_data.container_20ft_qty,
                    lcl_cbm_applicable=item_data.lcl_cbm_applicable,
                    lcl_cbm_price=item_data.lcl_cbm_price,
                    lcl_cbm_currency=item_data.lcl_cbm_currency,
                    lcl_cbm_qty=item_data.lcl_cbm_qty,
                    express_courier_applicable=item_data.express_courier_applicable,
                    express_courier_price=item_data.express_courier_price,
                    express_courier_currency=item_data.express_courier_currency,
                    eur_atr_applicable=item_data.eur_atr_applicable,
                    eur_atr_price=item_data.eur_atr_price,
                    eur_atr_currency=item_data.eur_atr_currency,
                    solas_vgm_applicable=item_data.solas_vgm_applicable,
                    solas_vgm_price=item_data.solas_vgm_price,
                    solas_vgm_currency=item_data.solas_vgm_currency,
                    vgm_notification_applicable=item_data.vgm_notification_applicable,
                    vgm_notification_price=item_data.vgm_notification_price,
                    vgm_notification_currency=item_data.vgm_notification_currency,
                    telex_release_applicable=item_data.telex_release_applicable,
                    telex_release_price=item_data.telex_release_price,
                    telex_release_currency=item_data.telex_release_currency,
                    insurance_applicable=item_data.insurance_applicable,
                    insurance_price=item_data.insurance_price,
                    insurance_currency=item_data.insurance_currency,
                    booking_cancellation_applicable=item_data.booking_cancellation_applicable,
                    booking_cancellation_price=item_data.booking_cancellation_price,
                    booking_cancellation_currency=item_data.booking_cancellation_currency,
                    ics2_filing_fee_applicable=item_data.ics2_filing_fee_applicable,
                    ics2_filing_fee_price=item_data.ics2_filing_fee_price,
                    ics2_filing_fee_currency=item_data.ics2_filing_fee_currency,
                    others_fee_applicable=item_data.others_fee_applicable,
                    others_fee_price=item_data.others_fee_price,
                    others_fee_currency=item_data.others_fee_currency,
                    document_fees_applicable=item_data.document_fees_applicable,
                    document_fees_price=item_data.document_fees_price,
                    document_fees_currency=item_data.document_fees_currency,
                    waiver_letter_fee_applicable=item_data.waiver_letter_fee_applicable,
                    waiver_letter_fee_price=item_data.waiver_letter_fee_price,
                    waiver_letter_fee_currency=item_data.waiver_letter_fee_currency,
                    dthc_applicable=item_data.dthc_applicable,
                    dthc_price=item_data.dthc_price,
                    dthc_currency=item_data.dthc_currency,
                    storage_per_week_applicable=item_data.storage_per_week_applicable,
                    storage_per_week_price=item_data.storage_per_week_price,
                    storage_per_week_currency=item_data.storage_per_week_currency,
                    extra_day_storage_applicable=item_data.extra_day_storage_applicable,
                    extra_day_storage_price=item_data.extra_day_storage_price,
                    extra_day_storage_currency=item_data.extra_day_storage_currency,
                )
                db.add(item_obj)

        session_obj.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(session_obj)
        return session_obj

    @staticmethod
    def soft_delete(db: Session, session_obj: ShippingEvaluationSession) -> None:
        session_obj.is_active = False
        session_obj.updated_at = datetime.now(timezone.utc)
        db.commit()

    @staticmethod
    def restore(db: Session, session_obj: ShippingEvaluationSession) -> ShippingEvaluationSession:
        session_obj.is_active = True
        session_obj.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(session_obj)
        return session_obj
