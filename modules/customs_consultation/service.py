"""
Customs Consultation Service Engine (BP-009)
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from modules.customs_consultation.model import CustomsConsultationSession
from modules.customs_consultation.schemas import (
    CustomsConsultationCreate,
    CustomsConsultationUpdate,
    CustomsConsultationResponse,
)
from modules.customs_consultation.repository import CustomsConsultationRepository
from modules.customs_consultation.validators import validate_broker_exists, validate_checklist_items


class CustomsConsultationService:

    @staticmethod
    def _compute_session_metrics(db_session: CustomsConsultationSession) -> CustomsConsultationResponse:
        """
        Calculates total documents, approved count, blocking issues count, readiness %, and overall status.
        """
        items = db_session.checklist_items or []
        total_count = len(items)
        approved_count = sum(1 for item in items if item.status == "Approved")
        rejected_count = sum(1 for item in items if item.status == "Rejected")
        blocking_count = sum(
            1 for item in items if item.is_blocking_shipment and item.status == "Rejected"
        )
        
        readiness_pct = (approved_count / total_count * 100.0) if total_count > 0 else 0.0
        readiness_pct = round(readiness_pct, 1)

        has_blocking = blocking_count > 0

        # Auto evaluate status if not explicitly locked or override
        overall_status = db_session.overall_status
        if has_blocking:
            overall_status = "Blocked"
        elif readiness_pct == 100.0 and total_count > 0:
            overall_status = "Clearance Ready"
        elif rejected_count > 0:
            overall_status = "Action Required"
        elif approved_count > 0 or any(i.status == "Verified" for i in items):
            overall_status = "In Progress"

        db_session.readiness_percentage = readiness_pct
        db_session.has_blocking_issues = has_blocking
        db_session.overall_status = overall_status

        res = CustomsConsultationResponse.model_validate(db_session)
        res.total_documents_count = total_count
        res.approved_documents_count = approved_count
        res.blocking_issues_count = blocking_count
        res.readiness_percentage = readiness_pct
        res.has_blocking_issues = has_blocking
        res.overall_status = overall_status
        return res

    @staticmethod
    def create_consultation(
        db: Session, session_in: CustomsConsultationCreate
    ) -> CustomsConsultationResponse:
        validate_broker_exists(db, session_in.broker_id)
        validate_checklist_items(session_in.checklist_items)

        db_session = CustomsConsultationRepository.create(db, session_in)
        return CustomsConsultationService._compute_session_metrics(db_session)

    @staticmethod
    def get_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        return CustomsConsultationService._compute_session_metrics(db_session)

    @staticmethod
    def list_consultations(
        db: Session,
        include_inactive: bool = False,
        search: Optional[str] = None,
        broker_id: Optional[int] = None,
        po_id: Optional[int] = None,
        project_id: Optional[int] = None,
        status: Optional[str] = None,
    ) -> List[CustomsConsultationResponse]:
        sessions = CustomsConsultationRepository.get_all(
            db,
            include_inactive=include_inactive,
            search=search,
            broker_id=broker_id,
            po_id=po_id,
            project_id=project_id,
            status=status,
        )
        return [CustomsConsultationService._compute_session_metrics(s) for s in sessions]

    @staticmethod
    def update_consultation(
        db: Session, consultation_id: int, update_in: CustomsConsultationUpdate
    ) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )

        if update_in.broker_id is not None:
            validate_broker_exists(db, update_in.broker_id)

        if update_in.checklist_items is not None:
            validate_checklist_items(update_in.checklist_items)

        updated_session = CustomsConsultationRepository.update(db, db_session, update_in)
        return CustomsConsultationService._compute_session_metrics(updated_session)

    @staticmethod
    def soft_delete_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        deleted_session = CustomsConsultationRepository.soft_delete(db, db_session)
        return CustomsConsultationService._compute_session_metrics(deleted_session)

    @staticmethod
    def restore_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        restored_session = CustomsConsultationRepository.restore(db, db_session)
        return CustomsConsultationService._compute_session_metrics(restored_session)
