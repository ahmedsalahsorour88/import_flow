import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/rbac_models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class RbacState {
  final List<PermissionModuleGroup> permissionGroups;
  final List<RoleModel> roles;
  final bool isLoading;
  final String? error;

  const RbacState({
    this.permissionGroups = const [],
    this.roles = const [],
    this.isLoading = false,
    this.error,
  });

  RbacState copyWith({
    List<PermissionModuleGroup>? permissionGroups,
    List<RoleModel>? roles,
    bool? isLoading,
    String? error,
  }) {
    return RbacState(
      permissionGroups: permissionGroups ?? this.permissionGroups,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Flat list of all permissions across all module groups.
  List<PermissionModel> get allPermissions =>
      permissionGroups.expand((g) => g.permissions).toList();
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RbacNotifier extends StateNotifier<RbacState> {
  final Dio _dio;
  CancelToken? _cancelToken;

  RbacNotifier(this._dio) : super(const RbacState());

  @override
  void dispose() {
    _cancelToken?.cancel('RbacNotifier disposed');
    super.dispose();
  }

  /// Fetch roles and permissions catalog from backend.
  Future<void> fetchRbacData() async {
    _cancelToken?.cancel('New fetch requested');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dio.get('${ApiConstants.auth}/permissions', cancelToken: _cancelToken),
        _dio.get('${ApiConstants.auth}/roles', cancelToken: _cancelToken),
      ]);

      final permGroups = (results[0].data as List<dynamic>)
          .map((g) => PermissionModuleGroup.fromJson(g as Map<String, dynamic>))
          .toList();

      final roles = (results[1].data as List<dynamic>)
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        permissionGroups: permGroups,
        roles: roles,
        isLoading: false,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      final respData = e.response?.data;
      final msg = respData is Map ? respData['detail']?.toString() ?? 'Failed to load RBAC data.' : 'Failed to load RBAC data.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
    }
  }

  /// Fetch effective permissions for a specific user.
  Future<UserEffectivePermissions?> fetchUserPermissions(int userId) async {
    try {
      final response = await _dio.get('${ApiConstants.auth}/users/$userId/permissions');
      return UserEffectivePermissions.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update a user's role and custom permission overrides.
  /// Returns null on success, or an error message string on failure.
  Future<String?> updateUserPermissions({
    required int userId,
    int? roleId,
    required List<Map<String, dynamic>> permissions, // [{permission_code, is_granted}]
  }) async {
    try {
      await _dio.put(
        '${ApiConstants.auth}/users/$userId/permissions',
        data: {
          'role_id': roleId,
          'permissions': permissions,
        },
      );
      return null; // success
    } on DioException catch (e) {
      final respData = e.response?.data;
      return respData is Map ? respData['detail']?.toString() ?? 'Failed to update permissions.' : 'Failed to update permissions.';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final rbacProvider = StateNotifierProvider<RbacNotifier, RbacState>((ref) {
  final dio = ref.watch(dioProvider);
  return RbacNotifier(dio);
});
