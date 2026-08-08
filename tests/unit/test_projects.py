import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.incoterms.model import Incoterm
from modules.projects.model import Project
from modules.projects.schemas import ProjectCreate, ProjectUpdate
from modules.projects.service import ProjectService
from modules.suppliers.model import Supplier
from fastapi import HTTPException


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()

    from modules.import_companies.service import create_import_company
    from modules.import_companies.schemas import ImportCompanyCreate
    from datetime import date, timedelta

    # Seed required FKs
    company = create_import_company(session, ImportCompanyCreate(
        importer_name="Test Company",
        address="Cairo",
        country="Egypt",
        importer_id="IMP-100200",
        importer_id_expiry=date.today() + timedelta(days=120),
        vat_id="VAT-998877",
        vat_id_expiry=date.today() + timedelta(days=90),
        registration_number="REG-554433",
        registration_expiry=date.today() + timedelta(days=60),
    ))
    from modules.suppliers.service import create_supplier_service
    from modules.suppliers.schemas import SupplierCreate

    supplier = create_supplier_service(session, SupplierCreate(
        company_name="Test Supplier",
        supplier_type="Manufacturer",
        registration_type="Factory",
        foreign_exporter_id="EXP-CN-8899",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="China",
    ))
    incoterm = Incoterm(incoterm_code="FOB", incoterm_name="Free on Board", is_active=True)
    session.add(incoterm)
    session.commit()

    try:
        yield session
    finally:
        session.close()


class TestProjectsBackend:

    def test_create_project(self, db_session):
        service = ProjectService(db_session)
        data = ProjectCreate(
            project_name="Solar Power Project",
            project_owner="Eng. Ali",
            company_id=1,
            supplier_id=1,
            incoterm_id=1,
            import_type="Direct Commercial",
            priority="High",
            shipment_category="FCL Container",
            allow_multi_shipment=True,
            allow_multi_company=True,
            total_budget_usd=500000.0,
        )
        proj = service.create(data)

        assert proj.project_id is not None
        assert proj.project_code.startswith("PRJ-")
        assert proj.allow_multi_shipment is True
        assert proj.allow_multi_company is True
        assert proj.status == "Open"

    def test_invalid_fk_raises_400(self, db_session):
        service = ProjectService(db_session)
        data = ProjectCreate(
            project_name="Invalid Project",
            project_owner="Owner",
            company_id=999,  # Non-existent
            supplier_id=1,
            incoterm_id=1,
        )

        with pytest.raises(HTTPException) as exc:
            service.create(data)

        assert exc.value.status_code == 400
        assert "Company with ID 999 does not exist" in exc.value.detail

    def test_update_and_soft_delete_project(self, db_session):
        service = ProjectService(db_session)
        proj = service.create(ProjectCreate(
            project_name="Raw Materials Q3",
            project_owner="Owner",
            company_id=1,
            supplier_id=1,
            incoterm_id=1,
        ))

        updated = service.update(proj.project_id, ProjectUpdate(status="Closed", priority="Low"))
        assert updated.status == "Closed"
        assert updated.priority == "Low"

        # Soft Delete
        service.soft_delete(proj.project_id)
        active_list = service.get_all(include_inactive=False)
        assert len(active_list) == 0

        # Restore
        restored = service.restore(proj.project_id)
        assert restored.is_active is True
        active_list = service.get_all(include_inactive=False)
        assert len(active_list) == 1
