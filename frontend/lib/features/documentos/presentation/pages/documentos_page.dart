import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/documento_provider.dart';
import '../../../../core/models/documento.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/subir_documento_dialog.dart';

class DocumentosPage extends ConsumerWidget {
  const DocumentosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentosProvider);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const SizedBox(height: 24),
          _buildFilters(context, ref, state),
          const SizedBox(height: 24),
          Expanded(
            child: _buildDocumentosList(context, ref, state),
          ),
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
            Text(
              'Documentos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona archivos y documentos de licitaciones',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showSubirDocumentoDialog(context, ref),
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir Documento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, DocumentosState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, descripción...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onSubmitted: (value) {
                      ref.read(documentosProvider.notifier).setSearchQuery(
                            value.isEmpty ? null : value,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    value: state.filterTipoDocumento,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
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
                      ref.read(documentosProvider.notifier).setFilterTipoDocumento(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    value: state.filterEstadoDocumento,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'vencido', child: Text('Vencido')),
                      DropdownMenuItem(value: 'reemplazado', child: Text('Reemplazado')),
                      DropdownMenuItem(value: 'eliminado', child: Text('Eliminado')),
                    ],
                    onChanged: (value) {
                      ref.read(documentosProvider.notifier).setFilterEstadoDocumento(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (state.hasFilters)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref.read(documentosProvider.notifier).clearFilters();
                    },
                    tooltip: 'Limpiar filtros',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(documentosProvider.notifier).refresh();
                  },
                  tooltip: 'Actualizar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentosList(BuildContext context, WidgetRef ref, DocumentosState state) {
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
            Text(
              'Error al cargar documentos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(documentosProvider.notifier).refresh();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.data == null || state.data!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron documentos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza subiendo un documento',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showSubirDocumentoDialog(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Documento'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(documentosProvider.notifier).refresh();
            },
            child: ListView.builder(
              itemCount: state.data!.items.length,
              itemBuilder: (context, index) {
                final documento = state.data!.items[index];
                return _DocumentoCard(
                  documento: documento,
                  onTap: () => context.go('/documentos/${documento.documentoId}'),
                  onDownload: () => _downloadDocumento(context, ref, documento),
                );
              },
            ),
          ),
        ),
        if (state.data!.totalPages > 1) _buildPagination(context, ref, state),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, WidgetRef ref, DocumentosState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${state.currentPage} de ${state.data!.totalPages} (${state.data!.total} documentos)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1
                    ? () {
                        ref.read(documentosProvider.notifier).previousPage();
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.data!.totalPages
                    ? () {
                        ref.read(documentosProvider.notifier).nextPage();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSubirDocumentoDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const SubirDocumentoDialog(),
    );

    if (result == true) {
      ref.read(documentosProvider.notifier).refresh();
    }
  }

  Future<void> _downloadDocumento(BuildContext context, WidgetRef ref, Documento documento) async {
    final success = await ref.read(documentoCrudProvider.notifier).downloadDocumento(
          documento.documentoId,
          documento.nombreArchivoOriginal,
        );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Descarga iniciada'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    }
  }
}

class _DocumentoCard extends StatelessWidget {
  final Documento documento;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _DocumentoCard({
    required this.documento,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  _buildFileIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                documento.nombreDocumento,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (!documento.isUltimaVersion)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'v${documento.version}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          documento.nombreArchivoOriginal,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTipoBadge(context),
                  const SizedBox(width: 8),
                  _buildEstadoBadge(context),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.insert_drive_file_outlined,
                    _formatFileSize(documento.tamanioBytes),
                  ),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    Icons.calendar_today_outlined,
                    _formatDate(documento.creadoEn),
                  ),
                  if (documento.fechaVencimiento != null) ...[
                    const SizedBox(width: 16),
                    _buildVencimientoChip(),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    onPressed: onDownload,
                    tooltip: 'Descargar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    switch (documento.extension.toLowerCase()) {
      case '.pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case '.doc':
      case '.docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case '.zip':
      case '.rar':
        icon = Icons.folder_zip;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildTipoBadge(BuildContext context) {
    final tipo = _formatTipoDocumento(documento.tipoDocumento);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String estado;

    switch (documento.estadoDocumento.toLowerCase()) {
      case 'activo':
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        estado = 'Activo';
        break;
      case 'vencido':
        backgroundColor = AppTheme.dangerColor.withOpacity(0.1);
        textColor = AppTheme.dangerColor;
        estado = 'Vencido';
        break;
      case 'reemplazado':
        backgroundColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        estado = 'Reemplazado';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        estado = documento.estadoDocumento;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildVencimientoChip() {
    if (documento.fechaVencimiento == null) return const SizedBox.shrink();

    final diasHasta = documento.diasHastaVencimiento ?? 0;
    IconData icon;
    Color color;
    String text;

    if (diasHasta < 0) {
      icon = Icons.error_outline;
      color = AppTheme.dangerColor;
      text = 'Vencido hace ${-diasHasta} días';
    } else if (diasHasta == 0) {
      icon = Icons.warning_outlined;
      color = AppTheme.dangerColor;
      text = 'Vence hoy';
    } else if (diasHasta <= 15) {
      icon = Icons.warning_outlined;
      color = AppTheme.warningColor;
      text = 'Vence en $diasHasta días';
    } else {
      icon = Icons.calendar_today_outlined;
      color = AppTheme.infoColor;
      text = 'Vence: ${_formatDate(documento.fechaVencimiento!)}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTipoDocumento(String tipo) {
    const Map<String, String> tipos = {
      'oferta_tecnica': 'Oferta Técnica',
      'oferta_economica': 'Oferta Económica',
      'pliego': 'Pliego',
      'garantia': 'Garantía',
      'certificacion': 'Certificación',
      'contrato': 'Contrato',
      'adenda': 'Adenda',
      'otro': 'Otro',
    };
    return tipos[tipo] ?? tipo;
  }
}
