import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dashboard_service.dart';
import '../services/api_client.dart';

/// Provider for DashboardService
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
});

/// Provider for dashboard statistics
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getDashboardStats();
});

/// Provider for recent activity with auto-refresh
final recentActivityProvider = FutureProvider.family<List<ActivityItem>, int>(
  (ref, limit) async {
    final service = ref.watch(dashboardServiceProvider);
    return service.getRecentActivity(limit: limit);
  },
);

/// Provider for upcoming deadlines with auto-refresh
final upcomingDeadlinesProvider = FutureProvider.family<List<DeadlineItem>, int>(
  (ref, limit) async {
    final service = ref.watch(dashboardServiceProvider);
    return service.getUpcomingDeadlines(limit: limit);
  },
);

/// State notifier for manual refresh control
class DashboardRefreshNotifier extends StateNotifier<int> {
  DashboardRefreshNotifier() : super(0);

  void refresh() {
    state++;
  }
}

final dashboardRefreshProvider =
    StateNotifierProvider<DashboardRefreshNotifier, int>((ref) {
  return DashboardRefreshNotifier();
});
