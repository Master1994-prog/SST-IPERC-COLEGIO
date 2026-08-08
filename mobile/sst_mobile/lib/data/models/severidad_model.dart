/// ===============================================================
/// MODELO - SEVERIDAD
/// ===============================================================
///
/// Representa el nivel de severidad utilizado en la evaluación
/// de riesgos de una Matriz IPERC.
///
/// En el backend, Severidad maneja valores entre 1 y 5.
///
/// Ejemplo referencial:
///
/// 1 = Leve
/// 2 = Menor
/// 3 = Moderada
/// 4 = Grave
/// 5 = Catastrófica
///
/// El nombre real que se mostrará en Flutter será el que venga
/// desde la base de datos.
///
/// Este modelo será utilizado principalmente en:
///
/// - Formulario de Detalle IPERC.
/// - Evaluación inicial.
/// - Evaluación residual.
/// - Matriz de riesgo 5x5.
/// ===============================================================
class SeveridadModel {
  const SeveridadModel({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  /// Identificador único de la severidad.
  final int id;

  /// Valor numérico utilizado en la matriz 5x5.
  ///
  /// Debe estar entre 1 y 5.
  final int valor;

  /// Nombre descriptivo de la severidad.
  ///
  /// Ejemplo:
  /// "Grave"
  final String nombre;

  /// Descripción adicional de la severidad.
  final String descripcion;

  // =============================================================
  // CONVERSIÓN DESDE JSON
  // =============================================================

  /// Convierte un objeto JSON recibido desde el backend
  /// en una instancia de SeveridadModel.
  ///
  /// Soporta nombres de propiedades tanto en camelCase
  /// como en PascalCase.
  factory SeveridadModel.fromJson(Map<String, dynamic> json) {
    return SeveridadModel(
      id: _toInt(json['id'] ?? json['Id']),
      valor: _toInt(json['valor'] ?? json['Valor']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
      descripcion: _toString(json['descripcion'] ?? json['Descripcion']),
    );
  }

  // =============================================================
  // CONVERTIR LISTA DESDE JSON
  // =============================================================

  /// Convierte una respuesta del backend
  /// en una lista de SeveridadModel.
  ///
  /// Soporta respuestas directas:
  ///
  /// [
  ///   {...},
  ///   {...}
  /// ]
  ///
  /// y respuestas encapsuladas:
  ///
  /// {
  ///   "data": [...]
  /// }
  ///
  /// {
  ///   "items": [...]
  /// }
  static List<SeveridadModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map item) {
          return SeveridadModel.fromJson(Map<String, dynamic>.from(item));
        })
        .where((SeveridadModel severidad) {
          return severidad.id > 0 &&
              severidad.valor >= 1 &&
              severidad.valor <= 5;
        })
        .toList();
  }

  // =============================================================
  // EXTRAER UN OBJETO
  // =============================================================

  /// Extrae una severidad individual desde una respuesta
  /// del servidor.
  ///
  /// Soporta:
  ///
  /// {
  ///   "id": 1,
  ///   ...
  /// }
  ///
  /// o:
  ///
  /// {
  ///   "data": {
  ///      ...
  ///   }
  /// }
  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['severidad'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  // =============================================================
  // TEXTO PARA MOSTRAR EN LA INTERFAZ
  // =============================================================

  /// Devuelve un texto preparado para utilizar
  /// en listas o DropdownButton.
  ///
  /// Ejemplo:
  ///
  /// "5 - Catastrófica"
  String get textoSeleccion {
    return '$valor - $nombre';
  }

  // =============================================================
  // MÉTODOS AUXILIARES
  // =============================================================

  /// Extrae una lista desde distintos formatos
  /// de respuesta posibles.
  static List<dynamic> _extraerLista(dynamic data) {
    /// Si el servidor devuelve directamente una lista.
    if (data is List) {
      return data;
    }

    /// Si devuelve un objeto envolviendo la lista.
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final List<dynamic> opciones = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['severidades'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
        }
      }
    }

    /// Si no encontramos ninguna lista válida.
    return <dynamic>[];
  }

  /// Convierte un valor a entero.
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
