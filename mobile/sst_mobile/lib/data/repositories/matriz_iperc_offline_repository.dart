import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/sync_constants.dart';
import '../datasources/local/matriz_iperc_local_datasource.dart';
import '../datasources/local/sync_queue_local_datasource.dart';
import '../models/matriz_iperc_local_model.dart';
import '../models/sync_queue_model.dart';

/// ===============================================================
/// REPOSITORIO OFFLINE - MATRIZ IPERC
/// ===============================================================
///
/// Administra matrices IPERC almacenadas localmente.
///
/// Cuando no existe conexión:
///
/// 1. Crea la matriz en SQLite.
/// 2. La marca como no sincronizada.
/// 3. Agrega una operación a la cola.
/// 4. Cuando vuelve internet, SyncService la envía al backend.
/// ===============================================================
class MatrizIpercOfflineRepository {
  MatrizIpercOfflineRepository({
    MatrizIpercLocalDatasource? matrizDatasource,
    SyncQueueLocalDatasource? syncQueueDatasource,
  }) : _matrizDatasource = matrizDatasource ?? MatrizIpercLocalDatasource(),
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource();

  final MatrizIpercLocalDatasource _matrizDatasource;

  final SyncQueueLocalDatasource _syncQueueDatasource;

  final Uuid _uuid = const Uuid();

  // =============================================================
  // CREAR MATRIZ OFFLINE
  // =============================================================

  Future<MatrizIpercLocalModel> createOffline({
    required String institucionId,

    String? sedeId,

    String? areaId,

    String? procesoId,

    String? actividadId,

    String? puestoTrabajoId,

    String? codigo,

    required String nombre,

    String? descripcion,

    required DateTime fechaEvaluacion,
  }) async {
    // -----------------------------------------------------------
    // VALIDACIONES
    // -----------------------------------------------------------

    final String institucion = institucionId.trim();

    if (institucion.isEmpty) {
      throw ArgumentError('La institución es obligatoria.');
    }

    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre de la matriz IPERC es obligatorio.');
    }

    final DateTime ahora = DateTime.now().toUtc();

    // -----------------------------------------------------------
    // CREAR MODELO LOCAL
    // -----------------------------------------------------------

    final MatrizIpercLocalModel matriz = MatrizIpercLocalModel(
      idLocal: _uuid.v4(),

      idServidor: null,

      institucionId: institucion,

      sedeId: _textoOpcional(sedeId),

      areaId: _textoOpcional(areaId),

      procesoId: _textoOpcional(procesoId),

      actividadId: _textoOpcional(actividadId),

      puestoTrabajoId: _textoOpcional(puestoTrabajoId),

      codigo: _textoOpcional(codigo),

      nombre: nombreLimpio,

      descripcion: _textoOpcional(descripcion),

      fechaEvaluacion: fechaEvaluacion,

      estadoMatriz: 'BORRADOR',

      sincronizado: false,

      eliminado: false,

      fechaRegistro: ahora,

      fechaActualizacion: null,

      fechaSincronizacion: null,
    );

    // -----------------------------------------------------------
    // GUARDAR EN SQLITE
    // -----------------------------------------------------------

    await _matrizDatasource.insert(matriz);

    // -----------------------------------------------------------
    // AGREGAR A COLA DE SINCRONIZACIÓN
    // -----------------------------------------------------------

    final SyncQueueModel queueItem = SyncQueueModel(
      entidad: SyncConstants.matrizIperc,

      entidadIdLocal: matriz.idLocal,

      operacion: SyncConstants.crear,

      datosJson: jsonEncode(matriz.toMap()),

      fechaCreacion: ahora,
    );

    await _syncQueueDatasource.insert(queueItem);

    return matriz;
  }

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  Future<List<MatrizIpercLocalModel>> getAll() {
    return _matrizDatasource.getAll();
  }

  // =============================================================
  // PENDIENTES
  // =============================================================

  Future<List<MatrizIpercLocalModel>> getPending() {
    return _matrizDatasource.getPendingSynchronization();
  }

  // =============================================================
  // BUSCAR POR ID LOCAL
  // =============================================================

  Future<MatrizIpercLocalModel?> getByLocalId(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    final List<MatrizIpercLocalModel> matrices = await _matrizDatasource
        .getAll();

    for (final MatrizIpercLocalModel matriz in matrices) {
      if (matriz.idLocal == id) {
        return matriz;
      }
    }

    return null;
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> countPending() async {
    final List<MatrizIpercLocalModel> pendientes = await getPending();

    return pendientes.length;
  }

  // =============================================================
  // AUXILIAR
  // =============================================================

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
