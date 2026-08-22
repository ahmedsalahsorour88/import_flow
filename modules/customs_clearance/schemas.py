from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class CustomsClearanceCreate(BaseModel):
    import_file_id: int
    declaration_46_no: Optional[str] = None
    customs_office_name: str = "Alexandria Port Customs"
    channel_type: str = "Red Channel"
    inspection_date: Optional[datetime] = None
    regulatory_bodies: List[str] = []
    inspection_notes: Optional[str] = None
    import_duty_amount: float = 0.0
    vat_amount: float = 0.0
    schedule_tax_amount: float = 0.0
    wht_amount: float = 0.0
    lab_service_fees: float = 0.0
    estimated_duty_total: float = 0.0
    actual_duty_total: float = 0.0
    duty_variance_amount: float = 0.0
    duty_variance_percentage: float = 0.0
    duty_variance_reason: Optional[str] = None
    nafeza_assessment_json: Optional[Dict[str, Any]] = None
    port_arrival_date: Optional[datetime] = None
    delivery_order_number: Optional[str] = None
    delivery_order_expiry: Optional[datetime] = None
    free_days_allowed: int = 14
    port_gate_out_date: Optional[datetime] = None
    owner: str = "Kamal"
    notes: Optional[str] = None

class DutyPaymentSubmit(BaseModel):
    bank_receipt_no: str
    paying_bank_name: str
    payment_date: datetime
    actual_duty_total: Optional[float] = None
    estimated_duty_total: Optional[float] = None
    duty_variance_reason: Optional[str] = None
    nafeza_assessment_json: Optional[Dict[str, Any]] = None
    payment_notes: Optional[str] = None

class CompleteReleaseSubmit(BaseModel):
    release_permit_no: str
    release_date: datetime
    port_gate_out_date: Optional[datetime] = None
    demurrage_storage_fees: float = 0.0
    dispatch_authorized: bool = True
    notes: Optional[str] = None

class CustomsClearanceUpdate(BaseModel):
    declaration_46_no: Optional[str] = None
    customs_office_name: Optional[str] = None
    channel_type: Optional[str] = None
    inspection_date: Optional[datetime] = None
    regulatory_bodies: Optional[List[str]] = None
    sample_test_status: Optional[str] = None
    inspection_notes: Optional[str] = None
    import_duty_amount: Optional[float] = None
    vat_amount: Optional[float] = None
    schedule_tax_amount: Optional[float] = None
    wht_amount: Optional[float] = None
    lab_service_fees: Optional[float] = None
    estimated_duty_total: Optional[float] = None
    actual_duty_total: Optional[float] = None
    duty_variance_amount: Optional[float] = None
    duty_variance_percentage: Optional[float] = None
    duty_variance_reason: Optional[str] = None
    nafeza_assessment_json: Optional[Dict[str, Any]] = None
    port_arrival_date: Optional[datetime] = None
    delivery_order_number: Optional[str] = None
    delivery_order_expiry: Optional[datetime] = None
    free_days_allowed: Optional[int] = None
    port_gate_out_date: Optional[datetime] = None
    status: Optional[str] = None
    owner: Optional[str] = None
    notes: Optional[str] = None

class CustomsClearanceResponse(BaseModel):
    customs_clearance_id: int
    clearance_code: str
    import_file_id: int
    declaration_46_no: Optional[str] = None
    customs_office_name: str
    channel_type: str
    inspection_date: Optional[datetime] = None
    regulatory_bodies: List[str]
    sample_test_status: str
    inspection_notes: Optional[str] = None
    import_duty_amount: float
    vat_amount: float
    schedule_tax_amount: float
    wht_amount: float
    lab_service_fees: float
    total_duty_payable: float
    estimated_duty_total: float = 0.0
    actual_duty_total: float = 0.0
    duty_variance_amount: float = 0.0
    duty_variance_percentage: float = 0.0
    duty_variance_reason: Optional[str] = None
    nafeza_assessment_json: Optional[Dict[str, Any]] = None
    port_arrival_date: Optional[datetime] = None
    delivery_order_number: Optional[str] = None
    delivery_order_expiry: Optional[datetime] = None
    free_days_allowed: int = 14
    port_gate_out_date: Optional[datetime] = None
    payment_status: str
    bank_receipt_no: Optional[str] = None
    paying_bank_name: Optional[str] = None
    payment_date: Optional[datetime] = None
    payment_notes: Optional[str] = None
    release_permit_no: Optional[str] = None
    release_date: Optional[datetime] = None
    demurrage_storage_fees: float
    dispatch_authorized: bool
    dispatch_date: Optional[datetime] = None
    status: str
    owner: str
    notes: Optional[str] = None
    is_active: bool
    created_at: datetime
    created_by: str
    updated_at: datetime
    updated_by: str

    model_config = ConfigDict(from_attributes=True)
