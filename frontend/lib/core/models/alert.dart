import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

@freezed
class Alert with _$Alert {
  const factory Alert({
    @JsonKey(name: 'alerta_id') required int alertaId,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'tipo_alerta') required String tipoAlerta,
    required String titulo,
    required String mensaje,
    @JsonKey(name: 'nivel_prioridad') required String nivelPrioridad,
    @JsonKey(name: 'estado_alerta') required String estadoAlerta,
    @JsonKey(name: 'requiere_accion') @Default(false) bool requiereAccion,
    @JsonKey(name: 'accion_sugerida') String? accionSugerida,
    @JsonKey(name: 'url_accion') String? urlAccion,
    @JsonKey(name: 'licitacion_id') int? licitacionId,
    @JsonKey(name: 'cliente_id') int? clienteId,
    @JsonKey(name: 'documento_id') int? documentoId,
    @JsonKey(name: 'fecha_alerta') DateTime? fechaAlerta,
    @JsonKey(name: 'fecha_leida') DateTime? fechaLeida,
    @JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}

enum AlertPriority {
  @JsonValue('critica')
  critical('Crítica', 'critical'),
  @JsonValue('alta')
  high('Alta', 'high'),
  @JsonValue('media')
  medium('Media', 'medium'),
  @JsonValue('baja')
  low('Baja', 'low');

  const AlertPriority(this.displayName, this.key);
  final String displayName;
  final String key;

  static AlertPriority fromString(String value) {
    return AlertPriority.values.firstWhere(
      (e) => e.name == value || e.key == value,
      orElse: () => AlertPriority.medium,
    );
  }
}

enum AlertStatus {
  @JsonValue('activa')
  active('Activa'),
  @JsonValue('leida')
  read('Leída'),
  @JsonValue('resuelta')
  resolved('Resuelta'),
  @JsonValue('archivada')
  archived('Archivada'),
  @JsonValue('descartada')
  dismissed('Descartada');

  const AlertStatus(this.displayName);
  final String displayName;
}

@freezed
class AlertList with _$AlertList {
  const factory AlertList({
    required int total,
    required List<Alert> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _AlertList;

  factory AlertList.fromJson(Map<String, dynamic> json) =>
      _$AlertListFromJson(json);
}

@freezed
class AlertStats with _$AlertStats {
  const factory AlertStats({
    @JsonKey(name: 'total_alertas') required int totalAlertas,
    @JsonKey(name: 'por_estado') required Map<String, int> porEstado,
    @JsonKey(name: 'por_tipo') required Map<String, int> porTipo,
    @JsonKey(name: 'por_prioridad') required Map<String, int> porPrioridad,
    @JsonKey(name: 'activas_criticas') required int activasCriticas,
    @JsonKey(name: 'requieren_accion') required int requierenAccion,
  }) = _AlertStats;

  factory AlertStats.fromJson(Map<String, dynamic> json) =>
      _$AlertStatsFromJson(json);
}
