/// ===============================================================
/// LOGIN RESPONSE MODEL - SST EDURISK
/// ===============================================================
///
/// Representa la respuesta de autenticación enviada por el backend.
///
/// Incluye la política de seguridad de contraseña:
/// - sesión 5, 10, 15, 20 y 25: recordatorio;
/// - sesión 30: cambio obligatorio;
/// - contraseña temporal: cambio obligatorio antes de ingresar.
/// ===============================================================
class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    required this.expiraEn,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    required this.roles,
    required this.institucionId,
    required this.debeCambiarPassword,
    required this.sesionesDesdeCambioPassword,
    required this.sesionesRestantesCambioPassword,
    required this.recordarCambioPassword,
    this.correo,
    this.sedeId,
    this.areaId,
  });

  final String token;
  final DateTime? expiraEn;

  final String usuarioId;
  final String nombreUsuario;
  final String nombres;
  final String apellidos;
  final String? correo;

  /// Rol principal usado por navegación y permisos visuales.
  final String rol;

  /// Lista completa de roles recibidos.
  final List<String> roles;

  final String institucionId;
  final String? sedeId;
  final String? areaId;

  /// Indica que el usuario no puede continuar sin cambiar su contraseña.
  final bool debeCambiarPassword;

  /// Sesiones online realizadas desde el último cambio válido.
  final int sesionesDesdeCambioPassword;

  /// Sesiones restantes hasta el límite de 30.
  final int sesionesRestantesCambioPassword;

  /// True en las sesiones 5, 10, 15, 20 y 25.
  final bool recordarCambioPassword;

  /// Cambio obligatorio por contraseña temporal.
  bool get esPasswordTemporal =>
      debeCambiarPassword && sesionesDesdeCambioPassword == 0;

  /// Cambio obligatorio por llegar a la sesión 30.
  bool get esCambioPorSesiones =>
      debeCambiarPassword && sesionesDesdeCambioPassword >= 30;

  /// Texto breve útil para UI.
  String get resumenSeguridad {
    if (esPasswordTemporal) {
      return 'Debe cambiar la contraseña temporal.';
    }

    if (esCambioPorSesiones) {
      return 'Alcanzó el límite de 30 sesiones.';
    }

    if (recordarCambioPassword) {
      return 'Recordatorio de cambio de contraseña.';
    }

    return 'Contraseña vigente.';
  }

  factory LoginResponseModel.fromMap(Map<String, dynamic> map) {
    final dynamic usuarioRaw = map['usuario'] ?? map['Usuario'];

    if (usuarioRaw is! Map) {
      throw const FormatException(
        'La respuesta no contiene los datos del usuario.',
      );
    }

    final Map<String, dynamic> usuarioData = Map<String, dynamic>.from(
      usuarioRaw,
    );

    final List<String> roles = _obtenerRoles(
      usuarioData['roles'] ?? usuarioData['Roles'],
    );

    final bool debeCambiarPassword = _toBool(
      usuarioData['debeCambiarPassword'] ?? usuarioData['DebeCambiarPassword'],
    );

    final int sesionesDesdeCambioPassword = _toInt(
      usuarioData['sesionesDesdeCambioPassword'] ??
          usuarioData['SesionesDesdeCambioPassword'],
    );

    int sesionesRestantesCambioPassword = _toInt(
      usuarioData['sesionesRestantesCambioPassword'] ??
          usuarioData['SesionesRestantesCambioPassword'],
      valorPredeterminado: (30 - sesionesDesdeCambioPassword).clamp(0, 30),
    );

    if (sesionesRestantesCambioPassword < 0) {
      sesionesRestantesCambioPassword = 0;
    }

    final bool recordarCambioPassword = _toBool(
      usuarioData['recordarCambioPassword'] ??
          usuarioData['RecordarCambioPassword'],
    );

    return LoginResponseModel(
      token: _toString(map['token'] ?? map['Token']),
      expiraEn: DateTime.tryParse(
        _toString(map['expiraEn'] ?? map['ExpiraEn']),
      ),
      usuarioId: _toString(usuarioData['id'] ?? usuarioData['Id']),
      nombreUsuario: _toString(
        usuarioData['nombreUsuario'] ?? usuarioData['NombreUsuario'],
      ),
      nombres: _toString(usuarioData['nombres'] ?? usuarioData['Nombres']),
      apellidos: _toString(
        usuarioData['apellidos'] ?? usuarioData['Apellidos'],
      ),
      correo: _toNullableString(usuarioData['correo'] ?? usuarioData['Correo']),
      rol: _obtenerRolPrincipal(roles),
      roles: roles,
      institucionId: _toString(
        usuarioData['institucionId'] ?? usuarioData['InstitucionId'],
      ),
      sedeId: _toNullableString(usuarioData['sedeId'] ?? usuarioData['SedeId']),
      areaId: _toNullableString(usuarioData['areaId'] ?? usuarioData['AreaId']),
      debeCambiarPassword: debeCambiarPassword,
      sesionesDesdeCambioPassword: sesionesDesdeCambioPassword,
      sesionesRestantesCambioPassword: sesionesRestantesCambioPassword,
      recordarCambioPassword: recordarCambioPassword,
    );
  }

  static List<String> _obtenerRoles(dynamic value) {
    if (value is List) {
      return value
          .where((dynamic item) => item != null)
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  /// =============================================================
  /// OBTENER ROL PRINCIPAL
  /// =============================================================
  ///
  /// Prioridad:
  /// 1. SUPER_ADMIN
  /// 2. ADMIN
  /// 3. SUP_TITULAR
  /// 4. SUP_SUPLENTE
  /// 5. COORDINADOR
  /// =============================================================
  static String _obtenerRolPrincipal(List<String> roles) {
    if (roles.isEmpty) {
      return 'Sin rol';
    }

    const List<String> prioridad = <String>[
      'SUPER_ADMIN',
      'ADMIN',
      'SUP_TITULAR',
      'SUP_SUPLENTE',
      'COORDINADOR',
    ];

    for (final String codigo in prioridad) {
      for (final String rol in roles) {
        if (_normalizarRol(rol) == codigo) {
          return codigo;
        }
      }
    }

    return _normalizarRol(roles.first);
  }

  static String _normalizarRol(String rol) {
    String value = rol.trim().toUpperCase();

    value = value
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (value) {
      case 'SUPER_ADMINISTRADOR':
      case 'SUPERADMIN':
      case 'SUPER_ADMIN':
        return 'SUPER_ADMIN';

      case 'ADMINISTRADOR':
      case 'ADMIN':
        return 'ADMIN';

      case 'SUPERVISOR_TITULAR':
      case 'SUP_TITULAR':
        return 'SUP_TITULAR';

      case 'SUPERVISOR_SUPLENTE':
      case 'SUP_SUPLENTE':
        return 'SUP_SUPLENTE';

      case 'COORDINADOR':
        return 'COORDINADOR';

      default:
        return value;
    }
  }

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _toNullableString(dynamic value) {
    final String texto = value?.toString().trim() ?? '';

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  static int _toInt(dynamic value, {int valorPredeterminado = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? valorPredeterminado;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String texto = value?.toString().trim().toLowerCase() ?? '';

    return <String>['true', '1', 'si', 'sí'].contains(texto);
  }
}
