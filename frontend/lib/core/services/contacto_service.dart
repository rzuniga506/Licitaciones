import 'package:dio/dio.dart';

import '../models/contacto.dart';
import 'api_client.dart';

class ContactoService {
  final ApiClient _apiClient;

  ContactoService(this._apiClient);

  /// Get paginated list of contactos with filters
  Future<ContactoList> getContactos({
    int page = 1,
    int pageSize = 20,
    int? clienteId,
    bool? isActive,
    bool? esContactoPrincipal,
    String? nivelDecision,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (clienteId != null) queryParams['cliente_id'] = clienteId;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (esContactoPrincipal != null) {
        queryParams['es_contacto_principal'] = esContactoPrincipal;
      }
      if (nivelDecision != null && nivelDecision.isNotEmpty) {
        queryParams['nivel_decision'] = nivelDecision;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/crm/contactos',
        queryParameters: queryParams,
      );

      return ContactoList.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar contactos: ${e.message}');
    }
  }

  /// Get a single contacto by ID
  Future<Contacto> getContacto(int id) async {
    try {
      final response = await _apiClient.dio.get('/crm/contactos/$id');
      return Contacto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Contacto no encontrado');
      }
      throw Exception('Error al cargar contacto: ${e.message}');
    }
  }

  /// Create a new contacto
  Future<Contacto> createContacto({
    required int clienteId,
    required String nombreContacto,
    String? cargo,
    String? departamento,
    String? telefono,
    String? celular,
    String? email,
    String? extension,
    String? linkedinUrl,
    bool esContactoPrincipal = false,
    bool puedeFirmar = false,
    String? nivelDecision,
    String? preferenciaContacto,
    String? mejorHorarioContacto,
    String? notas,
  }) async {
    try {
      final data = <String, dynamic>{
        'cliente_id': clienteId,
        'nombre_contacto': nombreContacto,
        'es_contacto_principal': esContactoPrincipal,
        'puede_firmar': puedeFirmar,
      };

      if (cargo != null) data['cargo'] = cargo;
      if (departamento != null) data['departamento'] = departamento;
      if (telefono != null) data['telefono'] = telefono;
      if (celular != null) data['celular'] = celular;
      if (email != null) data['email'] = email;
      if (extension != null) data['extension'] = extension;
      if (linkedinUrl != null) data['linkedin_url'] = linkedinUrl;
      if (nivelDecision != null) data['nivel_decision'] = nivelDecision;
      if (preferenciaContacto != null) data['preferencia_contacto'] = preferenciaContacto;
      if (mejorHorarioContacto != null) data['mejor_horario_contacto'] = mejorHorarioContacto;
      if (notas != null) data['notas'] = notas;

      final response = await _apiClient.dio.post(
        '/crm/contactos',
        data: data,
      );

      return Contacto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al crear contacto: ${e.message}');
    }
  }

  /// Update an existing contacto
  Future<Contacto> updateContacto(
    int id, {
    String? nombreContacto,
    String? cargo,
    String? departamento,
    String? telefono,
    String? celular,
    String? email,
    String? extension,
    String? linkedinUrl,
    bool? esContactoPrincipal,
    bool? puedeFirmar,
    String? nivelDecision,
    String? preferenciaContacto,
    String? mejorHorarioContacto,
    String? notas,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (nombreContacto != null) data['nombre_contacto'] = nombreContacto;
      if (cargo != null) data['cargo'] = cargo;
      if (departamento != null) data['departamento'] = departamento;
      if (telefono != null) data['telefono'] = telefono;
      if (celular != null) data['celular'] = celular;
      if (email != null) data['email'] = email;
      if (extension != null) data['extension'] = extension;
      if (linkedinUrl != null) data['linkedin_url'] = linkedinUrl;
      if (esContactoPrincipal != null) data['es_contacto_principal'] = esContactoPrincipal;
      if (puedeFirmar != null) data['puede_firmar'] = puedeFirmar;
      if (nivelDecision != null) data['nivel_decision'] = nivelDecision;
      if (preferenciaContacto != null) data['preferencia_contacto'] = preferenciaContacto;
      if (mejorHorarioContacto != null) data['mejor_horario_contacto'] = mejorHorarioContacto;
      if (notas != null) data['notas'] = notas;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _apiClient.dio.put(
        '/crm/contactos/$id',
        data: data,
      );

      return Contacto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Contacto no encontrado');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'];
        throw Exception('Datos inválidos: $errors');
      }
      throw Exception('Error al actualizar contacto: ${e.message}');
    }
  }

  /// Delete a contacto (soft delete)
  Future<void> deleteContacto(int id) async {
    try {
      await _apiClient.dio.delete('/crm/contactos/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Contacto no encontrado');
      }
      throw Exception('Error al eliminar contacto: ${e.message}');
    }
  }
}
