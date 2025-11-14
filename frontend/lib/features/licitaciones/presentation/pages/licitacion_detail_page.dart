import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/licitacion.dart';
import '../../../../core/providers/licitacion_provider.dart';

class LicitacionDetailPage extends ConsumerWidget {
  final int licitacionId;

  const LicitacionDetailPage({
    super.key,
    required this.licitacionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licitacionAsync = ref.watch(licitacionDetailProvider(licitacionId));

    return AppScaffold(
      title: 'Detalle de Licitación',
      currentRoute: '/licitaciones',
      child: licitacionAsync.when(
        data: (licitacion) => _buildContent(context, ref, licitacion),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar licitación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(licitacionDetailProvider(licitacionId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Licitacion licitacion,
  ) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            licitacion.numeroLicitacion,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.neutral700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            licitacion.tituloLicitacion,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildEstadoBadge(licitacion),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar',
                      onPressed: () {
                        ref.invalidate(licitacionDetailProvider(licitacionId));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () {
                        // TODO: Implement edit
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de edición en desarrollo'),
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            title: Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirmed = await _showDeleteConfirmation(context);
                          if (confirmed == true && context.mounted) {
                            final success = await ref
                                .read(licitacionCrudProvider.notifier)
                                .deleteLicitacion(licitacionId);

                            if (success && context.mounted) {
                              ref.invalidate(licitacionesProvider);
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Licitación eliminada'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildInformacionGeneral(context, licitacion),
                            const SizedBox(height: 16),
                            _buildFechas(context, licitacion),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildMontos(context, licitacion),
                            const SizedBox(height: 16),
                            _buildEstadisticas(context, licitacion),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildInformacionGeneral(context, licitacion),
                      const SizedBox(height: 16),
                      _buildMontos(context, licitacion),
                      const SizedBox(height: 16),
                      _buildFechas(context, licitacion),
                      const SizedBox(height: 16),
                      _buildEstadisticas(context, licitacion),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(Licitacion licitacion) {
    final estado = LicitacionEstado.fromString(licitacion.estadoLicitacion);
    Color color;
    switch (estado) {
      case LicitacionEstado.adjudicada:
      case LicitacionEstado.finalizada:
        color = AppTheme.successColor;
        break;
      case LicitacionEstado.publicada:
      case LicitacionEstado.presentada:
      case LicitacionEstado.enEvaluacion:
        color = AppTheme.warningColor;
        break;
      case LicitacionEstado.rechazada:
      case LicitacionEstado.desierta:
        color = AppTheme.errorColor;
        break;
      case LicitacionEstado.enEjecucion:
        color = AppTheme.infoColor;
        break;
      default:
        color = AppTheme.neutral500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        estado.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInformacionGeneral(BuildContext context, Licitacion licitacion) {
    final categoria = LicitacionCategoria.values.firstWhere(
      (c) => c.name == licitacion.categoria,
      orElse: () => LicitacionCategoria.servicios,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Categoría', categoria.displayName),
            const Divider(height: 24),
            _buildInfoRow(context, 'Cliente ID', licitacion.clienteId.toString()),
            if (licitacion.descripcion != null) ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    licitacion.descripcion!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFechas(BuildContext context, Licitacion licitacion) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fechas Importantes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            if (licitacion.fechaPublicacion != null)
              _buildInfoRow(
                context,
                'Publicación',
                dateFormat.format(licitacion.fechaPublicacion!),
                icon: Icons.calendar_today,
              ),
            if (licitacion.fechaPresentacion != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Presentación',
                dateFormat.format(licitacion.fechaPresentacion!),
                icon: Icons.event,
              ),
            ],
            if (licitacion.fechaAdjudicacion != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Adjudicación',
                dateFormat.format(licitacion.fechaAdjudicacion!),
                icon: Icons.check_circle,
              ),
            ],
            if (licitacion.fechaInicioContrato != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Inicio Contrato',
                dateFormat.format(licitacion.fechaInicioContrato!),
                icon: Icons.play_circle,
              ),
            ],
            if (licitacion.fechaFinContrato != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Fin Contrato',
                dateFormat.format(licitacion.fechaFinContrato!),
                icon: Icons.stop_circle,
              ),
            ],
            if (licitacion.fechaVencimientoGarantia != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Vencimiento Garantía',
                dateFormat.format(licitacion.fechaVencimientoGarantia!),
                icon: Icons.security,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontos(BuildContext context, Licitacion licitacion) {
    String formatCurrency(double? amount) {
      if (amount == null) return 'No especificado';
      final formatter = NumberFormat.currency(symbol: '₡', decimalDigits: 2);
      return formatter.format(amount);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            _buildMontoCard(
              context,
              'Monto Estimado',
              formatCurrency(licitacion.montoEstimado),
              AppTheme.infoColor,
              Icons.calculate,
            ),
            const SizedBox(height: 12),
            _buildMontoCard(
              context,
              'Monto Ofertado',
              formatCurrency(licitacion.montoOfertado),
              AppTheme.warningColor,
              Icons.attach_money,
            ),
            const SizedBox(height: 12),
            _buildMontoCard(
              context,
              'Monto Adjudicado',
              formatCurrency(licitacion.montoAdjudicado),
              AppTheme.successColor,
              Icons.monetization_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas(BuildContext context, Licitacion licitacion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            if (licitacion.probabilidadExito != null) ...[
              Text(
                'Probabilidad de Éxito',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: licitacion.probabilidadExito! / 100,
                minHeight: 8,
                backgroundColor: AppTheme.neutral300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  licitacion.probabilidadExito! >= 70
                      ? AppTheme.successColor
                      : (licitacion.probabilidadExito! >= 40
                          ? AppTheme.warningColor
                          : AppTheme.errorColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${licitacion.probabilidadExito}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: licitacion.probabilidadExito! >= 70
                          ? AppTheme.successColor
                          : (licitacion.probabilidadExito! >= 40
                              ? AppTheme.warningColor
                              : AppTheme.errorColor),
                    ),
              ),
            ],
            if (licitacion.createdAt != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                context,
                'Creada',
                DateFormat('dd/MM/yyyy HH:mm').format(licitacion.createdAt!),
                icon: Icons.access_time,
              ),
            ],
            if (licitacion.updatedAt != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Última actualización',
                DateFormat('dd/MM/yyyy HH:mm').format(licitacion.updatedAt!),
                icon: Icons.update,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppTheme.neutral500),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMontoCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta licitación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
