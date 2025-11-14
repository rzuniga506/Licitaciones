import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/alert.dart';
import '../../../../core/providers/alert_provider.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    final notifier = ref.read(alertsProvider.notifier);
    switch (index) {
      case 0: // Todas
        notifier.showAll();
        break;
      case 1: // Críticas
        notifier.showCritical();
        break;
      case 2: // Requieren Acción
        notifier.showRequiringAction();
        break;
      case 3: // Leídas
        notifier.showRead();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);
    final statsAsync = ref.watch(alertStatsProvider);

    return AppScaffold(
      title: 'Alertas',
      currentRoute: '/alertas',
      child: Column(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centro de Alertas',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          statsAsync.when(
                            data: (stats) => Text(
                              '${stats.totalAlertas} alertas • ${stats.activasCriticas} críticas',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.neutral700,
                                  ),
                            ),
                            loading: () => Text(
                              'Notificaciones y alertas del sistema',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.neutral700,
                                  ),
                            ),
                            error: (_, __) => Text(
                              'Notificaciones y alertas del sistema',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.neutral700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar',
                      onPressed: () {
                        ref.read(alertsProvider.notifier).refresh();
                        ref.invalidate(alertStatsProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'Todas'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Críticas'),
                          statsAsync.when(
                            data: (stats) {
                              final count = stats.activasCriticas;
                              if (count > 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Requieren Acción'),
                          statsAsync.when(
                            data: (stats) {
                              final count = stats.requierenAccion;
                              if (count > 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const Tab(text: 'Leídas'),
                  ],
                ),
              ],
            ),
          ),

          // Alerts list
          Expanded(
            child: _buildAlertsList(alertsState),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(AlertsState state) {
    if (state.isLoading && state.data == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.data == null) {
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
                'Error al cargar alertas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(alertsProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.data == null || state.data!.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: AppTheme.neutral500,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay alertas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Todo está bajo control',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral700,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(alertsProvider.notifier).refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: state.data!.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final alert = state.data!.items[index];
          return _AlertCard(
            alert: alert,
            onMarkAsRead: () async {
              final success = await ref
                  .read(alertActionProvider.notifier)
                  .markAsRead(alert.alertaId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta marcada como leída'),
                  ),
                );
              }
            },
            onResolve: () async {
              final success = await ref
                  .read(alertActionProvider.notifier)
                  .markAsResolved(alert.alertaId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta resuelta'),
                  ),
                );
              }
            },
            onDismiss: () async {
              final success = await ref
                  .read(alertActionProvider.notifier)
                  .dismissAlert(alert.alertaId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta descartada'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onMarkAsRead;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _AlertCard({
    required this.alert,
    required this.onMarkAsRead,
    required this.onResolve,
    required this.onDismiss,
  });

  Color _getPriorityColor() {
    final priority = AlertPriority.fromString(alert.nivelPrioridad);
    switch (priority) {
      case AlertPriority.critical:
        return AppTheme.errorColor;
      case AlertPriority.high:
        return AppTheme.warningColor;
      case AlertPriority.medium:
        return AppTheme.infoColor;
      case AlertPriority.low:
        return AppTheme.neutral500;
    }
  }

  IconData _getPriorityIcon() {
    final priority = AlertPriority.fromString(alert.nivelPrioridad);
    switch (priority) {
      case AlertPriority.critical:
        return Icons.error;
      case AlertPriority.high:
        return Icons.warning;
      case AlertPriority.medium:
        return Icons.info;
      case AlertPriority.low:
        return Icons.notifications;
    }
  }

  String _getTimeAgo() {
    if (alert.fechaAlerta == null) return 'Reciente';

    final now = DateTime.now();
    final difference = now.difference(alert.fechaAlerta!);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}sem';
    }
  }

  bool get isRead => alert.fechaLeida != null;

  @override
  Widget build(BuildContext context) {
    final priority = AlertPriority.fromString(alert.nivelPrioridad);

    return Card(
      color: isRead ? Colors.white : AppTheme.lightBlue,
      child: InkWell(
        onTap: !isRead ? onMarkAsRead : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPriorityIcon(),
                  color: _getPriorityColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.titulo,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          _getTimeAgo(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.mensaje,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral700,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority.displayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (alert.requiereAccion)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Requiere acción',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.warningColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        if (isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral300.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 12,
                                  color: AppTheme.neutral700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Leída',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.neutral700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'read',
                      child: ListTile(
                        leading: Icon(Icons.mark_email_read),
                        title: Text('Marcar como leída'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (alert.requiereAccion)
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.check_circle),
                        title: Text('Resolver'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'dismiss',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Descartar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'read':
                      onMarkAsRead();
                      break;
                    case 'resolve':
                      onResolve();
                      break;
                    case 'dismiss':
                      onDismiss();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
