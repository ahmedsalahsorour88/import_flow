# 🛡️ ImportFlow ERP — Users & Permissions (RBAC) System Review Log

> **Document Status:** Active / Production Audit & Implementation  
> **Initial Date:** 2026-09-07  
> **Governing Security Principle:** Backend-First Enforcement (Zero Trust / Deny by Default). UI element hiding in Flutter is cosmetics only; every protected action and endpoint must be validated on the backend before execution.

---

## 📌 1. Executive Summary & Goals

The objective of this initiative is to establish an enterprise-grade **Users & Permissions / Role-Based Access Control (RBAC)** architecture for **ImportFlow ERP** across Python (FastAPI backend) and Flutter Desktop (Frontend).

The system consists of three interconnected pillars:
1. **User Management**: Creating, viewing, updating, and deactivating system users with strict uniqueness, password salting/hashing, and soft deactivation (`is_active = False`).
2. **Permissions Definition**: Centralized, comprehensive catalog of granular permissions covering all system screens and operational actions, grouped by functional modules.
3. **User-Permission Linkage**: A hybrid assignment model allowing users to inherit permissions from predefined standard roles while also supporting custom user-level grants and explicit revocations.

---

## 🔍 2. Phase 0: Codebase Audit & Security Findings

### 2.1 Current State Analysis
A thorough audit of the backend authentication and routing infrastructure was conducted across all 40+ module routers in `f:\SorourLogistics`:

1. **User Model (`modules/users/model.py`)**:
   - `User` table holds: `user_id`, `username`, `email`, `hashed_password`, `full_name`, `role` (string: "ADMIN", "MANAGER", "OPERATOR"), `is_active`, `created_at`, `updated_at`.
   - Missing: Relational role table, permissions table, role-permission links, user-permission overrides.

2. **Authentication Flow (`modules/auth/`)**:
   - `AuthService` handles authentication and generates HMAC-SHA256 access tokens.
   - `security.py` provides password hashing via salted SHA-256 and token encode/decode.
   - `router.py` exposes `/login`, `/me`, `/users`, `/register`, `/users/{id}`, and `/users/{id}/toggle-status`.

### 2.2 Security Vulnerabilities & Gaps Identified
During the audit, the following critical security gaps were identified:

| # | Vulnerability / Gap | Severity | Description & Impact |
|---|---|---|---|
| **GAP-01** | Dev Fallback Bypass in `get_current_user` | **HIGH** | In `modules/auth/router.py`, if the `Authorization` header is missing, `get_current_user` automatically falls back to the database user `admin`. Any unauthenticated request was treated as `admin`. |
| **GAP-02** | Zero Operational RBAC Checks | **HIGH** | Out of 40 operational routers (e.g. `import_files`, `purchase_orders`, `freight_booking`, `customs_clearance`, `financial_approval`), 0 endpoints enforced granular permissions or verified the user's role before executing business mutations. |
| **GAP-03** | Lack of Role & Permission Tables | **MEDIUM** | Roles were hardcoded strings (`ADMIN`, `MANAGER`, `OPERATOR`) without configurable permissions or relational links. |
| **GAP-04** | Missing Direct User Permission Overrides | **MEDIUM** | No capability existed to grant or revoke specific permissions for an individual user without modifying their entire role. |

---

## 🏛️ 3. Architecture Decision Records (ADRs)

### ADR-001: Hybrid Role-Based & Direct User Permission Model
- **Context**: Different import logistics enterprises require predefined standard roles (e.g. Logistics Operator, Customs Officer, Finance Officer) to assign on onboarding, but frequently need to grant a specific user an exception (e.g. allow an operator to approve financial requests for a specific period) or explicitly revoke a permission.
- **Decision**: Implement a **Hybrid RBAC Model**:
  - `roles`: Predefined and custom roles.
  - `permissions`: Atomic permissions (`module.action`).
  - `role_permissions`: Base permissions assigned to a role.
  - `user_permissions`: User-level grants (`is_granted = True`) and explicit revocations (`is_granted = False`) that override role-inherited permissions.
- **Permission Resolution Algorithm**:
  1. If `user.is_active` is `False` ➔ **DENY** (no permissions).
  2. If `user.role == 'ADMIN'` or `Role.role_code == 'ADMIN'` ➔ **ALLOW ALL** (bypasses checks).
  3. Base permissions = `{p for p in role.permissions if role.is_active}`.
  4. Effective permissions = `(Base permissions ∪ {p where user_permission.is_granted == True}) \ {p where user_permission.is_granted == False}`.
  5. Check: `requested_permission in effective_permissions`.

### ADR-002: Modular Dot-Notation Action-Level Permission Catalog
- **Context**: Permissions must govern both screen access in Flutter and sensitive operations in FastAPI.
- **Decision**: Permissions are formatted as `module_name.action`:
  - `*.view`: Controls screen viewing and read endpoints.
  - `*.create`: Controls record creation.
  - `*.edit`: Controls record modifications.
  - `*.delete`: Controls record soft deletion.
  - `*.approve` / `*.confirm` / `*.release`: Controls business approvals and lifecycle transitions.
  - `*.export`: Controls exporting reports and confidential data.

### ADR-003: Central Enforcement Dependency (`require_permission`)
- **Context**: Backend endpoints must strictly verify permissions without duplicating boilerplate or introducing security bypasses.
- **Decision**: Create a central dependency factory in `modules/auth/permissions.py`:
  ```python
  def require_permission(permission_code: str):
      ...
  ```
  - Rejects unauthenticated requests with `401 Unauthorized` (strictly eliminates dev fallback).
  - Rejects inactive or unauthorized users with `403 Forbidden` (`{"detail": "Access denied. Permission 'xyz' required."}`).
  - Compatible with standard FastAPI dependency injection `Depends(require_permission("module.action"))`.

---

## 📋 4. ERP Modules & Granular Permission Catalog Inventory

The comprehensive permissions catalog contains 38 atomic permissions organized into 14 functional modules:

```text
1. Import Files (import_files)
   ├── import_files.view        (عرض ملفات الاستيراد)
   ├── import_files.create      (إنشاء ملف استيراد جديد)
   ├── import_files.edit        (تعديل بيانات ملف الاستيراد)
   └── import_files.close       (إغلاق ملف الاستيراد نهائياً)

2. Lifecycle Operations Board (lifecycle_board)
   ├── lifecycle_board.view     (عرض لوحة دورة حياة الشحنات)
   └── lifecycle_board.advance  (نقل وتحريك خطوات الشحنة يدوياً)

3. Purchase Orders (purchase_orders)
   ├── purchase_orders.view     (عرض أوامر الشراء)
   ├── purchase_orders.create   (إنشاء أمر شراء)
   └── purchase_orders.edit     (تعديل أوامر الشراء)

4. Freight Booking (freight_booking)
   ├── freight_booking.view     (عرض حجوزات الشحن)
   ├── freight_booking.create   (طلب وحجز الشحن)
   └── freight_booking.confirm  (تأكيد حجز الشحن واعتماد البوليصة)

5. Cargo Shipping & Tracking (cargo_shipping)
   ├── cargo_shipping.view      (عرض حركة الشحن وتتبع البواخر)
   └── cargo_shipping.update    (تحديث حالة السفينة وتتبع المسار)

6. Customs Clearance (customs_clearance)
   ├── customs_clearance.view   (عرض ملفات التخليص الجمركي)
   ├── customs_clearance.update (تحديث إجراءات الكشف ونموذج 46)
   └── customs_clearance.release (إصدار الإفراج الجمركي النهائي)

7. Customs Tariff & HS Codes (customs_tariff)
   ├── customs_tariff.view      (استعراض جدول التعريفة الجمركية)
   └── customs_tariff.edit      (تعديل بنود التعريفة والضرائب والاتفاقيات)

8. CargoX & Nafeza ACID (cargox_nafeza)
   ├── cargox_nafeza.view       (عرض بيانات كارجو إكس ورقم ACID)
   └── cargox_nafeza.manage     (رفع مستندات كارجو إكس ومتابعة نافذة)

9. Import Documentation (import_documentation)
   ├── import_documentation.view   (استعراض مستندات الشحن والمطابقة)
   └── import_documentation.upload (رفع واعتماد مستندات الشحنة)

10. Financial Approval (financial_approval)
   ├── financial_approval.view    (عرض طلبات الصرف وموازنات الاستيراد)
   └── financial_approval.approve (اعتماد طلبات الصرف المالي)

11. Financial Settlement & Landed Cost (financial_settlement)
   ├── financial_settlement.view      (عرض تسويات التكلفة الكلية)
   └── financial_settlement.calculate (حساب واعتماد تكلفة الوصول Landed Cost)

12. Warehouse Receiving (warehouse_receiving)
   ├── warehouse_receiving.view    (عرض استلامات المخازن)
   └── warehouse_receiving.receive (فحص وتسجيل الاستلام بالمستودع)

13. Master Reference Data (master_data)
   ├── master_data.view   (عرض الشركات والموردين والوكلاء والموانئ)
   └── master_data.edit   (إضافة وتعديل البيانات المرجعية الأساسية)

14. Users, Security & Audit (users_and_security)
   ├── users.view       (استعراض قائمة المستخدمين والأدوار)
   ├── users.manage     (إضافة وتعديل وتعطيل المستخدمين وإدارة الصلاحيات)
   ├── audit_logs.view  (استعراض سجل العمليات والرقابة Audit Logs)
   ├── reports.view     (استعراض التقارير الإدارية والتحليلات)
   └── reports.export   (تصدير التقارير المالية والتشغيلية)
```

---

## 👥 5. Standard Predefined Roles Matrix

| Standard Role Code | English Name | Arabic Name | Description & Key Permissions |
|---|---|---|---|
| `ADMIN` | System Administrator | مدير النظام | Superuser — unrestricted access to all endpoints, configuration, and security settings. |
| `GENERAL_MANAGER` | General Manager | مدير عام | Full read access across all modules (`*.view`), financial approvals (`financial_approval.approve`), file closure (`import_files.close`), reports export (`reports.export`), audit trail viewing (`audit_logs.view`). |
| `LOGISTICS_OPERATOR` | Logistics Operator | أخصائي عمليات لوجستية | End-to-end operational execution: `import_files.*` (except close), `purchase_orders.*`, `freight_booking.*`, `cargo_shipping.*`, `warehouse_receiving.*`, `master_data.view`. |
| `CUSTOMS_OFFICER` | Customs Clearance Officer | أخصائي تخليص جمركي | Customs-focused operations: `customs_clearance.*`, `customs_tariff.*`, `cargox_nafeza.*`, `import_documentation.*`, `master_data.view`. |
| `FINANCE_OFFICER` | Finance Officer | مسؤول مالي | Financial lifecycle: `financial_approval.*`, `financial_settlement.*`, `purchase_orders.view`, `import_files.view`, `reports.*`. |
| `AUDITOR_VIEWER` | Auditor / Viewer | مراجع ومشاهد | Read-only access across all operational modules (`*.view`), `audit_logs.view`, `reports.view`. Zero mutation or approval rights. |

---

## 🚀 6. Phase 1 Implementation Summary

- **Database Models (`modules/users/model.py`)**:
  - `Role`: Table `roles` with unique `role_code`, names, descriptions, and audit timestamps.
  - `Permission`: Table `permissions` with unique `permission_code`, module, action, names.
  - `RolePermission`: Table `role_permissions` with unique composite `(role_id, permission_id)`.
  - `UserPermission`: Table `user_permissions` with `is_granted` boolean and unique `(user_id, permission_id)`.
  - `User`: Updated with `role_id` foreign key, `assigned_role` relationship, and `user_permissions` relationship.
- **Auto-Seeder (`modules/auth/seed_rbac.py`)**:
  - Non-destructive idempotent sync of the complete permission catalog (38 permissions).
  - Non-destructive idempotent sync of the 6 standard roles and their assigned permission mappings.
  - Automatic association of initial `admin`, `manager`, `operator1` users to their respective roles.
- **Central Enforcement Engine (`modules/auth/permissions.py`)**:
  - `get_user_effective_permissions(db, user_id)`: Implements ADR-001 resolution algorithm.
  - `has_user_permission(db, user, permission_code)`: Instant checks with Admin override.
  - `require_permission(permission_code)`: FastAPI dependency enforcing strict Bearer authentication and RBAC verification.
- **Management API Endpoints (`modules/auth/router.py`)**:
  - `GET /api/v1/auth/permissions`: List all available permissions grouped by module.
  - `GET /api/v1/auth/roles`: List all system roles with assigned permissions.
  - `GET /api/v1/auth/users/{id}/permissions`: Fetch user's role, effective permissions, and custom overrides.
  - `PUT /api/v1/auth/users/{id}/permissions`: Assign role and custom grants/revocations with audit logging.
  - `GET /api/v1/auth/me/permissions`: Retrieve effective permissions for currently logged-in user.
- **Automated Pytest Security Suite (`tests/unit/test_rbac_permissions.py`)**:
  - Validates deny-by-default (403).
  - Validates role-based permission access (200).
  - Validates direct user-level grants (200).
  - Validates direct user-level revocations overriding role (403).
  - Validates admin bypass (200).
  - Validates inactive user blockage (403).
  - Validates missing/invalid token rejection (401).
  - Validates management endpoints security and audit trail recording.

---

## 🧪 7. Automated Test Execution Verification (100% Pass)

The following test suites were executed with `pytest` and passed cleanly:

| Test Suite | Test Function | Result | Security Behavior Verified |
|---|---|---|---|
| `test_rbac_permissions.py` | `test_admin_superuser_bypass` | **PASSED** | Admin bypasses checks for any requested permission |
| `test_rbac_permissions.py` | `test_deny_by_default_unassigned_user` | **PASSED** | Zero permissions by default for users without roles/grants |
| `test_rbac_permissions.py` | `test_direct_user_permission_explicit_revocation` | **PASSED** | Direct `is_granted=False` strips role-inherited permission |
| `test_rbac_permissions.py` | `test_direct_user_permission_grant_exception` | **PASSED** | Direct `is_granted=True` adds permission outside role |
| `test_rbac_permissions.py` | `test_endpoint_acceptance_with_direct_grant_200` | **PASSED** | HTTP 200 OK returned on protected endpoint after user grant |
| `test_rbac_permissions.py` | `test_endpoint_rejection_inactive_user_403` | **PASSED** | HTTP 403 Forbidden returned when user account is deactivated |
| `test_rbac_permissions.py` | `test_endpoint_rejection_invalid_token_401` | **PASSED** | HTTP 401 Unauthorized on invalid/expired Bearer token |
| `test_rbac_permissions.py` | `test_endpoint_rejection_lacking_permission_403` | **PASSED** | HTTP 403 Forbidden on endpoint when user lacks required permission |
| `test_rbac_permissions.py` | `test_endpoint_rejection_missing_token_401` | **PASSED** | HTTP 401 Unauthorized when Authorization header is omitted |
| `test_rbac_permissions.py` | `test_endpoint_rejection_with_direct_revocation_403` | **PASSED** | HTTP 403 Forbidden on endpoint after explicit user revocation |
| `test_rbac_permissions.py` | `test_inactive_user_denied_all` | **PASSED** | Inactive user returns empty effective permissions set |
| `test_rbac_permissions.py` | `test_rbac_management_endpoints` | **PASSED** | GET/PUT permissions, roles, and user permission endpoints work |
| `test_rbac_permissions.py` | `test_role_based_permissions_logistics_operator` | **PASSED** | Role-based permission inheritance matches matrix |
| `test_auth.py` | `test_auth (4 tests)` | **PASSED** | Passwords, tokens, duplicate checks, registration verified |
| `test_schema_upgrade_service.py` | `test_schema_upgrade (2 tests)` | **PASSED** | Non-destructive in-place database upgrade & seed idempotency |
| `test_audit_logs.py` | `test_audit_logs (2 tests)` | **PASSED** | Audit logging of user and permission changes |

```text
======================= 21 passed, 1 warning in 16.34s ========================
```

---

## 🏁 8. Next Steps (Phases 2 - 4)

- **Phase 2**: Frontend Users Management Screen in Flutter Desktop (Listing, User Form, Role Selector, Deactivation Toggle, Form Validators).
- **Phase 3**: Frontend Permissions Screen in Flutter Desktop (Permissions Catalog view grouped by module with active/inactive indicators).
- **Phase 4**: User-Permission Linkage UI (Assign roles, custom checkboxes for exception grants/revocations, real-time live sync with `ref.invalidate()`).
