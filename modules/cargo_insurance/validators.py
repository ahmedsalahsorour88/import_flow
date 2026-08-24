from fastapi import HTTPException, status
from modules.cargo_insurance.schemas import CargoInsuranceCertificateCreate, CargoInsuranceCertificateUpdate


def validate_cargo_insurance_create(data: CargoInsuranceCertificateCreate) -> None:
    if data.invoice_value < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invoice value cannot be negative.",
        )
    if data.freight_cost < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Freight cost cannot be negative.",
        )
    if not data.insured_entity_name or not data.insured_entity_name.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insured entity name (Importer / Consignee) is required.",
        )
    if not data.port_of_loading or not data.port_of_loading.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Port of Loading is required.",
        )
    if not data.port_of_discharge or not data.port_of_discharge.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Port of Discharge is required.",
        )

    valid_clauses = ["ICC_A", "AIR_ALL_RISKS", "ICC_B", "ICC_C"]
    if data.coverage_clause not in valid_clauses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid coverage clause '{data.coverage_clause}'. Valid clauses: {valid_clauses}",
        )

    valid_modes = ["OCEAN", "AIR", "ROAD"]
    if data.transport_mode not in valid_modes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid transport mode '{data.transport_mode}'. Valid modes: {valid_modes}",
        )


def validate_cargo_insurance_update(data: CargoInsuranceCertificateUpdate) -> None:
    if data.invoice_value is not None and data.invoice_value < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invoice value cannot be negative.",
        )
    if data.freight_cost is not None and data.freight_cost < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Freight cost cannot be negative.",
        )
    if data.insured_entity_name is not None and not data.insured_entity_name.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insured entity name cannot be empty.",
        )
