import '../datasources/local/detalle_iperc_local_datasource.dart';
import '../datasources/local/seguimiento_iperc_local_datasource.dart';
import '../datasources/remote/seguimiento_iperc_remote_datasource.dart';
import '../models/detalle_iperc_local_model.dart';
import '../models/seguimiento_iperc_local_model.dart';
import '../models/seguimiento_iperc_model.dart';

/// ===============================================================
/// SERVICIO DE SINCRONIZACIÓN - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Sincroniza un Seguimiento IPERC almacenado en SQLite con el
/// backend.
///
/// Este servicio NO recorre directamente toda la cola general.
/// Su función principal es sincronizar un registro concreto por su
/// `idLocal`.
///
/// El servicio general `SyncService` será quien:
///
/// 1. Lea `sincronizaciones_pendientes`.
/// 2. Respete el orden de dependencias:
///
///    MATRIZ_IPERC
///         ↓
///    DETALLE_IPERC
///         ↓
///    SEGUIMIENTO_IPERC
///
/// 3. Llame a:
///
///    `sincronizarPorIdLocal(...)`
///
/// Esto evita que un seguimiento intente llegar al servidor antes
/// de que su Detalle IPERC padre tenga un ID remoto válido.
///
/// Operaciones soportadas:
///
/// - CREAR.
/// - ACTUALIZAR.
/// - ELIMINAR.
///
/// ===============================================================
class SeguimientoIpercSyncService {
  SeguimientoIpercSyncService({
    SeguimientoIpercLocalDatasource? localDatasource,
    SeguimientoIpercRemoteDatasource? remoteDatasource,
    DetalleIpercLocalDatasource? detalleDatasource,
  }) : _localDatasource = localDatasource ?? SeguimientoIpercLocalDatasource(),
       _remoteDatasource =
           remoteDatasource ?? SeguimientoIpercRemoteDatasource(),
       _detalleDatasource = detalleDatasource ?? DetalleIpercLocalDatasource();

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  /// Fuente SQLite de Seguimiento IPERC.
  final SeguimientoIpercLocalDatasource _localDatasource;

  /// Fuente HTTP de Seguimiento IPERC.
  final SeguimientoIpercRemoteDatasource _remoteDatasource;

  /// Se utiliza para resolver el ID remoto del Detalle IPERC padre.
  final DetalleIpercLocalDatasource _detalleDatasource;

  // =============================================================
  // SINCRONIZAR POR ID LOCAL
  // =============================================================

  /// Sincroniza un seguimiento local concreto.
  ///
  /// Este es el método que utilizará posteriormente `SyncService`
  /// cuando encuentre en la cola una operación cuya entidad sea:
  ///
  /// `SEGUIMIENTO_IPERC`
  ///
  /// La operación se determina usando el estado real del registro:
  ///
  /// - eliminado = true  → ELIMINAR.
  /// - idServidor == null → CREAR.
  /// - idServidor > 0     → ACTUALIZAR.
  Future<void> sincronizarPorIdLocal(String idLocal) async {
    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local del seguimiento IPERC es obligatorio.',
      );
    }

    // -----------------------------------------------------------
    // OBTENER REGISTRO LOCAL
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel? seguimiento = await _localDatasource
        .obtenerPorIdLocal(localId);

    // -----------------------------------------------------------
    // REGISTRO YA NO EXISTE
    // -----------------------------------------------------------
    //
    // Puede ocurrir que una operación antigua permanezca en la cola
    // después de una limpieza o de una eliminación ya confirmada.
    //
    // En ese caso no existe información que sincronizar.
    // -----------------------------------------------------------

    if (seguimiento == null) {
      return;
    }

    await _sincronizarSeguimiento(seguimiento);
  }

  // =============================================================
  // SINCRONIZAR REGISTRO
  // =============================================================

  Future<void> _sincronizarSeguimiento(
    SeguimientoIpercLocalModel seguimiento,
  ) async {
    // -----------------------------------------------------------
    // ELIMINACIÓN TIENE PRIORIDAD
    // -----------------------------------------------------------

    if (seguimiento.eliminado) {
      await _eliminar(seguimiento);

      return;
    }

    // -----------------------------------------------------------
    // RESOLVER DETALLE IPERC EN EL SERVIDOR
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel resuelto = await _resolverDetalleServidor(
      seguimiento,
    );

    // -----------------------------------------------------------
    // CREAR O ACTUALIZAR
    // -----------------------------------------------------------

    if (!resuelto.tieneIdServidor) {
      await _crear(resuelto);

      return;
    }

    await _actualizar(resuelto);
  }

  // =============================================================
  // RESOLVER ID DEL DETALLE PADRE
  // =============================================================

  /// Obtiene el ID remoto del Detalle IPERC asociado al seguimiento.
  ///
  /// CASO A:
  /// El seguimiento ya contiene `detalleIpercIdServidor`.
  ///
  /// CASO B:
  /// El seguimiento fue creado mientras el detalle también estaba
  /// offline. Entonces busca nuevamente el detalle local para saber
  /// si ya fue sincronizado.
  ///
  /// Si el detalle todavía no tiene ID remoto se lanza un error.
  /// Esto es intencional: el Seguimiento IPERC no debe enviarse antes
  /// que su Detalle IPERC padre.
  Future<SeguimientoIpercLocalModel> _resolverDetalleServidor(
    SeguimientoIpercLocalModel seguimiento,
  ) async {
    if (seguimiento.tieneDetalleServidor) {
      return seguimiento;
    }

    final String detalleLocalId = seguimiento.detalleIpercIdLocal.trim();

    if (detalleLocalId.isEmpty) {
      throw StateError(
        'El seguimiento IPERC no contiene el identificador '
        'local de su Detalle IPERC.',
      );
    }

    final DetalleIpercLocalModel? detalle = await _detalleDatasource
        .obtenerPorIdLocal(detalleLocalId);

    if (detalle == null) {
      throw StateError(
        'No se encontró el Detalle IPERC padre del seguimiento.',
      );
    }

    if (detalle.eliminado) {
      throw StateError(
        'El Detalle IPERC padre fue eliminado y el seguimiento '
        'no puede sincronizarse.',
      );
    }

    final int? detalleServidorId = _parseIdServidor(detalle.idServidor);

    if (detalleServidorId == null) {
      throw StateError(
        'El Detalle IPERC padre todavía no ha sido sincronizado. '
        'Debe sincronizarse primero el detalle y después el seguimiento.',
      );
    }

    // -----------------------------------------------------------
    // PERSISTIR LA RELACIÓN RESUELTA
    // -----------------------------------------------------------
    //
    // Se actualizan todos los seguimientos dependientes de ese mismo
    // detalle para que futuras sincronizaciones ya dispongan del
    // identificador remoto.
    // -----------------------------------------------------------

    await _localDatasource.actualizarDetalleServidor(
      detalleIpercIdLocal: detalleLocalId,
      detalleIpercIdServidor: detalleServidorId,
    );

    return seguimiento.copyWith(detalleIpercIdServidor: detalleServidorId);
  }

  // =============================================================
  // CREAR EN BACKEND
  // =============================================================

  Future<void> _crear(SeguimientoIpercLocalModel seguimiento) async {
    final int detalleServidorId = _exigirDetalleServidor(seguimiento);

    // -----------------------------------------------------------
    // CONSTRUIR REQUEST REMOTO
    // -----------------------------------------------------------

    final CrearSeguimientoIpercRequest request = CrearSeguimientoIpercRequest(
      detalleIpercId: detalleServidorId,
      fechaSeguimiento: seguimiento.fechaSeguimiento,
      usuarioId: seguimiento.usuarioId,
      descripcion: seguimiento.descripcion,
      porcentajeAvance: seguimiento.porcentajeAvance,
      verificado: seguimiento.verificado,
      fechaVerificacion: seguimiento.fechaVerificacion,
      observaciones: seguimiento.observaciones,
      archivo: seguimiento.archivo,
      nombreArchivo: seguimiento.nombreArchivo,
      tipoArchivo: seguimiento.tipoArchivo,
    );

    // -----------------------------------------------------------
    // POST AL BACKEND
    // -----------------------------------------------------------

    final SeguimientoIpercModel creado = await _remoteDatasource.crear(request);

    if (creado.id <= 0) {
      throw StateError(
        'El backend registró el seguimiento IPERC, pero no devolvió '
        'un identificador válido.',
      );
    }

    // -----------------------------------------------------------
    // CONFIRMAR SINCRONIZACIÓN LOCAL
    // -----------------------------------------------------------

    await _localDatasource.marcarComoSincronizado(
      idLocal: seguimiento.idLocal,
      idServidor: creado.id,
      detalleIpercIdServidor: detalleServidorId,
    );
  }

  // =============================================================
  // ACTUALIZAR EN BACKEND
  // =============================================================

  Future<void> _actualizar(SeguimientoIpercLocalModel seguimiento) async {
    final int seguimientoServidorId = _exigirSeguimientoServidor(seguimiento);

    final int detalleServidorId = _exigirDetalleServidor(seguimiento);

    // -----------------------------------------------------------
    // CONSTRUIR REQUEST REMOTO
    // -----------------------------------------------------------

    final ActualizarSeguimientoIpercRequest request =
        ActualizarSeguimientoIpercRequest(
          detalleIpercId: detalleServidorId,
          fechaSeguimiento: seguimiento.fechaSeguimiento,
          usuarioId: seguimiento.usuarioId,
          descripcion: seguimiento.descripcion,
          porcentajeAvance: seguimiento.porcentajeAvance,
          verificado: seguimiento.verificado,
          fechaVerificacion: seguimiento.fechaVerificacion,
          observaciones: seguimiento.observaciones,
          archivo: seguimiento.archivo,
          nombreArchivo: seguimiento.nombreArchivo,
          tipoArchivo: seguimiento.tipoArchivo,
        );

    // -----------------------------------------------------------
    // PUT AL BACKEND
    // -----------------------------------------------------------

    final SeguimientoIpercModel actualizado = await _remoteDatasource
        .actualizar(seguimientoServidorId, request);

    final int confirmadoId = actualizado.id > 0
        ? actualizado.id
        : seguimientoServidorId;

    // -----------------------------------------------------------
    // CONFIRMAR SINCRONIZACIÓN LOCAL
    // -----------------------------------------------------------

    await _localDatasource.marcarComoSincronizado(
      idLocal: seguimiento.idLocal,
      idServidor: confirmadoId,
      detalleIpercIdServidor: detalleServidorId,
    );
  }

  // =============================================================
  // ELIMINAR EN BACKEND
  // =============================================================

  Future<void> _eliminar(SeguimientoIpercLocalModel seguimiento) async {
    // -----------------------------------------------------------
    // REGISTRO NUNCA SINCRONIZADO
    // -----------------------------------------------------------
    //
    // Si no existe ID remoto, el seguimiento nunca llegó al backend.
    // Por tanto no tiene sentido ejecutar DELETE HTTP.
    //
    // Solo se confirma la eliminación local.
    // -----------------------------------------------------------

    if (!seguimiento.tieneIdServidor) {
      await _localDatasource.confirmarEliminacionSincronizada(
        seguimiento.idLocal,
      );

      return;
    }

    final int servidorId = _exigirSeguimientoServidor(seguimiento);

    // -----------------------------------------------------------
    // DELETE EN BACKEND
    // -----------------------------------------------------------

    await _remoteDatasource.eliminar(servidorId);

    // -----------------------------------------------------------
    // ELIMINAR REGISTRO LOCAL YA CONFIRMADO
    // -----------------------------------------------------------

    await _localDatasource.confirmarEliminacionSincronizada(
      seguimiento.idLocal,
    );
  }

  // =============================================================
  // VALIDACIONES DE IDENTIFICADORES
  // =============================================================

  int _exigirDetalleServidor(SeguimientoIpercLocalModel seguimiento) {
    final int? id = seguimiento.detalleIpercIdServidor;

    if (id == null || id <= 0) {
      throw StateError(
        'El seguimiento IPERC no tiene un ID remoto válido '
        'para su Detalle IPERC.',
      );
    }

    return id;
  }

  int _exigirSeguimientoServidor(SeguimientoIpercLocalModel seguimiento) {
    final int? id = seguimiento.idServidor;

    if (id == null || id <= 0) {
      throw StateError(
        'El seguimiento IPERC no tiene un identificador '
        'válido en el servidor.',
      );
    }

    return id;
  }

  /// El modelo local actual de Detalle IPERC almacena `idServidor`
  /// como texto. Este helper lo transforma a entero positivo.
  int? _parseIdServidor(String? valor) {
    final int? id = int.tryParse(valor?.trim() ?? '');

    if (id == null || id <= 0) {
      return null;
    }

    return id;
  }
}
