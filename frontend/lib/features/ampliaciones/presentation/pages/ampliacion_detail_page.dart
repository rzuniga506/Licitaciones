import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/ampliaciones_provider.dart';
import '../../../../core/models/ampliacion_prorroga.dart';

class AmpliacionDetailPage extends ConsumerWidget {
  final int ampliacionId;

  const AmpliacionDetailPage({super.key, required this.ampliacionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ampliacionAsync = ref.watch(ampliacionDetailProvider(ampliacionId));

    return Scaffold(
      body: ampliacionAsync.when(
        data: (ampliacion) => _buildContent(context, ref, ampliacion),
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
              Text('Error al cargar ampliación'),
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
    AmpliacionProrroga ampliacion,
  ) {
    return Column(
      children: [
        // Header
        _buildHeader(context, ampliacion),

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
                            _buildInformacionGeneral(context, ampliacion),
                            const SizedBox(height: 16),
                            _buildDetallesSolicitud(context, ampliacion),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            if (ampliacion.respuestaEntidad != null)
                              _buildRespuesta(context, ampliacion),
                            if (ampliacion.respuestaEntidad != null)
                              const SizedBox(height: 16),
                            _buildDocumentos(context, ampliacion),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout de una columna para pantallas pequeñas
                  return Column(
                    children: [
                      _buildInformacionGeneral(context, ampliacion),
                      const SizedBox(height: 16),
                      _buildDetallesSolicitud(context, ampliacion),
                      const SizedBox(height: 16),
                      if (ampliacion.respuestaEntidad != null) ...[
                        _buildRespuesta(context, ampliacion),
                        const SizedBox(height: 16),
                      ],
                      _buildDocumentos(context, ampliacion),
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

  Widget _buildHeader(BuildContext context, AmpliacionProrroga ampliacion) {
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
              Icon(
                _getTipoIcon(ampliacion.tipo),
                size: 32,
                color: _getTipoColor(ampliacion.tipo),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ampliacion.licitacionTitulo ??
                          'Licitación #${ampliacion.licitacionId}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solicitud #${ampliacion.ampliacionId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              _buildTipoBadge(context, ampliacion.tipo),
              const SizedBox(width: 8),
              _buildEstadoBadge(context, ampliacion.estado),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionGeneral(
    BuildContext context,
    AmpliacionProrroga ampliacion,
  ) {
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
            _buildInfoRow(
              context,
              'Licitación',
              ampliacion.licitacionTitulo ??
                  'Licitación #${ampliacion.licitacionId}',
              Icons.business_center,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Tipo de Solicitud',
              _getTipoLabel(ampliacion.tipo),
              Icons.category,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Estado',
              _getEstadoLabel(ampliacion.estado),
              Icons.flag,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Fecha de Solicitud',
              DateFormat('dd/MM/yyyy HH:mm').format(ampliacion.fechaSolicitud),
              Icons.calendar_today,
            ),
            if (ampliacion.fechaRespuesta != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Fecha de Respuesta',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(ampliacion.fechaRespuesta!),
                Icons.event_available,
              ),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Solicitante',
              ampliacion.solicitanteNombre ??
                  'Usuario #${ampliacion.solicitanteId}',
              Icons.person,
            ),
            if (ampliacion.aprobadorNombre != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                'Aprobador',
                ampliacion.aprobadorNombre!,
                Icons.verified_user,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesSolicitud(
    BuildContext context,
    AmpliacionProrroga ampliacion,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalles de la Solicitud',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campos específicos según tipo
            if (ampliacion.tipo == 'ampliacion_monto') ...[
              _buildInfoRow(
                context,
                'Monto Solicitado',
                NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(ampliacion.montoSolicitado ?? 0),
                Icons.attach_money,
              ),
              if (ampliacion.montoAprobado != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  'Monto Aprobado',
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(ampliacion.montoAprobado!),
                  Icons.check_circle,
                ),
              ],
            ] else ...[
              _buildInfoRow(
                context,
                'Plazo Solicitado',
                '${ampliacion.plazoSolicitadoDias ?? 0} días',
                Icons.access_time,
              ),
              if (ampliacion.plazoAprobadoDias != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  'Plazo Aprobado',
                  '${ampliacion.plazoAprobadoDias!} días',
                  Icons.check_circle,
                ),
              ],
              if (ampliacion.fechaNuevaEntrega != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  'Nueva Fecha de Entrega',
                  DateFormat('dd/MM/yyyy')
                      .format(ampliacion.fechaNuevaEntrega!),
                  Icons.event,
                ),
              ],
            ],

            const Divider(height: 24),

            // Justificación
            Text(
              'Justificación',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(ampliacion.justificacion),
            ),

            // Observaciones
            if (ampliacion.observaciones != null &&
                ampliacion.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Observaciones',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ampliacion.observaciones!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRespuesta(BuildContext context, AmpliacionProrroga ampliacion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.message_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Respuesta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getEstadoColor(ampliacion.estado).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(ampliacion.respuestaEntidad ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentos(BuildContext context, AmpliacionProrroga ampliacion) {
    final hasDocumentos = ampliacion.documentoSolicitudId != null ||
        ampliacion.documentoRespuestaId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Documentos Asociados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasDocumentos)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay documentos asociados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  if (ampliacion.documentoSolicitudId != null)
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Documento de Solicitud'),
                      subtitle: Text('ID: ${ampliacion.documentoSolicitudId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          // Navigate to documento detail
                          context.go(
                            '/documentos/${ampliacion.documentoSolicitudId}',
                          );
                        },
                      ),
                    ),
                  if (ampliacion.documentoRespuestaId != null)
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Documento de Respuesta'),
                      subtitle: Text('ID: ${ampliacion.documentoRespuestaId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          context.go(
                            '/documentos/${ampliacion.documentoRespuestaId}',
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
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

  Widget _buildTipoBadge(BuildContext context, String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTipoColor(tipo).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getTipoColor(tipo).withOpacity(0.3)),
      ),
      child: Text(
        _getTipoLabel(tipo),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getTipoColor(tipo),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context, String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getEstadoColor(estado).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getEstadoColor(estado).withOpacity(0.3)),
      ),
      child: Text(
        _getEstadoLabel(estado),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getEstadoColor(estado),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'ampliacion_plazo':
        return Icons.schedule;
      case 'prorroga_contrato':
        return Icons.event_repeat;
      case 'ampliacion_monto':
        return Icons.trending_up;
      default:
        return Icons.extension;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'ampliacion_plazo':
        return Colors.blue;
      case 'prorroga_contrato':
        return Colors.purple;
      case 'ampliacion_monto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'ampliacion_plazo':
        return 'Ampliación de Plazo';
      case 'prorroga_contrato':
        return 'Prórroga de Contrato';
      case 'ampliacion_monto':
        return 'Ampliación de Monto';
      default:
        return tipo;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'solicitada':
        return Colors.orange;
      case 'en_revision':
        return Colors.blue;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'solicitada':
        return 'Solicitada';
      case 'en_revision':
        return 'En Revisión';
      case 'aprobada':
        return 'Aprobada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return estado;
    }
  }
}
