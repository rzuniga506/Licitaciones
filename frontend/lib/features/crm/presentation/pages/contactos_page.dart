import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/crm_provider.dart';
import '../../../../core/models/contacto.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/nuevo_contacto_dialog.dart';

class ContactosPage extends ConsumerWidget {
  const ContactosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactosProvider);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 24),
          _buildFilters(context, ref, state),
          const SizedBox(height: 24),
          Expanded(child: _buildContactosList(context, ref, state)),
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
            Text('Contactos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Gestiona los contactos de tus clientes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showNuevoContactoDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Contacto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, ContactosState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, email, teléfono...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSubmitted: (value) => ref.read(contactosProvider.notifier).setSearchQuery(value.isEmpty ? null : value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nivel Decisión',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                value: state.filterNivelDecision,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'ejecutivo', child: Text('Ejecutivo')),
                  DropdownMenuItem(value: 'gerencial', child: Text('Gerencial')),
                  DropdownMenuItem(value: 'operativo', child: Text('Operativo')),
                  DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                ],
                onChanged: (value) => ref.read(contactosProvider.notifier).setFilterNivelDecision(value),
              ),
            ),
            const SizedBox(width: 12),
            if (state.hasFilters)
              IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(contactosProvider.notifier).clearFilters(), tooltip: 'Limpiar filtros'),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(contactosProvider.notifier).refresh(), tooltip: 'Actualizar'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactosList(BuildContext context, WidgetRef ref, ContactosState state) {
    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar contactos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.error!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.read(contactosProvider.notifier).refresh(), child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (state.data == null || state.data!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No se encontraron contactos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showNuevoContactoDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Contacto'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await ref.read(contactosProvider.notifier).refresh(),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.data!.items.length,
              itemBuilder: (context, index) {
                final contacto = state.data!.items[index];
                return _ContactoCard(contacto: contacto, onTap: () => context.go('/crm/contactos/${contacto.contactoId}'));
              },
            ),
          ),
        ),
        if (state.data!.totalPages > 1) _buildPagination(context, ref, state),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, WidgetRef ref, ContactosState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Página ${state.currentPage} de ${state.data!.totalPages}', style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1 ? () => ref.read(contactosProvider.notifier).previousPage() : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.data!.totalPages ? () => ref.read(contactosProvider.notifier).nextPage() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNuevoContactoDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(context: context, builder: (context) => const NuevoContactoDialog());
    if (result == true) ref.read(contactosProvider.notifier).refresh();
  }
}

class _ContactoCard extends StatelessWidget {
  final Contacto contacto;
  final VoidCallback onTap;

  const _ContactoCard({required this.contacto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getNivelColor(contacto.nivelDecision).withOpacity(0.2),
                    child: Text(contacto.nombreContacto[0].toUpperCase(), style: TextStyle(color: _getNivelColor(contacto.nivelDecision), fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contacto.nombreContacto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (contacto.cargo != null) Text(contacto.cargo!, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (contacto.esContactoPrincipal) Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (contacto.email != null) _buildInfoRow(Icons.email_outlined, contacto.email!),
              if (contacto.telefono != null || contacto.celular != null) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.phone_outlined, contacto.celular ?? contacto.telefono!),
              ],
              if (contacto.nivelDecision != null) ...[
                const SizedBox(height: 8),
                _buildNivelBadge(contacto.nivelDecision!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildNivelBadge(String nivel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _getNivelColor(nivel).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(_formatNivel(nivel), style: TextStyle(fontSize: 11, color: _getNivelColor(nivel), fontWeight: FontWeight.w600)),
    );
  }

  Color _getNivelColor(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'ejecutivo': return AppTheme.dangerColor;
      case 'gerencial': return AppTheme.warningColor;
      case 'operativo': return AppTheme.infoColor;
      case 'tecnico': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  String _formatNivel(String nivel) {
    const Map<String, String> niveles = {
      'ejecutivo': 'Ejecutivo',
      'gerencial': 'Gerencial',
      'operativo': 'Operativo',
      'tecnico': 'Técnico',
    };
    return niveles[nivel] ?? nivel;
  }
}
