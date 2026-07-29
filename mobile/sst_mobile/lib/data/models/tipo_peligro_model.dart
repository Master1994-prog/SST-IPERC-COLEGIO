/// Modelo que representa un tipo de peligro del sistema SST.
///
/// Ejemplos:
///
/// - Físico.
/// - Químico.
/// - Biológico.
/// - Ergonómico.
/// - Psicosocial.
/// - Mecánico.
/// - Eléctrico.
class TipoPeligroModel {
  /// Identificador único.
  final int id;

  /// Código del tipo de peligro.
  ///
  /// Ejemplo:
  ///
  /// `TIP-001`
  final String codigo;

  /// Nombre del tipo de peligro.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Indica si el tipo de peligro está activo.
  final bool activo;

  /// Estado lógico heredado del registro.
  final bool estado;

  /// Fecha de registro.
  final DateTime? fechaRegistro;

  /// Fecha de actualización.
  final DateTime? fechaActualizacion;

  const TipoPeligroModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Convierte una respuesta JSON del backend
  /// en una instancia de [TipoPeligroModel].
  factory TipoPeligroModel.fromJson(Map<String, dynamic> json) {
    return TipoPeligroModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
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

  /// Convierte el modelo en JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia modificando solamente
  /// los valores proporcionados.
  TipoPeligroModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return TipoPeligroModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si el registro puede utilizarse
  /// en formularios de peligros.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Devuelve código y nombre.
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

  /// Devuelve una descripción preparada
  /// para mostrar en la interfaz.
  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin descripción';
    }

    return texto;
  }

  /// Convierte una respuesta que contiene
  /// una lista de tipos de peligro.
  static List<TipoPeligroModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map((dynamic elemento) {
          return TipoPeligroModel.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          );
        })
        .where((TipoPeligroModel tipo) => tipo.id > 0)
        .toList();
  }

  /// Extrae una lista desde distintos formatos
  /// de respuesta del backend.
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
        mapa['tiposPeligro'],
      ];

      for (final dynamic valor in posiblesValores) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  /// Convierte un valor dinámico en entero.
  static int _convertirEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  /// Convierte un valor dinámico en texto.
  static String _convertirTexto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  /// Convierte un valor dinámico en texto nullable.
  static String? _convertirTextoNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final String texto = valor.toString().trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }

  /// Convierte distintas representaciones
  /// en un valor booleano.
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

  /// Convierte un valor en fecha nullable.
  static DateTime? _convertirFechaNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.tryParse(valor.toString());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TipoPeligroModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TipoPeligroModel('
        'id: $id, '
        'codigo: $codigo, '
        'nombre: $nombre, '
        'activo: $activo, '
        'estado: $estado'
        ')';
  }
}

/// Datos enviados al backend para crear
/// un tipo de peligro.
class CrearTipoPeligroRequest {
  /// Código del tipo.
  final String codigo;

  /// Nombre del tipo.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Estado activo inicial.
  final bool activo;

  const CrearTipoPeligroRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  /// Convierte la solicitud en JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'activo': activo,
    };
  }
}

/// Datos enviados al backend para actualizar
/// un tipo de peligro.
class ActualizarTipoPeligroRequest {
  /// Código actualizado.
  final String codigo;

  /// Nombre actualizado.
  final String nombre;

  /// Descripción actualizada.
  final String? descripcion;

  /// Estado activo.
  final bool activo;

  const ActualizarTipoPeligroRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  /// Convierte la solicitud en JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'activo': activo,
    };
  }
}

/// Elimina espacios innecesarios y convierte
/// textos vacíos en null.
String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
