import 'dart:async';

import '../../core/services/iperc_catalog_preload_service.dart';
import '../../core/services/offline_credential_service.dart';
import '../../core/services/organizacion_catalog_preload_service.dart';
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
/// AUTH REPOSITORY - SST EDURISK
/// ===============================================================
///
/// Separa:
/// - sesión activa online;
/// - acceso offline autorizado.
///
/// Además, después de un login online válido prepara SQLite para:
/// - catálogos IPERC: peligros, consecuencias, probabilidad, severidad;
/// - catálogos organizacionales: instituciones, sedes, áreas,
///   puestos de trabajo, procesos y actividades.
///
/// De esta manera "Nueva matriz IPERC" puede abrirse sin Internet
/// después de haber realizado al menos un login online correcto.
/// ===============================================================
class AuthRepository {
  AuthRepository({
    AuthRemoteDatasource? remoteDatasource,
    SecureStorageService? secureStorage,
    IpercCatalogPreloadService? catalogPreloadService,
    OrganizacionCatalogPreloadService? organizacionCatalogPreloadService,
    OfflineCredentialService? offlineCredentialService,
  }) : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
       _secureStorage = secureStorage ?? SecureStorageService.instance,
       _catalogPreloadService =
           catalogPreloadService ?? IpercCatalogPreloadService(),
       _organizacionCatalogPreloadService =
           organizacionCatalogPreloadService ??
           OrganizacionCatalogPreloadService(),
       _offlineCredentialService =
           offlineCredentialService ?? OfflineCredentialService();

  final AuthRemoteDatasource _remoteDatasource;

  final SecureStorageService _secureStorage;

  final IpercCatalogPreloadService _catalogPreloadService;

  final OrganizacionCatalogPreloadService _organizacionCatalogPreloadService;

  final OfflineCredentialService _offlineCredentialService;

  // =============================================================
  // LOGIN ONLINE
  // =============================================================

  Future<LoginResponseModel> login({
    required String usuario,
    required String password,
  }) async {
    final LoginResponseModel response = await _remoteDatasource.login(
      usuario: usuario,
      password: password,
    );

    // -----------------------------------------------------------
    // SESIÓN ACTIVA
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
    // AUTORIZACIÓN OFFLINE
    // -----------------------------------------------------------

    if (response.debeCambiarPassword) {
      // Contraseña temporal o sesión 30:
      // no se permite reutilizar una autorización offline anterior.
      await _secureStorage.clearOfflineSession();

      await _offlineCredentialService.eliminarPasswordOffline();
    } else {
      // Login online válido:
      // renovamos la identidad y el verificador offline.
      await _secureStorage.saveOfflineSession(
        usuarioId: response.usuarioId,
        nombreUsuario: response.nombreUsuario,
        rol: response.rol,
        debeCambiarPassword: false,
      );

      await _offlineCredentialService.guardarPasswordOffline(password);

      // Esperamos la precarga antes de finalizar el login.
      // Esto garantiza que, al cortar Internet inmediatamente después,
      // los catálogos necesarios ya estén persistidos en SQLite.
      await _precargarCatalogosSilenciosamente();
    }

    return response;
  }

  // =============================================================
  // PRECARGA OFFLINE
  // =============================================================

  Future<void> _precargarCatalogosSilenciosamente() async {
    try {
      await Future.wait<bool>(<Future<bool>>[
        _catalogPreloadService.preload(),
        _organizacionCatalogPreloadService.preload(),
      ]);
    } catch (_) {
      // La precarga nunca debe impedir el ingreso del usuario.
      // Si una rama falla, el formulario seguirá usando la última
      // copia SQLite válida que exista.
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

    final String? usuarioId = await _secureStorage.getOfflineUsuarioId();

    final String? nombreUsuario = await _secureStorage
        .getOfflineNombreUsuario();

    final String? rol = await _secureStorage.getOfflineRol();

    if (usuarioId == null ||
        usuarioId.trim().isEmpty ||
        nombreUsuario == null ||
        nombreUsuario.trim().isEmpty ||
        rol == null ||
        rol.trim().isEmpty) {
      return null;
    }

    final bool debeCambiarPassword = await _secureStorage
        .getOfflineDebeCambiarPassword();

    return OfflineSession(
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      rol: rol,
      debeCambiarPassword: debeCambiarPassword,
    );
  }

  Future<bool> validarPasswordOffline({required String password}) {
    return _offlineCredentialService.validarPasswordOffline(password);
  }

  Future<bool> tieneAccesoOffline() async {
    final bool tieneSesion = await _secureStorage.hasOfflineSession();

    if (!tieneSesion) {
      return false;
    }

    return _offlineCredentialService.tienePasswordOffline();
  }

  // =============================================================
  // ELIMINAR ACCESO OFFLINE
  // =============================================================

  Future<void> eliminarAccesoOffline() async {
    await _secureStorage.clearOfflineSession();

    await _offlineCredentialService.eliminarPasswordOffline();
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
  // CAMBIAR CONTRASEÑA PROPIA
  // =============================================================

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

    // Backend:
    // DebeCambiarPassword = false
    // SesionesDesdeCambioPassword = 0
    await _secureStorage.setDebeCambiarPassword(false);

    // Si el acceso offline fue eliminado al llegar a la sesión 30,
    // lo volvemos a habilitar con la nueva contraseña.
    final bool sesionDisponible = await _secureStorage
        .habilitarOfflineDesdeSesionActual();

    if (sesionDisponible) {
      await _offlineCredentialService.guardarPasswordOffline(nuevaPassword);
    }

    // Aquí sí puede ejecutarse en segundo plano porque el usuario ya
    // tiene la sesión iniciada.
    unawaited(_precargarCatalogosSilenciosamente());

    return mensaje;
  }

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  /// Cierra únicamente la sesión activa.
  ///
  /// Conserva el acceso offline autorizado.
  Future<void> logout() {
    return _secureStorage.clearCurrentSession();
  }

  // =============================================================
  // DESVINCULAR DISPOSITIVO
  // =============================================================

  /// Elimina tanto la sesión activa como el acceso offline.
  Future<void> desvincularDispositivo() async {
    await _offlineCredentialService.eliminarPasswordOffline();

    await _secureStorage.clearAll();
  }
}
