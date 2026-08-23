import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const String _accessTokenKey = 'access_token';
  static const String _usuarioIdKey = 'usuario_id';
  static const String _nombreUsuarioKey = 'nombre_usuario';
  static const String _rolKey = 'rol';
  static const String _expiraEnKey = 'expira_en';
  static const String _sesionOfflineKey = 'sesion_offline';
  static const String _debeCambiarPasswordKey = 'debe_cambiar_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    required String usuarioId,
    required String nombreUsuario,
    required String rol,
    required bool debeCambiarPassword,
    DateTime? expiraEn,
  }) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _accessTokenKey, value: token),
      _storage.write(key: _usuarioIdKey, value: usuarioId),
      _storage.write(key: _nombreUsuarioKey, value: nombreUsuario),
      _storage.write(key: _rolKey, value: rol),
      _storage.write(key: _expiraEnKey, value: expiraEn?.toIso8601String()),
      _storage.write(key: _sesionOfflineKey, value: 'true'),
    ]);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getUsuarioId() {
    return _storage.read(key: _usuarioIdKey);
  }

  Future<String?> getNombreUsuario() {
    return _storage.read(key: _nombreUsuarioKey);
  }

  Future<String?> getRol() {
    return _storage.read(key: _rolKey);
  }

  Future<DateTime?> getExpiraEn() async {
    final String? value = await _storage.read(key: _expiraEnKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<bool> getDebeCambiarPassword() async {
    final String? value = await _storage.read(key: _debeCambiarPasswordKey);

    return value == 'true';
  }

  Future<void> setDebeCambiarPassword(bool value) {
    return _storage.write(
      key: _debeCambiarPasswordKey,
      value: value ? 'true' : 'false',
    );
  }

  Future<bool> hasOfflineSession() async {
    final String? sesion = await _storage.read(key: _sesionOfflineKey);

    final String? usuarioId = await getUsuarioId();
    final String? nombreUsuario = await getNombreUsuario();
    final String? rol = await getRol();

    return sesion == 'true' &&
        usuarioId != null &&
        usuarioId.isNotEmpty &&
        nombreUsuario != null &&
        nombreUsuario.isNotEmpty &&
        rol != null &&
        rol.isNotEmpty;
  }

  Future<void> clearSession() {
    return _storage.deleteAll();
  }
}
