"""
Customs Consultation & Broker Price Lists Service Engine (BP-009)
"""

from datetime import datetime, date, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from modules.customs_consultation.model import (
    ClearanceExpenseType,
    BrokerPriceList,
    CustomsConsultationSession,
)
from modules.customs_consultation.schemas import (
    ClearanceExpenseTypeCreate,
    ClearanceExpenseTypeUpdate,
    ClearanceExpenseTypeResponse,
    BrokerPriceListCreate,
    BrokerPriceListUpdate,
    BrokerPriceListResponse,
    CustomsConsultationCreate,
    CustomsConsultationUpdate,
    CustomsConsultationResponse,
)
from modules.customs_consultation.repository import (
    ClearanceExpenseTypeRepository,
    BrokerPriceListRepository,
    CustomsConsultationRepository,
)
from modules.customs_consultation.validators import (
    validate_broker_exists,
    validate_checklist_items,
    validate_expense_code_unique,
)


# ==============================================================================
# Clearance Expense Types Service
# ==============================================================================

class ClearanceExpenseTypeService:

    @staticmethod
    def create_expense_type(db: Session, schema: ClearanceExpenseTypeCreate) -> ClearanceExpenseTypeResponse:
        validate_expense_code_unique(db, schema.expense_code)
        obj = ClearanceExpenseTypeRepository.create(db, schema)
        return ClearanceExpenseTypeResponse.model_validate(obj)

    @staticmethod
    def get_expense_type(db: Session, expense_id: int) -> ClearanceExpenseTypeResponse:
        obj = ClearanceExpenseTypeRepository.get_by_id(db, expense_id)
        if not obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Expense Type with ID '{expense_id}' not found.",
            )
        return ClearanceExpenseTypeResponse.model_validate(obj)

    @staticmethod
    def list_expense_types(
        db: Session,
        include_inactive: bool = False,
        category: Optional[str] = None,
        search: Optional[str] = None,
    ) -> List[ClearanceExpenseTypeResponse]:
        items = ClearanceExpenseTypeRepository.get_all(
            db, include_inactive=include_inactive, category=category, search=search
        )
        return [ClearanceExpenseTypeResponse.model_validate(i) for i in items]

    @staticmethod
    def update_expense_type(
        db: Session, expense_id: int, schema: ClearanceExpenseTypeUpdate
    ) -> ClearanceExpenseTypeResponse:
        obj = ClearanceExpenseTypeRepository.get_by_id(db, expense_id)
        if not obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Expense Type with ID '{expense_id}' not found.",
            )
        if schema.expense_code and schema.expense_code != obj.expense_code:
            validate_expense_code_unique(db, schema.expense_code, current_id=expense_id)
        updated = ClearanceExpenseTypeRepository.update(db, obj, schema)
        return ClearanceExpenseTypeResponse.model_validate(updated)

    @staticmethod
    def delete_expense_type(db: Session, expense_id: int) -> ClearanceExpenseTypeResponse:
        obj = ClearanceExpenseTypeRepository.get_by_id(db, expense_id)
        if not obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Expense Type with ID '{expense_id}' not found.",
            )
        deleted = ClearanceExpenseTypeRepository.delete(db, obj)
        return ClearanceExpenseTypeResponse.model_validate(deleted)


# ==============================================================================
# Broker Price Lists Service
# ==============================================================================

class BrokerPriceListService:

    @staticmethod
    def create_price_list(db: Session, schema: BrokerPriceListCreate) -> BrokerPriceListResponse:
        validate_broker_exists(db, schema.broker_id)
        pl = BrokerPriceListRepository.create(db, schema)
        return BrokerPriceListResponse.model_validate(pl)

    @staticmethod
    def get_price_list(db: Session, price_list_id: int) -> BrokerPriceListResponse:
        pl = BrokerPriceListRepository.get_by_id(db, price_list_id)
        if not pl:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Broker Price List with ID '{price_list_id}' not found.",
            )
        return BrokerPriceListResponse.model_validate(pl)

    @staticmethod
    def list_price_lists(
        db: Session,
        include_inactive: bool = False,
        broker_id: Optional[int] = None,
        search: Optional[str] = None,
    ) -> List[BrokerPriceListResponse]:
        lists = BrokerPriceListRepository.get_all(
            db, include_inactive=include_inactive, broker_id=broker_id, search=search
        )
        return [BrokerPriceListResponse.model_validate(l) for l in lists]

    @staticmethod
    def get_active_price_list_for_broker(
        db: Session, broker_id: int, target_date: Optional[date] = None
    ) -> Optional[BrokerPriceListResponse]:
        validate_broker_exists(db, broker_id)
        pl = BrokerPriceListRepository.get_active_by_broker(db, broker_id, target_date)
        if not pl:
            return None
        return BrokerPriceListResponse.model_validate(pl)

    @staticmethod
    def update_price_list(
        db: Session, price_list_id: int, schema: BrokerPriceListUpdate
    ) -> BrokerPriceListResponse:
        pl = BrokerPriceListRepository.get_by_id(db, price_list_id)
        if not pl:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Broker Price List with ID '{price_list_id}' not found.",
            )
        if schema.broker_id:
            validate_broker_exists(db, schema.broker_id)
        updated = BrokerPriceListRepository.update(db, pl, schema)
        return BrokerPriceListResponse.model_validate(updated)

    @staticmethod
    def soft_delete_price_list(db: Session, price_list_id: int) -> BrokerPriceListResponse:
        pl = BrokerPriceListRepository.get_by_id(db, price_list_id)
        if not pl:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Broker Price List with ID '{price_list_id}' not found.",
            )
        deleted = BrokerPriceListRepository.soft_delete(db, pl)
        return BrokerPriceListResponse.model_validate(deleted)


# ==============================================================================
# Customs Consultation Session Service
# ==============================================================================

class CustomsConsultationService:

    @staticmethod
    def _compute_session_metrics(db: Session, db_session: CustomsConsultationSession) -> CustomsConsultationResponse:
        """
        Calculates total documents, approved count, blocking issues count, readiness %,
        total broker fees, applied broker items count, and overall status.
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

        # Broker quote items metrics
        quote_items = db_session.broker_quote_items or []
        applied_broker_count = sum(1 for q in quote_items if q.is_applicable)
        total_broker_fees = sum(q.total_amount for q in quote_items if q.is_applicable)
        db_session.total_broker_fees_egp = total_broker_fees

        import_file_code = None
        if db_session.import_file_id:
            from modules.import_files.model import ImportFile
            imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_session.import_file_id).first()
            if imp:
                import_file_code = imp.import_file_code or imp.custom_file_number

        res = CustomsConsultationResponse.model_validate(db_session)
        res.total_documents_count = total_count
        res.approved_documents_count = approved_count
        res.blocking_issues_count = blocking_count
        res.applied_broker_items_count = applied_broker_count
        res.readiness_percentage = readiness_pct
        res.has_blocking_issues = has_blocking
        res.overall_status = overall_status
        res.import_file_code = import_file_code
        res.total_broker_fees_egp = total_broker_fees
        return res

    @staticmethod
    def create_consultation(
        db: Session, session_in: CustomsConsultationCreate
    ) -> CustomsConsultationResponse:
        validate_broker_exists(db, session_in.broker_id)
        validate_checklist_items(session_in.checklist_items)

        # Prevent duplicate consultation creation for the same import file
        if session_in.import_file_id:
            existing = CustomsConsultationRepository.list_consultations(db, import_file_id=session_in.import_file_id)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"يوجد بالفعل دراسة استشارة جمركية محفوظة لهذا الملف. يرجى الذهاب لتعديل الدراسة الحالية بدلاً من إنشاء دراسة جديدة.",
                )

        db_session = CustomsConsultationRepository.create(db, session_in)
        return CustomsConsultationService._compute_session_metrics(db, db_session)

    @staticmethod
    def get_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        return CustomsConsultationService._compute_session_metrics(db, db_session)

    @staticmethod
    def list_consultations(
        db: Session,
        include_inactive: bool = False,
        search: Optional[str] = None,
        broker_id: Optional[int] = None,
        import_file_id: Optional[int] = None,
        po_id: Optional[int] = None,
        project_id: Optional[int] = None,
        status: Optional[str] = None,
    ) -> List[CustomsConsultationResponse]:
        sessions = CustomsConsultationRepository.get_all(
            db,
            include_inactive=include_inactive,
            search=search,
            broker_id=broker_id,
            import_file_id=import_file_id,
            po_id=po_id,
            project_id=project_id,
            status=status,
        )
        return [CustomsConsultationService._compute_session_metrics(db, s) for s in sessions]

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
        return CustomsConsultationService._compute_session_metrics(db, updated_session)

    @staticmethod
    def soft_delete_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        deleted_session = CustomsConsultationRepository.soft_delete(db, db_session)
        return CustomsConsultationService._compute_session_metrics(db, deleted_session)

    @staticmethod
    def restore_consultation(db: Session, consultation_id: int) -> CustomsConsultationResponse:
        db_session = CustomsConsultationRepository.get_by_id(db, consultation_id)
        if not db_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customs Consultation study with ID '{consultation_id}' not found.",
            )
        restored_session = CustomsConsultationRepository.restore(db, db_session)
        return CustomsConsultationService._compute_session_metrics(db, restored_session)
