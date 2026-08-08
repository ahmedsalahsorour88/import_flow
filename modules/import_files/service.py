"""
Service Layer for Import Files Master & Tracking Module
"""

from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from modules.import_files.schemas import (
    ImportFileCreate,
    ImportFileUpdate,
    ImportFileResponse,
    ImportMasterReportSummary,
)
from modules.import_files.model import ImportFile
import modules.import_files.repository as repo
import modules.import_files.validators as validators


def compute_file_formulas(
    form46_no: Optional[str] = None,
    form4_no: Optional[str] = None,
    swift_no: Optional[str] = None,
    selected_scenario: Optional[str] = None,
    status_str: str = "Open",
) -> Dict[str, Any]:
    """
    Computes Formula values for Current Module, Current Stage, Progress %, and Next Action.
    """
    if status_str == "Closed" or status_str == "Archived":
        return {
            "current_module": "BP-040 Close Import File & Historical Archive",
            "current_stage": "Phase 10: Import File Closure",
            "progress_percent": 100.0,
            "next_action": "File Fully Closed & Archived",
        }

    if form46_no and form46_no.strip():
        return {
            "current_module": "BP-019 Prepare Customs Declaration 46",
            "current_stage": "Phase 3: Import Documentation & ACI",
            "progress_percent": 65.0,
            "next_action": "Customs Inspection & Duty Settlement (Phase 6/7)",
        }

    if (form4_no and form4_no.strip()) or (swift_no and swift_no.strip()):
        return {
            "current_module": "BP-015 Process Form 4 / Form 9 / L/C",
            "current_stage": "Phase 3: Import Documentation & ACI",
            "progress_percent": 50.0,
            "next_action": "Upload Digital Documents to CargoX & Prepare Declaration 46",
        }

    if selected_scenario and selected_scenario.strip():
        return {
            "current_module": "BP-007 Evaluate Shipping Scenarios",
            "current_stage": "Phase 1: Import Planning & Feasibility",
            "progress_percent": 25.0,
            "next_action": "Create Payment Request (BP-012) & Issue Form 4",
        }

    return {
        "current_module": "BP-001 Receive Purchase Order & Planning",
        "current_stage": "Phase 1: Import Planning & Feasibility",
        "progress_percent": 15.0,
        "next_action": "Evaluate Shipping Scenarios (BP-007) & Request Freight Quotations (BP-008)",
    }


def create_import_file_service(db: Session, payload: ImportFileCreate) -> ImportFile:
    # 1. Validate custom file number uniqueness if provided
    validators.validate_custom_file_number_unique(db, payload.custom_file_number)

    # 2. Validate multi-project ownership rule
    validators.validate_company_project_ownership(db, payload.company_id, payload.project_ids)

    # 3. Generate file code if custom file number not given
    file_code = repo.generate_import_file_code(db)
    if not payload.custom_file_number:
        custom_num = file_code.replace("IMP-", "FILE-")
    else:
        custom_num = payload.custom_file_number.strip()

    # 4. Compute formulas
    formulas = compute_file_formulas(
        form46_no=payload.form46_no,
        form4_no=payload.form4_no,
        swift_no=payload.swift_no,
        selected_scenario=payload.selected_scenario,
        status_str=payload.status,
    )

    data_dict = payload.model_dump()
    data_dict["import_file_code"] = file_code
    data_dict["custom_file_number"] = custom_num
    data_dict.update(formulas)

    return repo.create_import_file(db, data_dict)


def update_import_file_service(
    db: Session, import_file_id: int, payload: ImportFileUpdate
) -> ImportFile:
    existing = repo.get_import_file_by_id(db, import_file_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ملف الاستيراد برقم المعرف {import_file_id} غير موجود.",
        )

    # Validate custom file number if changed
    if payload.custom_file_number:
        validators.validate_custom_file_number_unique(
            db, payload.custom_file_number, current_file_id=import_file_id
        )

    # Validate multi-project ownership
    target_company_id = payload.company_id or existing.company_id
    target_project_ids = payload.project_ids if payload.project_ids is not None else existing.project_ids
    validators.validate_company_project_ownership(db, target_company_id, target_project_ids)

    update_dict = payload.model_dump(exclude_unset=True)

    # Re-compute formulas
    f46 = update_dict.get("form46_no", existing.form46_no)
    f4 = update_dict.get("form4_no", existing.form4_no)
    swift = update_dict.get("swift_no", existing.swift_no)
    scen = update_dict.get("selected_scenario", existing.selected_scenario)
    stat = update_dict.get("status", existing.status)

    formulas = compute_file_formulas(
        form46_no=f46,
        form4_no=f4,
        swift_no=swift,
        selected_scenario=scen,
        status_str=stat,
    )
    update_dict.update(formulas)

    return repo.update_import_file(db, import_file_id, update_dict)


def generate_master_report_service(
    db: Session,
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
    search: Optional[str] = None,
) -> ImportMasterReportSummary:
    files = repo.get_all_import_files(
        db,
        include_inactive=False,
        search=search,
        company_id=company_id,
        supplier_id=supplier_id,
        status=status,
        owner=owner,
    )

    open_files = [f for f in files if f.status == "Open"]
    in_prog = [f for f in files if f.status == "In Progress"]
    closed_files = [f for f in files if f.status in ("Closed", "Archived")]
    total_cost = sum(f.estimated_cost for f in files)

    file_responses = [ImportFileResponse.model_validate(f) for f in files]

    return ImportMasterReportSummary(
        total_import_files=len(files),
        open_files_count=len(open_files),
        in_progress_count=len(in_prog),
        closed_files_count=len(closed_files),
        total_estimated_cost=total_cost,
        files=file_responses,
    )
