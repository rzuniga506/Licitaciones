import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/cliente_provider.dart';
import '../../../../core/models/cliente.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/nuevo_cliente_dialog.dart';

class ClientesPage extends ConsumerWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientesProvider);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 24),
          _buildSearchBar(context, ref, state),
          const SizedBox(height: 24),
          Expanded(
            child: _buildClientesList(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clientes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona tu cartera de clientes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showNuevoClienteDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Cliente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, ClientesState state) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, identificación...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.hasFilters
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(clientesProvider.notifier).clearFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (value) {
              ref.read(clientesProvider.notifier).setSearchQuery(
                    value.isEmpty ? null : value,
                  );
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(clientesProvider.notifier).refresh();
          },
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildClientesList(BuildContext context, WidgetRef ref, ClientesState state) {
    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar clientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(clientesProvider.notifier).refresh();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.data == null || state.data!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza agregando un nuevo cliente',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showNuevoClienteDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Cliente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(clientesProvider.notifier).refresh();
            },
            child: ListView.builder(
              itemCount: state.data!.items.length,
              itemBuilder: (context, index) {
                final cliente = state.data!.items[index];
                return _ClienteCard(
                  cliente: cliente,
                  onTap: () => context.go('/clientes/${cliente.clienteId}'),
                );
              },
            ),
          ),
        ),
        if (state.data!.totalPages > 1) _buildPagination(context, ref, state),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, WidgetRef ref, ClientesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${state.currentPage} de ${state.data!.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1
                    ? () {
                        ref.read(clientesProvider.notifier).previousPage();
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.data!.totalPages
                    ? () {
                        ref.read(clientesProvider.notifier).nextPage();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNuevoClienteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const NuevoClienteDialog(),
    );

    if (result == true) {
      ref.read(clientesProvider.notifier).refresh();
    }
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;

  const _ClienteCard({
    required this.cliente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreCliente,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (cliente.identificacion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            cliente.identificacion!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildTipoBadge(context),
                ],
              ),
              if (cliente.contactoPrincipal != null ||
                  cliente.email != null ||
                  cliente.telefono != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (cliente.contactoPrincipal != null)
                      _buildInfoChip(
                        Icons.person_outline,
                        cliente.contactoPrincipal!,
                      ),
                    if (cliente.email != null)
                      _buildInfoChip(
                        Icons.email_outlined,
                        cliente.email!,
                      ),
                    if (cliente.telefono != null)
                      _buildInfoChip(
                        Icons.phone_outlined,
                        cliente.telefono!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (cliente.tipoCliente.toLowerCase()) {
      case 'publico':
        icon = Icons.account_balance;
        color = AppTheme.primaryColor;
        break;
      case 'privado':
        icon = Icons.business;
        color = AppTheme.successColor;
        break;
      case 'mixto':
        icon = Icons.corporate_fare;
        color = AppTheme.warningColor;
        break;
      default:
        icon = Icons.business_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildTipoBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (cliente.tipoCliente.toLowerCase()) {
      case 'publico':
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        break;
      case 'privado':
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        break;
      case 'mixto':
        backgroundColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cliente.tipoCliente,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
