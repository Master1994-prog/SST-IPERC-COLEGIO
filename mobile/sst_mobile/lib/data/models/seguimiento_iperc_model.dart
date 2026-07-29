/// Representa un seguimiento realizado a un detalle de la matriz IPERC.
class SeguimientoIpercModel {
  const SeguimientoIpercModel({
    required this.id,
    required this.detalleIpercId,
    required this.fechaSeguimiento,
    required this.usuarioId,
    required this.descripcion,
    required this.porcentajeAvance,
    required this.verificado,
    this.detalleItem,
    this.detalleTarea,
    this.usuarioNombre,
    this.fechaVerificacion,
    this.observaciones,
    this.archivo,
    this.nombreArchivo,
    this.tipoArchivo,
  });

  final int id;
  final int detalleIpercId;
  final int? detalleItem;
  final String? detalleTarea;
  final DateTime fechaSeguimiento;
  final int usuarioId;
  final String? usuarioNombre;
  final String descripcion;
  final double porcentajeAvance;
  final bool verificado;
  final DateTime? fechaVerificacion;
  final String? observaciones;
  final String? archivo;
  final String? nombreArchivo;
  final String? tipoArchivo;

  factory SeguimientoIpercModel.fromJson(Map<String, dynamic> json) {
    return SeguimientoIpercModel(
      id: _toInt(json['id']),
      detalleIpercId: _toInt(
        json['detalleIPERCId'] ?? json['detalleIpercId'],
      ),
      detalleItem: _toNullableInt(json['detalleItem']),
      detalleTarea: _toNullableString(json['detalleTarea']),
      fechaSeguimiento:
          _toNullableDate(json['fechaSeguimiento']) ?? DateTime.now(),
      usuarioId: _toInt(json['usuarioId']),
      usuarioNombre: _toNullableString(json['usuarioNombre']),
      descripcion: _toString(json['descripcion']),
      porcentajeAvance: _toDouble(json['porcentajeAvance']),
      verificado: _toBool(json['verificado']),
      fechaVerificacion: _toNullableDate(json['fechaVerificacion']),
      observaciones: _toNullableString(json['observaciones']),
      archivo: _toNullableString(json['archivo']),
      nombreArchivo: _toNullableString(json['nombreArchivo']),
      tipoArchivo: _toNullableString(json['tipoArchivo']),
    );
  }

  static List<SeguimientoIpercModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (Map item) => SeguimientoIpercModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((SeguimientoIpercModel seguimiento) => seguimiento.id > 0)
        .toList();
  }

  String get detalleVisible {
    final String tarea = detalleTarea?.trim() ?? '';
    final String item = detalleItem == null ? '' : 'Item $detalleItem';

    if (item.isNotEmpty && tarea.isNotEmpty) {
      return '$item - $tarea';
    }

    if (tarea.isNotEmpty) {
      return tarea;
    }

    return 'Detalle IPERC $detalleIpercId';
  }

  String get estadoVisible {
    return verificado ? 'Verificado' : 'Pendiente';
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);
      final List<dynamic> posibles = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['seguimientos'],
        mapa['seguimientosIPERC'],
        mapa['seguimientosIperc'],
      ];

      for (final dynamic valor in posibles) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }
}

/// Solicitud para registrar un seguimiento IPERC.
class CrearSeguimientoIpercRequest {
  const CrearSeguimientoIpercRequest({
    required this.detalleIpercId,
    required this.fechaSeguimiento,
    required this.usuarioId,
    required this.descripcion,
    required this.porcentajeAvance,
    this.verificado = false,
    this.fechaVerificacion,
    this.observaciones,
    this.archivo,
    this.nombreArchivo,
    this.tipoArchivo,
  });

  final int detalleIpercId;
  final DateTime fechaSeguimiento;
  final int usuarioId;
  final String descripcion;
  final double porcentajeAvance;
  final bool verificado;
  final DateTime? fechaVerificacion;
  final String? observaciones;
  final String? archivo;
  final String? nombreArchivo;
  final String? tipoArchivo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'detalleIPERCId': detalleIpercId,
      'fechaSeguimiento': fechaSeguimiento.toIso8601String(),
      'usuarioId': usuarioId,
      'descripcion': descripcion.trim(),
      'porcentajeAvance': porcentajeAvance,
      'verificado': verificado,
      'fechaVerificacion': fechaVerificacion?.toIso8601String(),
      'observaciones': _nullableText(observaciones),
      'archivo': _nullableText(archivo),
      'nombreArchivo': _nullableText(nombreArchivo),
      'tipoArchivo': _nullableText(tipoArchivo),
    };
  }
}

/// Solicitud para actualizar un seguimiento IPERC.
class ActualizarSeguimientoIpercRequest {
  const ActualizarSeguimientoIpercRequest({
    required this.detalleIpercId,
    required this.fechaSeguimiento,
    required this.usuarioId,
    required this.descripcion,
    required this.porcentajeAvance,
    required this.verificado,
    this.fechaVerificacion,
    this.observaciones,
    this.archivo,
    this.nombreArchivo,
    this.tipoArchivo,
  });

  final int detalleIpercId;
  final DateTime fechaSeguimiento;
  final int usuarioId;
  final String descripcion;
  final double porcentajeAvance;
  final bool verificado;
  final DateTime? fechaVerificacion;
  final String? observaciones;
  final String? archivo;
  final String? nombreArchivo;
  final String? tipoArchivo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'detalleIPERCId': detalleIpercId,
      'fechaSeguimiento': fechaSeguimiento.toIso8601String(),
      'usuarioId': usuarioId,
      'descripcion': descripcion.trim(),
      'porcentajeAvance': porcentajeAvance,
      'verificado': verificado,
      'fechaVerificacion': fechaVerificacion?.toIso8601String(),
      'observaciones': _nullableText(observaciones),
      'archivo': _nullableText(archivo),
      'nombreArchivo': _nullableText(nombreArchivo),
      'tipoArchivo': _nullableText(tipoArchivo),
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

double _toDouble(dynamic valor) {
  if (valor is num) {
    return valor.toDouble();
  }

  return double.tryParse(valor?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic valor) {
  if (valor is bool) {
    return valor;
  }

  final String texto = valor?.toString().toLowerCase().trim() ?? '';
  return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
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
