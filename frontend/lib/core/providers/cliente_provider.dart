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
