import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../models/auth_response.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  /// Login with username and password
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens
      await _apiClient.saveAuth(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Usuario o contraseña incorrectos');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Datos inválidos');
      } else {
        throw Exception('Error de conexión. Por favor intente nuevamente.');
      }
    }
  }

  /// Get current user info
  Future<User> getCurrentUser() async {
    try {
      // First check if we have cached user data
      final cachedUser = await _storage.read(key: AppConfig.userDataKey);
      if (cachedUser != null) {
        return User.fromJson(json.decode(cachedUser));
      }

      // If not cached, fetch from API
      final response = await _apiClient.dio.get('/users/me');
      final user = User.fromJson(response.data);

      // Cache the user data
      await _storage.write(
        key: AppConfig.userDataKey,
        value: json.encode(user.toJson()),
      );

      return user;
    } on DioException catch (e) {
      throw Exception('Error al obtener datos del usuario: ${e.message}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Call logout endpoint (optional, depends on backend implementation)
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      // Clear all local data
      await _apiClient.clearAuth();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _apiClient.dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      await _apiClient.saveAuth(
        authResponse.accessToken,
        authResponse.refreshToken,
      );
    } on DioException catch (e) {
      // If refresh fails, clear auth
      await _apiClient.clearAuth();
      throw Exception('Sesión expirada. Por favor inicie sesión nuevamente.');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/users/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Contraseña actual incorrecta');
      } else {
        throw Exception('Error al cambiar contraseña');
      }
    }
  }
}
