import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';
import '../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/services/detalle_iperc_sync_service.dart';
import '../../data/services/seguimiento_iperc_sync_service.dart';
import '../../data/services/mapa_riesgo_sync_service.dart';
import '../constants/sync_constants.dart';
import '../network/network_info.dart';
import 'secure_storage_service.dart';

/// ===============================================================
/// RESULTADO DE SINCRONIZACIÓN
/// ===============================================================
class SyncResult {
  const SyncResult({
    required this.total,
    required this.synchronized,
    required this.failed,
    required this.withoutConnection,
  });

  /// Cantidad total de operaciones encontradas en la cola.
  final int total;

  /// Operaciones procesadas correctamente.
  final int synchronized;

  /// Operaciones que terminaron con error.
  final int failed;

  /// Indica que la sincronización no pudo continuar por falta de red.
  final bool withoutConnection;

  bool get successful {
    return !withoutConnection && failed == 0;
  }

  bool get partiallySuccessful {
    return synchronized > 0 && failed > 0;
  }
}

/// ===============================================================
/// SERVICIO GENERAL DE SINCRONIZACIÓN
/// ===============================================================
///
/// Procesa la cola:
///
/// `sincronizaciones_pendientes`
///
/// respetando las dependencias del modelo IPERC:
///
/// MATRIZ_IPERC
///      ↓
/// DETALLE_IPERC
///      ↓
/// SEGUIMIENTO_IPERC
///
/// La sincronización general es el único punto que debe recorrer la
/// cola completa. Los servicios especializados sincronizan únicamente
/// el registro que se les solicita.
/// ===============================================================
class SyncService {
  SyncService({
    NetworkInfo? networkInfo,
    SyncQueueLocalDatasource? syncQueueDatasource,
    MatrizIpercLocalDatasource? matrizLocalDatasource,
    MatrizIpercRemoteDatasource? matrizRemoteDatasource,
    DetalleIpercSyncService? detalleIpercSyncService,
    SeguimientoIpercSyncService? seguimientoIpercSyncService,
    MapaRiesgoSyncService? mapaRiesgoSyncService,
    SecureStorageService? secureStorageService,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource(),
       _matrizLocalDatasource =
           matrizLocalDatasource ?? MatrizIpercLocalDatasource(),
       _matrizRemoteDatasource =
           matrizRemoteDatasource ?? MatrizIpercRemoteDatasource(),
       _detalleIpercSyncService =
           detalleIpercSyncService ?? DetalleIpercSyncService(),
       _seguimientoIpercSyncService =
           seguimientoIpercSyncService ?? SeguimientoIpercSyncService(),
       _mapaRiesgoSyncService =
           mapaRiesgoSyncService ?? MapaRiesgoSyncService(),
       _secureStorageService =
           secureStorageService ?? SecureStorageService.instance;

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final NetworkInfo _networkInfo;

  final SyncQueueLocalDatasource _syncQueueDatasource;

  final MatrizIpercLocalDatasource _matrizLocalDatasource;

  final MatrizIpercRemoteDatasource _matrizRemoteDatasource;

  final DetalleIpercSyncService _detalleIpercSyncService;

  final SeguimientoIpercSyncService _seguimientoIpercSyncService;

  final MapaRiesgoSyncService _mapaRiesgoSyncService;

  final SecureStorageService _secureStorageService;

  // =============================================================
  // BLOQUEO GLOBAL
  // =============================================================
  //
  // Es static porque diferentes Providers pueden construir distintas
  // instancias de SyncService.
  //
  // IMPORTANTE:
  // El bloqueo se activa ANTES del primer await para evitar que dos
  // llamadas simultáneas superen la validación al mismo tiempo.
  // =============================================================

  static bool _globalSynchronizing = false;

  bool get isSynchronizing {
    return _globalSynchronizing;
  }

  // =============================================================
  // SINCRONIZAR PENDIENTES
  // =============================================================

  Future<SyncResult> synchronizePending() async {
    // -----------------------------------------------------------
    // EVITAR DOS SINCRONIZACIONES SIMULTÁNEAS
    // -----------------------------------------------------------

    if (_globalSynchronizing) {
      return const SyncResult(
        total: 0,
        synchronized: 0,
        failed: 0,
        withoutConnection: false,
      );
    }

    // El lock debe adquirirse antes de cualquier await.
    _globalSynchronizing = true;

    int synchronized = 0;
    int failed = 0;

    try {
      // ---------------------------------------------------------
      // COMPROBAR CONEXIÓN
      // ---------------------------------------------------------

      final bool connected = await _networkInfo.isConnected;

      if (!connected) {
        return const SyncResult(
          total: 0,
          synchronized: 0,
          failed: 0,
          withoutConnection: true,
        );
      }

      // ---------------------------------------------------------
      // LEER OPERACIONES PENDIENTES
      // ---------------------------------------------------------

      final List<SyncQueueModel> originales = await _syncQueueDatasource
          .getPending();

      final List<SyncQueueModel> pendingItems = List<SyncQueueModel>.from(
        originales,
      );

      // ---------------------------------------------------------
      // ORDENAR POR DEPENDENCIA
      // ---------------------------------------------------------

      pendingItems.sort(_compararOperaciones);

      // ---------------------------------------------------------
      // PROCESAR UNA POR UNA
      // ---------------------------------------------------------

      for (final SyncQueueModel item in pendingItems) {
        final int? queueId = item.id;

        if (queueId == null || queueId <= 0) {
          failed++;
          continue;
        }

        try {
          // -----------------------------------------------------
          // VALIDAR ESTRUCTURA DE LA OPERACIÓN
          // -----------------------------------------------------

          _validarOperacionCola(item);

          // -----------------------------------------------------
          // REVISAR CONEXIÓN ANTES DE CADA PETICIÓN
          // -----------------------------------------------------

          final bool sigueConectado = await _networkInfo.isConnected;

          if (!sigueConectado) {
            return SyncResult(
              total: pendingItems.length,
              synchronized: synchronized,
              failed: pendingItems.length - synchronized,
              withoutConnection: true,
            );
          }

          // -----------------------------------------------------
          // MARCAR EN PROCESO
          // -----------------------------------------------------

          await _syncQueueDatasource.markAsSynchronizing(queueId);

          // -----------------------------------------------------
          // EJECUTAR OPERACIÓN
          // -----------------------------------------------------

          await _processItem(item);

          // -----------------------------------------------------
          // CONFIRMAR COLA
          // -----------------------------------------------------

          await _syncQueueDatasource.markAsSynchronized(queueId);

          synchronized++;
        } catch (error) {
          failed++;

          // -----------------------------------------------------
          // REGISTRAR ERROR SIN ROMPER EL RESTO DE LA COLA
          // -----------------------------------------------------

          try {
            await _syncQueueDatasource.markAsError(
              id: queueId,
              error: _getErrorMessage(error),
              numeroIntentos: item.numeroIntentos + 1,
            );
          } catch (_) {
            // Si incluso guardar el error falla, continuamos con
            // las demás operaciones para no bloquear toda la cola.
          }
        }
      }

      return SyncResult(
        total: pendingItems.length,
        synchronized: synchronized,
        failed: failed,
        withoutConnection: false,
      );
    } finally {
      // ---------------------------------------------------------
      // SIEMPRE LIBERAR EL LOCK
      // ---------------------------------------------------------

      _globalSynchronizing = false;
    }
  }

  // =============================================================
  // ORDEN DE SINCRONIZACIÓN
  // =============================================================

  int _compararOperaciones(SyncQueueModel a, SyncQueueModel b) {
    final int prioridadA = _prioridadOperacion(a);
    final int prioridadB = _prioridadOperacion(b);

    final int porPrioridad = prioridadA.compareTo(prioridadB);

    if (porPrioridad != 0) {
      return porPrioridad;
    }

    final int porFecha = a.fechaCreacion.compareTo(b.fechaCreacion);

    if (porFecha != 0) {
      return porFecha;
    }

    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  /// Define el orden técnico de procesamiento.
  ///
  /// 10 = Crear matriz.
  /// 20 = Actualizar matriz.
  /// 30 = Detalles.
  /// 40 = Seguimientos.
  /// 50 = Eliminar matriz.
  ///
  /// Esto asegura que un seguimiento nunca se procese antes de que
  /// su Detalle IPERC padre tenga ID remoto.
  int _prioridadOperacion(SyncQueueModel item) {
    final String entidad = item.entidad.trim().toUpperCase();

    final String operacion = item.operacion.trim().toUpperCase();

    if (entidad == SyncConstants.matrizIperc &&
        operacion == SyncConstants.crear) {
      return 10;
    }

    if (entidad == SyncConstants.matrizIperc &&
        operacion == SyncConstants.actualizar) {
      return 20;
    }

    if (entidad == SyncConstants.detalleIperc) {
      return 30;
    }

    if (entidad == SyncConstants.seguimientoIperc) {
      return 40;
    }

    // El mapa depende de una Matriz IPERC ya sincronizada.
    // Se procesa antes de una eventual eliminación de la matriz.
    if (entidad == SyncConstants.mapaRiesgo) {
      return 45;
    }

    if (entidad == SyncConstants.matrizIperc &&
        operacion == SyncConstants.eliminar) {
      return 50;
    }

    return 100;
  }

  // =============================================================
  // VALIDAR OPERACIÓN DE COLA
  // =============================================================

  void _validarOperacionCola(SyncQueueModel item) {
    final String entidad = item.entidad.trim().toUpperCase();

    final String idLocal = item.entidadIdLocal.trim();

    final String operacion = item.operacion.trim().toUpperCase();

    if (entidad.isEmpty) {
      throw const FormatException(
        'La operación pendiente no contiene entidad.',
      );
    }

    if (idLocal.isEmpty) {
      throw const FormatException(
        'La operación pendiente no contiene identificador local.',
      );
    }

    if (operacion.isEmpty) {
      throw const FormatException(
        'La operación pendiente no contiene tipo de operación.',
      );
    }

    final bool entidadValida =
        entidad == SyncConstants.matrizIperc ||
        entidad == SyncConstants.detalleIperc ||
        entidad == SyncConstants.seguimientoIperc ||
        entidad == SyncConstants.mapaRiesgo;

    if (!entidadValida) {
      throw UnsupportedError(
        'Entidad de sincronización no soportada: $entidad.',
      );
    }

    final bool operacionValida =
        operacion == SyncConstants.crear ||
        operacion == SyncConstants.actualizar ||
        operacion == SyncConstants.eliminar;

    if (!operacionValida) {
      throw UnsupportedError(
        'Operación de sincronización no soportada: $operacion.',
      );
    }
  }

  // =============================================================
  // ENRUTAR OPERACIÓN
  // =============================================================

  Future<void> _processItem(SyncQueueModel item) async {
    final String entidad = item.entidad.trim().toUpperCase();

    final String operacion = item.operacion.trim().toUpperCase();

    if (entidad == SyncConstants.matrizIperc) {
      await _processMatrix(item, operacion);
      return;
    }

    if (entidad == SyncConstants.detalleIperc) {
      await _processDetail(item, operacion);
      return;
    }

    if (entidad == SyncConstants.seguimientoIperc) {
      await _processSeguimiento(item, operacion);
      return;
    }

    if (entidad == SyncConstants.mapaRiesgo) {
      await _mapaRiesgoSyncService.synchronizeQueueItem(item);
      return;
    }

    throw UnsupportedError(
      'No existe sincronización para la entidad "${item.entidad}".',
    );
  }

  // =============================================================
  // MATRIZ IPERC
  // =============================================================

  Future<void> _processMatrix(SyncQueueModel item, String operacion) async {
    final Map<String, dynamic> data = _decodeData(item.datosJson);

    switch (operacion) {
      case SyncConstants.crear:
        await _createMatrix(item, data);
        return;

      case SyncConstants.actualizar:
        await _updateMatrix(item, data);
        return;

      case SyncConstants.eliminar:
        await _deleteMatrix(item, data);
        return;

      default:
        throw UnsupportedError(
          'La operación "$operacion" no es válida para MATRIZ_IPERC.',
        );
    }
  }

  // =============================================================
  // CREAR MATRIZ
  // =============================================================

  Future<void> _createMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    final Map<String, dynamic> apiData = await _transformMatrixForApi(
      localData,
    );

    final String serverId = await _matrizRemoteDatasource.create(apiData);

    final String idServidor = serverId.trim();

    if (idServidor.isEmpty) {
      throw StateError(
        'El backend no devolvió el identificador de la matriz IPERC.',
      );
    }

    final int? servidorNumerico = int.tryParse(idServidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw FormatException(
        'El backend devolvió un identificador '
        'de matriz no válido: $idServidor.',
      );
    }

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: item.entidadIdLocal,
      idServidor: idServidor,
    );
  }

  // =============================================================
  // ACTUALIZAR MATRIZ
  // =============================================================

  Future<void> _updateMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    final String idLocal = item.entidadIdLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'La actualización de la matriz no contiene '
        'un identificador local.',
      );
    }

    int? idServidor = await _matrizLocalDatasource.getServerId(idLocal);

    idServidor ??= _intOptional(localData['id_servidor']);

    if (idServidor == null || idServidor <= 0) {
      throw StateError(
        'La matriz todavía no tiene un ID del servidor. '
        'Primero debe sincronizarse su creación.',
      );
    }

    final int usuarioActualizacionId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioActualizacionId',
      operacion: 'actualización',
    );

    final Map<String, dynamic> apiData = <String, dynamic>{
      'nombre': localData['nombre']?.toString().trim(),
      'objetivo': _textoOpcional(localData['descripcion']),
      'institucionId': _intFromLocal(
        localData['institucion_id'],
        nombre: 'institución',
        obligatorio: true,
      ),
      'sedeId': _intFromLocal(
        localData['sede_id'],
        nombre: 'sede',
        obligatorio: true,
      ),
      'areaId': _intFromLocal(
        localData['area_id'],
        nombre: 'área',
        obligatorio: true,
      ),
      'puestoTrabajoId': _intFromLocal(
        localData['puesto_trabajo_id'],
        nombre: 'puesto de trabajo',
        obligatorio: true,
      ),
      'procesoId': _intFromLocal(
        localData['proceso_id'],
        nombre: 'proceso',
        obligatorio: true,
      ),
      'actividadId': _intFromLocal(
        localData['actividad_id'],
        nombre: 'actividad',
        obligatorio: true,
      ),
      'estado': !_boolFromLocal(localData['eliminado']),
      'usuarioActualizacionId': usuarioActualizacionId,
    };

    final String nombre = apiData['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      throw const FormatException(
        'La matriz offline no contiene un nombre válido.',
      );
    }

    await _matrizRemoteDatasource.actualizar(idServidor, apiData);

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: idLocal,
      idServidor: idServidor.toString(),
    );
  }

  // =============================================================
  // ELIMINAR MATRIZ
  // =============================================================

  Future<void> _deleteMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    final String idLocal = item.entidadIdLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'La eliminación de la matriz no contiene '
        'un identificador local.',
      );
    }

    int? idServidor = await _matrizLocalDatasource.getServerId(idLocal);

    idServidor ??= _intOptional(localData['id_servidor']);

    // Una matriz nunca creada en el servidor no necesita DELETE.
    if (idServidor == null || idServidor <= 0) {
      return;
    }

    final int usuarioEliminacionId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioEliminacionId',
      operacion: 'eliminación',
    );

    await _matrizRemoteDatasource.eliminar(
      idServidor,
      usuarioEliminacionId: usuarioEliminacionId,
    );
  }

  // =============================================================
  // TRANSFORMAR MATRIZ LOCAL PARA API
  // =============================================================

  Future<Map<String, dynamic>> _transformMatrixForApi(
    Map<String, dynamic> localData,
  ) async {
    final int usuarioRegistroId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioRegistroId',
      operacion: 'registro',
    );

    final String nombre = localData['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      throw const FormatException(
        'La matriz offline no contiene un nombre válido.',
      );
    }

    return <String, dynamic>{
      'institucionId': _intFromLocal(
        localData['institucion_id'],
        nombre: 'institución',
        obligatorio: true,
      ),
      'sedeId': _intFromLocal(
        localData['sede_id'],
        nombre: 'sede',
        obligatorio: true,
      ),
      'areaId': _intFromLocal(
        localData['area_id'],
        nombre: 'área',
        obligatorio: true,
      ),
      'puestoTrabajoId': _intFromLocal(
        localData['puesto_trabajo_id'],
        nombre: 'puesto de trabajo',
        obligatorio: true,
      ),
      'procesoId': _intFromLocal(
        localData['proceso_id'],
        nombre: 'proceso',
        obligatorio: true,
      ),
      'actividadId': _intFromLocal(
        localData['actividad_id'],
        nombre: 'actividad',
        obligatorio: true,
      ),
      'codigo': _textoOpcional(localData['codigo']),
      'nombre': nombre,
      'objetivo': _textoOpcional(localData['descripcion']),
      'usuarioRegistroId': usuarioRegistroId,
    };
  }

  // =============================================================
  // DETALLE IPERC
  // =============================================================

  Future<void> _processDetail(SyncQueueModel item, String operacion) async {
    final bool operacionValida =
        operacion == SyncConstants.crear ||
        operacion == SyncConstants.actualizar ||
        operacion == SyncConstants.eliminar;

    if (!operacionValida) {
      throw UnsupportedError(
        'La operación "$operacion" no es válida '
        'para DETALLE_IPERC.',
      );
    }

    final String idLocal = item.entidadIdLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'La operación de detalle IPERC no contiene '
        'un identificador local.',
      );
    }

    await _detalleIpercSyncService.sincronizarPorIdLocal(idLocal);
  }

  // =============================================================
  // SEGUIMIENTO IPERC
  // =============================================================

  Future<void> _processSeguimiento(
    SyncQueueModel item,
    String operacion,
  ) async {
    final bool operacionValida =
        operacion == SyncConstants.crear ||
        operacion == SyncConstants.actualizar ||
        operacion == SyncConstants.eliminar;

    if (!operacionValida) {
      throw UnsupportedError(
        'La operación "$operacion" no es válida '
        'para SEGUIMIENTO_IPERC.',
      );
    }

    final String idLocal = item.entidadIdLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'La operación de Seguimiento IPERC no contiene '
        'un identificador local.',
      );
    }

    await _seguimientoIpercSyncService.sincronizarPorIdLocal(idLocal);
  }

  // =============================================================
  // DECODIFICAR JSON DE COLA
  // =============================================================

  Map<String, dynamic> _decodeData(String jsonText) {
    final String contenido = jsonText.trim();

    if (contenido.isEmpty) {
      throw const FormatException('La operación pendiente no contiene datos.');
    }

    final dynamic decoded = jsonDecode(contenido);

    if (decoded is! Map) {
      throw const FormatException(
        'Los datos de la operación pendiente '
        'no tienen un formato válido.',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  // =============================================================
  // RESOLVER USUARIO REAL
  // =============================================================

  Future<int> _resolverUsuarioId({
    required Map<String, dynamic> localData,
    required String clave,
    required String operacion,
  }) async {
    // -----------------------------------------------------------
    // USUARIO GUARDADO EN LA OPERACIÓN
    // -----------------------------------------------------------

    final int? usuarioCola = _intOptional(localData[clave]);

    if (usuarioCola != null && usuarioCola > 0) {
      return usuarioCola;
    }

    // -----------------------------------------------------------
    // FALLBACK: SESIÓN AUTENTICADA
    // -----------------------------------------------------------

    final String usuarioTexto =
        (await _secureStorageService.getUsuarioId())?.trim() ?? '';

    if (usuarioTexto.isEmpty) {
      throw StateError(
        'No se pudo identificar al usuario responsable '
        'de la $operacion. Inicie sesión nuevamente.',
      );
    }

    final int? usuarioId = int.tryParse(usuarioTexto);

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'El identificador del usuario autenticado '
        'no es válido: $usuarioTexto.',
      );
    }

    return usuarioId;
  }

  // =============================================================
  // CONVERSIONES
  // =============================================================

  int? _intFromLocal(
    dynamic value, {
    required String nombre,
    required bool obligatorio,
  }) {
    final String texto = value?.toString().trim() ?? '';

    if (texto.isEmpty) {
      if (obligatorio) {
        throw FormatException(
          'La matriz offline no tiene un '
          'identificador válido de $nombre.',
        );
      }

      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw FormatException(
        'El identificador de $nombre no es válido: $texto.',
      );
    }

    return id;
  }

  int? _intOptional(dynamic value) {
    if (value == null) {
      return null;
    }

    final String texto = value.toString().trim();

    if (texto.isEmpty) {
      return null;
    }

    final int? resultado = int.tryParse(texto);

    if (resultado == null || resultado <= 0) {
      return null;
    }

    return resultado;
  }

  bool _boolFromLocal(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value.toInt() == 1;
    }

    final String texto = value?.toString().trim().toLowerCase() ?? '';

    return texto == '1' || texto == 'true' || texto == 'si' || texto == 'sí';
  }

  String? _textoOpcional(dynamic value) {
    final String texto = value?.toString().trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // MENSAJE DE ERROR
  // =============================================================

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final dynamic responseData = error.response?.data;

      if (responseData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          responseData,
        );

        final dynamic mensaje =
            data['message'] ??
            data['mensaje'] ??
            data['error'] ??
            data['title'] ??
            data['detail'];

        if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
          return mensaje.toString().trim();
        }

        final dynamic errores = data['errors'];

        if (errores != null) {
          return errores.toString();
        }
      }

      if (responseData != null && responseData.toString().trim().isNotEmpty) {
        return responseData.toString().trim();
      }

      return error.message ?? 'Error de comunicación con el servidor.';
    }

    if (error is ArgumentError) {
      return error.message?.toString().trim() ??
          'Los datos de sincronización no son válidos.';
    }

    if (error is StateError) {
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }

    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'Bad state: ',
      'Unsupported operation: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty
        ? 'Ocurrió un error desconocido durante la sincronización.'
        : mensaje;
  }
}
