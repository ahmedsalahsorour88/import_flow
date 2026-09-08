/// RBAC Data Models — Permissions, Roles, and User Permission assignments.
/// Mirrors the backend schemas in modules/auth/schemas.py
library;

// ─── Permission ───────────────────────────────────────────────────────────────

class PermissionModel {
  final int permissionId;
  final String permissionCode;
  final String moduleName;
  final String action;
  final String nameEn;
  final String nameAr;
  final String? description;

  const PermissionModel({
    required this.permissionId,
    required this.permissionCode,
    required this.moduleName,
    required this.action,
    required this.nameEn,
    required this.nameAr,
    this.description,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      permissionId: json['permission_id'] as int,
      permissionCode: json['permission_code'] as String,
      moduleName: json['module_name'] as String,
      action: json['action'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      description: json['description'] as String?,
    );
  }
}

// ─── Permission Module Group ───────────────────────────────────────────────────

class PermissionModuleGroup {
  final String moduleName;
  final String moduleNameAr;
  final List<PermissionModel> permissions;

  const PermissionModuleGroup({
    required this.moduleName,
    required this.moduleNameAr,
    required this.permissions,
  });

  factory PermissionModuleGroup.fromJson(Map<String, dynamic> json) {
    return PermissionModuleGroup(
      moduleName: json['module_name'] as String,
      moduleNameAr: json['module_name_ar'] as String,
      permissions: (json['permissions'] as List<dynamic>)
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Role ─────────────────────────────────────────────────────────────────────

class RoleModel {
  final int roleId;
  final String roleCode;
  final String nameEn;
  final String nameAr;
  final String? description;
  final bool isSystemRole;
  final bool isActive;
  final List<String> permissions;

  const RoleModel({
    required this.roleId,
    required this.roleCode,
    required this.nameEn,
    required this.nameAr,
    this.description,
    required this.isSystemRole,
    required this.isActive,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['role_id'] as int,
      roleCode: json['role_code'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      description: json['description'] as String?,
      isSystemRole: json['is_system_role'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
    );
  }
}

// ─── User Effective Permissions ───────────────────────────────────────────────

class UserEffectivePermissions {
  final int userId;
  final String username;
  final String role;
  final int? roleId;
  final String? roleCode;
  final List<String> effectivePermissions;
  final List<String> customGrants;
  final List<String> customRevocations;

  const UserEffectivePermissions({
    required this.userId,
    required this.username,
    required this.role,
    this.roleId,
    this.roleCode,
    required this.effectivePermissions,
    required this.customGrants,
    required this.customRevocations,
  });

  factory UserEffectivePermissions.fromJson(Map<String, dynamic> json) {
    return UserEffectivePermissions(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      role: json['role'] as String? ?? 'OPERATOR',
      roleId: json['role_id'] as int?,
      roleCode: json['role_code'] as String?,
      effectivePermissions: (json['effective_permissions'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
      customGrants: (json['custom_grants'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
      customRevocations: (json['custom_revocations'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
    );
  }
}
