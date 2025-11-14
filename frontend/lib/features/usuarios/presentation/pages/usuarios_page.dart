import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/usuarios_provider.dart';
import '../../../../core/models/usuario.dart';
import '../widgets/usuario_form_dialog.dart';

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar usuarios al iniciar
    Future.microtask(
      () => ref.read(usuariosProvider.notifier).loadUsuarios(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosProvider);

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
                  Icons.people_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Usuarios',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Administración de cuentas y permisos',
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
                  onPressed: () => _showNuevoUsuarioDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Usuario'),
                ),
              ],
            ),
          ),

          // Filtros
          _buildFilters(),

          // Lista de usuarios
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
                                  .read(usuariosProvider.notifier)
                                  .loadUsuarios(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : state.data == null || state.data!.usuarios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_off_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay usuarios registrados',
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
                        : _buildUsuariosList(state.data!),
          ),

          // Paginación
          if (state.data != null && state.data!.totalPages > 1)
            _buildPagination(state),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final state = ref.watch(usuariosProvider);

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
                hintText: 'Buscar por nombre, email o username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.filterSearch != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(usuariosProvider.notifier)
                              .setFilterSearch(null);
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) {
                ref
                    .read(usuariosProvider.notifier)
                    .setFilterSearch(value.isEmpty ? null : value);
              },
            ),
          ),

          // Filtro Rol
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: state.filterRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'manager', child: Text('Gerente')),
                DropdownMenuItem(value: 'analyst', child: Text('Analista')),
                DropdownMenuItem(value: 'viewer', child: Text('Consulta')),
              ],
              onChanged: (value) {
                ref.read(usuariosProvider.notifier).setFilterRole(value);
              },
            ),
          ),

          // Filtro Estado
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<bool?>(
              value: state.filterIsActive,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: true, child: Text('Activos')),
                DropdownMenuItem(value: false, child: Text('Inactivos')),
              ],
              onChanged: (value) {
                ref.read(usuariosProvider.notifier).setFilterIsActive(value);
              },
            ),
          ),

          // Botón limpiar filtros
          if (state.filterRole != null ||
              state.filterIsActive != null ||
              state.filterSearch != null)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(usuariosProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildUsuariosList(UsuarioList data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.usuarios.length,
      itemBuilder: (context, index) {
        final usuario = data.usuarios[index];
        return _UsuarioCard(usuario: usuario);
      },
    );
  }

  Widget _buildPagination(UsuariosState state) {
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
            'Total: ${state.data!.total} usuarios',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1
                    ? () =>
                        ref.read(usuariosProvider.notifier).previousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: state.currentPage < state.data!.totalPages
                    ? () => ref.read(usuariosProvider.notifier).nextPage()
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNuevoUsuarioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UsuarioFormDialog(),
    );
  }
}

// ============================================================================
// Card de usuario
// ============================================================================

class _UsuarioCard extends ConsumerWidget {
  final Usuario usuario;

  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go('/usuarios/${usuario.usuarioId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getRoleColor().withOpacity(0.2),
                child: Text(
                  usuario.fullName.isNotEmpty
                      ? usuario.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(),
                  ),
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
                            usuario.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildRoleBadge(context),
                        const SizedBox(width: 8),
                        _buildStateBadge(context),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Username y Email
                    Text(
                      '@${usuario.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                    ),
                    Text(
                      usuario.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    if (usuario.departamento != null || usuario.cargo != null)
                      ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (usuario.cargo != null)
                              _buildInfoChip(
                                context,
                                Icons.work_outline,
                                usuario.cargo!,
                              ),
                            if (usuario.departamento != null)
                              _buildInfoChip(
                                context,
                                Icons.business_outlined,
                                usuario.departamento!,
                              ),
                          ],
                        ),
                      ],

                    const SizedBox(height: 12),

                    // Footer con última conexión
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (usuario.lastLogin != null)
                          _buildInfoChip(
                            context,
                            Icons.access_time,
                            'Último acceso: ${DateFormat('dd/MM/yyyy HH:mm').format(usuario.lastLogin!)}',
                          ),
                        if (usuario.loginCount != null && usuario.loginCount! > 0)
                          _buildInfoChip(
                            context,
                            Icons.login,
                            '${usuario.loginCount} accesos',
                          ),
                        if (usuario.failedLoginAttempts != null &&
                            usuario.failedLoginAttempts! > 0)
                          _buildWarningChip(
                            context,
                            Icons.warning,
                            '${usuario.failedLoginAttempts} intentos fallidos',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Acciones rápidas
              Column(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      _handleAction(context, ref, value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Ver detalle'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      if (usuario.isActive)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: ListTile(
                            leading: Icon(Icons.block, color: Colors.orange),
                            title: Text('Desactivar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'activate',
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Activar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'reset-password',
                        child: ListTile(
                          leading: Icon(Icons.lock_reset),
                          title: Text('Resetear contraseña'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (usuario.failedLoginAttempts != null &&
                          usuario.failedLoginAttempts! > 0)
                        const PopupMenuItem(
                          value: 'unlock',
                          child: ListTile(
                            leading: Icon(Icons.lock_open, color: Colors.blue),
                            title: Text('Desbloquear'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
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

  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getRoleColor().withOpacity(0.3)),
      ),
      child: Text(
        _getRoleLabel(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStateBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: usuario.isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: usuario.isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        usuario.isActive ? 'ACTIVO' : 'INACTIVO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: usuario.isActive ? Colors.green : Colors.grey,
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

  Widget _buildWarningChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Color _getRoleColor() {
    switch (usuario.role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.purple;
      case 'analyst':
        return Colors.blue;
      case 'viewer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel() {
    switch (usuario.role) {
      case 'admin':
        return 'ADMIN';
      case 'manager':
        return 'GERENTE';
      case 'analyst':
        return 'ANALISTA';
      case 'viewer':
        return 'CONSULTA';
      default:
        return usuario.role.toUpperCase();
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'view':
        context.go('/usuarios/${usuario.usuarioId}');
        break;
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => UsuarioFormDialog(usuario: usuario),
        );
        break;
      case 'activate':
        ref.read(usuarioCrudProvider.notifier).activarUsuario(usuario.usuarioId);
        break;
      case 'deactivate':
        ref.read(usuarioCrudProvider.notifier).desactivarUsuario(usuario.usuarioId);
        break;
      case 'unlock':
        ref.read(usuarioCrudProvider.notifier).desbloquearCuenta(usuario.usuarioId);
        break;
      case 'reset-password':
        // TODO: Show dialog to reset password
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función de reseteo de contraseña pendiente')),
        );
        break;
      case 'delete':
        // TODO: Show confirmation dialog
        ref.read(usuarioCrudProvider.notifier).deleteUsuario(usuario.usuarioId);
        break;
    }
  }
}
