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
/// Administra las matrices IPERC almacenadas en SQLite.
///
/// Operaciones soportadas:
///
/// - Crear offline.
/// - Editar offline.
/// - Eliminar offline.
/// - Consultar matrices.
/// - Consultar pendientes.
/// - Agregar operaciones a la cola de sincronización.
///
/// Las operaciones pendientes serán procesadas posteriormente por
/// SyncService cuando vuelva la conexión.
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
    final String institucion = institucionId.trim();

    if (institucion.isEmpty) {
      throw ArgumentError('La institución es obligatoria.');
    }

    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre de la matriz IPERC es obligatorio.');
    }

    if (nombreLimpio.length < 5) {
      throw ArgumentError('El nombre debe tener al menos 5 caracteres.');
    }

    final DateTime ahora = DateTime.now().toUtc();

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

      fechaEvaluacion: fechaEvaluacion.toUtc(),

      estadoMatriz: 'BORRADOR',

      sincronizado: false,

      eliminado: false,

      fechaRegistro: ahora,

      fechaActualizacion: null,

      fechaSincronizacion: null,
    );

    // -----------------------------------------------------------
    // GUARDAR SQLITE
    // -----------------------------------------------------------

    await _matrizDatasource.insert(matriz);

    // -----------------------------------------------------------
    // AGREGAR CREAR A LA COLA
    // -----------------------------------------------------------

    await _agregarOperacionCola(matriz: matriz, operacion: SyncConstants.crear);

    return matriz;
  }

  // =============================================================
  // ACTUALIZAR MATRIZ OFFLINE
  // =============================================================

  /// Actualiza una matriz almacenada en SQLite.
  ///
  /// Puede utilizarse tanto para una matriz:
  ///
  /// - creada completamente offline;
  /// - como para una matriz que ya tenga idServidor.
  ///
  /// La operación queda registrada como ACTUALIZAR.
  Future<MatrizIpercLocalModel> updateOffline({
    required String idLocal,

    required String institucionId,

    required String sedeId,

    required String areaId,

    required String puestoTrabajoId,

    required String procesoId,

    required String actividadId,

    required String nombre,

    String? descripcion,

    String? codigo,

    DateTime? fechaEvaluacion,

    String estadoMatriz = 'BORRADOR',

    int usuarioActualizacionId = 1,
  }) async {
    // -----------------------------------------------------------
    // VALIDACIONES
    // -----------------------------------------------------------

    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    final MatrizIpercLocalModel? existente = await _matrizDatasource.getById(
      localId,
    );

    if (existente == null) {
      throw StateError('No se encontró la matriz local que desea actualizar.');
    }

    if (existente.eliminado) {
      throw StateError('No se puede actualizar una matriz eliminada.');
    }

    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre de la matriz IPERC es obligatorio.');
    }

    if (nombreLimpio.length < 5) {
      throw ArgumentError('El nombre debe tener al menos 5 caracteres.');
    }

    if (usuarioActualizacionId <= 0) {
      throw ArgumentError('El usuario que actualiza la matriz es obligatorio.');
    }

    final String institucion = institucionId.trim();

    final String sede = sedeId.trim();

    final String area = areaId.trim();

    final String puesto = puestoTrabajoId.trim();

    final String proceso = procesoId.trim();

    final String actividad = actividadId.trim();

    if (institucion.isEmpty ||
        sede.isEmpty ||
        area.isEmpty ||
        puesto.isEmpty ||
        proceso.isEmpty ||
        actividad.isEmpty) {
      throw ArgumentError(
        'Debe seleccionar todos los datos organizacionales obligatorios.',
      );
    }

    final DateTime ahora = DateTime.now().toUtc();

    // -----------------------------------------------------------
    // CREAR NUEVA VERSIÓN LOCAL
    // -----------------------------------------------------------

    final MatrizIpercLocalModel actualizada = MatrizIpercLocalModel(
      idLocal: existente.idLocal,

      idServidor: existente.idServidor,

      institucionId: institucion,

      sedeId: sede,

      areaId: area,

      procesoId: proceso,

      actividadId: actividad,

      puestoTrabajoId: puesto,

      codigo: _textoOpcional(codigo) ?? existente.codigo,

      nombre: nombreLimpio,

      descripcion: _textoOpcional(descripcion),

      fechaEvaluacion: fechaEvaluacion?.toUtc() ?? existente.fechaEvaluacion,

      estadoMatriz: estadoMatriz.trim().isEmpty
          ? existente.estadoMatriz
          : estadoMatriz.trim(),

      // Cada edición genera un cambio pendiente.
      sincronizado: false,

      eliminado: false,

      fechaRegistro: existente.fechaRegistro,

      fechaActualizacion: ahora,

      fechaSincronizacion: existente.fechaSincronizacion,
    );

    // -----------------------------------------------------------
    // ACTUALIZAR SQLITE
    // -----------------------------------------------------------

    await _matrizDatasource.update(actualizada);

    // -----------------------------------------------------------
    // DATOS PARA SINCRONIZACIÓN
    // -----------------------------------------------------------

    final Map<String, dynamic> datosCola = Map<String, dynamic>.from(
      actualizada.toMap(),
    );

    datosCola['usuarioActualizacionId'] = usuarioActualizacionId;

    // -----------------------------------------------------------
    // AGREGAR ACTUALIZAR A LA COLA
    // -----------------------------------------------------------

    await _agregarOperacionCola(
      matriz: actualizada,
      operacion: SyncConstants.actualizar,
      datosPersonalizados: datosCola,
    );

    return actualizada;
  }

  // =============================================================
  // ELIMINAR MATRIZ OFFLINE
  // =============================================================

  /// Realiza eliminación lógica en SQLite.
  ///
  /// La matriz desaparece del listado normal, pero permanece
  /// almacenada para poder sincronizar posteriormente el DELETE.
  Future<void> deleteOffline({
    required String idLocal,

    int usuarioEliminacionId = 1,
  }) async {
    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    if (usuarioEliminacionId <= 0) {
      throw ArgumentError('El usuario que elimina la matriz es obligatorio.');
    }

    final MatrizIpercLocalModel? matriz = await _matrizDatasource.getById(
      localId,
    );

    if (matriz == null) {
      throw StateError('No se encontró la matriz local que desea eliminar.');
    }

    if (matriz.eliminado) {
      return;
    }

    // -----------------------------------------------------------
    // PREPARAR DATOS ANTES DE MARCARLA ELIMINADA
    // -----------------------------------------------------------

    final Map<String, dynamic> datosCola = Map<String, dynamic>.from(
      matriz.toMap(),
    );

    datosCola['usuarioEliminacionId'] = usuarioEliminacionId;

    // -----------------------------------------------------------
    // ELIMINACIÓN LÓGICA SQLITE
    // -----------------------------------------------------------

    await _matrizDatasource.deleteLogical(localId);

    // -----------------------------------------------------------
    // AGREGAR DELETE A COLA
    // -----------------------------------------------------------

    await _agregarOperacionCola(
      matriz: matriz,
      operacion: SyncConstants.eliminar,
      datosPersonalizados: datosCola,
    );
  }

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  Future<List<MatrizIpercLocalModel>> getAll() {
    return _matrizDatasource.getAll();
  }

  // =============================================================
  // OBTENER PENDIENTES
  // =============================================================

  Future<List<MatrizIpercLocalModel>> getPending() {
    return _matrizDatasource.getPendingSynchronization();
  }

  // =============================================================
  // OBTENER POR ID LOCAL
  // =============================================================

  Future<MatrizIpercLocalModel?> getByLocalId(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    return _matrizDatasource.getById(id);
  }

  // =============================================================
  // OBTENER ID SERVIDOR
  // =============================================================

  Future<int?> getServerId(String idLocal) {
    return _matrizDatasource.getServerId(idLocal);
  }

  // =============================================================
  // SABER SI ESTÁ SINCRONIZADA
  // =============================================================

  Future<bool> isSynchronized(String idLocal) {
    return _matrizDatasource.isSynchronized(idLocal);
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> countPending() async {
    final List<MatrizIpercLocalModel> pendientes = await getPending();

    return pendientes.length;
  }

  // =============================================================
  // AGREGAR OPERACIÓN A COLA
  // =============================================================

  Future<void> _agregarOperacionCola({
    required MatrizIpercLocalModel matriz,

    required String operacion,

    Map<String, dynamic>? datosPersonalizados,
  }) async {
    final DateTime ahora = DateTime.now().toUtc();

    final Map<String, dynamic> datos = datosPersonalizados ?? matriz.toMap();

    final SyncQueueModel queueItem = SyncQueueModel(
      entidad: SyncConstants.matrizIperc,

      entidadIdLocal: matriz.idLocal,

      operacion: operacion,

      datosJson: jsonEncode(datos),

      fechaCreacion: ahora,
    );

    await _syncQueueDatasource.insert(queueItem);
  }

  // =============================================================
  // TEXTO OPCIONAL
  // =============================================================

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
