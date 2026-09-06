from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr


class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    role: str = "OPERATOR"  # ADMIN, MANAGER, OPERATOR


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    """Partial update schema — all fields optional for PATCH."""
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    password: Optional[str] = None  # if provided, will be re-hashed


class UserResponse(UserBase):
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class LoginRequest(BaseModel):
    username_or_email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

