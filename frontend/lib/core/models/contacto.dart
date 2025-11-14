import 'package:freezed_annotation/freezed_annotation.dart';

part 'contacto.freezed.dart';
part 'contacto.g.dart';

@freezed
class Contacto with _$Contacto {
  const factory Contacto({
    @JsonKey(name: 'contacto_id') required int contactoId,
    @JsonKey(name: 'cliente_id') required int clienteId,
    @JsonKey(name: 'nombre_contacto') required String nombreContacto,
    @JsonKey(name: 'cargo') String? cargo,
    @JsonKey(name: 'departamento') String? departamento,
    @JsonKey(name: 'telefono') String? telefono,
    @JsonKey(name: 'celular') String? celular,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'extension') String? extension,
    @JsonKey(name: 'linkedin_url') String? linkedinUrl,
    @JsonKey(name: 'es_contacto_principal') required bool esContactoPrincipal,
    @JsonKey(name: 'puede_firmar') required bool puedeFirmar,
    @JsonKey(name: 'nivel_decision') String? nivelDecision,
    @JsonKey(name: 'preferencia_contacto') String? preferenciaContacto,
    @JsonKey(name: 'mejor_horario_contacto') String? mejorHorarioContacto,
    @JsonKey(name: 'notas') String? notas,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'created_at') required DateTime creadoEn,
    @JsonKey(name: 'updated_at') DateTime? actualizadoEn,
    @JsonKey(name: 'created_by') int? creadoPor,
  }) = _Contacto;

  factory Contacto.fromJson(Map<String, dynamic> json) => _$ContactoFromJson(json);
}

@freezed
class ContactoList with _$ContactoList {
  const factory ContactoList({
    required int total,
    required List<Contacto> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _ContactoList;

  factory ContactoList.fromJson(Map<String, dynamic> json) =>
      _$ContactoListFromJson(json);
}
