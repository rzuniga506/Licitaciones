import 'package:dio/dio.dart';
import '../models/ampliacion_prorroga.dart';
import '../utils/api_client.dart';

class AmpliacionService {
  final Dio _dio = ApiClient.dio;

  /// Obtiene lista de ampliaciones/prórrogas con filtros y paginación
  Future<AmpliacionProrrogaList> getAmpliaciones({
    int page = 1,
    int pageSize = 20,
    int? licitacionId,
    String? tipo,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (licitacionId != null) {
        queryParameters['licitacion_id'] = licitacionId;
      }
      if (tipo != null && tipo.isNotEmpty) {
        queryParameters['tipo'] = tipo;
      }
      if (estado != null && estado.isNotEmpty) {
        queryParameters['estado'] = estado;
      }
      if (fechaDesde != null) {
        queryParameters['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fecha_hasta'] = fechaHasta.toIso8601String();
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/ampliaciones',
        queryParameters: queryParameters,
      );

      return AmpliacionProrrogaList.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener ampliaciones: $e');
    }
  }

  /// Obtiene una ampliación/prórroga por ID
  Future<AmpliacionProrroga> getAmpliacionById(int ampliacionId) async {
    try {
      final response = await _dio.get('/ampliaciones/$ampliacionId');
      return AmpliacionProrroga.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener ampliación: $e');
    }
  }

  /// Crea una nueva ampliación/prórroga
  Future<AmpliacionProrroga> createAmpliacion({
    required int licitacionId,
    required String tipo,
    required String justificacion,
    double? montoSolicitado,
    int? plazoSolicitadoDias,
    DateTime? fechaNuevaEntrega,
    String? observaciones,
    int? documentoSolicitudId,
  }) async {
    try {
      final data = <String, dynamic>{
        'licitacion_id': licitacionId,
        'tipo': tipo,
        'justificacion': justificacion,
      };

      if (montoSolicitado != null) {
        data['monto_solicitado'] = montoSolicitado;
      }
      if (plazoSolicitadoDias != null) {
        data['plazo_solicitado_dias'] = plazoSolicitadoDias;
      }
      if (fechaNuevaEntrega != null) {
        data['fecha_nueva_entrega'] = fechaNuevaEntrega.toIso8601String();
      }
      if (observaciones != null && observaciones.isNotEmpty) {
        data['observaciones'] = observaciones;
      }
      if (documentoSolicitudId != null) {
        data['documento_solicitud_id'] = documentoSolicitudId;
      }

      final response = await _dio.post('/ampliaciones', data: data);
      return AmpliacionProrroga.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear ampliación: $e');
    }
  }

  /// Actualiza una ampliación/prórroga existente
  Future<AmpliacionProrroga> updateAmpliacion({
    required int ampliacionId,
    String? tipo,
    String? estado,
    double? montoSolicitado,
    double? montoAprobado,
    int? plazoSolicitadoDias,
    int? plazoAprobadoDias,
    DateTime? fechaNuevaEntrega,
    String? justificacion,
    String? respuestaEntidad,
    String? observaciones,
    int? documentoSolicitudId,
    int? documentoRespuestaId,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (tipo != null) data['tipo'] = tipo;
      if (estado != null) data['estado'] = estado;
      if (montoSolicitado != null) data['monto_solicitado'] = montoSolicitado;
      if (montoAprobado != null) data['monto_aprobado'] = montoAprobado;
      if (plazoSolicitadoDias != null) {
        data['plazo_solicitado_dias'] = plazoSolicitadoDias;
      }
      if (plazoAprobadoDias != null) {
        data['plazo_aprobado_dias'] = plazoAprobadoDias;
      }
      if (fechaNuevaEntrega != null) {
        data['fecha_nueva_entrega'] = fechaNuevaEntrega.toIso8601String();
      }
      if (justificacion != null) data['justificacion'] = justificacion;
      if (respuestaEntidad != null) {
        data['respuesta_entidad'] = respuestaEntidad;
      }
      if (observaciones != null) data['observaciones'] = observaciones;
      if (documentoSolicitudId != null) {
        data['documento_solicitud_id'] = documentoSolicitudId;
      }
      if (documentoRespuestaId != null) {
        data['documento_respuesta_id'] = documentoRespuestaId;
      }

      final response = await _dio.put(
        '/ampliaciones/$ampliacionId',
        data: data,
      );
      return AmpliacionProrroga.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar ampliación: $e');
    }
  }

  /// Elimina una ampliación/prórroga
  Future<void> deleteAmpliacion(int ampliacionId) async {
    try {
      await _dio.delete('/ampliaciones/$ampliacionId');
    } catch (e) {
      throw Exception('Error al eliminar ampliación: $e');
    }
  }

  /// Aprueba una ampliación/prórroga
  Future<AmpliacionProrroga> aprobarAmpliacion({
    required int ampliacionId,
    double? montoAprobado,
    int? plazoAprobadoDias,
    String? respuestaEntidad,
  }) async {
    try {
      final data = <String, dynamic>{
        'estado': 'aprobada',
      };

      if (montoAprobado != null) data['monto_aprobado'] = montoAprobado;
      if (plazoAprobadoDias != null) {
        data['plazo_aprobado_dias'] = plazoAprobadoDias;
      }
      if (respuestaEntidad != null) {
        data['respuesta_entidad'] = respuestaEntidad;
      }

      final response = await _dio.put(
        '/ampliaciones/$ampliacionId',
        data: data,
      );
      return AmpliacionProrroga.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al aprobar ampliación: $e');
    }
  }

  /// Rechaza una ampliación/prórroga
  Future<AmpliacionProrroga> rechazarAmpliacion({
    required int ampliacionId,
    required String respuestaEntidad,
  }) async {
    try {
      final data = {
        'estado': 'rechazada',
        'respuesta_entidad': respuestaEntidad,
      };

      final response = await _dio.put(
        '/ampliaciones/$ampliacionId',
        data: data,
      );
      return AmpliacionProrroga.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al rechazar ampliación: $e');
    }
  }
}
