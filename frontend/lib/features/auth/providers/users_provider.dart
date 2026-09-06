import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';

// ─── Extended User Model with created_at ─────────────────────────────────────

class UserDetail extends UserModel {
  final String? createdAt;
  final String? updatedAt;

  UserDetail({
    required super.userId,
    required super.username,
    required super.email,
    required super.fullName,
    required super.role,
    required super.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String? ?? 'OPERATOR',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

// ─── State ─────────────────────────────────────────────────────────────────────

class UsersState {
  final List<UserDetail> users;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  UsersState copyWith({
    List<UserDetail>? users,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class UsersNotifier extends StateNotifier<UsersState> {
  final Dio _dio;

  UsersNotifier(this._dio) : super(const UsersState());

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('${ApiConstants.auth}/users');
      final data = response.data as List<dynamic>;
      final users = data.map((j) => UserDetail.fromJson(j as Map<String, dynamic>)).toList();
      state = state.copyWith(users: users, isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'فشل في جلب المستخدمين.';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'خطأ غير متوقع: $e');
    }
  }

  Future<String?> createUser({
    required String username,
    required String email,
    required String fullName,
    required String role,
    required String password,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _dio.post(
        '${ApiConstants.auth}/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'full_name': fullName.trim(),
          'role': role,
          'password': password,
        },
      );
      state = state.copyWith(isSaving: false);
      await fetchUsers();
      return null; // success
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'فشل في إنشاء المستخدم.';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    } catch (e) {
      final msg = 'خطأ غير متوقع: $e';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    }
  }

  Future<String?> updateUser({
    required int userId,
    String? fullName,
    String? email,
    String? role,
    String? password,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final body = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) body['full_name'] = fullName.trim();
      if (email != null && email.isNotEmpty) body['email'] = email.trim();
      if (role != null && role.isNotEmpty) body['role'] = role;
      if (password != null && password.isNotEmpty) body['password'] = password;

      await _dio.patch('${ApiConstants.auth}/users/$userId', data: body);
      state = state.copyWith(isSaving: false);
      await fetchUsers();
      return null; // success
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'فشل في تعديل المستخدم.';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    } catch (e) {
      final msg = 'خطأ غير متوقع: $e';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    }
  }

  Future<String?> toggleUserStatus(int userId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _dio.patch('${ApiConstants.auth}/users/$userId/toggle-status');
      state = state.copyWith(isSaving: false);
      await fetchUsers();
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail']?.toString() ?? 'فشل في تغيير حالة المستخدم.';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    } catch (e) {
      final msg = 'خطأ غير متوقع: $e';
      state = state.copyWith(isSaving: false, error: msg);
      return msg;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final dio = ref.watch(dioProvider);
  return UsersNotifier(dio);
});
