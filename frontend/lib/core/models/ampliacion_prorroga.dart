import 'package:freezed_annotation/freezed_annotation.dart';

part 'ampliacion_prorroga.freezed.dart';
part 'ampliacion_prorroga.g.dart';

@freezed
class AmpliacionProrroga with _$AmpliacionProrroga {
  const factory AmpliacionProrroga({
    @JsonKey(name: 'ampliacion_id') required int ampliacionId,
    @JsonKey(name: 'licitacion_id') required int licitacionId,
    @JsonKey(name: 'licitacion_titulo') String? licitacionTitulo,
    @JsonKey(name: 'tipo') required String tipo, // ampliacion_plazo, prorroga_contrato, ampliacion_monto
    @JsonKey(name: 'fecha_solicitud') required DateTime fechaSolicitud,
    @JsonKey(name: 'fecha_respuesta') DateTime? fechaRespuesta,
    @JsonKey(name: 'estado') required String estado, // solicitada, aprobada, rechazada, en_revision
    @JsonKey(name: 'monto_solicitado') double? montoSolicitado,
    @JsonKey(name: 'monto_aprobado') double? montoAprobado,
    @JsonKey(name: 'plazo_solicitado_dias') int? plazoSolicitadoDias,
    @JsonKey(name: 'plazo_aprobado_dias') int? plazoAprobadoDias,
    @JsonKey(name: 'fecha_nueva_entrega') DateTime? fechaNuevaEntrega,
    @JsonKey(name: 'justificacion') required String justificacion,
    @JsonKey(name: 'respuesta_entidad') String? respuestaEntidad,
    @JsonKey(name: 'observaciones') String? observaciones,
    @JsonKey(name: 'documento_solicitud_id') int? documentoSolicitudId,
    @JsonKey(name: 'documento_respuesta_id') int? documentoRespuestaId,
    @JsonKey(name: 'solicitante_id') required int solicitanteId,
    @JsonKey(name: 'solicitante_nombre') String? solicitanteNombre,
    @JsonKey(name: 'aprobador_id') int? aprobadorId,
    @JsonKey(name: 'aprobador_nombre') String? aprobadorNombre,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AmpliacionProrroga;

  factory AmpliacionProrroga.fromJson(Map<String, dynamic> json) =>
      _$AmpliacionProrrogaFromJson(json);
}

@freezed
class AmpliacionProrrogaList with _$AmpliacionProrrogaList {
  const factory AmpliacionProrrogaList({
    required List<AmpliacionProrroga> ampliaciones,
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _AmpliacionProrrogaList;

  factory AmpliacionProrrogaList.fromJson(Map<String, dynamic> json) =>
      _$AmpliacionProrrogaListFromJson(json);
}
