import '../datasources/local/matriz_iperc_local_datasource.dart';
import '../mappers/detalle_iperc_sync_mapper.dart';
import '../models/detalle_iperc_local_model.dart';
import '../models/detalle_iperc_model.dart';
import '../repositories/detalle_iperc_local_repository.dart';
import '../repositories/detalle_iperc_repository.dart';

/// ===============================================================
/// RESULTADO DE SINCRONIZACIÓN
/// ===============================================================
class DetalleIpercSyncResult {
  const DetalleIpercSyncResult({
    required this.total,
    required this.sincronizados,
    required this.fallidos,
    required this.errores,
  });

  final int total;
  final int sincronizados;
  final int fallidos;
  final List<String> errores;

  bool get exitoso {
    return fallidos == 0;
  }

  bool get parcialmenteExitoso {
    return sincronizados > 0 && fallidos > 0;
  }

  bool get sinPendientes {
    return total == 0;
  }
}

/// ===============================================================
/// SERVICIO DE SINCRONIZACIÓN - DETALLE IPERC
/// ===============================================================
///
/// Sincroniza los detalles almacenados en SQLite con el backend.
///
/// IMPORTANTE:
///
/// El backend actual es responsable de crear y recalcular:
///
/// - Evaluación inicial.
/// - Evaluación residual.
///
/// Flutter únicamente envía:
///
/// - probabilidadInicialId.
/// - severidadInicialId.
/// - probabilidadResidualId.
/// - severidadResidualId.
///
/// Por lo tanto este servicio YA NO crea EvaluacionRiesgo
/// de manera independiente.
/// ===============================================================
class DetalleIpercSyncService {
  DetalleIpercSyncService({
    DetalleIpercLocalRepository? localRepository,
    DetalleIpercRepository? remoteRepository,
  }) : _localRepository = localRepository ?? DetalleIpercLocalRepository(),
       _remoteRepository = remoteRepository ?? DetalleIpercRepository();

  final MatrizIpercLocalDatasource _matrizLocalDatasource =
      MatrizIpercLocalDatasource();

  final DetalleIpercLocalRepository _localRepository;

  final DetalleIpercRepository _remoteRepository;

  bool _sincronizando = false;

  bool get sincronizando {
    return _sincronizando;
  }

  // =============================================================
  // SINCRONIZAR POR ID LOCAL
  // =============================================================

  Future<void> sincronizarPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local del detalle es obligatorio.');
    }

    final DetalleIpercLocalModel? detalle = await _localRepository
        .obtenerPorIdLocal(id);

    // El registro puede haber sido eliminado previamente.
    if (detalle == null) {
      return;
    }

    await _sincronizarDetalle(detalle);
  }

  // =============================================================
  // SINCRONIZAR TODOS LOS PENDIENTES
  // =============================================================

  Future<DetalleIpercSyncResult> sincronizarPendientes() async {
    if (_sincronizando) {
      return const DetalleIpercSyncResult(
        total: 0,
        sincronizados: 0,
        fallidos: 0,
        errores: <String>[
          'Ya existe una sincronización de detalles IPERC en ejecución.',
        ],
      );
    }

    _sincronizando = true;

    int sincronizados = 0;
    int fallidos = 0;

    final List<String> errores = <String>[];

    try {
      final List<DetalleIpercLocalModel> pendientes = await _localRepository
          .listarPendientes();

      for (final DetalleIpercLocalModel detalle in pendientes) {
        try {
          await _sincronizarDetalle(detalle);

          sincronizados++;
        } catch (error) {
          fallidos++;

          errores.add(
            'Detalle ${detalle.idLocal}: '
            '${_limpiarError(error)}',
          );
        }
      }

      return DetalleIpercSyncResult(
        total: pendientes.length,
        sincronizados: sincronizados,
        fallidos: fallidos,
        errores: errores,
      );
    } finally {
      _sincronizando = false;
    }
  }

  // =============================================================
  // SINCRONIZAR UN DETALLE
  // =============================================================

  Future<void> _sincronizarDetalle(DetalleIpercLocalModel detalle) async {
    // =============================================================
    // ELIMINACIÓN
    // =============================================================

    if (detalle.eliminado) {
      await _sincronizarEliminacion(detalle);
      return;
    }

    // =============================================================
    // RESOLVER MATRIZ DEL SERVIDOR
    // =============================================================

    final DetalleIpercLocalModel detallePreparado =
        await _resolverMatrizServidor(detalle);

    // =============================================================
    // CREAR O ACTUALIZAR
    // =============================================================

    final bool requiereCreacion = DetalleIpercSyncMapper.requiereCreacion(
      detallePreparado,
    );

    if (requiereCreacion) {
      await _sincronizarCreacion(detallePreparado);

      return;
    }

    await _sincronizarActualizacion(detallePreparado);
  }

  // ===============================================================
  // RESOLVER MATRIZ DEL SERVIDOR
  // ===============================================================

  /// Garantiza que el detalle conozca el identificador real de su
  /// matriz en el backend antes de intentar sincronizarse.
  ///
  /// Cuando el detalle fue creado totalmente offline puede tener:
  ///
  /// matrizIdLocal = UUID
  /// matrizIdServidor = null
  ///
  /// En ese caso se consulta matrices_iperc_local.
  ///
  /// Si la matriz todavía no fue sincronizada, se detiene el envío
  /// del detalle. La información NO se pierde y continuará pendiente.
  Future<DetalleIpercLocalModel> _resolverMatrizServidor(
    DetalleIpercLocalModel detalle,
  ) async {
    // -------------------------------------------------------------
    // YA TIENE ID DEL SERVIDOR
    // -------------------------------------------------------------

    final int? idActual = detalle.matrizIdServidor;

    if (idActual != null && idActual > 0) {
      return detalle;
    }

    // -------------------------------------------------------------
    // BUSCAR MATRIZ LOCAL
    // -------------------------------------------------------------

    final String matrizIdLocal = detalle.matrizIdLocal.trim();

    if (matrizIdLocal.isEmpty) {
      throw StateError(
        'El detalle ${detalle.idLocal} no tiene '
        'identificador local de matriz.',
      );
    }

    final int? matrizIdServidor = await _matrizLocalDatasource.getServerId(
      matrizIdLocal,
    );

    // -------------------------------------------------------------
    // MATRIZ TODAVÍA NO SINCRONIZADA
    // -------------------------------------------------------------

    if (matrizIdServidor == null || matrizIdServidor <= 0) {
      throw StateError(
        'La matriz asociada todavía no ha sido sincronizada. '
        'Primero debe sincronizarse la matriz y luego sus peligros.',
      );
    }

    // -------------------------------------------------------------
    // PREPARAR DETALLE
    // -------------------------------------------------------------

    return detalle.copyWith(matrizIdServidor: matrizIdServidor);
  }

  // =============================================================
  // CREAR EN BACKEND
  // =============================================================

  Future<void> _sincronizarCreacion(DetalleIpercLocalModel detalle) async {
    final CrearDetalleIpercRequest request =
        DetalleIpercSyncMapper.toCrearRequest(detalle);

    final DetalleIpercModel creado = await _remoteRepository.crear(request);

    if (creado.id <= 0) {
      throw StateError(
        'El backend no devolvió un identificador válido para el detalle.',
      );
    }

    await _localRepository.marcarComoSincronizado(
      idLocal: detalle.idLocal,
      idServidor: creado.id.toString(),
    );
  }

  // =============================================================
  // ACTUALIZAR EN BACKEND
  // =============================================================

  Future<void> _sincronizarActualizacion(DetalleIpercLocalModel detalle) async {
    final int idServidor = DetalleIpercSyncMapper.obtenerIdServidor(detalle);

    final ActualizarDetalleIpercRequest request =
        DetalleIpercSyncMapper.toActualizarRequest(detalle);

    final DetalleIpercModel actualizado = await _remoteRepository.actualizar(
      request,
    );

    final int idConfirmado = actualizado.id > 0 ? actualizado.id : idServidor;

    await _localRepository.marcarComoSincronizado(
      idLocal: detalle.idLocal,
      idServidor: idConfirmado.toString(),
    );
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> _sincronizarEliminacion(DetalleIpercLocalModel detalle) async {
    final String idServidorTexto = detalle.idServidor?.trim() ?? '';

    final int? idServidor = int.tryParse(idServidorTexto);

    // -----------------------------------------------------------
    // NUNCA EXISTIÓ EN BACKEND
    // -----------------------------------------------------------

    if (idServidor == null || idServidor <= 0) {
      await _localRepository.confirmarEliminacionSincronizada(detalle.idLocal);

      return;
    }

    // -----------------------------------------------------------
    // ELIMINAR / CERRAR EN BACKEND
    // -----------------------------------------------------------

    await _remoteRepository.eliminar(idServidor);

    await _localRepository.confirmarEliminacionSincronizada(detalle.idLocal);
  }

  // =============================================================
  // LIMPIAR MENSAJES
  // =============================================================

  String _limpiarError(Object error) {
    String texto = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'Bad state: ',
    ];

    for (final String prefijo in prefijos) {
      if (texto.startsWith(prefijo)) {
        texto = texto.substring(prefijo.length);
      }
    }

    return texto.isEmpty ? 'Error desconocido.' : texto;
  }
}
