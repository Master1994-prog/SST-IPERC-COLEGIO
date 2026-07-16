class SyncQueueModel {
  const SyncQueueModel({
    this.id,
    required this.entidad,
    required this.entidadIdLocal,
    required this.operacion,
    required this.datosJson,
    this.estado = 'PENDIENTE',
    this.numeroIntentos = 0,
    this.ultimoError,
    required this.fechaCreacion,
    this.fechaUltimoIntento,
    this.fechaSincronizacion,
  });

  final int? id;
  final String entidad;
  final String entidadIdLocal;
  final String operacion;
  final String datosJson;
  final String estado;
  final int numeroIntentos;
  final String? ultimoError;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoIntento;
  final DateTime? fechaSincronizacion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entidad': entidad,
      'entidad_id_local': entidadIdLocal,
      'operacion': operacion,
      'datos_json': datosJson,
      'estado': estado,
      'numero_intentos': numeroIntentos,
      'ultimo_error': ultimoError,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_ultimo_intento': fechaUltimoIntento?.toIso8601String(),
      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
    };
  }

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as int?,
      entidad: map['entidad'] as String,
      entidadIdLocal: map['entidad_id_local'] as String,
      operacion: map['operacion'] as String,
      datosJson: map['datos_json'] as String,
      estado: map['estado'] as String,
      numeroIntentos: map['numero_intentos'] as int,
      ultimoError: map['ultimo_error'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      fechaUltimoIntento: map['fecha_ultimo_intento'] == null
          ? null
          : DateTime.parse(map['fecha_ultimo_intento'] as String),
      fechaSincronizacion: map['fecha_sincronizacion'] == null
          ? null
          : DateTime.parse(map['fecha_sincronizacion'] as String),
    );
  }
}
