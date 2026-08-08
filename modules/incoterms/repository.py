from typing import List, Optional

from sqlalchemy.orm import Session

from .model import CostItem, Incoterm, IncotermResponsibility


# ==================================================
# Incoterm Repository (MD-006)
# ==================================================

def get_incoterm_by_id(db: Session, incoterm_id: int) -> Optional[Incoterm]:
    return db.query(Incoterm).filter(Incoterm.incoterm_id == incoterm_id).first()


def get_incoterm_by_code(db: Session, incoterm_code: str) -> Optional[Incoterm]:
    return db.query(Incoterm).filter(Incoterm.incoterm_code == incoterm_code.upper()).first()


def get_all_incoterms(db: Session, include_inactive: bool = False) -> List[Incoterm]:
    query = db.query(Incoterm)
    if not include_inactive:
        query = query.filter(Incoterm.is_active == True)
    return query.order_by(Incoterm.incoterm_code).all()


def create_incoterm(db: Session, data: dict) -> Incoterm:
    incoterm = Incoterm(**data)
    db.add(incoterm)
    db.commit()
    db.refresh(incoterm)
    return incoterm


def update_incoterm(db: Session, incoterm_id: int, data: dict) -> Optional[Incoterm]:
    incoterm = get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        return None
    for key, value in data.items():
        setattr(incoterm, key, value)
    db.commit()
    db.refresh(incoterm)
    return incoterm


def toggle_incoterm_active(db: Session, incoterm_id: int, is_active: bool) -> Optional[Incoterm]:
    incoterm = get_incoterm_by_id(db, incoterm_id)
    if not incoterm:
        return None
    incoterm.is_active = is_active
    db.commit()
    db.refresh(incoterm)
    return incoterm


# ==================================================
# Cost Item Repository (MD-006A)
# ==================================================

def get_cost_item_by_id(db: Session, cost_item_id: int) -> Optional[CostItem]:
    return db.query(CostItem).filter(CostItem.cost_item_id == cost_item_id).first()


def get_cost_item_by_code(db: Session, cost_item_code: str) -> Optional[CostItem]:
    return db.query(CostItem).filter(CostItem.cost_item_code == cost_item_code.upper()).first()


def get_all_cost_items(db: Session, include_inactive: bool = False) -> List[CostItem]:
    query = db.query(CostItem)
    if not include_inactive:
        query = query.filter(CostItem.is_active == True)
    return query.order_by(CostItem.cost_category, CostItem.cost_item_code).all()


def create_cost_item(db: Session, data: dict) -> CostItem:
    item = CostItem(**data)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_cost_item(db: Session, cost_item_id: int, data: dict) -> Optional[CostItem]:
    item = get_cost_item_by_id(db, cost_item_id)
    if not item:
        return None
    for key, value in data.items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


def toggle_cost_item_active(db: Session, cost_item_id: int, is_active: bool) -> Optional[CostItem]:
    item = get_cost_item_by_id(db, cost_item_id)
    if not item:
        return None
    item.is_active = is_active
    db.commit()
    db.refresh(item)
    return item


# ==================================================
# Incoterm Responsibility Repository (MD-006B)
# ==================================================

def get_responsibility_by_id(db: Session, responsibility_id: int) -> Optional[IncotermResponsibility]:
    return db.query(IncotermResponsibility).filter(
        IncotermResponsibility.responsibility_id == responsibility_id
    ).first()


def get_responsibility_by_pair(
    db: Session, incoterm_id: int, cost_item_id: int
) -> Optional[IncotermResponsibility]:
    return db.query(IncotermResponsibility).filter(
        IncotermResponsibility.incoterm_id == incoterm_id,
        IncotermResponsibility.cost_item_id == cost_item_id,
    ).first()


def get_all_responsibilities(db: Session) -> List[IncotermResponsibility]:
    return db.query(IncotermResponsibility).all()


def get_matrix_for_incoterm(db: Session, incoterm_id: int) -> List[IncotermResponsibility]:
    return db.query(IncotermResponsibility).filter(
        IncotermResponsibility.incoterm_id == incoterm_id
    ).all()


def create_responsibility(db: Session, data: dict) -> IncotermResponsibility:
    responsibility = IncotermResponsibility(**data)
    db.add(responsibility)
    db.commit()
    db.refresh(responsibility)
    return responsibility


def update_responsibility(
    db: Session, responsibility_id: int, data: dict
) -> Optional[IncotermResponsibility]:
    responsibility = get_responsibility_by_id(db, responsibility_id)
    if not responsibility:
        return None
    for key, value in data.items():
        setattr(responsibility, key, value)
    db.commit()
    db.refresh(responsibility)
    return responsibility


def delete_responsibility(db: Session, responsibility_id: int) -> Optional[IncotermResponsibility]:
    responsibility = get_responsibility_by_id(db, responsibility_id)
    if not responsibility:
        return None
    db.delete(responsibility)
    db.commit()
    return responsibility
