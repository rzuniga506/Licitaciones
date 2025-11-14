import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/crm_provider.dart';
import '../../../../core/providers/cliente_provider.dart';
import '../../../../core/theme/app_theme.dart';

class NuevoContactoDialog extends ConsumerStatefulWidget {
  final int? clienteId;

  const NuevoContactoDialog({super.key, this.clienteId});

  @override
  ConsumerState<NuevoContactoDialog> createState() => _NuevoContactoDialogState();
}

class _NuevoContactoDialogState extends ConsumerState<NuevoContactoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _extensionController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _horarioController = TextEditingController();
  final _notasController = TextEditingController();

  int? _selectedClienteId;
  String? _selectedNivel;
  String? _selectedPreferencia;
  bool _esContactoPrincipal = false;
  bool _puedeFirmar = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedClienteId = widget.clienteId;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cargoController.dispose();
    _departamentoController.dispose();
    _telefonoController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _extensionController.dispose();
    _linkedinController.dispose();
    _horarioController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 900 ? 800.0 : MediaQuery.of(context).size.width * 0.9,
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
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo Contacto', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Registra un nuevo contacto', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9))),
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
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _cargoController, decoration: InputDecoration(labelText: 'Cargo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _departamentoController, decoration: InputDecoration(labelText: 'Departamento', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _telefonoController, decoration: InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _celularController, decoration: InputDecoration(labelText: 'Celular', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedNivel,
                  decoration: InputDecoration(labelText: 'Nivel Decisión', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Seleccionar')),
                    DropdownMenuItem(value: 'ejecutivo', child: Text('Ejecutivo')),
                    DropdownMenuItem(value: 'gerencial', child: Text('Gerencial')),
                    DropdownMenuItem(value: 'operativo', child: Text('Operativo')),
                    DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                  ],
                  onChanged: (value) => setState(() => _selectedNivel = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPreferencia,
                  decoration: InputDecoration(labelText: 'Preferencia Contacto', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Seleccionar')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'telefono', child: Text('Teléfono')),
                    DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                    DropdownMenuItem(value: 'presencial', child: Text('Presencial')),
                  ],
                  onChanged: (value) => setState(() => _selectedPreferencia = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: CheckboxListTile(title: const Text('Contacto Principal'), value: _esContactoPrincipal, onChanged: (v) => setState(() => _esContactoPrincipal = v ?? false))),
              Expanded(child: CheckboxListTile(title: const Text('Puede Firmar'), value: _puedeFirmar, onChanged: (v) => setState(() => _puedeFirmar = v ?? false))),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _notasController, decoration: InputDecoration(labelText: 'Notas', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
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

    final success = await ref.read(contactoCrudProvider.notifier).createContacto(
          clienteId: _selectedClienteId ?? widget.clienteId!,
          nombreContacto: _nombreController.text.trim(),
          cargo: _cargoController.text.trim().isEmpty ? null : _cargoController.text.trim(),
          departamento: _departamentoController.text.trim().isEmpty ? null : _departamentoController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
          celular: _celularController.text.trim().isEmpty ? null : _celularController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          extension: _extensionController.text.trim().isEmpty ? null : _extensionController.text.trim(),
          linkedinUrl: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
          esContactoPrincipal: _esContactoPrincipal,
          puedeFirmar: _puedeFirmar,
          nivelDecision: _selectedNivel,
          preferenciaContacto: _selectedPreferencia,
          mejorHorarioContacto: _horarioController.text.trim().isEmpty ? null : _horarioController.text.trim(),
          notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacto creado exitosamente'), backgroundColor: AppTheme.successColor));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.read(contactoCrudProvider).error ?? 'Error desconocido'), backgroundColor: AppTheme.dangerColor));
        setState(() => _isSubmitting = false);
      }
    }
  }
}
