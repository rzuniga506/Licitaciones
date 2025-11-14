import 'package:dio/dio.dart';

import '../models/cliente.dart';
import 'api_client.dart';

class ClienteService {
  final ApiClient _apiClient;

  ClienteService(this._apiClient);

  /// Get paginated list of clientes
  Future<ClienteList> getClientes({
    int page = 1,
    int pageSize = 100,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/clientes/',
        queryParameters: queryParams,
      );

      return ClienteList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar clientes: ${e.message}');
    }
  }

  /// Get all clientes (for dropdowns)
  Future<List<Cliente>> getAllClientes() async {
    try {
      final result = await getClientes(pageSize: 1000);
      return result.items;
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  /// Get a single cliente by ID
  Future<Cliente> getCliente(int id) async {
    try {
      final response = await _apiClient.dio.get('/clientes/$id');
      return Cliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cliente no encontrado');
      }
      throw Exception('Error al cargar cliente: ${e.message}');
    }
  }

  /// Create a new cliente
  Future<Cliente> createCliente({
    required String nombreCliente,
    required String tipoCliente,
    String? identificacion,
    String? telefono,
    String? email,
    String? direccion,
    String? contactoPrincipal,
  }) async {
    try {
      final data = <String, dynamic>{
        'nombre_cliente': nombreCliente,
        'tipo_cliente': tipoCliente,
      };

      if (identificacion != null) data['identificacion'] = identificacion;
      if (telefono != null) data['telefono'] = telefono;
      if (email != null) data['email'] = email;
      if (direccion != null) data['direccion'] = direccion;
      if (contactoPrincipal != null) {
        data['contacto_principal'] = contactoPrincipal;
      }

      final response = await _apiClient.dio.post(
        '/clientes/',
        data: data,
      );

      return Cliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al crear cliente: ${e.message}');
    }
  }

  /// Update an existing cliente
  Future<Cliente> updateCliente(
    int id, {
    String? nombreCliente,
    String? tipoCliente,
    String? identificacion,
    String? telefono,
    String? email,
    String? direccion,
    String? contactoPrincipal,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (nombreCliente != null) data['nombre_cliente'] = nombreCliente;
      if (tipoCliente != null) data['tipo_cliente'] = tipoCliente;
      if (identificacion != null) data['identificacion'] = identificacion;
      if (telefono != null) data['telefono'] = telefono;
      if (email != null) data['email'] = email;
      if (direccion != null) data['direccion'] = direccion;
      if (contactoPrincipal != null) {
        data['contacto_principal'] = contactoPrincipal;
      }

      final response = await _apiClient.dio.put(
        '/clientes/$id',
        data: data,
      );

      return Cliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cliente no encontrado');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al actualizar cliente: ${e.message}');
    }
  }

  /// Delete a cliente (soft delete)
  Future<void> deleteCliente(int id) async {
    try {
      await _apiClient.dio.delete('/clientes/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cliente no encontrado');
      }
      throw Exception('Error al eliminar cliente: ${e.message}');
    }
  }
}
