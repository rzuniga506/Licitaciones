import 'package:dio/dio.dart';

import 'api_client.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  /// Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/stats');
      return DashboardStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al cargar estadísticas: ${e.message}');
    }
  }

  /// Get recent activity
  Future<List<ActivityItem>> getRecentActivity({int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard/activity',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((item) => ActivityItem.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar actividad reciente: ${e.message}');
    }
  }

  /// Get upcoming deadlines
  Future<List<DeadlineItem>> getUpcomingDeadlines({int limit = 5}) async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard/upcoming-deadlines',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((item) => DeadlineItem.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al cargar vencimientos: ${e.message}');
    }
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalLicitaciones;
  final int licitacionesEnProceso;
  final double tasaExito;
  final int alertasActivas;
  final int alertasCriticas;
  final int cambioMensualLicitaciones;
  final double cambioTasaExito;

  DashboardStats({
    required this.totalLicitaciones,
    required this.licitacionesEnProceso,
    required this.tasaExito,
    required this.alertasActivas,
    required this.alertasCriticas,
    required this.cambioMensualLicitaciones,
    required this.cambioTasaExito,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalLicitaciones: json['total_licitaciones'] ?? 0,
      licitacionesEnProceso: json['licitaciones_en_proceso'] ?? 0,
      tasaExito: (json['tasa_exito'] ?? 0.0).toDouble(),
      alertasActivas: json['alertas_activas'] ?? 0,
      alertasCriticas: json['alertas_criticas'] ?? 0,
      cambioMensualLicitaciones: json['cambio_mensual_licitaciones'] ?? 0,
      cambioTasaExito: (json['cambio_tasa_exito'] ?? 0.0).toDouble(),
    );
  }

  double get porcentajeEnProceso {
    if (totalLicitaciones == 0) return 0.0;
    return (licitacionesEnProceso / totalLicitaciones) * 100;
  }
}

/// Activity item model
class ActivityItem {
  final int id;
  final String title;
  final String subtitle;
  final String tipo;
  final DateTime timestamp;
  final String? icon;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tipo,
    required this.timestamp,
    this.icon,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      tipo: json['tipo'],
      timestamp: DateTime.parse(json['timestamp']),
      icon: json['icon'],
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}

/// Deadline item model
class DeadlineItem {
  final int id;
  final String title;
  final String subtitle;
  final DateTime deadline;
  final String tipo;
  final bool isUrgent;

  DeadlineItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.deadline,
    required this.tipo,
    this.isUrgent = false,
  });

  factory DeadlineItem.fromJson(Map<String, dynamic> json) {
    return DeadlineItem(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      deadline: DateTime.parse(json['deadline']),
      tipo: json['tipo'],
      isUrgent: json['is_urgent'] ?? false,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays;
  }

  bool get isOverdue => daysRemaining < 0;
  bool get isCritical => daysRemaining <= 2;
}
