import 'package:flutter/foundation.dart';

import '../../data/models/tipo_peligro_model.dart';
import '../../data/repositories/tipo_peligro_repository.dart';

/// Provider encargado de administrar el estado
/// del catálogo Tipos de Peligro.
class TipoPeligroProvider extends ChangeNotifier {
  TipoPeligroProvider({TipoPeligroRepository? repository})
    : _repository = repository ?? TipoPeligroRepository();

  final TipoPeligroRepository _repository;

  final List<TipoPeligroModel> _tipos = <TipoPeligroModel>[];

  final List<TipoPeligroModel> _tiposFiltrados = <TipoPeligroModel>[];

  bool _cargando = false;
  bool _guardando = false;
  bool _eliminando = false;

  String? _mensajeError;
  String _textoBusqueda = '';

  /// Lista completa de tipos.
  List<TipoPeligroModel> get tipos {
    return List<TipoPeligroModel>.unmodifiable(_tipos);
  }

  /// Lista filtrada.
  List<TipoPeligroModel> get tiposFiltrados {
    return List<TipoPeligroModel>.unmodifiable(_tiposFiltrados);
  }

  bool get cargando => _cargando;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;

  String? get mensajeError => _mensajeError;
  String get textoBusqueda => _textoBusqueda;

  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  bool get tieneTipos {
    return _tipos.isNotEmpty;
  }

  bool get tieneResultados {
    return _tiposFiltrados.isNotEmpty;
  }

  int get cantidadTotal {
    return _tipos.length;
  }

  int get cantidadActivos {
    return _tipos.where((TipoPeligroModel tipo) => tipo.estaDisponible).length;
  }

  int get cantidadInactivos {
    return _tipos.where((TipoPeligroModel tipo) => !tipo.estaDisponible).length;
  }

  /// Carga todos los tipos de peligro.
  Future<void> cargarTipos() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<TipoPeligroModel> resultado = await _repository.obtenerTodos();

      _tipos
        ..clear()
        ..addAll(resultado);

      _ordenarTipos();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _tipos.clear();
      _tiposFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Carga solamente los tipos activos.
  ///
  /// Este método se utilizará en formularios
  /// de creación y edición de peligros.
  Future<void> cargarTiposActivos() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<TipoPeligroModel> resultado = await _repository
          .obtenerActivos();

      _tipos
        ..clear()
        ..addAll(resultado);

      _ordenarTipos();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _tipos.clear();
      _tiposFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra un nuevo tipo de peligro.
  Future<bool> crearTipo(CrearTipoPeligroRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final TipoPeligroModel creado = await _repository.crear(request);

      _tipos.add(creado);

      _ordenarTipos();
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

  /// Actualiza un tipo de peligro.
  Future<bool> actualizarTipo(
    int id,
    ActualizarTipoPeligroRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final TipoPeligroModel actualizado = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _tipos.indexWhere(
        (TipoPeligroModel tipo) => tipo.id == id,
      );

      if (indice >= 0) {
        _tipos[indice] = actualizado;
      } else {
        _tipos.add(actualizado);
      }

      _ordenarTipos();
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

  /// Elimina o desactiva un tipo de peligro.
  Future<bool> eliminarTipo(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _tipos.removeWhere((TipoPeligroModel tipo) => tipo.id == id);

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

  /// Obtiene un tipo por ID.
  ///
  /// Primero busca en memoria y luego consulta
  /// al backend.
  Future<TipoPeligroModel?> obtenerTipoPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador del tipo de peligro no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _tipos.indexWhere(
      (TipoPeligroModel tipo) => tipo.id == id,
    );

    if (indiceLocal >= 0) {
      return _tipos[indiceLocal];
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      notifyListeners();
      return null;
    }
  }

  /// Aplica una búsqueda local.
  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Limpia el criterio de búsqueda.
  void limpiarBusqueda() {
    if (_textoBusqueda.isEmpty) {
      return;
    }

    _textoBusqueda = '';
    _aplicarFiltro();
    notifyListeners();
  }

  /// Limpia el mensaje de error.
  void limpiarError() {
    if (_mensajeError == null) {
      return;
    }

    _mensajeError = null;
    notifyListeners();
  }

  /// Busca un tipo directamente en memoria.
  TipoPeligroModel? buscarTipoLocal(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final TipoPeligroModel tipo in _tipos) {
      if (tipo.id == id) {
        return tipo;
      }
    }

    return null;
  }

  /// Reemplaza o agrega un registro.
  void reemplazarTipo(TipoPeligroModel tipo) {
    final int indice = _tipos.indexWhere(
      (TipoPeligroModel elemento) => elemento.id == tipo.id,
    );

    if (indice >= 0) {
      _tipos[indice] = tipo;
    } else {
      _tipos.add(tipo);
    }

    _ordenarTipos();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Aplica el filtro de búsqueda.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _tiposFiltrados.clear();

    if (criterio.isEmpty) {
      _tiposFiltrados.addAll(_tipos);
      return;
    }

    _tiposFiltrados.addAll(
      _tipos.where((TipoPeligroModel tipo) {
        return tipo.codigo.toLowerCase().contains(criterio) ||
            tipo.nombre.toLowerCase().contains(criterio) ||
            tipo.descripcionVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  /// Ordena los registros por nombre.
  void _ordenarTipos() {
    _tipos.sort((TipoPeligroModel primero, TipoPeligroModel segundo) {
      return primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );
    });
  }

  /// Limpia el prefijo Exception.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
