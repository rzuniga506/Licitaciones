import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/licitacion_service.dart';
import '../services/api_client.dart';
import '../models/licitacion.dart';

/// Provider for LicitacionService
final licitacionServiceProvider = Provider<LicitacionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LicitacionService(apiClient);
});

/// State for licitaciones list with filters
class LicitacionesState {
  final LicitacionList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? filterEstado;
  final String? filterCategoria;
  final String? searchQuery;

  LicitacionesState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterEstado,
    this.filterCategoria,
    this.searchQuery,
  });

  LicitacionesState copyWith({
    LicitacionList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? filterEstado,
    String? filterCategoria,
    String? searchQuery,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return LicitacionesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      filterEstado: clearFilters ? null : (filterEstado ?? this.filterEstado),
      filterCategoria:
          clearFilters ? null : (filterCategoria ?? this.filterCategoria),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      filterEstado != null || filterCategoria != null || searchQuery != null;
}

/// State notifier for licitaciones list
class LicitacionesNotifier extends StateNotifier<LicitacionesState> {
  final LicitacionService _service;

  LicitacionesNotifier(this._service) : super(LicitacionesState()) {
    loadLicitaciones();
  }

  Future<void> loadLicitaciones({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getLicitaciones(
        page: state.currentPage,
        estado: state.filterEstado,
        categoria: state.filterCategoria,
        search: state.searchQuery,
      );

      state = state.copyWith(
        data: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> nextPage() async {
    if (state.data == null) return;
    if (state.currentPage >= state.data!.totalPages) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadLicitaciones();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;

    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadLicitaciones();
  }

  Future<void> goToPage(int page) async {
    if (state.data == null) return;
    if (page < 1 || page > state.data!.totalPages) return;

    state = state.copyWith(currentPage: page);
    await loadLicitaciones();
  }

  void setFilterEstado(String? estado) {
    state = state.copyWith(filterEstado: estado, currentPage: 1);
    loadLicitaciones();
  }

  void setFilterCategoria(String? categoria) {
    state = state.copyWith(filterCategoria: categoria, currentPage: 1);
    loadLicitaciones();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadLicitaciones();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadLicitaciones();
  }

  Future<void> refresh() async {
    await loadLicitaciones(refresh: true);
  }
}

/// Provider for licitaciones list
final licitacionesProvider =
    StateNotifierProvider<LicitacionesNotifier, LicitacionesState>((ref) {
  final service = ref.watch(licitacionServiceProvider);
  return LicitacionesNotifier(service);
});

/// Provider for single licitacion by ID
final licitacionDetailProvider =
    FutureProvider.family<Licitacion, int>((ref, id) async {
  final service = ref.watch(licitacionServiceProvider);
  return service.getLicitacion(id);
});

/// State for CRUD operations
class LicitacionCrudState {
  final bool isLoading;
  final String? error;
  final Licitacion? result;

  LicitacionCrudState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  LicitacionCrudState copyWith({
    bool? isLoading,
    String? error,
    Licitacion? result,
    bool clearError = false,
  }) {
    return LicitacionCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

/// State notifier for CRUD operations
class LicitacionCrudNotifier extends StateNotifier<LicitacionCrudState> {
  final LicitacionService _service;

  LicitacionCrudNotifier(this._service) : super(LicitacionCrudState());

  Future<bool> createLicitacion({
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.createLicitacion(
        clienteId: clienteId,
        numeroLicitacion: numeroLicitacion,
        tituloLicitacion: tituloLicitacion,
        descripcion: descripcion,
        estadoLicitacion: estadoLicitacion,
        categoria: categoria,
        fechaPublicacion: fechaPublicacion,
        fechaPresentacion: fechaPresentacion,
        montoEstimado: montoEstimado,
        montoOfertado: montoOfertado,
        probabilidadExito: probabilidadExito,
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
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

  Future<bool> updateLicitacion(
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.updateLicitacion(
        id,
        numeroLicitacion: numeroLicitacion,
        tituloLicitacion: tituloLicitacion,
        descripcion: descripcion,
        estadoLicitacion: estadoLicitacion,
        categoria: categoria,
        fechaPublicacion: fechaPublicacion,
        fechaPresentacion: fechaPresentacion,
        fechaAdjudicacion: fechaAdjudicacion,
        montoEstimado: montoEstimado,
        montoOfertado: montoOfertado,
        montoAdjudicado: montoAdjudicado,
        probabilidadExito: probabilidadExito,
        fechaInicioContrato: fechaInicioContrato,
        fechaFinContrato: fechaFinContrato,
        fechaVencimientoGarantia: fechaVencimientoGarantia,
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
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

  Future<bool> deleteLicitacion(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteLicitacion(id);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = LicitacionCrudState();
  }
}

/// Provider for CRUD operations
final licitacionCrudProvider =
    StateNotifierProvider<LicitacionCrudNotifier, LicitacionCrudState>((ref) {
  final service = ref.watch(licitacionServiceProvider);
  return LicitacionCrudNotifier(service);
});
