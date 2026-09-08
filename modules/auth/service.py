from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from modules.users.model import User, Role, Permission, RolePermission, UserPermission
from .schemas import UserCreate, UserUpdate, UserPermissionsUpdatePayload
from .security import hash_password, verify_password, create_access_token
from .permissions import get_user_permissions_breakdown, get_user_effective_permissions


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

        # Resolve role_id and role_code
        role_obj: Optional[Role] = None
        if user_data.role_id:
            role_obj = self.db.query(Role).filter(Role.role_id == user_data.role_id).first()
            if not role_obj:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"معرف الدور '{user_data.role_id}' غير موجود."
                )
        elif user_data.role:
            role_input = user_data.role.upper()
            # Map legacy names if needed
            if role_input == "MANAGER":
                role_input = "GENERAL_MANAGER"
            elif role_input == "OPERATOR":
                role_input = "LOGISTICS_OPERATOR"

            role_obj = self.db.query(Role).filter(Role.role_code == role_input).first()

        role_code = role_obj.role_code if role_obj else (user_data.role.upper() if user_data.role else "LOGISTICS_OPERATOR")
        role_id = role_obj.role_id if role_obj else None

        user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            hashed_password=hash_password(user_data.password),
            role=role_code,
            role_id=role_id,
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
            new_data={"username": user.username, "role": user.role, "role_id": user.role_id}
        )

        return user

    def update_user(self, user_id: int, update_data: UserUpdate) -> User:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود.")

        old_data = {"role": user.role, "role_id": user.role_id, "full_name": user.full_name, "email": user.email}

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

        if update_data.role_id is not None:
            target_role = self.db.query(Role).filter(Role.role_id == update_data.role_id).first()
            if not target_role:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"معرف الدور '{update_data.role_id}' غير موجود."
                )
            user.role_id = target_role.role_id
            user.role = target_role.role_code
        elif update_data.role is not None:
            role_input = update_data.role.upper()
            if role_input == "MANAGER":
                role_input = "GENERAL_MANAGER"
            elif role_input == "OPERATOR":
                role_input = "LOGISTICS_OPERATOR"

            target_role = self.db.query(Role).filter(Role.role_code == role_input).first()
            if target_role:
                user.role_id = target_role.role_id
                user.role = target_role.role_code
            else:
                user.role = role_input

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
            new_data={"role": user.role, "role_id": user.role_id, "full_name": user.full_name, "email": user.email}
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

    # ─── RBAC Management Methods ──────────────────────────────────────────────

    def get_all_permissions(self) -> List[Permission]:
        return self.db.query(Permission).order_by(Permission.module_name, Permission.permission_code).all()

    def get_permissions_grouped(self) -> List[Dict[str, Any]]:
        perms = self.get_all_permissions()
        module_titles_ar = {
            "import_files": "ملفات الاستيراد",
            "lifecycle_board": "لوحة دورة حياة الشحنات",
            "purchase_orders": "أوامر الشراء",
            "freight_booking": "حجوزات الشحن",
            "cargo_shipping": "حركة وتتبع الشحن",
            "customs_clearance": "التخليص الجمركي",
            "customs_tariff": "التعريفة والبنود الجمركية",
            "cargox_nafeza": "كارجو إكس ومنظومة نافذة",
            "import_documentation": "مستندات الشحن والمطابقة",
            "financial_approval": "الاعتمادات وطلبات الصرف",
            "financial_settlement": "التسويات وتكلفة الوصول",
            "warehouse_receiving": "استلام المستودعات",
            "demurrage_detention": "الأرضيات وغرامات التأخير",
            "quotations": "عروض أسعار الشحن والتخليص",
            "master_data": "البيانات المرجعية الأساسية",
            "users_and_security": "المستخدمين وإدارة الصلاحيات",
            "audit_logs": "سجل العمليات والرقابة",
            "reports_and_analytics": "التقارير الإدارية والتحليلات",
        }
        groups_dict: Dict[str, List[Permission]] = {}
        for p in perms:
            groups_dict.setdefault(p.module_name, []).append(p)

        result = []
        for mod, items in groups_dict.items():
            result.append({
                "module_name": mod,
                "module_name_ar": module_titles_ar.get(mod, mod),
                "permissions": items,
            })
        return result

    def get_all_roles(self) -> List[Dict[str, Any]]:
        roles = self.db.query(Role).order_by(Role.role_id).all()
        result = []
        for r in roles:
            perm_codes = [rp.permission.permission_code for rp in r.role_permissions if rp.permission]
            result.append({
                "role_id": r.role_id,
                "role_code": r.role_code,
                "name_en": r.name_en,
                "name_ar": r.name_ar,
                "description": r.description,
                "is_system_role": r.is_system_role,
                "is_active": r.is_active,
                "permissions": sorted(perm_codes),
            })
        return result

    def get_user_permissions(self, user_id: int) -> Dict[str, Any]:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود.")

        breakdown = get_user_permissions_breakdown(self.db, user_id)
        return {
            "user_id": user.user_id,
            "username": user.username,
            "role": user.role,
            "role_id": user.role_id,
            "role_code": breakdown["role_code"],
            "effective_permissions": breakdown["effective_permissions"],
            "custom_grants": breakdown["custom_grants"],
            "custom_revocations": breakdown["custom_revocations"],
        }

    def update_user_permissions(
        self, user_id: int, payload: UserPermissionsUpdatePayload, admin_user: User
    ) -> Dict[str, Any]:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود.")

        old_role_id = user.role_id
        old_role_code = user.role

        # 1. Update role if specified
        if payload.role_id is not None:
            target_role = self.db.query(Role).filter(Role.role_id == payload.role_id).first()
            if not target_role:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="الدور المحدد غير موجود.")
            user.role_id = target_role.role_id
            user.role = target_role.role_code

        # 2. Update / replace UserPermission overrides
        all_perms_map = {p.permission_code: p.permission_id for p in self.db.query(Permission).all()}
        existing_ups = {up.permission_id: up for up in self.db.query(UserPermission).filter(UserPermission.user_id == user_id).all()}
        new_requested_pids = set()

        for item in payload.permissions:
            pid = all_perms_map.get(item.permission_code)
            if not pid:
                continue
            new_requested_pids.add(pid)
            if pid in existing_ups:
                up = existing_ups[pid]
                up.is_granted = item.is_granted
                up.granted_by = admin_user.user_id
            else:
                up = UserPermission(
                    user_id=user.user_id,
                    permission_id=pid,
                    is_granted=item.is_granted,
                    granted_by=admin_user.user_id,
                )
                self.db.add(up)

        for pid, up in existing_ups.items():
            if pid not in new_requested_pids:
                self.db.delete(up)

        self.db.commit()
        self.db.refresh(user)

        # Audit log
        from modules.audit_logs.service import AuditLogService
        AuditLogService(self.db).log_activity(
            entity_type="UserPermissions",
            entity_id=user.user_id,
            entity_code=user.username,
            action="UPDATE",
            old_data={"role_id": old_role_id, "role": old_role_code},
            new_data={
                "role_id": user.role_id,
                "role": user.role,
                "overrides_count": len(payload.permissions),
            },
        )

        return self.get_user_permissions(user_id)
