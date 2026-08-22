import os
import tempfile
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Create a temporary test database file for the test session
test_db_file = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
test_db_path = test_db_file.name
test_db_file.close()

os.environ["DATABASE_PATH"] = test_db_path

from database.database import Base, engine, SessionLocal, get_db

@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    # Build all tables in the temporary database
    Base.metadata.create_all(bind=engine)
    yield
    # Cleanup after test session
    try:
        if os.path.exists(test_db_path):
            os.remove(test_db_path)
    except Exception:
        pass
