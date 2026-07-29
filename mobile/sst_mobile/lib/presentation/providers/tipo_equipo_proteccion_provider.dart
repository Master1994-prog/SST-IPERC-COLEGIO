import 'package:flutter/foundation.dart';

import '../../data/models/tipo_equipo_proteccion_model.dart';
import '../../data/repositories/tipo_equipo_proteccion_repository.dart';

/// Provider encargado de administrar el estado del catálogo
/// Tipos de Equipo de Protección Personal.
///
/// Permite:
///
/// - Cargar tipos de EPP desde el backend.
/// - Mantener la lista completa.
/// - Filtrar tipos mediante búsqueda.
/// - Registrar nuevos tipos.
/// - Actualizar tipos existentes.
/// - Eliminar o desactivar tipos.
/// - Notificar cambios a las pantallas.
class TipoEquipoProteccionProvider extends ChangeNotifier {
  /// Constructor del provider.
  ///
  /// Permite inyectar un repositorio personalizado
  /// para pruebas unitarias.
  TipoEquipoProteccionProvider({TipoEquipoProteccionRepository? repository})
    : _repository = repository ?? TipoEquipoProteccionRepository();

  /// Repositorio utilizado para acceder a los datos.
  final TipoEquipoProteccionRepository _repository;

  /// Lista completa de tipos de EPP cargados.
  final List<TipoEquipoProteccionModel> _tipos = <TipoEquipoProteccionModel>[];

  /// Lista visible después de aplicar el filtro.
  final List<TipoEquipoProteccionModel> _tiposFiltrados =
      <TipoEquipoProteccionModel>[];

  /// Indica si los datos se están cargando.
  bool _cargando = false;

  /// Indica si se está registrando o actualizando.
  bool _guardando = false;

  /// Indica si se está eliminando un registro.
  bool _eliminando = false;

  /// Mensaje de error actual.
  String? _mensajeError;

  /// Texto utilizado para buscar.
  String _textoBusqueda = '';

  /// Devuelve una copia de solo lectura
  /// de todos los tipos cargados.
  List<TipoEquipoProteccionModel> get tipos {
    return List<TipoEquipoProteccionModel>.unmodifiable(_tipos);
  }

  /// Devuelve una copia de solo lectura
  /// de los resultados filtrados.
  List<TipoEquipoProteccionModel> get tiposFiltrados {
    return List<TipoEquipoProteccionModel>.unmodifiable(_tiposFiltrados);
  }

  /// Indica si se están cargando datos.
  bool get cargando => _cargando;

  /// Indica si se está guardando un registro.
  bool get guardando => _guardando;

  /// Indica si se está eliminando un registro.
  bool get eliminando => _eliminando;

  /// Devuelve el mensaje de error actual.
  String? get mensajeError => _mensajeError;

  /// Devuelve el texto actual de búsqueda.
  String get textoBusqueda => _textoBusqueda;

  /// Indica si existe un mensaje de error.
  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  /// Indica si existen tipos cargados.
  bool get tieneTipos {
    return _tipos.isNotEmpty;
  }

  /// Indica si existen resultados visibles.
  bool get tieneResultados {
    return _tiposFiltrados.isNotEmpty;
  }

  /// Cantidad total de tipos.
  int get cantidadTotal {
    return _tipos.length;
  }

  /// Cantidad de tipos activos.
  int get cantidadActivos {
    return _tipos
        .where((TipoEquipoProteccionModel tipo) => tipo.estaDisponible)
        .length;
  }

  /// Cantidad de tipos inactivos.
  int get cantidadInactivos {
    return _tipos
        .where((TipoEquipoProteccionModel tipo) => !tipo.estaDisponible)
        .length;
  }

  /// Carga todos los tipos de EPP desde el backend.
  Future<void> cargarTipos() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<TipoEquipoProteccionModel> resultado = await _repository
          .obtenerTodos();

      resultado.sort((
        TipoEquipoProteccionModel primero,
        TipoEquipoProteccionModel segundo,
      ) {
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

      _tipos
        ..clear()
        ..addAll(resultado);

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

  /// Carga solamente los tipos disponibles.
  ///
  /// Este método será útil para los selectores
  /// de Nuevo EPP y Editar EPP.
  Future<void> cargarTiposActivos() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<TipoEquipoProteccionModel> resultado = await _repository
          .obtenerActivos();

      resultado.sort((
        TipoEquipoProteccionModel primero,
        TipoEquipoProteccionModel segundo,
      ) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      _tipos
        ..clear()
        ..addAll(resultado);

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

  /// Registra un nuevo tipo de EPP.
  ///
  /// Devuelve `true` cuando la operación
  /// se completa correctamente.
  Future<bool> crearTipo(CrearTipoEquipoProteccionRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final TipoEquipoProteccionModel creado = await _repository.crear(request);

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

  /// Actualiza un tipo de EPP existente.
  ///
  /// Devuelve `true` cuando la actualización
  /// se completa correctamente.
  Future<bool> actualizarTipo(
    int id,
    ActualizarTipoEquipoProteccionRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final TipoEquipoProteccionModel actualizado = await _repository
          .actualizar(id, request);

      final int indice = _tipos.indexWhere(
        (TipoEquipoProteccionModel tipo) => tipo.id == id,
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

  /// Elimina o desactiva un tipo de EPP.
  ///
  /// Devuelve `true` cuando la operación
  /// se completa correctamente.
  Future<bool> eliminarTipo(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _tipos.removeWhere((TipoEquipoProteccionModel tipo) => tipo.id == id);

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

  /// Obtiene un tipo mediante su identificador.
  ///
  /// Primero busca en la lista local.
  /// Si no existe, consulta el backend.
  Future<TipoEquipoProteccionModel?> obtenerTipoPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador del tipo de EPP no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _tipos.indexWhere(
      (TipoEquipoProteccionModel tipo) => tipo.id == id,
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

  /// Actualiza el texto de búsqueda.
  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Limpia el filtro de búsqueda.
  void limpiarBusqueda() {
    if (_textoBusqueda.isEmpty) {
      return;
    }

    _textoBusqueda = '';
    _aplicarFiltro();
    notifyListeners();
  }

  /// Limpia el mensaje de error actual.
  void limpiarError() {
    if (_mensajeError == null) {
      return;
    }

    _mensajeError = null;
    notifyListeners();
  }

  /// Reemplaza un tipo existente o lo agrega
  /// cuando todavía no se encuentra cargado.
  void reemplazarTipo(TipoEquipoProteccionModel tipo) {
    final int indice = _tipos.indexWhere(
      (TipoEquipoProteccionModel elemento) => elemento.id == tipo.id,
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

  /// Busca un tipo dentro de la lista local
  /// mediante su identificador.
  TipoEquipoProteccionModel? buscarTipoLocal(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final TipoEquipoProteccionModel tipo in _tipos) {
      if (tipo.id == id) {
        return tipo;
      }
    }

    return null;
  }

  /// Filtra los tipos por:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _tiposFiltrados.clear();

    if (criterio.isEmpty) {
      _tiposFiltrados.addAll(_tipos);
      return;
    }

    _tiposFiltrados.addAll(
      _tipos.where((TipoEquipoProteccionModel tipo) {
        return tipo.codigo.toLowerCase().contains(criterio) ||
            tipo.nombre.toLowerCase().contains(criterio) ||
            tipo.descripcionVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  /// Ordena los tipos por nombre
  /// y posteriormente por código.
  void _ordenarTipos() {
    _tipos.sort((
      TipoEquipoProteccionModel primero,
      TipoEquipoProteccionModel segundo,
    ) {
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

  /// Limpia el prefijo `Exception:`
  /// antes de mostrar el mensaje.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
