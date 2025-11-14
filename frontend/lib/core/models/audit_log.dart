import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    @JsonKey(name: 'audit_id') required int auditId,
    @JsonKey(name: 'usuario_id') required int usuarioId,
    @JsonKey(name: 'usuario_nombre') String? usuarioNombre,
    @JsonKey(name: 'accion') required String accion, // create, update, delete, login, logout, etc.
    @JsonKey(name: 'modulo') required String modulo, // licitaciones, clientes, documentos, etc.
    @JsonKey(name: 'entidad_tipo') String? entidadTipo, // licitacion, cliente, documento, etc.
    @JsonKey(name: 'entidad_id') int? entidadId,
    @JsonKey(name: 'entidad_nombre') String? entidadNombre,
    @JsonKey(name: 'descripcion') String? descripcion,
    @JsonKey(name: 'datos_anteriores') Map<String, dynamic>? datosAnteriores,
    @JsonKey(name: 'datos_nuevos') Map<String, dynamic>? datosNuevos,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'resultado') String? resultado, // success, error
    @JsonKey(name: 'mensaje_error') String? mensajeError,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}

@freezed
class AuditLogList with _$AuditLogList {
  const factory AuditLogList({
    required List<AuditLog> logs,
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _AuditLogList;

  factory AuditLogList.fromJson(Map<String, dynamic> json) =>
      _$AuditLogListFromJson(json);
}

/// Estadísticas de auditoría
@freezed
class AuditStats with _$AuditStats {
  const factory AuditStats({
    @JsonKey(name: 'total_eventos') required int totalEventos,
    @JsonKey(name: 'eventos_hoy') required int eventosHoy,
    @JsonKey(name: 'usuarios_activos') required int usuariosActivos,
    @JsonKey(name: 'acciones_por_modulo') required Map<String, int> accionesPorModulo,
    @JsonKey(name: 'acciones_por_tipo') required Map<String, int> accionesPorTipo,
    @JsonKey(name: 'errores_recientes') int? erroresRecientes,
  }) = _AuditStats;

  factory AuditStats.fromJson(Map<String, dynamic> json) =>
      _$AuditStatsFromJson(json);
}
