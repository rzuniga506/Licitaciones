import 'package:freezed_annotation/freezed_annotation.dart';

part 'cliente.freezed.dart';
part 'cliente.g.dart';

@freezed
class Cliente with _$Cliente {
  const factory Cliente({
    @JsonKey(name: 'cliente_id') required int clienteId,
    @JsonKey(name: 'nombre_cliente') required String nombreCliente,
    @JsonKey(name: 'tipo_cliente') required String tipoCliente,
    String? identificacion,
    String? telefono,
    String? email,
    String? direccion,
    @JsonKey(name: 'contacto_principal') String? contactoPrincipal,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Cliente;

  factory Cliente.fromJson(Map<String, dynamic> json) =>
      _$ClienteFromJson(json);
}

@freezed
class ClienteList with _$ClienteList {
  const factory ClienteList({
    required int total,
    required List<Cliente> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _ClienteList;

  factory ClienteList.fromJson(Map<String, dynamic> json) =>
      _$ClienteListFromJson(json);
}
