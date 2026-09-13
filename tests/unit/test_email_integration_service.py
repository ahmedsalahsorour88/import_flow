"""
Unit Tests for Email Server Integration (INT-EMAIL-010)
Settings, Connection Testing, IMAP Ingestion, and SMTP Outbound Dispatching
"""

import pytest
from unittest.mock import MagicMock, patch
from datetime import date
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.import_companies.model import ImportCompany
from modules.suppliers.model import Supplier
from modules.import_files.model import ImportFile
from modules.import_documentation.model import CustomsDeclarationDraft
from modules.smart_email_listener.model import EmailSettings
from modules.smart_email_listener.schemas import (
    EmailSettingsCreate,
    EmailConnectionTestRequest,
    InboxFetchRequest,
    OutboundEmailSendRequest,
)
import modules.smart_email_listener.repository as repo
from modules.smart_email_listener.service import (
    test_email_connection_service as run_test_email_conn,
    fetch_and_process_inbox_service,
    send_outbound_email_service,
)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    company = ImportCompany(
        importer_name="شركة الفتح للاستيراد والتصدير",
        country="Egypt",
        address="القاهرة - مصر",
        importer_id="IMP-TEST-001",
        importer_id_expiry=date(2030, 1, 1),
        vat_id="100200300",
        vat_id_expiry=date(2030, 1, 1),
        registration_number="REG-998877",
        registration_expiry=date(2030, 1, 1),
    )
    supplier = Supplier(
        company_name="Global Tech Logistics",
        supplier_code="SUP-GTL-001",
        supplier_type="Manufacturer",
        registration_type="Commercial Registration",
        foreign_exporter_id="EXP-GTL-001",
        foreign_exporter_country="China",
        foreign_exporter_country_code="CN",
        address="Shanghai, China",
    )
    session.add_all([company, supplier])
    session.commit()

    import_file = ImportFile(
        import_file_code="IMP-2026-00099",
        company_id=company.company_id,
        company_name=company.importer_name,
        supplier_id=supplier.supplier_id,
        supplier_name=supplier.company_name,
        status="Open",
        current_stage="Phase 3 - Cargo Preparation & Shipping",
        required_eta=date(2026, 9, 20),
    )
    session.add(import_file)
    session.commit()

    decl = CustomsDeclarationDraft(
        declaration_code="DEC-2026-099",
        import_file_id=import_file.import_file_id,
        acid_number="9876543210987654321",
        bl_number="ONE1234567890",
        declaration_status="Draft Prepared",
    )
    session.add(decl)
    session.commit()

    yield session
    session.close()


class TestEmailSettingsRepository:
    def test_save_and_get_email_settings(self, db_session):
        settings_data = {
            "provider_type": "GMAIL",
            "email_address": "ops@sorourlogistics.com",
            "username": "ops@sorourlogistics.com",
            "password": "app-secret-password",
            "imap_host": "imap.gmail.com",
            "imap_port": 993,
            "imap_use_ssl": True,
            "smtp_host": "smtp.gmail.com",
            "smtp_port": 587,
            "smtp_use_tls": True,
            "smtp_use_ssl": False,
            "sender_display_name": "Sorour Operations",
            "auto_fetch_enabled": True,
            "fetch_interval_minutes": 10,
        }
        saved = repo.save_or_update_email_settings(db_session, settings_data, user="Admin")
        assert saved.settings_id is not None
        assert saved.email_address == "ops@sorourlogistics.com"
        assert saved.has_password is True

        retrieved = repo.get_email_settings(db_session)
        assert retrieved is not None
        assert retrieved.settings_id == saved.settings_id
        assert retrieved.provider_type == "GMAIL"
        assert retrieved.fetch_interval_minutes == 10

        # Update without changing password
        update_data = {
            "email_address": "newops@sorourlogistics.com",
            "password": "",  # Should not overwrite existing
            "fetch_interval_minutes": 30,
        }
        updated = repo.save_or_update_email_settings(db_session, update_data, user="Admin")
        assert updated.email_address == "newops@sorourlogistics.com"
        assert updated.password == "app-secret-password"
        assert updated.fetch_interval_minutes == 30

    def test_update_sync_status(self, db_session):
        repo.save_or_update_email_settings(
            db_session,
            {
                "provider_type": "OUTLOOK",
                "email_address": "test@outlook.com",
                "password": "pass",
            },
        )
        repo.update_email_settings_sync_status(db_session, "SUCCESS", "All emails synced.")
        settings = repo.get_email_settings(db_session)
        assert settings.last_sync_status == "SUCCESS"
        assert settings.last_sync_message == "All emails synced."
        assert settings.last_sync_at is not None


class TestEmailConnectionService:
    @patch("imaplib.IMAP4_SSL")
    @patch("smtplib.SMTP")
    def test_connection_test_success(self, mock_smtp_class, mock_imap_class):
        mock_imap_inst = MagicMock()
        mock_imap_inst.login.return_value = ("OK", [b"Logged in"])
        mock_imap_class.return_value = mock_imap_inst

        mock_smtp_inst = MagicMock()
        mock_smtp_inst.login.return_value = (235, b"Auth successful")
        mock_smtp_class.return_value = mock_smtp_inst

        req = EmailConnectionTestRequest(
            provider_type="GMAIL",
            email_address="user@gmail.com",
            username="user@gmail.com",
            password="app-password",
            imap_host="imap.gmail.com",
            imap_port=993,
            imap_use_ssl=True,
            smtp_host="smtp.gmail.com",
            smtp_port=587,
            smtp_use_tls=True,
            smtp_use_ssl=False,
        )

        result = run_test_email_conn(req)
        assert result.overall_success is True
        assert result.imap_connected is True
        assert result.smtp_connected is True

    @patch("imaplib.IMAP4_SSL")
    @patch("smtplib.SMTP")
    def test_connection_test_auth_failure(self, mock_smtp_class, mock_imap_class):
        mock_imap_class.side_effect = Exception("Authentication failed")
        mock_smtp_class.side_effect = Exception("535 5.7.8 Username and Password not accepted")

        req = EmailConnectionTestRequest(
            provider_type="GMAIL",
            email_address="user@gmail.com",
            username="user@gmail.com",
            password="wrong-password",
        )

        result = run_test_email_conn(req)
        assert result.overall_success is False
        assert result.imap_connected is False
        assert result.smtp_connected is False
        assert "تسجيل الدخول" in result.imap_message or "App Password" in result.imap_message or "المصادقة" in result.imap_message


class TestOutboundEmailService:
    @patch("smtplib.SMTP")
    def test_send_outbound_email_success(self, mock_smtp_class, db_session):
        repo.save_or_update_email_settings(
            db_session,
            {
                "provider_type": "CUSTOM",
                "email_address": "custom@sorour.com",
                "username": "custom@sorour.com",
                "password": "secretpassword",
                "smtp_host": "mail.sorour.com",
                "smtp_port": 587,
                "smtp_use_tls": True,
            },
        )
        mock_smtp_inst = MagicMock()
        mock_smtp_class.return_value = mock_smtp_inst

        req = OutboundEmailSendRequest(
            recipient_emails=["client@customer.com"],
            subject="Shipment Update IMP-2026-00099",
            body_text="Your shipment has arrived at Alexandria port.",
            is_html=False,
        )
        res = send_outbound_email_service(req, db_session)
        assert res.success is True
        assert "client@customer.com" in res.recipients
        mock_smtp_inst.send_message.assert_called_once()


class TestInboxFetchAndProcessService:
    @patch("imaplib.IMAP4_SSL")
    def test_fetch_inbox_with_matching_bl(self, mock_imap_class, db_session):
        repo.save_or_update_email_settings(
            db_session,
            {
                "provider_type": "GMAIL",
                "email_address": "ops@sorour.com",
                "username": "ops@sorour.com",
                "password": "pass",
                "imap_host": "imap.gmail.com",
                "imap_port": 993,
                "imap_use_ssl": True,
            },
        )

        mock_imap = MagicMock()
        mock_imap_class.return_value = mock_imap
        mock_imap.select.return_value = ("OK", [b"1"])
        mock_imap.search.return_value = ("OK", [b"101"])

        raw_arrival_email = (
            b"From: notifications@ocean-network-express.com\r\n"
            b"To: ops@sorour.com\r\n"
            b"Subject: ONE ARRIVAL NOTICE - BL ONE1234567890\r\n"
            b"Content-Type: text/plain; charset=utf-8\r\n\r\n"
            b"NOTICE OF ARRIVAL\r\n"
            b"BILL OF LADING: ONE1234567890\r\n"
            b"VESSEL: ONE APUS\r\n"
            b"VOYAGE: 014E\r\n"
            b"ETA: 2026-09-29\r\n"
            b"CONTAINERS: ONEU7788990\r\n"
            b"Please pay delivery order and customs fees.\r\n"
        )
        mock_imap.fetch.return_value = ("OK", [(b"101 (RFC822 {200})", raw_arrival_email)])

        result = fetch_and_process_inbox_service(db_session, max_emails=5)

        assert result.total_fetched == 1
        assert result.matched_files_count == 1
        assert result.tasks_created_count == 1
        assert result.results[0].extracted_bl_number == "ONE1234567890"
        assert result.results[0].import_file_code == "IMP-2026-00099"
        assert result.results[0].payment_task_created is True


class TestSmartEmailRouterEndpoints:
    def test_settings_api_lifecycle(self, db_session):
        from modules.smart_email_listener.router import (
            save_email_settings_endpoint,
            get_email_settings_endpoint,
        )

        create_payload = EmailSettingsCreate(
            provider_type="GMAIL",
            email_address="test-router@sorour.com",
            username="test-router@sorour.com",
            password="secret-password",
            imap_host="imap.gmail.com",
            imap_port=993,
            imap_use_ssl=True,
            smtp_host="smtp.gmail.com",
            smtp_port=587,
            smtp_use_tls=True,
            smtp_use_ssl=False,
            sender_display_name="Operations Team",
            auto_fetch_enabled=False,
            fetch_interval_minutes=15,
        )

        # 1. Save settings
        saved = save_email_settings_endpoint(create_payload, db=db_session)
        assert saved.email_address == "test-router@sorour.com"
        assert saved.has_password is True

        # 2. Get settings
        retrieved = get_email_settings_endpoint(db=db_session)
        assert retrieved is not None
        assert retrieved.email_address == "test-router@sorour.com"
        assert retrieved.provider_type == "GMAIL"


