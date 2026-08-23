/// ===============================================================
/// SOLICITUD DE ACCESO
/// ===============================================================
class SolicitudAccesoModel {
  const SolicitudAccesoModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.institucion,
    required this.cargo,
    required this.motivo,
    required this.estadoSolicitud,
    required this.fechaSolicitud,
    required this.fechaAtencion,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String correo;
  final String institucion;
  final String cargo;
  final String motivo;
  final String estadoSolicitud;
  final DateTime? fechaSolicitud;
  final DateTime? fechaAtencion;

  String get nombreCompleto {
    return '$nombres $apellidos'.trim();
  }

  bool get pendiente {
    return estadoSolicitud.toUpperCase() == 'PENDIENTE';
  }

  factory SolicitudAccesoModel.fromJson(Map<String, dynamic> json) {
    return SolicitudAccesoModel(
      id: _toInt(json['id'] ?? json['Id']),
      nombres: _toString(json['nombres'] ?? json['Nombres']),
      apellidos: _toString(json['apellidos'] ?? json['Apellidos']),
      correo: _toString(json['correo'] ?? json['Correo']),
      institucion: _toString(json['institucion'] ?? json['Institucion']),
      cargo: _toString(json['cargo'] ?? json['Cargo']),
      motivo: _toString(json['motivo'] ?? json['Motivo']),
      estadoSolicitud: _toString(
        json['estadoSolicitud'] ?? json['EstadoSolicitud'],
      ),
      fechaSolicitud: _toDateTime(
        json['fechaSolicitud'] ?? json['FechaSolicitud'],
      ),
      fechaAtencion: _toDateTime(
        json['fechaAtencion'] ?? json['FechaAtencion'],
      ),
    );
  }

  static List<SolicitudAccesoModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data, clave: 'solicitudes');

    return elementos
        .whereType<Map>()
        .map(
          (Map item) =>
              SolicitudAccesoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((SolicitudAccesoModel item) => item.id > 0)
        .toList();
  }
}

/// ===============================================================
/// SOLICITUD DE RECUPERACIÓN
/// ===============================================================
class SolicitudRecuperacionModel {
  const SolicitudRecuperacionModel({
    required this.id,
    required this.usuarioId,
    required this.identificador,
    required this.correo,
    required this.nombres,
    required this.apellidos,
    required this.nombreUsuario,
    required this.estadoSolicitud,
    required this.fechaSolicitud,
    required this.fechaAtencion,
  });

  final int id;

  final int? usuarioId;

  final String identificador;

  final String correo;

  final String nombres;

  final String apellidos;

  final String nombreUsuario;

  final String estadoSolicitud;

  final DateTime? fechaSolicitud;

  final DateTime? fechaAtencion;

  // =============================================================
  // NOMBRE COMPLETO
  // =============================================================

  String get nombreCompleto {
    final String resultado = '$nombres $apellidos'.trim();

    if (resultado.isNotEmpty) {
      return resultado;
    }

    return identificador;
  }

  bool get pendiente {
    return estadoSolicitud.toUpperCase() == 'PENDIENTE';
  }

  factory SolicitudRecuperacionModel.fromJson(Map<String, dynamic> json) {
    final int idUsuario = _toInt(json['usuarioId'] ?? json['UsuarioId']);

    return SolicitudRecuperacionModel(
      id: _toInt(json['id'] ?? json['Id']),
      usuarioId: idUsuario > 0 ? idUsuario : null,
      identificador: _toString(json['identificador'] ?? json['Identificador']),
      correo: _toString(json['correo'] ?? json['Correo']),
      nombres: _toString(json['nombres'] ?? json['Nombres']),
      apellidos: _toString(json['apellidos'] ?? json['Apellidos']),
      nombreUsuario: _toString(json['nombreUsuario'] ?? json['NombreUsuario']),
      estadoSolicitud: _toString(
        json['estadoSolicitud'] ?? json['EstadoSolicitud'],
      ),
      fechaSolicitud: _toDateTime(
        json['fechaSolicitud'] ?? json['FechaSolicitud'],
      ),
      fechaAtencion: _toDateTime(
        json['fechaAtencion'] ?? json['FechaAtencion'],
      ),
    );
  }

  static List<SolicitudRecuperacionModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data, clave: 'solicitudes');

    return elementos
        .whereType<Map>()
        .map(
          (Map item) => SolicitudRecuperacionModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((SolicitudRecuperacionModel item) => item.id > 0)
        .toList();
  }
}

// ===============================================================
// UTILIDADES
// ===============================================================

List<dynamic> _extraerLista(dynamic data, {required String clave}) {
  if (data is List) {
    return data;
  }

  if (data is Map) {
    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final List<dynamic> opciones = <dynamic>[
      mapa[clave],
      mapa['data'],
      mapa['items'],
      mapa['result'],
      mapa['results'],
      mapa['value'],
    ];

    for (final dynamic opcion in opciones) {
      if (opcion is List) {
        return opcion;
      }
    }
  }

  return <dynamic>[];
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _toString(dynamic value) {
  return value?.toString().trim() ?? '';
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
