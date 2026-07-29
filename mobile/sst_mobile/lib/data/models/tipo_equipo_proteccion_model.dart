/// Modelo que representa un tipo de Equipo de Protección Personal.
///
/// Ejemplos:
///
/// - Protección de cabeza.
/// - Protección ocular.
/// - Protección auditiva.
/// - Protección respiratoria.
/// - Protección de manos.
class TipoEquipoProteccionModel {
  /// Identificador único.
  final int id;

  /// Código generado para el tipo de EPP.
  ///
  /// Ejemplo: EPP-TIPO-001
  final String codigo;

  /// Nombre del tipo de protección.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Indica si el registro está activo.
  final bool activo;

  /// Estado lógico del registro.
  final bool estado;

  /// Fecha de registro.
  final DateTime? fechaRegistro;

  /// Fecha de última actualización.
  final DateTime? fechaActualizacion;

  /// Orden de presentación dentro del catálogo.
  final int orden;

  /// Indica si pertenece al catálogo global.
  final bool esGlobal;

  /// Colegio propietario cuando no es global.
  final int? colegioId;

  const TipoEquipoProteccionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.orden,
    required this.activo,
    required this.estado,
    required this.esGlobal,
    this.colegioId,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Convierte el JSON del backend en un modelo.
  factory TipoEquipoProteccionModel.fromJson(Map<String, dynamic> json) {
    return TipoEquipoProteccionModel(
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
      orden: _convertirEntero(json['orden']),
      esGlobal: _convertirBooleano(json['esGlobal'], valorPredeterminado: true),
      colegioId: _convertirEnteroNullable(json['colegioId']),
    );
  }

  static int? _convertirEnteroNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor.toString());
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
      'orden': orden,
      'esGlobal': esGlobal,
      'colegioId': colegioId,
    };
  }

  /// Crea una copia modificando solo
  /// los valores indicados.
  TipoEquipoProteccionModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    int? orden,
    bool? esGlobal,
    int? colegioId,
    bool limpiarColegioId = false,
  }) {
    return TipoEquipoProteccionModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      orden: orden ?? this.orden,
      esGlobal: esGlobal ?? this.esGlobal,
      colegioId: limpiarColegioId ? null : colegioId ?? this.colegioId,
    );
  }

  /// Indica si el tipo puede seleccionarse
  /// en un formulario de EPP.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Texto para mostrar en selectores.
  String get nombreCompleto {
    final String codigoLimpio = codigo.trim();
    final String nombreLimpio = nombre.trim();

    if (codigoLimpio.isEmpty) {
      return nombreLimpio;
    }

    return '$codigoLimpio - $nombreLimpio';
  }

  /// Descripción preparada para la interfaz.
  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    return texto.isEmpty ? 'Sin descripción' : texto;
  }

  /// Convierte distintas respuestas del backend
  /// en una lista de tipos de EPP.
  static List<TipoEquipoProteccionModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (dynamic elemento) => TipoEquipoProteccionModel.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          ),
        )
        .where((TipoEquipoProteccionModel tipo) => tipo.id > 0)
        .toList();
  }

  /// Extrae una lista desde respuestas directas
  /// o envueltas por el backend.
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
        mapa['tiposEquipoProteccion'],
        mapa['tiposEquiposProteccion'],
      ];

      for (final dynamic valor in posibles) {
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
        texto == 'activo' ||
        texto == 'si' ||
        texto == 'sí') {
      return true;
    }

    if (texto == 'false' ||
        texto == '0' ||
        texto == 'inactivo' ||
        texto == 'no') {
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
        other is TipoEquipoProteccionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Solicitud para registrar un nuevo tipo de EPP.
///
/// Coincide con CreateTipoEquipoProteccionDto
/// del backend.
class CrearTipoEquipoProteccionRequest {
  /// Código único del tipo de EPP.
  final String codigo;

  /// Nombre del tipo de protección.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Orden de presentación dentro del catálogo.
  final int orden;

  /// Indica si pertenece al catálogo general.
  final bool esGlobal;

  /// Colegio propietario cuando no es global.
  final int? colegioId;

  const CrearTipoEquipoProteccionRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.orden,
    this.esGlobal = true,
    this.colegioId,
  });

  /// Convierte la solicitud al JSON esperado
  /// por CreateTipoEquipoProteccionDto.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'orden': orden,
      'esGlobal': esGlobal,
      'colegioId': colegioId,
    };
  }
}

/// Solicitud para actualizar un tipo de EPP.
///
/// Coincide con UpdateTipoEquipoProteccionDto
/// del backend.
class ActualizarTipoEquipoProteccionRequest {
  /// Código actualizado.
  final String codigo;

  /// Nombre actualizado.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Orden de presentación.
  final int orden;

  /// Estado activo del registro.
  final bool activo;

  /// Indica si pertenece al catálogo global.
  final bool esGlobal;

  /// Colegio propietario cuando no es global.
  final int? colegioId;

  const ActualizarTipoEquipoProteccionRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.orden,
    required this.activo,
    required this.esGlobal,
    this.colegioId,
  });

  /// Convierte la solicitud al JSON requerido
  /// por UpdateTipoEquipoProteccionDto.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'orden': orden,
      'activo': activo,
      'esGlobal': esGlobal,
      'colegioId': colegioId,
    };
  }
}

String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
