/// Representa un peligro evaluado dentro de una matriz IPERC.
class DetalleIpercModel {
  const DetalleIpercModel({
    required this.id,
    required this.matrizIpercId,
    required this.item,
    required this.tarea,
    required this.peligroId,
    required this.consecuenciaId,
    required this.evaluacionInicialId,
    required this.estadoImplementacionId,
    required this.estadoImplementacionNombre,
    this.evaluacionInicial,
    this.controlIds = const <int>[],
    this.equipoProteccionIds = const <int>[],
    this.matrizIpercCodigo,
    this.peligroNombre,
    this.consecuenciaNombre,
    this.descripcionPeligro,
    this.evaluacionResidualId,
    this.evaluacionResidual,
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
  });

  final int id;
  final int matrizIpercId;
  final String? matrizIpercCodigo;
  final int item;
  final String tarea;
  final int peligroId;
  final String? peligroNombre;
  final int consecuenciaId;
  final String? consecuenciaNombre;
  final String? descripcionPeligro;
  final int evaluacionInicialId;
  final EvaluacionDetalleIpercModel? evaluacionInicial;
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
    final int estadoId = _toInt(
      json['estadoImplementacionId'] ?? json['estadoImplementacion'],
    );
    final EvaluacionDetalleIpercModel? evaluacionInicial =
        EvaluacionDetalleIpercModel.desdeValor(json['evaluacionInicial']);
    final EvaluacionDetalleIpercModel? evaluacionResidual =
        EvaluacionDetalleIpercModel.desdeValor(json['evaluacionResidual']);

    return DetalleIpercModel(
      id: _toInt(json['id']),
      matrizIpercId: _toInt(json['matrizIPERCId'] ?? json['matrizIpercId']),
      matrizIpercCodigo: _toNullableString(
        json['matrizIPERCCodigo'] ?? json['matrizIpercCodigo'],
      ),
      item: _toInt(json['item']),
      tarea: _toString(json['tarea']),
      peligroId: _toInt(json['peligroId']),
      peligroNombre: _toNullableString(json['peligroNombre']),
      consecuenciaId: _toInt(json['consecuenciaId']),
      consecuenciaNombre: _toNullableString(json['consecuenciaNombre']),
      descripcionPeligro: _toNullableString(json['descripcionPeligro']),
      evaluacionInicialId: _toInt(
        json['evaluacionInicialId'] ?? evaluacionInicial?.id,
      ),
      evaluacionInicial: evaluacionInicial,
      evaluacionResidualId: _toNullableInt(
        json['evaluacionResidualId'] ?? evaluacionResidual?.id,
      ),
      evaluacionResidual: evaluacionResidual,
      controlIds: _toIntList(
        json['controlIds'] ??
            json['controlesIds'] ??
            json['controles'] ??
            json['detalleIPERCControles'] ??
            json['detalleIpercControles'],
      ),
      equipoProteccionIds: _toIntList(
        json['equipoProteccionIds'] ??
            json['equiposProteccionIds'] ??
            json['eppIds'] ??
            json['equiposProteccion'] ??
            json['equiposDeProteccion'] ??
            json['detalleIPERCEPP'] ??
            json['detalleIpercEpp'],
      ),
      responsableImplementacionId: _toNullableInt(
        json['responsableImplementacionId'],
      ),
      fechaCompromiso: _toNullableDate(json['fechaCompromiso']),
      fechaImplementacion: _toNullableDate(json['fechaImplementacion']),
      estadoImplementacionId: estadoId,
      estadoImplementacionNombre:
          _toNullableString(json['estadoImplementacionNombre']) ??
          EstadoImplementacionIperc.obtenerNombre(estadoId),
    );
  }

  static List<DetalleIpercModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (Map elemento) =>
              DetalleIpercModel.fromJson(Map<String, dynamic>.from(elemento)),
        )
        .where((DetalleIpercModel detalle) => detalle.id > 0)
        .toList();
  }

  String get peligroVisible {
    return _textoVisible(peligroNombre, 'Peligro sin nombre');
  }

  String get consecuenciaVisible {
    return _textoVisible(consecuenciaNombre, 'Consecuencia sin nombre');
  }

  String get descripcionVisible {
    return _textoVisible(descripcionPeligro, 'Sin descripción específica');
  }

  bool get tieneEvaluacionResidual {
    return evaluacionResidual != null ||
        (evaluacionResidualId != null && evaluacionResidualId! > 0);
  }

  bool get tieneControles {
    return controlIds.isNotEmpty;
  }

  bool get tieneEquiposProteccion {
    return equipoProteccionIds.isNotEmpty;
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);
      final List<dynamic> posiblesListas = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['detalles'],
        mapa['detallesIPERC'],
        mapa['detallesIperc'],
      ];

      for (final dynamic valor in posiblesListas) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  static String _textoVisible(String? valor, String predeterminado) {
    final String texto = valor?.trim() ?? '';
    return texto.isEmpty ? predeterminado : texto;
  }
}

/// Información completa de una evaluación de riesgo asociada al detalle IPERC.
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
    final int valorProbabilidad = _toInt(
      json['valorProbabilidad'] ?? json['probabilidadValor'],
    );
    final int valorSeveridad = _toInt(
      json['valorSeveridad'] ?? json['severidadValor'],
    );
    final int valorRecibido = _toInt(json['valorRiesgo'] ?? json['valor']);

    return EvaluacionDetalleIpercModel(
      id: _toInt(json['id']),
      probabilidadId: _toInt(json['probabilidadId']),
      probabilidadNombre:
          _toNullableString(json['probabilidadNombre']) ?? 'Sin probabilidad',
      valorProbabilidad: valorProbabilidad,
      severidadId: _toInt(json['severidadId']),
      severidadNombre:
          _toNullableString(json['severidadNombre']) ?? 'Sin severidad',
      valorSeveridad: valorSeveridad,
      nivelRiesgoId: _toInt(json['nivelRiesgoId']),
      nivelRiesgoNombre:
          _toNullableString(json['nivelRiesgoNombre']) ?? 'Sin nivel',
      color: _normalizarColor(json['color']),
      valorRiesgo: valorRecibido > 0
          ? valorRecibido
          : valorProbabilidad * valorSeveridad,
      esAceptable: _toBool(json['esAceptable'] ?? json['aceptable']),
      requiereAccion: _toBool(json['requiereAccion']),
      observaciones: _toNullableString(json['observaciones']),
    );
  }

  static EvaluacionDetalleIpercModel? desdeValor(dynamic valor) {
    if (valor is! Map) {
      return null;
    }

    return EvaluacionDetalleIpercModel.fromJson(
      Map<String, dynamic>.from(valor),
    );
  }

  String get calculo {
    return '$valorProbabilidad × $valorSeveridad = $valorRiesgo';
  }
}

/// Solicitud para registrar un detalle IPERC.
class CrearDetalleIpercRequest {
  const CrearDetalleIpercRequest({
    required this.matrizIpercId,
    required this.tarea,
    required this.peligroId,
    required this.consecuenciaId,
    required this.evaluacionInicialId,
    this.item = 0,
    this.descripcionPeligro,
    this.evaluacionResidualId,
    this.controlIds = const <int>[],
    this.equipoProteccionIds = const <int>[],
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion = EstadoImplementacionIperc.pendiente,
  });

  final int matrizIpercId;
  final int item;
  final String tarea;
  final int peligroId;
  final int consecuenciaId;
  final String? descripcionPeligro;
  final int evaluacionInicialId;
  final int? evaluacionResidualId;
  final List<int> controlIds;
  final List<int> equipoProteccionIds;
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
      'descripcionPeligro': _nullableText(descripcionPeligro),
      'evaluacionInicialId': evaluacionInicialId,
      'evaluacionResidualId': evaluacionResidualId,
      'controlIds': controlIds,
      'equipoProteccionIds': equipoProteccionIds,
      'responsableImplementacionId': responsableImplementacionId,
      'fechaCompromiso': fechaCompromiso?.toIso8601String(),
      'fechaImplementacion': fechaImplementacion?.toIso8601String(),
      'estadoImplementacion': estadoImplementacion,
    };
  }
}

/// Solicitud para actualizar un detalle IPERC.
class ActualizarDetalleIpercRequest {
  const ActualizarDetalleIpercRequest({
    required this.matrizIpercId,
    required this.item,
    required this.tarea,
    required this.peligroId,
    required this.consecuenciaId,
    required this.evaluacionInicialId,
    this.descripcionPeligro,
    this.evaluacionResidualId,
    this.controlIds = const <int>[],
    this.equipoProteccionIds = const <int>[],
    this.responsableImplementacionId,
    this.fechaCompromiso,
    this.fechaImplementacion,
    this.estadoImplementacion = EstadoImplementacionIperc.pendiente,
  });

  final int matrizIpercId;
  final int item;
  final String tarea;
  final int peligroId;
  final int consecuenciaId;
  final String? descripcionPeligro;
  final int evaluacionInicialId;
  final int? evaluacionResidualId;
  final List<int> controlIds;
  final List<int> equipoProteccionIds;
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
      'descripcionPeligro': _nullableText(descripcionPeligro),
      'evaluacionInicialId': evaluacionInicialId,
      'evaluacionResidualId': evaluacionResidualId,
      'controlIds': controlIds,
      'equipoProteccionIds': equipoProteccionIds,
      'responsableImplementacionId': responsableImplementacionId,
      'fechaCompromiso': fechaCompromiso?.toIso8601String(),
      'fechaImplementacion': fechaImplementacion?.toIso8601String(),
      'estadoImplementacion': estadoImplementacion,
    };
  }
}

/// Estados admitidos por el backend.
abstract final class EstadoImplementacionIperc {
  static const int pendiente = 0;
  static const int enProceso = 1;
  static const int implementado = 2;
  static const int verificado = 3;
  static const int cerrado = 4;

  static const List<int> valores = <int>[
    pendiente,
    enProceso,
    implementado,
    verificado,
    cerrado,
  ];

  static String obtenerNombre(int valor) {
    return switch (valor) {
      enProceso => 'En proceso',
      implementado => 'Implementado',
      verificado => 'Verificado',
      cerrado => 'Cerrado',
      _ => 'Pendiente',
    };
  }
}

int _toInt(dynamic valor) {
  if (valor is int) {
    return valor;
  }

  if (valor is num) {
    return valor.toInt();
  }

  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic valor) {
  if (valor == null) {
    return null;
  }

  return int.tryParse(valor.toString());
}

List<int> _toIntList(dynamic valor) {
  if (valor is! List) {
    return <int>[];
  }

  final Set<int> ids = <int>{};

  for (final dynamic item in valor) {
    if (item is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(item);
      final int id = _toInt(
        mapa['id'] ??
            mapa['controlId'] ??
            mapa['equipoProteccionId'] ??
            mapa['equipoProteccionPersonalId'] ??
            mapa['eppId'],
      );

      if (id > 0) {
        ids.add(id);
      }

      continue;
    }

    final int id = _toInt(item);

    if (id > 0) {
      ids.add(id);
    }
  }

  return List<int>.unmodifiable(ids);
}

String _toString(dynamic valor) {
  return valor?.toString().trim() ?? '';
}

String? _toNullableString(dynamic valor) {
  final String texto = valor?.toString().trim() ?? '';
  return texto.isEmpty ? null : texto;
}

DateTime? _toNullableDate(dynamic valor) {
  return DateTime.tryParse(valor?.toString() ?? '');
}

String? _nullableText(String? valor) {
  final String texto = valor?.trim() ?? '';
  return texto.isEmpty ? null : texto;
}

bool _toBool(dynamic valor) {
  if (valor is bool) {
    return valor;
  }

  if (valor is num) {
    return valor != 0;
  }

  final String texto = valor?.toString().trim().toLowerCase() ?? '';
  return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
}

String _normalizarColor(dynamic valor) {
  final String color = _toNullableString(valor) ?? '#9E9E9E';
  return color.startsWith('#') ? color : '#$color';
}
