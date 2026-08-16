import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/sync_constants.dart';
import '../../core/services/secure_storage_service.dart';
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
/// - Crear una matriz offline.
/// - Actualizar una matriz offline.
/// - Eliminar una matriz offline.
/// - Consultar matrices locales.
/// - Consultar matrices pendientes.
/// - Registrar operaciones en la cola de sincronización.
///
/// Cuando el dispositivo recupera conexión, SyncService procesa
/// las operaciones pendientes y las envía al backend.
/// ===============================================================
class MatrizIpercOfflineRepository {
  MatrizIpercOfflineRepository({
    MatrizIpercLocalDatasource? matrizDatasource,
    SyncQueueLocalDatasource? syncQueueDatasource,
    SecureStorageService? secureStorageService,
  }) : _matrizDatasource = matrizDatasource ?? MatrizIpercLocalDatasource(),
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource(),
       _secureStorageService =
           secureStorageService ?? SecureStorageService.instance;

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final MatrizIpercLocalDatasource _matrizDatasource;

  final SyncQueueLocalDatasource _syncQueueDatasource;

  final SecureStorageService _secureStorageService;

  final Uuid _uuid = const Uuid();

  // =============================================================
  // CREAR MATRIZ OFFLINE
  // =============================================================

  /// Crea una nueva matriz IPERC en SQLite.
  ///
  /// La matriz queda marcada como no sincronizada y se agrega
  /// automáticamente una operación CREAR a la cola.
  Future<MatrizIpercLocalModel> createOffline({
    required String institucionId,
    required String sedeId,
    required String areaId,
    required String puestoTrabajoId,
    required String procesoId,
    required String actividadId,
    String? codigo,
    required String nombre,
    String? descripcion,
    required DateTime fechaEvaluacion,
  }) async {
    // -----------------------------------------------------------
    // VALIDAR DATOS ORGANIZACIONALES
    // -----------------------------------------------------------

    final String institucion = _validarIdTexto(institucionId, 'institución');

    final String sede = _validarIdTexto(sedeId, 'sede');

    final String area = _validarIdTexto(areaId, 'área');

    final String puesto = _validarIdTexto(puestoTrabajoId, 'puesto de trabajo');

    final String proceso = _validarIdTexto(procesoId, 'proceso');

    final String actividad = _validarIdTexto(actividadId, 'actividad');

    // -----------------------------------------------------------
    // VALIDAR NOMBRE
    // -----------------------------------------------------------

    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre de la matriz IPERC es obligatorio.');
    }

    if (nombreLimpio.length < 5) {
      throw ArgumentError('El nombre debe tener al menos 5 caracteres.');
    }

    // -----------------------------------------------------------
    // OBTENER USUARIO AUTENTICADO
    // -----------------------------------------------------------

    final int usuarioRegistroId = await _obtenerUsuarioAutenticadoId();

    final DateTime ahora = DateTime.now().toUtc();

    // -----------------------------------------------------------
    // CREAR MODELO LOCAL
    // -----------------------------------------------------------

    final MatrizIpercLocalModel matriz = MatrizIpercLocalModel(
      idLocal: _uuid.v4(),

      idServidor: null,

      institucionId: institucion,

      sedeId: sede,

      areaId: area,

      procesoId: proceso,

      actividadId: actividad,

      puestoTrabajoId: puesto,

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
    // GUARDAR EN SQLITE
    // -----------------------------------------------------------

    await _matrizDatasource.insert(matriz);

    // -----------------------------------------------------------
    // PREPARAR INFORMACIÓN DE SINCRONIZACIÓN
    // -----------------------------------------------------------

    final Map<String, dynamic> datosCola = Map<String, dynamic>.from(
      matriz.toMap(),
    );

    // El usuario que realmente creó la matriz queda almacenado
    // junto con la operación.
    datosCola['usuarioRegistroId'] = usuarioRegistroId;

    // -----------------------------------------------------------
    // AGREGAR OPERACIÓN CREAR
    // -----------------------------------------------------------

    await _agregarOperacionCola(
      matriz: matriz,
      operacion: SyncConstants.crear,
      datosPersonalizados: datosCola,
    );

    return matriz;
  }

  // =============================================================
  // ACTUALIZAR MATRIZ OFFLINE
  // =============================================================

  /// Actualiza una matriz almacenada localmente.
  ///
  /// Puede tratarse de:
  ///
  /// - una matriz creada completamente offline;
  /// - una matriz que anteriormente ya fue sincronizada.
  ///
  /// Después de modificarla queda nuevamente como pendiente.
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
  }) async {
    // -----------------------------------------------------------
    // VALIDAR ID LOCAL
    // -----------------------------------------------------------

    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    // -----------------------------------------------------------
    // BUSCAR MATRIZ
    // -----------------------------------------------------------

    final MatrizIpercLocalModel? existente = await _matrizDatasource.getById(
      localId,
    );

    if (existente == null) {
      throw StateError('No se encontró la matriz local que desea actualizar.');
    }

    if (existente.eliminado) {
      throw StateError('No se puede actualizar una matriz eliminada.');
    }

    // -----------------------------------------------------------
    // VALIDAR DATOS ORGANIZACIONALES
    // -----------------------------------------------------------

    final String institucion = _validarIdTexto(institucionId, 'institución');

    final String sede = _validarIdTexto(sedeId, 'sede');

    final String area = _validarIdTexto(areaId, 'área');

    final String puesto = _validarIdTexto(puestoTrabajoId, 'puesto de trabajo');

    final String proceso = _validarIdTexto(procesoId, 'proceso');

    final String actividad = _validarIdTexto(actividadId, 'actividad');

    // -----------------------------------------------------------
    // VALIDAR NOMBRE
    // -----------------------------------------------------------

    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre de la matriz IPERC es obligatorio.');
    }

    if (nombreLimpio.length < 5) {
      throw ArgumentError('El nombre debe tener al menos 5 caracteres.');
    }

    // -----------------------------------------------------------
    // OBTENER USUARIO AUTENTICADO
    // -----------------------------------------------------------

    final int usuarioActualizacionId = await _obtenerUsuarioAutenticadoId();

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

      // Cualquier modificación vuelve a dejarla pendiente.
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
    // PREPARAR DATOS DE LA COLA
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

  /// Realiza eliminación lógica de la matriz en SQLite.
  ///
  /// Si la matriz ya existe en MySQL, SyncService enviará DELETE.
  ///
  /// Si fue creada y eliminada sin haberse sincronizado nunca,
  /// no existe registro remoto que eliminar.
  Future<void> deleteOffline({required String idLocal}) async {
    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    // -----------------------------------------------------------
    // OBTENER MATRIZ
    // -----------------------------------------------------------

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
    // OBTENER USUARIO AUTENTICADO
    // -----------------------------------------------------------

    final int usuarioEliminacionId = await _obtenerUsuarioAutenticadoId();

    // -----------------------------------------------------------
    // PREPARAR DATOS ANTES DE ELIMINAR
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
    // AGREGAR DELETE A LA COLA
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
  // OBTENER ID DEL SERVIDOR
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
  // AGREGAR OPERACIÓN A LA COLA
  // =============================================================

  Future<void> _agregarOperacionCola({
    required MatrizIpercLocalModel matriz,
    required String operacion,
    Map<String, dynamic>? datosPersonalizados,
  }) async {
    final String operacionLimpia = operacion.trim().toUpperCase();

    if (operacionLimpia.isEmpty) {
      throw ArgumentError('La operación de sincronización es obligatoria.');
    }

    final DateTime ahora = DateTime.now().toUtc();

    final Map<String, dynamic> datos = datosPersonalizados != null
        ? Map<String, dynamic>.from(datosPersonalizados)
        : Map<String, dynamic>.from(matriz.toMap());

    final SyncQueueModel queueItem = SyncQueueModel(
      entidad: SyncConstants.matrizIperc,

      entidadIdLocal: matriz.idLocal,

      operacion: operacionLimpia,

      datosJson: jsonEncode(datos),

      fechaCreacion: ahora,
    );

    await _syncQueueDatasource.insert(queueItem);
  }

  // =============================================================
  // OBTENER USUARIO AUTENTICADO
  // =============================================================

  /// Obtiene desde FlutterSecureStorage el ID del usuario que
  /// inició sesión.
  ///
  /// Nunca utiliza un ID fijo como 1.
  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String texto =
        (await _secureStorageService.getUsuarioId())?.trim() ?? '';

    if (texto.isEmpty) {
      throw StateError(
        'No se encontró el usuario autenticado. '
        'Inicie sesión nuevamente.',
      );
    }

    final int? usuarioId = int.tryParse(texto);

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'El identificador del usuario autenticado '
        'no es válido: $texto.',
      );
    }

    return usuarioId;
  }

  // =============================================================
  // VALIDAR ID
  // =============================================================

  String _validarIdTexto(String value, String nombre) {
    final String texto = value.trim();

    if (texto.isEmpty) {
      throw ArgumentError('Debe seleccionar $nombre.');
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw ArgumentError(
        'El identificador de $nombre '
        'no es válido: $texto.',
      );
    }

    return id.toString();
  }

  // =============================================================
  // TEXTO OPCIONAL
  // =============================================================

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
