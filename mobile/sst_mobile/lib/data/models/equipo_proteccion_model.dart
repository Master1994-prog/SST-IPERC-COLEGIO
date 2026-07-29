/// Modelo que representa un Equipo de Protección Personal.
///
/// Ejemplos:
///
/// - Casco de seguridad.
/// - Guantes dieléctricos.
/// - Lentes de protección.
/// - Protector auditivo.
/// - Mascarilla.
/// - Calzado de seguridad.
class EquipoProteccionModel {
  /// Identificador único del equipo.
  final int id;

  /// Código generado por el backend.
  ///
  /// Ejemplo:
  ///
  /// `EPP-001`
  final String codigo;

  /// Nombre del equipo de protección.
  final String nombre;

  /// Descripción del equipo.
  final String? descripcion;

  /// Identificador del tipo de equipo de protección.
  final int? tipoEquipoProteccionId;

  /// Nombre del tipo de equipo.
  final String? tipoEquipoProteccionNombre;

  /// Indica si el equipo se encuentra activo.
  final bool activo;

  /// Estado lógico del registro.
  final bool estado;

  /// Fecha de creación del registro.
  final DateTime? fechaRegistro;

  /// Fecha de la última actualización.
  final DateTime? fechaActualizacion;

  const EquipoProteccionModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.tipoEquipoProteccionId,
    this.tipoEquipoProteccionNombre,
    required this.activo,
    required this.estado,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Convierte una respuesta JSON del backend
  /// en un modelo de equipo de protección.
  factory EquipoProteccionModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? tipo = _convertirMapa(
      json['tipoEquipoProteccion'],
    );

    return EquipoProteccionModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      tipoEquipoProteccionId: _convertirEnteroNullable(
        json['tipoEquipoProteccionId'] ?? tipo?['id'],
      ),
      tipoEquipoProteccionNombre: _convertirTextoNullable(
        json['tipoEquipoProteccionNombre'] ?? tipo?['nombre'],
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
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipoEquipoProteccionId': tipoEquipoProteccionId,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia del modelo modificando
  /// únicamente los campos indicados.
  EquipoProteccionModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    int? tipoEquipoProteccionId,
    bool limpiarTipoEquipoProteccionId = false,
    String? tipoEquipoProteccionNombre,
    bool limpiarTipoEquipoProteccionNombre = false,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return EquipoProteccionModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      tipoEquipoProteccionId: limpiarTipoEquipoProteccionId
          ? null
          : tipoEquipoProteccionId ?? this.tipoEquipoProteccionId,
      tipoEquipoProteccionNombre: limpiarTipoEquipoProteccionNombre
          ? null
          : tipoEquipoProteccionNombre ?? this.tipoEquipoProteccionNombre,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si el equipo puede utilizarse
  /// en nuevos registros IPERC.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Devuelve código y nombre en un solo texto.
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
  /// para mostrarse en la interfaz.
  String get descripcionVisible {
    final String texto = descripcion?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin descripción';
    }

    return texto;
  }

  /// Devuelve el nombre del tipo de EPP.
  String get tipoVisible {
    final String texto = tipoEquipoProteccionNombre?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Sin tipo de equipo';
    }

    return texto;
  }

  /// Convierte diferentes formatos de respuesta
  /// en una lista de equipos de protección.
  static List<EquipoProteccionModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map(
          (dynamic elemento) => EquipoProteccionModel.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          ),
        )
        .where((EquipoProteccionModel equipo) => equipo.id > 0)
        .toList();
  }

  /// Extrae una lista desde respuestas directas
  /// o respuestas envueltas.
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
        mapa['equiposProteccion'],
        mapa['equiposDeProteccion'],
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

    return texto.isEmpty ? null : texto;
  }

  /// Convierte diferentes representaciones
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
        other is EquipoProteccionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EquipoProteccionModel('
        'id: $id, '
        'codigo: $codigo, '
        'nombre: $nombre, '
        'tipoEquipoProteccionId: '
        '$tipoEquipoProteccionId, '
        'activo: $activo, '
        'estado: $estado'
        ')';
  }
}

/// Solicitud utilizada para registrar
/// un nuevo equipo de protección.
class CrearEquipoProteccionRequest {
  /// Código único del equipo.
  final String codigo;

  /// Nombre del equipo.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Identificador obligatorio del tipo de EPP.
  final int tipoEquipoProteccionId;

  /// Marca opcional del equipo.
  final String? marca;

  /// Modelo opcional del equipo.
  final String? modelo;

  /// Norma técnica aplicable.
  final String? normaTecnica;

  /// Vida útil aproximada, expresada en meses.
  final int? vidaUtilMeses;

  /// Indica si el equipo requiere capacitación.
  final bool requiereCapacitacion;

  /// Indica si el equipo requiere mantenimiento.
  final bool requiereMantenimiento;

  /// Indica si pertenece al catálogo general.
  final bool esGlobal;

  /// Colegio propietario cuando el equipo no es global.
  final int? colegioId;

  const CrearEquipoProteccionRequest({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.tipoEquipoProteccionId,
    this.marca,
    this.modelo,
    this.normaTecnica,
    this.vidaUtilMeses,
    this.requiereCapacitacion = false,
    this.requiereMantenimiento = false,
    this.esGlobal = true,
    this.colegioId,
  });

  /// Convierte la solicitud al formato exacto
  /// requerido por CreateEquipoProteccionDto.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'tipoEquipoProteccionId': tipoEquipoProteccionId,
      'marca': _normalizarTexto(marca),
      'modelo': _normalizarTexto(modelo),
      'normaTecnica': _normalizarTexto(normaTecnica),
      'vidaUtilMeses': vidaUtilMeses,
      'requiereCapacitacion': requiereCapacitacion,
      'requiereMantenimiento': requiereMantenimiento,
      'esGlobal': esGlobal,
      'colegioId': colegioId,
    };
  }
}

/// Solicitud utilizada para actualizar
/// un equipo de protección existente.
///
/// Coincide con UpdateEquipoProteccionDto
/// del backend.
class ActualizarEquipoProteccionRequest {
  /// Código actualizado del EPP.
  final String codigo;

  /// Nombre actualizado.
  final String nombre;

  /// Descripción actualizada.
  final String? descripcion;

  /// Tipo de EPP seleccionado.
  final int tipoEquipoProteccionId;

  /// Marca opcional.
  final String? marca;

  /// Modelo opcional.
  final String? modelo;

  /// Norma técnica aplicable.
  final String? normaTecnica;

  /// Vida útil estimada en meses.
  final int? vidaUtilMeses;

  /// Indica si requiere capacitación.
  final bool requiereCapacitacion;

  /// Indica si requiere mantenimiento.
  final bool requiereMantenimiento;

  /// Estado activo del registro.
  final bool activo;

  /// Indica si pertenece al catálogo global.
  final bool esGlobal;

  /// Colegio propietario.
  final int? colegioId;

  const ActualizarEquipoProteccionRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipoEquipoProteccionId,
    this.marca,
    this.modelo,
    this.normaTecnica,
    this.vidaUtilMeses,
    this.requiereCapacitacion = false,
    this.requiereMantenimiento = false,
    required this.activo,
    this.esGlobal = true,
    this.colegioId,
  });

  /// Convierte la solicitud al JSON requerido
  /// por UpdateEquipoProteccionDto.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'tipoEquipoProteccionId': tipoEquipoProteccionId,
      'marca': _normalizarTexto(marca),
      'modelo': _normalizarTexto(modelo),
      'normaTecnica': _normalizarTexto(normaTecnica),
      'vidaUtilMeses': vidaUtilMeses,
      'requiereCapacitacion': requiereCapacitacion,
      'requiereMantenimiento': requiereMantenimiento,
      'activo': activo,
      'esGlobal': esGlobal,
      'colegioId': colegioId,
    };
  }
}

/// Limpia los espacios de un texto.
///
/// Devuelve `null` cuando el contenido está vacío.
String? _normalizarTexto(String? valor) {
  final String texto = valor?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
