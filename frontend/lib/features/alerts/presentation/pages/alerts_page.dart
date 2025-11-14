import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/alert.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Centro de Alertas',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Notificaciones y alertas del sistema',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.neutral700,
                      ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Todas'),
                    Tab(text: 'Críticas'),
                    Tab(text: 'Requieren Acción'),
                    Tab(text: 'Leídas'),
                  ],
                ),
              ],
            ),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsList(context, null),
                _buildAlertsList(context, AlertPriority.critical),
                _buildAlertsList(context, null, requiresAction: true),
                _buildAlertsList(context, null, isRead: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(
    BuildContext context,
    AlertPriority? priority, {
    bool requiresAction = false,
    bool isRead = false,
  }) {
    // TODO: Replace with real data
    final alerts = List.generate(
      10,
      (index) => _MockAlert(
        id: index,
        title: 'Documento próximo a vencer',
        message: 'El documento "Certificación Fiscal" vence en ${index + 1} días',
        priority: index == 0
            ? AlertPriority.critical
            : (index == 1 ? AlertPriority.high : AlertPriority.medium),
        time: DateTime.now().subtract(Duration(hours: index)),
        isRead: isRead,
      ),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AlertCard(alert: alerts[index]),
    );
  }
}

class _MockAlert {
  final int id;
  final String title;
  final String message;
  final AlertPriority priority;
  final DateTime time;
  final bool isRead;

  _MockAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.time,
    required this.isRead,
  });
}

class _AlertCard extends StatelessWidget {
  final _MockAlert alert;

  const _AlertCard({required this.alert});

  Color _getPriorityColor() {
    switch (alert.priority) {
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
    switch (alert.priority) {
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
    final now = DateTime.now();
    final difference = now.difference(alert.time);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: alert.isRead ? Colors.white : AppTheme.lightBlue,
      child: InkWell(
        onTap: () {
          // TODO: Handle alert tap
        },
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
                            alert.title,
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
                      alert.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                            alert.priority.displayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Menu
              IconButton(
                icon: const Icon(Icons.more_vert),
                iconSize: 20,
                onPressed: () {
                  // TODO: Show menu
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
