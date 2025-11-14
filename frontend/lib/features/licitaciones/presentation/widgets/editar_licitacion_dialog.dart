import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/licitacion.dart';
import '../../../../core/providers/licitacion_provider.dart';
import '../../../../core/providers/cliente_provider.dart';

class EditarLicitacionDialog extends ConsumerStatefulWidget {
  final Licitacion licitacion;

  const EditarLicitacionDialog({
    super.key,
    required this.licitacion,
  });

  @override
  ConsumerState<EditarLicitacionDialog> createState() =>
      _EditarLicitacionDialogState();
}

class _EditarLicitacionDialogState
    extends ConsumerState<EditarLicitacionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroController;
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _montoEstimadoController;
  late final TextEditingController _montoOfertadoController;
  late final TextEditingController _montoAdjudicadoController;

  late String _selectedEstado;
  late String _selectedCategoria;
  DateTime? _fechaPublicacion;
  DateTime? _fechaPresentacion;
  DateTime? _fechaAdjudicacion;
  DateTime? _fechaInicioContrato;
  DateTime? _fechaFinContrato;
  DateTime? _fechaVencimientoGarantia;
  late double _probabilidadExito;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _numeroController = TextEditingController(text: widget.licitacion.numeroLicitacion);
    _tituloController = TextEditingController(text: widget.licitacion.tituloLicitacion);
    _descripcionController = TextEditingController(text: widget.licitacion.descripcion ?? '');
    _montoEstimadoController = TextEditingController(
      text: widget.licitacion.montoEstimado?.toString() ?? '',
    );
    _montoOfertadoController = TextEditingController(
      text: widget.licitacion.montoOfertado?.toString() ?? '',
    );
    _montoAdjudicadoController = TextEditingController(
      text: widget.licitacion.montoAdjudicado?.toString() ?? '',
    );

    // Initialize state variables
    _selectedEstado = widget.licitacion.estadoLicitacion;
    _selectedCategoria = widget.licitacion.categoria;
    _fechaPublicacion = widget.licitacion.fechaPublicacion;
    _fechaPresentacion = widget.licitacion.fechaPresentacion;
    _fechaAdjudicacion = widget.licitacion.fechaAdjudicacion;
    _fechaInicioContrato = widget.licitacion.fechaInicioContrato;
    _fechaFinContrato = widget.licitacion.fechaFinContrato;
    _fechaVencimientoGarantia = widget.licitacion.fechaVencimientoGarantia;
    _probabilidadExito = widget.licitacion.probabilidadExito?.toDouble() ?? 50.0;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _montoEstimadoController.dispose();
    _montoOfertadoController.dispose();
    _montoAdjudicadoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    DateTime? initialDate;
    switch (field) {
      case 'publicacion':
        initialDate = _fechaPublicacion;
        break;
      case 'presentacion':
        initialDate = _fechaPresentacion;
        break;
      case 'adjudicacion':
        initialDate = _fechaAdjudicacion;
        break;
      case 'inicio_contrato':
        initialDate = _fechaInicioContrato;
        break;
      case 'fin_contrato':
        initialDate = _fechaFinContrato;
        break;
      case 'vencimiento_garantia':
        initialDate = _fechaVencimientoGarantia;
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
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
        switch (field) {
          case 'publicacion':
            _fechaPublicacion = picked;
            break;
          case 'presentacion':
            _fechaPresentacion = picked;
            break;
          case 'adjudicacion':
            _fechaAdjudicacion = picked;
            break;
          case 'inicio_contrato':
            _fechaInicioContrato = picked;
            break;
          case 'fin_contrato':
            _fechaFinContrato = picked;
            break;
          case 'vencimiento_garantia':
            _fechaVencimientoGarantia = picked;
            break;
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ref.read(licitacionCrudProvider.notifier).updateLicitacion(
            widget.licitacion.licitacionId,
            numeroLicitacion: _numeroController.text.trim(),
            tituloLicitacion: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            estadoLicitacion: _selectedEstado,
            categoria: _selectedCategoria,
            fechaPublicacion: _fechaPublicacion,
            fechaPresentacion: _fechaPresentacion,
            fechaAdjudicacion: _fechaAdjudicacion,
            montoEstimado: _montoEstimadoController.text.trim().isEmpty
                ? null
                : double.parse(_montoEstimadoController.text.trim()),
            montoOfertado: _montoOfertadoController.text.trim().isEmpty
                ? null
                : double.parse(_montoOfertadoController.text.trim()),
            montoAdjudicado: _montoAdjudicadoController.text.trim().isEmpty
                ? null
                : double.parse(_montoAdjudicadoController.text.trim()),
            probabilidadExito: _probabilidadExito.round(),
            fechaInicioContrato: _fechaInicioContrato,
            fechaFinContrato: _fechaFinContrato,
            fechaVencimientoGarantia: _fechaVencimientoGarantia,
          );

      if (!mounted) return;

      if (success) {
        // Refresh the licitaciones list and detail
        ref.invalidate(licitacionesProvider);
        ref.invalidate(licitacionDetailProvider(widget.licitacion.licitacionId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licitación actualizada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        final error = ref.read(licitacionCrudProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al actualizar licitación'),
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Dialog(
      child: Container(
        width: isDesktop ? 900 : size.width * 0.9,
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
                    Icons.edit,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Licitación',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          widget.licitacion.numeroLicitacion,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                        ),
                      ],
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
                      // Información del Cliente (no editable)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business, color: AppTheme.neutral700),
                            const SizedBox(width: 12),
                            Text(
                              'Cliente ID: ${widget.licitacion.clienteId}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'No editable',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.infoColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
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

                      // Fechas Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Fecha de Publicación',
                              _fechaPublicacion,
                              'publicacion',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Fecha de Presentación',
                              _fechaPresentacion,
                              'presentacion',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Fechas Row 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Fecha de Adjudicación',
                              _fechaAdjudicacion,
                              'adjudicacion',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Inicio Contrato',
                              _fechaInicioContrato,
                              'inicio_contrato',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Fechas Row 3
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Fin Contrato',
                              _fechaFinContrato,
                              'fin_contrato',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Vencimiento Garantía',
                              _fechaVencimientoGarantia,
                              'vencimiento_garantia',
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

                      // Monto Adjudicado
                      Text(
                        'Monto Adjudicado (₡)',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _montoAdjudicadoController,
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
                            _validateNumeric(value, 'Monto Adjudicado'),
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
                    label: Text(_isSubmitting ? 'Guardando...' : 'Guardar Cambios'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? value,
    String field,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSubmitting ? null : () => _selectDate(context, field),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                switch (field) {
                                  case 'publicacion':
                                    _fechaPublicacion = null;
                                    break;
                                  case 'presentacion':
                                    _fechaPresentacion = null;
                                    break;
                                  case 'adjudicacion':
                                    _fechaAdjudicacion = null;
                                    break;
                                  case 'inicio_contrato':
                                    _fechaInicioContrato = null;
                                    break;
                                  case 'fin_contrato':
                                    _fechaFinContrato = null;
                                    break;
                                  case 'vencimiento_garantia':
                                    _fechaVencimientoGarantia = null;
                                    break;
                                }
                              });
                            },
                    ),
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            child: Text(
              value != null
                  ? DateFormat('dd/MM/yyyy').format(value)
                  : 'Seleccionar fecha',
              style: TextStyle(
                color: value != null ? Colors.black87 : AppTheme.neutral500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
