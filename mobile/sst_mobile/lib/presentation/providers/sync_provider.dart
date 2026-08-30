import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/network_info.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';

enum SyncStatus { idle, offline, synchronizing, completed, error }

/// ===============================================================
/// SYNC PROVIDER - SST EDURISK
/// ===============================================================
///
/// La regla principal de esta versión es:
///
/// - NetworkInfo decide si el backend es alcanzable.
/// - SecureStorage decide si existe un JWT para una sesión online.
/// - El backend sigue siendo la autoridad final sobre la validez del JWT.
/// - Después de un login correcto se fuerza un reintento de la cola.
/// ===============================================================
class SyncProvider extends ChangeNotifier {
  SyncProvider({
    NetworkInfo? networkInfo,
    SyncService? syncService,
    SyncQueueLocalDatasource? queueDatasource,
    SecureStorageService? secureStorageService,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncService = syncService ?? SyncService(),
       _queueDatasource = queueDatasource ?? SyncQueueLocalDatasource(),
       _secureStorageService =
           secureStorageService ?? SecureStorageService.instance;

  final NetworkInfo _networkInfo;
  final SyncService _syncService;
  final SyncQueueLocalDatasource _queueDatasource;
  final SecureStorageService _secureStorageService;

  StreamSubscription<bool>? _connectionSubscription;

  SyncStatus _status = SyncStatus.idle;
  bool _isConnected = false;
  int _pendingCount = 0;
  String? _message;
  String? _lastError;

  bool _initialized = false;
  bool _autoSyncInProgress = false;

  SyncStatus get status => _status;
  bool get isConnected => _isConnected;
  int get pendingCount => _pendingCount;
  String? get message => _message;
  String? get lastError => _lastError;
  bool get isSynchronizing => _status == SyncStatus.synchronizing;

  bool get hasError =>
      _status == SyncStatus.error ||
      (_lastError != null && _lastError!.trim().isNotEmpty);

  Future<bool> _hasOnlineToken() async {
    final String token =
        (await _secureStorageService.getAccessToken())?.trim() ?? '';

    return token.isNotEmpty;
  }

  // =============================================================
  // INICIALIZAR
  // =============================================================

  Future<void> initialize() async {
    if (!_initialized) {
      await _queueDatasource.recoverInterruptedSynchronizations();
      _initialized = true;
    }

    await refreshStatus();

    await _connectionSubscription?.cancel();

    _connectionSubscription = _networkInfo.connectionChanges.listen(
      (bool connected) {
        unawaited(_handleConnectionChange(connected));
      },
      onError: (Object error, StackTrace stackTrace) {
        _status = SyncStatus.error;
        _lastError = error.toString();
        _message = 'No se pudo comprobar la conexión con el servidor.';
        notifyListeners();
      },
    );

    await _tryAutoSynchronize();
  }

  // =============================================================
  // ACTUALIZAR ESTADO
  // =============================================================

  Future<void> refreshStatus() async {
    try {
      _isConnected = await _networkInfo.isConnected;
      _pendingCount = await _queueDatasource.countPending();
      _lastError = await _queueDatasource.getLastError();

      if (!_isConnected) {
        _status = SyncStatus.offline;
        _message = _pendingCount > 0
            ? 'Servidor no disponible. Hay $_pendingCount registro(s) '
                  'guardado(s) en el dispositivo.'
            : 'Servidor no disponible. La aplicación continuará '
                  'en modo offline.';
      } else if (_status != SyncStatus.synchronizing) {
        final bool hayToken = await _hasOnlineToken();

        if (!hayToken && _pendingCount > 0) {
          _status = SyncStatus.idle;
          _lastError = null;
          _message =
              'Hay $_pendingCount registro(s) pendiente(s). '
              'Inicia sesión online para sincronizarlos.';
        } else if (_lastError != null && _lastError!.trim().isNotEmpty) {
          _status = SyncStatus.error;
          _message = 'Hay un error de sincronización:\n$_lastError';
        } else {
          _status = SyncStatus.idle;
          _message = _pendingCount > 0
              ? 'Servidor disponible. Hay $_pendingCount registro(s) '
                    'pendiente(s) de sincronización.'
              : 'Todos los registros están sincronizados.';
        }
      }

      notifyListeners();
    } catch (error) {
      _status = SyncStatus.error;
      _lastError = error.toString();
      _message = 'No se pudo consultar el estado de sincronización: $error';
      notifyListeners();
    }
  }

  // =============================================================
  // CAMBIO DE CONEXIÓN
  // =============================================================

  Future<void> _handleConnectionChange(bool connected) async {
    _isConnected = connected;

    if (!connected) {
      _status = SyncStatus.offline;
      _pendingCount = await _queueDatasource.countPending();

      _message = _pendingCount > 0
          ? 'Se perdió la conexión con el servidor. '
                'Hay $_pendingCount registro(s) guardado(s) localmente.'
          : 'Se perdió la conexión con el servidor. '
                'Se continuará en modo offline.';

      notifyListeners();
      return;
    }

    await refreshStatus();
    await _tryAutoSynchronize();
  }

  // =============================================================
  // AUTO SYNC
  // =============================================================

  Future<void> _tryAutoSynchronize() async {
    if (_autoSyncInProgress || isSynchronizing) {
      return;
    }

    _autoSyncInProgress = true;

    try {
      _isConnected = await _networkInfo.isConnected;
      _pendingCount = await _queueDatasource.countPending();

      if (!_isConnected || _pendingCount <= 0) {
        return;
      }

      final bool hayToken = await _hasOnlineToken();

      if (!hayToken) {
        _status = SyncStatus.idle;
        _lastError = null;
        _message =
            'Hay $_pendingCount registro(s) pendiente(s). '
            'Inicia sesión online para sincronizarlos.';
        notifyListeners();
        return;
      }

      await synchronize();
    } finally {
      _autoSyncInProgress = false;
    }
  }

  // =============================================================
  // SINCRONIZAR
  // =============================================================

  Future<void> synchronize() async {
    if (isSynchronizing) {
      return;
    }

    _isConnected = await _networkInfo.isConnected;

    if (!_isConnected) {
      _pendingCount = await _queueDatasource.countPending();
      _status = SyncStatus.offline;
      _message =
          'No se puede contactar al servidor. '
          'Los registros siguen guardados localmente.';
      notifyListeners();
      return;
    }

    _pendingCount = await _queueDatasource.countPending();

    if (_pendingCount <= 0) {
      _status = SyncStatus.completed;
      _lastError = null;
      _message = 'No hay registros pendientes.';
      notifyListeners();
      return;
    }

    final bool hayToken = await _hasOnlineToken();

    if (!hayToken) {
      _status = SyncStatus.idle;
      _lastError = null;
      _message =
          'Hay $_pendingCount registro(s) pendiente(s). '
          'Inicia sesión online para sincronizarlos.';
      notifyListeners();
      return;
    }

    // Rehabilitar cualquier operación que falló con el JWT anterior.
    await _queueDatasource.resetErrorsToPending();

    _status = SyncStatus.synchronizing;
    _lastError = null;
    _message = 'Sincronizando $_pendingCount registro(s) pendientes...';
    notifyListeners();

    try {
      final SyncResult result = await _syncService.synchronizePending();

      _pendingCount = await _queueDatasource.countPending();
      _lastError = await _queueDatasource.getLastError();

      if (result.withoutConnection) {
        _isConnected = false;
        _status = SyncStatus.offline;
        _message =
            'Se perdió la conexión con el servidor durante '
            'la sincronización. Los registros no enviados '
            'permanecen en el dispositivo.';
        notifyListeners();
        return;
      }

      if (result.failed > 0 || _pendingCount > 0) {
        _status = SyncStatus.error;

        if (_lastError != null && _lastError!.trim().isNotEmpty) {
          _message =
              'Sincronización incompleta. '
              'Quedan $_pendingCount registro(s).\n'
              '$_lastError';
        } else {
          _message =
              'Sincronizados: ${result.synchronized}. '
              'Errores: ${result.failed}. '
              'Pendientes: $_pendingCount.';
        }

        notifyListeners();
        return;
      }

      _status = SyncStatus.completed;
      _lastError = null;
      _message =
          '${result.synchronized} registro(s) sincronizado(s) correctamente.';
    } catch (error) {
      _pendingCount = await _queueDatasource.countPending();
      _lastError = await _queueDatasource.getLastError();

      _status = SyncStatus.error;
      _lastError ??= error.toString();
      _message = 'Error durante la sincronización:\n$_lastError';
    }

    notifyListeners();
  }

  // =============================================================
  // CAMBIO LOCAL
  // =============================================================

  Future<void> notifyLocalChange() async {
    await refreshStatus();

    if (_isConnected && _pendingCount > 0 && !isSynchronizing) {
      await _tryAutoSynchronize();
    }
  }

  // =============================================================
  // DESPUÉS DEL LOGIN
  // =============================================================

  /// Este método debe ejecutarse inmediatamente después de un login
  /// ONLINE exitoso. Restablece ERROR -> PENDIENTE y procesa la cola
  /// con el JWT recién guardado.
  Future<void> synchronizeAfterLogin() async {
    if (isSynchronizing) {
      return;
    }

    final bool hayToken = await _hasOnlineToken();

    if (!hayToken) {
      await refreshStatus();
      return;
    }

    await _queueDatasource.resetErrorsToPending();
    await refreshStatus();

    if (_isConnected && _pendingCount > 0) {
      await synchronize();
    }
  }

  Future<void> refreshAndSynchronize() async {
    await refreshStatus();
    await _tryAutoSynchronize();
  }

  Future<void> retrySynchronization() async {
    if (isSynchronizing) {
      return;
    }

    await _queueDatasource.resetErrorsToPending();
    await refreshStatus();

    if (_isConnected && _pendingCount > 0) {
      await synchronize();
    }
  }

  void clearError() {
    _lastError = null;

    if (_status == SyncStatus.error) {
      _status = _isConnected ? SyncStatus.idle : SyncStatus.offline;
    }

    _message = _isConnected
        ? (_pendingCount > 0
              ? 'Hay $_pendingCount registro(s) pendiente(s) '
                    'de sincronización.'
              : 'Todos los registros están sincronizados.')
        : 'Servidor no disponible. Los datos permanecen '
              'guardados en el dispositivo.';

    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
