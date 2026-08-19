import 'mapa_riesgo_model.dart';

class MapaRiesgoLocalModel {
  const MapaRiesgoLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.matrizIpercIdServidor,
    required this.nombre,
    this.codigo,
    this.descripcion,
    this.ubicacion,
    this.archivoUrlServidor,
    this.archivoLocal,
    this.tipoArchivo,
    this.marcadoresJson,
    required this.fechaElaboracion,
    this.fechaRevision,
    required this.version,
    required this.estadoMapa,
    required this.activo,
    required this.sincronizado,
    required this.eliminado,
    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  final String idLocal;
  final int? idServidor;
  final int matrizIpercIdServidor;
  final String nombre;
  final String? codigo;
  final String? descripcion;
  final String? ubicacion;
  final String? archivoUrlServidor;
  final String? archivoLocal;
  final String? tipoArchivo;
  final String? marcadoresJson;
  final DateTime fechaElaboracion;
  final DateTime? fechaRevision;
  final int version;
  final String estadoMapa;
  final bool activo;
  final bool sincronizado;
  final bool eliminado;
  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final DateTime? fechaSincronizacion;

  factory MapaRiesgoLocalModel.fromMap(Map<String, dynamic> map) {
    return MapaRiesgoLocalModel(
      idLocal: map['id_local']?.toString() ?? '',
      idServidor: _nullableInt(map['id_servidor']),
      matrizIpercIdServidor: _toInt(map['matriz_iperc_id_servidor']),
      nombre: map['nombre']?.toString() ?? '',
      codigo: map['codigo']?.toString(),
      descripcion: map['descripcion']?.toString(),
      ubicacion: map['ubicacion']?.toString(),
      archivoUrlServidor: map['archivo_url_servidor']?.toString(),
      archivoLocal: map['archivo_local']?.toString(),
      tipoArchivo: map['tipo_archivo']?.toString(),
      marcadoresJson: map['marcadores_json']?.toString(),
      fechaElaboracion:
          DateTime.tryParse(map['fecha_elaboracion']?.toString() ?? '') ??
          DateTime.now(),
      fechaRevision: DateTime.tryParse(map['fecha_revision']?.toString() ?? ''),
      version: _toInt(map['version'], fallback: 1),
      estadoMapa: map['estado_mapa']?.toString() ?? 'Borrador',
      activo: _toBool(map['activo'], fallback: true),
      sincronizado: _toBool(map['sincronizado']),
      eliminado: _toBool(map['eliminado']),
      fechaRegistro:
          DateTime.tryParse(map['fecha_registro']?.toString() ?? '') ??
          DateTime.now(),
      fechaActualizacion: DateTime.tryParse(
        map['fecha_actualizacion']?.toString() ?? '',
      ),
      fechaSincronizacion: DateTime.tryParse(
        map['fecha_sincronizacion']?.toString() ?? '',
      ),
    );
  }

  factory MapaRiesgoLocalModel.fromRemote(
    MapaRiesgoModel remote, {
    required String idLocal,
    String? archivoLocal,
  }) {
    final now = DateTime.now();
    return MapaRiesgoLocalModel(
      idLocal: idLocal,
      idServidor: remote.id,
      matrizIpercIdServidor: remote.matrizIpercId,
      nombre: remote.nombre,
      codigo: remote.codigo,
      descripcion: remote.descripcion,
      ubicacion: remote.ubicacion,
      archivoUrlServidor: remote.archivoUrl,
      archivoLocal: archivoLocal,
      tipoArchivo: remote.tipoArchivo,
      marcadoresJson: remote.marcadoresJson,
      fechaElaboracion: remote.fechaElaboracion,
      fechaRevision: remote.fechaRevision,
      version: remote.version,
      estadoMapa: remote.estadoMapa,
      activo: remote.activo,
      sincronizado: true,
      eliminado: false,
      fechaRegistro: now,
      fechaActualizacion: now,
      fechaSincronizacion: now,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id_local': idLocal,
    'id_servidor': idServidor,
    'matriz_iperc_id_servidor': matrizIpercIdServidor,
    'codigo': codigo,
    'nombre': nombre,
    'descripcion': descripcion,
    'ubicacion': ubicacion,
    'archivo_url_servidor': archivoUrlServidor,
    'archivo_local': archivoLocal,
    'tipo_archivo': tipoArchivo,
    'marcadores_json': marcadoresJson,
    'fecha_elaboracion': fechaElaboracion.toIso8601String(),
    'fecha_revision': fechaRevision?.toIso8601String(),
    'version': version,
    'estado_mapa': estadoMapa,
    'activo': activo ? 1 : 0,
    'sincronizado': sincronizado ? 1 : 0,
    'eliminado': eliminado ? 1 : 0,
    'fecha_registro': fechaRegistro.toIso8601String(),
    'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
  };

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return fallback;
  }
}
