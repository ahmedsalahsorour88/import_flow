import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'importflow_jwt_token';
  static const String _userKey = 'importflow_user_profile';

  AuthNotifier(this._dio, this._storage)
      : super(const AuthState(
          isAuthenticated: true,
          user: null,
        )) {
    _initFromStorage();
  }

  Future<void> _initFromStorage() async {
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUserJson = await _storage.read(key: _userKey);

      if (savedToken != null && savedToken.isNotEmpty && savedUserJson != null) {
        final userData = jsonDecode(savedUserJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        state = state.copyWith(
          token: savedToken,
          user: user,
          isAuthenticated: true,
        );
      } else {
        // Default dev initial session (General Manager)
        final defaultUser = UserModel(
          userId: 2,
          username: 'manager',
          email: 'manager@importflow.com',
          fullName: 'General Logistics Manager',
          role: 'MANAGER',
          isActive: true,
        );
        state = state.copyWith(
          user: defaultUser,
          isAuthenticated: true,
        );
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/login',
        data: {
          'username_or_email': usernameOrEmail.trim(),
          'password': password.trim(),
        },
      );

      final token = response.data['access_token'] as String;
      final userJson = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      // Persist to secure storage
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(userJson));

      state = state.copyWith(
        user: user,
        token: token,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      String msg = 'اسم المستخدم أو كلمة المرور غير صحيحة.';
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        msg = e.response?.data['detail'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'تعذر الاتصال بخادم المصادقة: $e');
      return false;
    }
  }

  void switchDemoRole(String role) async {
    UserModel user;
    if (role == 'ADMIN') {
      user = UserModel(
        userId: 1,
        username: 'admin',
        email: 'admin@importflow.com',
        fullName: 'System Admin (مدير النظام)',
        role: 'ADMIN',
        isActive: true,
      );
    } else if (role == 'MANAGER') {
      user = UserModel(
        userId: 2,
        username: 'manager',
        email: 'manager@importflow.com',
        fullName: 'General Logistics Manager (مدير العمليات)',
        role: 'MANAGER',
        isActive: true,
      );
    } else {
      user = UserModel(
        userId: 3,
        username: 'operator1',
        email: 'operator1@importflow.com',
        fullName: 'Ahmed Import Specialist (أخصائي استيراد)',
        role: 'OPERATOR',
        isActive: true,
      );
    }

    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
    state = const AuthState(isAuthenticated: false, user: null, token: null);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(Dio(), storage);
});
