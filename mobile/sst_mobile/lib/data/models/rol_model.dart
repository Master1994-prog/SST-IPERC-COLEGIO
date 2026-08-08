/// Representa un rol disponible dentro del sistema SST/IPERC.
class RolModel {
  const RolModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.esGlobal,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final bool activo;
  final bool esGlobal;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  /// Convierte un JSON del backend en un RolModel.
  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: _toInt(json['id'] ?? json['Id']),
      codigo: _toString(json['codigo'] ?? json['Codigo']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
      descripcion: _toString(json['descripcion'] ?? json['Descripcion']),
      activo: _toBool(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
      esGlobal: _toBool(
        json['esGlobal'] ?? json['EsGlobal'],
        valorPredeterminado: false,
      ),
      fechaRegistro: _toDateTime(
        json['fechaRegistro'] ?? json['FechaRegistro'],
      ),
      fechaActualizacion: _toDateTime(
        json['fechaActualizacion'] ?? json['FechaActualizacion'],
      ),
    );
  }

  /// Convierte una respuesta dinámica en una lista de roles.
  static List<RolModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return RolModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((RolModel rol) {
          return rol.id > 0 && rol.nombre.isNotEmpty;
        })
        .toList();
  }

  /// Extrae un único objeto desde distintas formas de respuesta.
  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['rol'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  /// Crea una copia modificando solo los campos indicados.
  RolModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    bool? activo,
    bool? esGlobal,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return RolModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      esGlobal: esGlobal ?? this.esGlobal,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final List<dynamic> opciones = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['roles'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
        }
      }
    }

    return <dynamic>[];
  }

  static int _toInt(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  static bool _toBool(dynamic valor, {required bool valorPredeterminado}) {
    if (valor is bool) {
      return valor;
    }

    if (valor is num) {
      return valor != 0;
    }

    final String texto = valor?.toString().trim().toLowerCase() ?? '';

    if (<String>['true', '1', 'si', 'sí'].contains(texto)) {
      return true;
    }

    if (<String>['false', '0', 'no'].contains(texto)) {
      return false;
    }

    return valorPredeterminado;
  }

  static DateTime? _toDateTime(dynamic valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.tryParse(valor.toString());
  }
}
