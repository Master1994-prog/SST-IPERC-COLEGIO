import 'package:flutter/foundation.dart';

import '../../data/models/detalle_iperc_local_model.dart';
import '../../data/repositories/detalle_iperc_local_repository.dart';

/// Administra los detalles IPERC almacenados localmente.
///
/// Permite trabajar sin conexión y mantiene informado a Flutter sobre:
/// - carga de registros;
/// - errores;
/// - detalles de la matriz seleccionada;
/// - cantidad de registros pendientes de sincronización.
class DetalleIpercOfflineProvider extends ChangeNotifier {
  DetalleIpercOfflineProvider({DetalleIpercLocalRepository? repository})
    : _repository = repository ?? DetalleIpercLocalRepository();

  final DetalleIpercLocalRepository _repository;

  final List<DetalleIpercLocalModel> _detalles = <DetalleIpercLocalModel>[];

  DetalleIpercLocalModel? _detalleSeleccionado;

  bool _cargando = false;
  bool _guardando = false;
  String? _error;
  String? _matrizIdLocal;
  int _cantidadPendientes = 0;

  /// Lista inmutable de detalles cargados.
  List<DetalleIpercLocalModel> get detalles =>
      List<DetalleIpercLocalModel>.unmodifiable(_detalles);

  DetalleIpercLocalModel? get detalleSeleccionado => _detalleSeleccionado;

  bool get cargando => _cargando;
  bool get guardando => _guardando;

  /// Indica que el provider está realizando alguna operación.
  bool get procesando => _cargando || _guardando;

  String? get error => _error;
  bool get tieneError => _error != null && _error!.isNotEmpty;

  String? get matrizIdLocal => _matrizIdLocal;

  int get cantidadPendientes => _cantidadPendientes;
  bool get tienePendientes => _cantidadPendientes > 0;
  bool get estaVacio => _detalles.isEmpty;

  /// Carga los detalles activos de una matriz IPERC.
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

      await _actualizarCantidadPendientesInternamente();
    } catch (error) {
      _error = _obtenerMensajeError(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Recarga la matriz que está actualmente seleccionada.
  Future<void> recargar() async {
    final String? matrizId = _matrizIdLocal;

    if (matrizId == null || matrizId.isEmpty) {
      _establecerError('Primero debe seleccionarse una matriz IPERC.');
      return;
    }

    await cargarPorMatriz(matrizId, mostrarCarga: false);
  }

  /// Obtiene un detalle mediante su identificador local.
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

  /// Selecciona un detalle que ya se encuentra cargado.
  void seleccionarDetalle(DetalleIpercLocalModel? detalle) {
    _detalleSeleccionado = detalle;
    notifyListeners();
  }

  /// Limpia el detalle seleccionado.
  void limpiarSeleccion() {
    if (_detalleSeleccionado == null) {
      return;
    }

    _detalleSeleccionado = null;
    notifyListeners();
  }

  /// Registra una evaluación IPERC localmente.
  ///
  /// El datasource agregará automáticamente la operación CREAR
  /// a la cola de sincronización.
  Future<bool> crear(DetalleIpercLocalModel detalle) async {
    if (_guardando) {
      return false;
    }

    _iniciarGuardado();

    try {
      await _repository.crear(detalle);

      if (_matrizIdLocal == detalle.matrizIdLocal) {
        _detalles.add(detalle);
        _ordenarDetalles();
      }

      _detalleSeleccionado = detalle;

      await _actualizarCantidadPendientesInternamente();

      return true;
    } catch (error) {
      _error = _obtenerMensajeError(error);
      return false;
    } finally {
      _finalizarGuardado();
    }
  }

  /// Actualiza una evaluación IPERC almacenada localmente.
  Future<bool> actualizar(DetalleIpercLocalModel detalle) async {
    if (_guardando) {
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

      final int indice = _detalles.indexWhere(
        (DetalleIpercLocalModel item) => item.idLocal == actualizado.idLocal,
      );

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

  /// Elimina lógicamente un detalle.
  ///
  /// El registro desaparecerá de la pantalla, pero permanecerá en SQLite
  /// hasta que su eliminación sea confirmada por el backend.
  Future<bool> eliminar(String idLocal) async {
    if (_guardando) {
      return false;
    }

    _iniciarGuardado();

    try {
      await _repository.eliminar(idLocal);

      _detalles.removeWhere(
        (DetalleIpercLocalModel detalle) => detalle.idLocal == idLocal,
      );

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

  /// Consulta y actualiza la cantidad de registros pendientes.
  Future<void> actualizarCantidadPendientes() async {
    try {
      await _actualizarCantidadPendientesInternamente();
      notifyListeners();
    } catch (error) {
      _establecerError(_obtenerMensajeError(error));
    }
  }

  /// Marca un detalle como sincronizado con el backend.
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

  /// Confirma una eliminación realizada correctamente en el backend.
  Future<bool> confirmarEliminacionSincronizada(String idLocal) async {
    try {
      await _repository.confirmarEliminacionSincronizada(idLocal);

      _detalles.removeWhere(
        (DetalleIpercLocalModel detalle) => detalle.idLocal == idLocal,
      );

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

  /// Guarda un detalle recibido desde el servidor.
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

  /// Elimina el mensaje de error mostrado en la interfaz.
  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  /// Limpia la información al salir de una matriz.
  void limpiar() {
    _detalles.clear();
    _detalleSeleccionado = null;
    _matrizIdLocal = null;
    _error = null;
    _cargando = false;
    _guardando = false;
    notifyListeners();
  }

  Future<void> _reemplazarDetalleDesdeBase(String idLocal) async {
    final DetalleIpercLocalModel? actualizado = await _repository
        .obtenerPorIdLocal(idLocal);

    if (actualizado == null) {
      return;
    }

    final int indice = _detalles.indexWhere(
      (DetalleIpercLocalModel detalle) => detalle.idLocal == idLocal,
    );

    if (actualizado.eliminado) {
      if (indice >= 0) {
        _detalles.removeAt(indice);
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

    return 'Ocurrió un error al administrar el detalle IPERC: $error';
  }
}
