import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';
import '../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/services/detalle_iperc_sync_service.dart';
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

  /// Total de operaciones obtenidas desde la cola.
  final int total;

  /// Operaciones sincronizadas correctamente.
  final int synchronized;

  /// Operaciones que no pudieron sincronizarse.
  final int failed;

  /// Indica que el proceso no se ejecutó por falta de conexión.
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
/// Procesa las operaciones almacenadas en SQLite dentro de:
///
/// `sincronizaciones_pendientes`
///
/// Entidades actualmente admitidas:
///
/// - MATRIZ_IPERC.
/// - DETALLE_IPERC.
///
/// Las operaciones se procesan en orden de creación para respetar:
///
/// CREAR -> ACTUALIZAR -> ELIMINAR
/// ===============================================================
class SyncService {
  SyncService({
    NetworkInfo? networkInfo,
    SyncQueueLocalDatasource? syncQueueDatasource,
    MatrizIpercLocalDatasource? matrizLocalDatasource,
    MatrizIpercRemoteDatasource? matrizRemoteDatasource,
    DetalleIpercSyncService? detalleIpercSyncService,
    SecureStorageService? secureStorageService,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource(),
       _matrizLocalDatasource =
           matrizLocalDatasource ?? MatrizIpercLocalDatasource(),
       _matrizRemoteDatasource =
           matrizRemoteDatasource ?? MatrizIpercRemoteDatasource(),
       _detalleIpercSyncService =
           detalleIpercSyncService ?? DetalleIpercSyncService(),
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

  final SecureStorageService _secureStorageService;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _isSynchronizing = false;

  bool get isSynchronizing {
    return _isSynchronizing;
  }

  // =============================================================
  // SINCRONIZAR PENDIENTES
  // =============================================================

  /// Sincroniza todas las operaciones pendientes.
  ///
  /// Las operaciones se procesan respetando el orden en que
  /// fueron registradas en SQLite.
  Future<SyncResult> synchronizePending() async {
    // Evita ejecutar dos sincronizaciones simultáneamente.
    if (_isSynchronizing) {
      return const SyncResult(
        total: 0,
        synchronized: 0,
        failed: 0,
        withoutConnection: false,
      );
    }

    // -----------------------------------------------------------
    // COMPROBAR CONEXIÓN
    // -----------------------------------------------------------

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
      // ---------------------------------------------------------
      // OBTENER COLA
      // ---------------------------------------------------------

      final List<SyncQueueModel> pendingItems = await _syncQueueDatasource
          .getPending();

      // ---------------------------------------------------------
      // PROCESAR UNO POR UNO
      // ---------------------------------------------------------

      for (final SyncQueueModel item in pendingItems) {
        final int? queueId = item.id;

        if (queueId == null || queueId <= 0) {
          failed++;
          continue;
        }

        try {
          // -----------------------------------------------------
          // VERIFICAR CONEXIÓN ANTES DE CADA OPERACIÓN
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
          // MARCAR SINCRONIZANDO
          // -----------------------------------------------------

          await _syncQueueDatasource.markAsSynchronizing(queueId);

          // -----------------------------------------------------
          // PROCESAR OPERACIÓN
          // -----------------------------------------------------

          await _processItem(item);

          // -----------------------------------------------------
          // CONFIRMAR SINCRONIZACIÓN
          // -----------------------------------------------------

          await _syncQueueDatasource.markAsSynchronized(queueId);

          synchronized++;
        } catch (error) {
          failed++;

          // -----------------------------------------------------
          // GUARDAR ERROR
          // -----------------------------------------------------

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

  // =============================================================
  // PROCESAR ELEMENTO
  // =============================================================

  /// Determina qué servicio debe procesar la operación.
  Future<void> _processItem(SyncQueueModel item) async {
    final String entidad = item.entidad.trim().toUpperCase();

    final String operacion = item.operacion.trim().toUpperCase();

    // -----------------------------------------------------------
    // MATRIZ IPERC
    // -----------------------------------------------------------

    if (entidad == SyncConstants.matrizIperc) {
      await _processMatrix(item, operacion);

      return;
    }

    // -----------------------------------------------------------
    // DETALLE IPERC
    // -----------------------------------------------------------

    if (entidad == SyncConstants.detalleIperc) {
      await _processDetail(item, operacion);

      return;
    }

    throw UnsupportedError(
      'No existe sincronización para la entidad '
      '"${item.entidad}".',
    );
  }

  // =============================================================
  // MATRIZ IPERC
  // =============================================================

  /// Procesa una operación relacionada con una Matriz IPERC.
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
          'La operación "$operacion" no es válida '
          'para MATRIZ_IPERC.',
        );
    }
  }

  // =============================================================
  // CREAR MATRIZ IPERC
  // =============================================================

  /// Registra en el backend una matriz creada en SQLite.
  Future<void> _createMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    // -----------------------------------------------------------
    // TRANSFORMAR DATOS
    // -----------------------------------------------------------

    final Map<String, dynamic> apiData = await _transformMatrixForApi(
      localData,
    );

    // -----------------------------------------------------------
    // ENVIAR POST
    // -----------------------------------------------------------

    final String serverId = await _matrizRemoteDatasource.create(apiData);

    final String idServidor = serverId.trim();

    if (idServidor.isEmpty) {
      throw StateError(
        'El backend no devolvió el identificador '
        'de la matriz IPERC.',
      );
    }

    final int? servidorNumerico = int.tryParse(idServidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw FormatException(
        'El backend devolvió un identificador '
        'de matriz no válido: $idServidor.',
      );
    }

    // -----------------------------------------------------------
    // GUARDAR ID REMOTO
    // -----------------------------------------------------------

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: item.entidadIdLocal,
      idServidor: idServidor,
    );
  }

  // =============================================================
  // ACTUALIZAR MATRIZ IPERC
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

    // -----------------------------------------------------------
    // OBTENER ID DEL BACKEND
    // -----------------------------------------------------------

    int? idServidor = await _matrizLocalDatasource.getServerId(idLocal);

    // -----------------------------------------------------------
    // FALLBACK DESDE JSON
    // -----------------------------------------------------------

    idServidor ??= _intOptional(localData['id_servidor']);

    if (idServidor == null || idServidor <= 0) {
      throw StateError(
        'La matriz todavía no tiene un ID del servidor. '
        'Primero debe sincronizarse su creación.',
      );
    }

    // -----------------------------------------------------------
    // OBTENER USUARIO REAL
    // -----------------------------------------------------------

    final int usuarioActualizacionId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioActualizacionId',
      operacion: 'actualización',
    );

    // -----------------------------------------------------------
    // CONSTRUIR PAYLOAD
    // -----------------------------------------------------------

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

    // -----------------------------------------------------------
    // VALIDAR NOMBRE
    // -----------------------------------------------------------

    final String nombre = apiData['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      throw const FormatException(
        'La matriz offline no contiene un nombre válido.',
      );
    }

    // -----------------------------------------------------------
    // ENVIAR PUT
    // -----------------------------------------------------------

    await _matrizRemoteDatasource.actualizar(idServidor, apiData);

    // -----------------------------------------------------------
    // CONFIRMAR LOCAL
    // -----------------------------------------------------------

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: idLocal,
      idServidor: idServidor.toString(),
    );
  }

  // =============================================================
  // ELIMINAR MATRIZ IPERC
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

    // -----------------------------------------------------------
    // OBTENER ID DEL BACKEND
    // -----------------------------------------------------------

    int? idServidor = await _matrizLocalDatasource.getServerId(idLocal);

    idServidor ??= _intOptional(localData['id_servidor']);

    // ===========================================================
    // MATRIZ QUE NUNCA LLEGÓ AL SERVIDOR
    // ===========================================================
    //
    // Si se creó offline y se eliminó antes de sincronizarse,
    // no existe registro en MySQL que eliminar.
    //
    // En ese caso la operación DELETE puede terminar sin hacer
    // ninguna llamada HTTP.
    // ===========================================================

    if (idServidor == null || idServidor <= 0) {
      return;
    }

    // -----------------------------------------------------------
    // USUARIO REAL
    // -----------------------------------------------------------

    final int usuarioEliminacionId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioEliminacionId',
      operacion: 'eliminación',
    );

    // -----------------------------------------------------------
    // DELETE AL BACKEND
    // -----------------------------------------------------------

    await _matrizRemoteDatasource.eliminar(
      idServidor,
      usuarioEliminacionId: usuarioEliminacionId,
    );
  }

  // =============================================================
  // TRANSFORMAR MATRIZ PARA API
  // =============================================================

  /// Convierte una Matriz IPERC almacenada en SQLite al formato
  /// esperado por el endpoint POST del backend.
  Future<Map<String, dynamic>> _transformMatrixForApi(
    Map<String, dynamic> localData,
  ) async {
    // -----------------------------------------------------------
    // USUARIO QUE CREÓ LA MATRIZ
    // -----------------------------------------------------------

    final int usuarioRegistroId = await _resolverUsuarioId(
      localData: localData,
      clave: 'usuarioRegistroId',
      operacion: 'registro',
    );

    // -----------------------------------------------------------
    // VALIDAR NOMBRE
    // -----------------------------------------------------------

    final String nombre = localData['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      throw const FormatException(
        'La matriz offline no contiene un nombre válido.',
      );
    }

    // -----------------------------------------------------------
    // PAYLOAD
    // -----------------------------------------------------------

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

  /// Procesa una operación relacionada con Detalle IPERC.
  ///
  /// El servicio especializado consulta el registro actual desde
  /// SQLite y determina si debe crear, actualizar o eliminar.
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
  // DECODIFICAR JSON
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
  // OBTENER USUARIO DE OPERACIÓN
  // =============================================================

  /// Obtiene el usuario responsable de la operación.
  ///
  /// Prioridad:
  ///
  /// 1. Usuario almacenado originalmente en el JSON de la cola.
  /// 2. Usuario autenticado actualmente en SecureStorage.
  ///
  /// Esto permite mantener compatibilidad con operaciones antiguas
  /// que pudieran haberse creado antes de guardar el usuario
  /// dentro de `datos_json`.
  Future<int> _resolverUsuarioId({
    required Map<String, dynamic> localData,
    required String clave,
    required String operacion,
  }) async {
    // -----------------------------------------------------------
    // 1. USUARIO GUARDADO EN LA OPERACIÓN
    // -----------------------------------------------------------

    final int? usuarioCola = _intOptional(localData[clave]);

    if (usuarioCola != null && usuarioCola > 0) {
      return usuarioCola;
    }

    // -----------------------------------------------------------
    // 2. USUARIO DE LA SESIÓN ACTUAL
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
  // CONVERTIR ID LOCAL A ENTERO
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
          'La matriz offline no tiene un identificador '
          'válido de $nombre.',
        );
      }

      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw FormatException(
        'El identificador de $nombre '
        'no es válido: $texto.',
      );
    }

    return id;
  }

  // =============================================================
  // ENTERO OPCIONAL
  // =============================================================

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

  // =============================================================
  // BOOL DESDE SQLITE / JSON
  // =============================================================

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

  // =============================================================
  // TEXTO OPCIONAL
  // =============================================================

  String? _textoOpcional(dynamic value) {
    final String texto = value?.toString().trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // MENSAJE DE ERROR
  // =============================================================

  /// Convierte excepciones técnicas en mensajes almacenables
  /// dentro de la cola de sincronización.
  String _getErrorMessage(Object error) {
    // -----------------------------------------------------------
    // DIO
    // -----------------------------------------------------------

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

    // -----------------------------------------------------------
    // ARGUMENT ERROR
    // -----------------------------------------------------------

    if (error is ArgumentError) {
      return error.message?.toString().trim() ??
          'Los datos de sincronización no son válidos.';
    }

    // -----------------------------------------------------------
    // STATE ERROR
    // -----------------------------------------------------------

    if (error is StateError) {
      return error.message;
    }

    // -----------------------------------------------------------
    // FORMAT EXCEPTION
    // -----------------------------------------------------------

    if (error is FormatException) {
      return error.message;
    }

    // -----------------------------------------------------------
    // OTROS
    // -----------------------------------------------------------

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
