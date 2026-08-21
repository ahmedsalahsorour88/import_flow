from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc, or_

from .model import OriginalDocumentsCollectionSession


class OriginalDocumentsCollectionRepository:
    @staticmethod
    def get_next_collection_code(db: Session) -> str:
        current_year = datetime.now(timezone.utc).year
        prefix = f"DOC-COL-{current_year}-"

        latest_session = (
            db.query(OriginalDocumentsCollectionSession)
            .filter(OriginalDocumentsCollectionSession.collection_code.like(f"{prefix}%"))
            .order_by(desc(OriginalDocumentsCollectionSession.collection_id))
            .first()
        )

        if not latest_session:
            return f"{prefix}0001"

        try:
            seq_part = latest_session.collection_code.replace(prefix, "")
            seq_num = int(seq_part) + 1
            return f"{prefix}{seq_num:04d}"
        except Exception:
            return f"{prefix}0001"

    @staticmethod
    def create(db: Session, session: OriginalDocumentsCollectionSession) -> OriginalDocumentsCollectionSession:
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def get_by_id(db: Session, collection_id: int) -> Optional[OriginalDocumentsCollectionSession]:
        return (
            db.query(OriginalDocumentsCollectionSession)
            .filter(OriginalDocumentsCollectionSession.collection_id == collection_id)
            .first()
        )

    @staticmethod
    def get_by_import_file(db: Session, import_file_id: int) -> Optional[OriginalDocumentsCollectionSession]:
        return (
            db.query(OriginalDocumentsCollectionSession)
            .filter(
                OriginalDocumentsCollectionSession.import_file_id == import_file_id,
                OriginalDocumentsCollectionSession.is_active == True,
            )
            .first()
        )

    @staticmethod
    def get_all(
        db: Session,
        include_inactive: bool = False,
        status: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> List[OriginalDocumentsCollectionSession]:
        query = db.query(OriginalDocumentsCollectionSession)
        if not include_inactive:
            query = query.filter(OriginalDocumentsCollectionSession.is_active == True)

        if status and status != "All":
            query = query.filter(OriginalDocumentsCollectionSession.status == status)

        if search:
            search_pattern = f"%{search}%"
            query = query.filter(
                or_(
                    OriginalDocumentsCollectionSession.collection_code.ilike(search_pattern),
                    OriginalDocumentsCollectionSession.import_file_code.ilike(search_pattern),
                    OriginalDocumentsCollectionSession.acid_number.ilike(search_pattern),
                    OriginalDocumentsCollectionSession.importer_name.ilike(search_pattern),
                    OriginalDocumentsCollectionSession.supplier_name.ilike(search_pattern),
                )
            )

        return (
            query.order_by(desc(OriginalDocumentsCollectionSession.updated_at))
            .offset(offset)
            .limit(limit)
            .all()
        )

    @staticmethod
    def update(
        db: Session,
        session: OriginalDocumentsCollectionSession,
        updates: dict,
    ) -> OriginalDocumentsCollectionSession:
        for key, value in updates.items():
            if hasattr(session, key):
                setattr(session, key, value)

        session.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def soft_delete(db: Session, collection_id: int) -> bool:
        session = db.query(OriginalDocumentsCollectionSession).filter_by(collection_id=collection_id).first()
        if not session:
            return False
        session.is_active = False
        session.updated_at = datetime.now(timezone.utc)
        db.commit()
        return True
