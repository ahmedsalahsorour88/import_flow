import json
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session
from .model import AuditLog
from .schemas import AuditLogResponse


class AuditLogService:
    def __init__(self, db: Session):
        self.db = db

    def log_activity(
        self,
        entity_type: str,
        entity_id: int,
        action: str,
        entity_code: Optional[str] = None,
        old_data: Optional[Dict[str, Any]] = None,
        new_data: Optional[Dict[str, Any]] = None,
        performed_by: str = "System Admin"
    ) -> AuditLog:
        changes = []
        old_json = json.dumps(old_data, default=str) if old_data else None
        new_json = json.dumps(new_data, default=str) if new_data else None

        if action == "CREATE":
            changes_summary = f"Created new {entity_type} record"
        elif action == "DELETE":
            changes_summary = f"Deactivated {entity_type} record"
        elif action == "RESTORE":
            changes_summary = f"Reactivated {entity_type} record"
        elif action == "UPDATE" and old_data and new_data:
            for key, new_val in new_data.items():
                if key in old_data and old_data[key] != new_val:
                    changes.append(f"{key}: '{old_data[key]}' -> '{new_val}'")
            changes_summary = "Updated fields: " + (", ".join(changes) if changes else "No field values changed")
        else:
            changes_summary = f"Performed {action} on {entity_type}"

        log_obj = AuditLog(
            entity_type=entity_type,
            entity_id=entity_id,
            entity_code=entity_code,
            action=action,
            changes_summary=changes_summary,
            old_values=old_json,
            new_values=new_json,
            performed_by=performed_by,
        )
        self.db.add(log_obj)
        self.db.commit()
        self.db.refresh(log_obj)
        return log_obj

    def get_logs_for_entity(self, entity_type: str, entity_id: int) -> List[AuditLogResponse]:
        return self.db.query(AuditLog).filter(
            AuditLog.entity_type == entity_type,
            AuditLog.entity_id == entity_id
        ).order_by(AuditLog.log_id.desc()).all()

    def get_all_logs(self, limit: int = 100) -> List[AuditLogResponse]:
        return self.db.query(AuditLog).order_by(AuditLog.log_id.desc()).limit(limit).all()
