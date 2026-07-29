/// Modelo que representa una clasificación de control
/// dentro de la jerarquía de controles de SST.
///
/// Ejemplos:
///
/// - Eliminación.
/// - Sustitución.
/// - Control de ingeniería.
/// - Control administrativo.
/// - Equipo de protección personal.
class ClasificacionControlModel {
  /// Identificador único.
  final int id;

  /// Código único.
  ///
  /// Ejemplo: JC-001
  final String codigo;

  /// Nombre de la clasificación.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Nivel de prioridad.
  ///
  /// Un número menor representa una prioridad mayor.
  final int prioridad;

  /// Indica si la clasificación está activa.
  final bool activo;

  /// Estado lógico heredado de BaseAuditableEntity.
  final bool estado;

  /// Fecha de registro.
  final DateTime? fechaRegistro;

  /// Fecha de última actualización.
  final DateTime? fechaActualizacion;

  const ClasificacionControlModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.prioridad,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Convierte una respuesta JSON del backend
  /// en una clasificación de control.
  factory ClasificacionControlModel.fromJson(Map<String, dynamic> json) {
    return ClasificacionControlModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      prioridad: _convertirEntero(json['prioridad']),
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

  /// Convierte el modelo en un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia del modelo modificando
  /// solamente los valores indicados.
  ClasificacionControlModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    int? prioridad,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return ClasificacionControlModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si la clasificación puede utilizarse
  /// en los formularios de controles.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Nombre preparado para mostrarse en selectores.
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

  /// Prioridad preparada para la interfaz.
  String get prioridadVisible {
    return 'Prioridad $prioridad';
  }

  /// Convierte distintas respuestas del backend
  /// en una lista de clasificaciones.
  static List<ClasificacionControlModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (dynamic elemento) => ClasificacionControlModel.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          ),
        )
        .where(
          (ClasificacionControlModel clasificacion) => clasificacion.id > 0,
        )
        .toList();
  }

  /// Extrae la lista desde respuestas directas
  /// o respuestas envueltas.
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
        mapa['clasificacionesControl'],
        mapa['clasificaciones'],
      ];

      for (final dynamic valor in posibles) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  /// Convierte un valor dinámico a entero.
  static int _convertirEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  /// Convierte un valor dinámico a texto.
  static String _convertirTexto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  /// Convierte un valor dinámico a texto nullable.
  static String? _convertirTextoNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final String texto = valor.toString().trim();

    return texto.isEmpty ? null : texto;
  }

  /// Convierte distintos tipos de datos
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

  /// Convierte una fecha opcional.
  static DateTime? _convertirFechaNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.tryParse(valor.toString());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ClasificacionControlModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Solicitud utilizada para registrar
/// una nueva clasificación de control.
///
/// Coincide con CreateClasificacionControlDto.
class CrearClasificacionControlRequest {
  /// Código único.
  final String codigo;

  /// Nombre de la clasificación.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Nivel de prioridad.
  final int prioridad;

  /// Estado inicial.
  final bool activo;

  const CrearClasificacionControlRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.prioridad,
    this.activo = true,
  });

  /// Convierte la solicitud al JSON esperado
  /// por el backend.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'prioridad': prioridad,
      'activo': activo,
    };
  }
}

/// Solicitud utilizada para actualizar
/// una clasificación de control.
///
/// Coincide con UpdateClasificacionControlDto.
class ActualizarClasificacionControlRequest {
  /// Código actualizado.
  final String codigo;

  /// Nombre actualizado.
  final String nombre;

  /// Descripción actualizada.
  final String? descripcion;

  /// Prioridad actualizada.
  final int prioridad;

  /// Estado actualizado.
  final bool activo;

  const ActualizarClasificacionControlRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.prioridad,
    required this.activo,
  });

  /// Convierte la solicitud al JSON esperado
  /// por el backend.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'prioridad': prioridad,
      'activo': activo,
    };
  }
}

/// Convierte textos vacíos en null.
String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
