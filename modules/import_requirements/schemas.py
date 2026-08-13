from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime


class ImportRequirementBase(BaseModel):
    import_file_id: Optional[int] = None
    import_file_code: Optional[str] = None
    hs_code: Optional[str] = None
    commodity_description: Optional[str] = None
    country_of_origin: Optional[str] = None
    shipment_value_usd: float = Field(0.0, ge=0.0)
    
    coo_required: bool = False
    coo_type: Optional[str] = None
    coo_status: str = Field("Not Required")
    coo_notes: Optional[str] = None
    
    inspection_required: bool = False
    inspection_body: Optional[str] = None
    inspection_status: str = Field("Not Required")
    inspection_notes: Optional[str] = None
    
    msds_required: bool = False
    msds_status: str = Field("Not Required")
    msds_notes: Optional[str] = None
    
    halal_cert_required: bool = False
    halal_cert_status: str = Field("Not Required")
    halal_cert_notes: Optional[str] = None
    
    import_permit_required: bool = False
    permit_issuing_authority: Optional[str] = None
    permit_status: str = Field("Not Required")
    permit_notes: Optional[str] = None
    
    decree_43_applicable: bool = False
    white_list_required: bool = False
    other_requirements: Optional[List[Dict[str, Any]]] = None
    
    overall_status: str = Field("Draft")
    risk_level: str = Field("Low")
    assessed_by: str = Field("Kamal")
    assessment_notes: Optional[str] = None


class ImportRequirementCreate(ImportRequirementBase):
    pass


class ImportRequirementUpdate(BaseModel):
    hs_code: Optional[str] = None
    commodity_description: Optional[str] = None
    country_of_origin: Optional[str] = None
    shipment_value_usd: Optional[float] = None
    coo_required: Optional[bool] = None
    coo_type: Optional[str] = None
    coo_status: Optional[str] = None
    coo_notes: Optional[str] = None
    inspection_required: Optional[bool] = None
    inspection_body: Optional[str] = None
    inspection_status: Optional[str] = None
    inspection_notes: Optional[str] = None
    msds_required: Optional[bool] = None
    msds_status: Optional[str] = None
    msds_notes: Optional[str] = None
    halal_cert_required: Optional[bool] = None
    halal_cert_status: Optional[str] = None
    halal_cert_notes: Optional[str] = None
    import_permit_required: Optional[bool] = None
    permit_issuing_authority: Optional[str] = None
    permit_status: Optional[str] = None
    permit_notes: Optional[str] = None
    decree_43_applicable: Optional[bool] = None
    white_list_required: Optional[bool] = None
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
