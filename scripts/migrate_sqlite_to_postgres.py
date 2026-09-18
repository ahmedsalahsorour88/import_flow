"""
ImportFlow ERP — SQLite to PostgreSQL Enterprise Migration Utility
===================================================================
Transfers schema, tables, and operational/reference records from
SQLite (`sorour_logistics.db`) to PostgreSQL with transactional integrity.

Usage:
    python scripts/migrate_sqlite_to_postgres.py --target postgresql://postgres:password@localhost:5432/importflow_prod
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List

# Ensure project root in sys.path
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

from sqlalchemy import create_engine, MetaData, Table, select, func, text
from sqlalchemy.orm import sessionmaker

# Import all models to ensure complete SQLAlchemy registry
from database.database import Base, convention

# Import models
import modules.users.model
import modules.audit_logs.model
import modules.import_companies.model
import modules.suppliers.model
import modules.external_service_providers.model
import modules.projects.model
import modules.transport_locations.model
import modules.incoterms.model
import modules.customs_tariff.model
import modules.currencies.model
import modules.import_files.model
import modules.purchase_orders.model
import modules.cargox.model
import modules.import_documentation.model
import modules.shipping_scenarios.model
import modules.customs_consultation.model
import modules.demurrage_detention.model
import modules.warehouse_receiving.model
import modules.financial_settlement.model
import modules.file_closure.model
import modules.cargo_insurance.model
import modules.notifications.model


def migrate(source_sqlite_path: str, target_pg_url: str):
    print("=" * 80)
    print("=== ImportFlow ERP -- SQLite to PostgreSQL Migration ===")
    print("=" * 80)
    print(f"Source (SQLite):     {source_sqlite_path}")
    print(f"Target (PostgreSQL): {target_pg_url}")
    print()

    if not Path(source_sqlite_path).exists():
        print(f"[-] Error: Source database file '{source_sqlite_path}' does not exist.")
        sys.exit(1)

    # 1. Connect to Source (SQLite)
    sqlite_engine = create_engine(f"sqlite:///{Path(source_sqlite_path).as_posix()}", echo=False)
    
    # 2. Connect to Target (PostgreSQL)
    if target_pg_url.startswith("postgres://"):
        target_pg_url = target_pg_url.replace("postgres://", "postgresql://", 1)
        
    pg_engine = create_engine(target_pg_url, echo=False, pool_pre_ping=True)

    try:
        with pg_engine.connect() as conn:
            print("[+] Successfully connected to target PostgreSQL server.")
    except Exception as e:
        print(f"[-] Error connecting to PostgreSQL: {e}")
        print("    Please verify database credentials and ensure PostgreSQL service is active.")
        sys.exit(1)

    # 3. Create all tables in PostgreSQL
    print("[*] Creating schema and tables in PostgreSQL target...")
    Base.metadata.create_all(pg_engine)
    print("[+] All tables created successfully.")

    # 4. Migrate Data in Dependency Order
    sorted_tables: List[Table] = Base.metadata.sorted_tables
    print(f"[*] Beginning migration for {len(sorted_tables)} tables...")

    total_migrated_rows = 0

    with sqlite_engine.connect() as src_conn, pg_engine.connect() as tgt_conn:
        # Disable foreign key constraints during bulk load on Postgres
        try:
            tgt_conn.execute(text("SET session_replication_role = 'replica';"))
            tgt_conn.commit()
        except Exception:
            pass

        for table in sorted_tables:
            table_name = table.name
            
            # Count rows in source
            src_count = src_conn.execute(select(func.count()).select_from(table)).scalar() or 0
            if src_count == 0:
                print(f"    - {table_name:<40} (0 rows - skipped)")
                continue

            # Read source rows
            rows = src_conn.execute(select(table)).mappings().all()
            
            # Write to PostgreSQL target in transaction
            with tgt_conn.begin():
                tgt_conn.execute(table.insert(), [dict(r) for r in rows])

            print(f"    [OK] {table_name:<40} ({src_count} rows copied)")
            total_migrated_rows += src_count

        # Re-enable foreign key constraints
        try:
            with tgt_conn.begin():
                tgt_conn.execute(text("SET session_replication_role = 'origin';"))
        except Exception:
            pass

        # 5. Reset PostgreSQL Sequences for auto-increment primary keys
        print("[*] Synchronizing PostgreSQL sequence values for auto-increment columns...")
        for table in sorted_tables:
            for col in table.primary_key.columns:
                if str(col.type).startswith("INTEGER"):
                    try:
                        seq_query = text(f"""
                            SELECT setval(
                                pg_get_serial_sequence('{table.name}', '{col.name}'),
                                COALESCE(MAX({col.name}), 1)
                            ) FROM {table.name};
                        """)
                        with tgt_conn.begin():
                            tgt_conn.execute(seq_query)
                    except Exception:
                        pass

    print()
    print("=" * 80)
    print(f"[SUCCESS] Migration completed! Total {total_migrated_rows} rows migrated across {len(sorted_tables)} tables.")
    print("To switch the application to PostgreSQL, set in your .env:")
    print(f"DATABASE_URL={target_pg_url}")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(description="Migrate ImportFlow ERP SQLite database to PostgreSQL.")
    parser.add_argument(
        "--source",
        default=os.getenv("DATABASE_PATH", "sorour_logistics.db"),
        help="Path to source SQLite database file (default: sorour_logistics.db)",
    )
    parser.add_argument(
        "--target",
        default=os.getenv("TARGET_DATABASE_URL", ""),
        help="PostgreSQL connection URI (e.g. postgresql://user:password@localhost:5432/importflow_prod)",
    )

    args = parser.parse_args()

    if not args.target:
        print("[-] Error: Target PostgreSQL URL is required. Provide --target <postgresql_uri> or set TARGET_DATABASE_URL in .env.")
        sys.exit(1)

    migrate(args.source, args.target)


if __name__ == "__main__":
    main()
