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
}
