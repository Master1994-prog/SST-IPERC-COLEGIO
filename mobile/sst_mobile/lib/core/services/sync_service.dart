import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../data/datasources/local/sync_queue_local_datasource.dart';
import '../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/services/detalle_iperc_sync_service.dart';
import '../constants/sync_constants.dart';
import '../network/network_info.dart';

/// Resultado general del proceso automático de sincronización.
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

/// Servicio general de sincronización.
///
/// Procesa las operaciones almacenadas en:
///
/// `sincronizaciones_pendientes`
///
/// Entidades admitidas:
///
/// - MATRIZ_IPERC.
/// - DETALLE_IPERC.
class SyncService {
  SyncService({
    NetworkInfo? networkInfo,
    SyncQueueLocalDatasource? syncQueueDatasource,
    MatrizIpercLocalDatasource? matrizLocalDatasource,
    MatrizIpercRemoteDatasource? matrizRemoteDatasource,
    DetalleIpercSyncService? detalleIpercSyncService,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _syncQueueDatasource = syncQueueDatasource ?? SyncQueueLocalDatasource(),
       _matrizLocalDatasource =
           matrizLocalDatasource ?? MatrizIpercLocalDatasource(),
       _matrizRemoteDatasource =
           matrizRemoteDatasource ?? MatrizIpercRemoteDatasource(),
       _detalleIpercSyncService =
           detalleIpercSyncService ?? DetalleIpercSyncService();

  final NetworkInfo _networkInfo;

  final SyncQueueLocalDatasource _syncQueueDatasource;

  final MatrizIpercLocalDatasource _matrizLocalDatasource;

  final MatrizIpercRemoteDatasource _matrizRemoteDatasource;

  final DetalleIpercSyncService _detalleIpercSyncService;

  bool _isSynchronizing = false;

  bool get isSynchronizing {
    return _isSynchronizing;
  }

  /// Sincroniza todas las operaciones pendientes.
  ///
  /// Las operaciones se procesan en el orden en que fueron
  /// registradas en SQLite.
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

        if (queueId == null || queueId <= 0) {
          failed++;
          continue;
        }

        try {
          /*
           * Se comprueba la conexión antes de cada registro.
           * Esto evita continuar enviando operaciones cuando
           * la conexión se pierde a mitad del proceso.
           */
          final bool sigueConectado = await _networkInfo.isConnected;

          if (!sigueConectado) {
            return SyncResult(
              total: pendingItems.length,
              synchronized: synchronized,
              failed: pendingItems.length - synchronized,
              withoutConnection: true,
            );
          }

          await _syncQueueDatasource.markAsSynchronizing(queueId);

          await _processItem(item);

          /*
           * Los datasources locales también pueden actualizar
           * la cola durante la confirmación. Esta llamada asegura
           * que el elemento procesado quede definitivamente
           * marcado como sincronizado mediante su ID.
           */
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

  /// Procesa una operación según su entidad y tipo.
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

    throw UnsupportedError(
      'No existe sincronización para la entidad '
      '"${item.entidad}".',
    );
  }

  // ============================================================
  // MATRIZ IPERC
  // ============================================================

  /// Procesa operaciones relacionadas con matrices IPERC.
  Future<void> _processMatrix(SyncQueueModel item, String operacion) async {
    final Map<String, dynamic> data = _decodeData(item.datosJson);

    switch (operacion) {
      case SyncConstants.crear:
        await _createMatrix(item, data);
        return;

      case SyncConstants.actualizar:
        throw UnsupportedError(
          'La actualización offline de matrices IPERC '
          'todavía no está implementada.',
        );

      case SyncConstants.eliminar:
        throw UnsupportedError(
          'La eliminación offline de matrices IPERC '
          'todavía no está implementada.',
        );

      default:
        throw UnsupportedError(
          'La operación "$operacion" no es válida '
          'para MATRIZ_IPERC.',
        );
    }
  }

  /// Registra una matriz local en el backend.
  Future<void> _createMatrix(
    SyncQueueModel item,
    Map<String, dynamic> localData,
  ) async {
    final Map<String, dynamic> apiData = _transformMatrixForApi(localData);

    final String serverId = await _matrizRemoteDatasource.create(apiData);

    final String idServidor = serverId.trim();

    if (idServidor.isEmpty) {
      throw StateError(
        'El backend no devolvió el identificador '
        'de la matriz IPERC.',
      );
    }

    await _matrizLocalDatasource.markAsSynchronized(
      idLocal: item.entidadIdLocal,
      idServidor: idServidor,
    );
  }

  /// Convierte el mapa almacenado en SQLite al formato esperado
  /// por el endpoint de matrices IPERC.
  Map<String, dynamic> _transformMatrixForApi(Map<String, dynamic> localData) {
    return <String, dynamic>{
      'institucionId': localData['institucion_id'],
      'sedeId': localData['sede_id'],
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

  // ============================================================
  // DETALLE IPERC
  // ============================================================

  /// Procesa una operación relacionada con un detalle IPERC.
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

  // ============================================================
  // CONVERSIÓN Y ERRORES
  // ============================================================

  /// Convierte el JSON almacenado en la cola en un mapa.
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

  /// Convierte excepciones técnicas en mensajes almacenables
  /// dentro de la cola de sincronización.
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
