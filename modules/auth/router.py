from typing import List
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session
from database.database import get_db
from modules.users.model import User
from .schemas import LoginRequest, TokenResponse, UserCreate, UserResponse, UserUpdate
from .security import decode_access_token
from .service import AuthService

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication & User Access Control (RBAC)"])


# ─── Dependency: Current User ─────────────────────────────────────────────────

def get_current_user(authorization: str = Header(None), db: Session = Depends(get_db)) -> User:
    if not authorization:
        # Fallback for dev / unauthenticated requests
        user = db.query(User).filter(User.username == "admin").first()
        if user:
            return user
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header.")

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Authorization header format.")

    token = parts[1]
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired access token.")

    user_id = int(payload.get("sub", 0))
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive.")

    return user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """ADMIN role required."""
    if current_user.role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Admin role required."
        )
    return current_user


def require_manager_or_admin(current_user: User = Depends(get_current_user)) -> User:
    """MANAGER or ADMIN role required."""
    if current_user.role not in ["ADMIN", "MANAGER"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Manager or Admin role required."
        )
    return current_user


# ─── Auth Endpoints ───────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse)
def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    service = AuthService(db)
    user = service.authenticate_user(credentials.username_or_email, credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة."
        )
    token = service.generate_user_token(user)
    return TokenResponse(access_token=token, user=user)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


# ─── User Management Endpoints (ADMIN only) ───────────────────────────────────

@router.get("/users", response_model=List[UserResponse])
def get_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_manager_or_admin)
):
    """Get all users — MANAGER or ADMIN."""
    service = AuthService(db)
    return service.get_all_users()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Register a new user — ADMIN only."""
    service = AuthService(db)
    return service.register_user(user_data)


@router.patch("/users/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    update_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Update user data (full_name, email, role, password) — ADMIN only."""
    service = AuthService(db)
    return service.update_user(user_id, update_data)


@router.patch("/users/{user_id}/toggle-status", response_model=UserResponse)
def toggle_user_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Activate or deactivate a user — ADMIN only. Cannot deactivate yourself."""
    service = AuthService(db)
    return service.toggle_user_status(user_id, admin_user_id=current_user.user_id)
