import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ===============================================================
/// SECURE STORAGE SERVICE - SST EDURISK
/// ===============================================================
///
/// Separa dos conceptos:
///
/// 1. SESIÓN ACTIVA
///    Token JWT y datos utilizados mientras el usuario está conectado.
///
/// 2. ACCESO OFFLINE AUTORIZADO
///    Identidad mínima del último usuario habilitado para trabajar
///    sin conexión.
///
/// De esta manera "Cerrar sesión" elimina el JWT, pero NO elimina
/// automáticamente el acceso offline autorizado.
/// ===============================================================
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // =============================================================
  // CLAVES DE SESIÓN ACTIVA
  // =============================================================

  static const String _accessTokenKey = 'access_token';

  static const String _usuarioIdKey = 'usuario_id';

  static const String _nombreUsuarioKey = 'nombre_usuario';

  static const String _rolKey = 'rol';

  static const String _expiraEnKey = 'expira_en';

  static const String _debeCambiarPasswordKey = 'debe_cambiar_password';

  // =============================================================
  // CLAVES DE ACCESO OFFLINE
  // =============================================================

  static const String _offlineHabilitadoKey = 'offline_habilitado';

  static const String _offlineUsuarioIdKey = 'offline_usuario_id';

  static const String _offlineNombreUsuarioKey = 'offline_nombre_usuario';

  static const String _offlineRolKey = 'offline_rol';

  static const String _offlineDebeCambiarPasswordKey =
      'offline_debe_cambiar_password';

  // =============================================================
  // GUARDAR SESIÓN ACTIVA
  // =============================================================

  Future<void> saveSession({
    required String token,
    required String usuarioId,
    required String nombreUsuario,
    required String rol,
    required bool debeCambiarPassword,
    DateTime? expiraEn,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _storage.write(key: _accessTokenKey, value: token),
      _storage.write(key: _usuarioIdKey, value: usuarioId),
      _storage.write(key: _nombreUsuarioKey, value: nombreUsuario),
      _storage.write(key: _rolKey, value: rol),
      _storage.write(key: _expiraEnKey, value: expiraEn?.toIso8601String()),
      _storage.write(
        key: _debeCambiarPasswordKey,
        value: debeCambiarPassword ? 'true' : 'false',
      ),
    ]);
  }

  // =============================================================
  // LECTURA DE SESIÓN ACTIVA
  // =============================================================

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

    if (value == null || value.trim().isEmpty) {
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

  // =============================================================
  // GUARDAR ACCESO OFFLINE
  // =============================================================

  Future<void> saveOfflineSession({
    required String usuarioId,
    required String nombreUsuario,
    required String rol,
    required bool debeCambiarPassword,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _storage.write(key: _offlineHabilitadoKey, value: 'true'),
      _storage.write(key: _offlineUsuarioIdKey, value: usuarioId),
      _storage.write(key: _offlineNombreUsuarioKey, value: nombreUsuario),
      _storage.write(key: _offlineRolKey, value: rol),
      _storage.write(
        key: _offlineDebeCambiarPasswordKey,
        value: debeCambiarPassword ? 'true' : 'false',
      ),
    ]);
  }

  Future<String?> getOfflineUsuarioId() {
    return _storage.read(key: _offlineUsuarioIdKey);
  }

  Future<String?> getOfflineNombreUsuario() {
    return _storage.read(key: _offlineNombreUsuarioKey);
  }

  Future<String?> getOfflineRol() {
    return _storage.read(key: _offlineRolKey);
  }

  Future<bool> getOfflineDebeCambiarPassword() async {
    final String? value = await _storage.read(
      key: _offlineDebeCambiarPasswordKey,
    );

    return value == 'true';
  }

  Future<bool> hasOfflineSession() async {
    final List<String?> values = await Future.wait<String?>(<Future<String?>>[
      _storage.read(key: _offlineHabilitadoKey),
      getOfflineUsuarioId(),
      getOfflineNombreUsuario(),
      getOfflineRol(),
    ]);

    final String? habilitado = values[0];
    final String? usuarioId = values[1];
    final String? nombreUsuario = values[2];
    final String? rol = values[3];

    return habilitado == 'true' &&
        usuarioId != null &&
        usuarioId.trim().isNotEmpty &&
        nombreUsuario != null &&
        nombreUsuario.trim().isNotEmpty &&
        rol != null &&
        rol.trim().isNotEmpty;
  }

  // =============================================================
  // HABILITAR OFFLINE DESDE LA SESIÓN ACTUAL
  // =============================================================

  Future<bool> habilitarOfflineDesdeSesionActual() async {
    final String? usuarioId = await getUsuarioId();

    final String? nombreUsuario = await getNombreUsuario();

    final String? rol = await getRol();

    if (usuarioId == null ||
        usuarioId.trim().isEmpty ||
        nombreUsuario == null ||
        nombreUsuario.trim().isEmpty ||
        rol == null ||
        rol.trim().isEmpty) {
      return false;
    }

    await saveOfflineSession(
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      rol: rol,
      debeCambiarPassword: false,
    );

    return true;
  }

  // =============================================================
  // CERRAR SOLO SESIÓN ACTIVA
  // =============================================================

  /// Elimina el token y los datos de la sesión activa.
  ///
  /// NO elimina el acceso offline previamente autorizado.
  Future<void> clearCurrentSession() async {
    await Future.wait<void>(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _usuarioIdKey),
      _storage.delete(key: _nombreUsuarioKey),
      _storage.delete(key: _rolKey),
      _storage.delete(key: _expiraEnKey),
      _storage.delete(key: _debeCambiarPasswordKey),
    ]);
  }

  /// Alias de compatibilidad.
  ///
  /// Desde ahora clearSession() equivale a cerrar la sesión activa,
  /// NO a borrar todo FlutterSecureStorage.
  Future<void> clearSession() {
    return clearCurrentSession();
  }

  // =============================================================
  // ELIMINAR ACCESO OFFLINE
  // =============================================================

  Future<void> clearOfflineSession() async {
    await Future.wait<void>(<Future<void>>[
      _storage.delete(key: _offlineHabilitadoKey),
      _storage.delete(key: _offlineUsuarioIdKey),
      _storage.delete(key: _offlineNombreUsuarioKey),
      _storage.delete(key: _offlineRolKey),
      _storage.delete(key: _offlineDebeCambiarPasswordKey),
    ]);
  }

  // =============================================================
  // BORRADO TOTAL
  // =============================================================

  /// Utilizar únicamente cuando se quiera desvincular por completo
  /// el dispositivo.
  Future<void> clearAll() {
    return _storage.deleteAll();
  }
}
