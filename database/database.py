from sqlalchemy import MetaData, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


# SQLite Database
DATABASE_URL = "sqlite:///./importflow.db"


# Create Engine
engine = create_engine(
    DATABASE_URL,
    echo=False,
    connect_args={
        "check_same_thread": False
    }
)


# Create Session
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Base Class for all Models with standard naming convention
convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}
metadata = MetaData(naming_convention=convention)
Base = declarative_base(metadata=metadata)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()