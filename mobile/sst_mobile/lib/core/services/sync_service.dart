import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';
import '../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../data/models/sync_queue_model.dart';
import '../constants/sync_constants.dart';
import '../network/network_info.dart';

class SyncResult {
  const SyncResult({
    required this.total,
    required this.synchronized,
    required this.failed,
    required this.withoutConnection,
  });

  final int total;
  final int synchronized;
  final int failed;
  final bool withoutConnection;
}

class SyncService {
  SyncService({
    NetworkInfo? networkInfo,
    SyncQueueLocalDatasource? syncQueueDatasource,
    MatrizIpercLocalDatasource? matrizLocalDatasource,
    MatrizIpercRemoteDatasource? matrizRemoteDatasource,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource(),
       _matrizLocalDatasource =
           matrizLocalDatasource ?? MatrizIpercLocalDatasource(),
       _matrizRemoteDatasource =
           matrizRemoteDatasource ?? MatrizIpercRemoteDatasource();

  final NetworkInfo _networkInfo;
  final SyncQueueLocalDatasource _syncQueueDatasource;
  final MatrizIpercLocalDatasource _matrizLocalDatasource;
  final MatrizIpercRemoteDatasource _matrizRemoteDatasource;

  bool _isSynchronizing = false;

  bool get isSynchronizing => _isSynchronizing;

  Future<SyncResult> synchronizePending() async {
    if (_isSynchronizing) {
      return const SyncResult(
        total: 0,
        synchronized: 0,
        failed: 0,
        withoutConnection: false,
      );
    }

    final bool connected = await _networkInfo.isConnected;

    if (!connected) {
      return const SyncResult(
        total: 0,
        synchronized: 0,
        failed: 0,
        withoutConnection: true,
      );
    }

    _isSynchronizing = true;

    int synchronized = 0;
    int failed = 0;

    try {
      final List<SyncQueueModel> pendingItems = await _syncQueueDatasource
          .getPending();

      for (final SyncQueueModel item in pendingItems) {
        final int? queueId = item.id;

        if (queueId == null) {
          failed++;
          continue;
        }

        try {
          await _syncQueueDatasource.markAsSynchronizing(queueId);

          await _processItem(item);

          await _syncQueueDatasource.markAsSynchronized(queueId);

          synchronized++;
        } catch (error) {
          failed++;

          await _syncQueueDatasource.markAsError(
            id: queueId,
            error: _getErrorMessage(error),
            numeroIntentos: item.numeroIntentos + 1,
          );
        }
      }

      return SyncResult(
        total: pendingItems.length,
        synchronized: synchronized,
        failed: failed,
        withoutConnection: false,
      );
    } finally {
      _isSynchronizing = false;
    }
  }

  Future<void> _processItem(SyncQueueModel item) async {
    final Map<String, dynamic> data =
        jsonDecode(item.datosJson) as Map<String, dynamic>;

    if (item.entidad == SyncConstants.matrizIperc &&
        item.operacion == SyncConstants.crear) {
      await _createMatrix(item, data);
      return;
    }

    throw UnsupportedError(
      'No existe sincronización para '
      '${item.entidad} - ${item.operacion}.',
    );
  }

  Future<void> _createMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    final Map<String, dynamic> apiData = _transformMatrixForApi(localData);

    final String serverId = await _matrizRemoteDatasource.create(apiData);

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: item.entidadIdLocal,
      idServidor: serverId,
    );
  }

  Map<String, dynamic> _transformMatrixForApi(Map<String, dynamic> localData) {
    return <String, dynamic>{
      'institucionId': localData['institucion_id'],
      'areaId': localData['area_id'],
      'procesoId': localData['proceso_id'],
      'puestoTrabajoId': localData['puesto_trabajo_id'],
      'codigo': localData['codigo'],
      'nombre': localData['nombre'],
      'descripcion': localData['descripcion'],
      'fechaEvaluacion': localData['fecha_evaluacion'],
      'estadoMatriz': localData['estado_matriz'],
      'idLocal': localData['id_local'],
    };
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final dynamic responseData = error.response?.data;

      if (responseData != null) {
        return responseData.toString();
      }

      return error.message ?? 'Error de comunicación con el servidor.';
    }

    return error.toString();
  }
}
