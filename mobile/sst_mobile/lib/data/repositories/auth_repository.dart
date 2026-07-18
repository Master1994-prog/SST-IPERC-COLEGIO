import '../../core/services/secure_storage_service.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/login_response_model.dart';

class OfflineSession {
  const OfflineSession({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.rol,
  });

  final String usuarioId;
  final String nombreUsuario;
  final String rol;
}

class AuthRepository {
  AuthRepository({
    AuthRemoteDatasource? remoteDatasource,
    SecureStorageService? secureStorage,
  }) : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
       _secureStorage = secureStorage ?? SecureStorageService.instance;

  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageService _secureStorage;

  Future<LoginResponseModel> login({
    required String usuario,
    required String password,
  }) async {
    final LoginResponseModel response = await _remoteDatasource.login(
      usuario: usuario,
      password: password,
    );

    await _secureStorage.saveSession(
      token: response.token,
      usuarioId: response.usuarioId,
      nombreUsuario: response.nombreUsuario,
      rol: response.rol,
      expiraEn: response.expiraEn,
    );

    return response;
  }

  Future<OfflineSession?> getOfflineSession() async {
    final bool existe = await _secureStorage.hasOfflineSession();

    if (!existe) {
      return null;
    }

    final String? usuarioId = await _secureStorage.getUsuarioId();

    final String? nombreUsuario = await _secureStorage.getNombreUsuario();

    final String? rol = await _secureStorage.getRol();

    if (usuarioId == null || nombreUsuario == null || rol == null) {
      return null;
    }

    return OfflineSession(
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      rol: rol,
    );
  }

  Future<void> logout() {
    return _secureStorage.clearSession();
  }
}
