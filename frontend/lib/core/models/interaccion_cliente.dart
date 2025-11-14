import 'package:freezed_annotation/freezed_annotation.dart';

part 'interaccion_cliente.freezed.dart';
part 'interaccion_cliente.g.dart';

@freezed
class InteraccionCliente with _$InteraccionCliente {
  const factory InteraccionCliente({
    @JsonKey(name: 'interaccion_id') required int interaccionId,
    @JsonKey(name: 'cliente_id') required int clienteId,
    @JsonKey(name: 'contacto_id') int? contactoId,
    @JsonKey(name: 'licitacion_id') int? licitacionId,
    @JsonKey(name: 'tipo_interaccion') required String tipoInteraccion,
    @JsonKey(name: 'titulo') required String titulo,
    @JsonKey(name: 'descripcion') required String descripcion,
    @JsonKey(name: 'fecha_interaccion') required DateTime fechaInteraccion,
    @JsonKey(name: 'duracion_minutos') int? duracionMinutos,
    @JsonKey(name: 'ubicacion') String? ubicacion,
    @JsonKey(name: 'modalidad') String? modalidad,
    @JsonKey(name: 'resultado') String? resultado,
    @JsonKey(name: 'nivel_interes') int? nivelInteres,
    @JsonKey(name: 'requiere_seguimiento') required bool requiereSeguimiento,
    @JsonKey(name: 'fecha_proximo_seguimiento') DateTime? fechaProximoSeguimiento,
    @JsonKey(name: 'accion_siguiente') String? accionSiguiente,
    @JsonKey(name: 'responsable_seguimiento') int? responsableSeguimiento,
    @JsonKey(name: 'participantes') List<String>? participantes,
    @JsonKey(name: 'asistentes_internos') List<String>? asistentesInternos,
    @JsonKey(name: 'documentos_vinculados') List<int>? documentosVinculados,
    @JsonKey(name: 'observaciones') String? observaciones,
    @JsonKey(name: 'puntos_clave') String? puntosClave,
    @JsonKey(name: 'compromisos') String? compromisos,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'created_at') required DateTime creadoEn,
    @JsonKey(name: 'updated_at') DateTime? actualizadoEn,
    @JsonKey(name: 'created_by') int? creadoPor,
  }) = _InteraccionCliente;

  factory InteraccionCliente.fromJson(Map<String, dynamic> json) =>
      _$InteraccionClienteFromJson(json);
}

@freezed
class InteraccionClienteList with _$InteraccionClienteList {
  const factory InteraccionClienteList({
    required int total,
    required List<InteraccionCliente> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _InteraccionClienteList;

  factory InteraccionClienteList.fromJson(Map<String, dynamic> json) =>
      _$InteraccionClienteListFromJson(json);
}
