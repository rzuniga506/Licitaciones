import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cliente_service.dart';
import '../services/api_client.dart';
import '../models/cliente.dart';

/// Provider for ClienteService
final clienteServiceProvider = Provider<ClienteService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClienteService(apiClient);
});

/// Provider for all clientes (for dropdowns)
final allClientesProvider = FutureProvider<List<Cliente>>((ref) async {
  final service = ref.watch(clienteServiceProvider);
  return service.getAllClientes();
});

/// State for clientes list with filters
class ClientesState {
  final ClienteList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? searchQuery;

  ClientesState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.searchQuery,
  });

  ClientesState copyWith({
    ClienteList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? searchQuery,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return ClientesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters => searchQuery != null;
}

/// State notifier for clientes list
class ClientesNotifier extends StateNotifier<ClientesState> {
  final ClienteService _service;

  ClientesNotifier(this._service) : super(ClientesState()) {
    loadClientes();
  }

  Future<void> loadClientes({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getClientes(
        page: state.currentPage,
        pageSize: 20,
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
    await loadClientes();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;

    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadClientes();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadClientes();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadClientes();
  }

  Future<void> refresh() async {
    await loadClientes(refresh: true);
  }
}

/// Provider for clientes list
final clientesProvider =
    StateNotifierProvider<ClientesNotifier, ClientesState>((ref) {
  final service = ref.watch(clienteServiceProvider);
  return ClientesNotifier(service);
});

/// Provider for single cliente by ID
final clienteDetailProvider =
    FutureProvider.family<Cliente, int>((ref, id) async {
  final service = ref.watch(clienteServiceProvider);
  return service.getCliente(id);
});

/// State for CRUD operations
class ClienteCrudState {
  final bool isLoading;
  final String? error;
  final Cliente? result;

  ClienteCrudState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  ClienteCrudState copyWith({
    bool? isLoading,
    String? error,
    Cliente? result,
    bool clearError = false,
  }) {
    return ClienteCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

/// State notifier for CRUD operations
class ClienteCrudNotifier extends StateNotifier<ClienteCrudState> {
  final ClienteService _service;

  ClienteCrudNotifier(this._service) : super(ClienteCrudState());

  Future<bool> createCliente({
    required String nombreCliente,
    required String tipoCliente,
    String? identificacion,
    String? telefono,
    String? email,
    String? direccion,
    String? contactoPrincipal,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.createCliente(
        nombreCliente: nombreCliente,
        tipoCliente: tipoCliente,
        identificacion: identificacion,
        telefono: telefono,
        email: email,
        direccion: direccion,
        contactoPrincipal: contactoPrincipal,
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

  Future<bool> updateCliente(
    int id, {
    String? nombreCliente,
    String? tipoCliente,
    String? identificacion,
    String? telefono,
    String? email,
    String? direccion,
    String? contactoPrincipal,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.updateCliente(
        id,
        nombreCliente: nombreCliente,
        tipoCliente: tipoCliente,
        identificacion: identificacion,
        telefono: telefono,
        email: email,
        direccion: direccion,
        contactoPrincipal: contactoPrincipal,
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

  Future<bool> deleteCliente(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteCliente(id);

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
    state = ClienteCrudState();
  }
}

/// Provider for CRUD operations
final clienteCrudProvider =
    StateNotifierProvider<ClienteCrudNotifier, ClienteCrudState>((ref) {
  final service = ref.watch(clienteServiceProvider);
  return ClienteCrudNotifier(service);
});
