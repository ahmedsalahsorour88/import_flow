"""
Sorour Logistics ERP — Enterprise User Provisioning & RBAC Manager
==================================================================
Production CLI tool for IT Administrators to provision, assign roles,
reset passwords, and audit staff accounts safely.
"""
import os
import sys
import secrets
import argparse
from datetime import datetime, timezone
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR))

from database.database import SessionLocal
from modules.users.model import User, Role
from modules.auth.security import hash_password, validate_password_strength
from utils.cache_manager import memory_cache

ROLE_MAPPING = {
    "ADMIN": (1, "مدير النظام (كامل الصلاحيات)"),
    "MANAGER": (2, "مدير العمليات واللوجستيات (اعتمادات وتفويض)"),
    "OPERATOR": (3, "أخصائي استيراد ومتابعة شحنات"),
    "CUSTOMS_BROKER": (4, "مخلص جمركي (شهادة 46 والإفراج وسداد الرسوم)"),
    "FINANCE": (5, "مدير مالي ومحاسب (تكلفة الوصول والتسويات والفواتير)"),
    "WAREHOUSE": (6, "أمين مخزن (إذن الإضافة والفحص الفني والعجز والتالف)"),
}


def list_users():
    db = SessionLocal()
    try:
        users = db.query(User).order_by(User.user_id).all()
        print("==================================================================================================")
        print("                  Sorour Logistics ERP — Active System Users & Roles                              ")
        print("==================================================================================================")
        print(f"{'ID':<4} | {'Username':<15} | {'Role':<15} | {'Status':<8} | {'Full Name':<25} | {'Email'}")
        print("-" * 98)
        for u in users:
            status = "Active" if u.is_active else "Disabled"
            print(f"{u.user_id:<4} | {u.username:<15} | {u.role:<15} | {status:<8} | {u.full_name:<25} | {u.email}")
        print("==================================================================================================")
        print(f"Total Users: {len(users)}")
    finally:
        db.close()


def create_user(username, email, full_name, role, password=None):
    db = SessionLocal()
    try:
        existing = db.query(User).filter((User.username == username) | (User.email == email)).first()
        if existing:
            print(f"[ERROR] A user with username '{username}' or email '{email}' already exists.")
            return False

        if not password:
            # Generate a secure 12-char random enterprise password
            password = secrets.token_urlsafe(8) + "A1!"
            generated = True
        else:
            generated = False

        # Validate password strength
        valid, msg = validate_password_strength(password)
        if not valid:
            print(f"[ERROR] Password strength validation failed: {msg}")
            return False

        role_upper = role.upper()
        if role_upper not in ROLE_MAPPING:
            print(f"[ERROR] Invalid role '{role}'. Valid choices: {', '.join(ROLE_MAPPING.keys())}")
            return False

        role_id, role_desc = ROLE_MAPPING[role_upper]

        new_user = User(
            username=username.strip().lower(),
            email=email.strip().lower(),
            full_name=full_name.strip(),
            hashed_password=hash_password(password),
            role=role_upper,
            role_id=role_id,
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        db.add(new_user)
        db.commit()

        print("================================================================================")
        print(f"[SUCCESS] Staff User Account Created Successfully!")
        print(f" - Username:  {new_user.username}")
        print(f" - Full Name: {new_user.full_name}")
        print(f" - Role:      {new_user.role} ({role_desc})")
        print(f" - Email:     {new_user.email}")
        if generated:
            print(f" - Generated Password: {password}")
            print("   (Please provide this password to the employee and have them change it upon first login)")
        else:
            print(" - Password:  [Configured securely with PBKDF2 hash]")
        print("================================================================================")
        return True
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to create user: {e}")
        return False
    finally:
        db.close()


def reset_password(username, new_password):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == username.strip().lower()).first()
        if not user:
            print(f"[ERROR] User '{username}' not found.")
            return False

        valid, msg = validate_password_strength(new_password)
        if not valid:
            print(f"[ERROR] Password strength validation failed: {msg}")
            return False

        user.hashed_password = hash_password(new_password)
        user.updated_at = datetime.now(timezone.utc)
        db.commit()
        memory_cache.delete(f"auth_user:{user.user_id}")

        print(f"[SUCCESS] Password for user '{username}' has been updated and securely hashed.")
        return True
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to reset password: {e}")
        return False
    finally:
        db.close()


def assign_role(username, new_role):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == username.strip().lower()).first()
        if not user:
            print(f"[ERROR] User '{username}' not found.")
            return False

        role_upper = new_role.upper()
        if role_upper not in ROLE_MAPPING:
            print(f"[ERROR] Invalid role '{new_role}'. Choices: {', '.join(ROLE_MAPPING.keys())}")
            return False

        role_id, role_desc = ROLE_MAPPING[role_upper]
        user.role = role_upper
        user.role_id = role_id
        user.updated_at = datetime.now(timezone.utc)
        db.commit()
        memory_cache.delete(f"auth_user:{user.user_id}")

        print(f"[SUCCESS] User '{username}' assigned to role: {role_upper} ({role_desc})")
        return True
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to assign role: {e}")
        return False
    finally:
        db.close()


def set_user_active(username, is_active: bool):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == username.strip().lower()).first()
        if not user:
            print(f"[ERROR] User '{username}' not found.")
            return False

        if user.username == "admin" and not is_active:
            print("[ERROR] Primary system 'admin' user cannot be deactivated.")
            return False

        user.is_active = is_active
        user.updated_at = datetime.now(timezone.utc)
        db.commit()
        memory_cache.delete(f"auth_user:{user.user_id}")

        action_str = "Activated" if is_active else "Deactivated (Disabled)"
        print(f"[SUCCESS] User '{username}' account status changed to: {action_str}")
        return True
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to change account status: {e}")
        return False
    finally:
        db.close()


def delete_user(username):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == username.strip().lower()).first()
        if not user:
            print(f"[ERROR] User '{username}' not found.")
            return False

        if user.username == "admin":
            print("[ERROR] Primary system 'admin' user cannot be deleted.")
            return False

        user_id = user.user_id
        db.delete(user)
        db.commit()
        memory_cache.delete(f"auth_user:{user_id}")
        print(f"[SUCCESS] User account '{username}' has been deleted.")
        return True
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to delete user: {e}")
        return False
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Sorour Logistics ERP User Provisioning & RBAC Manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # list
    subparsers.add_parser("list", help="List all users and roles")

    # create
    create_p = subparsers.add_parser("create", help="Create a new staff user account")
    create_p.add_argument("--username", required=True, help="Unique username")
    create_p.add_argument("--email", required=True, help="User email address")
    create_p.add_argument("--name", required=True, help="Full Name")
    create_p.add_argument("--role", required=True, choices=list(ROLE_MAPPING.keys()), help="Assigned RBAC role")
    create_p.add_argument("--password", help="Password (if omitted, a secure password is generated)")

    # reset-password
    pwd_p = subparsers.add_parser("reset-password", help="Reset password for an existing user")
    pwd_p.add_argument("--username", required=True, help="Target username")
    pwd_p.add_argument("--password", required=True, help="New password meeting enterprise complexity")

    # assign-role
    role_p = subparsers.add_parser("assign-role", help="Change role for a user")
    role_p.add_argument("--username", required=True, help="Target username")
    role_p.add_argument("--role", required=True, choices=list(ROLE_MAPPING.keys()), help="New role to assign")

    # activate / deactivate
    act_p = subparsers.add_parser("activate", help="Activate a user account")
    act_p.add_argument("username", help="Username to activate")

    deact_p = subparsers.add_parser("deactivate", help="Deactivate (disable) a user account")
    deact_p.add_argument("username", help="Username to deactivate")

    # delete
    del_p = subparsers.add_parser("delete", help="Permanently delete a user account")
    del_p.add_argument("username", help="Username to delete")

    args = parser.parse_args()

    if args.command == "list":
        list_users()
    elif args.command == "create":
        create_user(args.username, args.email, args.name, args.role, args.password)
    elif args.command == "reset-password":
        reset_password(args.username, args.password)
    elif args.command == "assign-role":
        assign_role(args.username, args.role)
    elif args.command == "activate":
        set_user_active(args.username, True)
    elif args.command == "deactivate":
        set_user_active(args.username, False)
    elif args.command == "delete":
        delete_user(args.username)


if __name__ == "__main__":
    main()
