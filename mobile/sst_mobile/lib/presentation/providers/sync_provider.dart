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

  SyncStatus get status => _status;
  bool get isConnected => _isConnected;
  int get pendingCount => _pendingCount;
  String? get message => _message;

  bool get isSynchronizing => _status == SyncStatus.synchronizing;

  /// Inicializa el monitoreo de red.
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

  /// Actualiza conexión y cantidad de registros pendientes.
  Future<void> refreshStatus() async {
    try {
      _isConnected = await _networkInfo.isConnected;
      _pendingCount = await _queueDatasource.countPending();

      if (!_isConnected) {
        _status = SyncStatus.offline;
        _message = 'Sin conexión. Los datos se guardarán en el dispositivo.';
      } else if (_status != SyncStatus.synchronizing) {
        _status = SyncStatus.idle;
        _message = _pendingCount > 0
            ? 'Hay $_pendingCount registro(s) pendiente(s).'
            : 'Todos los registros están sincronizados.';
      }

      notifyListeners();
    } catch (error) {
      _status = SyncStatus.error;
      _message = 'No se pudo consultar el estado: $error';
      notifyListeners();
    }
  }

  /// Se ejecuta cuando cambia el estado de internet.
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

  /// Sincroniza manual o automáticamente.
  Future<void> synchronize() async {
    if (_status == SyncStatus.synchronizing) {
      return;
    }

    _isConnected = await _networkInfo.isConnected;

    if (!_isConnected) {
      _status = SyncStatus.offline;
      _message = 'No hay internet. Los registros siguen guardados localmente.';
      notifyListeners();
      return;
    }

    _status = SyncStatus.synchronizing;
    _message = 'Sincronizando registros pendientes...';
    notifyListeners();

    try {
      final SyncResult result = await _syncService.synchronizePending();

      _pendingCount = await _queueDatasource.countPending();

      if (result.withoutConnection) {
        _status = SyncStatus.offline;
        _message = 'No hay conexión disponible.';
      } else if (result.failed > 0) {
        _status = SyncStatus.error;
        _message =
            'Sincronizados: ${result.synchronized}. '
            'Errores: ${result.failed}.';
      } else {
        _status = SyncStatus.completed;
        _message = result.total == 0
            ? 'No hay registros pendientes.'
            : '${result.synchronized} registro(s) sincronizado(s).';
      }
    } catch (error) {
      _status = SyncStatus.error;
      _message = 'Error durante la sincronización: $error';
    }

    notifyListeners();
  }

  /// Se llama después de crear o modificar un registro local.
  Future<void> notifyLocalChange() async {
    _pendingCount = await _queueDatasource.countPending();
    notifyListeners();

    if (_isConnected && _pendingCount > 0) {
      await synchronize();
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
