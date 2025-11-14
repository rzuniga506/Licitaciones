import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../services/documento_service.dart';
import '../services/api_client.dart';
import '../models/documento.dart';

/// Provider for DocumentoService
final documentoServiceProvider = Provider<DocumentoService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentoService(apiClient);
});

/// State for documentos list with filters
class DocumentosState {
  final DocumentoList? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? filterLicitacionId;
  final String? filterTipoDocumento;
  final String? filterEstadoDocumento;
  final String? searchQuery;

  DocumentosState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.filterLicitacionId,
    this.filterTipoDocumento,
    this.filterEstadoDocumento,
    this.searchQuery,
  });

  DocumentosState copyWith({
    DocumentoList? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? filterLicitacionId,
    String? filterTipoDocumento,
    String? filterEstadoDocumento,
    String? searchQuery,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return DocumentosState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      filterLicitacionId: clearFilters ? null : (filterLicitacionId ?? this.filterLicitacionId),
      filterTipoDocumento: clearFilters ? null : (filterTipoDocumento ?? this.filterTipoDocumento),
      filterEstadoDocumento: clearFilters ? null : (filterEstadoDocumento ?? this.filterEstadoDocumento),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      filterLicitacionId != null ||
      filterTipoDocumento != null ||
      filterEstadoDocumento != null ||
      searchQuery != null;
}

/// State notifier for documentos list
class DocumentosNotifier extends StateNotifier<DocumentosState> {
  final DocumentoService _service;

  DocumentosNotifier(this._service) : super(DocumentosState()) {
    loadDocumentos();
  }

  Future<void> loadDocumentos({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getDocumentos(
        page: state.currentPage,
        pageSize: 20,
        licitacionId: state.filterLicitacionId,
        tipoDocumento: state.filterTipoDocumento,
        estadoDocumento: state.filterEstadoDocumento,
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
    await loadDocumentos();
  }

  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;

    state = state.copyWith(currentPage: state.currentPage - 1);
    await loadDocumentos();
  }

  void setFilterLicitacionId(int? id) {
    state = state.copyWith(filterLicitacionId: id, currentPage: 1);
    loadDocumentos();
  }

  void setFilterTipoDocumento(String? tipo) {
    state = state.copyWith(filterTipoDocumento: tipo, currentPage: 1);
    loadDocumentos();
  }

  void setFilterEstadoDocumento(String? estado) {
    state = state.copyWith(filterEstadoDocumento: estado, currentPage: 1);
    loadDocumentos();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadDocumentos();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadDocumentos();
  }

  Future<void> refresh() async {
    await loadDocumentos(refresh: true);
  }
}

/// Provider for documentos list
final documentosProvider =
    StateNotifierProvider<DocumentosNotifier, DocumentosState>((ref) {
  final service = ref.watch(documentoServiceProvider);
  return DocumentosNotifier(service);
});

/// Provider for single documento by ID
final documentoDetailProvider =
    FutureProvider.family<Documento, int>((ref, id) async {
  final service = ref.watch(documentoServiceProvider);
  return service.getDocumento(id);
});

/// Provider for version history
final versionHistoryProvider =
    FutureProvider.family<List<Documento>, int>((ref, documentoId) async {
  final service = ref.watch(documentoServiceProvider);
  return service.getVersionHistory(documentoId);
});

/// Provider for documentos expiring soon
final documentosVenciendoProvider =
    FutureProvider.family<List<Documento>, int>((ref, dias) async {
  final service = ref.watch(documentoServiceProvider);
  return service.getDocumentosVenciendo(dias: dias);
});

/// Provider for expired documentos
final documentosVencidosProvider = FutureProvider<List<Documento>>((ref) async {
  final service = ref.watch(documentoServiceProvider);
  return service.getDocumentosVencidos();
});

/// State for upload/CRUD operations
class DocumentoCrudState {
  final bool isLoading;
  final String? error;
  final Documento? result;
  final double? uploadProgress;

  DocumentoCrudState({
    this.isLoading = false,
    this.error,
    this.result,
    this.uploadProgress,
  });

  DocumentoCrudState copyWith({
    bool? isLoading,
    String? error,
    Documento? result,
    double? uploadProgress,
    bool clearError = false,
  }) {
    return DocumentoCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// State notifier for CRUD operations
class DocumentoCrudNotifier extends StateNotifier<DocumentoCrudState> {
  final DocumentoService _service;

  DocumentoCrudNotifier(this._service) : super(DocumentoCrudState());

  Future<bool> uploadDocumento({
    required int licitacionId,
    required String nombreDocumento,
    required String tipoDocumento,
    required Uint8List fileBytes,
    required String fileName,
    String? descripcion,
    DateTime? fechaVencimiento,
    List<String>? tags,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.uploadDocumento(
        licitacionId: licitacionId,
        nombreDocumento: nombreDocumento,
        tipoDocumento: tipoDocumento,
        fileBytes: fileBytes,
        fileName: fileName,
        descripcion: descripcion,
        fechaVencimiento: fechaVencimiento,
        tags: tags,
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

  Future<bool> uploadNewVersion({
    required int documentoId,
    required Uint8List fileBytes,
    required String fileName,
    String? descripcion,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.uploadNewVersion(
        documentoId: documentoId,
        fileBytes: fileBytes,
        fileName: fileName,
        descripcion: descripcion,
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

  Future<bool> downloadDocumento(int documentoId, String fileName) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.downloadDocumento(documentoId, fileName);

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

  Future<bool> updateDocumento(
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.updateDocumento(
        id,
        nombreDocumento: nombreDocumento,
        tipoDocumento: tipoDocumento,
        categoriaDocumento: categoriaDocumento,
        descripcion: descripcion,
        fechaEmision: fechaEmision,
        fechaVencimiento: fechaVencimiento,
        diasAlertaVencimiento: diasAlertaVencimiento,
        tags: tags,
        estadoDocumento: estadoDocumento,
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

  Future<bool> deleteDocumento(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteDocumento(id);

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
    state = DocumentoCrudState();
  }
}

/// Provider for CRUD operations
final documentoCrudProvider =
    StateNotifierProvider<DocumentoCrudNotifier, DocumentoCrudState>((ref) {
  final service = ref.watch(documentoServiceProvider);
  return DocumentoCrudNotifier(service);
});
