from datetime import datetime, timezone, date
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_
from .model import FreightIndexSnapshot, DemurrageRule, PortDemurrageTariff, ExternalApiQuotaLog


class FreightDataRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- SFX Freight Snapshots ---
    def get_latest_snapshots(self) -> List[FreightIndexSnapshot]:
        # Subquery for latest snapshot date
        latest_date = self.db.query(FreightIndexSnapshot.snapshot_date).order_by(
            desc(FreightIndexSnapshot.snapshot_date)
        ).first()
        if not latest_date:
            return []
        return self.db.query(FreightIndexSnapshot).filter(
            FreightIndexSnapshot.snapshot_date == latest_date[0]
        ).all()

    def get_snapshot_by_route(self, route_query: str) -> Optional[FreightIndexSnapshot]:
        return self.db.query(FreightIndexSnapshot).filter(
            FreightIndexSnapshot.route_name.ilike(f"%{route_query}%")
        ).order_by(desc(FreightIndexSnapshot.snapshot_date)).first()

    def add_snapshots(self, snapshots: List[FreightIndexSnapshot]) -> int:
        self.db.add_all(snapshots)
        self.db.commit()
        return len(snapshots)

    # --- Demurrage Rules ---
    def get_demurrage_rules(self, shipping_line: Optional[str] = None) -> List[DemurrageRule]:
        query = self.db.query(DemurrageRule).filter(DemurrageRule.is_active == True)
        if shipping_line:
            query = query.filter(DemurrageRule.shipping_line.ilike(shipping_line))
        return query.all()

    def get_demurrage_rule(self, shipping_line: str, container_type: str) -> Optional[DemurrageRule]:
        # Match container type fuzzily (e.g. 40HC vs 40ft vs 40HQ)
        line = shipping_line.lower().strip()
        ctype = container_type.upper().strip()
        return self.db.query(DemurrageRule).filter(
            DemurrageRule.shipping_line.ilike(line),
            DemurrageRule.is_active == True,
            or_(
                DemurrageRule.container_type == ctype,
                DemurrageRule.container_type.ilike(f"%{ctype[:2]}%")
            )
        ).first()

    def upsert_demurrage_rule(self, rule: DemurrageRule) -> DemurrageRule:
        existing = self.db.query(DemurrageRule).filter(
            DemurrageRule.shipping_line.ilike(rule.shipping_line),
            DemurrageRule.container_type == rule.container_type
        ).first()
        if existing:
            existing.default_free_days = rule.default_free_days
            existing.rate_slabs = rule.rate_slabs
            existing.last_synced_at = datetime.now(timezone.utc)
            existing.is_active = True
            self.db.commit()
            self.db.refresh(existing)
            return existing
        else:
            self.db.add(rule)
            self.db.commit()
            self.db.refresh(rule)
            return rule

    # --- Egyptian Port Demurrage Tariff (Versioned) ---
    def get_port_tariffs(self, port_authority: Optional[str] = None) -> List[PortDemurrageTariff]:
        query = self.db.query(PortDemurrageTariff)
        if port_authority:
            query = query.filter(PortDemurrageTariff.port_authority.ilike(f"%{port_authority}%"))
        return query.order_by(desc(PortDemurrageTariff.effective_from)).all()

    def find_effective_port_tariff(self, port_authority: str, container_type: str, target_date: date) -> Optional[PortDemurrageTariff]:
        port = port_authority.strip()
        ctype = container_type.strip()
        return self.db.query(PortDemurrageTariff).filter(
            PortDemurrageTariff.port_authority.ilike(f"%{port}%"),
            or_(
                PortDemurrageTariff.container_type.ilike(f"%{ctype}%"),
                PortDemurrageTariff.container_type.ilike(f"%{ctype[:2]}%")
            ),
            PortDemurrageTariff.effective_from <= target_date,
            or_(
                PortDemurrageTariff.effective_to == None,
                PortDemurrageTariff.effective_to >= target_date
            )
        ).order_by(desc(PortDemurrageTariff.effective_from)).first()

    def create_port_tariff(self, tariff: PortDemurrageTariff) -> PortDemurrageTariff:
        self.db.add(tariff)
        self.db.commit()
        self.db.refresh(tariff)
        return tariff

    # --- Quota Logs ---
    def get_monthly_quota_used(self, provider: str, month_str: str) -> int:
        return self.db.query(ExternalApiQuotaLog).filter(
            ExternalApiQuotaLog.provider == provider,
            ExternalApiQuotaLog.call_month == month_str,
            ExternalApiQuotaLog.is_success == True
        ).count()

    def log_api_call(self, provider: str, endpoint: str, details: str, success: bool = True) -> ExternalApiQuotaLog:
        now = datetime.now(timezone.utc)
        month_str = now.strftime("%Y-%m")
        log = ExternalApiQuotaLog(
            provider=provider,
            call_month=month_str,
            call_timestamp=now,
            endpoint=endpoint,
            request_details=details,
            is_success=success
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log
