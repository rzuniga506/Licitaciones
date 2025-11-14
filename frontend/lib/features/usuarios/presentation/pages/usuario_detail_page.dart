import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/usuarios_provider.dart';
import '../../../../core/models/usuario.dart';
import '../widgets/usuario_form_dialog.dart';

class UsuarioDetailPage extends ConsumerWidget {
  final int usuarioId;

  const UsuarioDetailPage({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioDetailProvider(usuarioId));
    final statsAsync = ref.watch(usuarioStatsProvider(usuarioId));

    return Scaffold(
      body: usuarioAsync.when(
        data: (usuario) => _buildContent(context, ref, usuario, statsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error al cargar usuario'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
    AsyncValue<UsuarioStats> statsAsync,
  ) {
    return Column(
      children: [
        // Header
        _buildHeader(context, ref, usuario),

        // Contenido
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  // Layout de dos columnas para pantallas grandes
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildInformacionGeneral(context, usuario),
                            const SizedBox(height: 16),
                            _buildAccesoSeguridad(context, usuario),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildEstadisticas(context, statsAsync),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout de una columna para pantallas pequeñas
                  return Column(
                    children: [
                      _buildInformacionGeneral(context, usuario),
                      const SizedBox(height: 16),
                      _buildAccesoSeguridad(context, usuario),
                      const SizedBox(height: 16),
                      _buildEstadisticas(context, statsAsync),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Usuario usuario) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),

              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: _getRoleColor(usuario.role).withOpacity(0.2),
                child: Text(
                  usuario.fullName.isNotEmpty
                      ? usuario.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(usuario.role),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${usuario.username}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),

              _buildRoleBadge(context, usuario.role),
              const SizedBox(width: 8),
              _buildStateBadge(context, usuario.isActive),
              const SizedBox(width: 16),

              // Acciones
              _buildActionButtons(context, ref, usuario),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Usuario usuario) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => UsuarioFormDialog(usuario: usuario),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Editar'),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleAction(context, ref, usuario, value),
          itemBuilder: (context) => [
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
    );
  }

  Widget _buildInformacionGeneral(BuildContext context, Usuario usuario) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Información General',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(context, 'Email', usuario.email, Icons.email),
            const Divider(height: 24),
            _buildInfoRow(context, 'Rol', _getRoleLabel(usuario.role), Icons.admin_panel_settings),
            if (usuario.departamento != null) ...[
              const Divider(height: 24),
              _buildInfoRow(context, 'Departamento', usuario.departamento!, Icons.business),
            ],
            if (usuario.cargo != null) ...[
              const Divider(height: 24),
              _buildInfoRow(context, 'Cargo', usuario.cargo!, Icons.work),
            ],
            if (usuario.telefono != null) ...[
              const Divider(height: 24),
              _buildInfoRow(context, 'Teléfono', usuario.telefono!, Icons.phone),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Fecha de creación',
              usuario.createdAt != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(usuario.createdAt!)
                  : 'N/A',
              Icons.calendar_today,
            ),
            if (usuario.createdByName != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Creado por',
                usuario.createdByName!,
                Icons.person,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccesoSeguridad(BuildContext context, Usuario usuario) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Acceso y Seguridad',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              'Estado de la cuenta',
              usuario.isActive ? 'Activa' : 'Inactiva',
              Icons.account_circle,
            ),
            if (usuario.lastLogin != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Último acceso',
                DateFormat('dd/MM/yyyy HH:mm').format(usuario.lastLogin!),
                Icons.login,
              ),
            ],
            if (usuario.loginCount != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Número de accesos',
                '${usuario.loginCount}',
                Icons.numbers,
              ),
            ],
            if (usuario.failedLoginAttempts != null &&
                usuario.failedLoginAttempts! > 0) ...[
              const Divider(height: 24),
              _buildWarningRow(
                context,
                'Intentos fallidos',
                '${usuario.failedLoginAttempts}',
                Icons.warning,
              ),
            ],
            if (usuario.passwordChangedAt != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Contraseña cambiada',
                DateFormat('dd/MM/yyyy').format(usuario.passwordChangedAt!),
                Icons.lock_clock,
              ),
            ],
            if (usuario.mustChangePassword == true) ...[
              const Divider(height: 24),
              _buildWarningRow(
                context,
                'Debe cambiar contraseña',
                'Sí',
                Icons.lock_reset,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas(BuildContext context, AsyncValue<UsuarioStats> statsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas de Uso',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _buildStatRow(
                    context,
                    'Licitaciones creadas',
                    '${stats.licitacionesCreadas ?? 0}',
                    Icons.gavel,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Documentos subidos',
                    '${stats.documentosSubidos ?? 0}',
                    Icons.upload_file,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Interacciones registradas',
                    '${stats.interaccionesRegistradas ?? 0}',
                    Icons.people,
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Alertas activas',
                    '${stats.alertasActivas ?? 0}',
                    Icons.notifications,
                    Colors.orange,
                  ),
                  if (stats.ultimaActividad != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Última actividad',
                      DateFormat('dd/MM/yyyy HH:mm').format(stats.ultimaActividad!),
                      Icons.access_time,
                    ),
                  ],
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar estadísticas',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
      ),
      child: Text(
        _getRoleLabel(role),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getRoleColor(role),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStateBadge(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'INACTIVO',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
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

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'analyst':
        return 'Analista';
      case 'viewer':
        return 'Consulta';
      default:
        return role;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, Usuario usuario, String action) {
    switch (action) {
      case 'activate':
        ref.read(usuarioCrudProvider.notifier).activarUsuario(usuario.usuarioId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario activado'), backgroundColor: Colors.green),
        );
        break;
      case 'deactivate':
        ref.read(usuarioCrudProvider.notifier).desactivarUsuario(usuario.usuarioId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desactivado'), backgroundColor: Colors.orange),
        );
        break;
      case 'unlock':
        ref.read(usuarioCrudProvider.notifier).desbloquearCuenta(usuario.usuarioId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta desbloqueada'), backgroundColor: Colors.blue),
        );
        break;
      case 'reset-password':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función de reseteo de contraseña pendiente')),
        );
        break;
      case 'delete':
        ref.read(usuarioCrudProvider.notifier).deleteUsuario(usuario.usuarioId);
        context.go('/usuarios');
        break;
    }
  }
}
