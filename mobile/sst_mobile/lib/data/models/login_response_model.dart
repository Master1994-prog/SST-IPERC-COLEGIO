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

  /// Rol principal utilizado por la navegación y los permisos visuales.
  ///
  /// IMPORTANTE:
  /// Ya no se toma simplemente roles.first.
  /// Se selecciona el rol con mayor privilegio.
  final String rol;

  /// Lista completa de roles recibidos desde el backend.
  final List<String> roles;

  final String institucionId;
  final String? sedeId;
  final String? areaId;

  final bool debeCambiarPassword;

  factory LoginResponseModel.fromMap(Map<String, dynamic> map) {
    final dynamic usuarioData = map['usuario'];

    if (usuarioData is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta no contiene los datos del usuario.',
      );
    }

    final List<String> roles = _obtenerRoles(usuarioData['roles']);

    return LoginResponseModel(
      token: map['token']?.toString() ?? '',
      expiraEn: DateTime.tryParse(map['expiraEn']?.toString() ?? ''),
      usuarioId: usuarioData['id']?.toString() ?? '',
      nombreUsuario: usuarioData['nombreUsuario']?.toString() ?? '',
      nombres: usuarioData['nombres']?.toString() ?? '',
      apellidos: usuarioData['apellidos']?.toString() ?? '',
      correo: usuarioData['correo']?.toString(),

      // ==========================================================
      // CORRECCIÓN:
      // Se determina el rol principal por prioridad.
      // Si el usuario tiene SUPER_ADMIN en cualquier posición,
      // ese será siempre el rol utilizado por la navegación.
      // ==========================================================
      rol: _obtenerRolPrincipal(roles),

      roles: roles,
      institucionId: usuarioData['institucionId']?.toString() ?? '',
      sedeId: usuarioData['sedeId']?.toString(),
      areaId: usuarioData['areaId']?.toString(),
      debeCambiarPassword: usuarioData['debeCambiarPassword'] == true,
    );
  }

  /// Convierte la respuesta de roles en una lista de texto.
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
  ///
  /// 1. SUPER_ADMIN
  /// 2. ADMIN
  /// 3. SUP_TITULAR
  /// 4. SUP_SUPLENTE
  /// 5. COORDINADOR
  ///
  /// Así, aunque SUPER_ADMIN sea el segundo o tercer rol recibido
  /// desde el backend, seguirá teniendo acceso administrativo total.
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

    // Si llega un rol no contemplado todavía,
    // se conserva el primero para no bloquear el ingreso.
    return roles.first;
  }

  /// Normaliza nombres y códigos de rol.
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
}
