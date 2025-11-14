import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// Provider for ApiClient singleton
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await _storage.read(key: AppConfig.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _logger.d(
            'REQUEST: ${options.method} ${options.path}\n'
            'Headers: ${options.headers}\n'
            'Data: ${options.data}',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE: ${response.statusCode} ${response.requestOptions.path}\n'
            'Data: ${response.data}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e(
            'ERROR: ${error.response?.statusCode} ${error.requestOptions.path}\n'
            'Message: ${error.message}\n'
            'Data: ${error.response?.data}',
          );

          // Handle 401 Unauthorized - try to refresh token
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              return handler.resolve(await _retry(error.requestOptions));
            } else {
              // Refresh failed, clear auth and redirect to login
              await clearAuth();
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Logging interceptor for debugging (can be removed in production)
    if (const bool.fromEnvironment('DEBUG', defaultValue: true)) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        await _storage.write(
          key: AppConfig.accessTokenKey,
          value: newAccessToken,
        );
        await _storage.write(
          key: AppConfig.refreshTokenKey,
          value: newRefreshToken,
        );

        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> saveAuth(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: AppConfig.accessTokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.userDataKey);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConfig.accessTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Dio get dio => _dio;
}
