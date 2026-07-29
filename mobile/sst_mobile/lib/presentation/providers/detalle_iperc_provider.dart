import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../data/models/detalle_iperc_model.dart';
import '../../data/repositories/detalle_iperc_repository.dart';

/// Administra el estado de los peligros evaluados de una matriz IPERC.
class DetalleIpercProvider extends ChangeNotifier {
  DetalleIpercProvider({DetalleIpercRepository? repository})
    : _repository = repository ?? DetalleIpercRepository();

  final DetalleIpercRepository _repository;
  final List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];

  bool _cargando = false;
  bool _procesando = false;
  String? _error;
  String _terminoBusqueda = '';
  int? _matrizIpercIdActual;

  UnmodifiableListView<DetalleIpercModel> get detalles {
    return UnmodifiableListView<DetalleIpercModel>(_detalles);
  }

  List<DetalleIpercModel> get detallesFiltrados {
    final String termino = _normalizar(_terminoBusqueda);

    if (termino.isEmpty) {
      return List<DetalleIpercModel>.unmodifiable(_detalles);
    }

    return _detalles.where((DetalleIpercModel detalle) {
      final String contenido = _normalizar(
        '${detalle.item} ${detalle.tarea} ${detalle.peligroVisible} '
        '${detalle.consecuenciaVisible} ${detalle.descripcionVisible} '
        '${detalle.estadoImplementacionNombre}',
      );

      return contenido.contains(termino);
    }).toList(growable: false);
  }

  bool get cargando => _cargando;
  bool get procesando => _procesando;
  String? get error => _error;
  String get terminoBusqueda => _terminoBusqueda;
  int get cantidadDetalles => _detalles.length;
  int get cantidadConRiesgoResidual {
    return _detalles
        .where((DetalleIpercModel detalle) => detalle.tieneEvaluacionResidual)
        .length;
  }

  bool get tieneDetalles => _detalles.isNotEmpty;
  bool get tieneError => _error != null && _error!.trim().isNotEmpty;

  int get siguienteItem {
    if (_detalles.isEmpty) {
      return 1;
    }

    final int ultimoItem = _detalles
        .map((DetalleIpercModel detalle) => detalle.item)
        .fold<int>(0, (int mayor, int item) => item > mayor ? item : mayor);

    return ultimoItem + 1;
  }

  Future<void> cargarPorMatriz(int matrizIpercId) async {
    if (_cargando) {
      return;
    }

    if (matrizIpercId <= 0) {
      _error = 'El identificador de la matriz IPERC no es válido.';
      notifyListeners();
      return;
    }

    _matrizIpercIdActual = matrizIpercId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final List<DetalleIpercModel> resultado = await _repository
          .obtenerPorMatriz(matrizIpercId);

      _detalles
        ..clear()
        ..addAll(resultado);
      _ordenar();
    } catch (error) {
      _detalles.clear();
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() async {
    final int? matrizId = _matrizIpercIdActual;

    if (matrizId == null) {
      _error = 'No se ha seleccionado una matriz IPERC.';
      notifyListeners();
      return;
    }

    await cargarPorMatriz(matrizId);
  }

  /// Registra un nuevo peligro evaluado y actualiza la lista de la matriz.
  Future<bool> crear(CrearDetalleIpercRequest request) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.crear(request);
      _matrizIpercIdActual = request.matrizIpercId;

      final List<DetalleIpercModel> resultado = await _repository
          .obtenerPorMatriz(request.matrizIpercId);

      _detalles
        ..clear()
        ..addAll(resultado);
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
    ActualizarDetalleIpercRequest request,
  ) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      final DetalleIpercModel actualizado = await _repository.actualizar(
        id,
        request,
      );
      _matrizIpercIdActual = request.matrizIpercId;

      final int index = _detalles.indexWhere(
        (DetalleIpercModel detalle) => detalle.id == id,
      );

      if (index >= 0) {
        _detalles[index] = actualizado;
      } else {
        _detalles.add(actualizado);
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

  Future<bool> eliminar(int id) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);
      _detalles.removeWhere((DetalleIpercModel detalle) => detalle.id == id);
      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void _ordenar() {
    _detalles.sort((DetalleIpercModel a, DetalleIpercModel b) {
      final int porItem = a.item.compareTo(b.item);
      return porItem != 0 ? porItem : a.id.compareTo(b.id);
    });
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
