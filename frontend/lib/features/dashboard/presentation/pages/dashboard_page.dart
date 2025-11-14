import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Dashboard',
      currentRoute: '/',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
            const SizedBox(height: 32),

            // KPI Cards
            _buildKPIGrid(context),
            const SizedBox(height: 24),

            // Charts and Lists
            _buildContentGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
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
          value: '120',
          subtitle: '+12 este mes',
          icon: Icons.gavel,
          color: AppTheme.primaryBlue,
        ),
        _KPICard(
          title: 'En Proceso',
          value: '35',
          subtitle: '29% del total',
          icon: Icons.pending_actions,
          color: AppTheme.warningColor,
        ),
        _KPICard(
          title: 'Tasa de Éxito',
          value: '70.5%',
          subtitle: '+5.2% vs anterior',
          icon: Icons.trending_up,
          color: AppTheme.successColor,
        ),
        _KPICard(
          title: 'Alertas Activas',
          value: '8',
          subtitle: '3 críticas',
          icon: Icons.notifications_active,
          color: AppTheme.errorColor,
        ),
      ],
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

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) => _ActivityItem(
                title: 'Licitación #2025-LIC-00${index + 1}',
                subtitle: 'Estado actualizado a "En Evaluación"',
                time: '${index + 1}h',
                icon: Icons.update,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingDeadlines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) => _DeadlineItem(
                title: 'Presentación Oferta',
                subtitle: 'LIC-${2025 - index}-001',
                days: index + 2,
                isUrgent: index == 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

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
            icon,
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
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral700,
                    ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.neutral500,
              ),
        ),
      ],
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int days;
  final bool isUrgent;

  const _DeadlineItem({
    required this.title,
    required this.subtitle,
    required this.days,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                days.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUrgent ? AppTheme.errorColor : AppTheme.warningColor,
                    ),
              ),
              Text(
                'días',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUrgent ? AppTheme.errorColor : AppTheme.warningColor,
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
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
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
