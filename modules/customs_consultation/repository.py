"""
Customs Consultation Database Repository (BP-009)
"""

from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from modules.customs_consultation.model import CustomsConsultationSession, CustomsChecklistItem
from modules.customs_consultation.schemas import CustomsConsultationCreate, CustomsConsultationUpdate


class CustomsConsultationRepository:

    @staticmethod
    def generate_consultation_code(db: Session) -> str:
        """
        Generates auto-incremented consultation code in format CUS-YYYY-XXX (e.g. CUS-2026-001).
        """
        current_year = datetime.utcnow().year
        prefix = f"CUS-{current_year}-"
        
        last_session = (
            db.query(CustomsConsultationSession)
            .filter(CustomsConsultationSession.consultation_code.like(f"{prefix}%"))
            .order_by(CustomsConsultationSession.consultation_id.desc())
            .first()
        )
        
        if last_session:
            try:
                last_num = int(last_session.consultation_code.split("-")[-1])
                new_num = last_num + 1
            except ValueError:
                new_num = 1
        else:
            new_num = 1

        return f"{prefix}{new_num:03d}"

    @staticmethod
    def create(db: Session, session_in: CustomsConsultationCreate) -> CustomsConsultationSession:
        code = CustomsConsultationRepository.generate_consultation_code(db)
        
        db_session = CustomsConsultationSession(
            consultation_code=code,
            title=session_in.title,
            broker_id=session_in.broker_id,
            broker_name=session_in.broker_name,
            broker_contact_person=session_in.broker_contact_person,
            import_file_id=session_in.import_file_id,
            po_id=session_in.po_id,
            project_id=session_in.project_id,
            overall_status=session_in.overall_status,
            estimated_duties_egp=session_in.estimated_duties_egp,
            notes=session_in.notes,
            is_active=True,
        )

        db.add(db_session)
        db.flush()  # get consultation_id

        for item_in in session_in.checklist_items:
            db_item = CustomsChecklistItem(
                consultation_id=db_session.consultation_id,
                document_type=item_in.document_type,
                hs_code=item_in.hs_code,
                is_required=item_in.is_required,
                is_blocking_shipment=item_in.is_blocking_shipment,
                responsible_party=item_in.responsible_party,
                status=item_in.status,
                received_date=item_in.received_date,
                verified_date=item_in.verified_date,
                regulatory_agency=item_in.regulatory_agency,
                remarks=item_in.remarks,
                corrective_action_required=item_in.corrective_action_required,
            )
            db.add(db_item)

        db.commit()
        db.refresh(db_session)
        return db_session

    @staticmethod
    def get_by_id(db: Session, consultation_id: int) -> Optional[CustomsConsultationSession]:
        return (
            db.query(CustomsConsultationSession)
            .filter(CustomsConsultationSession.consultation_id == consultation_id)
            .first()
        )

    @staticmethod
    def get_all(
        db: Session,
        include_inactive: bool = False,
        search: Optional[str] = None,
        broker_id: Optional[int] = None,
        import_file_id: Optional[int] = None,
        po_id: Optional[int] = None,
        project_id: Optional[int] = None,
        status: Optional[str] = None,
    ) -> List[CustomsConsultationSession]:
        query = db.query(CustomsConsultationSession)

        if not include_inactive:
            query = query.filter(CustomsConsultationSession.is_active == True)

        if broker_id:
            query = query.filter(CustomsConsultationSession.broker_id == broker_id)

        if import_file_id:
            query = query.filter(CustomsConsultationSession.import_file_id == import_file_id)

        if po_id:
            query = query.filter(CustomsConsultationSession.po_id == po_id)

        if project_id:
            query = query.filter(CustomsConsultationSession.project_id == project_id)

        if status:
            query = query.filter(CustomsConsultationSession.overall_status == status)

        if search:
            search_pattern = f"%{search}%"
            query = query.filter(
                (CustomsConsultationSession.consultation_code.ilike(search_pattern))
                | (CustomsConsultationSession.title.ilike(search_pattern))
                | (CustomsConsultationSession.broker_name.ilike(search_pattern))
            )

        return query.order_by(CustomsConsultationSession.consultation_id.desc()).all()

    @staticmethod
    def update(
        db: Session, db_session: CustomsConsultationSession, update_in: CustomsConsultationUpdate
    ) -> CustomsConsultationSession:
        update_data = update_in.model_dump(exclude_unset=True, exclude={"checklist_items"})

        for field, value in update_data.items():
            setattr(db_session, field, value)

        if update_in.checklist_items is not None:
            # Replace checklist items
            db.query(CustomsChecklistItem).filter(
                CustomsChecklistItem.consultation_id == db_session.consultation_id
            ).delete()

            for item_in in update_in.checklist_items:
                db_item = CustomsChecklistItem(
                    consultation_id=db_session.consultation_id,
                    document_type=item_in.document_type,
                    hs_code=item_in.hs_code,
                    is_required=item_in.is_required,
                    is_blocking_shipment=item_in.is_blocking_shipment,
                    responsible_party=item_in.responsible_party,
                    status=item_in.status,
                    received_date=item_in.received_date,
                    verified_date=item_in.verified_date,
                    regulatory_agency=item_in.regulatory_agency,
                    remarks=item_in.remarks,
                    corrective_action_required=item_in.corrective_action_required,
                )
                db.add(db_item)

        db_session.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_session)
        return db_session

    @staticmethod
    def soft_delete(db: Session, db_session: CustomsConsultationSession) -> CustomsConsultationSession:
        db_session.is_active = False
        db_session.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_session)
        return db_session

    @staticmethod
    def restore(db: Session, db_session: CustomsConsultationSession) -> CustomsConsultationSession:
        db_session.is_active = True
        db_session.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_session)
        return db_session
