import 'package:dio/dio.dart';

import '../models/alert.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _apiClient;

  AlertService(this._apiClient);

  /// Get paginated list of alerts with optional filters
  Future<AlertList> getAlertas({
    int page = 1,
    int pageSize = 20,
    String? prioridad,
    String? estado,
    bool? requiereAccion,
    bool? leidas,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (prioridad != null) queryParams['prioridad'] = prioridad;
      if (estado != null) queryParams['estado'] = estado;
      if (requiereAccion != null) {
        queryParams['requiere_accion'] = requiereAccion;
      }
      if (leidas != null) queryParams['leidas'] = leidas;

      final response = await _apiClient.dio.get(
        '/alertas/',
        queryParameters: queryParams,
      );

      return AlertList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar alertas: ${e.message}');
    }
  }

  /// Get a single alert by ID
  Future<Alert> getAlerta(int id) async {
    try {
      final response = await _apiClient.dio.get('/alertas/$id');
      return Alert.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Alerta no encontrada');
      }
      throw Exception('Error al cargar alerta: ${e.message}');
    }
  }

  /// Get alerts statistics
  Future<AlertStats> getAlertasStats() async {
    try {
      final response = await _apiClient.dio.get('/alertas/stats');
      return AlertStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar estadísticas: ${e.message}');
    }
  }

  /// Mark alert as read
  Future<Alert> markAsRead(int id) async {
    try {
      final response = await _apiClient.dio.post('/alertas/$id/marcar-leida');
      return Alert.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Alerta no encontrada');
      }
      throw Exception('Error al marcar alerta como leída: ${e.message}');
    }
  }

  /// Mark alert as resolved
  Future<Alert> markAsResolved(int id) async {
    try {
      final response = await _apiClient.dio.post('/alertas/$id/resolver');
      return Alert.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Alerta no encontrada');
      }
      throw Exception('Error al resolver alerta: ${e.message}');
    }
  }

  /// Dismiss/archive alert
  Future<void> dismissAlert(int id) async {
    try {
      await _apiClient.dio.post('/alertas/$id/descartar');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Alerta no encontrada');
      }
      throw Exception('Error al descartar alerta: ${e.message}');
    }
  }

  /// Mark multiple alerts as read
  Future<void> markMultipleAsRead(List<int> ids) async {
    try {
      await _apiClient.dio.post(
        '/alertas/marcar-leidas-multiple',
        data: {'alerta_ids': ids},
      );
    } on DioException catch (e) {
      throw Exception('Error al marcar alertas como leídas: ${e.message}');
    }
  }

  /// Get alerts by priority
  Future<AlertList> getAlertasByPriority(
    String prioridad, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlertas(
      prioridad: prioridad,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get alerts that require action
  Future<AlertList> getAlertasRequiringAction({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlertas(
      requiereAccion: true,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get unread alerts
  Future<AlertList> getUnreadAlertas({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlertas(
      leidas: false,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get read alerts
  Future<AlertList> getReadAlertas({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getAlertas(
      leidas: true,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get active alerts count
  Future<int> getActiveAlertsCount() async {
    try {
      final stats = await getAlertasStats();
      return stats.porEstado['activa'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get critical alerts count
  Future<int> getCriticalAlertsCount() async {
    try {
      final stats = await getAlertasStats();
      return stats.activasCriticas;
    } catch (e) {
      return 0;
    }
  }
}
