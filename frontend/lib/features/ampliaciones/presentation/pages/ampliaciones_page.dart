import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/ampliaciones_provider.dart';
import '../../../../core/models/ampliacion_prorroga.dart';
import '../widgets/nueva_ampliacion_dialog.dart';

class AmpliacionesPage extends ConsumerStatefulWidget {
  const AmpliacionesPage({super.key});

  @override
  ConsumerState<AmpliacionesPage> createState() => _AmpliacionesPageState();
}

class _AmpliacionesPageState extends ConsumerState<AmpliacionesPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar ampliaciones al iniciar
    Future.microtask(
      () => ref.read(ampliacionesProvider.notifier).loadAmpliaciones(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ampliacionesProvider);

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
            child: Row(
              children: [
                Icon(
                  Icons.extension_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ampliaciones y Prórrogas',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestión de solicitudes de ampliación y prórroga',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showNuevaAmpliacionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Solicitud'),
                ),
              ],
            ),
          ),

          // Filtros
          _buildFilters(),

          // Lista de ampliaciones
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
                                  .read(ampliacionesProvider.notifier)
                                  .loadAmpliaciones(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : state.data == null || state.data!.ampliaciones.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.extension_off_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay ampliaciones registradas',
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
                        : _buildAmpliacionesList(state.data!),
          ),

          // Paginación
          if (state.data != null && state.data!.totalPages > 1)
            _buildPagination(state),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final state = ref.watch(ampliacionesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
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
                              .read(ampliacionesProvider.notifier)
                              .setFilterSearch(null);
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) {
                ref
                    .read(ampliacionesProvider.notifier)
                    .setFilterSearch(value.isEmpty ? null : value);
              },
            ),
          ),

          // Filtro Tipo
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: state.filterTipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(
                  value: 'ampliacion_plazo',
                  child: Text('Ampliación de Plazo'),
                ),
                DropdownMenuItem(
                  value: 'prorroga_contrato',
                  child: Text('Prórroga de Contrato'),
                ),
                DropdownMenuItem(
                  value: 'ampliacion_monto',
                  child: Text('Ampliación de Monto'),
                ),
              ],
              onChanged: (value) {
                ref.read(ampliacionesProvider.notifier).setFilterTipo(value);
              },
            ),
          ),

          // Filtro Estado
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: state.filterEstado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(
                  value: 'solicitada',
                  child: Text('Solicitada'),
                ),
                DropdownMenuItem(
                  value: 'en_revision',
                  child: Text('En Revisión'),
                ),
                DropdownMenuItem(
                  value: 'aprobada',
                  child: Text('Aprobada'),
                ),
                DropdownMenuItem(
                  value: 'rechazada',
                  child: Text('Rechazada'),
                ),
              ],
              onChanged: (value) {
                ref.read(ampliacionesProvider.notifier).setFilterEstado(value);
              },
            ),
          ),

          // Botón limpiar filtros
          if (state.filterTipo != null ||
              state.filterEstado != null ||
              state.filterSearch != null)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(ampliacionesProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildAmpliacionesList(AmpliacionProrrogaList data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.ampliaciones.length,
      itemBuilder: (context, index) {
        final ampliacion = data.ampliaciones[index];
        return _AmpliacionCard(ampliacion: ampliacion);
      },
    );
  }

  Widget _buildPagination(AmpliacionesState state) {
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
            'Total: ${state.data!.total} ampliaciones',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1
                    ? () => ref
                        .read(ampliacionesProvider.notifier)
                        .previousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: state.currentPage < state.data!.totalPages
                    ? () =>
                        ref.read(ampliacionesProvider.notifier).nextPage()
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNuevaAmpliacionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NuevaAmpliacionDialog(),
    );
  }
}

// ============================================================================
// Card de ampliación
// ============================================================================

class _AmpliacionCard extends StatelessWidget {
  final AmpliacionProrroga ampliacion;

  const _AmpliacionCard({required this.ampliacion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go('/ampliaciones/${ampliacion.ampliacionId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono según tipo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTipoColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTipoIcon(),
                  color: _getTipoColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ampliacion.licitacionTitulo ?? 'Licitación #${ampliacion.licitacionId}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildEstadoBadge(context),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tipo badge
                    _buildTipoBadge(context),
                    const SizedBox(height: 8),

                    // Información específica según tipo
                    _buildTipoInfo(context),

                    const SizedBox(height: 8),

                    // Justificación (truncada)
                    Text(
                      ampliacion.justificacion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 12),

                    // Footer con fechas y solicitante
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.calendar_today,
                          'Solicitada: ${DateFormat('dd/MM/yyyy').format(ampliacion.fechaSolicitud)}',
                        ),
                        if (ampliacion.fechaRespuesta != null)
                          _buildInfoChip(
                            context,
                            Icons.event_available,
                            'Respuesta: ${DateFormat('dd/MM/yyyy').format(ampliacion.fechaRespuesta!)}',
                          ),
                        _buildInfoChip(
                          context,
                          Icons.person_outline,
                          ampliacion.solicitanteNombre ?? 'Usuario #${ampliacion.solicitanteId}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTipoColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getTipoColor().withOpacity(0.3)),
      ),
      child: Text(
        _getTipoLabel(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getTipoColor(),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getEstadoColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getEstadoColor().withOpacity(0.3)),
      ),
      child: Text(
        _getEstadoLabel(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getEstadoColor(),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTipoInfo(BuildContext context) {
    final List<Widget> chips = [];

    if (ampliacion.tipo == 'ampliacion_plazo' || ampliacion.tipo == 'prorroga_contrato') {
      if (ampliacion.plazoSolicitadoDias != null) {
        chips.add(
          Chip(
            avatar: const Icon(Icons.access_time, size: 16),
            label: Text('Plazo: ${ampliacion.plazoSolicitadoDias} días'),
            visualDensity: VisualDensity.compact,
          ),
        );
      }
      if (ampliacion.plazoAprobadoDias != null) {
        chips.add(
          Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: Text('Aprobado: ${ampliacion.plazoAprobadoDias} días'),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.green.withOpacity(0.1),
          ),
        );
      }
      if (ampliacion.fechaNuevaEntrega != null) {
        chips.add(
          Chip(
            avatar: const Icon(Icons.event, size: 16),
            label: Text(
              'Nueva entrega: ${DateFormat('dd/MM/yyyy').format(ampliacion.fechaNuevaEntrega!)}',
            ),
            visualDensity: VisualDensity.compact,
          ),
        );
      }
    }

    if (ampliacion.tipo == 'ampliacion_monto') {
      if (ampliacion.montoSolicitado != null) {
        chips.add(
          Chip(
            avatar: const Icon(Icons.attach_money, size: 16),
            label: Text(
              'Monto: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(ampliacion.montoSolicitado)}',
            ),
            visualDensity: VisualDensity.compact,
          ),
        );
      }
      if (ampliacion.montoAprobado != null) {
        chips.add(
          Chip(
            avatar: const Icon(Icons.check_circle, size: 16),
            label: Text(
              'Aprobado: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(ampliacion.montoAprobado)}',
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.green.withOpacity(0.1),
          ),
        );
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
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

  IconData _getTipoIcon() {
    switch (ampliacion.tipo) {
      case 'ampliacion_plazo':
        return Icons.schedule;
      case 'prorroga_contrato':
        return Icons.event_repeat;
      case 'ampliacion_monto':
        return Icons.trending_up;
      default:
        return Icons.extension;
    }
  }

  Color _getTipoColor() {
    switch (ampliacion.tipo) {
      case 'ampliacion_plazo':
        return Colors.blue;
      case 'prorroga_contrato':
        return Colors.purple;
      case 'ampliacion_monto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTipoLabel() {
    switch (ampliacion.tipo) {
      case 'ampliacion_plazo':
        return 'AMPLIACIÓN DE PLAZO';
      case 'prorroga_contrato':
        return 'PRÓRROGA DE CONTRATO';
      case 'ampliacion_monto':
        return 'AMPLIACIÓN DE MONTO';
      default:
        return ampliacion.tipo.toUpperCase();
    }
  }

  Color _getEstadoColor() {
    switch (ampliacion.estado) {
      case 'solicitada':
        return Colors.orange;
      case 'en_revision':
        return Colors.blue;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel() {
    switch (ampliacion.estado) {
      case 'solicitada':
        return 'SOLICITADA';
      case 'en_revision':
        return 'EN REVISIÓN';
      case 'aprobada':
        return 'APROBADA';
      case 'rechazada':
        return 'RECHAZADA';
      default:
        return ampliacion.estado.toUpperCase();
    }
  }
}
