import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ampliacion_prorroga.dart';
import '../services/ampliacion_service.dart';

// ============================================================================
// State para lista de ampliaciones
// ============================================================================

class AmpliacionesState {
  final AmpliacionProrrogaList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? filterLicitacionId;
  final String? filterTipo;
  final String? filterEstado;
  final DateTime? filterFechaDesde;
  final DateTime? filterFechaHasta;
  final String? filterSearch;

  AmpliacionesState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterLicitacionId,
    this.filterTipo,
    this.filterEstado,
    this.filterFechaDesde,
    this.filterFechaHasta,
    this.filterSearch,
  });

  AmpliacionesState copyWith({
    AmpliacionProrrogaList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? filterLicitacionId,
    String? filterTipo,
    String? filterEstado,
    DateTime? filterFechaDesde,
    DateTime? filterFechaHasta,
    String? filterSearch,
  }) {
    return AmpliacionesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      filterLicitacionId: filterLicitacionId ?? this.filterLicitacionId,
      filterTipo: filterTipo ?? this.filterTipo,
      filterEstado: filterEstado ?? this.filterEstado,
      filterFechaDesde: filterFechaDesde ?? this.filterFechaDesde,
      filterFechaHasta: filterFechaHasta ?? this.filterFechaHasta,
      filterSearch: filterSearch ?? this.filterSearch,
    );
  }
}

// ============================================================================
// Notifier para gestión de lista de ampliaciones
// ============================================================================

class AmpliacionesNotifier extends StateNotifier<AmpliacionesState> {
  final AmpliacionService _service = AmpliacionService();

  AmpliacionesNotifier() : super(AmpliacionesState());

  Future<void> loadAmpliaciones({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _service.getAmpliaciones(
        page: state.currentPage,
        pageSize: 20,
        licitacionId: state.filterLicitacionId,
        tipo: state.filterTipo,
        estado: state.filterEstado,
        fechaDesde: state.filterFechaDesde,
        fechaHasta: state.filterFechaHasta,
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

  void setFilterLicitacionId(int? licitacionId) {
    state = state.copyWith(
      filterLicitacionId: licitacionId,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void setFilterTipo(String? tipo) {
    state = state.copyWith(
      filterTipo: tipo,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void setFilterEstado(String? estado) {
    state = state.copyWith(
      filterEstado: estado,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void setFilterFechaDesde(DateTime? fecha) {
    state = state.copyWith(
      filterFechaDesde: fecha,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void setFilterFechaHasta(DateTime? fecha) {
    state = state.copyWith(
      filterFechaHasta: fecha,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void setFilterSearch(String? search) {
    state = state.copyWith(
      filterSearch: search,
      currentPage: 1,
    );
    loadAmpliaciones();
  }

  void clearFilters() {
    state = AmpliacionesState(currentPage: 1);
    loadAmpliaciones();
  }

  void nextPage() {
    if (state.data != null && state.currentPage < state.data!.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadAmpliaciones();
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadAmpliaciones();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && (state.data == null || page <= state.data!.totalPages)) {
      state = state.copyWith(currentPage: page);
      loadAmpliaciones();
    }
  }
}

// Provider para la lista
final ampliacionesProvider =
    StateNotifierProvider<AmpliacionesNotifier, AmpliacionesState>((ref) {
  return AmpliacionesNotifier();
});

// ============================================================================
// State para CRUD de ampliación individual
// ============================================================================

class AmpliacionCrudState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AmpliacionCrudState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AmpliacionCrudState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AmpliacionCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ============================================================================
// Notifier para operaciones CRUD
// ============================================================================

class AmpliacionCrudNotifier extends StateNotifier<AmpliacionCrudState> {
  final AmpliacionService _service = AmpliacionService();
  final Ref _ref;

  AmpliacionCrudNotifier(this._ref) : super(AmpliacionCrudState());

  Future<bool> createAmpliacion({
    required int licitacionId,
    required String tipo,
    required String justificacion,
    double? montoSolicitado,
    int? plazoSolicitadoDias,
    DateTime? fechaNuevaEntrega,
    String? observaciones,
    int? documentoSolicitudId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.createAmpliacion(
        licitacionId: licitacionId,
        tipo: tipo,
        justificacion: justificacion,
        montoSolicitado: montoSolicitado,
        plazoSolicitadoDias: plazoSolicitadoDias,
        fechaNuevaEntrega: fechaNuevaEntrega,
        observaciones: observaciones,
        documentoSolicitudId: documentoSolicitudId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ampliación creada exitosamente',
      );

      // Refrescar lista
      _ref.read(ampliacionesProvider.notifier).loadAmpliaciones(refresh: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateAmpliacion({
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
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.updateAmpliacion(
        ampliacionId: ampliacionId,
        tipo: tipo,
        estado: estado,
        montoSolicitado: montoSolicitado,
        montoAprobado: montoAprobado,
        plazoSolicitadoDias: plazoSolicitadoDias,
        plazoAprobadoDias: plazoAprobadoDias,
        fechaNuevaEntrega: fechaNuevaEntrega,
        justificacion: justificacion,
        respuestaEntidad: respuestaEntidad,
        observaciones: observaciones,
        documentoSolicitudId: documentoSolicitudId,
        documentoRespuestaId: documentoRespuestaId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ampliación actualizada exitosamente',
      );

      // Refrescar lista
      _ref.read(ampliacionesProvider.notifier).loadAmpliaciones();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteAmpliacion(int ampliacionId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.deleteAmpliacion(ampliacionId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ampliación eliminada exitosamente',
      );

      // Refrescar lista
      _ref.read(ampliacionesProvider.notifier).loadAmpliaciones();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> aprobarAmpliacion({
    required int ampliacionId,
    double? montoAprobado,
    int? plazoAprobadoDias,
    String? respuestaEntidad,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.aprobarAmpliacion(
        ampliacionId: ampliacionId,
        montoAprobado: montoAprobado,
        plazoAprobadoDias: plazoAprobadoDias,
        respuestaEntidad: respuestaEntidad,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ampliación aprobada exitosamente',
      );

      // Refrescar lista
      _ref.read(ampliacionesProvider.notifier).loadAmpliaciones();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> rechazarAmpliacion({
    required int ampliacionId,
    required String respuestaEntidad,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _service.rechazarAmpliacion(
        ampliacionId: ampliacionId,
        respuestaEntidad: respuestaEntidad,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ampliación rechazada',
      );

      // Refrescar lista
      _ref.read(ampliacionesProvider.notifier).loadAmpliaciones();

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
final ampliacionCrudProvider =
    StateNotifierProvider<AmpliacionCrudNotifier, AmpliacionCrudState>((ref) {
  return AmpliacionCrudNotifier(ref);
});

// ============================================================================
// Provider para obtener una ampliación por ID
// ============================================================================

final ampliacionDetailProvider =
    FutureProvider.family<AmpliacionProrroga, int>((ref, ampliacionId) async {
  final service = AmpliacionService();
  return await service.getAmpliacionById(ampliacionId);
});
