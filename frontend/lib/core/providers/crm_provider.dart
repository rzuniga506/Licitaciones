import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contacto_service.dart';
import '../services/interaccion_service.dart';
import '../services/api_client.dart';
import '../models/contacto.dart';
import '../models/interaccion_cliente.dart';

/// Provider for ContactoService
final contactoServiceProvider = Provider<ContactoService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContactoService(apiClient);
});

/// Provider for InteraccionService
final interaccionServiceProvider = Provider<InteraccionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InteraccionService(apiClient);
});

// ==================== CONTACTOS ====================

/// State for contactos list with filters
class ContactosState {
  final ContactoList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? filterClienteId;
  final bool? filterEsContactoPrincipal;
  final String? filterNivelDecision;
  final String? searchQuery;

  ContactosState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterClienteId,
    this.filterEsContactoPrincipal,
    this.filterNivelDecision,
    this.searchQuery,
  });

  ContactosState copyWith({
    ContactoList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? filterClienteId,
    bool? filterEsContactoPrincipal,
    String? filterNivelDecision,
    String? searchQuery,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return ContactosState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      filterClienteId: clearFilters ? null : (filterClienteId ?? this.filterClienteId),
      filterEsContactoPrincipal: clearFilters ? null : (filterEsContactoPrincipal ?? this.filterEsContactoPrincipal),
      filterNivelDecision: clearFilters ? null : (filterNivelDecision ?? this.filterNivelDecision),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      filterClienteId != null ||
      filterEsContactoPrincipal != null ||
      filterNivelDecision != null ||
      searchQuery != null;
}

/// State notifier for contactos list
class ContactosNotifier extends StateNotifier<ContactosState> {
  final ContactoService _service;

  ContactosNotifier(this._service) : super(ContactosState()) {
    loadContactos();
  }

  Future<void> loadContactos({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getContactos(
        page: state.currentPage,
        pageSize: 20,
        clienteId: state.filterClienteId,
        esContactoPrincipal: state.filterEsContactoPrincipal,
        nivelDecision: state.filterNivelDecision,
        search: state.searchQuery,
      );

      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> nextPage() async {
    if (state.data == null || state.currentPage >= state.data!.totalPages) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadContactos();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;
    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadContactos();
  }

  void setFilterClienteId(int? id) {
    state = state.copyWith(filterClienteId: id, currentPage: 1);
    loadContactos();
  }

  void setFilterEsContactoPrincipal(bool? value) {
    state = state.copyWith(filterEsContactoPrincipal: value, currentPage: 1);
    loadContactos();
  }

  void setFilterNivelDecision(String? nivel) {
    state = state.copyWith(filterNivelDecision: nivel, currentPage: 1);
    loadContactos();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadContactos();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadContactos();
  }

  Future<void> refresh() async {
    await loadContactos(refresh: true);
  }
}

final contactosProvider = StateNotifierProvider<ContactosNotifier, ContactosState>((ref) {
  final service = ref.watch(contactoServiceProvider);
  return ContactosNotifier(service);
});

final contactoDetailProvider = FutureProvider.family<Contacto, int>((ref, id) async {
  final service = ref.watch(contactoServiceProvider);
  return service.getContacto(id);
});

/// State for CRUD operations
class ContactoCrudState {
  final bool isLoading;
  final String? error;
  final Contacto? result;

  ContactoCrudState({this.isLoading = false, this.error, this.result});

  ContactoCrudState copyWith({
    bool? isLoading,
    String? error,
    Contacto? result,
    bool clearError = false,
  }) {
    return ContactoCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

class ContactoCrudNotifier extends StateNotifier<ContactoCrudState> {
  final ContactoService _service;

  ContactoCrudNotifier(this._service) : super(ContactoCrudState());

  Future<bool> createContacto({
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.createContacto(
        clienteId: clienteId,
        nombreContacto: nombreContacto,
        cargo: cargo,
        departamento: departamento,
        telefono: telefono,
        celular: celular,
        email: email,
        extension: extension,
        linkedinUrl: linkedinUrl,
        esContactoPrincipal: esContactoPrincipal,
        puedeFirmar: puedeFirmar,
        nivelDecision: nivelDecision,
        preferenciaContacto: preferenciaContacto,
        mejorHorarioContacto: mejorHorarioContacto,
        notas: notas,
      );

      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateContacto(int id, {
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
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.updateContacto(
        id,
        nombreContacto: nombreContacto,
        cargo: cargo,
        departamento: departamento,
        telefono: telefono,
        celular: celular,
        email: email,
        extension: extension,
        linkedinUrl: linkedinUrl,
        esContactoPrincipal: esContactoPrincipal,
        puedeFirmar: puedeFirmar,
        nivelDecision: nivelDecision,
        preferenciaContacto: preferenciaContacto,
        mejorHorarioContacto: mejorHorarioContacto,
        notas: notas,
      );

      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteContacto(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteContacto(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final contactoCrudProvider = StateNotifierProvider<ContactoCrudNotifier, ContactoCrudState>((ref) {
  final service = ref.watch(contactoServiceProvider);
  return ContactoCrudNotifier(service);
});

// ==================== INTERACCIONES ====================

class InteraccionesState {
  final InteraccionClienteList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? filterClienteId;
  final int? filterContactoId;
  final String? filterTipoInteraccion;
  final bool? filterRequiereSeguimiento;
  final String? searchQuery;

  InteraccionesState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterClienteId,
    this.filterContactoId,
    this.filterTipoInteraccion,
    this.filterRequiereSeguimiento,
    this.searchQuery,
  });

  InteraccionesState copyWith({
    InteraccionClienteList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? filterClienteId,
    int? filterContactoId,
    String? filterTipoInteraccion,
    bool? filterRequiereSeguimiento,
    String? searchQuery,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return InteraccionesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      filterClienteId: clearFilters ? null : (filterClienteId ?? this.filterClienteId),
      filterContactoId: clearFilters ? null : (filterContactoId ?? this.filterContactoId),
      filterTipoInteraccion: clearFilters ? null : (filterTipoInteraccion ?? this.filterTipoInteraccion),
      filterRequiereSeguimiento: clearFilters ? null : (filterRequiereSeguimiento ?? this.filterRequiereSeguimiento),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      filterClienteId != null ||
      filterContactoId != null ||
      filterTipoInteraccion != null ||
      filterRequiereSeguimiento != null ||
      searchQuery != null;
}

class InteraccionesNotifier extends StateNotifier<InteraccionesState> {
  final InteraccionService _service;

  InteraccionesNotifier(this._service) : super(InteraccionesState()) {
    loadInteracciones();
  }

  Future<void> loadInteracciones({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getInteracciones(
        page: state.currentPage,
        pageSize: 20,
        clienteId: state.filterClienteId,
        contactoId: state.filterContactoId,
        tipoInteraccion: state.filterTipoInteraccion,
        requiereSeguimiento: state.filterRequiereSeguimiento,
        search: state.searchQuery,
      );

      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> nextPage() async {
    if (state.data == null || state.currentPage >= state.data!.totalPages) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadInteracciones();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;
    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadInteracciones();
  }

  void setFilterClienteId(int? id) {
    state = state.copyWith(filterClienteId: id, currentPage: 1);
    loadInteracciones();
  }

  void setFilterContactoId(int? id) {
    state = state.copyWith(filterContactoId: id, currentPage: 1);
    loadInteracciones();
  }

  void setFilterTipoInteraccion(String? tipo) {
    state = state.copyWith(filterTipoInteraccion: tipo, currentPage: 1);
    loadInteracciones();
  }

  void setFilterRequiereSeguimiento(bool? value) {
    state = state.copyWith(filterRequiereSeguimiento: value, currentPage: 1);
    loadInteracciones();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadInteracciones();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadInteracciones();
  }

  Future<void> refresh() async {
    await loadInteracciones(refresh: true);
  }
}

final interaccionesProvider = StateNotifierProvider<InteraccionesNotifier, InteraccionesState>((ref) {
  final service = ref.watch(interaccionServiceProvider);
  return InteraccionesNotifier(service);
});

final interaccionDetailProvider = FutureProvider.family<InteraccionCliente, int>((ref, id) async {
  final service = ref.watch(interaccionServiceProvider);
  return service.getInteraccion(id);
});

class InteraccionCrudState {
  final bool isLoading;
  final String? error;
  final InteraccionCliente? result;

  InteraccionCrudState({this.isLoading = false, this.error, this.result});

  InteraccionCrudState copyWith({
    bool? isLoading,
    String? error,
    InteraccionCliente? result,
    bool clearError = false,
  }) {
    return InteraccionCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

class InteraccionCrudNotifier extends StateNotifier<InteraccionCrudState> {
  final InteraccionService _service;

  InteraccionCrudNotifier(this._service) : super(InteraccionCrudState());

  Future<bool> createInteraccion({
    required int clienteId,
    int? contactoId,
    int? licitacionId,
    required String tipoInteraccion,
    required String titulo,
    required String descripcion,
    required DateTime fechaInteraccion,
    int? duracionMinutos,
    String? ubicacion,
    String? modalidad,
    String? resultado,
    int? nivelInteres,
    bool requiereSeguimiento = false,
    DateTime? fechaProximoSeguimiento,
    String? accionSiguiente,
    List<String>? participantes,
    String? observaciones,
    String? puntosClave,
    String? compromisos,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.createInteraccion(
        clienteId: clienteId,
        contactoId: contactoId,
        licitacionId: licitacionId,
        tipoInteraccion: tipoInteraccion,
        titulo: titulo,
        descripcion: descripcion,
        fechaInteraccion: fechaInteraccion,
        duracionMinutos: duracionMinutos,
        ubicacion: ubicacion,
        modalidad: modalidad,
        resultado: resultado,
        nivelInteres: nivelInteres,
        requiereSeguimiento: requiereSeguimiento,
        fechaProximoSeguimiento: fechaProximoSeguimiento,
        accionSiguiente: accionSiguiente,
        participantes: participantes,
        observaciones: observaciones,
        puntosClave: puntosClave,
        compromisos: compromisos,
      );

      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateInteraccion(int id, {
    String? titulo,
    String? descripcion,
    String? tipoInteraccion,
    DateTime? fechaInteraccion,
    int? duracionMinutos,
    String? ubicacion,
    String? modalidad,
    String? resultado,
    int? nivelInteres,
    bool? requiereSeguimiento,
    DateTime? fechaProximoSeguimiento,
    String? accionSiguiente,
    List<String>? participantes,
    String? observaciones,
    String? puntosClave,
    String? compromisos,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.updateInteraccion(
        id,
        titulo: titulo,
        descripcion: descripcion,
        tipoInteraccion: tipoInteraccion,
        fechaInteraccion: fechaInteraccion,
        duracionMinutos: duracionMinutos,
        ubicacion: ubicacion,
        modalidad: modalidad,
        resultado: resultado,
        nivelInteres: nivelInteres,
        requiereSeguimiento: requiereSeguimiento,
        fechaProximoSeguimiento: fechaProximoSeguimiento,
        accionSiguiente: accionSiguiente,
        participantes: participantes,
        observaciones: observaciones,
        puntosClave: puntosClave,
        compromisos: compromisos,
      );

      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteInteraccion(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteInteraccion(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final interaccionCrudProvider = StateNotifierProvider<InteraccionCrudNotifier, InteraccionCrudState>((ref) {
  final service = ref.watch(interaccionServiceProvider);
  return InteraccionCrudNotifier(service);
});
