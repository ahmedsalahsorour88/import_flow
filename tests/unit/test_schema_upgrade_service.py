"""
Unit Tests for SchemaUpgradeService and MasterDataSyncService
"""
import os
import sqlite3
import pytest
from pathlib import Path
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String
from sqlalchemy.orm import sessionmaker

from database.database import Base
from database.schema_upgrade_service import SchemaUpgradeService
from database.master_data_sync_service import MasterDataSyncService
from modules.incoterms.model import Incoterm, CostItem
from modules.currencies.model import Currency
from modules.customs_tariff.model import CustomsTariff
from modules.users.model import User


def test_master_data_sync_service_idempotency(tmp_path):
    """Verifies that running MasterDataSyncService multiple times does not duplicate records."""
    db_file = tmp_path / "test_master_data.db"
    db_url = f"sqlite:///{db_file.as_posix()}"
    engine = create_engine(db_url)
    Base.metadata.create_all(bind=engine)

    Session = sessionmaker(bind=engine)
    session = Session()

    sync_service = MasterDataSyncService(session)

    # 1. First run
    res1 = sync_service.sync_all()
    assert res1["status"] == "synchronized_cleanly"
    incoterms_count_1 = session.query(Incoterm).count()
    currencies_count_1 = session.query(Currency).count()
    tariffs_count_1 = session.query(CustomsTariff).count()

    assert incoterms_count_1 >= 11
    assert currencies_count_1 >= 7
    assert tariffs_count_1 >= 10

    # 2. Second run (Idempotency check)
    res2 = sync_service.sync_all()
    incoterms_count_2 = session.query(Incoterm).count()
    currencies_count_2 = session.query(Currency).count()
    tariffs_count_2 = session.query(CustomsTariff).count()

    assert incoterms_count_2 == incoterms_count_1
    assert currencies_count_2 == currencies_count_1
    assert tariffs_count_2 == tariffs_count_1

    session.close()


def test_schema_upgrade_service_safe_execution(tmp_path):
    """Verifies automated safety backup, dynamic column addition, and upgrade execution."""
    db_file = tmp_path / "test_upgrade.db"
    backups_dir = tmp_path / "backups"

    db_url = f"sqlite:///{db_file.as_posix()}"
    engine = create_engine(db_url)

    # Create an initial table with 2 columns
    meta_v1 = MetaData()
    test_table_v1 = Table(
        "users",
        meta_v1,
        Column("user_id", Integer, primary_key=True),
        Column("username", String(50)),
    )
    meta_v1.create_all(bind=engine)

    # Insert a dummy record
    with engine.connect() as conn:
        conn.execute(test_table_v1.insert().values(user_id=1, username="existing_client_user"))
        conn.commit()

    # Define metadata with full models (including more columns)
    upgrade_res = SchemaUpgradeService.execute_safe_startup_upgrade(
        db_path=str(db_file),
        target_engine=engine,
        metadata=Base.metadata,
        backups_dir=backups_dir,
        max_auto_backups=5,
    )

    assert upgrade_res["status"] == "upgraded_successfully"
    assert upgrade_res["backup_created"] is not None
    assert (backups_dir / upgrade_res["backup_created"]).exists()

    # Verify original user was preserved
    Session = sessionmaker(bind=engine)
    session = Session()
    user = session.query(User).filter(User.username == "existing_client_user").first()
    assert user is not None
    assert user.user_id == 1
    session.close()
