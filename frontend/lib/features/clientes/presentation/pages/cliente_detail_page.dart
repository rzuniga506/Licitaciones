import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/cliente_provider.dart';
import '../../../../core/models/cliente.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/editar_cliente_dialog.dart';

class ClienteDetailPage extends ConsumerWidget {
  final int clienteId;

  const ClienteDetailPage({
    super.key,
    required this.clienteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteDetailProvider(clienteId));

    return AppScaffold(
      child: clienteAsync.when(
        data: (cliente) => _buildContent(context, ref, cliente),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Cliente cliente) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, cliente),
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftColumn(context, cliente)),
                const SizedBox(width: 24),
                Expanded(child: _buildRightColumn(context, cliente)),
              ],
            )
          else
            Column(
              children: [
                _buildLeftColumn(context, cliente),
                const SizedBox(height: 24),
                _buildRightColumn(context, cliente),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Cliente cliente) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/clientes'),
                ),
                const SizedBox(width: 12),
                _buildTypeIcon(cliente.tipoCliente),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCliente,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (cliente.identificacion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          cliente.identificacion!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildTipoBadge(context, cliente.tipoCliente),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditarClienteDialog(context, ref, cliente),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context, ref, cliente),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, Cliente cliente) {
    return Column(
      children: [
        _buildInfoCard(context, cliente),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, Cliente cliente) {
    return Column(
      children: [
        _buildContactCard(context, cliente),
        const SizedBox(height: 16),
        _buildMetadataCard(context, cliente),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, Cliente cliente) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Nombre', cliente.nombreCliente, Icons.business),
            const SizedBox(height: 12),
            _buildInfoRow('Tipo', cliente.tipoCliente, Icons.category_outlined),
            if (cliente.identificacion != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Identificación', cliente.identificacion!, Icons.badge_outlined),
            ],
            if (cliente.direccion != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Dirección', cliente.direccion!, Icons.location_on_outlined),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Cliente cliente) {
    final hasContact = cliente.contactoPrincipal != null ||
        cliente.email != null ||
        cliente.telefono != null;

    if (!hasContact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Sin información de contacto',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: AppTheme.successColor),
                const SizedBox(width: 8),
                Text(
                  'Información de Contacto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (cliente.contactoPrincipal != null) ...[
              _buildInfoRow('Contacto Principal', cliente.contactoPrincipal!, Icons.person_outline),
              const SizedBox(height: 12),
            ],
            if (cliente.email != null) ...[
              _buildInfoRow('Email', cliente.email!, Icons.email_outlined, isEmail: true),
              const SizedBox(height: 12),
            ],
            if (cliente.telefono != null)
              _buildInfoRow('Teléfono', cliente.telefono!, Icons.phone_outlined, isPhone: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, Cliente cliente) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Creado',
              _formatDateTime(cliente.creadoEn),
              Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Última Actualización',
              _formatDateTime(cliente.actualizadoEn),
              Icons.update_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isEmail = false, bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (isEmail)
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                )
              else if (isPhone)
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(String tipo) {
    IconData icon;
    Color color;

    switch (tipo.toLowerCase()) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildTipoBadge(BuildContext context, String tipo) {
    Color backgroundColor;
    Color textColor;

    switch (tipo.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.dangerColor),
          const SizedBox(height: 16),
          Text(
            'Error al cargar cliente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/clientes'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Clientes'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditarClienteDialog(BuildContext context, WidgetRef ref, Cliente cliente) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditarClienteDialog(cliente: cliente),
    );

    if (result == true) {
      ref.invalidate(clienteDetailProvider(clienteId));
      ref.invalidate(clientesProvider);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, Cliente cliente) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el cliente "${cliente.nombreCliente}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(clienteCrudProvider.notifier).deleteCliente(clienteId);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Cliente eliminado exitosamente'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/clientes');
        } else {
          final error = ref.read(clienteCrudProvider).error ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
