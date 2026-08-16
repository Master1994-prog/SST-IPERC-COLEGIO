import 'package:flutter/foundation.dart';

import '../../core/services/sync_service.dart';
import '../../data/models/detalle_iperc_local_model.dart';
import '../../data/repositories/detalle_iperc_local_repository.dart';
import '../../data/services/detalle_iperc_sync_service.dart';

/// ===============================================================
/// PROVIDER OFFLINE - DETALLE IPERC
/// ===============================================================
///
/// Administra los detalles IPERC almacenados localmente.
///
/// IMPORTANTE:
///
/// La sincronización manual ya NO utiliza directamente
/// DetalleIpercSyncService.
///
/// Toda sincronización pasa por SyncService para respetar siempre:
///
/// MATRIZ_IPERC
///      ↓
/// DETALLE_IPERC
///
/// De esta forma un detalle nunca intenta llegar al backend antes
/// de que su matriz padre tenga un ID válido del servidor.
/// ===============================================================
class DetalleIpercOfflineProvider extends ChangeNotifier {
  factory DetalleIpercOfflineProvider({
    DetalleIpercLocalRepository? repository,
    SyncService? syncService,
  }) {
    final DetalleIpercLocalRepository repositorio =
        repository ?? DetalleIpercLocalRepository();

    return DetalleIpercOfflineProvider._(
      repository: repositorio,
      syncService: syncService ?? SyncService(),
    );
  }

  DetalleIpercOfflineProvider._({
    required this._repository,
    required this._syncService,
  });

  final DetalleIpercLocalRepository _repository;

  /// Servicio GENERAL de sincronización.
  ///
  /// No utilizar aquí DetalleIpercSyncService para sincronización
  /// manual porque se perdería el orden Matriz -> Detalle.
  final SyncService _syncService;

  final List<DetalleIpercLocalModel> _detalles = <DetalleIpercLocalModel>[];

  DetalleIpercLocalModel? _detalleSeleccionado;

  bool _cargando = false;
  bool _guardando = false;
  bool _sincronizando = false;

  String? _error;
  String? _errorSincronizacion;

  String? _matrizIdLocal;

  int _cantidadPendientes = 0;

  DetalleIpercSyncResult? _ultimoResultadoSincronizacion;

  // ============================================================
  // GETTERS
  // ============================================================

  List<DetalleIpercLocalModel> get detalles {
    return List<DetalleIpercLocalModel>.unmodifiable(_detalles);
  }

  DetalleIpercLocalModel? get detalleSeleccionado {
    return _detalleSeleccionado;
  }

  bool get cargando {
    return _cargando;
  }

  bool get guardando {
    return _guardando;
  }

  bool get sincronizando {
    return _sincronizando;
  }

  bool get procesando {
    return _cargando || _guardando || _sincronizando;
  }

  String? get error {
    return _error;
  }

  bool get tieneError {
    return _error != null && _error!.trim().isNotEmpty;
  }

  String? get errorSincronizacion {
    return _errorSincronizacion;
  }

  bool get tieneErrorSincronizacion {
    return _errorSincronizacion != null &&
        _errorSincronizacion!.trim().isNotEmpty;
  }

  DetalleIpercSyncResult? get ultimoResultadoSincronizacion {
    return _ultimoResultadoSincronizacion;
  }

  String? get matrizIdLocal {
    return _matrizIdLocal;
  }

  int get cantidadPendientes {
    return _cantidadPendientes;
  }

  bool get tienePendientes {
    return _cantidadPendientes > 0;
  }

  bool get estaVacio {
    return _detalles.isEmpty;
  }

  // ============================================================
  // CARGA DE DETALLES
  // ============================================================

  Future<void> cargarPorMatriz(
    String matrizIdLocal, {
    bool mostrarCarga = true,
  }) async {
    final String matrizId = matrizIdLocal.trim();

    if (matrizId.isEmpty) {
      _establecerError('El identificador local de la matriz es obligatorio.');
      return;
    }

    _matrizIdLocal = matrizId;
    _error = null;

    if (mostrarCarga) {
      _cargando = true;
      notifyListeners();
    }

    try {
      final List<DetalleIpercLocalModel> resultado = await _repository
          .listarPorMatriz(matrizId);

      _detalles
        ..clear()
        ..addAll(resultado);

      _ordenarDetalles();

      await _actualizarCantidadPendientesInternamente();
    } catch (error) {
      _error = _obtenerMensajeError(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargar() async {
    final String? matrizId = _matrizIdLocal;

    if (matrizId == null || matrizId.trim().isEmpty) {
      _establecerError('Primero debe seleccionarse una matriz IPERC.');
      return;
    }

    await cargarPorMatriz(matrizId, mostrarCarga: false);
  }

  Future<DetalleIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    _error = null;

    try {
      final DetalleIpercLocalModel? detalle = await _repository
          .obtenerPorIdLocal(idLocal);

      _detalleSeleccionado = detalle;

      notifyListeners();

      return detalle;
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));

      return null;
    }
  }

  void seleccionarDetalle(DetalleIpercLocalModel? detalle) {
    _detalleSeleccionado = detalle;

    notifyListeners();
  }

  void limpiarSeleccion() {
    if (_detalleSeleccionado == null) {
      return;
    }

    _detalleSeleccionado = null;

    notifyListeners();
  }

  // ============================================================
  // CREACIÓN
  // ============================================================

  Future<bool> crear(DetalleIpercLocalModel detalle) async {
    if (_guardando || _sincronizando) {
      return false;
    }

    _iniciarGuardado();

    try {
      await _repository.crear(detalle);

      final DetalleIpercLocalModel? creado = await _repository
          .obtenerPorIdLocal(detalle.idLocal);

      final DetalleIpercLocalModel detalleGuardado = creado ?? detalle;

      if (_matrizIdLocal == detalleGuardado.matrizIdLocal) {
        final int indice = _detalles.indexWhere((DetalleIpercLocalModel item) {
          return item.idLocal == detalleGuardado.idLocal;
        });

        if (indice >= 0) {
          _detalles[indice] = detalleGuardado;
        } else {
          _detalles.add(detalleGuardado);
        }

        _ordenarDetalles();
      }

      _detalleSeleccionado = detalleGuardado;

      await _actualizarCantidadPendientesInternamente();

      return true;
    } catch (error) {
      _error = _obtenerMensajeError(error);

      return false;
    } finally {
      _finalizarGuardado();
    }
  }

  // ============================================================
  // ACTUALIZACIÓN
  // ============================================================

  Future<bool> actualizar(DetalleIpercLocalModel detalle) async {
    if (_guardando || _sincronizando) {
      return false;
    }

    _iniciarGuardado();

    try {
      await _repository.actualizar(detalle);

      final DetalleIpercLocalModel? actualizado = await _repository
          .obtenerPorIdLocal(detalle.idLocal);

      if (actualizado == null) {
        throw StateError('No se pudo recuperar el detalle IPERC actualizado.');
      }

      final int indice = _detalles.indexWhere((DetalleIpercLocalModel item) {
        return item.idLocal == actualizado.idLocal;
      });

      if (indice >= 0) {
        _detalles[indice] = actualizado;
      } else if (_matrizIdLocal == actualizado.matrizIdLocal &&
          !actualizado.eliminado) {
        _detalles.add(actualizado);
      }

      _ordenarDetalles();

      _detalleSeleccionado = actualizado;

      await _actualizarCantidadPendientesInternamente();

      return true;
    } catch (error) {
      _error = _obtenerMensajeError(error);

      return false;
    } finally {
      _finalizarGuardado();
    }
  }

  // ============================================================
  // ELIMINACIÓN
  // ============================================================

  Future<bool> eliminar(String idLocal) async {
    if (_guardando || _sincronizando) {
      return false;
    }

    _iniciarGuardado();

    try {
      await _repository.eliminar(idLocal);

      _detalles.removeWhere((DetalleIpercLocalModel detalle) {
        return detalle.idLocal == idLocal;
      });

      if (_detalleSeleccionado?.idLocal == idLocal) {
        _detalleSeleccionado = null;
      }

      await _actualizarCantidadPendientesInternamente();

      return true;
    } catch (error) {
      _error = _obtenerMensajeError(error);

      return false;
    } finally {
      _finalizarGuardado();
    }
  }

  // ============================================================
  // PENDIENTES
  // ============================================================

  Future<void> actualizarCantidadPendientes() async {
    try {
      await _actualizarCantidadPendientesInternamente();

      notifyListeners();
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));
    }
  }

  // ============================================================
  // SINCRONIZACIÓN GLOBAL
  // ============================================================

  /// Mantiene la firma histórica del provider, pero internamente
  /// utiliza SyncService GENERAL.
  ///
  /// Esto garantiza que primero se procesen las matrices y después
  /// los detalles.
  Future<DetalleIpercSyncResult?> sincronizarPendientes() async {
    if (_sincronizando || _guardando || _cargando) {
      return null;
    }

    if (_cantidadPendientes <= 0) {
      _errorSincronizacion = null;

      _ultimoResultadoSincronizacion = const DetalleIpercSyncResult(
        total: 0,
        sincronizados: 0,
        fallidos: 0,
        errores: <String>[],
      );

      notifyListeners();

      return _ultimoResultadoSincronizacion;
    }

    _sincronizando = true;
    _errorSincronizacion = null;
    _ultimoResultadoSincronizacion = null;

    notifyListeners();

    try {
      final SyncResult resultadoGlobal = await _syncService
          .synchronizePending();

      final List<String> errores = <String>[];

      if (resultadoGlobal.withoutConnection) {
        errores.add('No hay conexión con el servidor.');
      } else if (resultadoGlobal.failed > 0) {
        errores.add(
          'No se pudieron sincronizar '
          '${resultadoGlobal.failed} operación(es).',
        );
      }

      final DetalleIpercSyncResult resultado = DetalleIpercSyncResult(
        total: resultadoGlobal.total,
        sincronizados: resultadoGlobal.synchronized,
        fallidos: resultadoGlobal.withoutConnection
            ? resultadoGlobal.total
            : resultadoGlobal.failed,
        errores: errores,
      );

      _ultimoResultadoSincronizacion = resultado;

      if (errores.isNotEmpty) {
        _errorSincronizacion = errores.join('\n');
      }

      await _recargarDetallesActuales();

      await _actualizarCantidadPendientesInternamente();

      return resultado;
    } catch (error) {
      _errorSincronizacion = _obtenerMensajeError(error);

      return null;
    } finally {
      _sincronizando = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CONFIRMACIONES LOCALES
  // ============================================================

  Future<bool> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
  }) async {
    try {
      await _repository.marcarComoSincronizado(
        idLocal: idLocal,
        idServidor: idServidor,
      );

      await _reemplazarDetalleDesdeBase(idLocal);

      await _actualizarCantidadPendientesInternamente();

      notifyListeners();

      return true;
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));

      return false;
    }
  }

  Future<bool> confirmarEliminacionSincronizada(String idLocal) async {
    try {
      await _repository.confirmarEliminacionSincronizada(idLocal);

      _detalles.removeWhere((DetalleIpercLocalModel detalle) {
        return detalle.idLocal == idLocal;
      });

      if (_detalleSeleccionado?.idLocal == idLocal) {
        _detalleSeleccionado = null;
      }

      await _actualizarCantidadPendientesInternamente();

      notifyListeners();

      return true;
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));

      return false;
    }
  }

  Future<bool> guardarDesdeServidor(DetalleIpercLocalModel detalle) async {
    try {
      await _repository.guardarDesdeServidor(detalle);

      if (_matrizIdLocal == detalle.matrizIdLocal) {
        await _reemplazarDetalleDesdeBase(detalle.idLocal);
      }

      await _actualizarCantidadPendientesInternamente();

      notifyListeners();

      return true;
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));

      return false;
    }
  }

  void limpiarErrorSincronizacion() {
    if (_errorSincronizacion == null) {
      return;
    }

    _errorSincronizacion = null;

    notifyListeners();
  }

  // ============================================================
  // LIMPIEZA
  // ============================================================

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }

  void limpiar() {
    _detalles.clear();

    _detalleSeleccionado = null;
    _matrizIdLocal = null;

    _error = null;
    _errorSincronizacion = null;

    _ultimoResultadoSincronizacion = null;

    _cargando = false;
    _guardando = false;
    _sincronizando = false;

    _cantidadPendientes = 0;

    notifyListeners();
  }

  // ============================================================
  // MÉTODOS INTERNOS
  // ============================================================

  Future<void> _recargarDetallesActuales() async {
    final String? matrizId = _matrizIdLocal;

    if (matrizId == null || matrizId.trim().isEmpty) {
      return;
    }

    final List<DetalleIpercLocalModel> resultado = await _repository
        .listarPorMatriz(matrizId);

    _detalles
      ..clear()
      ..addAll(resultado);

    _ordenarDetalles();

    final String? idSeleccionado = _detalleSeleccionado?.idLocal;

    if (idSeleccionado == null) {
      return;
    }

    DetalleIpercLocalModel? detalleActualizado;

    for (final DetalleIpercLocalModel detalle in _detalles) {
      if (detalle.idLocal == idSeleccionado) {
        detalleActualizado = detalle;
        break;
      }
    }

    _detalleSeleccionado = detalleActualizado;
  }

  Future<void> _reemplazarDetalleDesdeBase(String idLocal) async {
    final DetalleIpercLocalModel? actualizado = await _repository
        .obtenerPorIdLocal(idLocal);

    final int indice = _detalles.indexWhere((DetalleIpercLocalModel detalle) {
      return detalle.idLocal == idLocal;
    });

    if (actualizado == null || actualizado.eliminado) {
      if (indice >= 0) {
        _detalles.removeAt(indice);
      }

      if (_detalleSeleccionado?.idLocal == idLocal) {
        _detalleSeleccionado = null;
      }

      return;
    }

    if (indice >= 0) {
      _detalles[indice] = actualizado;
    } else if (_matrizIdLocal == actualizado.matrizIdLocal) {
      _detalles.add(actualizado);
    }

    if (_detalleSeleccionado?.idLocal == idLocal) {
      _detalleSeleccionado = actualizado;
    }

    _ordenarDetalles();
  }

  Future<void> _actualizarCantidadPendientesInternamente() async {
    _cantidadPendientes = await _repository.contarPendientes();
  }

  void _ordenarDetalles() {
    _detalles.sort((
      DetalleIpercLocalModel primero,
      DetalleIpercLocalModel segundo,
    ) {
      final int comparacionItem = primero.item.compareTo(segundo.item);

      if (comparacionItem != 0) {
        return comparacionItem;
      }

      return primero.fechaRegistro.compareTo(segundo.fechaRegistro);
    });
  }

  void _iniciarGuardado() {
    _guardando = true;
    _error = null;

    notifyListeners();
  }

  void _finalizarGuardado() {
    _guardando = false;

    notifyListeners();
  }

  void _establecerError(String mensaje) {
    _error = mensaje;

    notifyListeners();
  }

  String _obtenerMensajeError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ??
          'Los datos ingresados no son válidos.';
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
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    if (mensaje.isEmpty) {
      return 'Ocurrió un error inesperado al administrar '
          'el detalle IPERC.';
    }

    return mensaje;
  }
}
