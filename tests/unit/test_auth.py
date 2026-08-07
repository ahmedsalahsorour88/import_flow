import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database.database import Base
from modules.auth.schemas import UserCreate
from modules.auth.security import hash_password, verify_password, create_access_token, decode_access_token
from modules.auth.service import AuthService


class TestAuthAndRBAC(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(self.engine)
        TestingSessionLocal = sessionmaker(bind=self.engine)
        self.db = TestingSessionLocal()
        self.auth_service = AuthService(self.db)

    def tearDown(self):
        self.db.close()

    def test_password_hashing_and_verification(self):
        raw = "secret123"
        hashed = hash_password(raw)
        self.assertNotEqual(raw, hashed)
        self.assertTrue(verify_password("secret123", hashed))
        self.assertFalse(verify_password("wrongpass", hashed))

    def test_jwt_token_generation_and_decoding(self):
        token = create_access_token({"sub": "42", "role": "MANAGER"})
        payload = decode_access_token(token)
        self.assertIsNotNone(payload)
        self.assertEqual(payload["sub"], "42")
        self.assertEqual(payload["role"], "MANAGER")

    def test_register_and_authenticate_user(self):
        user_in = UserCreate(
            username="testmanager",
            email="testmanager@importflow.com",
            full_name="Test Manager",
            password="managerpass123",
            role="MANAGER",
        )
        user = self.auth_service.register_user(user_in)
        self.assertIsNotNone(user.user_id)
        self.assertEqual(user.role, "MANAGER")

        authenticated = self.auth_service.authenticate_user("testmanager", "managerpass123")
        self.assertIsNotNone(authenticated)
        self.assertEqual(authenticated.user_id, user.user_id)

    def test_duplicate_username_raises_exception(self):
        user_in1 = UserCreate(
            username="dupuser",
            email="dup1@importflow.com",
            full_name="User 1",
            password="password",
            role="OPERATOR",
        )
        self.auth_service.register_user(user_in1)

        user_in2 = UserCreate(
            username="dupuser",
            email="dup2@importflow.com",
            full_name="User 2",
            password="password",
            role="OPERATOR",
        )
        with self.assertRaises(Exception):
            self.auth_service.register_user(user_in2)


if __name__ == "__main__":
    unittest.main()
