class ConsecuenciaModel {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? clasificacion;
  final bool incapacidadPermanente;
  final bool fatalidad;
  final bool activo;
  final bool estado;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  const ConsecuenciaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.clasificacion,
    required this.incapacidadPermanente,
    required this.fatalidad,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory ConsecuenciaModel.fromJson(Map<String, dynamic> json) {
    return ConsecuenciaModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      clasificacion: _convertirTextoNullable(json['clasificacion']),
      incapacidadPermanente: _convertirBooleano(
        json['incapacidadPermanente'],
        valorPredeterminado: false,
      ),
      fatalidad: _convertirBooleano(
        json['fatalidad'],
        valorPredeterminado: false,
      ),
      activo: _convertirBooleano(json['activo'], valorPredeterminado: true),
      estado: _convertirBooleano(json['estado'], valorPredeterminado: true),
      fechaRegistro: _convertirFechaNullable(
        json['fechaRegistro'] ?? json['createdAt'],
      ),
      fechaActualizacion: _convertirFechaNullable(
        json['fechaActualizacion'] ?? json['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'clasificacion': clasificacion,
      'incapacidadPermanente': incapacidadPermanente,
      'fatalidad': fatalidad,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  ConsecuenciaModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    String? clasificacion,
    bool limpiarClasificacion = false,
    bool? incapacidadPermanente,
    bool? fatalidad,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return ConsecuenciaModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      clasificacion: limpiarClasificacion
          ? null
          : clasificacion ?? this.clasificacion,
      incapacidadPermanente:
          incapacidadPermanente ?? this.incapacidadPermanente,
      fatalidad: fatalidad ?? this.fatalidad,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  bool get estaDisponible {
    return activo && estado;
  }

  String get nombreCompleto {
    final String codigoLimpio = codigo.trim();
    final String nombreLimpio = nombre.trim();

    if (codigoLimpio.isEmpty) {
      return nombreLimpio;
    }

    if (nombreLimpio.isEmpty) {
      return codigoLimpio;
    }

    return '$codigoLimpio - $nombreLimpio';
  }

  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    return texto.isEmpty ? 'Sin descripción' : texto;
  }

  String get clasificacionVisible {
    final String texto = clasificacion?.trim() ?? '';

    return texto.isEmpty ? 'Sin clasificación' : texto;
  }

  String get gravedadVisible {
    if (fatalidad) {
      return 'Puede ocasionar fatalidad';
    }

    if (incapacidadPermanente) {
      return 'Puede ocasionar incapacidad permanente';
    }

    return 'Sin condición grave registrada';
  }

  static List<ConsecuenciaModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (dynamic elemento) => ConsecuenciaModel.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          ),
        )
        .where((ConsecuenciaModel consecuencia) => consecuencia.id > 0)
        .toList();
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final List<dynamic> posiblesValores = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['consecuencias'],
      ];

      for (final dynamic valor in posiblesValores) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  static int _convertirEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static String _convertirTexto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  static String? _convertirTextoNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final String texto = valor.toString().trim();

    return texto.isEmpty ? null : texto;
  }

  static bool _convertirBooleano(
    dynamic valor, {
    required bool valorPredeterminado,
  }) {
    if (valor == null) {
      return valorPredeterminado;
    }

    if (valor is bool) {
      return valor;
    }

    if (valor is num) {
      return valor != 0;
    }

    final String texto = valor.toString().trim().toLowerCase();

    if (texto == 'true' ||
        texto == '1' ||
        texto == 'si' ||
        texto == 'sí' ||
        texto == 'activo') {
      return true;
    }

    if (texto == 'false' ||
        texto == '0' ||
        texto == 'no' ||
        texto == 'inactivo') {
      return false;
    }

    return valorPredeterminado;
  }

  static DateTime? _convertirFechaNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.tryParse(valor.toString());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConsecuenciaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConsecuenciaModel('
        'id: $id, '
        'codigo: $codigo, '
        'nombre: $nombre, '
        'activo: $activo, '
        'estado: $estado'
        ')';
  }
}

class CrearConsecuenciaRequest {
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? clasificacion;
  final bool incapacidadPermanente;
  final bool fatalidad;
  final bool activo;
  final int usuarioRegistroId;

  const CrearConsecuenciaRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.clasificacion,
    this.incapacidadPermanente = false,
    this.fatalidad = false,
    this.activo = true,
    required this.usuarioRegistroId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'clasificacion': _normalizarTexto(clasificacion),
      'incapacidadPermanente': incapacidadPermanente,
      'fatalidad': fatalidad,
      'activo': activo,
      'usuarioRegistroId': usuarioRegistroId,
    };
  }
}

class ActualizarConsecuenciaRequest {
  final String nombre;
  final String? descripcion;
  final String? clasificacion;
  final bool incapacidadPermanente;
  final bool fatalidad;
  final bool activo;
  final int usuarioActualizacionId;

  const ActualizarConsecuenciaRequest({
    required this.nombre,
    this.descripcion,
    this.clasificacion,
    required this.incapacidadPermanente,
    required this.fatalidad,
    required this.activo,
    required this.usuarioActualizacionId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'clasificacion': _normalizarTexto(clasificacion),
      'incapacidadPermanente': incapacidadPermanente,
      'fatalidad': fatalidad,
      'activo': activo,
      'usuarioActualizacionId': usuarioActualizacionId,
    };
  }
}

String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
