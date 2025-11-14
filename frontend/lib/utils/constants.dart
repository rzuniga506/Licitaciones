/// Application constants

class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  static const String apiUrl = '$apiBaseUrl$apiVersion';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String usersEndpoint = '/users';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // File Upload
  static const int maxUploadSizeMB = 10;
  static const List<String> allowedFileExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'zip'
  ];

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleCoordinator = 'coordinator';
  static const String roleAnalyst = 'analyst';
  static const String roleViewer = 'viewer';
}
