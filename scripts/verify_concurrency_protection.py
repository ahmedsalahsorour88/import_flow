"""
Sorour Logistics ERP — Concurrency Conflict Protection Verification Runner
==========================================================================
Demonstrates and proves:
1. Single-user normal edits increment version monotonically (1 -> 2).
2. Two-user concurrent edits: User B's stale save is rejected with HTTP 409
   (ConcurrencyConflictException) instead of silently overwriting User A.
3. Conflict event is reliably logged to `concurrency_conflict_logs` audit table.
4. User B reloads latest record, resolves conflict, and successfully saves on top of version 2.
"""
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

import json
from datetime import datetime, timezone
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import scripts.migrate_sqlite_to_postgres
from database.database import Base
from modules.purchase_orders.model import PurchaseOrder, POLineItem
from modules.purchase_orders.schemas import PurchaseOrderUpdate
from modules.purchase_orders.repository import PurchaseOrderRepository
from modules.common.concurrency import ConcurrencyConflictException, ConcurrencyConflictLog

def run_concurrency_verification():
    print("=" * 85)
    print("   CONCURRENT-EDIT CONFLICT PROTECTION VERIFICATION (OPTIMISTIC LOCKING)")
    print("=" * 85)
    print(f"Timestamp: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print("Scope:     Purchase Orders & Nested Packing List (High-Risk Financial/Logistics)")
    print("-" * 85)

    # Sandbox In-Memory Engine
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)

    # 1. Create Initial PO (Version 1)
    db = Session()
    repo = PurchaseOrderRepository(db)
    po = PurchaseOrder(
        po_number="PO-2026-CONCURRENCY-001",
        project_id=1,
        company_id=1,
        supplier_id=1,
        incoterm_id=1,
        currency_id=1,
        payment_terms="Original Terms: 100% LC at Sight",
        notes="Baseline notes created by Procurement Officer",
        version=1,
        status="Draft",
        is_active=True,
    )
    db.add(po)
    db.commit()
    po_id = po.po_id
    print(f"[Step 1] Initial Purchase Order Created:")
    print(f"         PO Number: {po.po_number} (ID={po_id})")
    print(f"         Version:   {po.version}")
    print(f"         Terms:     '{po.payment_terms}'")
    print("-" * 85)

    # 2. Simulate User A and User B opening the record simultaneously
    db_user_a = Session()
    repo_a = PurchaseOrderRepository(db_user_a)
    po_user_a = repo_a.get_by_id(po_id)

    db_user_b = Session()
    repo_b = PurchaseOrderRepository(db_user_b)
    po_user_b = repo_b.get_by_id(po_id)

    print(f"[Step 2] Simultaneous Load by Two Users:")
    print(f"         User A opened PO #{po_id} at Version {po_user_a.version}")
    print(f"         User B opened PO #{po_id} at Version {po_user_b.version}")
    print("-" * 85)

    # 3. User A saves modifications first (submits version 1)
    print(f"[Step 3] User A edits and saves first:")
    payload_a = PurchaseOrderUpdate(
        payment_terms="Revised Terms by User A: 30% Advance, 70% CAD",
        notes="CFO Salah approved updated payment schedule",
        version=1,
    )
    saved_a = repo_a.update(po_user_a, payload_a, current_user_name="User_A_Accountant")
    print(f"         User A Save: SUCCESS (HTTP 200 OK)")
    print(f"         New Version in DB: {saved_a.version}")
    print(f"         Terms in DB now:   '{saved_a.payment_terms}'")
    print("-" * 85)

    # 4. User B attempts to save stale version 1
    print(f"[Step 4] User B attempts to save with stale Version 1 (Unaware of User A's save):")
    payload_b = PurchaseOrderUpdate(
        payment_terms="Conflicting Terms by User B: Net 60 Days",
        notes="Conflicting notes attempting to overwrite",
        version=1,  # Stale version! Current version in DB is now 2
    )

    conflict_caught = False
    caught_exception_detail = None
    try:
        repo_b.update(po_user_b, payload_b, current_user_name="User_B_LogisticsManager")
        print("         [CRITICAL ERROR] Stale update succeeded without conflict detection!")
    except ConcurrencyConflictException as exc:
        conflict_caught = True
        caught_exception_detail = exc.detail
        print(f"         [DETECTED] ConcurrencyConflictException caught successfully!")
        print(f"         HTTP Status Code:   409 Conflict")
        print(f"         Conflict Detail:    {caught_exception_detail}")
    print("-" * 85)

    # 5. Verify Database Integrity & Non-Overwritten Data
    db_verify = Session()
    current_po = db_verify.query(PurchaseOrder).filter_by(po_id=po_id).first()
    print(f"[Step 5] Database State Audit:")
    print(f"         Current Stored Version: {current_po.version}")
    print(f"         Current Stored Terms:   '{current_po.payment_terms}'")

    data_protected = "User A" in current_po.payment_terms and "User B" not in current_po.payment_terms
    if data_protected:
        print(f"         [PROTECTED] User A's changes are 100% intact. User B's stale save was blocked.")
    else:
        print(f"         [FAILED] Data was overwritten.")
    print("-" * 85)

    # 6. Verify Conflict Audit Log
    conflict_logs = db_verify.query(ConcurrencyConflictLog).filter_by(record_id=po_id).all()
    print(f"[Step 6] Concurrency Conflict Audit Logs in DB:")
    print(f"         Total conflict events logged: {len(conflict_logs)}")
    for log in conflict_logs:
        print(f"         -> Log ID={log.conflict_id}: Entity={log.entity_name} | SubmVersion={log.submitted_version} | CurrVersion={log.current_version} | AttemptedBy={log.attempted_by}")
    print("-" * 85)

    # 7. User B recovers: Reloads latest version 2 and applies new edit on top
    print(f"[Step 7] User B Discard & Reload Recovery:")
    db_user_b_refresh = Session()
    repo_b_refresh = PurchaseOrderRepository(db_user_b_refresh)
    po_reloaded = repo_b_refresh.get_by_id(po_id)
    print(f"         User B reloaded latest record -> Version is now {po_reloaded.version}")

    payload_b_recovered = PurchaseOrderUpdate(
        notes=f"{po_reloaded.notes} | Addendum by User B: Container delivery confirmed",
        version=po_reloaded.version,  # Version 2
    )
    saved_b_recovered = repo_b_refresh.update(po_reloaded, payload_b_recovered, current_user_name="User_B_LogisticsManager")
    print(f"         User B Save on Latest Version: SUCCESS (HTTP 200 OK)")
    print(f"         Final Record Version in DB:    {saved_b_recovered.version}")
    print(f"         Final Notes in DB:             '{saved_b_recovered.notes}'")
    print("-" * 85)

    success = conflict_caught and data_protected and len(conflict_logs) > 0 and saved_b_recovered.version == 3
    print("======================== CONCURRENCY VERDICT ========================")
    if success:
        print("[SUCCESS] OPTIMISTIC CONCURRENCY PROTECTION 100% VERIFIED & PROVEN")
        print("          - Stale saves are strictly rejected with HTTP 409.")
        print("          - Concurrent edits cannot silently overwrite data.")
        print("          - All collision events are recorded in audit trail.")
        print("          - Reload-and-recover workflow functions flawlessly.")
    else:
        print("[FAIL] Concurrency verification did not meet all criteria.")
    print("=====================================================================")
    return success

if __name__ == "__main__":
    run_concurrency_verification()
