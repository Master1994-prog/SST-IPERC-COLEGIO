import 'rol_model.dart';

/// Representa un usuario del sistema SST/IPERC.
class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.correo,
    required this.telefono,
    required this.debeCambiarPassword,
    required this.institucionId,
    required this.sedeId,
    required this.areaId,
    required this.activo,
    required this.roles,
    this.ultimoAcceso,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;

  final String nombreUsuario;

  final String numeroDocumento;
  final String tipoDocumento;

  final String correo;
  final String telefono;

  final bool debeCambiarPassword;

  final DateTime? ultimoAcceso;

  final int institucionId;
  final int? sedeId;
  final int? areaId;

  final bool activo;

  final List<RolModel> roles;

  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  /// Convierte la respuesta JSON del backend en un UsuarioModel.
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: _toInt(json['id'] ?? json['Id']),
      nombres: _toString(json['nombres'] ?? json['Nombres']),
      apellidos: _toString(json['apellidos'] ?? json['Apellidos']),
      nombreCompleto: _obtenerNombreCompleto(json),
      nombreUsuario: _toString(json['nombreUsuario'] ?? json['NombreUsuario']),
      numeroDocumento: _toString(
        json['numeroDocumento'] ?? json['NumeroDocumento'],
      ),
      tipoDocumento: _toString(json['tipoDocumento'] ?? json['TipoDocumento']),
      correo: _toString(json['correo'] ?? json['Correo']),
      telefono: _toString(json['telefono'] ?? json['Telefono']),
      debeCambiarPassword: _toBool(
        json['debeCambiarPassword'] ?? json['DebeCambiarPassword'],
        valorPredeterminado: true,
      ),
      ultimoAcceso: _toDateTime(json['ultimoAcceso'] ?? json['UltimoAcceso']),
      institucionId: _toInt(json['institucionId'] ?? json['InstitucionId']),
      sedeId: _toNullableInt(json['sedeId'] ?? json['SedeId']),
      areaId: _toNullableInt(json['areaId'] ?? json['AreaId']),
      activo: _toBool(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
      roles: _rolesDesdeJson(json['roles'] ?? json['Roles']),
      fechaRegistro: _toDateTime(
        json['fechaRegistro'] ?? json['FechaRegistro'],
      ),
      fechaActualizacion: _toDateTime(
        json['fechaActualizacion'] ?? json['FechaActualizacion'],
      ),
    );
  }

  /// Convierte una respuesta del backend en una lista de usuarios.
  static List<UsuarioModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map((Map elemento) {
          return UsuarioModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((UsuarioModel usuario) {
          return usuario.id > 0 && usuario.nombreUsuario.isNotEmpty;
        })
        .toList();
  }

  /// Extrae un único usuario desde diferentes formatos de respuesta.
  static Map<String, dynamic> objetoDesdeJson(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['usuario'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  /// Devuelve los identificadores de los roles asignados.
  List<int> get rolIds {
    return roles
        .map((RolModel rol) => rol.id)
        .where((int id) => id > 0)
        .toList();
  }

  /// Devuelve los nombres de roles separados por coma.
  String get rolesTexto {
    if (roles.isEmpty) {
      return 'Sin rol';
    }

    return roles
        .map((RolModel rol) => rol.nombre)
        .where((String nombre) => nombre.trim().isNotEmpty)
        .join(', ');
  }

  /// Devuelve el nombre visible del usuario.
  String get nombreVisible {
    if (nombreCompleto.trim().isNotEmpty) {
      return nombreCompleto.trim();
    }

    final String nombre = '$nombres $apellidos'.trim();

    if (nombre.isNotEmpty) {
      return nombre;
    }

    return nombreUsuario;
  }

  /// Crea una copia del usuario.
  UsuarioModel copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? nombreCompleto,
    String? nombreUsuario,
    String? numeroDocumento,
    String? tipoDocumento,
    String? correo,
    String? telefono,
    bool? debeCambiarPassword,
    DateTime? ultimoAcceso,
    int? institucionId,
    int? sedeId,
    int? areaId,
    bool? activo,
    List<RolModel>? roles,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      debeCambiarPassword: debeCambiarPassword ?? this.debeCambiarPassword,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      institucionId: institucionId ?? this.institucionId,
      sedeId: sedeId ?? this.sedeId,
      areaId: areaId ?? this.areaId,
      activo: activo ?? this.activo,
      roles: roles ?? this.roles,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  static List<RolModel> _rolesDesdeJson(dynamic data) {
    if (data is! List) {
      return <RolModel>[];
    }

    return data
        .whereType<Map>()
        .map((Map elemento) {
          return RolModel.fromJson(Map<String, dynamic>.from(elemento));
        })
        .where((RolModel rol) => rol.id > 0)
        .toList();
  }

  static String _obtenerNombreCompleto(Map<String, dynamic> json) {
    final String nombreCompleto = _toString(
      json['nombreCompleto'] ?? json['NombreCompleto'],
    );

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    final String nombres = _toString(json['nombres'] ?? json['Nombres']);

    final String apellidos = _toString(json['apellidos'] ?? json['Apellidos']);

    return '$nombres $apellidos'.trim();
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
        mapa['usuarios'],
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

  static int? _toNullableInt(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    final String texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return int.tryParse(texto);
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
