from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# SQLite Database
DATABASE_URL = "sqlite:///importflow.db"

# Create Engine
engine = create_engine(
    DATABASE_URL,
    echo=False
)

# Create Session
SessionLocal = sessionmaker(
    autoflush=False,
    autocommit=False,
    bind=engine
)

# Base Class for all Models
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()