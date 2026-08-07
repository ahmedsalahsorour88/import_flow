import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
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

  AuthNotifier(this._dio) : super(AuthState(
    // Default demo user: General Manager
    user: UserModel(
      userId: 2,
      username: 'manager',
      email: 'manager@importflow.com',
      fullName: 'General Logistics Manager',
      role: 'MANAGER',
      isActive: true,
    ),
    isAuthenticated: true,
  ));

  Future<bool> login(String usernameOrEmail, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/login',
        data: {
          'username_or_email': usernameOrEmail,
          'password': password,
        },
      );

      final token = response.data['access_token'] as String;
      final userJson = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      state = state.copyWith(
        user: user,
        token: token,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      String msg = 'Invalid username/email or password.';
      if (e.response != null && e.response?.data != null && e.response?.data['detail'] != null) {
        msg = e.response?.data['detail'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected authentication error occurred.');
      return false;
    }
  }

  void switchDemoRole(String role) {
    if (role == 'ADMIN') {
      state = state.copyWith(
        user: UserModel(
          userId: 1,
          username: 'admin',
          email: 'admin@importflow.com',
          fullName: 'System Admin',
          role: 'ADMIN',
          isActive: true,
        ),
      );
    } else if (role == 'MANAGER') {
      state = state.copyWith(
        user: UserModel(
          userId: 2,
          username: 'manager',
          email: 'manager@importflow.com',
          fullName: 'General Logistics Manager',
          role: 'MANAGER',
          isActive: true,
        ),
      );
    } else {
      state = state.copyWith(
        user: UserModel(
          userId: 3,
          username: 'operator1',
          email: 'operator1@importflow.com',
          fullName: 'Ahmed Import Specialist',
          role: 'OPERATOR',
          isActive: true,
        ),
      );
    }
  }

  void logout() {
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(Dio());
});
