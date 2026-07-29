/// Modelo utilizado para representar un peligro SST.
///
/// La categoría no se almacena directamente en el peligro.
/// El backend la obtiene mediante el tipo de peligro relacionado.
class PeligroModel {
  const PeligroModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipoPeligroId,
    this.tipoPeligroNombre,
    this.categoriaPeligroId,
    this.categoriaPeligroNombre,
    this.fuente,
    this.medio,
    this.receptor,
    this.requisitoLegal,
    this.recomendaciones,
    required this.activo,
    this.estado = true,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Identificador único del peligro.
  final int id;

  /// Código único.
  ///
  /// Ejemplo: PEL-0001.
  final String codigo;

  /// Nombre del peligro.
  final String nombre;

  /// Descripción detallada.
  final String? descripcion;

  /// Identificador del tipo de peligro.
  ///
  /// Este campo es obligatorio en el backend.
  final int tipoPeligroId;

  /// Nombre del tipo de peligro.
  final String? tipoPeligroNombre;

  /// Identificador de la categoría.
  ///
  /// Es un campo de lectura porque el backend lo obtiene
  /// desde el tipo de peligro.
  final int? categoriaPeligroId;

  /// Nombre de la categoría.
  ///
  /// Es un campo de lectura porque el backend lo obtiene
  /// desde el tipo de peligro.
  final String? categoriaPeligroNombre;

  /// Fuente que genera el peligro.
  final String? fuente;

  /// Medio por el cual se transmite el peligro.
  final String? medio;

  /// Persona o elemento expuesto.
  final String? receptor;

  /// Requisitos legales aplicables.
  final String? requisitoLegal;

  /// Recomendaciones generales.
  final String? recomendaciones;

  /// Estado funcional del peligro.
  final bool activo;

  /// Estado general utilizado por algunos módulos del sistema.
  ///
  /// El DTO actual del backend no lo devuelve, por eso
  /// se considera verdadero de manera predeterminada.
  final bool estado;

  /// Fecha de registro, cuando el backend la proporciona.
  final DateTime? fechaRegistro;

  /// Fecha de actualización, cuando el backend la proporciona.
  final DateTime? fechaActualizacion;

  /// Crea un peligro desde la respuesta del backend.
  factory PeligroModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? tipo = _convertirMapa(json['tipoPeligro']);

    final Map<String, dynamic>? categoria = _convertirMapa(
      json['categoriaPeligro'] ?? tipo?['categoriaPeligro'],
    );

    return PeligroModel(
      id: _convertirEntero(json['id']),
      codigo: _convertirTexto(json['codigo']),
      nombre: _convertirTexto(json['nombre']),
      descripcion: _convertirTextoNullable(json['descripcion']),
      tipoPeligroId: _convertirEntero(json['tipoPeligroId'] ?? tipo?['id']),
      tipoPeligroNombre: _convertirTextoNullable(
        json['tipoPeligroNombre'] ?? tipo?['nombre'],
      ),
      categoriaPeligroId: _convertirEnteroNullable(
        json['categoriaPeligroId'] ??
            categoria?['id'] ??
            tipo?['categoriaPeligroId'],
      ),
      categoriaPeligroNombre: _convertirTextoNullable(
        json['categoriaPeligroNombre'] ?? categoria?['nombre'],
      ),
      fuente: _convertirTextoNullable(json['fuente']),
      medio: _convertirTextoNullable(json['medio']),
      receptor: _convertirTextoNullable(json['receptor']),
      requisitoLegal: _convertirTextoNullable(json['requisitoLegal']),
      recomendaciones: _convertirTextoNullable(json['recomendaciones']),
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
  ///
  /// Se utiliza principalmente para almacenamiento local.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipoPeligroId': tipoPeligroId,
      'tipoPeligroNombre': tipoPeligroNombre,
      'categoriaPeligroId': categoriaPeligroId,
      'categoriaPeligroNombre': categoriaPeligroNombre,
      'fuente': fuente,
      'medio': medio,
      'receptor': receptor,
      'requisitoLegal': requisitoLegal,
      'recomendaciones': recomendaciones,
      'activo': activo,
      'estado': estado,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea una copia modificada del peligro.
  PeligroModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool limpiarDescripcion = false,
    int? tipoPeligroId,
    String? tipoPeligroNombre,
    bool limpiarTipoPeligroNombre = false,
    int? categoriaPeligroId,
    bool limpiarCategoriaPeligroId = false,
    String? categoriaPeligroNombre,
    bool limpiarCategoriaPeligroNombre = false,
    String? fuente,
    bool limpiarFuente = false,
    String? medio,
    bool limpiarMedio = false,
    String? receptor,
    bool limpiarReceptor = false,
    String? requisitoLegal,
    bool limpiarRequisitoLegal = false,
    String? recomendaciones,
    bool limpiarRecomendaciones = false,
    bool? activo,
    bool? estado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool limpiarFechaActualizacion = false,
  }) {
    return PeligroModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: limpiarDescripcion ? null : descripcion ?? this.descripcion,
      tipoPeligroId: tipoPeligroId ?? this.tipoPeligroId,
      tipoPeligroNombre: limpiarTipoPeligroNombre
          ? null
          : tipoPeligroNombre ?? this.tipoPeligroNombre,
      categoriaPeligroId: limpiarCategoriaPeligroId
          ? null
          : categoriaPeligroId ?? this.categoriaPeligroId,
      categoriaPeligroNombre: limpiarCategoriaPeligroNombre
          ? null
          : categoriaPeligroNombre ?? this.categoriaPeligroNombre,
      fuente: limpiarFuente ? null : fuente ?? this.fuente,
      medio: limpiarMedio ? null : medio ?? this.medio,
      receptor: limpiarReceptor ? null : receptor ?? this.receptor,
      requisitoLegal: limpiarRequisitoLegal
          ? null
          : requisitoLegal ?? this.requisitoLegal,
      recomendaciones: limpiarRecomendaciones
          ? null
          : recomendaciones ?? this.recomendaciones,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: limpiarFechaActualizacion
          ? null
          : fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si puede utilizarse en nuevos registros.
  bool get estaDisponible {
    return activo && estado;
  }

  /// Código y nombre juntos.
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
    return _textoVisible(descripcion, 'Sin descripción');
  }

  String get tipoVisible {
    return _textoVisible(tipoPeligroNombre, 'Sin tipo de peligro');
  }

  String get categoriaVisible {
    return _textoVisible(categoriaPeligroNombre, 'Sin categoría');
  }

  String get fuenteVisible {
    return _textoVisible(fuente, 'Sin fuente registrada');
  }

  String get medioVisible {
    return _textoVisible(medio, 'Sin medio registrado');
  }

  String get receptorVisible {
    return _textoVisible(receptor, 'Sin receptor registrado');
  }

  String get requisitoLegalVisible {
    return _textoVisible(requisitoLegal, 'Sin requisito legal');
  }

  String get recomendacionesVisible {
    return _textoVisible(recomendaciones, 'Sin recomendaciones');
  }

  /// Convierte diferentes estructuras de respuesta
  /// en una lista de peligros.
  static List<PeligroModel> listaDesdeJson(dynamic data) {
    final List<dynamic> lista = _extraerLista(data);

    return lista
        .whereType<Map>()
        .map((Map elemento) {
          return PeligroModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((PeligroModel peligro) {
          return peligro.id > 0;
        })
        .toList();
  }

  /// Extrae una lista desde distintas respuestas API.
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
        mapa['peligros'],
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

  static Map<String, dynamic>? _convertirMapa(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }

    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

    return null;
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
  String toString() {
    return 'PeligroModel('
        'id: $id, '
        'codigo: $codigo, '
        'nombre: $nombre, '
        'tipoPeligroId: $tipoPeligroId, '
        'activo: $activo'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PeligroModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Solicitud enviada al backend para crear un peligro.
///
/// Coincide con `CreatePeligroDto`.
class CrearPeligroRequest {
  const CrearPeligroRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipoPeligroId,
    this.fuente,
    this.medio,
    this.receptor,
    this.requisitoLegal,
    this.recomendaciones,
  });

  /// Código obligatorio.
  final String codigo;

  /// Nombre obligatorio.
  final String nombre;

  /// Descripción opcional.
  final String? descripcion;

  /// Tipo de peligro obligatorio.
  final int tipoPeligroId;

  final String? fuente;
  final String? medio;
  final String? receptor;
  final String? requisitoLegal;
  final String? recomendaciones;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim().toUpperCase(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'tipoPeligroId': tipoPeligroId,
      'fuente': _normalizarTexto(fuente),
      'medio': _normalizarTexto(medio),
      'receptor': _normalizarTexto(receptor),
      'requisitoLegal': _normalizarTexto(requisitoLegal),
      'recomendaciones': _normalizarTexto(recomendaciones),
    };
  }

  static String? _normalizarTexto(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}

/// Solicitud enviada al backend para actualizar un peligro.
///
/// Coincide con `UpdatePeligroDto`.
class ActualizarPeligroRequest {
  const ActualizarPeligroRequest({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipoPeligroId,
    this.fuente,
    this.medio,
    this.receptor,
    this.requisitoLegal,
    this.recomendaciones,
    required this.activo,
  });

  final String codigo;
  final String nombre;
  final String? descripcion;
  final int tipoPeligroId;
  final String? fuente;
  final String? medio;
  final String? receptor;
  final String? requisitoLegal;
  final String? recomendaciones;
  final bool activo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo': codigo.trim().toUpperCase(),
      'nombre': nombre.trim(),
      'descripcion': _normalizarTexto(descripcion),
      'tipoPeligroId': tipoPeligroId,
      'fuente': _normalizarTexto(fuente),
      'medio': _normalizarTexto(medio),
      'receptor': _normalizarTexto(receptor),
      'requisitoLegal': _normalizarTexto(requisitoLegal),
      'recomendaciones': _normalizarTexto(recomendaciones),
      'activo': activo,
    };
  }

  static String? _normalizarTexto(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
