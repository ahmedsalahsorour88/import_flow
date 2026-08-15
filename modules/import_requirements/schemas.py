from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class ImportRequirementBase(BaseModel):
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    hs_code: Optional[str] = None
    commodity_description: Optional[str] = None
    country_of_origin: Optional[str] = None
    currency: str = Field("USD", max_length=10)
    shipment_value: float = Field(0.0, ge=0.0)
    shipment_value_usd: float = Field(0.0, ge=0.0)
    
    # Pillar 1: Decree 43 & Foreign Suppliers
    supplier_id: Optional[int] = None
    supplier_name: Optional[str] = None
    decree_43_applicable: bool = False
    white_list_required: bool = False
    white_list_verified: bool = False
    factory_registration_no: Optional[str] = None
    
    # Pillar 2: Certificate of Origin (COO) & Trade Reductions
    coo_required: bool = False
    coo_type: Optional[str] = None
    coo_status: str = Field("Not Required")
    coo_notes: Optional[str] = None
    
    # Pillar 3: Inspection Certificate
    inspection_required: bool = False
    inspection_body: Optional[str] = None
    inspection_status: str = Field("Not Required")
    inspection_report_no: Optional[str] = None
    inspection_notes: Optional[str] = None
    
    # Pillar 4: Import Permit & Regulatory Authorities
    import_permit_required: bool = False
    permit_issuing_authority: Optional[str] = None
    permit_number: Optional[str] = None
    permit_status: str = Field("Not Required")
    permit_notes: Optional[str] = None
    
    # Pillar 5: Technical & Special Certs (MSDS, Halal, COA)
    msds_required: bool = False
    msds_status: str = Field("Not Required")
    msds_notes: Optional[str] = None
    
    halal_cert_required: bool = False
    halal_cert_status: str = Field("Not Required")
    halal_cert_notes: Optional[str] = None
    
    coa_required: bool = False
    coa_status: str = Field("Not Required")
    coa_notes: Optional[str] = None
    
    other_requirements: Optional[List[Dict[str, Any]]] = None
    
    # Overall Assessment & Risk
    overall_status: str = Field("Draft")
    risk_level: str = Field("Low")
    assessed_by: str = Field("Kamal")
    assessment_notes: Optional[str] = None


class ImportRequirementCreate(ImportRequirementBase):
    pass


class ImportRequirementUpdate(BaseModel):
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    hs_code: Optional[str] = None
    commodity_description: Optional[str] = None
    country_of_origin: Optional[str] = None
    currency: Optional[str] = None
    shipment_value: Optional[float] = None
    shipment_value_usd: Optional[float] = None
    
    supplier_id: Optional[int] = None
    supplier_name: Optional[str] = None
    decree_43_applicable: Optional[bool] = None
    white_list_required: Optional[bool] = None
    white_list_verified: Optional[bool] = None
    factory_registration_no: Optional[str] = None
    
    coo_required: Optional[bool] = None
    coo_type: Optional[str] = None
    coo_status: Optional[str] = None
    coo_notes: Optional[str] = None
    
    inspection_required: Optional[bool] = None
    inspection_body: Optional[str] = None
    inspection_status: Optional[str] = None
    inspection_report_no: Optional[str] = None
    inspection_notes: Optional[str] = None
    
    import_permit_required: Optional[bool] = None
    permit_issuing_authority: Optional[str] = None
    permit_number: Optional[str] = None
    permit_status: Optional[str] = None
    permit_notes: Optional[str] = None
    
    msds_required: Optional[bool] = None
    msds_status: Optional[str] = None
    msds_notes: Optional[str] = None
    
    halal_cert_required: Optional[bool] = None
    halal_cert_status: Optional[str] = None
    halal_cert_notes: Optional[str] = None
    
    coa_required: Optional[bool] = None
    coa_status: Optional[str] = None
    coa_notes: Optional[str] = None
    
    other_requirements: Optional[List[Dict[str, Any]]] = None
    overall_status: Optional[str] = None
    risk_level: Optional[str] = None
    assessed_by: Optional[str] = None
    assessment_notes: Optional[str] = None


class ImportRequirementResponse(ImportRequirementBase):
    model_config = ConfigDict(from_attributes=True)
    
    assessment_id: int
    assessment_code: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    created_by: str
    updated_by: str
