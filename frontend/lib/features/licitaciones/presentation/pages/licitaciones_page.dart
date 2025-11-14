import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/licitacion.dart';

class LicitacionesPage extends ConsumerStatefulWidget {
  const LicitacionesPage({super.key});

  @override
  ConsumerState<LicitacionesPage> createState() => _LicitacionesPageState();
}

class _LicitacionesPageState extends ConsumerState<LicitacionesPage> {
  String? _selectedEstado;
  String? _selectedCategoria;

  @override
  Widget build(BuildContext context) {
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
                            'Gestión de licitaciones y ofertas',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.neutral700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Add licitacion
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Licitación'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip(
                      'Estado',
                      _selectedEstado,
                      LicitacionEstado.values.map((e) => e.displayName).toList(),
                      (value) => setState(() => _selectedEstado = value),
                    ),
                    _buildFilterChip(
                      'Categoría',
                      _selectedCategoria,
                      LicitacionCategoria.values.map((e) => e.displayName).toList(),
                      (value) => setState(() => _selectedCategoria = value),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of licitaciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 10, // TODO: Replace with real data
              itemBuilder: (context, index) => _LicitacionCard(
                numero: '2025-LIC-00${index + 1}',
                titulo: 'Adquisición de Equipos de Cómputo',
                cliente: 'Ministerio de Educación Pública',
                estado: LicitacionEstado.publicada,
                monto: 250000000,
                fechaLimite: DateTime.now().add(Duration(days: index + 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selected,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected ?? label),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor: selected != null ? AppTheme.lightBlue : AppTheme.neutral100,
      ),
      itemBuilder: (context) => [
        if (selected != null)
          PopupMenuItem(
            value: null,
            child: const Text('Todos'),
          ),
        ...options.map(
          (option) => PopupMenuItem(
            value: option,
            child: Text(option),
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }
}

class _LicitacionCard extends StatelessWidget {
  final String numero;
  final String titulo;
  final String cliente;
  final LicitacionEstado estado;
  final double monto;
  final DateTime fechaLimite;

  const _LicitacionCard({
    required this.numero,
    required this.titulo,
    required this.cliente,
    required this.estado,
    required this.monto,
    required this.fechaLimite,
  });

  Color _getEstadoColor() {
    switch (estado) {
      case LicitacionEstado.adjudicada:
        return AppTheme.successColor;
      case LicitacionEstado.publicada:
      case LicitacionEstado.presentada:
        return AppTheme.warningColor;
      case LicitacionEstado.rechazada:
      case LicitacionEstado.desierta:
        return AppTheme.errorColor;
      default:
        return AppTheme.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = fechaLimite.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detail
        },
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
                          numero,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.neutral700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titulo,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: AppTheme.neutral500),
                  const SizedBox(width: 6),
                  Text(
                    cliente,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutral700,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        '₡${monto.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Días Restantes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysLeft.toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: daysLeft <= 3 ? AppTheme.errorColor : AppTheme.warningColor,
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
