import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../data/models/seguimiento_iperc_model.dart';
import '../../data/repositories/seguimiento_iperc_repository.dart';

/// Administra el estado de los seguimientos IPERC.
class SeguimientoIpercProvider extends ChangeNotifier {
  SeguimientoIpercProvider({SeguimientoIpercRepository? repository})
    : _repository = repository ?? SeguimientoIpercRepository();

  final SeguimientoIpercRepository _repository;
  final List<SeguimientoIpercModel> _seguimientos = <SeguimientoIpercModel>[];

  bool _cargando = false;
  bool _procesando = false;
  String? _error;
  String _terminoBusqueda = '';
  int? _detalleIpercIdActual;

  UnmodifiableListView<SeguimientoIpercModel> get seguimientos {
    return UnmodifiableListView<SeguimientoIpercModel>(_seguimientos);
  }

  List<SeguimientoIpercModel> get seguimientosFiltrados {
    final String termino = _normalizar(_terminoBusqueda);

    if (termino.isEmpty) {
      return List<SeguimientoIpercModel>.unmodifiable(_seguimientos);
    }

    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) {
          final String contenido = _normalizar(
            '${seguimiento.detalleVisible} ${seguimiento.descripcion} '
            '${seguimiento.observaciones ?? ''} ${seguimiento.estadoVisible}',
          );

          return contenido.contains(termino);
        })
        .toList(growable: false);
  }

  bool get cargando => _cargando;
  bool get procesando => _procesando;
  String? get error => _error;
  String get terminoBusqueda => _terminoBusqueda;
  bool get tieneError => _error != null && _error!.trim().isNotEmpty;
  bool get tieneSeguimientos => _seguimientos.isNotEmpty;
  int get total => _seguimientos.length;

  int get pendientes {
    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) => !seguimiento.verificado)
        .length;
  }

  int get verificados {
    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) => seguimiento.verificado)
        .length;
  }

  Future<void> cargarTodos() async {
    if (_cargando) {
      return;
    }

    _detalleIpercIdActual = null;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final List<SeguimientoIpercModel> resultado = await _repository
          .obtenerTodos();

      _seguimientos
        ..clear()
        ..addAll(resultado);
      _ordenar();
    } catch (error) {
      _seguimientos.clear();
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarPorDetalle(int detalleIpercId) async {
    if (_cargando) {
      return;
    }

    if (detalleIpercId <= 0) {
      _error = 'El identificador del detalle IPERC no es válido.';
      notifyListeners();
      return;
    }

    _detalleIpercIdActual = detalleIpercId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final List<SeguimientoIpercModel> resultado = await _repository
          .obtenerPorDetalle(detalleIpercId);

      _seguimientos
        ..clear()
        ..addAll(resultado);
      _ordenar();
    } catch (error) {
      _seguimientos.clear();
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() async {
    final int? detalleId = _detalleIpercIdActual;

    if (detalleId == null) {
      await cargarTodos();
      return;
    }

    await cargarPorDetalle(detalleId);
  }

  Future<bool> crear(CrearSeguimientoIpercRequest request) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      final SeguimientoIpercModel creado = await _repository.crear(request);
      _seguimientos.insert(0, creado);
      _ordenar();
      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizar(
    int id,
    ActualizarSeguimientoIpercRequest request,
  ) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      final SeguimientoIpercModel actualizado = await _repository.actualizar(
        id,
        request,
      );
      final int index = _seguimientos.indexWhere(
        (SeguimientoIpercModel seguimiento) => seguimiento.id == id,
      );

      if (index >= 0) {
        _seguimientos[index] = actualizado;
      } else {
        _seguimientos.add(actualizado);
      }

      _ordenar();
      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  Future<bool> verificar(int id) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.verificar(id);
      await refrescar();
      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminar(int id) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);
      _seguimientos.removeWhere(
        (SeguimientoIpercModel seguimiento) => seguimiento.id == id,
      );
      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  void buscar(String valor) {
    _terminoBusqueda = valor.trim();
    notifyListeners();
  }

  void limpiarBusqueda() {
    if (_terminoBusqueda.isEmpty) {
      return;
    }

    _terminoBusqueda = '';
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void _ordenar() {
    _seguimientos.sort(
      (SeguimientoIpercModel a, SeguimientoIpercModel b) =>
          b.fechaSeguimiento.compareTo(a.fechaSeguimiento),
    );
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}
