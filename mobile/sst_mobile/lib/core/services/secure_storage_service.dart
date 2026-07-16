import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const String _accessTokenKey = 'access_token';
  static const String _usuarioIdKey = 'usuario_id';
  static const String _nombreUsuarioKey = 'nombre_usuario';
  static const String _rolKey = 'rol';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    required String usuarioId,
    required String nombreUsuario,
    required String rol,
  }) async {
    await _storage.write(key: _accessTokenKey, value: token);

    await _storage.write(key: _usuarioIdKey, value: usuarioId);

    await _storage.write(key: _nombreUsuarioKey, value: nombreUsuario);

    await _storage.write(key: _rolKey, value: rol);
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

  Future<void> clearSession() {
    return _storage.deleteAll();
  }
}
