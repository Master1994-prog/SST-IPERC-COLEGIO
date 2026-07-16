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

  final String rol;
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
      rol: roles.isNotEmpty ? roles.first : 'Sin rol',
      roles: roles,
      institucionId: usuarioData['institucionId']?.toString() ?? '',
      sedeId: usuarioData['sedeId']?.toString(),
      areaId: usuarioData['areaId']?.toString(),
      debeCambiarPassword: usuarioData['debeCambiarPassword'] == true,
    );
  }

  static List<String> _obtenerRoles(dynamic value) {
    if (value is List) {
      return value
          .where((dynamic item) => item != null)
          .map((dynamic item) => item.toString())
          .where((String item) => item.isNotEmpty)
          .toList();
    }

    return <String>[];
  }
}
