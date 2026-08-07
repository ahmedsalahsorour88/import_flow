from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.users.model import User
from .schemas import UserCreate
from .security import hash_password, verify_password, create_access_token


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def register_user(self, user_data: UserCreate) -> User:
        # Check existing username or email
        existing_username = self.db.query(User).filter(User.username == user_data.username).first()
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Username '{user_data.username}' is already taken."
            )

        existing_email = self.db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Email '{user_data.email}' is already registered."
            )

        user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            hashed_password=hash_password(user_data.password),
            role=user_data.role.upper(),
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        from modules.audit_logs.service import AuditLogService
        AuditLogService(self.db).log_activity(
            entity_type="User",
            entity_id=user.user_id,
            entity_code=user.username,
            action="CREATE",
            new_data={"username": user.username, "role": user.role}
        )

        return user

    def authenticate_user(self, username_or_email: str, password: str) -> Optional[User]:
        user = self.db.query(User).filter(
            (User.username == username_or_email) | (User.email == username_or_email)
        ).first()

        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated."
            )

        return user

    def generate_user_token(self, user: User) -> str:
        payload = {
            "sub": str(user.user_id),
            "username": user.username,
            "role": user.role,
        }
        return create_access_token(payload)

    def get_all_users(self) -> List[User]:
        return self.db.query(User).order_by(User.user_id).all()
