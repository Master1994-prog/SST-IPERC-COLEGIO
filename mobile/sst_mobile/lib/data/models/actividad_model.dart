/// Representa una actividad perteneciente a un proceso.
class ActividadModel {
  const ActividadModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.procesoId,
    required this.procesoNombre,
    required this.areaId,
    required this.areaNombre,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final int procesoId;
  final String procesoNombre;
  final int areaId;
  final String areaNombre;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  factory ActividadModel.fromJson(Map<String, dynamic> json) {
    return ActividadModel(
      id: _toInt(json['id'] ?? json['Id']),
      nombre: _toString(json['nombre'] ?? json['Nombre']),
      descripcion: _toString(json['descripcion'] ?? json['Descripcion']),
      activo: _toBool(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
      procesoId: _toInt(json['procesoId'] ?? json['ProcesoId']),
      procesoNombre: _toString(json['procesoNombre'] ?? json['ProcesoNombre']),
      areaId: _toInt(json['areaId'] ?? json['AreaId']),
      areaNombre: _toString(json['areaNombre'] ?? json['AreaNombre']),
      fechaRegistro: _toDateTime(
        json['fechaRegistro'] ?? json['FechaRegistro'],
      ),
      fechaActualizacion: _toDateTime(
        json['fechaActualizacion'] ?? json['FechaActualizacion'],
      ),
    );
  }

  static List<ActividadModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return ActividadModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((ActividadModel actividad) {
          return actividad.id > 0 && actividad.nombre.isNotEmpty;
        })
        .toList();
  }

  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['actividad'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
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
        mapa['actividades'],
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
