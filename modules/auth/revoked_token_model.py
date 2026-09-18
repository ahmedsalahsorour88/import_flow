from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, Integer, String, Index
from database.database import Base


class RevokedToken(Base):
    __tablename__ = "revoked_tokens"

    id = Column(Integer, primary_key=True, autoincrement=True)
    token_hash = Column(String(64), unique=True, nullable=False, index=True)
    user_id = Column(Integer, nullable=True, index=True)
    revoked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime, nullable=False, index=True)

    __table_args__ = (
        Index("ix_revoked_tokens_hash_exp", "token_hash", "expires_at"),
    )
