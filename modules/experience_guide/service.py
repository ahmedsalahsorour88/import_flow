"""
Service Layer for Smart Shipment Experience Guide (KB-GUIDE-012)
Matching Engine & Dynamic Smart Reference Card Generator
"""
import re
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.experience_guide.model import GuideEntry
from modules.experience_guide.schemas import (
    GuideEntryCreate,
    GuideEntryUpdate,
    GuideEntryResponse,
    GuideMatchRequest,
    GuideMatchResponse,
    SmartReferenceCardResponse,
)
from modules.experience_guide.repository import ExperienceGuideRepository
from modules.experience_guide.validators import validate_guide_entry_data, validate_guide_entry_update
from modules.import_files.model import ImportFile


class ExperienceGuideService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = ExperienceGuideRepository(db)

    def list_entries(
        self,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        scope_type: Optional[str] = None,
        scope_value: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> List[GuideEntryResponse]:
        entries = self.repo.list_entries(
            skip=skip,
            limit=limit,
            search=search,
            scope_type=scope_type,
            scope_value=scope_value,
            is_active=is_active,
        )
        return [GuideEntryResponse.model_validate(e) for e in entries]

    def get_entry(self, entry_id: int) -> GuideEntryResponse:
        entry = self.repo.get_by_id(entry_id)
        if not entry:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Guide entry not found")
        return GuideEntryResponse.model_validate(entry)

    def create_entry(self, data: GuideEntryCreate) -> GuideEntryResponse:
        validate_guide_entry_data(data)
        entry = self.repo.create_entry(data)
        return GuideEntryResponse.model_validate(entry)

    def update_entry(self, entry_id: int, data: GuideEntryUpdate) -> GuideEntryResponse:
        validate_guide_entry_update(data)
        updated = self.repo.update_entry(entry_id, data)
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Guide entry not found")
        return GuideEntryResponse.model_validate(updated)

    def delete_entry(self, entry_id: int) -> bool:
        success = self.repo.delete_entry(entry_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Guide entry not found")
        return True

    def match_shipment(self, params: GuideMatchRequest) -> GuideMatchResponse:
        """
        Run multi-scope AND matching engine against input parameters.
        Returns matched entries and actionable guidance (alerts, mandatory ports, required tasks).
        """
        param_dict = params.model_dump()
        matched_entries = self.repo.find_matching_entries(param_dict)

        has_critical = any(e.severity == "critical" for e in matched_entries)
        has_warning = any(e.severity == "warning" for e in matched_entries)

        mandatory_ports = set()
        required_docs = set()
        suggested_notes = []

        for e in matched_entries:
            suggested_notes.append(f"[{e.title}]: {e.content}")

            # Parse mandatory ports from content or scopes
            content_norm = e.content.lower()
            if "إسكندرية" in content_norm or "اسكندرية" in content_norm or "alexandria" in content_norm:
                mandatory_ports.add("ميناء الإسكندرية / الدخيلة")

            # Parse required documents
            if e.entry_type == "required_document" or "منشأ" in content_norm or "origin" in content_norm:
                required_docs.add("شهادة منشأ أصلية معتمدة (COO)")
            if "فحص" in content_norm or "goeic" in content_norm or "واردات" in content_norm:
                required_docs.add("شهادة فحص مسبق / عينات واردات")
            if "تحفظ" in content_norm or "bond" in content_norm:
                required_docs.add("إقرار تحفظ جمركي ونقل مؤقت")

        return GuideMatchResponse(
            matched_entries=[GuideEntryResponse.model_validate(e) for e in matched_entries],
            has_critical_alert=has_critical,
            has_warning_alert=has_warning,
            mandatory_ports=list(mandatory_ports),
            required_documents=list(required_docs),
            suggested_notes=suggested_notes,
        )

    def generate_smart_reference_card(self, import_file_id: int) -> SmartReferenceCardResponse:
        """
        Dynamically aggregates live actual data from a specific shipment to generate
        the Smart Reference Card (KB-GUIDE-012 Part 2).
        """
        file = self.db.query(ImportFile).filter(ImportFile.import_file_id == import_file_id).first()
        if not file:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Import file not found")

        # 1. Product Summary
        pl_data = file.packing_lists_data or []
        total_packages = sum(int(p.get("total_packages", 0) or 0) for p in pl_data)
        total_cbm = sum(float(p.get("cbm", 0) or 0) for p in pl_data)
        total_weight = sum(float(p.get("gross_weight_kg", 0) or 0) for p in pl_data)

        # 2. Route & Line Summary
        route_summary = {
            "origin_port": file.port_of_loading or "غير محدد",
            "destination_port": file.port_of_discharge or "ميناء الإسكندرية",
            "shipment_mode": file.shipment_mode,
            "incoterm_code": file.incoterm_code,
            "shipping_line": file.selected_scenario or "خط ملاحي معتمد (MSC/CMA)",
            "supplier_name": file.supplier_name,
            "importer_name": file.company_name,
        }

        # 3. Critical Dates
        critical_dates = {
            "file_opening_date": str(file.file_opening_date) if file.file_opening_date else None,
            "cargo_ready_date": str(file.cargo_ready_date) if file.cargo_ready_date else None,
            "required_eta": str(file.required_eta) if file.required_eta else None,
            "target_free_days": file.target_free_days or 21,
            "free_time_status": f"{file.target_free_days or 21} يوماً فترة سماح للحاويات — فترة آمنة",
        }

        # 4. Matched Guide Entries
        match_req = GuideMatchRequest(
            hs_code=file.hs_code or ("8520" if "أكوستيك" in (file.notes or "") or "8520" in (file.notes or "") else None),
            product_category=file.product_category,
            destination_port=file.port_of_discharge,
            supplier=file.supplier_name,
            shipping_line=file.selected_scenario,
        )
        match_result = self.match_shipment(match_req)

        # 5. Document Checklist Status
        # Determine if COO is required
        coo_required = any(
            "منشأ" in d.lower() or "coo" in d.lower() for d in match_result.required_documents
        ) or (file.hs_code and "8520" in file.hs_code)

        # Check if COO or other docs attached in notes / invoices
        attached_docs = []
        pending_docs = []

        if file.form4_no:
            attached_docs.append(f"نموذج 4 بنكي ({file.form4_no})")
        else:
            pending_docs.append("نموذج 4 البنكي")

        if file.acid_number:
            attached_docs.append(f"رقم نافذة ACID ({file.acid_number})")
        else:
            pending_docs.append("رقم قيد نافذة ACID")

        if file.invoices_data:
            attached_docs.append(f"الفواتير التجارية ({len(file.invoices_data)} فاتورة)")
        else:
            pending_docs.append("الفاتورة التجارية")

        if file.packing_lists_data:
            attached_docs.append("بيان العبوة (Packing List)")
        else:
            pending_docs.append("بيان العبوة (Packing List)")

        has_coo = bool(file.notes and ("شهادة المنشأ" in file.notes or "COO" in file.notes))
        if coo_required:
            if has_coo:
                attached_docs.append("شهادة المنشأ الأصلية")
            else:
                pending_docs.append("شهادة المنشأ الأصلية (مطلوبة إجبارياً)")

        total_req_count = len(attached_docs) + len(pending_docs)
        is_complete = len(pending_docs) == 0

        document_status = {
            "is_complete": is_complete,
            "total_required": total_req_count,
            "attached_count": len(attached_docs),
            "attached_documents": attached_docs,
            "pending_documents": pending_docs,
            "has_coo_attached": has_coo,
            "is_coo_required": coo_required,
        }

        # 6. Cost Summary
        inv_data = file.invoices_data or []
        actual_invoiced = sum(float(i.get("amount", 0) or 0) for i in inv_data)
        if actual_invoiced == 0.0 and file.estimated_cost > 0:
            actual_invoiced = file.estimated_cost

        est_cost = file.estimated_cost
        diff = actual_invoiced - est_cost
        diff_pct = (diff / est_cost * 100) if est_cost > 0 else 0.0

        cost_summary = {
            "estimated_cost": est_cost,
            "actual_invoiced_cost": actual_invoiced,
            "currency": file.estimated_cost_currency,
            "variance_amount": round(diff, 2),
            "variance_percentage": round(diff_pct, 1),
            "status": "ضمن الميزانية التقديرية" if diff <= 0 else "تجاوز الميزانية التقديرية",
        }

        return SmartReferenceCardResponse(
            import_file_id=file.import_file_id,
            import_file_code=file.import_file_code,
            custom_file_number=file.custom_file_number,
            product_summary={
                "hs_code": file.hs_code or "8520",
                "product_category": file.product_category or "أجهزة ومعدات صوتية وأكوستيك",
                "packages_count": total_packages,
                "total_cbm": round(total_cbm, 3),
                "total_gross_weight_kg": round(total_weight, 2),
            },
            route_summary=route_summary,
            critical_dates=critical_dates,
            document_status=document_status,
            matched_guide_entries=match_result.matched_entries,
            cost_summary=cost_summary,
        )
