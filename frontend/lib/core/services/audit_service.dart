import 'package:dio/dio.dart';
import '../models/audit_log.dart';
import '../utils/api_client.dart';

class AuditService {
  final Dio _dio = ApiClient.dio;

  /// Obtiene logs de auditoría con filtros y paginación
  Future<AuditLogList> getAuditLogs({
    int page = 1,
    int pageSize = 50,
    int? usuarioId,
    String? accion,
    String? modulo,
    String? entidadTipo,
    int? entidadId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? resultado,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (usuarioId != null) {
        queryParameters['usuario_id'] = usuarioId;
      }
      if (accion != null && accion.isNotEmpty) {
        queryParameters['accion'] = accion;
      }
      if (modulo != null && modulo.isNotEmpty) {
        queryParameters['modulo'] = modulo;
      }
      if (entidadTipo != null && entidadTipo.isNotEmpty) {
        queryParameters['entidad_tipo'] = entidadTipo;
      }
      if (entidadId != null) {
        queryParameters['entidad_id'] = entidadId;
      }
      if (fechaDesde != null) {
        queryParameters['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fecha_hasta'] = fechaHasta.toIso8601String();
      }
      if (resultado != null && resultado.isNotEmpty) {
        queryParameters['resultado'] = resultado;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/audit-logs',
        queryParameters: queryParameters,
      );

      return AuditLogList.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener logs de auditoría: $e');
    }
  }

  /// Obtiene un log de auditoría por ID
  Future<AuditLog> getAuditLogById(int auditId) async {
    try {
      final response = await _dio.get('/audit-logs/$auditId');
      return AuditLog.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener log de auditoría: $e');
    }
  }

  /// Obtiene estadísticas de auditoría
  Future<AuditStats> getAuditStats({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (fechaDesde != null) {
        queryParameters['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fecha_hasta'] = fechaHasta.toIso8601String();
      }

      final response = await _dio.get(
        '/audit-logs/stats',
        queryParameters: queryParameters,
      );

      return AuditStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener estadísticas de auditoría: $e');
    }
  }

  /// Exporta logs de auditoría a CSV
  Future<List<int>> exportToCsv({
    int? usuarioId,
    String? accion,
    String? modulo,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (usuarioId != null) {
        queryParameters['usuario_id'] = usuarioId;
      }
      if (accion != null && accion.isNotEmpty) {
        queryParameters['accion'] = accion;
      }
      if (modulo != null && modulo.isNotEmpty) {
        queryParameters['modulo'] = modulo;
      }
      if (fechaDesde != null) {
        queryParameters['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fecha_hasta'] = fechaHasta.toIso8601String();
      }

      final response = await _dio.get(
        '/audit-logs/export/csv',
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data as List<int>;
    } catch (e) {
      throw Exception('Error al exportar logs: $e');
    }
  }

  /// Limpia logs antiguos (solo admin)
  Future<Map<String, dynamic>> cleanOldLogs({
    required int diasAntiguedad,
  }) async {
    try {
      final response = await _dio.delete(
        '/audit-logs/clean',
        data: {'dias_antiguedad': diasAntiguedad},
      );

      return {
        'deleted_count': response.data['deleted_count'] ?? 0,
        'message': response.data['message'] ?? 'Logs eliminados',
      };
    } catch (e) {
      throw Exception('Error al limpiar logs: $e');
    }
  }
}
