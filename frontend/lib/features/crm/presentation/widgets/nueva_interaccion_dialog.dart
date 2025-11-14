import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/crm_provider.dart';
import '../../../../core/providers/cliente_provider.dart';
import '../../../../core/theme/app_theme.dart';

class NuevaInteraccionDialog extends ConsumerStatefulWidget {
  final int? clienteId;

  const NuevaInteraccionDialog({super.key, this.clienteId});

  @override
  ConsumerState<NuevaInteraccionDialog> createState() => _NuevaInteraccionDialogState();
}

class _NuevaInteraccionDialogState extends ConsumerState<NuevaInteraccionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _duracionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _puntosClaveController = TextEditingController();
  final _compromisosController = TextEditingController();

  int? _selectedClienteId;
  String _selectedTipo = 'reunion';
  String? _selectedModalidad;
  String? _selectedResultado;
  DateTime _fechaInteraccion = DateTime.now();
  int? _nivelInteres;
  bool _requiereSeguimiento = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedClienteId = widget.clienteId;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _duracionController.dispose();
    _observacionesController.dispose();
    _puntosClaveController.dispose();
    _compromisosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 900 ? 900.0 : MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildForm())),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      child: Row(
        children: [
          const Icon(Icons.add_comment, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva Interacción', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Registra una interacción con un cliente', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final clientesAsync = ref.watch(clientesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.clienteId == null && clientesAsync.data != null)
            DropdownButtonFormField<int>(
              value: _selectedClienteId,
              decoration: InputDecoration(labelText: 'Cliente *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: clientesAsync.data!.items.map((c) => DropdownMenuItem(value: c.clienteId, child: Text(c.nombreCliente))).toList(),
              onChanged: (value) => setState(() => _selectedClienteId = value),
              validator: (value) => value == null ? 'Selecciona un cliente' : null,
            ),
          if (widget.clienteId == null) const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTipo,
                  decoration: InputDecoration(labelText: 'Tipo *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'reunion', child: Text('Reunión')),
                    DropdownMenuItem(value: 'llamada', child: Text('Llamada')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'visita', child: Text('Visita')),
                    DropdownMenuItem(value: 'presentacion', child: Text('Presentación')),
                    DropdownMenuItem(value: 'seguimiento', child: Text('Seguimiento')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (value) => setState(() => _selectedTipo = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedModalidad,
                  decoration: InputDecoration(labelText: 'Modalidad', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Seleccionar')),
                    DropdownMenuItem(value: 'presencial', child: Text('Presencial')),
                    DropdownMenuItem(value: 'virtual', child: Text('Virtual')),
                    DropdownMenuItem(value: 'telefonica', child: Text('Telefónica')),
                    DropdownMenuItem(value: 'hibrida', child: Text('Híbrida')),
                  ],
                  onChanged: (value) => setState(() => _selectedModalidad = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tituloController,
            decoration: InputDecoration(labelText: 'Título *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionController,
            decoration: InputDecoration(labelText: 'Descripción *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            maxLines: 3,
            validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _fechaInteraccion, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_fechaInteraccion));
                      if (time != null) setState(() => _fechaInteraccion = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Fecha y Hora *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('${_fechaInteraccion.day}/${_fechaInteraccion.month}/${_fechaInteraccion.year} ${_fechaInteraccion.hour}:${_fechaInteraccion.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _duracionController, decoration: InputDecoration(labelText: 'Duración (min)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedResultado,
                  decoration: InputDecoration(labelText: 'Resultado', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Seleccionar')),
                    DropdownMenuItem(value: 'exitosa', child: Text('Exitosa')),
                    DropdownMenuItem(value: 'pendiente_seguimiento', child: Text('Pendiente seguimiento')),
                    DropdownMenuItem(value: 'sin_interes', child: Text('Sin interés')),
                    DropdownMenuItem(value: 'requiere_propuesta', child: Text('Requiere propuesta')),
                  ],
                  onChanged: (value) => setState(() => _selectedResultado = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _nivelInteres,
                  decoration: InputDecoration(labelText: 'Nivel de Interés', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Seleccionar')),
                    DropdownMenuItem(value: 1, child: Text('1 - Muy bajo')),
                    DropdownMenuItem(value: 2, child: Text('2 - Bajo')),
                    DropdownMenuItem(value: 3, child: Text('3 - Medio')),
                    DropdownMenuItem(value: 4, child: Text('4 - Alto')),
                    DropdownMenuItem(value: 5, child: Text('5 - Muy alto')),
                  ],
                  onChanged: (value) => setState(() => _nivelInteres = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Requiere Seguimiento'),
            value: _requiereSeguimiento,
            onChanged: (v) => setState(() => _requiereSeguimiento = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _puntosClaveController, decoration: InputDecoration(labelText: 'Puntos Clave', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
          const SizedBox(height: 16),
          TextFormField(controller: _compromisosController, decoration: InputDecoration(labelText: 'Compromisos', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Guardando...' : 'Guardar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || (_selectedClienteId == null && widget.clienteId == null)) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(interaccionCrudProvider.notifier).createInteraccion(
          clienteId: _selectedClienteId ?? widget.clienteId!,
          tipoInteraccion: _selectedTipo,
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          fechaInteraccion: _fechaInteraccion,
          duracionMinutos: _duracionController.text.isEmpty ? null : int.tryParse(_duracionController.text),
          ubicacion: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
          modalidad: _selectedModalidad,
          resultado: _selectedResultado,
          nivelInteres: _nivelInteres,
          requiereSeguimiento: _requiereSeguimiento,
          puntosClave: _puntosClaveController.text.trim().isEmpty ? null : _puntosClaveController.text.trim(),
          compromisos: _compromisosController.text.trim().isEmpty ? null : _compromisosController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interacción creada exitosamente'), backgroundColor: AppTheme.successColor));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(interaccionCrudProvider).error ?? 'Error desconocido'), backgroundColor: AppTheme.dangerColor));
        setState(() => _isSubmitting = false);
      }
    }
  }
}
