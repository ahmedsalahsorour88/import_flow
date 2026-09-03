"""
Database Repository for Simulation Scenarios and FX Exposure Data
"""

from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from modules.simulation.model import SavedSimulationScenario
from modules.import_files.model import ImportFile


def save_simulation_scenario(
    db: Session,
    scenario_data: dict,
) -> SavedSimulationScenario:
    """Saves a simulated scenario to database."""
    scenario = SavedSimulationScenario(
        scenario_name=scenario_data["scenario_name"],
        import_file_id=scenario_data.get("import_file_id"),
        base_currency=scenario_data.get("base_currency", "USD"),
        base_exchange_rate=scenario_data.get("base_exchange_rate", 50.0),
        simulated_exchange_rate=scenario_data.get("simulated_exchange_rate", 50.0),
        rate_change_pct=scenario_data.get("rate_change_pct", 0.0),
        shipping_route=scenario_data.get("shipping_route", "RED_SEA"),
        transit_delay_days=scenario_data.get("transit_delay_days", 0),
        port_storage_delay_days=scenario_data.get("port_storage_delay_days", 0),
        baseline_landed_cost=scenario_data.get("baseline_landed_cost", 0.0),
        simulated_landed_cost=scenario_data.get("simulated_landed_cost", 0.0),
        cost_variance_amount=scenario_data.get("cost_variance_amount", 0.0),
        cost_variance_pct=scenario_data.get("cost_variance_pct", 0.0),
        acid_risk_status=scenario_data.get("acid_risk_status", "SAFE"),
        risk_level=scenario_data.get("risk_level", "LOW"),
        recommendations=scenario_data.get("recommendations", []),
        scenario_data=scenario_data.get("scenario_data", {}),
        created_by=scenario_data.get("created_by", "System User"),
    )
    db.add(scenario)
    db.commit()
    db.refresh(scenario)
    return scenario


def list_saved_simulation_scenarios(
    db: Session,
    limit: int = 50,
    offset: int = 0,
) -> List[SavedSimulationScenario]:
    """Retrieves saved simulation history ordered by creation date descending."""
    return (
        db.query(SavedSimulationScenario)
        .order_by(desc(SavedSimulationScenario.created_at))
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_saved_scenario_by_id(
    db: Session,
    scenario_id: int,
) -> Optional[SavedSimulationScenario]:
    """Finds a scenario by ID."""
    return (
        db.query(SavedSimulationScenario)
        .filter(SavedSimulationScenario.scenario_id == scenario_id)
        .first()
    )


def get_active_import_files_for_exposure(
    db: Session,
) -> List[ImportFile]:
    """
    Fetches open/active import files where stage is not 'Closed'
    to evaluate open foreign currency financial obligations.
    """
    return (
        db.query(ImportFile)
        .filter(ImportFile.is_active == True)
        .filter(ImportFile.status != "Closed")
        .all()
    )
