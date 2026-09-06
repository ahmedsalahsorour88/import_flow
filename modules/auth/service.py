from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.users.model import User
from .schemas import UserCreate, UserUpdate
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
                detail=f"اسم المستخدم '{user_data.username}' مستخدم بالفعل."
            )

        existing_email = self.db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"البريد الإلكتروني '{user_data.email}' مسجل بالفعل."
            )

        if len(user_data.password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="كلمة المرور يجب أن تكون 6 أحرف على الأقل."
            )

        allowed_roles = ["ADMIN", "MANAGER", "OPERATOR"]
        role = user_data.role.upper()
        if role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"الدور '{user_data.role}' غير صالح. الأدوار المتاحة: {allowed_roles}"
            )

        user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            hashed_password=hash_password(user_data.password),
            role=role,
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

    def update_user(self, user_id: int, update_data: UserUpdate) -> User:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود.")

        old_data = {"role": user.role, "full_name": user.full_name, "email": user.email}

        if update_data.full_name is not None:
            user.full_name = update_data.full_name

        if update_data.email is not None:
            existing = self.db.query(User).filter(
                User.email == update_data.email,
                User.user_id != user_id
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"البريد الإلكتروني '{update_data.email}' مستخدم من مستخدم آخر."
                )
            user.email = update_data.email

        if update_data.role is not None:
            allowed_roles = ["ADMIN", "MANAGER", "OPERATOR"]
            role = update_data.role.upper()
            if role not in allowed_roles:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"الدور '{update_data.role}' غير صالح."
                )
            user.role = role

        if update_data.password is not None:
            if len(update_data.password) < 6:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="كلمة المرور يجب أن تكون 6 أحرف على الأقل."
                )
            user.hashed_password = hash_password(update_data.password)

        self.db.commit()
        self.db.refresh(user)

        from modules.audit_logs.service import AuditLogService
        AuditLogService(self.db).log_activity(
            entity_type="User",
            entity_id=user.user_id,
            entity_code=user.username,
            action="UPDATE",
            old_data=old_data,
            new_data={"role": user.role, "full_name": user.full_name, "email": user.email}
        )

        return user

    def toggle_user_status(self, user_id: int, admin_user_id: int) -> User:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود.")

        if user.user_id == admin_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن تعطيل حسابك الخاص."
            )

        old_status = user.is_active
        user.is_active = not user.is_active
        self.db.commit()
        self.db.refresh(user)

        from modules.audit_logs.service import AuditLogService
        AuditLogService(self.db).log_activity(
            entity_type="User",
            entity_id=user.user_id,
            entity_code=user.username,
            action="UPDATE",
            old_data={"is_active": old_status},
            new_data={"is_active": user.is_active}
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
                detail="حساب المستخدم معطّل. تواصل مع مدير النظام."
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

    def get_user_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.user_id == user_id).first()
