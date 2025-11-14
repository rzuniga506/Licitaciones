import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/audits_provider.dart';
import '../../../../core/models/audit_log.dart';

class AuditoriaPage extends ConsumerStatefulWidget {
  const AuditoriaPage({super.key});

  @override
  ConsumerState<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends ConsumerState<AuditoriaPage> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(auditsProvider.notifier).loadAudits(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditsProvider);
    final statsAsync = ref.watch(auditStatsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auditoría del Sistema',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Registro completo de actividades y cambios',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                      ),
                      tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Exportar a CSV
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de exportación pendiente'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar'),
                    ),
                  ],
                ),

                // Estadísticas rápidas
                const SizedBox(height: 16),
                statsAsync.when(
                  data: (stats) => _buildQuickStats(context, stats),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Filtros expandibles
          if (_showFilters) _buildFilters(),

          // Timeline de logs
          Expanded(
            child: state.isLoading && state.data == null
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: ${state.error}'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref
                                  .read(auditsProvider.notifier)
                                  .loadAudits(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : state.data == null || state.data!.logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay eventos de auditoría',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          )
                        : _buildAuditTimeline(state.data!),
          ),

          // Paginación
          if (state.data != null && state.data!.totalPages > 1)
            _buildPagination(state),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AuditStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Eventos',
            '${stats.totalEventos}',
            Icons.analytics,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Eventos Hoy',
            '${stats.eventosHoy}',
            Icons.today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Usuarios Activos',
            '${stats.usuariosActivos}',
            Icons.people,
            Colors.purple,
          ),
        ),
        if (stats.erroresRecientes != null && stats.erroresRecientes! > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Errores Recientes',
              '${stats.erroresRecientes}',
              Icons.warning,
              Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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

  Widget _buildFilters() {
    final state = ref.watch(auditsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila de filtros
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Búsqueda
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.filterSearch != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(auditsProvider.notifier)
                                  .setFilterSearch(null);
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    ref
                        .read(auditsProvider.notifier)
                        .setFilterSearch(value.isEmpty ? null : value);
                  },
                ),
              ),

              // Filtro Acción
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: state.filterAccion,
                  decoration: const InputDecoration(
                    labelText: 'Acción',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: 'create', child: Text('Crear')),
                    DropdownMenuItem(value: 'update', child: Text('Actualizar')),
                    DropdownMenuItem(value: 'delete', child: Text('Eliminar')),
                    DropdownMenuItem(value: 'login', child: Text('Login')),
                    DropdownMenuItem(value: 'logout', child: Text('Logout')),
                    DropdownMenuItem(value: 'export', child: Text('Exportar')),
                  ],
                  onChanged: (value) {
                    ref.read(auditsProvider.notifier).setFilterAccion(value);
                  },
                ),
              ),

              // Filtro Módulo
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: state.filterModulo,
                  decoration: const InputDecoration(
                    labelText: 'Módulo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'licitaciones', child: Text('Licitaciones')),
                    DropdownMenuItem(value: 'clientes', child: Text('Clientes')),
                    DropdownMenuItem(value: 'documentos', child: Text('Documentos')),
                    DropdownMenuItem(value: 'crm', child: Text('CRM')),
                    DropdownMenuItem(value: 'ampliaciones', child: Text('Ampliaciones')),
                    DropdownMenuItem(value: 'usuarios', child: Text('Usuarios')),
                    DropdownMenuItem(value: 'auth', child: Text('Autenticación')),
                  ],
                  onChanged: (value) {
                    ref.read(auditsProvider.notifier).setFilterModulo(value);
                  },
                ),
              ),

              // Filtro Resultado
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: state.filterResultado,
                  decoration: const InputDecoration(
                    labelText: 'Resultado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'success', child: Text('Éxito')),
                    DropdownMenuItem(value: 'error', child: Text('Error')),
                  ],
                  onChanged: (value) {
                    ref.read(auditsProvider.notifier).setFilterResultado(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botón limpiar filtros
          if (state.filterAccion != null ||
              state.filterModulo != null ||
              state.filterResultado != null ||
              state.filterSearch != null)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(auditsProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildAuditTimeline(AuditLogList data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.logs.length,
      itemBuilder: (context, index) {
        final log = data.logs[index];
        final isLast = index == data.logs.length - 1;
        return _AuditLogItem(log: log, isLast: isLast);
      },
    );
  }

  Widget _buildPagination(AuditsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${state.currentPage} de ${state.data!.totalPages} • '
            'Total: ${state.data!.total} eventos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1
                    ? () => ref.read(auditsProvider.notifier).previousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: state.currentPage < state.data!.totalPages
                    ? () => ref.read(auditsProvider.notifier).nextPage()
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Item de log en timeline
// ============================================================================

class _AuditLogItem extends StatelessWidget {
  final AuditLog log;
  final bool isLast;

  const _AuditLogItem({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAccionColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getAccionColor(),
                  width: 2,
                ),
              ),
              child: Icon(
                _getAccionIcon(),
                color: _getAccionColor(),
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildAccionBadge(context),
                                const SizedBox(width: 8),
                                _buildModuloBadge(context),
                                if (log.resultado != null) ...[
                                  const SizedBox(width: 8),
                                  _buildResultadoBadge(context),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (log.descripcion != null)
                              Text(
                                log.descripcion!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Información adicional
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.person,
                        log.usuarioNombre ?? 'Usuario #${log.usuarioId}',
                      ),
                      _buildInfoChip(
                        context,
                        Icons.access_time,
                        DateFormat('dd/MM/yyyy HH:mm:ss').format(log.createdAt),
                      ),
                      if (log.entidadNombre != null)
                        _buildInfoChip(
                          context,
                          Icons.label,
                          log.entidadNombre!,
                        ),
                      if (log.ipAddress != null)
                        _buildInfoChip(
                          context,
                          Icons.computer,
                          log.ipAddress!,
                        ),
                    ],
                  ),

                  // Mensaje de error si existe
                  if (log.mensajeError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.mensajeError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccionBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getAccionColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getAccionColor().withOpacity(0.3)),
      ),
      child: Text(
        _getAccionLabel(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getAccionColor(),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildModuloBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        log.modulo.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildResultadoBadge(BuildContext context) {
    final isSuccess = log.resultado == 'success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.3),
        ),
      ),
      child: Text(
        isSuccess ? 'ÉXITO' : 'ERROR',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  IconData _getAccionIcon() {
    switch (log.accion) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'export':
        return Icons.download;
      case 'import':
        return Icons.upload;
      default:
        return Icons.circle;
    }
  }

  Color _getAccionColor() {
    switch (log.accion) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      case 'export':
        return Colors.teal;
      case 'import':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getAccionLabel() {
    switch (log.accion) {
      case 'create':
        return 'CREAR';
      case 'update':
        return 'ACTUALIZAR';
      case 'delete':
        return 'ELIMINAR';
      case 'login':
        return 'LOGIN';
      case 'logout':
        return 'LOGOUT';
      case 'export':
        return 'EXPORTAR';
      case 'import':
        return 'IMPORTAR';
      default:
        return log.accion.toUpperCase();
    }
  }
}
