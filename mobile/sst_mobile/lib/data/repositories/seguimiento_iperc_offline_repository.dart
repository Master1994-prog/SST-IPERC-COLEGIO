import 'package:uuid/uuid.dart';

import '../../core/services/secure_storage_service.dart';
import '../datasources/local/detalle_iperc_local_datasource.dart';
import '../datasources/local/seguimiento_iperc_local_datasource.dart';
import '../models/detalle_iperc_local_model.dart';
import '../models/seguimiento_iperc_local_model.dart';

/// ===============================================================
/// REPOSITORIO OFFLINE - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Centraliza la lógica de negocio necesaria para trabajar con
/// Seguimiento IPERC cuando el dispositivo no tiene conexión.
///
/// Este repositorio NO realiza llamadas HTTP.
///
/// Su responsabilidad es:
///
/// - Crear seguimientos en SQLite.
/// - Obtener el usuario autenticado real.
/// - Relacionar el seguimiento con su Detalle IPERC local.
/// - Conservar el ID remoto del detalle cuando ya exista.
/// - Actualizar seguimientos.
/// - Verificar seguimientos.
/// - Eliminar seguimientos de forma lógica.
/// - Consultar seguimientos locales.
/// - Dejar cada cambio listo para la cola de sincronización.
///
/// La inserción de las operaciones CREAR / ACTUALIZAR / ELIMINAR
/// dentro de `sincronizaciones_pendientes` la realiza:
///
/// `SeguimientoIpercLocalDatasource`.
///
/// Flujo general:
///
/// Usuario
///   ↓
/// SeguimientoIpercOfflineRepository
///   ↓
/// SeguimientoIpercLocalDatasource
///   ↓
/// SQLite + cola de sincronización
///   ↓
/// SyncService
///   ↓
/// Backend
/// ===============================================================
class SeguimientoIpercOfflineRepository {
  SeguimientoIpercOfflineRepository({
    SeguimientoIpercLocalDatasource? seguimientoDatasource,
    DetalleIpercLocalDatasource? detalleDatasource,
    SecureStorageService? secureStorageService,
  }) : _seguimientoDatasource =
           seguimientoDatasource ?? SeguimientoIpercLocalDatasource(),
       _detalleDatasource = detalleDatasource ?? DetalleIpercLocalDatasource(),
       _secureStorageService =
           secureStorageService ?? SecureStorageService.instance;

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  /// CRUD local de Seguimiento IPERC.
  final SeguimientoIpercLocalDatasource _seguimientoDatasource;

  /// Permite validar que el Detalle IPERC padre exista localmente.
  final DetalleIpercLocalDatasource _detalleDatasource;

  /// Permite obtener el usuario que inició sesión.
  final SecureStorageService _secureStorageService;

  /// Generador de identificadores únicos para registros offline.
  final Uuid _uuid = const Uuid();

  // =============================================================
  // CREAR SEGUIMIENTO OFFLINE
  // =============================================================

  /// Crea un seguimiento relacionado con un Detalle IPERC local.
  ///
  /// No se solicita `usuarioId` desde la pantalla porque el usuario
  /// debe ser siempre el usuario autenticado de la sesión actual.
  ///
  /// Si el Detalle IPERC ya fue sincronizado, también se almacena
  /// su ID del servidor. Si todavía es completamente offline, ese
  /// valor permanece nulo hasta que el detalle se sincronice.
  Future<SeguimientoIpercLocalModel> createOffline({
    required String detalleIpercIdLocal,
    required DateTime fechaSeguimiento,
    required String descripcion,
    required double porcentajeAvance,
    String? observaciones,
    String? archivo,
    String? nombreArchivo,
    String? tipoArchivo,
  }) async {
    // -----------------------------------------------------------
    // VALIDAR ID DEL DETALLE LOCAL
    // -----------------------------------------------------------

    final String detalleLocal = detalleIpercIdLocal.trim();

    if (detalleLocal.isEmpty) {
      throw ArgumentError(
        'El identificador local del Detalle IPERC es obligatorio.',
      );
    }

    // -----------------------------------------------------------
    // OBTENER DETALLE IPERC PADRE
    // -----------------------------------------------------------

    final DetalleIpercLocalModel? detalle = await _detalleDatasource
        .obtenerPorIdLocal(detalleLocal);

    if (detalle == null) {
      throw StateError(
        'No se encontró el Detalle IPERC local asociado al seguimiento.',
      );
    }

    if (detalle.eliminado) {
      throw StateError(
        'No se puede registrar un seguimiento sobre un '
        'Detalle IPERC eliminado.',
      );
    }

    // -----------------------------------------------------------
    // VALIDAR DESCRIPCIÓN
    // -----------------------------------------------------------

    final String descripcionLimpia = descripcion.trim();

    if (descripcionLimpia.isEmpty) {
      throw ArgumentError(
        'La descripción del seguimiento IPERC es obligatoria.',
      );
    }

    // -----------------------------------------------------------
    // VALIDAR PORCENTAJE DE AVANCE
    // -----------------------------------------------------------

    _validarPorcentaje(porcentajeAvance);

    // -----------------------------------------------------------
    // OBTENER USUARIO AUTENTICADO
    // -----------------------------------------------------------

    final int usuarioId = await _obtenerUsuarioAutenticadoId();

    final String? usuarioNombre = _textoOpcional(
      await _secureStorageService.getNombreUsuario(),
    );

    final DateTime ahora = DateTime.now().toUtc();

    // -----------------------------------------------------------
    // RESOLVER ID REMOTO DEL DETALLE
    // -----------------------------------------------------------

    final int? detalleServidorId = _parseIdServidor(detalle.idServidor);

    // -----------------------------------------------------------
    // CREAR MODELO LOCAL
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel seguimiento = SeguimientoIpercLocalModel(
      idLocal: _uuid.v4(),
      idServidor: null,
      detalleIpercIdLocal: detalle.idLocal,
      detalleIpercIdServidor: detalleServidorId,
      detalleItem: detalle.item,
      detalleTarea: detalle.tarea,
      fechaSeguimiento: fechaSeguimiento.toUtc(),
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      descripcion: descripcionLimpia,
      porcentajeAvance: porcentajeAvance,
      verificado: false,
      fechaVerificacion: null,
      observaciones: _textoOpcional(observaciones),
      archivo: _textoOpcional(archivo),
      nombreArchivo: _textoOpcional(nombreArchivo),
      tipoArchivo: _textoOpcional(tipoArchivo),
      sincronizado: false,
      eliminado: false,
      fechaRegistro: ahora,
      fechaActualizacion: null,
      fechaSincronizacion: null,
    );

    // -----------------------------------------------------------
    // GUARDAR EN SQLITE
    // -----------------------------------------------------------
    //
    // El datasource también agregará automáticamente una operación
    // CREAR en `sincronizaciones_pendientes`.
    // -----------------------------------------------------------

    await _seguimientoDatasource.crear(seguimiento);

    return seguimiento;
  }

  // =============================================================
  // ACTUALIZAR SEGUIMIENTO OFFLINE
  // =============================================================

  /// Actualiza los datos editables de un seguimiento local.
  ///
  /// Conserva:
  ///
  /// - idLocal.
  /// - idServidor.
  /// - fechaRegistro.
  /// - vínculo con el Detalle IPERC.
  ///
  /// El registro vuelve a quedar:
  ///
  /// `sincronizado = false`
  ///
  /// para que la modificación llegue posteriormente al backend.
  Future<SeguimientoIpercLocalModel> updateOffline({
    required String idLocal,
    required DateTime fechaSeguimiento,
    required String descripcion,
    required double porcentajeAvance,
    String? observaciones,
    String? archivo,
    String? nombreArchivo,
    String? tipoArchivo,
  }) async {
    // -----------------------------------------------------------
    // OBTENER REGISTRO ACTUAL
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel existente = await _obtenerExistente(
      idLocal,
    );

    if (existente.eliminado) {
      throw StateError(
        'No se puede actualizar un seguimiento IPERC eliminado.',
      );
    }

    // -----------------------------------------------------------
    // VALIDAR DESCRIPCIÓN
    // -----------------------------------------------------------

    final String descripcionLimpia = descripcion.trim();

    if (descripcionLimpia.isEmpty) {
      throw ArgumentError(
        'La descripción del seguimiento IPERC es obligatoria.',
      );
    }

    // -----------------------------------------------------------
    // VALIDAR AVANCE
    // -----------------------------------------------------------

    _validarPorcentaje(porcentajeAvance);

    // -----------------------------------------------------------
    // OBTENER USUARIO REAL DE LA SESIÓN
    // -----------------------------------------------------------
    //
    // Si el seguimiento es editado por otro usuario autenticado,
    // se conserva la trazabilidad del usuario que realiza la
    // modificación mediante el campo usuarioId utilizado por el
    // contrato remoto actual.
    // -----------------------------------------------------------

    final int usuarioId = await _obtenerUsuarioAutenticadoId();

    final String? usuarioNombre = _textoOpcional(
      await _secureStorageService.getNombreUsuario(),
    );

    final DateTime ahora = DateTime.now().toUtc();

    // -----------------------------------------------------------
    // CONSTRUIR MODELO ACTUALIZADO
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel actualizado = SeguimientoIpercLocalModel(
      idLocal: existente.idLocal,
      idServidor: existente.idServidor,
      detalleIpercIdLocal: existente.detalleIpercIdLocal,
      detalleIpercIdServidor: existente.detalleIpercIdServidor,
      detalleItem: existente.detalleItem,
      detalleTarea: existente.detalleTarea,
      fechaSeguimiento: fechaSeguimiento.toUtc(),
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre ?? existente.usuarioNombre,
      descripcion: descripcionLimpia,
      porcentajeAvance: porcentajeAvance,
      verificado: existente.verificado,
      fechaVerificacion: existente.fechaVerificacion,
      observaciones: _textoOpcional(observaciones),
      archivo: _textoOpcional(archivo),
      nombreArchivo: _textoOpcional(nombreArchivo),
      tipoArchivo: _textoOpcional(tipoArchivo),
      sincronizado: false,
      eliminado: false,
      fechaRegistro: existente.fechaRegistro,
      fechaActualizacion: ahora,
      fechaSincronizacion: existente.fechaSincronizacion,
    );

    // -----------------------------------------------------------
    // ACTUALIZAR SQLITE
    // -----------------------------------------------------------
    //
    // Si todavía no tiene idServidor, el datasource mantendrá una
    // operación CREAR.
    //
    // Si ya tiene idServidor, generará ACTUALIZAR.
    // -----------------------------------------------------------

    await _seguimientoDatasource.actualizar(actualizado);

    return actualizado;
  }

  // =============================================================
  // VERIFICAR SEGUIMIENTO OFFLINE
  // =============================================================

  /// Marca un seguimiento como verificado sin necesitar Internet.
  ///
  /// La fecha de verificación se genera automáticamente en UTC.
  ///
  /// La actualización queda pendiente en la cola y será enviada
  /// al backend cuando exista conexión.
  Future<SeguimientoIpercLocalModel> verifyOffline({
    required String idLocal,
  }) async {
    final SeguimientoIpercLocalModel existente = await _obtenerExistente(
      idLocal,
    );

    if (existente.eliminado) {
      throw StateError('No se puede verificar un seguimiento IPERC eliminado.');
    }

    // Si ya estaba verificado, no generamos una modificación inútil.
    if (existente.verificado) {
      return existente;
    }

    final int usuarioId = await _obtenerUsuarioAutenticadoId();

    final String? usuarioNombre = _textoOpcional(
      await _secureStorageService.getNombreUsuario(),
    );

    final DateTime ahora = DateTime.now().toUtc();

    final SeguimientoIpercLocalModel verificado = SeguimientoIpercLocalModel(
      idLocal: existente.idLocal,
      idServidor: existente.idServidor,
      detalleIpercIdLocal: existente.detalleIpercIdLocal,
      detalleIpercIdServidor: existente.detalleIpercIdServidor,
      detalleItem: existente.detalleItem,
      detalleTarea: existente.detalleTarea,
      fechaSeguimiento: existente.fechaSeguimiento,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre ?? existente.usuarioNombre,
      descripcion: existente.descripcion,
      porcentajeAvance: existente.porcentajeAvance,
      verificado: true,
      fechaVerificacion: ahora,
      observaciones: existente.observaciones,
      archivo: existente.archivo,
      nombreArchivo: existente.nombreArchivo,
      tipoArchivo: existente.tipoArchivo,
      sincronizado: false,
      eliminado: false,
      fechaRegistro: existente.fechaRegistro,
      fechaActualizacion: ahora,
      fechaSincronizacion: existente.fechaSincronizacion,
    );

    await _seguimientoDatasource.actualizar(verificado);

    return verificado;
  }

  // =============================================================
  // QUITAR VERIFICACIÓN OFFLINE
  // =============================================================

  /// Permite volver un seguimiento a estado pendiente.
  ///
  /// Se utiliza un constructor completo en vez de `copyWith`
  /// porque necesitamos establecer explícitamente:
  ///
  /// `fechaVerificacion = null`.
  Future<SeguimientoIpercLocalModel> unverifyOffline({
    required String idLocal,
  }) async {
    final SeguimientoIpercLocalModel existente = await _obtenerExistente(
      idLocal,
    );

    if (existente.eliminado) {
      throw StateError('No se puede modificar un seguimiento IPERC eliminado.');
    }

    if (!existente.verificado) {
      return existente;
    }

    final int usuarioId = await _obtenerUsuarioAutenticadoId();

    final String? usuarioNombre = _textoOpcional(
      await _secureStorageService.getNombreUsuario(),
    );

    final DateTime ahora = DateTime.now().toUtc();

    final SeguimientoIpercLocalModel pendiente = SeguimientoIpercLocalModel(
      idLocal: existente.idLocal,
      idServidor: existente.idServidor,
      detalleIpercIdLocal: existente.detalleIpercIdLocal,
      detalleIpercIdServidor: existente.detalleIpercIdServidor,
      detalleItem: existente.detalleItem,
      detalleTarea: existente.detalleTarea,
      fechaSeguimiento: existente.fechaSeguimiento,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre ?? existente.usuarioNombre,
      descripcion: existente.descripcion,
      porcentajeAvance: existente.porcentajeAvance,
      verificado: false,
      fechaVerificacion: null,
      observaciones: existente.observaciones,
      archivo: existente.archivo,
      nombreArchivo: existente.nombreArchivo,
      tipoArchivo: existente.tipoArchivo,
      sincronizado: false,
      eliminado: false,
      fechaRegistro: existente.fechaRegistro,
      fechaActualizacion: ahora,
      fechaSincronizacion: existente.fechaSincronizacion,
    );

    await _seguimientoDatasource.actualizar(pendiente);

    return pendiente;
  }

  // =============================================================
  // ELIMINAR SEGUIMIENTO OFFLINE
  // =============================================================

  /// Elimina lógicamente un seguimiento.
  ///
  /// El datasource decide cómo dejar la operación en la cola:
  ///
  /// - Si existía una operación anterior PENDIENTE/ERROR, la
  ///   reemplaza.
  /// - Finalmente registra ELIMINAR.
  ///
  /// La eliminación física del registro se realizará únicamente
  /// cuando el backend confirme la eliminación durante la
  /// sincronización.
  Future<void> deleteOffline({required String idLocal}) async {
    final SeguimientoIpercLocalModel existente = await _obtenerExistente(
      idLocal,
    );

    if (existente.eliminado) {
      return;
    }

    await _seguimientoDatasource.eliminar(existente.idLocal);
  }

  // =============================================================
  // CONSULTAS
  // =============================================================

  /// Devuelve todos los seguimientos no eliminados.
  Future<List<SeguimientoIpercLocalModel>> getAll() {
    return _seguimientoDatasource.listarTodos();
  }

  /// Devuelve los seguimientos de un Detalle IPERC usando su ID
  /// local, por lo que también funciona cuando el detalle todavía
  /// no existe en el backend.
  Future<List<SeguimientoIpercLocalModel>> getByDetalleLocal(
    String detalleIpercIdLocal,
  ) {
    return _seguimientoDatasource.listarPorDetalleLocal(detalleIpercIdLocal);
  }

  /// Consulta seguimientos usando el ID remoto del Detalle IPERC.
  ///
  /// Este método es útil para detalles que ya fueron sincronizados.
  Future<List<SeguimientoIpercLocalModel>> getByDetalleServidor(
    int detalleIpercIdServidor,
  ) {
    return _seguimientoDatasource.listarPorDetalleServidor(
      detalleIpercIdServidor,
    );
  }

  /// Obtiene un seguimiento local concreto.
  Future<SeguimientoIpercLocalModel?> getByIdLocal(String idLocal) {
    return _seguimientoDatasource.obtenerPorIdLocal(idLocal);
  }

  /// Devuelve registros que todavía requieren alguna operación de
  /// sincronización.
  Future<List<SeguimientoIpercLocalModel>> getPending() {
    return _seguimientoDatasource.listarPendientes();
  }

  /// Devuelve la cantidad de seguimientos aún no sincronizados.
  Future<int> countPending() {
    return _seguimientoDatasource.contarPendientes();
  }

  // =============================================================
  // HELPERS PRIVADOS
  // =============================================================

  /// Busca un seguimiento y genera un mensaje uniforme si no existe.
  Future<SeguimientoIpercLocalModel> _obtenerExistente(String idLocal) async {
    final String localId = idLocal.trim();

    if (localId.isEmpty) {
      throw ArgumentError(
        'El identificador local del seguimiento IPERC es obligatorio.',
      );
    }

    final SeguimientoIpercLocalModel? seguimiento = await _seguimientoDatasource
        .obtenerPorIdLocal(localId);

    if (seguimiento == null) {
      throw StateError('No se encontró el seguimiento IPERC local solicitado.');
    }

    return seguimiento;
  }

  /// Lee el usuario desde FlutterSecureStorage.
  ///
  /// No utiliza IDs fijos como `1`.
  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String? valor = await _secureStorageService.getUsuarioId();

    final int? usuarioId = int.tryParse(valor?.trim() ?? '');

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'No se encontró un usuario autenticado válido. '
        'Inicie sesión nuevamente.',
      );
    }

    return usuarioId;
  }

  /// Convierte el ID remoto del Detalle IPERC a entero.
  ///
  /// El modelo local de Detalle IPERC conserva actualmente
  /// `idServidor` como texto.
  int? _parseIdServidor(String? valor) {
    final int? id = int.tryParse(valor?.trim() ?? '');

    if (id == null || id <= 0) {
      return null;
    }

    return id;
  }

  /// Valida el rango permitido por el modelo y la base SQLite.
  void _validarPorcentaje(double porcentaje) {
    if (porcentaje < 0 || porcentaje > 100) {
      throw ArgumentError('El porcentaje de avance debe estar entre 0 y 100.');
    }
  }

  /// Normaliza textos opcionales.
  String? _textoOpcional(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
