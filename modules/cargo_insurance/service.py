from datetime import datetime, timezone
from typing import Optional, Tuple, List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from modules.cargo_insurance.model import CargoInsuranceCertificate
from modules.cargo_insurance.repository import CargoInsuranceRepository
from modules.cargo_insurance.schemas import (
    InsuranceCalculationInput,
    InsuranceCalculationResult,
    CargoInsuranceCertificateCreate,
    CargoInsuranceCertificateUpdate,
)
from modules.cargo_insurance.validators import (
    validate_cargo_insurance_create,
    validate_cargo_insurance_update,
)


RATE_TABLE = {
    "ICC_A": 0.0025,          # 0.25% All Risks (London Institute Cargo Clauses A)
    "AIR_ALL_RISKS": 0.0020,  # 0.20% Air Cargo All Risks
    "ICC_B": 0.0015,          # 0.15% Intermediate (London Institute Cargo Clauses B)
    "ICC_C": 0.0010,          # 0.10% Minimum (London Institute Cargo Clauses C)
}
WAR_STRIKES_RATE = 0.0005    # 0.05% Institute War & Strikes Clauses


def calculate_cargo_insurance_engine(input_data: InsuranceCalculationInput) -> InsuranceCalculationResult:
    markup = input_data.markup_percentage if input_data.markup_percentage is not None else 0.10
    issuance_fee = input_data.issuance_fee if input_data.issuance_fee is not None else 15.00
    min_premium = input_data.minimum_premium if input_data.minimum_premium is not None else 30.00
    tax_rate = input_data.tax_rate if input_data.tax_rate is not None else 0.05

    # 1. Calculate CIF / CIP Base and Insured Value (110% CIF standard)
    cif_value = round(input_data.invoice_value + input_data.freight_cost + (input_data.other_costs or 0.0), 2)
    insured_value = round(cif_value * (1.0 + markup), 2)

    # 2. Lookup Base Rate from ICC Matrix
    base_rate = RATE_TABLE.get(input_data.coverage_clause, 0.0025)
    base_premium = round(insured_value * base_rate, 2)

    # 3. War & Strikes Add-on
    war_rate = WAR_STRIKES_RATE if input_data.include_war_and_strikes else 0.0
    war_strikes_premium = round(insured_value * war_rate, 2)

    # 4. Apply Policy Minimum Premium Threshold
    calculated_net = round(base_premium + war_strikes_premium, 2)
    net_premium = round(max(calculated_net, min_premium), 2)

    # 5. Administrative Issuance Fee, Stamp Duty & Taxes
    taxable_base = net_premium + issuance_fee
    tax_amount = round(taxable_base * tax_rate, 2)
    total_payable = round(net_premium + issuance_fee + tax_amount, 2)

    return InsuranceCalculationResult(
        cif_value=cif_value,
        markup_percentage=markup,
        insured_value=insured_value,
        coverage_clause=input_data.coverage_clause,
        base_rate=base_rate,
        base_premium=base_premium,
        war_rate=war_rate,
        war_strikes_premium=war_strikes_premium,
        net_premium=net_premium,
        issuance_fee=issuance_fee,
        tax_rate=tax_rate,
        tax_amount=tax_amount,
        total_payable_premium=total_payable,
        currency=input_data.currency,
    )


class CargoInsuranceService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = CargoInsuranceRepository(db)

    def calculate_insurance(self, input_data: InsuranceCalculationInput) -> InsuranceCalculationResult:
        return calculate_cargo_insurance_engine(input_data)

    def create_certificate(
        self,
        data: CargoInsuranceCertificateCreate,
        current_user: str = "system",
    ) -> CargoInsuranceCertificate:
        validate_cargo_insurance_create(data)

        # 1. Run Financial Engine Calculation
        calc_input = InsuranceCalculationInput(
            invoice_value=data.invoice_value,
            freight_cost=data.freight_cost,
            other_costs=data.other_logistics_costs,
            markup_percentage=data.markup_percentage,
            coverage_clause=data.coverage_clause,
            transport_mode=data.transport_mode,
            include_war_and_strikes=data.include_war_and_strikes,
            currency=data.currency,
            minimum_premium=data.minimum_premium,
            issuance_fee=data.issuance_fee,
            tax_rate=data.tax_rate,
        )
        calc_result = calculate_cargo_insurance_engine(calc_input)

        # 2. Generate Certificate Code
        cert_code = self.repo.generate_next_certificate_code()

        # 3. Create Entity Record
        certificate = CargoInsuranceCertificate(
            certificate_code=cert_code,
            policy_number=data.policy_number or f"POL-{datetime.now().strftime('%Y%m')}-{cert_code.split('-')[-1]}",
            policy_type=data.policy_type,
            import_file_id=data.import_file_id,
            insurance_company_id=data.insurance_company_id,
            insurance_company_name=data.insurance_company_name or "Misr Insurance / Suez Canal Insurance",
            insured_entity_name=data.insured_entity_name,
            transport_mode=data.transport_mode,
            carrier_name=data.carrier_name,
            vessel_or_flight_no=data.vessel_or_flight_no,
            voyage_number=data.voyage_number,
            tracking_reference=data.tracking_reference,
            port_of_loading=data.port_of_loading,
            port_of_discharge=data.port_of_discharge,
            final_destination=data.final_destination or "Cairo / Alexandria, Egypt",
            currency=data.currency,
            exchange_rate=data.exchange_rate,
            invoice_value=data.invoice_value,
            freight_cost=data.freight_cost,
            other_logistics_costs=data.other_logistics_costs,
            cif_value=calc_result.cif_value,
            markup_percentage=calc_result.markup_percentage,
            insured_value=calc_result.insured_value,
            coverage_clause=calc_result.coverage_clause,
            include_war_and_strikes=data.include_war_and_strikes,
            base_rate=calc_result.base_rate,
            war_rate=calc_result.war_rate,
            base_premium=calc_result.base_premium,
            war_strikes_premium=calc_result.war_strikes_premium,
            minimum_premium=data.minimum_premium,
            net_premium=calc_result.net_premium,
            issuance_fee=calc_result.issuance_fee,
            tax_rate=calc_result.tax_rate,
            tax_amount=calc_result.tax_amount,
            total_payable_premium=calc_result.total_payable_premium,
            goods_description=data.goods_description,
            package_count=data.package_count,
            package_type=data.package_type,
            gross_weight_kg=data.gross_weight_kg,
            survey_agent_in_destination=data.survey_agent_in_destination or "Lloyd's Agency / Local Marine Surveyor",
            claims_payable_at=data.claims_payable_at or "Cairo, Egypt",
            status="DRAFT",
            remarks=data.remarks,
            created_by=current_user,
            updated_by=current_user,
        )

        return self.repo.create(certificate)

    def get_certificate(self, certificate_id: int) -> CargoInsuranceCertificate:
        cert = self.repo.get_by_id(certificate_id)
        if not cert:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cargo insurance certificate with ID {certificate_id} not found.",
            )
        return cert

    def list_certificates(
        self,
        skip: int = 0,
        limit: int = 50,
        import_file_id: Optional[int] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
    ) -> Tuple[List[CargoInsuranceCertificate], int]:
        return self.repo.list_certificates(
            skip=skip,
            limit=limit,
            import_file_id=import_file_id,
            status=status,
            search=search,
        )

    def update_certificate(
        self,
        certificate_id: int,
        data: CargoInsuranceCertificateUpdate,
        current_user: str = "system",
    ) -> CargoInsuranceCertificate:
        validate_cargo_insurance_update(data)
        cert = self.get_certificate(certificate_id)

        update_dict = data.model_dump(exclude_unset=True)

        for key, value in update_dict.items():
            if hasattr(cert, key) and value is not None:
                setattr(cert, key, value)

        # Recalculate financial fields if values were updated
        calc_input = InsuranceCalculationInput(
            invoice_value=cert.invoice_value,
            freight_cost=cert.freight_cost,
            other_costs=cert.other_logistics_costs,
            markup_percentage=cert.markup_percentage,
            coverage_clause=cert.coverage_clause,
            transport_mode=cert.transport_mode,
            include_war_and_strikes=cert.include_war_and_strikes,
            currency=cert.currency,
            minimum_premium=cert.minimum_premium,
            issuance_fee=cert.issuance_fee,
            tax_rate=cert.tax_rate,
        )
        calc_result = calculate_cargo_insurance_engine(calc_input)
        cert.cif_value = calc_result.cif_value
        cert.insured_value = calc_result.insured_value
        cert.base_rate = calc_result.base_rate
        cert.base_premium = calc_result.base_premium
        cert.war_rate = calc_result.war_rate
        cert.war_strikes_premium = calc_result.war_strikes_premium
        cert.net_premium = calc_result.net_premium
        cert.tax_amount = calc_result.tax_amount
        cert.total_payable_premium = calc_result.total_payable_premium

        cert.updated_at = datetime.now(timezone.utc)
        cert.updated_by = current_user

        return self.repo.update(cert)

    def issue_certificate(
        self,
        certificate_id: int,
        current_user: str = "system",
    ) -> CargoInsuranceCertificate:
        cert = self.get_certificate(certificate_id)
        if cert.status == "ISSUED":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Certificate has already been issued.",
            )

        cert.status = "ISSUED"
        cert.issued_at = datetime.now(timezone.utc)
        cert.updated_at = datetime.now(timezone.utc)
        cert.updated_by = current_user

        return self.repo.update(cert)

    def delete_certificate(self, certificate_id: int) -> None:
        cert = self.get_certificate(certificate_id)
        self.repo.soft_delete(cert)
