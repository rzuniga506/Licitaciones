import 'package:dio/dio.dart';

import '../models/interaccion_cliente.dart';
import 'api_client.dart';

class InteraccionService {
  final ApiClient _apiClient;

  InteraccionService(this._apiClient);

  /// Get paginated list of interacciones with filters
  Future<InteraccionClienteList> getInteracciones({
    int page = 1,
    int pageSize = 20,
    int? clienteId,
    int? contactoId,
    String? tipoInteraccion,
    bool? requiereSeguimiento,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (clienteId != null) queryParams['cliente_id'] = clienteId;
      if (contactoId != null) queryParams['contacto_id'] = contactoId;
      if (tipoInteraccion != null && tipoInteraccion.isNotEmpty) {
        queryParams['tipo_interaccion'] = tipoInteraccion;
      }
      if (requiereSeguimiento != null) {
        queryParams['requiere_seguimiento'] = requiereSeguimiento;
      }
      if (fechaDesde != null) {
        queryParams['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParams['fecha_hasta'] = fechaHasta.toIso8601String();
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/crm/interacciones',
        queryParameters: queryParams,
      );

      return InteraccionClienteList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar interacciones: ${e.message}');
    }
  }

  /// Get a single interaccion by ID
  Future<InteraccionCliente> getInteraccion(int id) async {
    try {
      final response = await _apiClient.dio.get('/crm/interacciones/$id');
      return InteraccionCliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Interacción no encontrada');
      }
      throw Exception('Error al cargar interacción: ${e.message}');
    }
  }

  /// Create a new interaccion
  Future<InteraccionCliente> createInteraccion({
    required int clienteId,
    int? contactoId,
    int? licitacionId,
    required String tipoInteraccion,
    required String titulo,
    required String descripcion,
    required DateTime fechaInteraccion,
    int? duracionMinutos,
    String? ubicacion,
    String? modalidad,
    String? resultado,
    int? nivelInteres,
    bool requiereSeguimiento = false,
    DateTime? fechaProximoSeguimiento,
    String? accionSiguiente,
    int? responsableSeguimiento,
    List<String>? participantes,
    List<String>? asistentesInternos,
    List<int>? documentosVinculados,
    String? observaciones,
    String? puntosClave,
    String? compromisos,
  }) async {
    try {
      final data = <String, dynamic>{
        'cliente_id': clienteId,
        'tipo_interaccion': tipoInteraccion,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_interaccion': fechaInteraccion.toIso8601String(),
        'requiere_seguimiento': requiereSeguimiento,
      };

      if (contactoId != null) data['contacto_id'] = contactoId;
      if (licitacionId != null) data['licitacion_id'] = licitacionId;
      if (duracionMinutos != null) data['duracion_minutos'] = duracionMinutos;
      if (ubicacion != null) data['ubicacion'] = ubicacion;
      if (modalidad != null) data['modalidad'] = modalidad;
      if (resultado != null) data['resultado'] = resultado;
      if (nivelInteres != null) data['nivel_interes'] = nivelInteres;
      if (fechaProximoSeguimiento != null) {
        data['fecha_proximo_seguimiento'] = fechaProximoSeguimiento.toIso8601String().split('T')[0];
      }
      if (accionSiguiente != null) data['accion_siguiente'] = accionSiguiente;
      if (responsableSeguimiento != null) data['responsable_seguimiento'] = responsableSeguimiento;
      if (participantes != null) data['participantes'] = participantes;
      if (asistentesInternos != null) data['asistentes_internos'] = asistentesInternos;
      if (documentosVinculados != null) data['documentos_vinculados'] = documentosVinculados;
      if (observaciones != null) data['observaciones'] = observaciones;
      if (puntosClave != null) data['puntos_clave'] = puntosClave;
      if (compromisos != null) data['compromisos'] = compromisos;

      final response = await _apiClient.dio.post(
        '/crm/interacciones',
        data: data,
      );

      return InteraccionCliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al crear interacción: ${e.message}');
    }
  }

  /// Update an existing interaccion
  Future<InteraccionCliente> updateInteraccion(
    int id, {
    int? contactoId,
    int? licitacionId,
    String? tipoInteraccion,
    String? titulo,
    String? descripcion,
    DateTime? fechaInteraccion,
    int? duracionMinutos,
    String? ubicacion,
    String? modalidad,
    String? resultado,
    int? nivelInteres,
    bool? requiereSeguimiento,
    DateTime? fechaProximoSeguimiento,
    String? accionSiguiente,
    int? responsableSeguimiento,
    List<String>? participantes,
    List<String>? asistentesInternos,
    List<int>? documentosVinculados,
    String? observaciones,
    String? puntosClave,
    String? compromisos,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (contactoId != null) data['contacto_id'] = contactoId;
      if (licitacionId != null) data['licitacion_id'] = licitacionId;
      if (tipoInteraccion != null) data['tipo_interaccion'] = tipoInteraccion;
      if (titulo != null) data['titulo'] = titulo;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (fechaInteraccion != null) data['fecha_interaccion'] = fechaInteraccion.toIso8601String();
      if (duracionMinutos != null) data['duracion_minutos'] = duracionMinutos;
      if (ubicacion != null) data['ubicacion'] = ubicacion;
      if (modalidad != null) data['modalidad'] = modalidad;
      if (resultado != null) data['resultado'] = resultado;
      if (nivelInteres != null) data['nivel_interes'] = nivelInteres;
      if (requiereSeguimiento != null) data['requiere_seguimiento'] = requiereSeguimiento;
      if (fechaProximoSeguimiento != null) {
        data['fecha_proximo_seguimiento'] = fechaProximoSeguimiento.toIso8601String().split('T')[0];
      }
      if (accionSiguiente != null) data['accion_siguiente'] = accionSiguiente;
      if (responsableSeguimiento != null) data['responsable_seguimiento'] = responsableSeguimiento;
      if (participantes != null) data['participantes'] = participantes;
      if (asistentesInternos != null) data['asistentes_internos'] = asistentesInternos;
      if (documentosVinculados != null) data['documentos_vinculados'] = documentosVinculados;
      if (observaciones != null) data['observaciones'] = observaciones;
      if (puntosClave != null) data['puntos_clave'] = puntosClave;
      if (compromisos != null) data['compromisos'] = compromisos;

      final response = await _apiClient.dio.put(
        '/crm/interacciones/$id',
        data: data,
      );

      return InteraccionCliente.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Interacción no encontrada');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al actualizar interacción: ${e.message}');
    }
  }

  /// Delete an interaccion (soft delete)
  Future<void> deleteInteraccion(int id) async {
    try {
      await _apiClient.dio.delete('/crm/interacciones/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Interacción no encontrada');
      }
      throw Exception('Error al eliminar interacción: ${e.message}');
    }
  }
}
