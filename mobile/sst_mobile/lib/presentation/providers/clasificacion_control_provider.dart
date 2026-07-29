import 'package:flutter/foundation.dart';

import '../../data/models/clasificacion_control_model.dart';
import '../../data/repositories/clasificacion_control_repository.dart';

/// Provider encargado de administrar el estado del catálogo
/// Clasificaciones de Control.
///
/// Permite:
///
/// - Cargar clasificaciones.
/// - Filtrar registros.
/// - Registrar.
/// - Actualizar.
/// - Eliminar o desactivar.
/// - Notificar cambios a la interfaz.
class ClasificacionControlProvider extends ChangeNotifier {
  ClasificacionControlProvider({ClasificacionControlRepository? repository})
    : _repository = repository ?? ClasificacionControlRepository();

  final ClasificacionControlRepository _repository;

  final List<ClasificacionControlModel> _clasificaciones =
      <ClasificacionControlModel>[];

  final List<ClasificacionControlModel> _clasificacionesFiltradas =
      <ClasificacionControlModel>[];

  bool _cargando = false;
  bool _guardando = false;
  bool _eliminando = false;

  String? _mensajeError;
  String _textoBusqueda = '';

  List<ClasificacionControlModel> get clasificaciones {
    return List<ClasificacionControlModel>.unmodifiable(_clasificaciones);
  }

  List<ClasificacionControlModel> get clasificacionesFiltradas {
    return List<ClasificacionControlModel>.unmodifiable(
      _clasificacionesFiltradas,
    );
  }

  bool get cargando => _cargando;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;

  String? get mensajeError => _mensajeError;
  String get textoBusqueda => _textoBusqueda;

  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  bool get tieneClasificaciones {
    return _clasificaciones.isNotEmpty;
  }

  bool get tieneResultados {
    return _clasificacionesFiltradas.isNotEmpty;
  }

  int get cantidadTotal {
    return _clasificaciones.length;
  }

  int get cantidadActivas {
    return _clasificaciones
        .where(
          (ClasificacionControlModel clasificacion) =>
              clasificacion.estaDisponible,
        )
        .length;
  }

  int get cantidadInactivas {
    return _clasificaciones
        .where(
          (ClasificacionControlModel clasificacion) =>
              !clasificacion.estaDisponible,
        )
        .length;
  }

  /// Carga todas las clasificaciones.
  Future<void> cargarClasificaciones() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<ClasificacionControlModel> resultado = await _repository
          .obtenerTodos();

      _clasificaciones
        ..clear()
        ..addAll(resultado);

      _ordenarClasificaciones();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _clasificaciones.clear();
      _clasificacionesFiltradas.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Carga solamente las clasificaciones activas.
  ///
  /// Este método será usado en los selectores
  /// de Nuevo control y Editar control.
  Future<void> cargarClasificacionesActivas() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<ClasificacionControlModel> resultado = await _repository
          .obtenerActivos();

      _clasificaciones
        ..clear()
        ..addAll(resultado);

      _ordenarClasificaciones();
      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _clasificaciones.clear();
      _clasificacionesFiltradas.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra una nueva clasificación.
  Future<bool> crearClasificacion(
    CrearClasificacionControlRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ClasificacionControlModel creado = await _repository.crear(request);

      _clasificaciones.add(creado);

      _ordenarClasificaciones();
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

  /// Actualiza una clasificación existente.
  Future<bool> actualizarClasificacion(
    int id,
    ActualizarClasificacionControlRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ClasificacionControlModel actualizado = await _repository
          .actualizar(id, request);

      final int indice = _clasificaciones.indexWhere(
        (ClasificacionControlModel clasificacion) => clasificacion.id == id,
      );

      if (indice >= 0) {
        _clasificaciones[indice] = actualizado;
      } else {
        _clasificaciones.add(actualizado);
      }

      _ordenarClasificaciones();
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

  /// Elimina o desactiva una clasificación.
  Future<bool> eliminarClasificacion(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _clasificaciones.removeWhere(
        (ClasificacionControlModel clasificacion) => clasificacion.id == id,
      );

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

  /// Obtiene una clasificación por ID.
  ///
  /// Primero revisa la lista local.
  Future<ClasificacionControlModel?> obtenerClasificacionPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador de la clasificación no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _clasificaciones.indexWhere(
      (ClasificacionControlModel clasificacion) => clasificacion.id == id,
    );

    if (indiceLocal >= 0) {
      return _clasificaciones[indiceLocal];
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      notifyListeners();
      return null;
    }
  }

  /// Aplica búsqueda por código, nombre,
  /// descripción y prioridad.
  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Limpia el filtro.
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

  /// Busca una clasificación en memoria.
  ClasificacionControlModel? buscarClasificacionLocal(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final ClasificacionControlModel clasificacion in _clasificaciones) {
      if (clasificacion.id == id) {
        return clasificacion;
      }
    }

    return null;
  }

  /// Reemplaza o agrega una clasificación.
  void reemplazarClasificacion(ClasificacionControlModel clasificacion) {
    final int indice = _clasificaciones.indexWhere(
      (ClasificacionControlModel elemento) => elemento.id == clasificacion.id,
    );

    if (indice >= 0) {
      _clasificaciones[indice] = clasificacion;
    } else {
      _clasificaciones.add(clasificacion);
    }

    _ordenarClasificaciones();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Aplica el filtro actual.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _clasificacionesFiltradas.clear();

    if (criterio.isEmpty) {
      _clasificacionesFiltradas.addAll(_clasificaciones);

      return;
    }

    _clasificacionesFiltradas.addAll(
      _clasificaciones.where((ClasificacionControlModel clasificacion) {
        return clasificacion.codigo.toLowerCase().contains(criterio) ||
            clasificacion.nombre.toLowerCase().contains(criterio) ||
            clasificacion.descripcionVisible.toLowerCase().contains(criterio) ||
            clasificacion.prioridad.toString().contains(criterio);
      }),
    );
  }

  /// Ordena primero por prioridad y luego por nombre.
  void _ordenarClasificaciones() {
    _clasificaciones.sort((
      ClasificacionControlModel primero,
      ClasificacionControlModel segundo,
    ) {
      final int comparacionPrioridad = primero.prioridad.compareTo(
        segundo.prioridad,
      );

      if (comparacionPrioridad != 0) {
        return comparacionPrioridad;
      }

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
