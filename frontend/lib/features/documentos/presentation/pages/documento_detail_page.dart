import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/documento_provider.dart';
import '../../../../core/models/documento.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../widgets/editar_documento_dialog.dart';

class DocumentoDetailPage extends ConsumerWidget {
  final int documentoId;

  const DocumentoDetailPage({
    super.key,
    required this.documentoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentoAsync = ref.watch(documentoDetailProvider(documentoId));
    final versionesAsync = ref.watch(versionHistoryProvider(documentoId));

    return AppScaffold(
      child: documentoAsync.when(
        data: (documento) => _buildContent(context, ref, documento, versionesAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Documento documento,
    AsyncValue<List<Documento>> versionesAsync,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, documento),
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLeftColumn(context, documento)),
                const SizedBox(width: 24),
                Expanded(child: _buildRightColumn(context, ref, documento, versionesAsync)),
              ],
            )
          else
            Column(
              children: [
                _buildLeftColumn(context, documento),
                const SizedBox(height: 24),
                _buildRightColumn(context, ref, documento, versionesAsync),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Documento documento) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/documentos'),
                ),
                const SizedBox(width: 12),
                _buildFileIcon(documento.extension),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              documento.nombreDocumento,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (!documento.isUltimaVersion)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Versión ${documento.version}',
                                style: TextStyle(
                                  fontSize: 12,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildEstadoBadge(context, documento.estadoDocumento),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _downloadDocumento(context, ref, documento),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEditarDialog(context, ref, documento),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDialog(context, ref, documento),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerColor,
                    side: const BorderSide(color: AppTheme.dangerColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, Documento documento) {
    return Column(
      children: [
        _buildInfoCard(context, documento),
        const SizedBox(height: 16),
        if (documento.descripcion != null && documento.descripcion!.isNotEmpty)
          _buildDescripcionCard(context, documento),
      ],
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    WidgetRef ref,
    Documento documento,
    AsyncValue<List<Documento>> versionesAsync,
  ) {
    return Column(
      children: [
        _buildMetadataCard(context, documento),
        const SizedBox(height: 16),
        if (documento.tags != null && documento.tags!.isNotEmpty) _buildTagsCard(context, documento),
        if (documento.tags != null && documento.tags!.isNotEmpty) const SizedBox(height: 16),
        _buildVersionesCard(context, ref, documento, versionesAsync),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, Documento documento) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información del Archivo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Nombre Original', documento.nombreArchivoOriginal, Icons.insert_drive_file_outlined),
            const SizedBox(height: 12),
            _buildInfoRow('Tamaño', _formatFileSize(documento.tamanioBytes), Icons.storage_outlined),
            const SizedBox(height: 12),
            _buildInfoRow('Tipo', _formatTipoDocumento(documento.tipoDocumento), Icons.category_outlined),
            const SizedBox(height: 12),
            _buildInfoRow('Extensión', documento.extension.toUpperCase(), Icons.code_outlined),
            if (documento.mimeType != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('MIME Type', documento.mimeType!, Icons.description_outlined),
            ],
            if (documento.fechaEmision != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Fecha de Emisión', _formatDate(documento.fechaEmision!), Icons.calendar_today_outlined),
            ],
            if (documento.fechaVencimiento != null) ...[
              const SizedBox(height: 12),
              _buildVencimientoRow(documento),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionCard(BuildContext context, Documento documento) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_outlined, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              documento.descripcion!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, Documento documento) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.successColor),
                const SizedBox(width: 8),
                Text(
                  'Metadata del Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('ID', '#${documento.documentoId}', Icons.tag_outlined),
            const SizedBox(height: 12),
            _buildInfoRow('Versión', '${documento.version}', Icons.layers_outlined),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Estado de Versión',
              documento.isUltimaVersion ? 'Última versión' : 'Versión antigua',
              Icons.update_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Subido', _formatDateTime(documento.creadoEn), Icons.upload_outlined),
            if (documento.actualizadoEn != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Última Actualización', _formatDateTime(documento.actualizadoEn!), Icons.update),
            ],
            if (documento.hashArchivo != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Hash (SHA256)', documento.hashArchivo!.substring(0, 16) + '...', Icons.fingerprint),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context, Documento documento) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label_outlined, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: documento.tags!.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionesCard(
    BuildContext context,
    WidgetRef ref,
    Documento documento,
    AsyncValue<List<Documento>> versionesAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_outlined, color: AppTheme.infoColor),
                    const SizedBox(width: 8),
                    Text(
                      'Historial de Versiones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement upload new version
                  },
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: const Text('Nueva Versión'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            versionesAsync.when(
              data: (versiones) {
                if (versiones.isEmpty) {
                  return const Text('No hay versiones anteriores');
                }

                return Column(
                  children: versiones.map((version) {
                    final isCurrent = version.documentoId == documentoId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent ? AppTheme.primaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? Icons.check_circle : Icons.circle_outlined,
                            color: isCurrent ? AppTheme.primaryColor : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Versión ${version.version}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? AppTheme.primaryColor : Colors.black,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(version.creadoEn),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCurrent)
                            IconButton(
                              icon: const Icon(Icons.download_outlined, size: 18),
                              onPressed: () => _downloadDocumento(context, ref, version),
                              tooltip: 'Descargar esta versión',
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVencimientoRow(Documento documento) {
    final diasHasta = documento.diasHastaVencimiento ?? 0;
    Color color;
    IconData icon;
    String status;

    if (diasHasta < 0) {
      color = AppTheme.dangerColor;
      icon = Icons.error_outline;
      status = 'Vencido hace ${-diasHasta} días';
    } else if (diasHasta == 0) {
      color = AppTheme.dangerColor;
      icon = Icons.warning_outlined;
      status = 'Vence hoy';
    } else if (diasHasta <= 15) {
      color = AppTheme.warningColor;
      icon = Icons.warning_outlined;
      status = 'Vence en $diasHasta días';
    } else {
      color = AppTheme.successColor;
      icon = Icons.check_circle_outline;
      status = 'Vence en $diasHasta días';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha de Vencimiento',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(documento.fechaVencimiento!),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon(String extension) {
    IconData icon;
    Color color;

    switch (extension.toLowerCase()) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildEstadoBadge(BuildContext context, String estado) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (estado.toLowerCase()) {
      case 'activo':
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        label = 'Activo';
        break;
      case 'vencido':
        backgroundColor = AppTheme.dangerColor.withOpacity(0.1);
        textColor = AppTheme.dangerColor;
        label = 'Vencido';
        break;
      case 'reemplazado':
        backgroundColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        label = 'Reemplazado';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
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

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.dangerColor),
          const SizedBox(height: 16),
          Text(
            'Error al cargar documento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/documentos'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Documentos'),
          ),
        ],
      ),
    );
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

  Future<void> _showEditarDialog(BuildContext context, WidgetRef ref, Documento documento) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditarDocumentoDialog(documento: documento),
    );

    if (result == true) {
      ref.invalidate(documentoDetailProvider(documentoId));
      ref.invalidate(documentosProvider);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, Documento documento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el documento "${documento.nombreDocumento}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(documentoCrudProvider.notifier).deleteDocumento(documentoId);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Documento eliminado exitosamente'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/documentos');
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
}
