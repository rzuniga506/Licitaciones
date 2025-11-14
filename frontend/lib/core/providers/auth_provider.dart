import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

part 'auth_provider.freezed.dart';

// Providers
final apiClientProvider = Provider((ref) => ApiClient());

final authServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Auth State
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    checkAuth();
  }

  /// Check if user is authenticated on app start
  Future<void> checkAuth() async {
    state = const AuthState.loading();

    try {
      final isAuth = await _authService.isAuthenticated();

      if (isAuth) {
        final user = await _authService.getCurrentUser();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Login
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();

    try {
      await _authService.login(username, password);
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
      // Reset to unauthenticated after showing error
      Future.delayed(const Duration(seconds: 3), () {
        if (state is _Error) {
          state = const AuthState.unauthenticated();
        }
      });
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AuthState.loading();

    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout API fails, clear local state
      state = const AuthState.unauthenticated();
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      // If refresh fails, log out
      state = const AuthState.unauthenticated();
    }
  }
}
