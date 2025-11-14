import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';

// ============================================================================
// State para lista de usuarios
// ============================================================================

class UsuariosState {
  final UsuarioList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? filterRole;
  final bool? filterIsActive;
  final String? filterSearch;

  UsuariosState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterRole,
    this.filterIsActive,
    this.filterSearch,
  });

  UsuariosState copyWith({
    UsuarioList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? filterRole,
    bool? filterIsActive,
    String? filterSearch,
  }) {
    return UsuariosState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      filterRole: filterRole ?? this.filterRole,
      filterIsActive: filterIsActive ?? this.filterIsActive,
      filterSearch: filterSearch ?? this.filterSearch,
    );
  }
}

// ============================================================================
// Notifier para gestión de lista de usuarios
// ============================================================================

class UsuariosNotifier extends StateNotifier<UsuariosState> {
  final UsuarioService _service = UsuarioService();

  UsuariosNotifier() : super(UsuariosState());

  Future<void> loadUsuarios({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _service.getUsuarios(
        page: state.currentPage,
        pageSize: 20,
        role: state.filterRole,
        isActive: state.filterIsActive,
        search: state.filterSearch,
      );

      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void setFilterRole(String? role) {
    state = state.copyWith(
      filterRole: role,
      currentPage: 1,
    );
    loadUsuarios();
  }

  void setFilterIsActive(bool? isActive) {
    state = state.copyWith(
      filterIsActive: isActive,
      currentPage: 1,
    );
    loadUsuarios();
  }

  void setFilterSearch(String? search) {
    state = state.copyWith(
      filterSearch: search,
      currentPage: 1,
    );
    loadUsuarios();
  }

  void clearFilters() {
    state = UsuariosState(currentPage: 1);
    loadUsuarios();
  }

  void nextPage() {
    if (state.data != null && state.currentPage < state.data!.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadUsuarios();
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadUsuarios();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && (state.data == null || page <= state.data!.totalPages)) {
      state = state.copyWith(currentPage: page);
      loadUsuarios();
    }
  }
}

// Provider para la lista
final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, UsuariosState>((ref) {
  return UsuariosNotifier();
});

// ============================================================================
// State para CRUD de usuario individual
// ============================================================================

class UsuarioCrudState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  UsuarioCrudState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  UsuarioCrudState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return UsuarioCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ============================================================================
// Notifier para operaciones CRUD
// ============================================================================

class UsuarioCrudNotifier extends StateNotifier<UsuarioCrudState> {
  final UsuarioService _service = UsuarioService();
  final Ref _ref;

  UsuarioCrudNotifier(this._ref) : super(UsuarioCrudState());

  Future<bool> createUsuario(UsuarioCreate usuario) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.createUsuario(usuario);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario creado exitosamente',
      );

      // Refrescar lista
      _ref.read(usuariosProvider.notifier).loadUsuarios(refresh: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateUsuario({
    required int usuarioId,
    required UsuarioUpdate updates,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.updateUsuario(
        usuarioId: usuarioId,
        updates: updates,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario actualizado exitosamente',
      );

      // Refrescar lista
      _ref.read(usuariosProvider.notifier).loadUsuarios();
      // Invalidar detalle
      _ref.invalidate(usuarioDetailProvider(usuarioId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteUsuario(int usuarioId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.deleteUsuario(usuarioId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario eliminado exitosamente',
      );

      // Refrescar lista
      _ref.read(usuariosProvider.notifier).loadUsuarios();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> activarUsuario(int usuarioId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.activarUsuario(usuarioId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario activado',
      );

      // Refrescar lista y detalle
      _ref.read(usuariosProvider.notifier).loadUsuarios();
      _ref.invalidate(usuarioDetailProvider(usuarioId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> desactivarUsuario(int usuarioId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.desactivarUsuario(usuarioId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario desactivado',
      );

      // Refrescar lista y detalle
      _ref.read(usuariosProvider.notifier).loadUsuarios();
      _ref.invalidate(usuarioDetailProvider(usuarioId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> cambiarRol({
    required int usuarioId,
    required String nuevoRol,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.cambiarRol(usuarioId: usuarioId, nuevoRol: nuevoRol);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Rol actualizado exitosamente',
      );

      // Refrescar lista y detalle
      _ref.read(usuariosProvider.notifier).loadUsuarios();
      _ref.invalidate(usuarioDetailProvider(usuarioId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> resetearPassword({
    required int usuarioId,
    required String newPassword,
    bool mustChangePassword = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.resetearPassword(
        usuarioId: usuarioId,
        newPassword: newPassword,
        mustChangePassword: mustChangePassword,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Contraseña reseteada exitosamente',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> desbloquearCuenta(int usuarioId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.desbloquearCuenta(usuarioId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cuenta desbloqueada exitosamente',
      );

      // Refrescar detalle
      _ref.invalidate(usuarioDetailProvider(usuarioId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Provider para CRUD
final usuarioCrudProvider =
    StateNotifierProvider<UsuarioCrudNotifier, UsuarioCrudState>((ref) {
  return UsuarioCrudNotifier(ref);
});

// ============================================================================
// Provider para obtener un usuario por ID
// ============================================================================

final usuarioDetailProvider =
    FutureProvider.family<Usuario, int>((ref, usuarioId) async {
  final service = UsuarioService();
  return await service.getUsuarioById(usuarioId);
});

// ============================================================================
// Provider para estadísticas de usuario
// ============================================================================

final usuarioStatsProvider =
    FutureProvider.family<UsuarioStats, int>((ref, usuarioId) async {
  final service = UsuarioService();
  return await service.getUsuarioStats(usuarioId);
});
