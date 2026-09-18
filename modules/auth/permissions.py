import os
from typing import List, Set, Dict, Any, Optional, Tuple
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session
from database.database import get_db
from modules.users.model import User, Role, Permission, UserPermission, RolePermission
from modules.auth.security import decode_access_token
from settings import ALLOW_DEV_AUTH_BYPASS
from utils.cache_manager import memory_cache


import time
import threading
from sqlalchemy import event

_PERMISSION_CACHE: Dict[Tuple[int, int], tuple] = {}
_CACHE_LOCK = threading.Lock()
_CACHE_TTL_SECONDS = 60.0


def invalidate_permission_cache(user_id: Optional[int] = None) -> None:
    """
    Invalidates the permission cache for a specific user or all users.
    Called when roles, permissions, or user active statuses are updated.
    """
    with _CACHE_LOCK:
        if user_id is not None:
            keys_to_del = [k for k in _PERMISSION_CACHE if k[1] == user_id]
            for k in keys_to_del:
                _PERMISSION_CACHE.pop(k, None)
            memory_cache.delete(f"auth_user:{user_id}")
        else:
            _PERMISSION_CACHE.clear()
            memory_cache.clear_prefix("auth_user:")


@event.listens_for(UserPermission, "after_insert")
@event.listens_for(UserPermission, "after_update")
@event.listens_for(UserPermission, "after_delete")
def _on_user_permission_change(mapper, connection, target):
    invalidate_permission_cache()


@event.listens_for(RolePermission, "after_insert")
@event.listens_for(RolePermission, "after_update")
@event.listens_for(RolePermission, "after_delete")
def _on_role_permission_change(mapper, connection, target):
    invalidate_permission_cache()


@event.listens_for(User, "after_update")
@event.listens_for(User, "after_insert")
@event.listens_for(User, "after_delete")
def _on_user_change(mapper, connection, target):
    invalidate_permission_cache()


def get_user_effective_permissions(db: Session, user_id: int) -> Set[str]:
    """
    Computes effective permissions for a given user according to the Hybrid RBAC algorithm:
    1. If user is inactive -> Empty set (Deny all).
    2. If user is ADMIN -> All permissions in catalog + "*".
    3. Inherit base permissions from assigned Role (if role is active).
    4. Apply custom UserPermission overrides:
       - is_granted == True: Add to effective set (grant exception).
       - is_granted == False: Remove from effective set (explicit revocation).
    
    Optimized with a 60-second in-memory TTL cache to eliminate redundant DB query waterfalls
    during high concurrent user loads.
    """
    bind_id = id(db.get_bind())
    cache_key = (bind_id, user_id)
    now = time.time()
    with _CACHE_LOCK:
        cached = _PERMISSION_CACHE.get(cache_key)
        if cached is not None:
            cached_time, cached_perms = cached
            if now - cached_time < _CACHE_TTL_SECONDS:
                return set(cached_perms)

    user = db.query(User).filter(User.user_id == user_id).first()
    if not user or not user.is_active:
        return set()

    # Admin superuser check
    is_admin = (user.role == "ADMIN")
    if user.assigned_role and user.assigned_role.role_code == "ADMIN":
        is_admin = True

    if is_admin:
        all_perms = {p.permission_code for p in db.query(Permission).all()}
        all_perms.add("*")
        with _CACHE_LOCK:
            _PERMISSION_CACHE[cache_key] = (now, set(all_perms))
        return all_perms

    effective: Set[str] = set()

    # Step 1: Base Role Permissions
    if user.assigned_role and user.assigned_role.is_active:
        for rp in user.assigned_role.role_permissions:
            if rp.permission:
                effective.add(rp.permission.permission_code)

    # Step 2: Custom User-level Overrides
    user_perms = db.query(UserPermission).filter(UserPermission.user_id == user_id).all()
    for up in user_perms:
        if up.permission:
            code = up.permission.permission_code
            if up.is_granted:
                effective.add(code)
            else:
                effective.discard(code)

    with _CACHE_LOCK:
        _PERMISSION_CACHE[cache_key] = (now, set(effective))

    return effective


def get_user_permissions_breakdown(db: Session, user_id: int) -> Dict[str, Any]:
    """Returns detailed role permissions, custom grants, custom revocations, and effective permissions."""
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        return {
            "role_code": None,
            "role_permissions": [],
            "custom_grants": [],
            "custom_revocations": [],
            "effective_permissions": [],
        }

    role_code = user.assigned_role.role_code if user.assigned_role else user.role
    role_perms: List[str] = []
    if user.assigned_role and user.assigned_role.is_active:
        role_perms = [rp.permission.permission_code for rp in user.assigned_role.role_permissions if rp.permission]

    user_perms = db.query(UserPermission).filter(UserPermission.user_id == user_id).all()
    custom_grants: List[str] = []
    custom_revocations: List[str] = []

    for up in user_perms:
        if up.permission:
            if up.is_granted:
                custom_grants.append(up.permission.permission_code)
            else:
                custom_revocations.append(up.permission.permission_code)

    effective = get_user_effective_permissions(db, user_id)

    return {
        "role_code": role_code,
        "role_permissions": sorted(role_perms),
        "custom_grants": sorted(custom_grants),
        "custom_revocations": sorted(custom_revocations),
        "effective_permissions": sorted(list(effective)),
    }


def has_user_permission(db: Session, user: User, permission_code: str) -> bool:
    """Check if the user possesses the specified permission."""
    if not user or not user.is_active:
        return False

    if user.role == "ADMIN":
        return True

    if user.assigned_role and user.assigned_role.role_code == "ADMIN":
        return True

    effective = get_user_effective_permissions(db, user.user_id)
    return ("*" in effective) or (permission_code in effective)


def resolve_user(
    db: Session,
    authorization: Optional[str] = None,
    x_user_role: Optional[str] = None,
    x_user_name: Optional[str] = None,
) -> User:
    """
    Resolves the authenticated user:
    1. If Authorization Bearer token is valid -> returns user.
    2. If x-user-name or x-user-role header is present -> returns matching active user.
    3. If running in desktop/dev mode (no auth header) -> falls back to primary active ADMIN or first active user.
    """
    if authorization:
        parts = authorization.split()
        if len(parts) == 2 and parts[0].lower() == "bearer":
            token = parts[1]
            payload = decode_access_token(token)
            if payload:
                user_id = int(payload.get("sub", 0))
                cache_key = f"auth_user:{user_id}"
                cached = memory_cache.get(cache_key)
                if cached is not None and not cached.get("is_active", True):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="حساب المستخدم معطّل. تواصل مع مدير النظام."
                    )
                user = db.get(User, user_id)
                if user:
                    if not user.is_active:
                        memory_cache.set(cache_key, {"is_active": False}, ttl_seconds=30)
                        raise HTTPException(
                            status_code=status.HTTP_403_FORBIDDEN,
                            detail="حساب المستخدم معطّل. تواصل مع مدير النظام."
                        )
                    memory_cache.set(cache_key, {"is_active": True, "role": user.role, "username": user.username}, ttl_seconds=30)
                    return user
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired access token."
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Authorization header format. Expected 'Bearer <token>'."
            )

    # 2. Desktop client header resolution (restricted by ALLOW_DEV_AUTH_BYPASS)
    if not ALLOW_DEV_AUTH_BYPASS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header.",
        )

    if x_user_name:
        user = db.query(User).filter(User.username == x_user_name, User.is_active == True).first()
        if user:
            return user

    if x_user_role:
        user = db.query(User).filter(User.role == x_user_role.upper(), User.is_active == True).first()
        if user:
            return user

    # 3. Fallback to active admin for desktop ERP environment
    admin = db.query(User).filter(User.is_active == True, User.role == "ADMIN").first()
    if admin:
        return admin

    first_user = db.query(User).filter(User.is_active == True).first()
    if first_user:
        return first_user

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Missing Authorization header.",
    )


def require_permission(permission_code: str):
    """
    FastAPI dependency factory enforcing granular RBAC permissions.
    Supports JWT Bearer authorization and desktop client headers.
    """
    def dependency(
        authorization: Optional[str] = Header(None),
        x_user_role: Optional[str] = Header(None),
        x_user_name: Optional[str] = Header(None),
        db: Session = Depends(get_db)
    ) -> User:
        user = resolve_user(
            db,
            authorization=authorization,
            x_user_role=x_user_role,
            x_user_name=x_user_name
        )

        if not has_user_permission(db, user, permission_code):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Permission '{permission_code}' required."
            )

        return user

    return dependency
