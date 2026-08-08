/// ===============================================================
/// MODELO - PROBABILIDAD
/// ===============================================================
///
/// Representa una probabilidad utilizada en la evaluación
/// de riesgos de la matriz IPERC.
///
/// En el backend, Probabilidad maneja valores entre 1 y 5:
///
/// 1 = Rara
/// 2 = Poco probable
/// 3 = Posible
/// 4 = Probable
/// 5 = Casi segura
///
/// Este modelo será utilizado principalmente en listas
/// desplegables dentro del formulario de Detalle IPERC.
/// ===============================================================
class ProbabilidadModel {
  const ProbabilidadModel({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  /// Identificador interno de la probabilidad.
  final int id;

  /// Valor numérico utilizado para el cálculo del riesgo.
  ///
  /// Debe estar entre 1 y 5.
  final int valor;

  /// Nombre descriptivo.
  ///
  /// Ejemplo:
  /// "Probable"
  final String nombre;

  /// Descripción adicional.
  final String descripcion;

  // =============================================================
  // CONVERSIÓN DESDE JSON
  // =============================================================

  /// Convierte una respuesta JSON del backend
  /// en una instancia de ProbabilidadModel.
  factory ProbabilidadModel.fromJson(Map<String, dynamic> json) {
    return ProbabilidadModel(
      id: _toInt(json['id'] ?? json['Id']),
      valor: _toInt(json['valor'] ?? json['Valor']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
      descripcion: _toString(json['descripcion'] ?? json['Descripcion']),
    );
  }

  // =============================================================
  // LISTA DESDE JSON
  // =============================================================

  /// Convierte diferentes formatos de respuesta
  /// en una lista de probabilidades.
  ///
  /// Soporta:
  ///
  /// [
  ///   {...},
  ///   {...}
  /// ]
  ///
  /// o respuestas como:
  ///
  /// {
  ///   "data": [...]
  /// }
  ///
  /// {
  ///   "items": [...]
  /// }
  static List<ProbabilidadModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map item) {
          return ProbabilidadModel.fromJson(Map<String, dynamic>.from(item));
        })
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList();
  }

  // =============================================================
  // OBJETO DESDE JSON
  // =============================================================

  /// Extrae un único objeto de una respuesta.
  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['probabilidad'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  // =============================================================
  // TEXTO PARA LA INTERFAZ
  // =============================================================

  /// Texto que podemos mostrar directamente
  /// en un DropdownButton o lista.
  ///
  /// Ejemplo:
  ///
  /// "4 - Probable"
  String get textoSeleccion {
    return '$valor - $nombre';
  }

  // =============================================================
  // MÉTODOS AUXILIARES
  // =============================================================

  /// Extrae una lista desde distintos formatos
  /// posibles enviados por la API.
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
        mapa['probabilidades'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
        }
      }
    }

    return <dynamic>[];
  }

  /// Convierte cualquier valor compatible a entero.
  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Convierte un valor a texto limpio.
  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
