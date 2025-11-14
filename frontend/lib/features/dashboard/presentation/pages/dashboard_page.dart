import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/services/dashboard_service.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return AppScaffold(
      title: 'Dashboard',
      currentRoute: '/',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(upcomingDeadlinesProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Resumen general del sistema',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.neutral700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                    onPressed: () {
                      ref.invalidate(dashboardStatsProvider);
                      ref.invalidate(recentActivityProvider);
                      ref.invalidate(upcomingDeadlinesProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // KPI Cards
              statsAsync.when(
                data: (stats) => _buildKPIGrid(context, stats),
                loading: () => _buildKPIGridLoading(context),
                error: (error, stack) => _buildError(
                  context,
                  'Error al cargar estadísticas',
                  error.toString(),
                  () => ref.invalidate(dashboardStatsProvider),
                ),
              ),
              const SizedBox(height: 24),

              // Charts and Lists
              _buildContentGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, DashboardStats stats) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConfig.desktopBreakpoint;
    final isTablet = size.width > AppConfig.tabletBreakpoint;

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _KPICard(
          title: 'Total Licitaciones',
          value: stats.totalLicitaciones.toString(),
          subtitle: stats.cambioMensualLicitaciones >= 0
              ? '+${stats.cambioMensualLicitaciones} este mes'
              : '${stats.cambioMensualLicitaciones} este mes',
          icon: Icons.gavel,
          color: AppTheme.primaryBlue,
        ),
        _KPICard(
          title: 'En Proceso',
          value: stats.licitacionesEnProceso.toString(),
          subtitle: '${stats.porcentajeEnProceso.toStringAsFixed(1)}% del total',
          icon: Icons.pending_actions,
          color: AppTheme.warningColor,
        ),
        _KPICard(
          title: 'Tasa de Éxito',
          value: '${stats.tasaExito.toStringAsFixed(1)}%',
          subtitle: stats.cambioTasaExito >= 0
              ? '+${stats.cambioTasaExito.toStringAsFixed(1)}% vs anterior'
              : '${stats.cambioTasaExito.toStringAsFixed(1)}% vs anterior',
          icon: Icons.trending_up,
          color: AppTheme.successColor,
        ),
        _KPICard(
          title: 'Alertas Activas',
          value: stats.alertasActivas.toString(),
          subtitle: '${stats.alertasCriticas} críticas',
          icon: Icons.notifications_active,
          color: AppTheme.errorColor,
        ),
      ],
    );
  }

  Widget _buildKPIGridLoading(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConfig.desktopBreakpoint;
    final isTablet = size.width > AppConfig.tabletBreakpoint;

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: List.generate(
        4,
        (index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String title,
    String message,
    VoidCallback onRetry,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppConfig.desktopBreakpoint;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _RecentActivity(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _UpcomingDeadlines(),
          ),
        ],
      );
    }

    return Column(
      children: [
        _RecentActivity(),
        const SizedBox(height: 24),
        _UpcomingDeadlines(),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral700,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider(5));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad Reciente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            activityAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No hay actividad reciente',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral500,
                            ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityItemWidget(activity: activity);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar actividad',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingDeadlines extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlinesAsync = ref.watch(upcomingDeadlinesProvider(5));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximos Vencimientos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            deadlinesAsync.when(
              data: (deadlines) {
                if (deadlines.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No hay vencimientos próximos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral500,
                            ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deadlines.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final deadline = deadlines[index];
                    return _DeadlineItemWidget(deadline: deadline);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar vencimientos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItemWidget extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityItemWidget({required this.activity});

  IconData _getIconForType() {
    switch (activity.tipo.toLowerCase()) {
      case 'licitacion':
        return Icons.gavel;
      case 'documento':
        return Icons.description;
      case 'alerta':
        return Icons.notifications;
      case 'contrato':
        return Icons.assignment;
      default:
        return Icons.update;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activity.icon != null
                ? IconData(int.tryParse(activity.icon!) ?? 0xe318, fontFamily: 'MaterialIcons')
                : _getIconForType(),
            size: 20,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                activity.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral700,
                    ),
              ),
            ],
          ),
        ),
        Text(
          activity.timeAgo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.neutral500,
              ),
        ),
      ],
    );
  }
}

class _DeadlineItemWidget extends StatelessWidget {
  final DeadlineItem deadline;

  const _DeadlineItemWidget({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final days = deadline.daysRemaining;
    final isUrgent = deadline.isCritical;
    final isOverdue = deadline.isOverdue;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOverdue
                ? AppTheme.errorColor.withOpacity(0.1)
                : (isUrgent
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : AppTheme.warningColor.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                isOverdue ? days.abs().toString() : days.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOverdue
                          ? AppTheme.errorColor
                          : (isUrgent ? AppTheme.errorColor : AppTheme.warningColor),
                    ),
              ),
              Text(
                isOverdue ? 'vencido' : 'días',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? AppTheme.errorColor
                          : (isUrgent ? AppTheme.errorColor : AppTheme.warningColor),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deadline.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                deadline.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
