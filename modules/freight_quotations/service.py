"""
Freight Quotations Calculation & Business Service Engine (BP-008)
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from modules.freight_quotations.model import FreightRFQRequest, FreightQuotationItem
from modules.freight_quotations.schemas import (
    FreightRFQRequestCreate,
    FreightRFQRequestUpdate,
    FreightRFQRequestResponse,
)
from modules.freight_quotations.repository import FreightQuotationRepository
from modules.freight_quotations.validators import validate_carrier_exists, validate_quotation_dates


class FreightQuotationService:

    @staticmethod
    def _compute_rfq_metrics(db: Session, db_rfq: FreightRFQRequest) -> FreightRFQRequestResponse:
        """
        Calculates summary metrics: lowest freight cost, avg freight cost, fastest transit days, avg transit days, awarded provider name.
        """
        quotes = db_rfq.quotations or []
        total_count = len(quotes)

        included_quotes = [q for q in quotes if not q.is_excluded_from_avg]

        lowest_cost = 0.0
        avg_cost = 0.0
        fastest_transit = 0
        avg_transit = 0.0
        awarded_name: Optional[str] = None

        if quotes:
            costs = [q.total_cost for q in quotes]
            lowest_cost = round(min(costs), 2)

            for q in quotes:
                if q.is_awarded or (db_rfq.selected_quotation_id and q.quotation_id == db_rfq.selected_quotation_id):
                    awarded_name = q.provider_name
                    q.is_awarded = True

        if included_quotes:
            inc_costs = [q.total_cost for q in included_quotes]
            avg_cost = round(sum(inc_costs) / len(inc_costs), 2)

            transits = [q.transit_days for q in included_quotes]
            fastest_transit = min(transits)
            avg_transit = round(sum(transits) / len(transits), 1)

        import_file_code = None
        if db_rfq.import_file_id:
            from modules.import_files.model import ImportFile
            imp = db.query(ImportFile).filter(ImportFile.import_file_id == db_rfq.import_file_id).first()
            if imp:
                import_file_code = imp.file_code or imp.custom_file_number

        res = FreightRFQRequestResponse.model_validate(db_rfq)
        res.total_quotations_count = total_count
        res.lowest_freight_cost = lowest_cost
        res.average_freight_cost = avg_cost
        res.fastest_transit_days = fastest_transit
        res.average_transit_days = avg_transit
        res.awarded_provider_name = awarded_name
        res.import_file_code = import_file_code
        return res

    @staticmethod
    def create_rfq(db: Session, rfq_in: FreightRFQRequestCreate) -> FreightRFQRequestResponse:
        for q in rfq_in.quotations:
            validate_carrier_exists(db, q.provider_id)
            validate_quotation_dates(rfq_in.crd_date, q.sailing_date, q.estimated_arrival_date)

        db_rfq = FreightQuotationRepository.create(db, rfq_in)
        return FreightQuotationService._compute_rfq_metrics(db, db_rfq)

    @staticmethod
    def get_rfq(db: Session, rfq_id: int) -> FreightRFQRequestResponse:
        db_rfq = FreightQuotationRepository.get_by_id(db, rfq_id)
        if not db_rfq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Freight RFQ with ID '{rfq_id}' not found.",
            )
        return FreightQuotationService._compute_rfq_metrics(db, db_rfq)

    @staticmethod
    def list_rfqs(
        db: Session,
        include_inactive: bool = False,
        search: Optional[str] = None,
        shipping_method: Optional[str] = None,
        import_file_id: Optional[int] = None,
        po_id: Optional[int] = None,
        project_id: Optional[int] = None,
        status: Optional[str] = None,
    ) -> List[FreightRFQRequestResponse]:
        rfqs = FreightQuotationRepository.get_all(
            db,
            include_inactive=include_inactive,
            search=search,
            shipping_method=shipping_method,
            import_file_id=import_file_id,
            po_id=po_id,
            project_id=project_id,
            status=status,
        )
        return [FreightQuotationService._compute_rfq_metrics(db, r) for r in rfqs]

    @staticmethod
    def update_rfq(
        db: Session, rfq_id: int, update_in: FreightRFQRequestUpdate
    ) -> FreightRFQRequestResponse:
        db_rfq = FreightQuotationRepository.get_by_id(db, rfq_id)
        if not db_rfq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Freight RFQ with ID '{rfq_id}' not found.",
            )

        crd = update_in.crd_date or db_rfq.crd_date
        if update_in.quotations is not None:
            for q in update_in.quotations:
                validate_carrier_exists(db, q.provider_id)
                validate_quotation_dates(crd, q.sailing_date, q.estimated_arrival_date)

        updated_rfq = FreightQuotationRepository.update(db, db_rfq, update_in)
        return FreightQuotationService._compute_rfq_metrics(db, updated_rfq)

    @staticmethod
    def award_quotation(db: Session, rfq_id: int, quotation_id: int) -> FreightRFQRequestResponse:
        """
        Awards a specific carrier quotation, freezes choice, and updates RFQ status to 'Awarded'.
        """
        db_rfq = FreightQuotationRepository.get_by_id(db, rfq_id)
        if not db_rfq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Freight RFQ with ID '{rfq_id}' not found.",
            )

        found_quote = None
        for q in db_rfq.quotations:
            if q.quotation_id == quotation_id:
                q.is_awarded = True
                found_quote = q
            else:
                q.is_awarded = False

        if not found_quote:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Quotation item with ID '{quotation_id}' not found in RFQ '{rfq_id}'.",
            )

        db_rfq.selected_quotation_id = quotation_id
        db_rfq.status = "Awarded"
        db.commit()
        db.refresh(db_rfq)
        return FreightQuotationService._compute_rfq_metrics(db, db_rfq)

    @staticmethod
    def soft_delete_rfq(db: Session, rfq_id: int) -> FreightRFQRequestResponse:
        db_rfq = FreightQuotationRepository.get_by_id(db, rfq_id)
        if not db_rfq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Freight RFQ with ID '{rfq_id}' not found.",
            )
        deleted_rfq = FreightQuotationRepository.soft_delete(db, db_rfq)
        return FreightQuotationService._compute_rfq_metrics(db, deleted_rfq)

    @staticmethod
    def restore_rfq(db: Session, rfq_id: int) -> FreightRFQRequestResponse:
        db_rfq = FreightQuotationRepository.get_by_id(db, rfq_id)
        if not db_rfq:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Freight RFQ with ID '{rfq_id}' not found.",
            )
        restored_rfq = FreightQuotationRepository.restore(db, db_rfq)
        return FreightQuotationService._compute_rfq_metrics(db, restored_rfq)
