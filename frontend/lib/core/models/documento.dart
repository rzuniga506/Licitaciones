import 'package:freezed_annotation/freezed_annotation.dart';

part 'documento.freezed.dart';
part 'documento.g.dart';

@freezed
class Documento with _$Documento {
  const factory Documento({
    @JsonKey(name: 'documento_id') required int documentoId,
    @JsonKey(name: 'licitacion_id') required int licitacionId,
    @JsonKey(name: 'nombre_documento') required String nombreDocumento,
    @JsonKey(name: 'nombre_archivo_original') required String nombreArchivoOriginal,
    @JsonKey(name: 'nombre_archivo_almacenado') required String nombreArchivoAlmacenado,
    @JsonKey(name: 'ruta_archivo') required String rutaArchivo,
    @JsonKey(name: 'extension') required String extension,
    @JsonKey(name: 'tamanio_bytes') required int tamanioBytes,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'tipo_documento') required String tipoDocumento,
    @JsonKey(name: 'categoria_documento') String? categoriaDocumento,
    @JsonKey(name: 'version') required int version,
    @JsonKey(name: 'documento_padre_id') int? documentoPadreId,
    @JsonKey(name: 'is_ultima_version') required bool isUltimaVersion,
    @JsonKey(name: 'fecha_emision') DateTime? fechaEmision,
    @JsonKey(name: 'fecha_vencimiento') DateTime? fechaVencimiento,
    @JsonKey(name: 'dias_alerta_vencimiento') int? diasAlertaVencimiento,
    @JsonKey(name: 'estado_documento') required String estadoDocumento,
    @JsonKey(name: 'descripcion') String? descripcion,
    @JsonKey(name: 'tags') List<String>? tags,
    @JsonKey(name: 'hash_archivo') String? hashArchivo,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'created_at') required DateTime creadoEn,
    @JsonKey(name: 'updated_at') DateTime? actualizadoEn,
    @JsonKey(name: 'uploaded_by') int? uploadedBy,
    @JsonKey(name: 'is_vencido') bool? isVencido,
    @JsonKey(name: 'dias_hasta_vencimiento') int? diasHastaVencimiento,
  }) = _Documento;

  factory Documento.fromJson(Map<String, dynamic> json) => _$DocumentoFromJson(json);
}

@freezed
class DocumentoList with _$DocumentoList {
  const factory DocumentoList({
    required int total,
    required List<Documento> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _DocumentoList;

  factory DocumentoList.fromJson(Map<String, dynamic> json) =>
      _$DocumentoListFromJson(json);
}
