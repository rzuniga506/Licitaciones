import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario.freezed.dart';
part 'usuario.g.dart';

@freezed
class Usuario with _$Usuario {
  const factory Usuario({
    @JsonKey(name: 'usuario_id') required int usuarioId,
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'role') required String role, // admin, manager, analyst, viewer
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'departamento') String? departamento,
    @JsonKey(name: 'cargo') String? cargo,
    @JsonKey(name: 'telefono') String? telefono,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    @JsonKey(name: 'login_count') int? loginCount,
    @JsonKey(name: 'failed_login_attempts') int? failedLoginAttempts,
    @JsonKey(name: 'password_changed_at') DateTime? passwordChangedAt,
    @JsonKey(name: 'must_change_password') bool? mustChangePassword,
    @JsonKey(name: 'preferences') Map<String, dynamic>? preferences,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_name') String? createdByName,
  }) = _Usuario;

  factory Usuario.fromJson(Map<String, dynamic> json) =>
      _$UsuarioFromJson(json);
}

@freezed
class UsuarioList with _$UsuarioList {
  const factory UsuarioList({
    required List<Usuario> usuarios,
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _UsuarioList;

  factory UsuarioList.fromJson(Map<String, dynamic> json) =>
      _$UsuarioListFromJson(json);
}

@freezed
class UsuarioCreate with _$UsuarioCreate {
  const factory UsuarioCreate({
    required String username,
    required String email,
    required String password,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'is_active') bool? isActive,
    String? departamento,
    String? cargo,
    String? telefono,
    @JsonKey(name: 'must_change_password') bool? mustChangePassword,
  }) = _UsuarioCreate;

  factory UsuarioCreate.fromJson(Map<String, dynamic> json) =>
      _$UsuarioCreateFromJson(json);

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        if (isActive != null) 'is_active': isActive,
        if (departamento != null) 'departamento': departamento,
        if (cargo != null) 'cargo': cargo,
        if (telefono != null) 'telefono': telefono,
        if (mustChangePassword != null)
          'must_change_password': mustChangePassword,
      };
}

@freezed
class UsuarioUpdate with _$UsuarioUpdate {
  const factory UsuarioUpdate({
    String? email,
    @JsonKey(name: 'full_name') String? fullName,
    String? role,
    @JsonKey(name: 'is_active') bool? isActive,
    String? departamento,
    String? cargo,
    String? telefono,
    String? password,
    @JsonKey(name: 'must_change_password') bool? mustChangePassword,
  }) = _UsuarioUpdate;

  factory UsuarioUpdate.fromJson(Map<String, dynamic> json) =>
      _$UsuarioUpdateFromJson(json);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (fullName != null) map['full_name'] = fullName;
    if (role != null) map['role'] = role;
    if (isActive != null) map['is_active'] = isActive;
    if (departamento != null) map['departamento'] = departamento;
    if (cargo != null) map['cargo'] = cargo;
    if (telefono != null) map['telefono'] = telefono;
    if (password != null) map['password'] = password;
    if (mustChangePassword != null) {
      map['must_change_password'] = mustChangePassword;
    }
    return map;
  }
}

/// Estadísticas de uso de usuario
@freezed
class UsuarioStats with _$UsuarioStats {
  const factory UsuarioStats({
    @JsonKey(name: 'usuario_id') required int usuarioId,
    @JsonKey(name: 'licitaciones_creadas') int? licitacionesCreadas,
    @JsonKey(name: 'documentos_subidos') int? documentosSubidos,
    @JsonKey(name: 'interacciones_registradas') int? interaccionesRegistradas,
    @JsonKey(name: 'alertas_activas') int? alertasActivas,
    @JsonKey(name: 'ultima_actividad') DateTime? ultimaActividad,
  }) = _UsuarioStats;

  factory UsuarioStats.fromJson(Map<String, dynamic> json) =>
      _$UsuarioStatsFromJson(json);
}
