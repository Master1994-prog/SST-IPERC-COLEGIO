import 'dart:async';

import '../../core/services/iperc_catalog_preload_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/login_response_model.dart';

/// ===============================================================
/// SESIÓN OFFLINE
/// ===============================================================
class OfflineSession {
  const OfflineSession({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.rol,
    required this.debeCambiarPassword,
  });

  final String usuarioId;
  final String nombreUsuario;
  final String rol;

  final bool debeCambiarPassword;
}

/// ===============================================================
/// REPOSITORIO DE AUTENTICACIÓN
/// ===============================================================
///
/// Además de autenticar al usuario:
///
/// 1. Guarda la sesión segura.
/// 2. Inicia silenciosamente la precarga de catálogos IPERC.
///
/// La precarga NO bloquea el ingreso a la aplicación.
/// ===============================================================
class AuthRepository {
  AuthRepository({
    AuthRemoteDatasource? remoteDatasource,
    SecureStorageService? secureStorage,
    IpercCatalogPreloadService? catalogPreloadService,
  }) : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
       _secureStorage = secureStorage ?? SecureStorageService.instance,
       _catalogPreloadService =
           catalogPreloadService ?? IpercCatalogPreloadService();

  final AuthRemoteDatasource _remoteDatasource;

  final SecureStorageService _secureStorage;

  final IpercCatalogPreloadService _catalogPreloadService;

  // =============================================================
  // LOGIN ONLINE
  // =============================================================

  Future<LoginResponseModel> login({
    required String usuario,
    required String password,
  }) async {
    // -----------------------------------------------------------
    // AUTENTICAR CONTRA EL BACKEND
    // -----------------------------------------------------------

    final LoginResponseModel response = await _remoteDatasource.login(
      usuario: usuario,
      password: password,
    );

    // -----------------------------------------------------------
    // GUARDAR SESIÓN ANTES DE CUALQUIER OTRA LLAMADA API
    // -----------------------------------------------------------
    //
    // De esta forma ApiClient ya puede recuperar el token para
    // descargar los catálogos protegidos.
    // -----------------------------------------------------------

    await _secureStorage.saveSession(
      token: response.token,
      usuarioId: response.usuarioId,
      nombreUsuario: response.nombreUsuario,
      rol: response.rol,
      debeCambiarPassword: response.debeCambiarPassword,
      expiraEn: response.expiraEn,
    );

    // -----------------------------------------------------------
    // PRECARGA AUTOMÁTICA DE CATÁLOGOS IPERC
    // -----------------------------------------------------------
    //
    // No usamos await porque:
    //
    // - No queremos retrasar la apertura de la pantalla principal.
    // - La descarga puede seguir ejecutándose en segundo plano
    //   mientras el usuario entra al sistema.
    //
    // El propio servicio captura los errores individuales de cada
    // catálogo y conserva la última copia SQLite válida.
    // -----------------------------------------------------------

    if (!response.debeCambiarPassword) {
      unawaited(_precargarCatalogosSilenciosamente());
    }

    return response;
  }

  // =============================================================
  // PRECARGA SILENCIOSA
  // =============================================================

  Future<void> _precargarCatalogosSilenciosamente() async {
    try {
      await _catalogPreloadService.preload();
    } catch (_) {
      // El login ya fue correcto.
      // Un fallo de precarga nunca debe cerrar ni impedir la sesión.
    }
  }

  // =============================================================
  // SESIÓN OFFLINE
  // =============================================================

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

    final bool debeCambiarPassword = await _secureStorage
        .getDebeCambiarPassword();

    return OfflineSession(
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      rol: rol,
      debeCambiarPassword: debeCambiarPassword,
    );
  }

  // =============================================================
  // SOLICITAR ACCESO
  // =============================================================

  Future<String> solicitarAcceso({
    required String nombres,
    required String apellidos,
    required String correo,
    required String institucion,
    String? cargo,
    String? motivo,
  }) {
    return _remoteDatasource.solicitarAcceso(
      nombres: nombres,
      apellidos: apellidos,
      correo: correo,
      institucion: institucion,
      cargo: cargo,
      motivo: motivo,
    );
  }

  // =============================================================
  // RECUPERAR CONTRASEÑA
  // =============================================================

  Future<String> recuperarPassword({required String identificador}) {
    return _remoteDatasource.recuperarPassword(identificador: identificador);
  }

  // =============================================================
  // LOGOUT
  // =============================================================

  Future<void> logout() {
    return _secureStorage.clearSession();
  }

  Future<String> cambiarPasswordPropio({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    final String mensaje = await _remoteDatasource.cambiarPasswordPropio(
      passwordActual: passwordActual,
      nuevaPassword: nuevaPassword,
      confirmarPassword: confirmarPassword,
    );

    await _secureStorage.setDebeCambiarPassword(false);

    unawaited(_precargarCatalogosSilenciosamente());

    return mensaje;
  }
}
