import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/documento_provider.dart';
import '../../../../core/models/documento.dart';
import '../../../../core/theme/app_theme.dart';

class EditarDocumentoDialog extends ConsumerStatefulWidget {
  final Documento documento;

  const EditarDocumentoDialog({
    super.key,
    required this.documento,
  });

  @override
  ConsumerState<EditarDocumentoDialog> createState() => _EditarDocumentoDialogState();
}

class _EditarDocumentoDialogState extends ConsumerState<EditarDocumentoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _tagsController;

  late String _selectedTipo;
  late String _selectedEstado;
  DateTime? _fechaEmision;
  DateTime? _fechaVencimiento;
  late int _diasAlertaVencimiento;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _nombreController = TextEditingController(text: widget.documento.nombreDocumento);
    _descripcionController = TextEditingController(text: widget.documento.descripcion ?? '');
    _tagsController = TextEditingController(
      text: widget.documento.tags?.join(', ') ?? '',
    );

    _selectedTipo = widget.documento.tipoDocumento;
    _selectedEstado = widget.documento.estadoDocumento;
    _fechaEmision = widget.documento.fechaEmision;
    _fechaVencimiento = widget.documento.fechaVencimiento;
    _diasAlertaVencimiento = widget.documento.diasAlertaVencimiento ?? 15;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 900 ? 700.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(context),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Documento',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.documento.nombreArchivoOriginal,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solo puedes editar la información del documento, no el archivo. Para actualizar el archivo, sube una nueva versión.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Información Básica', Icons.info_outline),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del Documento *',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: _validateRequired,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTipo,
            decoration: InputDecoration(
              labelText: 'Tipo de Documento *',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'oferta_tecnica', child: Text('Oferta Técnica')),
              DropdownMenuItem(value: 'oferta_economica', child: Text('Oferta Económica')),
              DropdownMenuItem(value: 'pliego', child: Text('Pliego')),
              DropdownMenuItem(value: 'garantia', child: Text('Garantía')),
              DropdownMenuItem(value: 'certificacion', child: Text('Certificación')),
              DropdownMenuItem(value: 'contrato', child: Text('Contrato')),
              DropdownMenuItem(value: 'adenda', child: Text('Adenda')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTipo = value;
                });
              }
            },
            validator: _validateRequired,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedEstado,
            decoration: InputDecoration(
              labelText: 'Estado *',
              prefixIcon: const Icon(Icons.flag_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'activo', child: Text('Activo')),
              DropdownMenuItem(value: 'vencido', child: Text('Vencido')),
              DropdownMenuItem(value: 'reemplazado', child: Text('Reemplazado')),
              DropdownMenuItem(value: 'eliminado', child: Text('Eliminado')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedEstado = value;
                });
              }
            },
            validator: _validateRequired,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              prefixIcon: const Icon(Icons.notes_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Opcional',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Fechas', Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectFechaEmision(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de Emisión',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: _fechaEmision != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _fechaEmision = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Opcional',
              ),
              child: Text(
                _fechaEmision != null ? _formatDate(_fechaEmision!) : 'Seleccionar fecha',
                style: TextStyle(
                  color: _fechaEmision != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectFechaVencimiento(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de Vencimiento',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: _fechaVencimiento != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _fechaVencimiento = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Opcional',
              ),
              child: Text(
                _fechaVencimiento != null
                    ? _formatDate(_fechaVencimiento!)
                    : 'Seleccionar fecha',
                style: TextStyle(
                  color: _fechaVencimiento != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),
          if (_fechaVencimiento != null) ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _diasAlertaVencimiento.toString(),
              decoration: InputDecoration(
                labelText: 'Días de Alerta antes del Vencimiento',
                prefixIcon: const Icon(Icons.notifications_active_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Número de días antes de vencer para mostrar alerta',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final dias = int.tryParse(value);
                if (dias != null && dias >= 1 && dias <= 90) {
                  _diasAlertaVencimiento = dias;
                }
              },
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Tags', Icons.label_outlined),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags',
              hintText: 'legal, urgente, confidencial',
              prefixIcon: const Icon(Icons.label_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Separar con comas. Opcional',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Guardando...' : 'Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  Future<void> _selectFechaEmision(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEmision ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaEmision = picked;
      });
    }
  }

  Future<void> _selectFechaVencimiento(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaVencimiento = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final success = await ref.read(documentoCrudProvider.notifier).updateDocumento(
            widget.documento.documentoId,
            nombreDocumento: _nombreController.text.trim() != widget.documento.nombreDocumento
                ? _nombreController.text.trim()
                : null,
            tipoDocumento: _selectedTipo != widget.documento.tipoDocumento ? _selectedTipo : null,
            estadoDocumento: _selectedEstado != widget.documento.estadoDocumento ? _selectedEstado : null,
            descripcion: _descripcionController.text.trim() != (widget.documento.descripcion ?? '')
                ? (_descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim())
                : null,
            fechaEmision: _fechaEmision != widget.documento.fechaEmision ? _fechaEmision : null,
            fechaVencimiento: _fechaVencimiento != widget.documento.fechaVencimiento ? _fechaVencimiento : null,
            diasAlertaVencimiento: _diasAlertaVencimiento != (widget.documento.diasAlertaVencimiento ?? 15)
                ? _diasAlertaVencimiento
                : null,
            tags: tags.join(', ') != (widget.documento.tags?.join(', ') ?? '')
                ? (tags.isEmpty ? null : tags)
                : null,
          );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Documento actualizado exitosamente'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final error = ref.read(documentoCrudProvider).error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
