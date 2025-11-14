import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

import '../models/documento.dart';
import 'api_client.dart';

class DocumentoService {
  final ApiClient _apiClient;

  DocumentoService(this._apiClient);

  /// Get paginated list of documentos with filters
  Future<DocumentoList> getDocumentos({
    int page = 1,
    int pageSize = 20,
    int? licitacionId,
    String? tipoDocumento,
    String? estadoDocumento,
    DateTime? vencimientoDesde,
    DateTime? vencimientoHasta,
    String? search,
    List<String>? tags,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (licitacionId != null) queryParams['licitacion_id'] = licitacionId;
      if (tipoDocumento != null && tipoDocumento.isNotEmpty) {
        queryParams['tipo_documento'] = tipoDocumento;
      }
      if (estadoDocumento != null && estadoDocumento.isNotEmpty) {
        queryParams['estado_documento'] = estadoDocumento;
      }
      if (vencimientoDesde != null) {
        queryParams['vencimiento_desde'] = vencimientoDesde.toIso8601String().split('T')[0];
      }
      if (vencimientoHasta != null) {
        queryParams['vencimiento_hasta'] = vencimientoHasta.toIso8601String().split('T')[0];
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');

      final response = await _apiClient.dio.get(
        '/documentos/',
        queryParameters: queryParams,
      );

      return DocumentoList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar documentos: ${e.message}');
    }
  }

  /// Get documentos expiring soon
  Future<List<Documento>> getDocumentosVenciendo({int dias = 15}) async {
    try {
      final response = await _apiClient.dio.get(
        '/documentos/venciendo',
        queryParameters: {'dias': dias},
      );

      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar documentos por vencer: ${e.message}');
    }
  }

  /// Get expired documentos
  Future<List<Documento>> getDocumentosVencidos() async {
    try {
      final response = await _apiClient.dio.get('/documentos/vencidos');

      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar documentos vencidos: ${e.message}');
    }
  }

  /// Get a single documento by ID
  Future<Documento> getDocumento(int id) async {
    try {
      final response = await _apiClient.dio.get('/documentos/$id');
      return Documento.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Documento no encontrado');
      }
      throw Exception('Error al cargar documento: ${e.message}');
    }
  }

  /// Get version history of a documento
  Future<List<Documento>> getVersionHistory(int documentoId) async {
    try {
      final response = await _apiClient.dio.get('/documentos/$documentoId/versions');

      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar historial de versiones: ${e.message}');
    }
  }

  /// Upload a new documento with file
  Future<Documento> uploadDocumento({
    required int licitacionId,
    required String nombreDocumento,
    required String tipoDocumento,
    required Uint8List fileBytes,
    required String fileName,
    String? descripcion,
    DateTime? fechaVencimiento,
    List<String>? tags,
  }) async {
    try {
      final formData = FormData.fromMap({
        'licitacion_id': licitacionId,
        'nombre_documento': nombreDocumento,
        'tipo_documento': tipoDocumento,
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        if (descripcion != null) 'descripcion': descripcion,
        if (fechaVencimiento != null)
          'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      });

      final response = await _apiClient.dio.post(
        '/documentos/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return Documento.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al subir documento: ${e.message}');
    }
  }

  /// Upload a new version of an existing documento
  Future<Documento> uploadNewVersion({
    required int documentoId,
    required Uint8List fileBytes,
    required String fileName,
    String? descripcion,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _apiClient.dio.post(
        '/documentos/$documentoId/new-version',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return Documento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al subir nueva versión: ${e.message}');
    }
  }

  /// Download documento file
  Future<void> downloadDocumento(int documentoId, String fileName) async {
    try {
      final response = await _apiClient.dio.get(
        '/documentos/$documentoId/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      // Trigger download in browser
      final blob = html.Blob([response.data]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Archivo no encontrado');
      }
      throw Exception('Error al descargar documento: ${e.message}');
    }
  }

  /// Update documento metadata
  Future<Documento> updateDocumento(
    int id, {
    String? nombreDocumento,
    String? tipoDocumento,
    String? categoriaDocumento,
    String? descripcion,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    int? diasAlertaVencimiento,
    List<String>? tags,
    String? estadoDocumento,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (nombreDocumento != null) data['nombre_documento'] = nombreDocumento;
      if (tipoDocumento != null) data['tipo_documento'] = tipoDocumento;
      if (categoriaDocumento != null) data['categoria_documento'] = categoriaDocumento;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (fechaEmision != null) {
        data['fecha_emision'] = fechaEmision.toIso8601String().split('T')[0];
      }
      if (fechaVencimiento != null) {
        data['fecha_vencimiento'] = fechaVencimiento.toIso8601String().split('T')[0];
      }
      if (diasAlertaVencimiento != null) {
        data['dias_alerta_vencimiento'] = diasAlertaVencimiento;
      }
      if (tags != null) data['tags'] = tags;
      if (estadoDocumento != null) data['estado_documento'] = estadoDocumento;

      final response = await _apiClient.dio.put(
        '/documentos/$id',
        data: data,
      );

      return Documento.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Documento no encontrado');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al actualizar documento: ${e.message}');
    }
  }

  /// Delete a documento (soft delete)
  Future<void> deleteDocumento(int id) async {
    try {
      await _apiClient.dio.delete('/documentos/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Documento no encontrado');
      }
      throw Exception('Error al eliminar documento: ${e.message}');
    }
  }
}
