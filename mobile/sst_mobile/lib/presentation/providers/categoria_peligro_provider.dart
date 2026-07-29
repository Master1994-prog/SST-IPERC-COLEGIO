import 'package:flutter/foundation.dart';

import '../../data/models/categoria_peligro_model.dart';
import '../../data/repositories/categoria_peligro_repository.dart';

/// Provider encargado de administrar el estado
/// del catálogo Categorías de Peligro.
class CategoriaPeligroProvider extends ChangeNotifier {
  CategoriaPeligroProvider({CategoriaPeligroRepository? repository})
    : _repository = repository ?? CategoriaPeligroRepository();

  final CategoriaPeligroRepository _repository;

  final List<CategoriaPeligroModel> _categorias = <CategoriaPeligroModel>[];

  final List<CategoriaPeligroModel> _categoriasFiltradas =
      <CategoriaPeligroModel>[];

  bool _cargando = false;
  bool _guardando = false;
  bool _eliminando = false;

  String? _mensajeError;
  String _textoBusqueda = '';

  /// Lista completa.
  List<CategoriaPeligroModel> get categorias {
    return List<CategoriaPeligroModel>.unmodifiable(_categorias);
  }

  /// Lista filtrada.
  List<CategoriaPeligroModel> get categoriasFiltradas {
    return List<CategoriaPeligroModel>.unmodifiable(_categoriasFiltradas);
  }

  bool get cargando => _cargando;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;

  String? get mensajeError => _mensajeError;
  String get textoBusqueda => _textoBusqueda;

  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  bool get tieneCategorias {
    return _categorias.isNotEmpty;
  }

  bool get tieneResultados {
    return _categoriasFiltradas.isNotEmpty;
  }

  int get cantidadTotal {
    return _categorias.length;
  }

  int get cantidadActivas {
    return _categorias.where((CategoriaPeligroModel categoria) {
      return categoria.estaDisponible;
    }).length;
  }

  int get cantidadInactivas {
    return _categorias.where((CategoriaPeligroModel categoria) {
      return !categoria.estaDisponible;
    }).length;
  }

  /// Carga todas las categorías.
  Future<void> cargarCategorias() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<CategoriaPeligroModel> resultado = await _repository
          .obtenerTodas();

      _categorias
        ..clear()
        ..addAll(resultado);

      _ordenarCategorias();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _categorias.clear();
      _categoriasFiltradas.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Carga solamente las categorías activas.
  Future<void> cargarCategoriasActivas() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<CategoriaPeligroModel> resultado = await _repository
          .obtenerActivas();

      _categorias
        ..clear()
        ..addAll(resultado);

      _ordenarCategorias();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _categorias.clear();
      _categoriasFiltradas.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Crea una categoría.
  Future<bool> crearCategoria(CrearCategoriaPeligroRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final CategoriaPeligroModel creada = await _repository.crear(request);

      /*
       * Cuando el backend devuelve el objeto creado,
       * se agrega directamente a la lista.
       *
       * Cuando devuelve 204 sin contenido, el modelo
       * temporal puede tener ID 0. En ese caso se vuelve
       * a cargar todo el listado desde el backend.
       */
      if (creada.id > 0) {
        _categorias.add(creada);

        _ordenarCategorias();
        _aplicarFiltro();
      } else {
        final List<CategoriaPeligroModel> resultado = await _repository
            .obtenerTodas();

        _categorias
          ..clear()
          ..addAll(resultado);

        _ordenarCategorias();
        _aplicarFiltro();
      }

      return true;
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// Actualiza una categoría.
  Future<bool> actualizarCategoria(
    int id,
    ActualizarCategoriaPeligroRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    if (id <= 0) {
      _mensajeError = 'El identificador de la categoría no es válido.';

      notifyListeners();
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final CategoriaPeligroModel actualizada = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _categorias.indexWhere((
        CategoriaPeligroModel categoria,
      ) {
        return categoria.id == id;
      });

      if (indice >= 0) {
        _categorias[indice] = actualizada;
      } else {
        _categorias.add(actualizada);
      }

      _ordenarCategorias();
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

  /// Elimina o desactiva una categoría.
  Future<bool> eliminarCategoria(int id) async {
    if (_eliminando) {
      return false;
    }

    if (id <= 0) {
      _mensajeError = 'El identificador de la categoría no es válido.';

      notifyListeners();
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _categorias.removeWhere((CategoriaPeligroModel categoria) {
        return categoria.id == id;
      });

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

  /// Obtiene una categoría por ID.
  Future<CategoriaPeligroModel?> obtenerCategoriaPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador de la categoría no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _categorias.indexWhere((
      CategoriaPeligroModel categoria,
    ) {
      return categoria.id == id;
    });

    if (indiceLocal >= 0) {
      return _categorias[indiceLocal];
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

  /// Limpia la búsqueda.
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

  /// Busca una categoría en memoria.
  CategoriaPeligroModel? buscarCategoriaLocal(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final CategoriaPeligroModel categoria in _categorias) {
      if (categoria.id == id) {
        return categoria;
      }
    }

    return null;
  }

  /// Reemplaza o agrega una categoría.
  void reemplazarCategoria(CategoriaPeligroModel categoria) {
    final int indice = _categorias.indexWhere((CategoriaPeligroModel elemento) {
      return elemento.id == categoria.id;
    });

    if (indice >= 0) {
      _categorias[indice] = categoria;
    } else {
      _categorias.add(categoria);
    }

    _ordenarCategorias();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Aplica el filtro actual.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _categoriasFiltradas.clear();

    if (criterio.isEmpty) {
      _categoriasFiltradas.addAll(_categorias);

      return;
    }

    _categoriasFiltradas.addAll(
      _categorias.where((CategoriaPeligroModel categoria) {
        return categoria.nombre.toLowerCase().contains(criterio) ||
            categoria.descripcionVisible.toLowerCase().contains(criterio) ||
            categoria.colorVisible.toLowerCase().contains(criterio) ||
            categoria.iconoVisible.toLowerCase().contains(criterio) ||
            categoria.orden.toString().contains(criterio);
      }),
    );
  }

  /// Ordena primero por orden y después por nombre.
  void _ordenarCategorias() {
    _categorias.sort((
      CategoriaPeligroModel primera,
      CategoriaPeligroModel segunda,
    ) {
      final int comparacionOrden = primera.orden.compareTo(segunda.orden);

      if (comparacionOrden != 0) {
        return comparacionOrden;
      }

      return primera.nombre.toLowerCase().compareTo(
        segunda.nombre.toLowerCase(),
      );
    });
  }

  /// Elimina el prefijo Exception del mensaje.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
