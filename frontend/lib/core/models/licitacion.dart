import 'package:freezed_annotation/freezed_annotation.dart';

part 'licitacion.freezed.dart';
part 'licitacion.g.dart';

@freezed
class Licitacion with _$Licitacion {
  const factory Licitacion({
    @JsonKey(name: 'licitacion_id') required int licitacionId,
    @JsonKey(name: 'numero_licitacion') required String numeroLicitacion,
    @JsonKey(name: 'cliente_id') required int clienteId,
    @JsonKey(name: 'titulo_licitacion') required String tituloLicitacion,
    String? descripcion,
    @JsonKey(name: 'estado_licitacion') required String estadoLicitacion,
    required String categoria,
    @JsonKey(name: 'fecha_publicacion') DateTime? fechaPublicacion,
    @JsonKey(name: 'fecha_presentacion') DateTime? fechaPresentacion,
    @JsonKey(name: 'fecha_adjudicacion') DateTime? fechaAdjudicacion,
    @JsonKey(name: 'monto_estimado') double? montoEstimado,
    @JsonKey(name: 'monto_ofertado') double? montoOfertado,
    @JsonKey(name: 'monto_adjudicado') double? montoAdjudicado,
    @JsonKey(name: 'probabilidad_exito') int? probabilidadExito,
    @JsonKey(name: 'fecha_inicio_contrato') DateTime? fechaInicioContrato,
    @JsonKey(name: 'fecha_fin_contrato') DateTime? fechaFinContrato,
    @JsonKey(name: 'fecha_vencimiento_garantia') DateTime? fechaVencimientoGarantia,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Licitacion;

  factory Licitacion.fromJson(Map<String, dynamic> json) =>
      _$LicitacionFromJson(json);
}

/// Licitacion status enum
enum LicitacionEstado {
  @JsonValue('en_preparacion')
  enPreparacion('En Preparación', 'preparing'),
  @JsonValue('publicada')
  publicada('Publicada', 'published'),
  @JsonValue('presentada')
  presentada('Presentada', 'submitted'),
  @JsonValue('en_evaluacion')
  enEvaluacion('En Evaluación', 'evaluating'),
  @JsonValue('adjudicada')
  adjudicada('Adjudicada', 'awarded'),
  @JsonValue('en_ejecucion')
  enEjecucion('En Ejecución', 'executing'),
  @JsonValue('finalizada')
  finalizada('Finalizada', 'finished'),
  @JsonValue('rechazada')
  rechazada('Rechazada', 'rejected'),
  @JsonValue('desierta')
  desierta('Desierta', 'deserted');

  const LicitacionEstado(this.displayName, this.key);
  final String displayName;
  final String key;

  static LicitacionEstado fromString(String value) {
    return LicitacionEstado.values.firstWhere(
      (e) => e.name == value || e.key == value,
      orElse: () => LicitacionEstado.enPreparacion,
    );
  }
}

/// Licitacion category enum
enum LicitacionCategoria {
  @JsonValue('servicios')
  servicios('Servicios'),
  @JsonValue('obras')
  obras('Obras'),
  @JsonValue('suministros')
  suministros('Suministros'),
  @JsonValue('consultoria')
  consultoria('Consultoría'),
  @JsonValue('tecnologia')
  tecnologia('Tecnología'),
  @JsonValue('desarrollo')
  desarrollo('Desarrollo');

  const LicitacionCategoria(this.displayName);
  final String displayName;
}

@freezed
class LicitacionList with _$LicitacionList {
  const factory LicitacionList({
    required int total,
    required List<Licitacion> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _LicitacionList;

  factory LicitacionList.fromJson(Map<String, dynamic> json) =>
      _$LicitacionListFromJson(json);
}
