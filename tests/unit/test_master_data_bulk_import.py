import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import main # Ensures all models are imported and registered in Base.metadata
from database.database import Base, get_db
from main import app

engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    app.dependency_overrides[get_db] = override_get_db
    yield
    Base.metadata.drop_all(bind=engine)
    app.dependency_overrides.clear()


client = TestClient(app)


class TestMasterDataBulkImportAndExport:

    def test_transport_locations_excel_template(self):
        """
        اختبار تنزيل قالب Excel القياسي لمواقع النقل والموانئ (MD-009).
        """
        response = client.get("/api/v1/transport-locations/excel-template")
        assert response.status_code == 200
        assert "spreadsheetml" in response.headers.get("content-type", "")
        assert len(response.content) > 0

    def test_transport_locations_export_excel(self):
        """
        اختبار تصدير تقرير Excel المجمّع لمواقع النقل والموانئ.
        """
        response = client.get("/api/v1/transport-locations/export-excel")
        assert response.status_code == 200
        assert "spreadsheetml" in response.headers.get("content-type", "")

    def test_transport_locations_export_pdf(self):
        """
        اختبار تصدير تقرير PDF لمواقع النقل والموانئ.
        """
        response = client.get("/api/v1/transport-locations/export-pdf")
        assert response.status_code == 200
        assert "pdf" in response.headers.get("content-type", "")

    def test_suppliers_excel_template_and_export(self):
        """
        اختبار تنزيل قالب وتصدير الموردين الأجانب (MD-002).
        """
        res_template = client.get("/api/v1/suppliers/excel-template")
        assert res_template.status_code == 200

        res_excel = client.get("/api/v1/suppliers/export-excel")
        assert res_excel.status_code == 200

        res_pdf = client.get("/api/v1/suppliers/export-pdf")
        assert res_pdf.status_code == 200

    def test_import_companies_excel_template_and_export(self):
        """
        اختبار تنزيل قالب وتصدير الشركات المستوردة (MD-001).
        """
        res_template = client.get("/api/v1/import-companies/excel-template")
        assert res_template.status_code == 200

        res_excel = client.get("/api/v1/import-companies/export-excel")
        assert res_excel.status_code == 200

        res_pdf = client.get("/api/v1/import-companies/export-pdf")
        assert res_pdf.status_code == 200

    def test_partners_excel_template_and_export(self):
        """
        اختبار تنزيل قالب وتصدير الشركاء والبنوك (MD-003).
        """
        res_template = client.get("/api/v1/external-service-providers/excel-template")
        assert res_template.status_code == 200

        res_excel = client.get("/api/v1/external-service-providers/export-excel")
        assert res_excel.status_code == 200

        res_pdf = client.get("/api/v1/external-service-providers/export-pdf")
        assert res_pdf.status_code == 200
