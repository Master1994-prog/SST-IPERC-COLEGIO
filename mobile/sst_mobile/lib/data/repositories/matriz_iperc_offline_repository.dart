import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/sync_constants.dart';
import '../datasources/local/matriz_iperc_local_datasource.dart';
import '../datasources/local/sync_queue_local_datasource.dart';
import '../models/matriz_iperc_local_model.dart';
import '../models/sync_queue_model.dart';

class MatrizIpercOfflineRepository {
  MatrizIpercOfflineRepository({
    MatrizIpercLocalDatasource? matrizDatasource,
    SyncQueueLocalDatasource? syncQueueDatasource,
  }) : _matrizDatasource = matrizDatasource ?? MatrizIpercLocalDatasource(),
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource();

  final MatrizIpercLocalDatasource _matrizDatasource;
  final SyncQueueLocalDatasource _syncQueueDatasource;

  final Uuid _uuid = const Uuid();

  Future<MatrizIpercLocalModel> createOffline({
    required String institucionId,
    String? areaId,
    String? procesoId,
    String? puestoTrabajoId,
    String? codigo,
    required String nombre,
    String? descripcion,
    required DateTime fechaEvaluacion,
  }) async {
    final DateTime now = DateTime.now();

    final MatrizIpercLocalModel matriz = MatrizIpercLocalModel(
      idLocal: _uuid.v4(),
      institucionId: institucionId,
      areaId: areaId,
      procesoId: procesoId,
      puestoTrabajoId: puestoTrabajoId,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      fechaEvaluacion: fechaEvaluacion,
      fechaRegistro: now,
      sincronizado: false,
    );

    await _matrizDatasource.insert(matriz);

    final SyncQueueModel queueItem = SyncQueueModel(
      entidad: SyncConstants.matrizIperc,
      entidadIdLocal: matriz.idLocal,
      operacion: SyncConstants.crear,
      datosJson: jsonEncode(matriz.toMap()),
      fechaCreacion: now,
    );

    await _syncQueueDatasource.insert(queueItem);

    return matriz;
  }

  Future<List<MatrizIpercLocalModel>> getAll() {
    return _matrizDatasource.getAll();
  }

  Future<List<MatrizIpercLocalModel>> getPending() {
    return _matrizDatasource.getPendingSynchronization();
  }
}
