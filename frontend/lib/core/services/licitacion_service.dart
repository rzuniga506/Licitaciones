import 'package:dio/dio.dart';

import '../models/licitacion.dart';
import 'api_client.dart';

class LicitacionService {
  final ApiClient _apiClient;

  LicitacionService(this _apiClient);

  /// Get paginated list of licitaciones with optional filters
  Future<LicitacionList> getLicitaciones({
    int page = 1,
    int pageSize = 20,
    int? clienteId,
    String? estado,
    String? categoria,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (clienteId != null) queryParams['cliente_id'] = clienteId;
      if (estado != null) queryParams['estado'] = estado;
      if (categoria != null) queryParams['categoria'] = categoria;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/licitaciones/',
        queryParameters: queryParams,
      );

      return LicitacionList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar licitaciones: ${e.message}');
    }
  }

  /// Get a single licitacion by ID
  Future<Licitacion> getLicitacion(int id) async {
    try {
      final response = await _apiClient.dio.get('/licitaciones/$id');
      return Licitacion.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Licitación no encontrada');
      }
      throw Exception('Error al cargar licitación: ${e.message}');
    }
  }

  /// Create a new licitacion
  Future<Licitacion> createLicitacion({
    required int clienteId,
    required String numeroLicitacion,
    required String tituloLicitacion,
    String? descripcion,
    required String estadoLicitacion,
    required String categoria,
    DateTime? fechaPublicacion,
    DateTime? fechaPresentacion,
    double? montoEstimado,
    double? montoOfertado,
    int? probabilidadExito,
  }) async {
    try {
      final data = <String, dynamic>{
        'cliente_id': clienteId,
        'numero_licitacion': numeroLicitacion,
        'titulo_licitacion': tituloLicitacion,
        'estado_licitacion': estadoLicitacion,
        'categoria': categoria,
      };

      if (descripcion != null) data['descripcion'] = descripcion;
      if (fechaPublicacion != null) {
        data['fecha_publicacion'] = fechaPublicacion.toIso8601String();
      }
      if (fechaPresentacion != null) {
        data['fecha_presentacion'] = fechaPresentacion.toIso8601String();
      }
      if (montoEstimado != null) data['monto_estimado'] = montoEstimado;
      if (montoOfertado != null) data['monto_ofertado'] = montoOfertado;
      if (probabilidadExito != null) {
        data['probabilidad_exito'] = probabilidadExito;
      }

      final response = await _apiClient.dio.post(
        '/licitaciones/',
        data: data,
      );

      return Licitacion.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al crear licitación: ${e.message}');
    }
  }

  /// Update an existing licitacion
  Future<Licitacion> updateLicitacion(
    int id, {
    String? numeroLicitacion,
    String? tituloLicitacion,
    String? descripcion,
    String? estadoLicitacion,
    String? categoria,
    DateTime? fechaPublicacion,
    DateTime? fechaPresentacion,
    DateTime? fechaAdjudicacion,
    double? montoEstimado,
    double? montoOfertado,
    double? montoAdjudicado,
    int? probabilidadExito,
    DateTime? fechaInicioContrato,
    DateTime? fechaFinContrato,
    DateTime? fechaVencimientoGarantia,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (numeroLicitacion != null) {
        data['numero_licitacion'] = numeroLicitacion;
      }
      if (tituloLicitacion != null) {
        data['titulo_licitacion'] = tituloLicitacion;
      }
      if (descripcion != null) data['descripcion'] = descripcion;
      if (estadoLicitacion != null) {
        data['estado_licitacion'] = estadoLicitacion;
      }
      if (categoria != null) data['categoria'] = categoria;
      if (fechaPublicacion != null) {
        data['fecha_publicacion'] = fechaPublicacion.toIso8601String();
      }
      if (fechaPresentacion != null) {
        data['fecha_presentacion'] = fechaPresentacion.toIso8601String();
      }
      if (fechaAdjudicacion != null) {
        data['fecha_adjudicacion'] = fechaAdjudicacion.toIso8601String();
      }
      if (montoEstimado != null) data['monto_estimado'] = montoEstimado;
      if (montoOfertado != null) data['monto_ofertado'] = montoOfertado;
      if (montoAdjudicado != null) data['monto_adjudicado'] = montoAdjudicado;
      if (probabilidadExito != null) {
        data['probabilidad_exito'] = probabilidadExito;
      }
      if (fechaInicioContrato != null) {
        data['fecha_inicio_contrato'] = fechaInicioContrato.toIso8601String();
      }
      if (fechaFinContrato != null) {
        data['fecha_fin_contrato'] = fechaFinContrato.toIso8601String();
      }
      if (fechaVencimientoGarantia != null) {
        data['fecha_vencimiento_garantia'] =
            fechaVencimientoGarantia.toIso8601String();
      }

      final response = await _apiClient.dio.put(
        '/licitaciones/$id',
        data: data,
      );

      return Licitacion.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Licitación no encontrada');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al actualizar licitación: ${e.message}');
    }
  }

  /// Delete a licitacion (soft delete)
  Future<void> deleteLicitacion(int id) async {
    try {
      await _apiClient.dio.delete('/licitaciones/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Licitación no encontrada');
      }
      throw Exception('Error al eliminar licitación: ${e.message}');
    }
  }

  /// Get licitaciones by cliente
  Future<LicitacionList> getLicitacionesByCliente(
    int clienteId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getLicitaciones(
      clienteId: clienteId,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get licitaciones by estado
  Future<LicitacionList> getLicitacionesByEstado(
    String estado, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getLicitaciones(
      estado: estado,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get licitaciones by categoria
  Future<LicitacionList> getLicitacionesByCategoria(
    String categoria, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getLicitaciones(
      categoria: categoria,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Search licitaciones
  Future<LicitacionList> searchLicitaciones(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return getLicitaciones(
      search: query,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get licitaciones statistics (summary)
  Future<Map<String, dynamic>> getLicitacionesStats() async {
    try {
      final response = await _apiClient.dio.get('/licitaciones/stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Error al cargar estadísticas: ${e.message}');
    }
  }
}
