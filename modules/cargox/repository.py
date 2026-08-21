"""
CargoX & ACI Dispatch Hub Repository Layer (CGX-001)
"""

from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import select, func, or_
from sqlalchemy.orm import Session
from .model import CargoXEnvelope, CargoXEnvelopeDocument


class CargoXRepository:

    @staticmethod
    def get_by_id(db: Session, envelope_id: int, include_inactive: bool = False) -> Optional[CargoXEnvelope]:
        query = select(CargoXEnvelope).where(CargoXEnvelope.envelope_id == envelope_id)
        if not include_inactive:
            query = query.where(CargoXEnvelope.is_active.is_(True))
        return db.execute(query).scalar_one_or_none()

    @staticmethod
    def get_by_code(db: Session, envelope_code: str) -> Optional[CargoXEnvelope]:
        query = select(CargoXEnvelope).where(CargoXEnvelope.envelope_code == envelope_code)
        return db.execute(query).scalar_one_or_none()

    @staticmethod
    def get_by_import_file(db: Session, import_file_id: int) -> Optional[CargoXEnvelope]:
        query = (
            select(CargoXEnvelope)
            .where(CargoXEnvelope.import_file_id == import_file_id, CargoXEnvelope.is_active.is_(True))
            .order_by(CargoXEnvelope.envelope_id.desc())
        )
        return db.execute(query).scalars().first()

    @staticmethod
    def get_all(
        db: Session,
        search: Optional[str] = None,
        status: Optional[str] = None,
        import_file_id: Optional[int] = None,
        supplier_id: Optional[int] = None,
        include_inactive: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> List[CargoXEnvelope]:
        query = select(CargoXEnvelope)
        if not include_inactive:
            query = query.where(CargoXEnvelope.is_active.is_(True))

        if import_file_id:
            query = query.where(CargoXEnvelope.import_file_id == import_file_id)

        if supplier_id:
            query = query.where(CargoXEnvelope.supplier_id == supplier_id)

        if status and status != "All":
            query = query.where(CargoXEnvelope.status == status)

        if search:
            s = f"%{search.strip().lower()}%"
            query = query.where(
                or_(
                    func.lower(CargoXEnvelope.envelope_code).like(s),
                    func.lower(CargoXEnvelope.acid_number).like(s),
                    func.lower(CargoXEnvelope.importer_company_name).like(s),
                    func.lower(CargoXEnvelope.supplier_name).like(s),
                    func.lower(CargoXEnvelope.supplier_cargox_id).like(s),
                    func.lower(CargoXEnvelope.bl_number).like(s),
                    func.lower(CargoXEnvelope.import_file_code).like(s),
                )
            )

        query = query.order_by(CargoXEnvelope.envelope_id.desc()).limit(limit).offset(offset)
        return list(db.execute(query).scalars().all())

    @staticmethod
    def count(
        db: Session,
        status: Optional[str] = None,
        include_inactive: bool = False,
    ) -> int:
        query = select(func.count(CargoXEnvelope.envelope_id))
        if not include_inactive:
            query = query.where(CargoXEnvelope.is_active.is_(True))
        if status and status != "All":
            query = query.where(CargoXEnvelope.status == status)
        return db.execute(query).scalar_one()

    @staticmethod
    def get_next_code(db: Session) -> str:
        current_year = datetime.now(timezone.utc).year
        prefix = f"CGX-ENV-{current_year}-"
        query = (
            select(CargoXEnvelope.envelope_code)
            .where(CargoXEnvelope.envelope_code.like(f"{prefix}%"))
            .order_by(CargoXEnvelope.envelope_id.desc())
        )
        last_code = db.execute(query).scalars().first()
        if last_code:
            try:
                last_num = int(last_code.split("-")[-1])
                return f"{prefix}{str(last_num + 1).zfill(4)}"
            except Exception:
                pass
        return f"{prefix}0001"

    @staticmethod
    def create(db: Session, envelope: CargoXEnvelope) -> CargoXEnvelope:
        db.add(envelope)
        db.commit()
        db.refresh(envelope)
        return envelope

    @staticmethod
    def update(db: Session, envelope: CargoXEnvelope) -> CargoXEnvelope:
        envelope.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(envelope)
        return envelope

    @staticmethod
    def soft_delete(db: Session, envelope: CargoXEnvelope, deleted_by: str = "SYSTEM") -> CargoXEnvelope:
        envelope.is_active = False
        envelope.updated_by = deleted_by
        envelope.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(envelope)
        return envelope

    @staticmethod
    def restore(db: Session, envelope: CargoXEnvelope, restored_by: str = "SYSTEM") -> CargoXEnvelope:
        envelope.is_active = True
        envelope.updated_by = restored_by
        envelope.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(envelope)
        return envelope


class CargoXStandardInvoiceRepository:

    @staticmethod
    def get_by_id(db: Session, session_id: int, include_inactive: bool = False) -> Optional["CargoXStandardInvoiceReviewSession"]:
        from .model import CargoXStandardInvoiceReviewSession
        query = select(CargoXStandardInvoiceReviewSession).where(CargoXStandardInvoiceReviewSession.session_id == session_id)
        if not include_inactive:
            query = query.where(CargoXStandardInvoiceReviewSession.is_active.is_(True))
        return db.execute(query).scalar_one_or_none()

    @staticmethod
    def get_by_import_file(db: Session, import_file_id: int) -> Optional["CargoXStandardInvoiceReviewSession"]:
        from .model import CargoXStandardInvoiceReviewSession
        query = (
            select(CargoXStandardInvoiceReviewSession)
            .where(
                CargoXStandardInvoiceReviewSession.import_file_id == import_file_id,
                CargoXStandardInvoiceReviewSession.is_active.is_(True),
            )
            .order_by(CargoXStandardInvoiceReviewSession.session_id.desc())
        )
        return db.execute(query).scalars().first()

    @staticmethod
    def get_all(
        db: Session,
        search: Optional[str] = None,
        status: Optional[str] = None,
        import_file_id: Optional[int] = None,
        include_inactive: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> List["CargoXStandardInvoiceReviewSession"]:
        from .model import CargoXStandardInvoiceReviewSession
        query = select(CargoXStandardInvoiceReviewSession)
        if not include_inactive:
            query = query.where(CargoXStandardInvoiceReviewSession.is_active.is_(True))
        if import_file_id:
            query = query.where(CargoXStandardInvoiceReviewSession.import_file_id == import_file_id)
        if status and status != "All":
            query = query.where(CargoXStandardInvoiceReviewSession.status == status)
        if search:
            s = f"%{search.strip().lower()}%"
            query = query.where(
                or_(
                    func.lower(CargoXStandardInvoiceReviewSession.session_code).like(s),
                    func.lower(CargoXStandardInvoiceReviewSession.acid_number).like(s),
                    func.lower(CargoXStandardInvoiceReviewSession.invoice_number).like(s),
                    func.lower(CargoXStandardInvoiceReviewSession.exporter_name).like(s),
                    func.lower(CargoXStandardInvoiceReviewSession.importer_name).like(s),
                    func.lower(CargoXStandardInvoiceReviewSession.import_file_code).like(s),
                )
            )
        query = query.order_by(CargoXStandardInvoiceReviewSession.session_id.desc()).limit(limit).offset(offset)
        return list(db.execute(query).scalars().all())

    @staticmethod
    def get_next_code(db: Session) -> str:
        from .model import CargoXStandardInvoiceReviewSession
        current_year = datetime.now(timezone.utc).year
        prefix = f"CX-INV-{current_year}-"
        query = (
            select(CargoXStandardInvoiceReviewSession.session_code)
            .where(CargoXStandardInvoiceReviewSession.session_code.like(f"{prefix}%"))
            .order_by(CargoXStandardInvoiceReviewSession.session_id.desc())
        )
        last_code = db.execute(query).scalars().first()
        if last_code:
            try:
                last_num = int(last_code.split("-")[-1])
                return f"{prefix}{str(last_num + 1).zfill(4)}"
            except Exception:
                pass
        return f"{prefix}0001"

    @staticmethod
    def create(db: Session, session: "CargoXStandardInvoiceReviewSession") -> "CargoXStandardInvoiceReviewSession":
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def update(db: Session, session: "CargoXStandardInvoiceReviewSession") -> "CargoXStandardInvoiceReviewSession":
        session.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(session)
        return session

