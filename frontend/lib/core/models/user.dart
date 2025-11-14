import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id') required int userId,
    required String email,
    required String username,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// User roles enum
enum UserRole {
  @JsonValue('admin')
  admin('Administrador'),
  @JsonValue('coordinator')
  coordinator('Coordinador'),
  @JsonValue('analyst')
  analyst('Analista'),
  @JsonValue('viewer')
  viewer('Visualizador');

  const UserRole(this.displayName);
  final String displayName;

  bool get isAdmin => this == UserRole.admin;
  bool get canEdit => this == UserRole.admin ||
      this == UserRole.coordinator ||
      this == UserRole.analyst;
  bool get canApprove => this == UserRole.admin || this == UserRole.coordinator;
}
