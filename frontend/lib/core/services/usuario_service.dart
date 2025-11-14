import 'package:dio/dio.dart';
import '../models/usuario.dart';
import '../utils/api_client.dart';

class UsuarioService {
  final Dio _dio = ApiClient.dio;

  /// Obtiene lista de usuarios con filtros y paginación
  Future<UsuarioList> getUsuarios({
    int page = 1,
    int pageSize = 20,
    String? role,
    bool? isActive,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (role != null && role.isNotEmpty) {
        queryParameters['role'] = role;
      }
      if (isActive != null) {
        queryParameters['is_active'] = isActive;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/usuarios',
        queryParameters: queryParameters,
      );

      return UsuarioList.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Obtiene un usuario por ID
  Future<Usuario> getUsuarioById(int usuarioId) async {
    try {
      final response = await _dio.get('/usuarios/$usuarioId');
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Crea un nuevo usuario
  Future<Usuario> createUsuario(UsuarioCreate usuario) async {
    try {
      final response = await _dio.post(
        '/usuarios',
        data: usuario.toJson(),
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Actualiza un usuario existente
  Future<Usuario> updateUsuario({
    required int usuarioId,
    required UsuarioUpdate updates,
  }) async {
    try {
      final response = await _dio.put(
        '/usuarios/$usuarioId',
        data: updates.toJson(),
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Elimina un usuario (soft delete)
  Future<void> deleteUsuario(int usuarioId) async {
    try {
      await _dio.delete('/usuarios/$usuarioId');
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Activa un usuario
  Future<Usuario> activarUsuario(int usuarioId) async {
    try {
      final response = await _dio.put(
        '/usuarios/$usuarioId',
        data: {'is_active': true},
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al activar usuario: $e');
    }
  }

  /// Desactiva un usuario
  Future<Usuario> desactivarUsuario(int usuarioId) async {
    try {
      final response = await _dio.put(
        '/usuarios/$usuarioId',
        data: {'is_active': false},
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al desactivar usuario: $e');
    }
  }

  /// Resetea la contraseña de un usuario
  Future<void> resetearPassword({
    required int usuarioId,
    required String newPassword,
    bool mustChangePassword = true,
  }) async {
    try {
      await _dio.post(
        '/usuarios/$usuarioId/reset-password',
        data: {
          'password': newPassword,
          'must_change_password': mustChangePassword,
        },
      );
    } catch (e) {
      throw Exception('Error al resetear contraseña: $e');
    }
  }

  /// Cambia el rol de un usuario
  Future<Usuario> cambiarRol({
    required int usuarioId,
    required String nuevoRol,
  }) async {
    try {
      final response = await _dio.put(
        '/usuarios/$usuarioId',
        data: {'role': nuevoRol},
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cambiar rol: $e');
    }
  }

  /// Obtiene estadísticas de uso de un usuario
  Future<UsuarioStats> getUsuarioStats(int usuarioId) async {
    try {
      final response = await _dio.get('/usuarios/$usuarioId/stats');
      return UsuarioStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Desbloquea una cuenta (resetea intentos fallidos)
  Future<Usuario> desbloquearCuenta(int usuarioId) async {
    try {
      final response = await _dio.post(
        '/usuarios/$usuarioId/unlock',
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al desbloquear cuenta: $e');
    }
  }

  /// Verifica si un username está disponible
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _dio.get(
        '/usuarios/check-username',
        queryParameters: {'username': username},
      );
      return response.data['available'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si un email está disponible
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _dio.get(
        '/usuarios/check-email',
        queryParameters: {'email': email},
      );
      return response.data['available'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el historial de actividad de un usuario
  Future<List<Map<String, dynamic>>> getActivityLog(
    int usuarioId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/usuarios/$usuarioId/activity',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return List<Map<String, dynamic>>.from(response.data['activities'] ?? []);
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }
}
