/// Representa una institución disponible en el sistema.
class InstitucionModel {
  const InstitucionModel({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory InstitucionModel.fromJson(Map<String, dynamic> json) {
    return InstitucionModel(
      id: _toInt(json['id'] ?? json['Id']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
    );
  }

  static List<InstitucionModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return InstitucionModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((InstitucionModel institucion) {
          return institucion.id > 0 && institucion.nombre.trim().isNotEmpty;
        })
        .toList();
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
        mapa['instituciones'],
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
}
