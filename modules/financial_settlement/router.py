from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from database.database import get_db
from .schemas import (
    FinancialSettlementCreate,
    FinancialSettlementUpdate,
    FinancialSettlementResponse,
    OdooJournalEntryResponse,
    OdooExportConfig,
)
from .service import (
    create_settlement_service,
    recalculate_settlement_service,
    update_settlement_service,
    get_settlement_service,
    list_settlements_service,
    soft_delete_settlement_service,
    restore_settlement_service,
)
from .odoo_export_service import (
    generate_odoo_journal_entry_service,
    export_odoo_csv_service,
    export_odoo_excel_service,
)

router = APIRouter(prefix="/api/v1/financial-settlement", tags=["Phase 9 - Financial Settlement & Landed Cost"])

@router.get("", response_model=List[FinancialSettlementResponse])
def list_settlements(
    include_inactive: bool = Query(False, description="Include soft-deleted records"),
    import_file_id: Optional[int] = Query(None, description="Filter by import file ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by operational status"),
    search: Optional[str] = Query(None, description="Search term"),
    db: Session = Depends(get_db),
):
    return list_settlements_service(db, include_inactive, import_file_id, status_filter, search)

@router.post("", response_model=FinancialSettlementResponse, status_code=status.HTTP_201_CREATED)
def create_settlement(
    schema: FinancialSettlementCreate,
    db: Session = Depends(get_db),
):
    return create_settlement_service(db, schema)

@router.get("/{settlement_id}", response_model=FinancialSettlementResponse)
def get_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    return get_settlement_service(db, settlement_id)

@router.put("/{settlement_id}", response_model=FinancialSettlementResponse)
def update_settlement(
    settlement_id: int,
    schema: FinancialSettlementUpdate,
    db: Session = Depends(get_db),
):
    return update_settlement_service(db, settlement_id, schema)

@router.post("/{settlement_id}/recalculate", response_model=FinancialSettlementResponse)
def recalculate_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    return recalculate_settlement_service(db, settlement_id)

@router.delete("/{settlement_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    soft_delete_settlement_service(db, settlement_id)
    return None

@router.patch("/{settlement_id}/restore", response_model=FinancialSettlementResponse)
def restore_settlement(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    return restore_settlement_service(db, settlement_id)

@router.get("/{settlement_id}/odoo-journal-entry", response_model=OdooJournalEntryResponse)
def get_odoo_journal_entry(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    """
    Returns balanced double-entry accounting journal for Odoo and ERP General Ledger.
    """
    return generate_odoo_journal_entry_service(db, settlement_id)

@router.get("/{settlement_id}/export-odoo-csv")
def export_odoo_csv(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    """
    Exports Odoo-compatible CSV file for account.move / account.move.line batch import.
    """
    csv_data = export_odoo_csv_service(db, settlement_id)
    filename = f"odoo_landed_cost_settlement_{settlement_id}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )

@router.get("/{settlement_id}/export-odoo-excel")
def export_odoo_excel(
    settlement_id: int,
    db: Session = Depends(get_db),
):
    """
    Exports full professional Excel file containing Odoo import sheet, Accounting Voucher, and Item Landed Cost breakdown.
    """
    excel_bytes = export_odoo_excel_service(db, settlement_id)
    filename = f"accounting_landed_cost_voucher_{settlement_id}.xlsx"
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
