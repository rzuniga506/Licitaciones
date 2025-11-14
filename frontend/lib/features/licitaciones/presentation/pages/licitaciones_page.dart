import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/licitacion.dart';
import '../../../../core/providers/licitacion_provider.dart';
import '../widgets/nueva_licitacion_dialog.dart';

class LicitacionesPage extends ConsumerStatefulWidget {
  const LicitacionesPage({super.key});

  @override
  ConsumerState<LicitacionesPage> createState() => _LicitacionesPageState();
}

class _LicitacionesPageState extends ConsumerState<LicitacionesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licitacionesState = ref.watch(licitacionesProvider);

    return AppScaffold(
      title: 'Licitaciones',
      currentRoute: '/licitaciones',
      child: Column(
        children: [
          // Header with filters
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
                            'Licitaciones',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            licitacionesState.data != null
                                ? '${licitacionesState.data!.total} licitaciones encontradas'
                                : 'Gestión de licitaciones y ofertas',
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
                        ref.read(licitacionesProvider.notifier).refresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Licitación'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por número o título...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(licitacionesProvider.notifier).setSearchQuery(null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    ref.read(licitacionesProvider.notifier).setSearchQuery(
                          value.isEmpty ? null : value,
                        );
                  },
                ),
                const SizedBox(height: 16),

                // Filters
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip(
                      'Estado',
                      licitacionesState.filterEstado,
                      LicitacionEstado.values.map((e) => e.name).toList(),
                      LicitacionEstado.values.map((e) => e.displayName).toList(),
                      (value) {
                        ref.read(licitacionesProvider.notifier).setFilterEstado(value);
                      },
                    ),
                    _buildFilterChip(
                      'Categoría',
                      licitacionesState.filterCategoria,
                      LicitacionCategoria.values.map((e) => e.name).toList(),
                      LicitacionCategoria.values.map((e) => e.displayName).toList(),
                      (value) {
                        ref.read(licitacionesProvider.notifier).setFilterCategoria(value);
                      },
                    ),
                    if (licitacionesState.hasFilters)
                      ActionChip(
                        label: const Text('Limpiar filtros'),
                        avatar: const Icon(Icons.clear_all, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(licitacionesProvider.notifier).clearFilters();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          // List of licitaciones
          Expanded(
            child: _buildLicitacionesList(licitacionesState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selected,
    List<String> optionValues,
    List<String> optionLabels,
    Function(String?) onChanged,
  ) {
    final selectedLabel = selected != null
        ? optionLabels[optionValues.indexOf(selected)]
        : null;

    return PopupMenuButton<String>(
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedLabel ?? label),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor: selected != null ? AppTheme.lightBlue : AppTheme.neutral100,
      ),
      itemBuilder: (context) => [
        if (selected != null)
          const PopupMenuItem(
            value: null,
            child: Text('Todos'),
          ),
        ...List.generate(
          optionValues.length,
          (index) => PopupMenuItem(
            value: optionValues[index],
            child: Text(optionLabels[index]),
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }

  Widget _buildLicitacionesList(LicitacionesState state) {
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
                'Error al cargar licitaciones',
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
                  ref.read(licitacionesProvider.notifier).refresh();
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
                Icons.inbox_outlined,
                size: 64,
                color: AppTheme.neutral500,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron licitaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta ajustar los filtros o crear una nueva licitación',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral700,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.read(licitacionesProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.data!.items.length,
              itemBuilder: (context, index) {
                final licitacion = state.data!.items[index];
                return _LicitacionCard(
                  licitacion: licitacion,
                  onTap: () {
                    context.go('/licitaciones/${licitacion.licitacionId}');
                  },
                );
              },
            ),
          ),
        ),
        if (state.data!.totalPages > 1) _buildPagination(state),
      ],
    );
  }

  Widget _buildPagination(LicitacionesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.neutral300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${state.currentPage} de ${state.data!.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1
                    ? () => ref.read(licitacionesProvider.notifier).previousPage()
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.currentPage}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.data!.totalPages
                    ? () => ref.read(licitacionesProvider.notifier).nextPage()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NuevaLicitacionDialog(),
    );

    // If licitacion was created successfully, result will be true
    if (result == true && mounted) {
      // List will auto-refresh due to invalidate in the dialog
    }
  }
}

class _LicitacionCard extends StatelessWidget {
  final Licitacion licitacion;
  final VoidCallback onTap;

  const _LicitacionCard({
    required this.licitacion,
    required this.onTap,
  });

  Color _getEstadoColor() {
    final estado = LicitacionEstado.fromString(licitacion.estadoLicitacion);
    switch (estado) {
      case LicitacionEstado.adjudicada:
      case LicitacionEstado.finalizada:
        return AppTheme.successColor;
      case LicitacionEstado.publicada:
      case LicitacionEstado.presentada:
      case LicitacionEstado.enEvaluacion:
        return AppTheme.warningColor;
      case LicitacionEstado.rechazada:
      case LicitacionEstado.desierta:
        return AppTheme.errorColor;
      case LicitacionEstado.enEjecucion:
        return AppTheme.infoColor;
      default:
        return AppTheme.neutral500;
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'No especificado';
    if (amount >= 1000000) {
      return '₡${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₡${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '₡${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = LicitacionEstado.fromString(licitacion.estadoLicitacion);
    final fechaLimite = licitacion.fechaPresentacion ?? licitacion.fechaPublicacion;
    final daysLeft = fechaLimite != null
        ? fechaLimite.difference(DateTime.now()).inDays
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          licitacion.numeroLicitacion,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.neutral700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          licitacion.tituloLicitacion,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getEstadoColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      estado.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getEstadoColor(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (licitacion.descripcion != null) ...[
                const SizedBox(height: 12),
                Text(
                  licitacion.descripcion!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto Estimado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(licitacion.montoEstimado),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (daysLeft != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          daysLeft >= 0 ? 'Días Restantes' : 'Vencida',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          daysLeft >= 0 ? daysLeft.toString() : '${daysLeft.abs()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: daysLeft < 0
                                    ? AppTheme.errorColor
                                    : (daysLeft <= 3 ? AppTheme.errorColor : AppTheme.warningColor),
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
