/// Modelo que representa una categoría de peligro.
///
/// Las categorías permiten agrupar los tipos de peligro
/// utilizados dentro del sistema SST/IPERC.
class CategoriaPeligroModel {
  const CategoriaPeligroModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    this.icono,
    required this.orden,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Identificador de la categoría.
  final int id;

  /// Nombre visible de la categoría.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Color almacenado por el backend.
  ///
  /// Puede contener valores como:
  ///
  /// `#FF0000`
  ///
  /// `FF0000`
  final String? color;

  /// Nombre o código del icono.
  final String? icono;

  /// Posición de la categoría dentro de los listados.
  final int orden;

  /// Estado funcional de la categoría.
  final bool activo;

  /// Estado general heredado de auditoría.
  final bool estado;

  /// Fecha de registro.
  final DateTime? fechaRegistro;

  /// Fecha de última modificación.
  final DateTime? fechaActualizacion;

  /// Construye el modelo desde una respuesta JSON.
  factory CategoriaPeligroModel.fromJson(Map<String, dynamic> json) {
    return CategoriaPeligroModel(
      id: _convertirEntero(json['id']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      color: _convertirTextoNullable(json['color']),
      icono: _convertirTextoNullable(json['icono']),
      orden: _convertirEntero(json['orden'], valorPredeterminado: 1),
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

  /// Convierte el modelo a JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'icono': icono,
      'orden': orden,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia modificada del registro.
  CategoriaPeligroModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    String? color,
    bool limpiarColor = false,
    String? icono,
    bool limpiarIcono = false,
    int? orden,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return CategoriaPeligroModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      color: limpiarColor ? null : color ?? this.color,
      icono: limpiarIcono ? null : icono ?? this.icono,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si la categoría puede utilizarse.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Descripción que se mostrará en pantalla.
  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin descripción';
    }

    return texto;
  }

  /// Color visible normalizado.
  String get colorVisible {
    final String texto = color?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin color';
    }

    return texto;
  }

  /// Icono visible normalizado.
  String get iconoVisible {
    final String texto = icono?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin icono';
    }

    return texto;
  }

  /// Convierte diferentes formatos de respuesta
  /// en una lista de categorías.
  static List<CategoriaPeligroModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map((Map elemento) {
          return CategoriaPeligroModel.fromJson(
            Map<String, dynamic>.from(elemento),
          );
        })
        .where((CategoriaPeligroModel categoria) {
          return categoria.id > 0;
        })
        .toList();
  }

  /// Extrae una lista desde diferentes formatos
  /// enviados por el backend.
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
        mapa['categorias'],
        mapa['categoriasPeligro'],
      ];

      for (final dynamic valor in posiblesListas) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  static int _convertirEntero(dynamic valor, {int valorPredeterminado = 0}) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? valorPredeterminado;
  }

  static String _convertirTexto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

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
  String toString() {
    return 'CategoriaPeligroModel('
        'id: $id, '
        'nombre: $nombre, '
        'orden: $orden, '
        'activo: $activo, '
        'estado: $estado'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CategoriaPeligroModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Datos enviados para registrar
/// una categoría de peligro.
class CrearCategoriaPeligroRequest {
  const CrearCategoriaPeligroRequest({
    required this.nombre,
    this.descripcion,
    this.color,
    this.icono,
    required this.orden,
    this.activo = true,
  });

  final String nombre;
  final String? descripcion;
  final String? color;
  final String? icono;
  final int orden;
  final bool activo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'color': _normalizarTexto(color),
      'icono': _normalizarTexto(icono),
      'orden': orden,
      'activo': activo,
    };
  }

  static String? _normalizarTexto(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}

/// Datos enviados para actualizar
/// una categoría de peligro.
class ActualizarCategoriaPeligroRequest {
  const ActualizarCategoriaPeligroRequest({
    required this.nombre,
    this.descripcion,
    this.color,
    this.icono,
    required this.orden,
    required this.activo,
  });

  final String nombre;
  final String? descripcion;
  final String? color;
  final String? icono;
  final int orden;
  final bool activo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'color': _normalizarTexto(color),
      'icono': _normalizarTexto(icono),
      'orden': orden,
      'activo': activo,
    };
  }

  static String? _normalizarTexto(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
