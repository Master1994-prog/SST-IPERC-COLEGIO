import 'dart:convert';

/// Representa un detalle IPERC almacenado localmente en SQLite.
///
/// Contiene el peligro, la consecuencia, las evaluaciones inicial y residual,
/// los controles, los EPP y el estado de sincronización.
class DetalleIpercLocalModel {
  const DetalleIpercLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.matrizIdLocal,
    this.actividadId,
    this.peligroId,
    this.consecuenciaId,
    this.actividadDescripcion,
    this.peligroDescripcion,
    this.consecuenciaDescripcion,
    required this.severidadInicial,
    required this.frecuenciaInicial,
    required this.valorRiesgoInicial,
    required this.nivelRiesgoInicial,
    this.controlIds = const <String>[],
    this.equipoProteccionIds = const <String>[],
    this.controlDescripcion,
    this.severidadResidual,
    this.frecuenciaResidual,
    this.valorRiesgoResidual,
    this.nivelRiesgoResidual,
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion,
    this.observaciones,
    this.sincronizado = false,
    this.eliminado = false,
    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  /// Identificador generado en el dispositivo.
  final String idLocal;

  /// Identificador asignado por el backend después de sincronizar.
  final String? idServidor;

  /// Identificador local de la matriz a la que pertenece.
  final String matrizIdLocal;

  final String? actividadId;
  final String? peligroId;
  final String? consecuenciaId;

  final String? actividadDescripcion;
  final String? peligroDescripcion;
  final String? consecuenciaDescripcion;

  /// Evaluación inicial.
  final int severidadInicial;
  final int frecuenciaInicial;
  final int valorRiesgoInicial;
  final String nivelRiesgoInicial;

  /// Controles y equipos seleccionados.
  final List<String> controlIds;
  final List<String> equipoProteccionIds;
  final String? controlDescripcion;

  /// Evaluación después de aplicar los controles.
  final int? severidadResidual;
  final int? frecuenciaResidual;
  final int? valorRiesgoResidual;
  final String? nivelRiesgoResidual;

  /// Datos para implementar los controles.
  final String? responsableImplementacionId;
  final DateTime? fechaCompromiso;
  final DateTime? fechaImplementacion;
  final String? estadoImplementacion;

  final String? observaciones;

  /// Estado local y de sincronización.
  final bool sincronizado;
  final bool eliminado;

  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final DateTime? fechaSincronizacion;

  /// Convierte el modelo al formato utilizado por SQLite.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_local': idLocal,
      'id_servidor': idServidor,
      'matriz_id_local': matrizIdLocal,
      'actividad_id': actividadId,
      'peligro_id': peligroId,
      'consecuencia_id': consecuenciaId,
      'actividad_descripcion': actividadDescripcion,
      'peligro_descripcion': peligroDescripcion,
      'consecuencia_descripcion': consecuenciaDescripcion,
      'severidad_inicial': severidadInicial,
      'frecuencia_inicial': frecuenciaInicial,
      'valor_riesgo_inicial': valorRiesgoInicial,
      'nivel_riesgo_inicial': nivelRiesgoInicial,
      'control_ids_json': jsonEncode(controlIds),
      'equipo_proteccion_ids_json': jsonEncode(equipoProteccionIds),
      'control_descripcion': controlDescripcion,
      'severidad_residual': severidadResidual,
      'frecuencia_residual': frecuenciaResidual,
      'valor_riesgo_residual': valorRiesgoResidual,
      'nivel_riesgo_residual': nivelRiesgoResidual,
      'responsable_implementacion_id': responsableImplementacionId,
      'fecha_compromiso': fechaCompromiso?.toIso8601String(),
      'fecha_implementacion': fechaImplementacion?.toIso8601String(),
      'estado_implementacion': estadoImplementacion,
      'observaciones': observaciones,
      'sincronizado': sincronizado ? 1 : 0,
      'eliminado': eliminado ? 1 : 0,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
    };
  }

  /// Crea el modelo utilizando un registro obtenido de SQLite.
  factory DetalleIpercLocalModel.fromMap(Map<String, dynamic> map) {
    return DetalleIpercLocalModel(
      idLocal: map['id_local'] as String,
      idServidor: map['id_servidor'] as String?,
      matrizIdLocal: map['matriz_id_local'] as String,
      actividadId: map['actividad_id'] as String?,
      peligroId: map['peligro_id'] as String?,
      consecuenciaId: map['consecuencia_id'] as String?,
      actividadDescripcion: map['actividad_descripcion'] as String?,
      peligroDescripcion: map['peligro_descripcion'] as String?,
      consecuenciaDescripcion: map['consecuencia_descripcion'] as String?,
      severidadInicial: (map['severidad_inicial'] as num).toInt(),
      frecuenciaInicial: (map['frecuencia_inicial'] as num).toInt(),
      valorRiesgoInicial: (map['valor_riesgo_inicial'] as num).toInt(),
      nivelRiesgoInicial: map['nivel_riesgo_inicial'] as String,
      controlIds: _decodeStringList(map['control_ids_json']),
      equipoProteccionIds: _decodeStringList(map['equipo_proteccion_ids_json']),
      controlDescripcion: map['control_descripcion'] as String?,
      severidadResidual: _nullableInt(map['severidad_residual']),
      frecuenciaResidual: _nullableInt(map['frecuencia_residual']),
      valorRiesgoResidual: _nullableInt(map['valor_riesgo_residual']),
      nivelRiesgoResidual: map['nivel_riesgo_residual'] as String?,
      responsableImplementacionId:
          map['responsable_implementacion_id'] as String?,
      fechaCompromiso: _nullableDate(map['fecha_compromiso']),
      fechaImplementacion: _nullableDate(map['fecha_implementacion']),
      estadoImplementacion: map['estado_implementacion'] as String?,
      observaciones: map['observaciones'] as String?,
      sincronizado: (map['sincronizado'] as num).toInt() == 1,
      eliminado: (map['eliminado'] as num).toInt() == 1,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
      fechaActualizacion: _nullableDate(map['fecha_actualizacion']),
      fechaSincronizacion: _nullableDate(map['fecha_sincronizacion']),
    );
  }

  /// Crea una copia del registro con información actualizada.
  DetalleIpercLocalModel copyWith({
    String? idServidor,
    String? actividadId,
    String? peligroId,
    String? consecuenciaId,
    String? actividadDescripcion,
    String? peligroDescripcion,
    String? consecuenciaDescripcion,
    int? severidadInicial,
    int? frecuenciaInicial,
    int? valorRiesgoInicial,
    String? nivelRiesgoInicial,
    List<String>? controlIds,
    List<String>? equipoProteccionIds,
    String? controlDescripcion,
    int? severidadResidual,
    int? frecuenciaResidual,
    int? valorRiesgoResidual,
    String? nivelRiesgoResidual,
    String? responsableImplementacionId,
    DateTime? fechaCompromiso,
    DateTime? fechaImplementacion,
    String? estadoImplementacion,
    String? observaciones,
    bool? sincronizado,
    bool? eliminado,
    DateTime? fechaActualizacion,
    DateTime? fechaSincronizacion,
  }) {
    return DetalleIpercLocalModel(
      idLocal: idLocal,
      idServidor: idServidor ?? this.idServidor,
      matrizIdLocal: matrizIdLocal,
      actividadId: actividadId ?? this.actividadId,
      peligroId: peligroId ?? this.peligroId,
      consecuenciaId: consecuenciaId ?? this.consecuenciaId,
      actividadDescripcion: actividadDescripcion ?? this.actividadDescripcion,
      peligroDescripcion: peligroDescripcion ?? this.peligroDescripcion,
      consecuenciaDescripcion:
          consecuenciaDescripcion ?? this.consecuenciaDescripcion,
      severidadInicial: severidadInicial ?? this.severidadInicial,
      frecuenciaInicial: frecuenciaInicial ?? this.frecuenciaInicial,
      valorRiesgoInicial: valorRiesgoInicial ?? this.valorRiesgoInicial,
      nivelRiesgoInicial: nivelRiesgoInicial ?? this.nivelRiesgoInicial,
      controlIds: controlIds ?? this.controlIds,
      equipoProteccionIds: equipoProteccionIds ?? this.equipoProteccionIds,
      controlDescripcion: controlDescripcion ?? this.controlDescripcion,
      severidadResidual: severidadResidual ?? this.severidadResidual,
      frecuenciaResidual: frecuenciaResidual ?? this.frecuenciaResidual,
      valorRiesgoResidual: valorRiesgoResidual ?? this.valorRiesgoResidual,
      nivelRiesgoResidual: nivelRiesgoResidual ?? this.nivelRiesgoResidual,
      responsableImplementacionId:
          responsableImplementacionId ?? this.responsableImplementacionId,
      fechaCompromiso: fechaCompromiso ?? this.fechaCompromiso,
      fechaImplementacion: fechaImplementacion ?? this.fechaImplementacion,
      estadoImplementacion: estadoImplementacion ?? this.estadoImplementacion,
      observaciones: observaciones ?? this.observaciones,
      sincronizado: sincronizado ?? this.sincronizado,
      eliminado: eliminado ?? this.eliminado,
      fechaRegistro: fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaSincronizacion: fechaSincronizacion ?? this.fechaSincronizacion,
    );
  }

  /// Convierte una columna JSON en una lista de identificadores.
  static List<String> _decodeStringList(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return <String>[];
    }

    try {
      final dynamic decoded = jsonDecode(value.toString());

      if (decoded is! List<dynamic>) {
        return <String>[];
      }

      return decoded.map((dynamic item) => item.toString()).toList();
    } on FormatException {
      return <String>[];
    }
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return (value as num).toInt();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
