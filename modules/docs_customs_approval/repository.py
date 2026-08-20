"""
Database Repository for Docs Customs Approval Hub (DCA-001)
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc

from modules.docs_customs_approval.model import (
    CustomsDocumentApproval,
    DiscrepancyRectificationTicket,
)


# --- Approval Queries ---

def get_approval_by_id(db: Session, approval_id: int) -> Optional[CustomsDocumentApproval]:
    return db.query(CustomsDocumentApproval).filter(
        CustomsDocumentApproval.approval_id == approval_id,
        CustomsDocumentApproval.is_active == True
    ).first()


def get_approval_by_code(db: Session, approval_code: str) -> Optional[CustomsDocumentApproval]:
    return db.query(CustomsDocumentApproval).filter(
        CustomsDocumentApproval.approval_code == approval_code,
        CustomsDocumentApproval.is_active == True
    ).first()


def list_approvals(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    document_type: Optional[str] = None,
    overall_status: Optional[str] = None,
    search: Optional[str] = None,
) -> List[CustomsDocumentApproval]:
    query = db.query(CustomsDocumentApproval)
    if not include_inactive:
        query = query.filter(CustomsDocumentApproval.is_active == True)
    if import_file_id is not None:
        query = query.filter(CustomsDocumentApproval.import_file_id == import_file_id)
    if document_type:
        query = query.filter(CustomsDocumentApproval.document_type == document_type)
    if overall_status and overall_status != "All":
        query = query.filter(CustomsDocumentApproval.overall_status == overall_status)
    if search:
        s = f"%{search}%"
        query = query.filter(
            or_(
                CustomsDocumentApproval.approval_code.ilike(s),
                CustomsDocumentApproval.document_reference_no.ilike(s),
                CustomsDocumentApproval.import_file_code.ilike(s),
                CustomsDocumentApproval.customs_broker_name.ilike(s),
            )
        )
    return query.order_by(desc(CustomsDocumentApproval.approval_id)).all()


def create_approval(db: Session, approval: CustomsDocumentApproval) -> CustomsDocumentApproval:
    db.add(approval)
    db.commit()
    db.refresh(approval)
    return approval


def update_approval(db: Session, approval: CustomsDocumentApproval) -> CustomsDocumentApproval:
    db.commit()
    db.refresh(approval)
    return approval


def soft_delete_approval(db: Session, approval_id: int) -> bool:
    approval = db.query(CustomsDocumentApproval).filter(CustomsDocumentApproval.approval_id == approval_id).first()
    if not approval:
        return False
    approval.is_active = False
    db.commit()
    return True


# --- Discrepancy Ticket Queries ---

def get_ticket_by_id(db: Session, ticket_id: int) -> Optional[DiscrepancyRectificationTicket]:
    return db.query(DiscrepancyRectificationTicket).filter(
        DiscrepancyRectificationTicket.ticket_id == ticket_id,
        DiscrepancyRectificationTicket.is_active == True
    ).first()


def list_tickets(
    db: Session,
    include_inactive: bool = False,
    import_file_id: Optional[int] = None,
    approval_id: Optional[int] = None,
    status: Optional[str] = None,
    severity: Optional[str] = None,
    search: Optional[str] = None,
) -> List[DiscrepancyRectificationTicket]:
    query = db.query(DiscrepancyRectificationTicket)
    if not include_inactive:
        query = query.filter(DiscrepancyRectificationTicket.is_active == True)
    if import_file_id is not None:
        query = query.filter(DiscrepancyRectificationTicket.import_file_id == import_file_id)
    if approval_id is not None:
        query = query.filter(DiscrepancyRectificationTicket.approval_id == approval_id)
    if status and status != "All":
        query = query.filter(DiscrepancyRectificationTicket.status == status)
    if severity and severity != "All":
        query = query.filter(DiscrepancyRectificationTicket.severity == severity)
    if search:
        s = f"%{search}%"
        query = query.filter(
            or_(
                DiscrepancyRectificationTicket.ticket_code.ilike(s),
                DiscrepancyRectificationTicket.description.ilike(s),
                DiscrepancyRectificationTicket.issue_category.ilike(s),
            )
        )
    return query.order_by(desc(DiscrepancyRectificationTicket.ticket_id)).all()


def create_ticket(db: Session, ticket: DiscrepancyRectificationTicket) -> DiscrepancyRectificationTicket:
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket


def update_ticket(db: Session, ticket: DiscrepancyRectificationTicket) -> DiscrepancyRectificationTicket:
    db.commit()
    db.refresh(ticket)
    return ticket
