from typing import List, Optional
from sqlalchemy.orm import Session
from .model import ContainerSpecModel, ContainerLoaderSessionModel
from .container_specs import ContainerSpec, STANDARD_CONTAINERS


def get_all_container_specs(db: Session) -> List[ContainerSpec]:
    """
    Returns active container specifications from database if present,
    otherwise returns standard defaults.
    """
    db_specs = db.query(ContainerSpecModel).filter(ContainerSpecModel.is_active == True).all()
    if not db_specs:
        return STANDARD_CONTAINERS

    specs: List[ContainerSpec] = []
    for s in db_specs:
        specs.append(
            ContainerSpec(
                code=s.code,
                name=s.name,
                internal_length=s.internal_length,
                internal_width=s.internal_width,
                internal_height=s.internal_height,
                door_width=s.door_width,
                door_height=s.door_height,
                max_payload=s.max_payload,
            )
        )
    return specs


def save_loader_session(db: Session, session_data: dict) -> ContainerLoaderSessionModel:
    session_obj = ContainerLoaderSessionModel(**session_data)
    db.add(session_obj)
    db.commit()
    db.refresh(session_obj)
    return session_obj
