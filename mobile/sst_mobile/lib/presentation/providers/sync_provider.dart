import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/network_info.dart';
import '../../core/services/sync_service.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';

enum SyncStatus { idle, offline, synchronizing, completed, error }

class SyncProvider extends ChangeNotifier {
  SyncProvider({
    NetworkInfo? networkInfo,
    SyncService? syncService,
    SyncQueueLocalDatasource? queueDatasource,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncService = syncService ?? SyncService(),
       _queueDatasource = queueDatasource ?? SyncQueueLocalDatasource();

  final NetworkInfo _networkInfo;

  final SyncService _syncService;

  final SyncQueueLocalDatasource _queueDatasource;

  StreamSubscription<bool>? _connectionSubscription;

  SyncStatus _status = SyncStatus.idle;

  bool _isConnected = false;

  int _pendingCount = 0;

  String? _message;

  String? _lastError;

  // =============================================================
  // GETTERS
  // =============================================================

  SyncStatus get status => _status;

  bool get isConnected => _isConnected;

  int get pendingCount => _pendingCount;

  String? get message => _message;

  String? get lastError => _lastError;

  bool get isSynchronizing => _status == SyncStatus.synchronizing;

  bool get hasError =>
      _status == SyncStatus.error ||
      (_lastError != null && _lastError!.trim().isNotEmpty);

  // =============================================================
  // INICIALIZAR
  // =============================================================

  Future<void> initialize() async {
    await refreshStatus();

    await _connectionSubscription?.cancel();

    _connectionSubscription = _networkInfo.connectionChanges.listen(
      _handleConnectionChange,
    );

    if (_isConnected && _pendingCount > 0) {
      await synchronize();
    }
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

        _message =
            'Sin conexión. Los datos permanecen guardados en el dispositivo.';
      } else if (_status != SyncStatus.synchronizing) {
        if (_lastError != null) {
          _status = SyncStatus.error;

          _message = 'Hay un error de sincronización:\n$_lastError';
        } else {
          _status = SyncStatus.idle;

          _message = _pendingCount > 0
              ? 'Hay $_pendingCount registro(s) pendiente(s) de sincronización.'
              : 'Todos los registros están sincronizados.';
        }
      }

      notifyListeners();
    } catch (error) {
      _status = SyncStatus.error;

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

      _message = 'Se perdió la conexión. Se continuará en modo offline.';

      notifyListeners();

      return;
    }

    _message = 'Conexión recuperada.';

    notifyListeners();

    await refreshStatus();

    if (_pendingCount > 0) {
      await synchronize();
    }
  }

  // =============================================================
  // SINCRONIZAR
  // =============================================================

  Future<void> synchronize() async {
    if (_status == SyncStatus.synchronizing) {
      return;
    }

    _isConnected = await _networkInfo.isConnected;

    if (!_isConnected) {
      _status = SyncStatus.offline;

      _message = 'No hay conexión. Los registros siguen guardados localmente.';

      notifyListeners();

      return;
    }

    // -----------------------------------------------------------
    // Los registros que anteriormente fallaron vuelven a
    // PENDIENTE para permitir un nuevo intento.
    // -----------------------------------------------------------

    await _queueDatasource.resetErrorsToPending();

    _status = SyncStatus.synchronizing;

    _lastError = null;

    _message = 'Sincronizando registros pendientes...';

    notifyListeners();

    try {
      final SyncResult result = await _syncService.synchronizePending();

      _pendingCount = await _queueDatasource.countPending();

      _lastError = await _queueDatasource.getLastError();

      if (result.withoutConnection) {
        _status = SyncStatus.offline;

        _message = 'La conexión se perdió durante la sincronización.';

        notifyListeners();

        return;
      }

      if (result.failed > 0) {
        _status = SyncStatus.error;

        if (_lastError != null) {
          _message = 'Error de sincronización:\n$_lastError';
        } else {
          _message =
              'Sincronizados: ${result.synchronized}. '
              'Errores: ${result.failed}.';
        }

        notifyListeners();

        return;
      }

      _status = SyncStatus.completed;

      _lastError = null;

      _message = result.total == 0
          ? 'No hay registros pendientes.'
          : '${result.synchronized} registro(s) sincronizado(s) correctamente.';
    } catch (error) {
      _status = SyncStatus.error;

      _lastError = error.toString();

      _message = 'Error durante la sincronización:\n$error';
    }

    notifyListeners();
  }

  // =============================================================
  // CAMBIO LOCAL
  // =============================================================

  Future<void> notifyLocalChange() async {
    _pendingCount = await _queueDatasource.countPending();

    notifyListeners();

    if (_isConnected && _pendingCount > 0) {
      await synchronize();
    }
  }

  // =============================================================
  // REINTENTAR
  // =============================================================

  Future<void> retrySynchronization() async {
    await _queueDatasource.resetErrorsToPending();

    await synchronize();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _connectionSubscription?.cancel();

    super.dispose();
  }
}
