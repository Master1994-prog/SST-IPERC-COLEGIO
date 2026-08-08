/// Representa un puesto de trabajo perteneciente a un área.
class PuestoTrabajoModel {
  const PuestoTrabajoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.areaId,
    required this.areaNombre,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final int areaId;
  final String areaNombre;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  /// Convierte la respuesta JSON del backend en un objeto.
  factory PuestoTrabajoModel.fromJson(Map<String, dynamic> json) {
    return PuestoTrabajoModel(
      id: _convertirEntero(json['id'] ?? json['Id']),
      nombre: _convertirTexto(json['nombre'] ?? json['Nombre']),
      descripcion: _convertirTexto(json['descripcion'] ?? json['Descripcion']),
      activo: _convertirBooleano(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
      areaId: _convertirEntero(json['areaId'] ?? json['AreaId']),
      areaNombre: _convertirTexto(json['areaNombre'] ?? json['AreaNombre']),
      fechaRegistro: _convertirFecha(
        json['fechaRegistro'] ?? json['FechaRegistro'],
      ),
      fechaActualizacion: _convertirFecha(
        json['fechaActualizacion'] ?? json['FechaActualizacion'],
      ),
    );
  }

  /// Convierte una respuesta dinámica en una lista de puestos.
  static List<PuestoTrabajoModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return PuestoTrabajoModel.fromJson(
            Map<String, dynamic>.from(elemento),
          );
        })
        .where((PuestoTrabajoModel puesto) {
          return puesto.id > 0 && puesto.nombre.isNotEmpty;
        })
        .toList();
  }

  /// Extrae un objeto individual desde diferentes formatos de respuesta.
  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ??
        mapa['result'] ??
        mapa['value'] ??
        mapa['puestoTrabajo'] ??
        mapa['puesto'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  /// Genera una copia del puesto modificando solo los campos indicados.
  PuestoTrabajoModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activo,
    int? areaId,
    String? areaNombre,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return PuestoTrabajoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      areaId: areaId ?? this.areaId,
      areaNombre: areaNombre ?? this.areaNombre,
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
        mapa['puestosTrabajo'],
        mapa['puestos'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
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

  static bool _convertirBooleano(
    dynamic valor, {
    required bool valorPredeterminado,
  }) {
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

  static DateTime? _convertirFecha(dynamic valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.tryParse(valor.toString());
  }
}
