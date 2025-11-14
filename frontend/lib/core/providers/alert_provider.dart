import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alert_service.dart';
import '../services/api_client.dart';
import '../models/alert.dart';

/// Provider for AlertService
final alertServiceProvider = Provider<AlertService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlertService(apiClient);
});

/// State for alerts list with filters
class AlertsState {
  final AlertList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? filterPrioridad;
  final bool? filterRequiereAccion;
  final bool? filterLeidas;

  AlertsState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterPrioridad,
    this.filterRequiereAccion,
    this.filterLeidas,
  });

  AlertsState copyWith({
    AlertList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? filterPrioridad,
    bool? filterRequiereAccion,
    bool? filterLeidas,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return AlertsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      filterPrioridad:
          clearFilters ? null : (filterPrioridad ?? this.filterPrioridad),
      filterRequiereAccion: clearFilters
          ? null
          : (filterRequiereAccion ?? this.filterRequiereAccion),
      filterLeidas: clearFilters ? null : (filterLeidas ?? this.filterLeidas),
    );
  }

  bool get hasFilters =>
      filterPrioridad != null ||
      filterRequiereAccion != null ||
      filterLeidas != null;
}

/// State notifier for alerts list
class AlertsNotifier extends StateNotifier<AlertsState> {
  final AlertService _service;

  AlertsNotifier(this._service) : super(AlertsState()) {
    loadAlertas();
  }

  Future<void> loadAlertas({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getAlertas(
        page: state.currentPage,
        prioridad: state.filterPrioridad,
        requiereAccion: state.filterRequiereAccion,
        leidas: state.filterLeidas,
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
    await loadAlertas();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;

    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadAlertas();
  }

  void setFilterPrioridad(String? prioridad) {
    state = state.copyWith(filterPrioridad: prioridad, currentPage: 1);
    loadAlertas();
  }

  void setFilterRequiereAccion(bool? requiereAccion) {
    state = state.copyWith(filterRequiereAccion: requiereAccion, currentPage: 1);
    loadAlertas();
  }

  void setFilterLeidas(bool? leidas) {
    state = state.copyWith(filterLeidas: leidas, currentPage: 1);
    loadAlertas();
  }

  void showCritical() {
    state = state.copyWith(
      filterPrioridad: 'critica',
      currentPage: 1,
      clearFilters: false,
    );
    loadAlertas();
  }

  void showRequiringAction() {
    state = state.copyWith(
      filterRequiereAccion: true,
      currentPage: 1,
      clearFilters: false,
    );
    loadAlertas();
  }

  void showRead() {
    state = state.copyWith(
      filterLeidas: true,
      currentPage: 1,
      clearFilters: false,
    );
    loadAlertas();
  }

  void showAll() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadAlertas();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadAlertas();
  }

  Future<void> refresh() async {
    await loadAlertas(refresh: true);
  }
}

/// Provider for alerts list
final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  final service = ref.watch(alertServiceProvider);
  return AlertsNotifier(service);
});

/// Provider for alert statistics
final alertStatsProvider = FutureProvider<AlertStats>((ref) async {
  final service = ref.watch(alertServiceProvider);
  return service.getAlertasStats();
});

/// Provider for single alert by ID
final alertDetailProvider =
    FutureProvider.family<Alert, int>((ref, id) async {
  final service = ref.watch(alertServiceProvider);
  return service.getAlerta(id);
});

/// Provider for unread alerts count (used in app bar badge)
final unreadAlertsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(alertServiceProvider);
  try {
    final stats = await service.getAlertasStats();
    return stats.porEstado['activa'] ?? 0;
  } catch (e) {
    return 0;
  }
});

/// State for alert actions
class AlertActionState {
  final bool isLoading;
  final String? error;
  final bool success;

  AlertActionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AlertActionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) {
    return AlertActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}

/// State notifier for alert actions (mark as read, resolve, dismiss)
class AlertActionNotifier extends StateNotifier<AlertActionState> {
  final AlertService _service;
  final Ref _ref;

  AlertActionNotifier(this._service, this._ref) : super(AlertActionState());

  Future<bool> markAsRead(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.markAsRead(id);

      state = state.copyWith(isLoading: false, success: true);

      // Refresh the alerts list
      _ref.invalidate(alertsProvider);
      _ref.invalidate(alertStatsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
      return false;
    }
  }

  Future<bool> markAsResolved(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.markAsResolved(id);

      state = state.copyWith(isLoading: false, success: true);

      // Refresh the alerts list
      _ref.invalidate(alertsProvider);
      _ref.invalidate(alertStatsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
      return false;
    }
  }

  Future<bool> dismissAlert(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.dismissAlert(id);

      state = state.copyWith(isLoading: false, success: true);

      // Refresh the alerts list
      _ref.invalidate(alertsProvider);
      _ref.invalidate(alertStatsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        success: false,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = AlertActionState();
  }
}

/// Provider for alert actions
final alertActionProvider =
    StateNotifierProvider<AlertActionNotifier, AlertActionState>((ref) {
  final service = ref.watch(alertServiceProvider);
  return AlertActionNotifier(service, ref);
});
