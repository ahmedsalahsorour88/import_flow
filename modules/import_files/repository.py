"""
Repository Layer for Import Files Master & Tracking Module
"""

from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import or_

from modules.import_files.model import ImportFile


def generate_import_file_code(db: Session) -> str:
    """Generates unique import file code: IMP-YYYY-XXXX"""
    current_year = datetime.utcnow().year
    prefix = f"IMP-{current_year}-"
    count = db.query(ImportFile).filter(ImportFile.import_file_code.like(f"{prefix}%")).count()
    return f"{prefix}{count + 1:04d}"


def get_all_import_files(
    db: Session,
    include_inactive: bool = False,
    search: Optional[str] = None,
    company_id: Optional[int] = None,
    supplier_id: Optional[int] = None,
    status: Optional[str] = None,
    owner: Optional[str] = None,
) -> List[ImportFile]:
    query = db.query(ImportFile)
    if not include_inactive:
        query = query.filter(ImportFile.is_active == True)

    if company_id:
        query = query.filter(ImportFile.company_id == company_id)
    if supplier_id:
        query = query.filter(ImportFile.supplier_id == supplier_id)
    if status and status != "All":
        query = query.filter(ImportFile.status == status)
    if owner and owner != "All":
        query = query.filter(ImportFile.owner == owner)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                ImportFile.import_file_code.ilike(term),
                ImportFile.custom_file_number.ilike(term),
                ImportFile.company_name.ilike(term),
                ImportFile.supplier_name.ilike(term),
                ImportFile.po_number.ilike(term),
                ImportFile.pi_number.ilike(term),
                ImportFile.owner.ilike(term),
            )
        )

    return query.order_by(ImportFile.import_file_id.desc()).all()


def get_import_file_by_id(db: Session, import_file_id: int) -> Optional[ImportFile]:
    return db.query(ImportFile).filter(
        ImportFile.import_file_id == import_file_id,
        ImportFile.is_active == True
    ).first()


def get_import_file_by_code(db: Session, code_or_custom_num: str) -> Optional[ImportFile]:
    return db.query(ImportFile).filter(
        or_(
            ImportFile.import_file_code == code_or_custom_num,
            ImportFile.custom_file_number == code_or_custom_num,
        ),
        ImportFile.is_active == True
    ).first()


def create_import_file(db: Session, obj_data: dict) -> ImportFile:
    db_obj = ImportFile(**obj_data)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def update_import_file(db: Session, import_file_id: int, update_data: dict) -> Optional[ImportFile]:
    db_obj = get_import_file_by_id(db, import_file_id)
    if not db_obj:
        return None

    for key, value in update_data.items():
        if hasattr(db_obj, key):
            setattr(db_obj, key, value)

    db_obj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_obj)
    return db_obj


def soft_delete_import_file(db: Session, import_file_id: int) -> bool:
    db_obj = get_import_file_by_id(db, import_file_id)
    if not db_obj:
        return False

    db_obj.is_active = False
    db_obj.updated_at = datetime.utcnow()
    db.commit()
    return True


def get_operational_dashboard_data(
    db: Session,
    phase: Optional[str] = None,
    priority: Optional[str] = None,
    broker_id: Optional[int] = None,
    broker_name: Optional[str] = None,
    search: Optional[str] = None,
):
    """
    Fetches operational dashboard shipments matching phase, priority, broker, and search
    using strict AND combination logic. Returns shipment count, list, phase counts, and dynamic brokers.
    """
    query = db.query(ImportFile).filter(ImportFile.is_active == True)

    # 1. Phase Filter
    if phase and phase != "All":
        phase_str = str(phase).strip()
        query = query.filter(
            or_(
                ImportFile.current_module.ilike(f"%{phase_str}%"),
                ImportFile.current_stage.ilike(f"%{phase_str}%"),
            )
        )

    # 2. Priority Filter
    if priority and priority != "All":
        query = query.filter(ImportFile.priority == priority)

    # 3. Customs Broker Filter
    if broker_id:
        query = query.filter(ImportFile.broker_id == broker_id)
    elif broker_name and broker_name != "All":
        query = query.filter(ImportFile.broker_name == broker_name)

    # 4. Search Filter
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                ImportFile.import_file_code.ilike(term),
                ImportFile.custom_file_number.ilike(term),
                ImportFile.company_name.ilike(term),
                ImportFile.supplier_name.ilike(term),
                ImportFile.po_number.ilike(term),
                ImportFile.broker_name.ilike(term),
            )
        )

    shipments = query.order_by(ImportFile.import_file_id.desc()).all()
    shipment_count = len(shipments)

    # Calculate Phase distribution across all active files
    all_active = db.query(ImportFile).filter(ImportFile.is_active == True).all()
    phase_counts = {f"Phase {i}": 0 for i in range(1, 11)}
    for file in all_active:
        stage_text = f"{file.current_module} {file.current_stage}"
        for i in range(1, 11):
            if f"Phase {i}" in stage_text:
                phase_counts[f"Phase {i}"] += 1

    # Dynamic Brokers List from Database
    brokers_query = db.query(ImportFile.broker_id, ImportFile.broker_name).filter(
        ImportFile.is_active == True,
        ImportFile.broker_name.isnot(None),
        ImportFile.broker_name != "",
    ).distinct().all()

    from modules.external_service_providers.model import ExternalServiceProvider
    ext_brokers = db.query(ExternalServiceProvider).filter(
        ExternalServiceProvider.is_active == True,
        ExternalServiceProvider.provider_type == "Customs Broker",
    ).all()

    broker_dict = {}
    for p in ext_brokers:
        broker_dict[p.provider_name] = p.provider_id
    for b_id, b_name in brokers_query:
        if b_name and b_name not in broker_dict:
            broker_dict[b_name] = b_id

    available_brokers = [
        {"broker_id": v, "broker_name": k} for k, v in broker_dict.items()
    ]

    return {
        "shipment_count": shipment_count,
        "shipments": shipments,
        "last_updated_at": datetime.utcnow(),
        "available_brokers": available_brokers,
        "phase_counts": phase_counts,
    }

