import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/ampliaciones_provider.dart';
import '../../../../core/providers/licitaciones_provider.dart';

class NuevaAmpliacionDialog extends ConsumerStatefulWidget {
  final int? licitacionId;

  const NuevaAmpliacionDialog({super.key, this.licitacionId});

  @override
  ConsumerState<NuevaAmpliacionDialog> createState() =>
      _NuevaAmpliacionDialogState();
}

class _NuevaAmpliacionDialogState extends ConsumerState<NuevaAmpliacionDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedLicitacionId;
  String _selectedTipo = 'ampliacion_plazo';

  final _montoController = TextEditingController();
  final _plazoController = TextEditingController();
  final _justificacionController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime? _fechaNuevaEntrega;

  @override
  void initState() {
    super.initState();
    _selectedLicitacionId = widget.licitacionId;

    // Cargar licitaciones si no hay una pre-seleccionada
    if (widget.licitacionId == null) {
      Future.microtask(
        () => ref.read(licitacionesProvider.notifier).loadLicitaciones(),
      );
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _plazoController.dispose();
    _justificacionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crudState = ref.watch(ampliacionCrudProvider);

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
                    Icons.extension,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Nueva Solicitud de Ampliación/Prórroga',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      // Selector de licitación
                      if (widget.licitacionId == null) _buildLicitacionSelector(),

                      const SizedBox(height: 20),

                      // Tipo de solicitud
                      Text(
                        'Tipo de Solicitud',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTipo,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
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
                          setState(() {
                            _selectedTipo = value!;
                            // Limpiar campos específicos al cambiar tipo
                            if (value == 'ampliacion_monto') {
                              _plazoController.clear();
                              _fechaNuevaEntrega = null;
                            } else {
                              _montoController.clear();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione un tipo';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Campos específicos según tipo
                      if (_selectedTipo == 'ampliacion_plazo' ||
                          _selectedTipo == 'prorroga_contrato')
                        ..._buildPlazoCampos()
                      else if (_selectedTipo == 'ampliacion_monto')
                        ..._buildMontoCampos(),

                      const SizedBox(height: 20),

                      // Justificación
                      Text(
                        'Justificación *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _justificacionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Describa las razones de la solicitud...',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La justificación es requerida';
                          }
                          if (value.length < 20) {
                            return 'La justificación debe tener al menos 20 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Observaciones
                      Text(
                        'Observaciones',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Información adicional (opcional)...',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
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
                        : const Icon(Icons.save),
                    label: const Text('Crear Solicitud'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicitacionSelector() {
    final licitacionesState = ref.watch(licitacionesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Licitación *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedLicitacionId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seleccione una licitación',
            prefixIcon: Icon(Icons.business_center),
          ),
          items: licitacionesState.data?.licitaciones.map((lic) {
            return DropdownMenuItem<int>(
              value: lic.licitacionId,
              child: Text(
                lic.titulo,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLicitacionId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Seleccione una licitación';
            }
            return null;
          },
        ),
      ],
    );
  }

  List<Widget> _buildPlazoCampos() {
    return [
      Text(
        'Plazo Solicitado (días) *',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _plazoController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Ej: 30',
          prefixIcon: Icon(Icons.access_time),
          suffixText: 'días',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'El plazo es requerido';
          }
          final plazo = int.tryParse(value);
          if (plazo == null || plazo <= 0) {
            return 'Ingrese un plazo válido';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      Text(
        'Nueva Fecha de Entrega',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => _selectFechaNuevaEntrega(),
        child: InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.event),
            suffixIcon: _fechaNuevaEntrega != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _fechaNuevaEntrega = null;
                      });
                    },
                  )
                : null,
          ),
          child: Text(
            _fechaNuevaEntrega != null
                ? DateFormat('dd/MM/yyyy').format(_fechaNuevaEntrega!)
                : 'Seleccione fecha (opcional)',
            style: TextStyle(
              color: _fechaNuevaEntrega != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMontoCampos() {
    return [
      Text(
        'Monto Solicitado *',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _montoController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Ej: 1000000',
          prefixIcon: Icon(Icons.attach_money),
          prefixText: '\$ ',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'El monto es requerido';
          }
          final monto = double.tryParse(value);
          if (monto == null || monto <= 0) {
            return 'Ingrese un monto válido';
          }
          return null;
        },
      ),
    ];
  }

  Future<void> _selectFechaNuevaEntrega() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNuevaEntrega ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaNuevaEntrega) {
      setState(() {
        _fechaNuevaEntrega = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLicitacionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una licitación')),
      );
      return;
    }

    final success = await ref.read(ampliacionCrudProvider.notifier).createAmpliacion(
      licitacionId: _selectedLicitacionId!,
      tipo: _selectedTipo,
      justificacion: _justificacionController.text,
      montoSolicitado: _selectedTipo == 'ampliacion_monto'
          ? double.tryParse(_montoController.text)
          : null,
      plazoSolicitadoDias: _selectedTipo != 'ampliacion_monto'
          ? int.tryParse(_plazoController.text)
          : null,
      fechaNuevaEntrega: _fechaNuevaEntrega,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      final error = ref.read(ampliacionCrudProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear solicitud'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
