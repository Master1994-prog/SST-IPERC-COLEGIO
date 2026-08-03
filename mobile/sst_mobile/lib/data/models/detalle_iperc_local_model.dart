import 'dart:convert';

/// Representa un detalle IPERC almacenado localmente en SQLite.
///
/// Contiene:
/// - actividad, peligro y consecuencia;
/// - evaluación inicial y residual;
/// - controles y equipos de protección;
/// - información de implementación;
/// - estado de sincronización con el backend.
class DetalleIpercLocalModel {
  const DetalleIpercLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.matrizIdLocal,

    // Datos necesarios para sincronizar con la matriz del servidor.
    this.matrizIdServidor,
    this.item = 1,
    this.tarea = '',

    // Relaciones principales.
    this.actividadId,
    this.peligroId,
    this.consecuenciaId,

    // Descripciones para el funcionamiento offline.
    this.actividadDescripcion,
    this.peligroDescripcion,
    this.consecuenciaDescripcion,

    // Evaluación inicial.
    this.evaluacionInicialId,
    required this.severidadInicial,
    required this.frecuenciaInicial,
    required this.valorRiesgoInicial,
    required this.nivelRiesgoInicial,

    // Controles y EPP.
    this.controlIds = const <String>[],
    this.equipoProteccionIds = const <String>[],
    this.controlDescripcion,

    // Evaluación residual.
    this.evaluacionResidualId,
    this.severidadResidual,
    this.frecuenciaResidual,
    this.valorRiesgoResidual,
    this.nivelRiesgoResidual,

    // Implementación de controles.
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion,

    this.observaciones,

    // Sincronización.
    this.sincronizado = false,
    this.eliminado = false,

    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  // ============================================================
  // IDENTIFICADORES
  // ============================================================

  /// Identificador generado localmente en el celular.
  final String idLocal;

  /// Identificador asignado por el backend.
  final String? idServidor;

  /// Identificador local de la matriz IPERC.
  final String matrizIdLocal;

  /// Identificador numérico de la matriz almacenada en el backend.
  ///
  /// Se utiliza al enviar el detalle IPERC a la API.
  final int? matrizIdServidor;

  // ============================================================
  // DATOS DEL DETALLE
  // ============================================================

  /// Número correlativo dentro de la matriz IPERC.
  final int item;

  /// Tarea evaluada.
  final String tarea;

  final String? actividadId;
  final String? peligroId;
  final String? consecuenciaId;

  final String? actividadDescripcion;
  final String? peligroDescripcion;
  final String? consecuenciaDescripcion;

  // ============================================================
  // EVALUACIÓN INICIAL
  // ============================================================

  /// Identificador de la evaluación inicial registrada en el backend.
  final int? evaluacionInicialId;

  final int severidadInicial;
  final int frecuenciaInicial;
  final int valorRiesgoInicial;
  final String nivelRiesgoInicial;

  // ============================================================
  // CONTROLES Y EQUIPOS DE PROTECCIÓN
  // ============================================================

  final List<String> controlIds;
  final List<String> equipoProteccionIds;
  final String? controlDescripcion;

  // ============================================================
  // EVALUACIÓN RESIDUAL
  // ============================================================

  /// Identificador de la evaluación residual registrada en el backend.
  final int? evaluacionResidualId;

  final int? severidadResidual;
  final int? frecuenciaResidual;
  final int? valorRiesgoResidual;
  final String? nivelRiesgoResidual;

  // ============================================================
  // IMPLEMENTACIÓN DE CONTROLES
  // ============================================================

  final String? responsableImplementacionId;
  final DateTime? fechaCompromiso;
  final DateTime? fechaImplementacion;
  final String? estadoImplementacion;

  final String? observaciones;

  // ============================================================
  // ESTADO LOCAL Y SINCRONIZACIÓN
  // ============================================================

  final bool sincronizado;
  final bool eliminado;

  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final DateTime? fechaSincronizacion;

  // ============================================================
  // CONVERSIÓN PARA SQLITE
  // ============================================================

  /// Convierte el modelo al formato utilizado por SQLite.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_local': idLocal,
      'id_servidor': idServidor,
      'matriz_id_local': matrizIdLocal,
      'matriz_id_servidor': matrizIdServidor,
      'item': item,
      'tarea': tarea,
      'actividad_id': actividadId,
      'peligro_id': peligroId,
      'consecuencia_id': consecuenciaId,
      'actividad_descripcion': actividadDescripcion,
      'peligro_descripcion': peligroDescripcion,
      'consecuencia_descripcion': consecuenciaDescripcion,
      'evaluacion_inicial_id': evaluacionInicialId,
      'severidad_inicial': severidadInicial,
      'frecuencia_inicial': frecuenciaInicial,
      'valor_riesgo_inicial': valorRiesgoInicial,
      'nivel_riesgo_inicial': nivelRiesgoInicial,
      'control_ids_json': jsonEncode(controlIds),
      'equipo_proteccion_ids_json': jsonEncode(equipoProteccionIds),
      'control_descripcion': controlDescripcion,
      'evaluacion_residual_id': evaluacionResidualId,
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

  /// Crea el modelo a partir de un registro obtenido de SQLite.
  factory DetalleIpercLocalModel.fromMap(Map<String, dynamic> map) {
    return DetalleIpercLocalModel(
      idLocal: _stringValue(map['id_local']),
      idServidor: _nullableString(map['id_servidor']),
      matrizIdLocal: _stringValue(map['matriz_id_local']),
      matrizIdServidor: _nullableInt(map['matriz_id_servidor']),
      item: _intValue(map['item'], valorPredeterminado: 1),
      tarea: _stringValue(map['tarea']),
      actividadId: _nullableString(map['actividad_id']),
      peligroId: _nullableString(map['peligro_id']),
      consecuenciaId: _nullableString(map['consecuencia_id']),
      actividadDescripcion: _nullableString(map['actividad_descripcion']),
      peligroDescripcion: _nullableString(map['peligro_descripcion']),
      consecuenciaDescripcion: _nullableString(map['consecuencia_descripcion']),
      evaluacionInicialId: _nullableInt(map['evaluacion_inicial_id']),
      severidadInicial: _intValue(
        map['severidad_inicial'],
        valorPredeterminado: 1,
      ),
      frecuenciaInicial: _intValue(
        map['frecuencia_inicial'],
        valorPredeterminado: 1,
      ),
      valorRiesgoInicial: _intValue(
        map['valor_riesgo_inicial'],
        valorPredeterminado: 1,
      ),
      nivelRiesgoInicial: _stringValue(map['nivel_riesgo_inicial']),
      controlIds: _decodeStringList(map['control_ids_json']),
      equipoProteccionIds: _decodeStringList(map['equipo_proteccion_ids_json']),
      controlDescripcion: _nullableString(map['control_descripcion']),
      evaluacionResidualId: _nullableInt(map['evaluacion_residual_id']),
      severidadResidual: _nullableInt(map['severidad_residual']),
      frecuenciaResidual: _nullableInt(map['frecuencia_residual']),
      valorRiesgoResidual: _nullableInt(map['valor_riesgo_residual']),
      nivelRiesgoResidual: _nullableString(map['nivel_riesgo_residual']),
      responsableImplementacionId: _nullableString(
        map['responsable_implementacion_id'],
      ),
      fechaCompromiso: _nullableDate(map['fecha_compromiso']),
      fechaImplementacion: _nullableDate(map['fecha_implementacion']),
      estadoImplementacion: _nullableString(map['estado_implementacion']),
      observaciones: _nullableString(map['observaciones']),
      sincronizado: _boolValue(map['sincronizado']),
      eliminado: _boolValue(map['eliminado']),
      fechaRegistro:
          _nullableDate(map['fecha_registro']) ?? DateTime.now().toUtc(),
      fechaActualizacion: _nullableDate(map['fecha_actualizacion']),
      fechaSincronizacion: _nullableDate(map['fecha_sincronizacion']),
    );
  }

  // ============================================================
  // COPIA DEL MODELO
  // ============================================================

  /// Crea una copia del detalle con los valores proporcionados.
  DetalleIpercLocalModel copyWith({
    String? idServidor,
    int? matrizIdServidor,
    int? item,
    String? tarea,
    String? actividadId,
    String? peligroId,
    String? consecuenciaId,
    String? actividadDescripcion,
    String? peligroDescripcion,
    String? consecuenciaDescripcion,
    int? evaluacionInicialId,
    int? severidadInicial,
    int? frecuenciaInicial,
    int? valorRiesgoInicial,
    String? nivelRiesgoInicial,
    List<String>? controlIds,
    List<String>? equipoProteccionIds,
    String? controlDescripcion,
    int? evaluacionResidualId,
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
      matrizIdServidor: matrizIdServidor ?? this.matrizIdServidor,
      item: item ?? this.item,
      tarea: tarea ?? this.tarea,
      actividadId: actividadId ?? this.actividadId,
      peligroId: peligroId ?? this.peligroId,
      consecuenciaId: consecuenciaId ?? this.consecuenciaId,
      actividadDescripcion: actividadDescripcion ?? this.actividadDescripcion,
      peligroDescripcion: peligroDescripcion ?? this.peligroDescripcion,
      consecuenciaDescripcion:
          consecuenciaDescripcion ?? this.consecuenciaDescripcion,
      evaluacionInicialId: evaluacionInicialId ?? this.evaluacionInicialId,
      severidadInicial: severidadInicial ?? this.severidadInicial,
      frecuenciaInicial: frecuenciaInicial ?? this.frecuenciaInicial,
      valorRiesgoInicial: valorRiesgoInicial ?? this.valorRiesgoInicial,
      nivelRiesgoInicial: nivelRiesgoInicial ?? this.nivelRiesgoInicial,
      controlIds: controlIds ?? this.controlIds,
      equipoProteccionIds: equipoProteccionIds ?? this.equipoProteccionIds,
      controlDescripcion: controlDescripcion ?? this.controlDescripcion,
      evaluacionResidualId: evaluacionResidualId ?? this.evaluacionResidualId,
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

  // ============================================================
  // MÉTODOS AUXILIARES
  // ============================================================

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

      return decoded
          .map((dynamic item) => item.toString())
          .where((String item) => item.trim().isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return <String>[];
    }
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String texto = value.toString().trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }

  static int _intValue(dynamic value, {required int valorPredeterminado}) {
    if (value == null) {
      return valorPredeterminado;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? valorPredeterminado;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static bool _boolValue(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value.toInt() == 1;
    }

    final String texto = value.toString().toLowerCase().trim();

    return texto == '1' || texto == 'true';
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
