import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.database import Base
from modules.notifications.schemas import NotificationCreate
from modules.notifications.service import NotificationService


class TestNotificationsModule(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
        TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        Base.metadata.create_all(bind=self.engine)
        self.db = TestingSessionLocal()
        self.service = NotificationService(self.db)

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_create_and_fetch_notification(self):
        schema = NotificationCreate(
            title="تنبيه تجريبي من الاختبارات",
            message="هذا الإشعار لتجربة محرك الإشعارات اللحظية",
            severity="WARNING",
            category="COMPANY_EXPIRY",
            entity_type="ImportCompany",
            entity_id=1,
            target_role="ALL",
        )

        notif = self.service.create_notification(schema)
        self.assertIsNotNone(notif.notification_id)
        self.assertFalse(notif.is_read)
        self.assertEqual(notif.severity, "WARNING")

        # Fetch notifications
        all_notifs = self.service.get_notifications(unread_only=True)
        self.assertGreaterEqual(len(all_notifs), 1)

    def test_mark_as_read(self):
        schema = NotificationCreate(
            title="تنبيه قابل للقراءة",
            message="اختبار الفلترة وتغيير الحالة",
            severity="INFO",
            category="SYSTEM",
        )
        notif = self.service.create_notification(schema)

        # Mark read
        updated = self.service.mark_read(notif.notification_id)
        self.assertTrue(updated.is_read)

        summary = self.service.get_summary()
        self.assertGreaterEqual(summary.total_count, 1)

    def test_trigger_expiry_check(self):
        new_alerts = self.service.trigger_expiry_check()
        self.assertIsInstance(new_alerts, list)
