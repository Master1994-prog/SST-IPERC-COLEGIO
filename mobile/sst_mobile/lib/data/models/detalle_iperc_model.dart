class EvaluacionDetalleIpercModel {
  const EvaluacionDetalleIpercModel({
    required this.id,
    required this.probabilidadId,
    required this.probabilidadNombre,
    required this.valorProbabilidad,
    required this.severidadId,
    required this.severidadNombre,
    required this.valorSeveridad,
    required this.nivelRiesgoId,
    required this.nivelRiesgoNombre,
    required this.color,
    required this.valorRiesgo,
    required this.esAceptable,
    required this.requiereAccion,
    this.observaciones,
  });

  final int id;

  final int probabilidadId;
  final String probabilidadNombre;
  final int valorProbabilidad;

  final int severidadId;
  final String severidadNombre;
  final int valorSeveridad;

  final int nivelRiesgoId;
  final String nivelRiesgoNombre;

  final String color;

  final int valorRiesgo;

  final bool esAceptable;
  final bool requiereAccion;

  final String? observaciones;

  factory EvaluacionDetalleIpercModel.fromJson(Map<String, dynamic> json) {
    return EvaluacionDetalleIpercModel(
      id: _toInt(json['id'] ?? json['Id']),
      probabilidadId: _toInt(json['probabilidadId'] ?? json['ProbabilidadId']),
      probabilidadNombre: _toString(
        json['probabilidadNombre'] ?? json['ProbabilidadNombre'],
      ),
      valorProbabilidad: _toInt(
        json['valorProbabilidad'] ?? json['ValorProbabilidad'],
      ),
      severidadId: _toInt(json['severidadId'] ?? json['SeveridadId']),
      severidadNombre: _toString(
        json['severidadNombre'] ?? json['SeveridadNombre'],
      ),
      valorSeveridad: _toInt(json['valorSeveridad'] ?? json['ValorSeveridad']),
      nivelRiesgoId: _toInt(json['nivelRiesgoId'] ?? json['NivelRiesgoId']),
      nivelRiesgoNombre: _toString(
        json['nivelRiesgoNombre'] ?? json['NivelRiesgoNombre'],
      ),
      color: _toString(json['color'] ?? json['Color']),
      valorRiesgo: _toInt(json['valorRiesgo'] ?? json['ValorRiesgo']),
      esAceptable: _toBool(json['esAceptable'] ?? json['EsAceptable']),
      requiereAccion: _toBool(json['requiereAccion'] ?? json['RequiereAccion']),
      observaciones: _toNullableString(
        json['observaciones'] ?? json['Observaciones'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _toNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().toLowerCase().trim() ?? '';

    return text == 'true' || text == '1' || text == 'si' || text == 'sí';
  }
  // =============================================================
  // COMPATIBILIDAD CON PANTALLAS EXISTENTES
  // =============================================================

  /// Devuelve el cálculo de riesgo en formato visible.
  ///
  /// Ejemplo:
  /// 4 x 5 = 20
  String get calculo {
    return '$valorProbabilidad x $valorSeveridad = $valorRiesgo';
  }
}

class DetalleIpercModel {
  const DetalleIpercModel({
    required this.id,
    required this.matrizIpercId,
    required this.matrizIpercCodigo,
    required this.item,
    required this.tarea,
    required this.peligroId,
    required this.peligroNombre,
    required this.consecuenciaId,
    required this.consecuenciaNombre,
    required this.evaluacionInicialId,
    required this.evaluacionInicial,
    required this.controlIds,
    required this.equipoProteccionIds,
    required this.estadoImplementacionId,
    required this.estadoImplementacionNombre,
    this.descripcionPeligro,
    this.evaluacionResidualId,
    this.evaluacionResidual,
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
  });

  final int id;

  final int matrizIpercId;
  final String matrizIpercCodigo;

  final int item;
  final String tarea;

  final int peligroId;
  final String peligroNombre;

  final int consecuenciaId;
  final String consecuenciaNombre;

  final String? descripcionPeligro;

  final int evaluacionInicialId;
  final EvaluacionDetalleIpercModel evaluacionInicial;

  final int? evaluacionResidualId;
  final EvaluacionDetalleIpercModel? evaluacionResidual;

  final List<int> controlIds;
  final List<int> equipoProteccionIds;

  final int? responsableImplementacionId;

  final DateTime? fechaCompromiso;
  final DateTime? fechaImplementacion;

  final int estadoImplementacionId;
  final String estadoImplementacionNombre;

  factory DetalleIpercModel.fromJson(Map<String, dynamic> json) {
    final dynamic evaluacionInicialJson =
        json['evaluacionInicial'] ?? json['EvaluacionInicial'];

    final dynamic evaluacionResidualJson =
        json['evaluacionResidual'] ?? json['EvaluacionResidual'];

    return DetalleIpercModel(
      id: _toInt(json['id'] ?? json['Id']),
      matrizIpercId: _toInt(
        json['matrizIPERCId'] ?? json['matrizIpercId'] ?? json['MatrizIPERCId'],
      ),
      matrizIpercCodigo: _toString(
        json['matrizIPERCCodigo'] ??
            json['matrizIpercCodigo'] ??
            json['MatrizIPERCCodigo'],
      ),
      item: _toInt(json['item'] ?? json['Item']),
      tarea: _toString(json['tarea'] ?? json['Tarea']),
      peligroId: _toInt(json['peligroId'] ?? json['PeligroId']),
      peligroNombre: _toString(json['peligroNombre'] ?? json['PeligroNombre']),
      consecuenciaId: _toInt(json['consecuenciaId'] ?? json['ConsecuenciaId']),
      consecuenciaNombre: _toString(
        json['consecuenciaNombre'] ?? json['ConsecuenciaNombre'],
      ),
      descripcionPeligro: _toNullableString(
        json['descripcionPeligro'] ?? json['DescripcionPeligro'],
      ),
      evaluacionInicialId: _toInt(
        json['evaluacionInicialId'] ?? json['EvaluacionInicialId'],
      ),
      evaluacionInicial: evaluacionInicialJson is Map
          ? EvaluacionDetalleIpercModel.fromJson(
              Map<String, dynamic>.from(evaluacionInicialJson),
            )
          : const EvaluacionDetalleIpercModel(
              id: 0,
              probabilidadId: 0,
              probabilidadNombre: '',
              valorProbabilidad: 0,
              severidadId: 0,
              severidadNombre: '',
              valorSeveridad: 0,
              nivelRiesgoId: 0,
              nivelRiesgoNombre: '',
              color: '',
              valorRiesgo: 0,
              esAceptable: false,
              requiereAccion: false,
            ),
      evaluacionResidualId: _toNullableInt(
        json['evaluacionResidualId'] ?? json['EvaluacionResidualId'],
      ),
      evaluacionResidual: evaluacionResidualJson is Map
          ? EvaluacionDetalleIpercModel.fromJson(
              Map<String, dynamic>.from(evaluacionResidualJson),
            )
          : null,
      controlIds: _toIntList(json['controlIds'] ?? json['ControlIds']),
      equipoProteccionIds: _toIntList(
        json['equipoProteccionIds'] ?? json['EquipoProteccionIds'],
      ),
      responsableImplementacionId: _toNullableInt(
        json['responsableImplementacionId'] ??
            json['ResponsableImplementacionId'],
      ),
      fechaCompromiso: _toDateTime(
        json['fechaCompromiso'] ?? json['FechaCompromiso'],
      ),
      fechaImplementacion: _toDateTime(
        json['fechaImplementacion'] ?? json['FechaImplementacion'],
      ),
      estadoImplementacionId: _toInt(
        json['estadoImplementacionId'] ?? json['EstadoImplementacionId'],
      ),
      estadoImplementacionNombre: _toString(
        json['estadoImplementacionNombre'] ??
            json['EstadoImplementacionNombre'],
      ),
    );
  }

  static List<DetalleIpercModel> listaDesdeJson(dynamic data) {
    final List<dynamic> items = _extraerLista(data);

    return items
        .whereType<Map>()
        .map(
          (Map item) =>
              DetalleIpercModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(data);

    final dynamic contenido =
        map['data'] ?? map['result'] ?? map['value'] ?? map['detalle'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return map;
  }

  bool get tieneEvaluacionResidual => evaluacionResidual != null;

  bool get estaCerrado => estadoImplementacionId == 4;

  bool get requiereAccion =>
      evaluacionResidual?.requiereAccion ?? evaluacionInicial.requiereAccion;

  int get valorRiesgoActual =>
      evaluacionResidual?.valorRiesgo ?? evaluacionInicial.valorRiesgo;

  String get nivelRiesgoActual =>
      evaluacionResidual?.nivelRiesgoNombre ??
      evaluacionInicial.nivelRiesgoNombre;

  String get colorRiesgoActual =>
      evaluacionResidual?.color ?? evaluacionInicial.color;
  // =============================================================
  // GETTERS DE COMPATIBILIDAD
  // =============================================================

  /// Nombre visible del peligro.
  String get peligroVisible {
    if (peligroNombre.trim().isNotEmpty) {
      return peligroNombre.trim();
    }

    return 'Peligro no especificado';
  }

  /// Nombre visible de la consecuencia.
  String get consecuenciaVisible {
    if (consecuenciaNombre.trim().isNotEmpty) {
      return consecuenciaNombre.trim();
    }

    return 'Consecuencia no especificada';
  }

  /// Descripción que utilizan las pantallas y reportes antiguos.
  String get descripcionVisible {
    final String descripcion = descripcionPeligro?.trim() ?? '';

    if (descripcion.isNotEmpty) {
      return descripcion;
    }

    return peligroVisible;
  }

  /// Indica si tiene controles asociados.
  bool get tieneControles {
    return controlIds.isNotEmpty;
  }

  /// Indica si tiene EPP asociados.
  bool get tieneEquiposProteccion {
    return equipoProteccionIds.isNotEmpty;
  }

  /// Alias utilizado por código anterior.
  String get nivelRiesgoVisible {
    if (nivelRiesgoActual.trim().isNotEmpty) {
      return nivelRiesgoActual.trim();
    }

    return 'Sin nivel de riesgo';
  }

  /// Alias de estado.
  bool get cerrado {
    return estadoImplementacionId == 4;
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);

      final List<dynamic> opciones = <dynamic>[
        map['data'],
        map['items'],
        map['result'],
        map['results'],
        map['value'],
        map['detalles'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
        }
      }
    }

    return <dynamic>[];
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
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

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _toNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static List<int> _toIntList(dynamic value) {
    if (value is! List) {
      return <int>[];
    }

    return value.map(_toInt).where((int id) => id > 0).toList();
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}

// ===============================================================
// ESTADO DE IMPLEMENTACIÓN IPERC
// ===============================================================

/// Estados de implementación utilizados por Detalle IPERC.
///
/// Se mantienen como valores enteros porque las pantallas,
/// providers, sincronización y backend ya trabajan con int.
///
/// Backend:
///
/// 0 = Pendiente
/// 1 = EnProceso
/// 2 = Implementado
/// 3 = Verificado
/// 4 = Cerrado
class EstadoImplementacionIperc {
  EstadoImplementacionIperc._();

  /// Medidas todavía no iniciadas.
  static const int pendiente = 0;

  /// Medidas actualmente en ejecución.
  static const int enProceso = 1;

  /// Medidas ya implementadas.
  static const int implementado = 2;

  /// Medidas implementadas y verificadas.
  static const int verificado = 3;

  /// Registro cerrado.
  static const int cerrado = 4;

  /// Lista utilizada por DropdownButton y formularios.
  static const List<int> valores = <int>[
    pendiente,
    enProceso,
    implementado,
    verificado,
    cerrado,
  ];

  /// Devuelve el nombre visible correspondiente al estado.
  static String obtenerNombre(int estado) {
    switch (estado) {
      case pendiente:
        return 'Pendiente';

      case enProceso:
        return 'En proceso';

      case implementado:
        return 'Implementado';

      case verificado:
        return 'Verificado';

      case cerrado:
        return 'Cerrado';

      default:
        return 'Desconocido';
    }
  }

  /// Comprueba si un valor corresponde a un estado válido.
  static bool esValido(int estado) {
    return valores.contains(estado);
  }
}

// ===============================================================
// REQUEST - CREAR DETALLE IPERC
// ===============================================================

/// Objeto utilizado por providers, pantallas y sincronización
/// para crear un nuevo detalle.
///
/// Conservamos esta clase porque ya era utilizada por
/// varias partes del proyecto.
///
/// Internamente ahora trabaja con:
///
/// - ProbabilidadInicialId
/// - SeveridadInicialId
/// - ProbabilidadResidualId
/// - SeveridadResidualId
///
/// en lugar de exigir EvaluacionInicialId.
class CrearDetalleIpercRequest {
  const CrearDetalleIpercRequest({
    required this.matrizIpercId,
    this.item = 0,
    required this.tarea,
    required this.peligroId,
    required this.consecuenciaId,
    this.descripcionPeligro,
    required this.probabilidadInicialId,
    required this.severidadInicialId,
    this.observacionesEvaluacionInicial,
    this.probabilidadResidualId,
    this.severidadResidualId,
    this.observacionesEvaluacionResidual,
    this.controlIds = const <int>[],
    this.equipoProteccionIds = const <int>[],
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion = 0,
  });

  final int matrizIpercId;
  final int item;

  final String tarea;

  final int peligroId;
  final int consecuenciaId;

  final String? descripcionPeligro;

  // Evaluación inicial.
  final int probabilidadInicialId;
  final int severidadInicialId;

  final String? observacionesEvaluacionInicial;

  // Evaluación residual.
  final int? probabilidadResidualId;
  final int? severidadResidualId;

  final String? observacionesEvaluacionResidual;

  // Controles y EPP.
  final List<int> controlIds;
  final List<int> equipoProteccionIds;

  // Implementación.
  final int? responsableImplementacionId;

  final DateTime? fechaCompromiso;
  final DateTime? fechaImplementacion;

  final int estadoImplementacion;

  /// JSON compatible con CreateDetalleIPERCDto
  /// del backend.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'matrizIPERCId': matrizIpercId,
      'item': item,
      'tarea': tarea.trim(),
      'peligroId': peligroId,
      'consecuenciaId': consecuenciaId,
      'descripcionPeligro': _textoNullable(descripcionPeligro),
      'probabilidadInicialId': probabilidadInicialId,
      'severidadInicialId': severidadInicialId,
      'observacionesEvaluacionInicial': _textoNullable(
        observacionesEvaluacionInicial,
      ),
      'probabilidadResidualId': probabilidadResidualId,
      'severidadResidualId': severidadResidualId,
      'observacionesEvaluacionResidual': _textoNullable(
        observacionesEvaluacionResidual,
      ),
      'controlIds': controlIds,
      'equipoProteccionIds': equipoProteccionIds,
      'responsableImplementacionId': responsableImplementacionId,
      'fechaCompromiso': fechaCompromiso?.toIso8601String(),
      'fechaImplementacion': fechaImplementacion?.toIso8601String(),
      'estadoImplementacion': estadoImplementacion,
    };
  }
}

// ===============================================================
// REQUEST - ACTUALIZAR DETALLE IPERC
// ===============================================================

/// Objeto utilizado para actualizar un detalle existente.
///
/// Mantiene compatibilidad con:
///
/// - DetalleIpercProvider
/// - DetalleIpercSyncService
/// - EditarDetalleIpercScreen
class ActualizarDetalleIpercRequest {
  const ActualizarDetalleIpercRequest({
    required this.id,
    required this.matrizIpercId,
    required this.item,
    required this.tarea,
    required this.peligroId,
    required this.consecuenciaId,
    this.descripcionPeligro,
    required this.probabilidadInicialId,
    required this.severidadInicialId,
    this.observacionesEvaluacionInicial,
    this.probabilidadResidualId,
    this.severidadResidualId,
    this.observacionesEvaluacionResidual,
    this.controlIds = const <int>[],
    this.equipoProteccionIds = const <int>[],
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion = 0,
  });

  final int id;

  final int matrizIpercId;
  final int item;

  final String tarea;

  final int peligroId;
  final int consecuenciaId;

  final String? descripcionPeligro;

  // Evaluación inicial.
  final int probabilidadInicialId;
  final int severidadInicialId;

  final String? observacionesEvaluacionInicial;

  // Evaluación residual.
  final int? probabilidadResidualId;
  final int? severidadResidualId;

  final String? observacionesEvaluacionResidual;

  // Controles y EPP.
  final List<int> controlIds;
  final List<int> equipoProteccionIds;

  // Implementación.
  final int? responsableImplementacionId;

  final DateTime? fechaCompromiso;
  final DateTime? fechaImplementacion;

  final int estadoImplementacion;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'matrizIPERCId': matrizIpercId,
      'item': item,
      'tarea': tarea.trim(),
      'peligroId': peligroId,
      'consecuenciaId': consecuenciaId,
      'descripcionPeligro': _textoNullable(descripcionPeligro),
      'probabilidadInicialId': probabilidadInicialId,
      'severidadInicialId': severidadInicialId,
      'observacionesEvaluacionInicial': _textoNullable(
        observacionesEvaluacionInicial,
      ),
      'probabilidadResidualId': probabilidadResidualId,
      'severidadResidualId': severidadResidualId,
      'observacionesEvaluacionResidual': _textoNullable(
        observacionesEvaluacionResidual,
      ),
      'controlIds': controlIds,
      'equipoProteccionIds': equipoProteccionIds,
      'responsableImplementacionId': responsableImplementacionId,
      'fechaCompromiso': fechaCompromiso?.toIso8601String(),
      'fechaImplementacion': fechaImplementacion?.toIso8601String(),
      'estadoImplementacion': estadoImplementacion,
    };
  }
}

// ===============================================================
// ALIASES DE COMPATIBILIDAD
// ===============================================================

/// El proyecto antiguo utiliza en algunos lugares
/// el nombre inglés CreateDetalleIpercRequest.
///
/// Creamos este alias sin duplicar lógica.
typedef CreateDetalleIpercRequest = CrearDetalleIpercRequest;

/// Lo mismo para actualización.
typedef UpdateDetalleIpercRequest = ActualizarDetalleIpercRequest;

// ===============================================================
// UTILIDAD
// ===============================================================

String? _textoNullable(String? texto) {
  final String resultado = texto?.trim() ?? '';

  return resultado.isEmpty ? null : resultado;
}
