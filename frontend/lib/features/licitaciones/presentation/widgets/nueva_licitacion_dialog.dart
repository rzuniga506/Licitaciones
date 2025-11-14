import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/licitacion.dart';
import '../../../../core/providers/licitacion_provider.dart';
import '../../../../core/providers/cliente_provider.dart';

class NuevaLicitacionDialog extends ConsumerStatefulWidget {
  const NuevaLicitacionDialog({super.key});

  @override
  ConsumerState<NuevaLicitacionDialog> createState() =>
      _NuevaLicitacionDialogState();
}

class _NuevaLicitacionDialogState
    extends ConsumerState<NuevaLicitacionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoEstimadoController = TextEditingController();
  final _montoOfertadoController = TextEditingController();

  int? _selectedClienteId;
  String _selectedEstado = 'en_preparacion';
  String _selectedCategoria = 'servicios';
  DateTime? _fechaPublicacion;
  DateTime? _fechaPresentacion;
  double _probabilidadExito = 50;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _numeroController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _montoEstimadoController.dispose();
    _montoOfertadoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPublicacion) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPublicacion) {
          _fechaPublicacion = picked;
        } else {
          _fechaPresentacion = picked;
        }
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  String? _validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un cliente'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref.read(licitacionCrudProvider.notifier).createLicitacion(
            clienteId: _selectedClienteId!,
            numeroLicitacion: _numeroController.text.trim(),
            tituloLicitacion: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            estadoLicitacion: _selectedEstado,
            categoria: _selectedCategoria,
            fechaPublicacion: _fechaPublicacion,
            fechaPresentacion: _fechaPresentacion,
            montoEstimado: _montoEstimadoController.text.trim().isEmpty
                ? null
                : double.parse(_montoEstimadoController.text.trim()),
            montoOfertado: _montoOfertadoController.text.trim().isEmpty
                ? null
                : double.parse(_montoOfertadoController.text.trim()),
            probabilidadExito: _probabilidadExito.round(),
          );

      if (!mounted) return;

      if (success) {
        // Refresh the licitaciones list
        ref.invalidate(licitacionesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licitación creada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        final error = ref.read(licitacionCrudProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al crear licitación'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(allClientesProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Dialog(
      child: Container(
        width: isDesktop ? 800 : size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva Licitación',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cliente Dropdown
                      Text(
                        'Cliente *',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      clientesAsync.when(
                        data: (clientes) {
                          if (clientes.isEmpty) {
                            return const Text(
                              'No hay clientes disponibles. Por favor cree un cliente primero.',
                              style: TextStyle(color: AppTheme.errorColor),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            value: _selectedClienteId,
                            decoration: InputDecoration(
                              hintText: 'Seleccione un cliente',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: clientes.map((cliente) {
                              return DropdownMenuItem(
                                value: cliente.clienteId,
                                child: Text(cliente.nombreCliente),
                              );
                            }).toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedClienteId = value;
                                    });
                                  },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (error, _) => Text(
                          'Error al cargar clientes: $error',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Número y Título
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Número de Licitación *',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _numeroController,
                                  decoration: InputDecoration(
                                    hintText: 'Ej: 2025-LIC-001',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  enabled: !_isSubmitting,
                                  validator: (value) =>
                                      _validateRequired(value, 'Número'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Título *',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _tituloController,
                                  decoration: InputDecoration(
                                    hintText: 'Título de la licitación',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  enabled: !_isSubmitting,
                                  validator: (value) =>
                                      _validateRequired(value, 'Título'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Descripción
                      Text(
                        'Descripción',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          hintText: 'Descripción detallada (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 20),

                      // Estado y Categoría
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado *',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedEstado,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: LicitacionEstado.values.map((estado) {
                                    return DropdownMenuItem(
                                      value: estado.name,
                                      child: Text(estado.displayName),
                                    );
                                  }).toList(),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedEstado = value;
                                            });
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Categoría *',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategoria,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: LicitacionCategoria.values.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.name,
                                      child: Text(cat.displayName),
                                    );
                                  }).toList(),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedCategoria = value;
                                            });
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Fechas
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Publicación',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _selectDate(context, true),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _fechaPublicacion != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_fechaPublicacion!)
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaPublicacion != null
                                            ? Colors.black87
                                            : AppTheme.neutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Presentación',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _selectDate(context, false),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _fechaPresentacion != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_fechaPresentacion!)
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaPresentacion != null
                                            ? Colors.black87
                                            : AppTheme.neutral500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Montos
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monto Estimado (₡)',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _montoEstimadoController,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixText: '₡ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  enabled: !_isSubmitting,
                                  validator: (value) =>
                                      _validateNumeric(value, 'Monto Estimado'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monto Ofertado (₡)',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _montoOfertadoController,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixText: '₡ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  enabled: !_isSubmitting,
                                  validator: (value) =>
                                      _validateNumeric(value, 'Monto Ofertado'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Probabilidad de Éxito
                      Text(
                        'Probabilidad de Éxito: ${_probabilidadExito.round()}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _probabilidadExito,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_probabilidadExito.round()}%',
                        activeColor: AppTheme.primaryBlue,
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _probabilidadExito = value;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '* Campos requeridos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral700,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                border: Border(
                  top: BorderSide(color: AppTheme.neutral300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSubmitting ? 'Guardando...' : 'Crear Licitación'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
