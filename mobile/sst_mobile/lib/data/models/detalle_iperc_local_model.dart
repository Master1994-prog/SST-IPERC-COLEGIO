import 'dart:convert';

/// ===============================================================
/// MODELO LOCAL - DETALLE IPERC
/// ===============================================================
///
/// Representa un detalle IPERC almacenado localmente en SQLite.
///
/// Este modelo mantiene separados:
///
/// 1. El ID real del catálogo del backend.
/// 2. El valor utilizado en la matriz IPERC 5x5.
///
/// Ejemplo:
///
/// probabilidadInicialId = 8
/// frecuenciaInicial = 3
///
/// Esto evita asumir incorrectamente que:
///
/// ID catálogo == valor IPERC
///
/// Los campos antiguos se mantienen temporalmente para no romper
/// las pantallas y servicios offline existentes.
/// ===============================================================
class DetalleIpercLocalModel {
  const DetalleIpercLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.matrizIdLocal,

    // Matriz servidor.
    this.matrizIdServidor,

    this.item = 1,
    this.tarea = '',

    // Relaciones principales.
    this.actividadId,
    this.peligroId,
    this.consecuenciaId,

    // Descripciones offline.
    this.actividadDescripcion,
    this.peligroDescripcion,
    this.consecuenciaDescripcion,

    // ===========================================================
    // EVALUACIÓN INICIAL
    // ===========================================================
    this.evaluacionInicialId,

    // IDs reales de los catálogos del backend.
    this.probabilidadInicialId,
    this.severidadInicialId,

    // Valores IPERC 1..5.
    required this.severidadInicial,
    required this.frecuenciaInicial,

    required this.valorRiesgoInicial,
    required this.nivelRiesgoInicial,

    // ===========================================================
    // CONTROLES Y EPP
    // ===========================================================
    this.controlIds = const <String>[],
    this.equipoProteccionIds = const <String>[],
    this.controlDescripcion,

    // ===========================================================
    // EVALUACIÓN RESIDUAL
    // ===========================================================
    this.evaluacionResidualId,

    // IDs reales de catálogo.
    this.probabilidadResidualId,
    this.severidadResidualId,

    // Valores IPERC 1..5.
    this.severidadResidual,
    this.frecuenciaResidual,

    this.valorRiesgoResidual,
    this.nivelRiesgoResidual,

    // ===========================================================
    // IMPLEMENTACIÓN
    // ===========================================================
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion,

    this.observaciones,

    // ===========================================================
    // SINCRONIZACIÓN
    // ===========================================================
    this.sincronizado = false,
    this.eliminado = false,

    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  // =============================================================
  // IDENTIFICADORES
  // =============================================================

  /// ID generado localmente.
  final String idLocal;

  /// ID asignado posteriormente por el backend.
  final String? idServidor;

  /// ID local de la matriz.
  final String matrizIdLocal;

  /// ID real de la matriz en el backend.
  final int? matrizIdServidor;

  // =============================================================
  // DATOS DEL DETALLE
  // =============================================================

  final int item;

  final String tarea;

  final String? actividadId;

  final String? peligroId;

  final String? consecuenciaId;

  final String? actividadDescripcion;

  final String? peligroDescripcion;

  final String? consecuenciaDescripcion;

  // =============================================================
  // EVALUACIÓN INICIAL
  // =============================================================

  /// ID de EvaluacionRiesgo una vez sincronizada.
  ///
  /// No se envía para crear una evaluación nueva.
  final int? evaluacionInicialId;

  /// ID real de Probabilidad en MySQL.
  final int? probabilidadInicialId;

  /// ID real de Severidad en MySQL.
  final int? severidadInicialId;

  /// Valor 1..5 utilizado por la matriz.
  ///
  /// Este nombre se mantiene por compatibilidad con
  /// el código offline existente.
  final int frecuenciaInicial;

  /// Valor 1..5 utilizado por la matriz.
  final int severidadInicial;

  /// Resultado:
  ///
  /// frecuenciaInicial × severidadInicial
  final int valorRiesgoInicial;

  final String nivelRiesgoInicial;

  // =============================================================
  // CONTROLES Y EPP
  // =============================================================

  final List<String> controlIds;

  final List<String> equipoProteccionIds;

  final String? controlDescripcion;

  // =============================================================
  // EVALUACIÓN RESIDUAL
  // =============================================================

  /// ID de EvaluacionRiesgo residual después de sincronizar.
  final int? evaluacionResidualId;

  /// ID real del catálogo Probabilidad.
  final int? probabilidadResidualId;

  /// ID real del catálogo Severidad.
  final int? severidadResidualId;

  /// Valor residual de probabilidad 1..5.
  ///
  /// Se mantiene el nombre frecuenciaResidual
  /// para compatibilidad con el código existente.
  final int? frecuenciaResidual;

  /// Valor residual de severidad 1..5.
  final int? severidadResidual;

  final int? valorRiesgoResidual;

  final String? nivelRiesgoResidual;

  // =============================================================
  // IMPLEMENTACIÓN
  // =============================================================

  final String? responsableImplementacionId;

  final DateTime? fechaCompromiso;

  final DateTime? fechaImplementacion;

  final String? estadoImplementacion;

  final String? observaciones;

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  final bool sincronizado;

  final bool eliminado;

  final DateTime fechaRegistro;

  final DateTime? fechaActualizacion;

  final DateTime? fechaSincronizacion;

  // =============================================================
  // GETTERS ÚTILES
  // =============================================================

  /// Indica si la evaluación inicial tiene IDs reales
  /// disponibles para sincronización segura.
  bool get tieneIdsEvaluacionInicial {
    return probabilidadInicialId != null &&
        probabilidadInicialId! > 0 &&
        severidadInicialId != null &&
        severidadInicialId! > 0;
  }

  /// Indica si existe evaluación residual.
  bool get tieneEvaluacionResidual {
    return frecuenciaResidual != null && severidadResidual != null;
  }

  /// Indica si la residual ya tiene IDs reales
  /// del catálogo del backend.
  bool get tieneIdsEvaluacionResidual {
    if (!tieneEvaluacionResidual) {
      return false;
    }

    return probabilidadResidualId != null &&
        probabilidadResidualId! > 0 &&
        severidadResidualId != null &&
        severidadResidualId! > 0;
  }

  /// Recalcula únicamente el valor inicial.
  int get riesgoInicialCalculado {
    return frecuenciaInicial * severidadInicial;
  }

  /// Calcula el residual cuando existen sus dos valores.
  int? get riesgoResidualCalculado {
    final int? probabilidad = frecuenciaResidual;
    final int? severidad = severidadResidual;

    if (probabilidad == null || severidad == null) {
      return null;
    }

    return probabilidad * severidad;
  }

  // =============================================================
  // CONVERSIÓN A SQLITE
  // =============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      // Identificadores.
      'id_local': idLocal,
      'id_servidor': idServidor,

      'matriz_id_local': matrizIdLocal,
      'matriz_id_servidor': matrizIdServidor,

      // Detalle.
      'item': item,
      'tarea': tarea,

      'actividad_id': actividadId,
      'peligro_id': peligroId,
      'consecuencia_id': consecuenciaId,

      'actividad_descripcion': actividadDescripcion,
      'peligro_descripcion': peligroDescripcion,
      'consecuencia_descripcion': consecuenciaDescripcion,

      // =========================================================
      // EVALUACIÓN INICIAL
      // =========================================================
      'evaluacion_inicial_id': evaluacionInicialId,

      // Nuevas columnas.
      'probabilidad_inicial_id': probabilidadInicialId,
      'severidad_inicial_id': severidadInicialId,

      // Valores 1..5 existentes.
      'severidad_inicial': severidadInicial,
      'frecuencia_inicial': frecuenciaInicial,

      'valor_riesgo_inicial': valorRiesgoInicial,
      'nivel_riesgo_inicial': nivelRiesgoInicial,

      // =========================================================
      // CONTROLES / EPP
      // =========================================================
      'control_ids_json': jsonEncode(controlIds),

      'equipo_proteccion_ids_json': jsonEncode(equipoProteccionIds),

      'control_descripcion': controlDescripcion,

      // =========================================================
      // EVALUACIÓN RESIDUAL
      // =========================================================
      'evaluacion_residual_id': evaluacionResidualId,

      // Nuevas columnas.
      'probabilidad_residual_id': probabilidadResidualId,
      'severidad_residual_id': severidadResidualId,

      // Valores 1..5 existentes.
      'severidad_residual': severidadResidual,
      'frecuencia_residual': frecuenciaResidual,

      'valor_riesgo_residual': valorRiesgoResidual,
      'nivel_riesgo_residual': nivelRiesgoResidual,

      // =========================================================
      // IMPLEMENTACIÓN
      // =========================================================
      'responsable_implementacion_id': responsableImplementacionId,

      'fecha_compromiso': fechaCompromiso?.toIso8601String(),

      'fecha_implementacion': fechaImplementacion?.toIso8601String(),

      'estado_implementacion': estadoImplementacion,

      'observaciones': observaciones,

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      'sincronizado': sincronizado ? 1 : 0,

      'eliminado': eliminado ? 1 : 0,

      'fecha_registro': fechaRegistro.toIso8601String(),

      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),

      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
    };
  }

  // =============================================================
  // DESDE SQLITE
  // =============================================================

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

      // =========================================================
      // EVALUACIÓN INICIAL
      // =========================================================
      evaluacionInicialId: _nullableInt(map['evaluacion_inicial_id']),

      probabilidadInicialId: _nullableInt(map['probabilidad_inicial_id']),

      severidadInicialId: _nullableInt(map['severidad_inicial_id']),

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

      // =========================================================
      // CONTROLES
      // =========================================================
      controlIds: _decodeStringList(map['control_ids_json']),

      equipoProteccionIds: _decodeStringList(map['equipo_proteccion_ids_json']),

      controlDescripcion: _nullableString(map['control_descripcion']),

      // =========================================================
      // EVALUACIÓN RESIDUAL
      // =========================================================
      evaluacionResidualId: _nullableInt(map['evaluacion_residual_id']),

      probabilidadResidualId: _nullableInt(map['probabilidad_residual_id']),

      severidadResidualId: _nullableInt(map['severidad_residual_id']),

      severidadResidual: _nullableInt(map['severidad_residual']),

      frecuenciaResidual: _nullableInt(map['frecuencia_residual']),

      valorRiesgoResidual: _nullableInt(map['valor_riesgo_residual']),

      nivelRiesgoResidual: _nullableString(map['nivel_riesgo_residual']),

      // =========================================================
      // IMPLEMENTACIÓN
      // =========================================================
      responsableImplementacionId: _nullableString(
        map['responsable_implementacion_id'],
      ),

      fechaCompromiso: _nullableDate(map['fecha_compromiso']),

      fechaImplementacion: _nullableDate(map['fecha_implementacion']),

      estadoImplementacion: _nullableString(map['estado_implementacion']),

      observaciones: _nullableString(map['observaciones']),

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      sincronizado: _boolValue(map['sincronizado']),

      eliminado: _boolValue(map['eliminado']),

      fechaRegistro:
          _nullableDate(map['fecha_registro']) ?? DateTime.now().toUtc(),

      fechaActualizacion: _nullableDate(map['fecha_actualizacion']),

      fechaSincronizacion: _nullableDate(map['fecha_sincronizacion']),
    );
  }

  // =============================================================
  // COPY WITH
  // =============================================================

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

    // Evaluación inicial.
    int? evaluacionInicialId,
    int? probabilidadInicialId,
    int? severidadInicialId,

    int? severidadInicial,
    int? frecuenciaInicial,

    int? valorRiesgoInicial,
    String? nivelRiesgoInicial,

    // Controles.
    List<String>? controlIds,
    List<String>? equipoProteccionIds,
    String? controlDescripcion,

    // Evaluación residual.
    int? evaluacionResidualId,
    int? probabilidadResidualId,
    int? severidadResidualId,

    int? severidadResidual,
    int? frecuenciaResidual,

    int? valorRiesgoResidual,
    String? nivelRiesgoResidual,

    // Implementación.
    String? responsableImplementacionId,
    DateTime? fechaCompromiso,
    DateTime? fechaImplementacion,
    String? estadoImplementacion,

    String? observaciones,

    // Sincronización.
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

      // Evaluación inicial.
      evaluacionInicialId: evaluacionInicialId ?? this.evaluacionInicialId,

      probabilidadInicialId:
          probabilidadInicialId ?? this.probabilidadInicialId,

      severidadInicialId: severidadInicialId ?? this.severidadInicialId,

      severidadInicial: severidadInicial ?? this.severidadInicial,

      frecuenciaInicial: frecuenciaInicial ?? this.frecuenciaInicial,

      valorRiesgoInicial: valorRiesgoInicial ?? this.valorRiesgoInicial,

      nivelRiesgoInicial: nivelRiesgoInicial ?? this.nivelRiesgoInicial,

      // Controles.
      controlIds: controlIds ?? this.controlIds,

      equipoProteccionIds: equipoProteccionIds ?? this.equipoProteccionIds,

      controlDescripcion: controlDescripcion ?? this.controlDescripcion,

      // Evaluación residual.
      evaluacionResidualId: evaluacionResidualId ?? this.evaluacionResidualId,

      probabilidadResidualId:
          probabilidadResidualId ?? this.probabilidadResidualId,

      severidadResidualId: severidadResidualId ?? this.severidadResidualId,

      severidadResidual: severidadResidual ?? this.severidadResidual,

      frecuenciaResidual: frecuenciaResidual ?? this.frecuenciaResidual,

      valorRiesgoResidual: valorRiesgoResidual ?? this.valorRiesgoResidual,

      nivelRiesgoResidual: nivelRiesgoResidual ?? this.nivelRiesgoResidual,

      // Implementación.
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

  // =============================================================
  // MÉTODOS AUXILIARES
  // =============================================================

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
