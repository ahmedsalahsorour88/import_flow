"""
SQLAlchemy Model for Import Requirements Assessment (BP-011)
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Float, ForeignKey, JSON
from database.database import Base

class ImportRequirementAssessment(Base):
    __tablename__ = "import_requirement_assessments"

    assessment_id = Column(Integer, primary_key=True, autoincrement=True)
    assessment_code = Column(String(50), unique=True, nullable=False)  # BP011-2026-0001
    import_file_id = Column(Integer, ForeignKey("import_files.import_file_id", ondelete="CASCADE"), nullable=True)
    import_file_code = Column(String(50), nullable=True)  # denormalized
    
    # HS Code & Commodity
    hs_code = Column(String(20), nullable=True)
    commodity_description = Column(Text, nullable=True)
    country_of_origin = Column(String(100), nullable=True)
    currency = Column(String(10), nullable=False, default="USD")
    shipment_value = Column(Float, nullable=False, default=0.0)
    shipment_value_usd = Column(Float, nullable=False, default=0.0)
    
    # Certificate of Origin (COO)
    coo_required = Column(Boolean, nullable=False, default=False)
    coo_type = Column(String(100), nullable=True)  # EUR.1, Form A, GSTP, Arab League COO
    coo_status = Column(String(50), nullable=False, default="Not Required")  # Not Required, Pending, Obtained, Waived
    coo_notes = Column(Text, nullable=True)
    
    # Inspection Certificate
    inspection_required = Column(Boolean, nullable=False, default=False)
    inspection_body = Column(String(200), nullable=True)  # SGS, Bureau Veritas, QIMA
    inspection_status = Column(String(50), nullable=False, default="Not Required")  # Not Required, Pending, Scheduled, Completed
    inspection_notes = Column(Text, nullable=True)
    
    # MSDS (Material Safety Data Sheet)
    msds_required = Column(Boolean, nullable=False, default=False)
    msds_status = Column(String(50), nullable=False, default="Not Required")  # Not Required, Pending, Obtained
    msds_notes = Column(Text, nullable=True)
    
    # Halal / Food Safety Certificate
    halal_cert_required = Column(Boolean, nullable=False, default=False)
    halal_cert_status = Column(String(50), nullable=False, default="Not Required")
    halal_cert_notes = Column(Text, nullable=True)
    
    # Import Permit (موافقة الجهات الرقابية)
    import_permit_required = Column(Boolean, nullable=False, default=False)
    permit_issuing_authority = Column(String(200), nullable=True)  # GOEIC, Ministry of Health, etc.
    permit_status = Column(String(50), nullable=False, default="Not Required")  # Not Required, Applied, Approved, Rejected
    permit_notes = Column(Text, nullable=True)
    
    # Decree 43 / White List (المحور 1: قرار 43 وتسجيل المصانع)
    supplier_id = Column(Integer, ForeignKey("suppliers.supplier_id"), nullable=True)
    supplier_name = Column(String(200), nullable=True)
    decree_43_applicable = Column(Boolean, nullable=False, default=False)
    white_list_required = Column(Boolean, nullable=False, default=False)
    white_list_verified = Column(Boolean, nullable=False, default=False)
    factory_registration_no = Column(String(100), nullable=True)  # رقم قيد المصنع/المورد بالهيئة
    
    # Inspection Certificate (المحور 3: فحص ما قبل الشحن)
    inspection_report_no = Column(String(100), nullable=True)
    
    # Import Permit (المحور 4: موافقات وتصاريح الجهات الرقابية)
    permit_number = Column(String(100), nullable=True)
    
    # Technical & Special Certs (المحور 5: شهادات خاصة)
    coa_required = Column(Boolean, nullable=False, default=False)
    coa_status = Column(String(50), nullable=False, default="Not Required")
    coa_notes = Column(Text, nullable=True)
    
    # Other Requirements (flexible JSON)
    other_requirements = Column(JSON, nullable=True)  # [{name, required, status, notes}]
    
    # Assessment Summary
    overall_status = Column(String(50), nullable=False, default="Draft")  # Draft, In Progress, Complete, Cleared
    risk_level = Column(String(20), nullable=False, default="Low")  # Low, Medium, High
    assessed_by = Column(String(100), nullable=False, default="Kamal")
    assessment_notes = Column(Text, nullable=True)
    
    # Audit
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by = Column(String(100), nullable=False, default="System")
    updated_by = Column(String(100), nullable=False, default="System")
