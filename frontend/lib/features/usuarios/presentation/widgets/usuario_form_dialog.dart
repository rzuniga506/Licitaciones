import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/usuarios_provider.dart';
import '../../../../core/models/usuario.dart';

class UsuarioFormDialog extends ConsumerStatefulWidget {
  final Usuario? usuario;

  const UsuarioFormDialog({super.key, this.usuario});

  @override
  ConsumerState<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends ConsumerState<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _departamentoController;
  late final TextEditingController _cargoController;
  late final TextEditingController _telefonoController;

  String _selectedRole = 'analyst';
  bool _isActive = true;
  bool _mustChangePassword = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool get isEditing => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.usuario?.username ?? '',
    );
    _emailController = TextEditingController(
      text: widget.usuario?.email ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.usuario?.fullName ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _departamentoController = TextEditingController(
      text: widget.usuario?.departamento ?? '',
    );
    _cargoController = TextEditingController(
      text: widget.usuario?.cargo ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.usuario?.telefono ?? '',
    );

    if (widget.usuario != null) {
      _selectedRole = widget.usuario!.role;
      _isActive = widget.usuario!.isActive;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departamentoController.dispose();
    _cargoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crudState = ref.watch(usuarioCrudProvider);

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.person_add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username (solo para crear)
                      if (!isEditing) ...[
                        Text(
                          'Nombre de Usuario *',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'username',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El username es requerido';
                            }
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                              return 'Solo letras, números y guión bajo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Nombre Completo
                      Text(
                        'Nombre Completo *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Juan Pérez',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      Text(
                        'Email *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'user@ejemplo.com',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es requerido';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Rol
                      Text(
                        'Rol *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Gerente'),
                          ),
                          DropdownMenuItem(
                            value: 'analyst',
                            child: Text('Analista'),
                          ),
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Consulta'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Departamento y Cargo (en dos columnas)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Departamento',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _departamentoController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Ventas',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cargo',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cargoController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Analista',
                                    prefixIcon: Icon(Icons.work),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Teléfono
                      Text(
                        'Teléfono',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '+506 8888-8888',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contraseña (solo para crear o cambiar)
                      if (!isEditing || _passwordController.text.isNotEmpty) ...[
                        Text(
                          isEditing
                              ? 'Nueva Contraseña'
                              : 'Contraseña *',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (!isEditing &&
                                (value == null || value.isEmpty)) {
                              return 'La contraseña es requerida';
                            }
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 8) {
                              return 'Mínimo 8 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword =
                                      !_showConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (_passwordController.text.isNotEmpty &&
                                value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Opciones
                      CheckboxListTile(
                        title: const Text('Usuario activo'),
                        subtitle: const Text(
                          'Permitir el acceso del usuario al sistema',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (!isEditing || _passwordController.text.isNotEmpty)
                        CheckboxListTile(
                          title: const Text('Debe cambiar contraseña'),
                          subtitle: const Text(
                            'Requerir cambio de contraseña en el siguiente acceso',
                          ),
                          value: _mustChangePassword,
                          onChanged: (value) {
                            setState(() {
                              _mustChangePassword = value ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Acciones
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: crudState.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: crudState.isLoading ? null : _submitForm,
                    icon: crudState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? 'Guardar' : 'Crear Usuario'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool success;

    if (isEditing) {
      // Actualizar usuario existente
      success = await ref.read(usuarioCrudProvider.notifier).updateUsuario(
            usuarioId: widget.usuario!.usuarioId,
            updates: UsuarioUpdate(
              email: _emailController.text,
              fullName: _fullNameController.text,
              role: _selectedRole,
              isActive: _isActive,
              departamento: _departamentoController.text.isNotEmpty
                  ? _departamentoController.text
                  : null,
              cargo: _cargoController.text.isNotEmpty
                  ? _cargoController.text
                  : null,
              telefono: _telefonoController.text.isNotEmpty
                  ? _telefonoController.text
                  : null,
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
              mustChangePassword: _passwordController.text.isNotEmpty
                  ? _mustChangePassword
                  : null,
            ),
          );
    } else {
      // Crear nuevo usuario
      success = await ref.read(usuarioCrudProvider.notifier).createUsuario(
            UsuarioCreate(
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              role: _selectedRole,
              isActive: _isActive,
              departamento: _departamentoController.text.isNotEmpty
                  ? _departamentoController.text
                  : null,
              cargo: _cargoController.text.isNotEmpty
                  ? _cargoController.text
                  : null,
              telefono: _telefonoController.text.isNotEmpty
                  ? _telefonoController.text
                  : null,
              mustChangePassword: _mustChangePassword,
            ),
          );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Usuario actualizado exitosamente'
                : 'Usuario creado exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      final error = ref.read(usuarioCrudProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
