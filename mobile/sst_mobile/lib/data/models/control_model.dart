/// Modelo que representa una medida de control del sistema SST.
///
/// Una medida de control se utiliza para reducir, eliminar
/// o mantener bajo control un peligro identificado.
class ControlModel {
  /// Identificador único del control.
  final int id;

  /// Código generado para el control.
  ///
  /// Ejemplo:
  ///
  /// `CTRL-001`
  final String codigo;

  /// Nombre de la medida de control.
  final String nombre;

  /// Descripción detallada del control.
  final String? descripcion;

  /// Identificador de la clasificación del control.
  ///
  /// Puede representar categorías como:
  ///
  /// - Eliminación.
  /// - Sustitución.
  /// - Control de ingeniería.
  /// - Control administrativo.
  /// - Equipo de protección personal.
  final int? clasificacionControlId;

  /// Nombre de la clasificación del control.
  final String? clasificacionControlNombre;

  /// Indica si el control se encuentra activo.
  final bool activo;

  /// Estado lógico del registro.
  ///
  /// Normalmente se utiliza para eliminación lógica.
  final bool estado;

  /// Fecha en la que se registró el control.
  final DateTime? fechaRegistro;

  /// Fecha de la última actualización.
  final DateTime? fechaActualizacion;

  const ControlModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.clasificacionControlId,
    this.clasificacionControlNombre,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Convierte una respuesta JSON del backend
  /// en una instancia de [ControlModel].
  factory ControlModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? clasificacion = _convertirMapa(
      json['clasificacionControl'],
    );

    return ControlModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      clasificacionControlId: _convertirEnteroNullable(
        json['clasificacionControlId'] ?? clasificacion?['id'],
      ),
      clasificacionControlNombre: _convertirTextoNullable(
        json['clasificacionControlNombre'] ?? clasificacion?['nombre'],
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

  /// Convierte el modelo en un mapa JSON.
  ///
  /// Puede utilizarse para almacenamiento local
  /// o para enviar información al backend.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'clasificacionControlId': clasificacionControlId,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia del modelo modificando solamente
  /// los valores indicados.
  ControlModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    int? clasificacionControlId,
    bool limpiarClasificacionControlId = false,
    String? clasificacionControlNombre,
    bool limpiarClasificacionControlNombre = false,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return ControlModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      clasificacionControlId: limpiarClasificacionControlId
          ? null
          : clasificacionControlId ?? this.clasificacionControlId,
      clasificacionControlNombre: limpiarClasificacionControlNombre
          ? null
          : clasificacionControlNombre ?? this.clasificacionControlNombre,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si el control puede utilizarse
  /// en nuevos registros IPERC.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Devuelve el código y nombre en un solo texto.
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

  /// Devuelve una descripción preparada para mostrar
  /// en la interfaz.
  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin descripción';
    }

    return texto;
  }

  /// Devuelve el nombre de la clasificación.
  String get clasificacionVisible {
    final String texto = clasificacionControlNombre?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin clasificación';
    }

    return texto;
  }

  /// Convierte una respuesta JSON que contiene una lista
  /// de controles.
  ///
  /// Admite respuestas directas:
  ///
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "nombre": "Señalización"
  ///   }
  /// ]
  /// ```
  ///
  /// También admite respuestas envueltas:
  ///
  /// ```json
  /// {
  ///   "data": []
  /// }
  /// ```
  static List<ControlModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (dynamic elemento) =>
              ControlModel.fromJson(Map<String, dynamic>.from(elemento as Map)),
        )
        .where((ControlModel control) => control.id > 0)
        .toList();
  }

  /// Extrae una lista desde diferentes formatos
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
        mapa['controles'],
      ];

      for (final dynamic valor in posiblesValores) {
        if (valor is List) {
          return valor;
        }
      }
    }

    return <dynamic>[];
  }

  /// Convierte un valor dinámico en mapa.
  static Map<String, dynamic>? _convertirMapa(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }

    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

    return null;
  }

  /// Convierte un valor en entero.
  static int _convertirEntero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  /// Convierte un valor en entero nullable.
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

  /// Convierte un valor en texto.
  static String _convertirTexto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  /// Convierte un valor en texto nullable.
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

  /// Convierte diferentes representaciones en booleano.
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
    return identical(this, other) || other is ControlModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ControlModel('
        'id: $id, '
        'codigo: $codigo, '
        'nombre: $nombre, '
        'clasificacionControlId: '
        '$clasificacionControlId, '
        'activo: $activo, '
        'estado: $estado'
        ')';
  }
}

/// Datos que Flutter enviará al backend
/// para registrar una medida de control.
class CrearControlRequest {
  /// Código generado para el control.
  final String codigo;

  /// Nombre de la medida de control.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Clasificación seleccionada.
  final int? clasificacionControlId;

  /// Indica si el control estará activo.
  final bool activo;

  /// Usuario que registra el control.
  final int usuarioRegistroId;

  const CrearControlRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.clasificacionControlId,
    this.activo = true,
    required this.usuarioRegistroId,
  });

  /// Convierte la solicitud en JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'clasificacionControlId': clasificacionControlId,
      'activo': activo,
      'usuarioRegistroId': usuarioRegistroId,
    };
  }
}

/// Datos que Flutter enviará al backend
/// para actualizar una medida de control.
class ActualizarControlRequest {
  /// Código actual del control.
  final String codigo;

  /// Nombre actualizado.
  final String nombre;

  /// Descripción actualizada.
  final String? descripcion;

  /// Clasificación seleccionada.
  final int? clasificacionControlId;

  /// Estado activo.
  final bool activo;

  /// Usuario que modifica el control.
  final int usuarioActualizacionId;

  const ActualizarControlRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.clasificacionControlId,
    required this.activo,
    required this.usuarioActualizacionId,
  });

  /// Convierte la solicitud en JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'clasificacionControlId': clasificacionControlId,
      'activo': activo,
      'usuarioActualizacionId': usuarioActualizacionId,
    };
  }
}

/// Elimina espacios innecesarios.
///
/// Cuando el texto está vacío, devuelve `null`.
String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
