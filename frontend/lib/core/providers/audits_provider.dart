import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import '../services/audit_service.dart';

// ============================================================================
// State para lista de logs de auditoría
// ============================================================================

class AuditsState {
  final AuditLogList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? filterUsuarioId;
  final String? filterAccion;
  final String? filterModulo;
  final String? filterEntidadTipo;
  final int? filterEntidadId;
  final DateTime? filterFechaDesde;
  final DateTime? filterFechaHasta;
  final String? filterResultado;
  final String? filterSearch;

  AuditsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterUsuarioId,
    this.filterAccion,
    this.filterModulo,
    this.filterEntidadTipo,
    this.filterEntidadId,
    this.filterFechaDesde,
    this.filterFechaHasta,
    this.filterResultado,
    this.filterSearch,
  });

  AuditsState copyWith({
    AuditLogList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? filterUsuarioId,
    String? filterAccion,
    String? filterModulo,
    String? filterEntidadTipo,
    int? filterEntidadId,
    DateTime? filterFechaDesde,
    DateTime? filterFechaHasta,
    String? filterResultado,
    String? filterSearch,
  }) {
    return AuditsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      filterUsuarioId: filterUsuarioId ?? this.filterUsuarioId,
      filterAccion: filterAccion ?? this.filterAccion,
      filterModulo: filterModulo ?? this.filterModulo,
      filterEntidadTipo: filterEntidadTipo ?? this.filterEntidadTipo,
      filterEntidadId: filterEntidadId ?? this.filterEntidadId,
      filterFechaDesde: filterFechaDesde ?? this.filterFechaDesde,
      filterFechaHasta: filterFechaHasta ?? this.filterFechaHasta,
      filterResultado: filterResultado ?? this.filterResultado,
      filterSearch: filterSearch ?? this.filterSearch,
    );
  }
}

// ============================================================================
// Notifier para gestión de lista de logs
// ============================================================================

class AuditsNotifier extends StateNotifier<AuditsState> {
  final AuditService _service = AuditService();

  AuditsNotifier() : super(AuditsState());

  Future<void> loadAudits({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _service.getAuditLogs(
        page: state.currentPage,
        pageSize: 50,
        usuarioId: state.filterUsuarioId,
        accion: state.filterAccion,
        modulo: state.filterModulo,
        entidadTipo: state.filterEntidadTipo,
        entidadId: state.filterEntidadId,
        fechaDesde: state.filterFechaDesde,
        fechaHasta: state.filterFechaHasta,
        resultado: state.filterResultado,
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

  void setFilterUsuarioId(int? usuarioId) {
    state = state.copyWith(
      filterUsuarioId: usuarioId,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterAccion(String? accion) {
    state = state.copyWith(
      filterAccion: accion,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterModulo(String? modulo) {
    state = state.copyWith(
      filterModulo: modulo,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterEntidadTipo(String? entidadTipo) {
    state = state.copyWith(
      filterEntidadTipo: entidadTipo,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterResultado(String? resultado) {
    state = state.copyWith(
      filterResultado: resultado,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterFechaDesde(DateTime? fecha) {
    state = state.copyWith(
      filterFechaDesde: fecha,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterFechaHasta(DateTime? fecha) {
    state = state.copyWith(
      filterFechaHasta: fecha,
      currentPage: 1,
    );
    loadAudits();
  }

  void setFilterSearch(String? search) {
    state = state.copyWith(
      filterSearch: search,
      currentPage: 1,
    );
    loadAudits();
  }

  void clearFilters() {
    state = AuditsState(currentPage: 1);
    loadAudits();
  }

  void nextPage() {
    if (state.data != null && state.currentPage < state.data!.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadAudits();
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadAudits();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && (state.data == null || page <= state.data!.totalPages)) {
      state = state.copyWith(currentPage: page);
      loadAudits();
    }
  }
}

// Provider para la lista
final auditsProvider =
    StateNotifierProvider<AuditsNotifier, AuditsState>((ref) {
  return AuditsNotifier();
});

// ============================================================================
// Provider para estadísticas de auditoría
// ============================================================================

final auditStatsProvider = FutureProvider<AuditStats>((ref) async {
  final service = AuditService();
  return await service.getAuditStats();
});

// ============================================================================
// Provider para obtener un log por ID
// ============================================================================

final auditDetailProvider =
    FutureProvider.family<AuditLog, int>((ref, auditId) async {
  final service = AuditService();
  return await service.getAuditLogById(auditId);
});
