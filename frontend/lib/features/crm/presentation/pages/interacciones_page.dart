import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/crm_provider.dart';
import '../../../../core/models/interaccion_cliente.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/nueva_interaccion_dialog.dart';

class InteraccionesPage extends ConsumerWidget {
  const InteraccionesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interaccionesProvider);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 24),
          _buildFilters(context, ref, state),
          const SizedBox(height: 24),
          Expanded(child: _buildInteraccionesList(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interacciones', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Historial de interacciones con clientes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showNuevaInteraccionDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Interacción'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, InteraccionesState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                onSubmitted: (value) => ref.read(interaccionesProvider.notifier).setSearchQuery(value.isEmpty ? null : value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                value: state.filterTipoInteraccion,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'reunion', child: Text('Reunión')),
                  DropdownMenuItem(value: 'llamada', child: Text('Llamada')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'visita', child: Text('Visita')),
                  DropdownMenuItem(value: 'presentacion', child: Text('Presentación')),
                  DropdownMenuItem(value: 'seguimiento', child: Text('Seguimiento')),
                ],
                onChanged: (value) => ref.read(interaccionesProvider.notifier).setFilterTipoInteraccion(value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<bool>(
                decoration: InputDecoration(labelText: 'Seguimiento', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                value: state.filterRequiereSeguimiento,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Requiere')),
                  DropdownMenuItem(value: false, child: Text('No requiere')),
                ],
                onChanged: (value) => ref.read(interaccionesProvider.notifier).setFilterRequiereSeguimiento(value),
              ),
            ),
            const SizedBox(width: 12),
            if (state.hasFilters) IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(interaccionesProvider.notifier).clearFilters(), tooltip: 'Limpiar'),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(interaccionesProvider.notifier).refresh(), tooltip: 'Actualizar'),
          ],
        ),
      ),
    );
  }

  Widget _buildInteraccionesList(BuildContext context, WidgetRef ref, InteraccionesState state) {
    if (state.isLoading && state.data == null) return const Center(child: CircularProgressIndicator());

    if (state.error != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar interacciones', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.read(interaccionesProvider.notifier).refresh(), child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (state.data == null || state.data!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay interacciones registradas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () => _showNuevaInteraccionDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nueva Interacción')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await ref.read(interaccionesProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: state.data!.items.length,
              itemBuilder: (context, index) => _InteraccionCard(interaccion: state.data!.items[index]),
            ),
          ),
        ),
        if (state.data!.totalPages > 1) _buildPagination(context, ref, state),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, WidgetRef ref, InteraccionesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Página ${state.currentPage} de ${state.data!.totalPages}', style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: state.currentPage > 1 ? () => ref.read(interaccionesProvider.notifier).previousPage() : null),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: state.currentPage < state.data!.totalPages ? () => ref.read(interaccionesProvider.notifier).nextPage() : null),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNuevaInteraccionDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(context: context, builder: (context) => const NuevaInteraccionDialog());
    if (result == true) ref.read(interaccionesProvider.notifier).refresh();
  }
}

class _InteraccionCard extends StatelessWidget {
  final InteraccionCliente interaccion;

  const _InteraccionCard({required this.interaccion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _getTipoColor().withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getTipoIcon(), color: _getTipoColor(), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(interaccion.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Text(_formatFecha(interaccion.fechaInteraccion), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_formatTipo(interaccion.tipoInteraccion), style: TextStyle(fontSize: 13, color: _getTipoColor(), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(interaccion.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (interaccion.resultado != null) _buildChip(Icons.check_circle_outline, _formatResultado(interaccion.resultado!), _getResultadoColor()),
                      if (interaccion.nivelInteres != null) _buildChip(Icons.star_outline, 'Interés: ${interaccion.nivelInteres}/5', AppTheme.warningColor),
                      if (interaccion.requiereSeguimiento) _buildChip(Icons.flag_outlined, 'Requiere seguimiento', AppTheme.dangerColor),
                      if (interaccion.duracionMinutos != null) _buildChip(Icons.access_time, '${interaccion.duracionMinutos} min', AppTheme.infoColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: color.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getTipoIcon() {
    switch (interaccion.tipoInteraccion.toLowerCase()) {
      case 'reunion': return Icons.groups_outlined;
      case 'llamada': return Icons.phone_outlined;
      case 'email': return Icons.email_outlined;
      case 'visita': return Icons.home_outlined;
      case 'presentacion': return Icons.present_to_all_outlined;
      case 'seguimiento': return Icons.track_changes_outlined;
      default: return Icons.chat_outlined;
    }
  }

  Color _getTipoColor() {
    switch (interaccion.tipoInteraccion.toLowerCase()) {
      case 'reunion': return AppTheme.primaryColor;
      case 'llamada': return AppTheme.successColor;
      case 'email': return AppTheme.infoColor;
      case 'visita': return AppTheme.warningColor;
      default: return Colors.grey;
    }
  }

  Color _getResultadoColor() {
    switch (interaccion.resultado?.toLowerCase()) {
      case 'exitosa': return AppTheme.successColor;
      case 'pendiente_seguimiento': return AppTheme.warningColor;
      case 'sin_interes': return AppTheme.dangerColor;
      default: return AppTheme.infoColor;
    }
  }

  String _formatTipo(String tipo) {
    const Map<String, String> tipos = {'reunion': 'Reunión', 'llamada': 'Llamada', 'email': 'Email', 'visita': 'Visita', 'presentacion': 'Presentación', 'seguimiento': 'Seguimiento'};
    return tipos[tipo] ?? tipo;
  }

  String _formatResultado(String resultado) {
    const Map<String, String> resultados = {'exitosa': 'Exitosa', 'pendiente_seguimiento': 'Pendiente', 'sin_interes': 'Sin interés', 'requiere_propuesta': 'Requiere propuesta'};
    return resultados[resultado] ?? resultado;
  }

  String _formatFecha(DateTime fecha) => DateFormat('dd/MM/yyyy HH:mm').format(fecha);
}
