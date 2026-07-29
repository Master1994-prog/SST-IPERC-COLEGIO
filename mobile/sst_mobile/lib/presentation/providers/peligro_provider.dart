import 'package:flutter/foundation.dart';

import '../../data/models/peligro_model.dart';
import '../../data/repositories/peligro_repository.dart';

class PeligroProvider extends ChangeNotifier {
  PeligroProvider({PeligroRepository? repository})
    : _repository = repository ?? PeligroRepository();

  final PeligroRepository _repository;

  final List<PeligroModel> _peligros = <PeligroModel>[];
  final List<PeligroModel> _peligrosFiltrados = <PeligroModel>[];

  bool _cargando = false;
  bool _guardando = false;
  bool _eliminando = false;

  String? _mensajeError;
  String _textoBusqueda = '';

  List<PeligroModel> get peligros => List<PeligroModel>.unmodifiable(_peligros);

  List<PeligroModel> get peligrosFiltrados =>
      List<PeligroModel>.unmodifiable(_peligrosFiltrados);

  bool get cargando => _cargando;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;

  String? get mensajeError => _mensajeError;
  String get textoBusqueda => _textoBusqueda;

  bool get tieneError =>
      _mensajeError != null && _mensajeError!.trim().isNotEmpty;

  bool get tienePeligros => _peligros.isNotEmpty;

  bool get tieneResultados => _peligrosFiltrados.isNotEmpty;

  int get cantidadTotal => _peligros.length;

  int get cantidadActivos {
    return _peligros.where((peligro) => peligro.estaDisponible).length;
  }

  int get cantidadInactivos {
    return _peligros.where((peligro) => !peligro.estaDisponible).length;
  }

  Future<void> cargarPeligros() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<PeligroModel> resultado = await _repository.obtenerTodos();

      resultado.sort((primero, segundo) {
        final int comparacionNombre = primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );

        if (comparacionNombre != 0) {
          return comparacionNombre;
        }

        return primero.codigo.toLowerCase().compareTo(
          segundo.codigo.toLowerCase(),
        );
      });

      _peligros
        ..clear()
        ..addAll(resultado);

      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _peligros.clear();
      _peligrosFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crearPeligro(CrearPeligroRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final PeligroModel creado = await _repository.crear(request);

      _peligros.add(creado);

      _ordenarPeligros();
      _aplicarFiltro();

      return true;
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarPeligro(
    int id,
    ActualizarPeligroRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final PeligroModel actualizado = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _peligros.indexWhere((peligro) => peligro.id == id);

      if (indice >= 0) {
        _peligros[indice] = actualizado;
      } else {
        _peligros.add(actualizado);
      }

      _ordenarPeligros();
      _aplicarFiltro();

      return true;
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarPeligro(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _peligros.removeWhere((peligro) => peligro.id == id);

      _aplicarFiltro();

      return true;
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      return false;
    } finally {
      _eliminando = false;
      notifyListeners();
    }
  }

  Future<PeligroModel?> obtenerPeligroPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador del peligro no es válido.';
      notifyListeners();
      return null;
    }

    final int indiceLocal = _peligros.indexWhere((peligro) => peligro.id == id);

    if (indiceLocal >= 0) {
      return _peligros[indiceLocal];
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      notifyListeners();
      return null;
    }
  }

  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  void limpiarBusqueda() {
    if (_textoBusqueda.isEmpty) {
      return;
    }

    _textoBusqueda = '';
    _aplicarFiltro();
    notifyListeners();
  }

  void limpiarError() {
    if (_mensajeError == null) {
      return;
    }

    _mensajeError = null;
    notifyListeners();
  }

  void reemplazarPeligro(PeligroModel peligro) {
    final int indice = _peligros.indexWhere(
      (elemento) => elemento.id == peligro.id,
    );

    if (indice >= 0) {
      _peligros[indice] = peligro;
    } else {
      _peligros.add(peligro);
    }

    _ordenarPeligros();
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _peligrosFiltrados.clear();

    if (criterio.isEmpty) {
      _peligrosFiltrados.addAll(_peligros);
      return;
    }

    _peligrosFiltrados.addAll(
      _peligros.where((peligro) {
        return peligro.codigo.toLowerCase().contains(criterio) ||
            peligro.nombre.toLowerCase().contains(criterio) ||
            peligro.descripcionVisible.toLowerCase().contains(criterio) ||
            peligro.categoriaVisible.toLowerCase().contains(criterio) ||
            peligro.tipoVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  void _ordenarPeligros() {
    _peligros.sort((primero, segundo) {
      final int comparacionNombre = primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );

      if (comparacionNombre != 0) {
        return comparacionNombre;
      }

      return primero.codigo.toLowerCase().compareTo(
        segundo.codigo.toLowerCase(),
      );
    });
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
