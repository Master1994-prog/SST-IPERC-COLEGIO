class MapaRiesgoModel {
  const MapaRiesgoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.ubicacion,
    this.archivoUrl,
    this.tipoArchivo,
    this.marcadoresJson,
    required this.fechaElaboracion,
    this.fechaRevision,
    required this.version,
    required this.estadoMapa,
    required this.activo,
    required this.matrizIpercId,
    this.matrizIpercCodigo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? ubicacion;
  final String? archivoUrl;
  final String? tipoArchivo;
  final String? marcadoresJson;
  final DateTime fechaElaboracion;
  final DateTime? fechaRevision;
  final int version;
  final String estadoMapa;
  final bool activo;
  final int matrizIpercId;
  final String? matrizIpercCodigo;

  factory MapaRiesgoModel.fromJson(Map<String, dynamic> json) {
    return MapaRiesgoModel(
      id: _toInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      archivoUrl: json['archivoUrl']?.toString(),
      tipoArchivo: json['tipoArchivo']?.toString(),
      marcadoresJson: json['marcadoresJson']?.toString(),
      fechaElaboracion:
          DateTime.tryParse(json['fechaElaboracion']?.toString() ?? '') ??
          DateTime.now(),
      fechaRevision: DateTime.tryParse(json['fechaRevision']?.toString() ?? ''),
      version: _toInt(json['version'], fallback: 1),
      estadoMapa: json['estadoMapa']?.toString() ?? 'Borrador',
      activo: _toBool(json['activo'], fallback: true),
      matrizIpercId: _toInt(json['matrizIPERCId'] ?? json['matrizIpercId']),
      matrizIpercCodigo:
          (json['matrizIPERCCodigo'] ?? json['matrizIpercCodigo'])?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() => <String, dynamic>{
    'nombre': nombre,
    'descripcion': descripcion,
    'ubicacion': ubicacion,
    'archivoUrl': archivoUrl,
    'tipoArchivo': tipoArchivo,
    'marcadoresJson': marcadoresJson,
    'fechaElaboracion': fechaElaboracion.toIso8601String(),
    'fechaRevision': fechaRevision?.toIso8601String(),
    'version': version,
    'estadoMapa': estadoMapa,
    'matrizIPERCId': matrizIpercId,
  };

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    ...toCreateJson(),
    'activo': activo,
  };

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase() ?? '';
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }
}
