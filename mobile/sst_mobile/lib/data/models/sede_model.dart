/// Representa una sede perteneciente a una institución.
class SedeModel {
  const SedeModel({
    required this.id,
    required this.nombre,
    required this.institucionId,
    required this.activo,
    this.codigo = '',
    this.direccion = '',
    this.descripcion = '',
  });

  final int id;
  final String codigo;
  final String nombre;
  final String direccion;
  final String descripcion;
  final int institucionId;
  final bool activo;

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: _toInt(json['id'] ?? json['Id']),
      codigo: _toString(json['codigo'] ?? json['Codigo']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
      direccion: _toString(json['direccion'] ?? json['Direccion']),
      descripcion: _toString(json['descripcion'] ?? json['Descripcion']),
      institucionId: _toInt(json['institucionId'] ?? json['InstitucionId']),
      activo: _toBool(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
    );
  }

  static List<SedeModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return SedeModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((SedeModel sede) {
          return sede.id > 0 && sede.nombre.isNotEmpty;
        })
        .toList();
  }

  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['sede'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  SedeModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? direccion,
    String? descripcion,
    int? institucionId,
    bool? activo,
  }) {
    return SedeModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      descripcion: descripcion ?? this.descripcion,
      institucionId: institucionId ?? this.institucionId,
      activo: activo ?? this.activo,
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
        mapa['sedes'],
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
}
