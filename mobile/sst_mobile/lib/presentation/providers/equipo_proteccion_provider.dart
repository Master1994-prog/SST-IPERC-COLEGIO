import 'package:flutter/foundation.dart';

import '../../data/models/equipo_proteccion_model.dart';
import '../../data/repositories/equipo_proteccion_repository.dart';

/// Provider encargado de administrar el estado del módulo
/// Equipos de Protección Personal.
///
/// Permite:
///
/// - Cargar equipos desde el backend.
/// - Mantener la lista completa.
/// - Filtrar equipos mediante búsqueda.
/// - Registrar nuevos equipos.
/// - Actualizar equipos existentes.
/// - Eliminar equipos.
/// - Notificar los cambios a las pantallas.
class EquipoProteccionProvider extends ChangeNotifier {
  /// Constructor del provider.
  ///
  /// Permite inyectar un repositorio personalizado
  /// para pruebas unitarias.
  EquipoProteccionProvider({EquipoProteccionRepository? repository})
    : _repository = repository ?? EquipoProteccionRepository();

  /// Repositorio utilizado para acceder a los datos.
  final EquipoProteccionRepository _repository;

  /// Lista completa de equipos cargados.
  final List<EquipoProteccionModel> _equipos = <EquipoProteccionModel>[];

  /// Lista visible después de aplicar una búsqueda.
  final List<EquipoProteccionModel> _equiposFiltrados =
      <EquipoProteccionModel>[];

  /// Indica si se están cargando los datos.
  bool _cargando = false;

  /// Indica si se está registrando o actualizando.
  bool _guardando = false;

  /// Indica si se está eliminando un registro.
  bool _eliminando = false;

  /// Mensaje de error actual.
  String? _mensajeError;

  /// Texto de búsqueda actual.
  String _textoBusqueda = '';

  /// Devuelve una copia de solo lectura
  /// de todos los equipos.
  List<EquipoProteccionModel> get equipos {
    return List<EquipoProteccionModel>.unmodifiable(_equipos);
  }

  /// Devuelve una copia de solo lectura
  /// de los resultados filtrados.
  List<EquipoProteccionModel> get equiposFiltrados {
    return List<EquipoProteccionModel>.unmodifiable(_equiposFiltrados);
  }

  /// Indica si se están cargando datos.
  bool get cargando => _cargando;

  /// Indica si se está guardando un equipo.
  bool get guardando => _guardando;

  /// Indica si se está eliminando un equipo.
  bool get eliminando => _eliminando;

  /// Mensaje de error actual.
  String? get mensajeError => _mensajeError;

  /// Texto de búsqueda actual.
  String get textoBusqueda => _textoBusqueda;

  /// Indica si existe un mensaje de error.
  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  /// Indica si existen equipos cargados.
  bool get tieneEquipos {
    return _equipos.isNotEmpty;
  }

  /// Indica si la búsqueda produjo resultados.
  bool get tieneResultados {
    return _equiposFiltrados.isNotEmpty;
  }

  /// Cantidad total de equipos.
  int get cantidadTotal {
    return _equipos.length;
  }

  /// Cantidad de equipos activos.
  int get cantidadActivos {
    return _equipos
        .where((EquipoProteccionModel equipo) => equipo.estaDisponible)
        .length;
  }

  /// Cantidad de equipos inactivos.
  int get cantidadInactivos {
    return _equipos
        .where((EquipoProteccionModel equipo) => !equipo.estaDisponible)
        .length;
  }

  /// Cantidad de equipos que tienen un tipo asignado.
  int get cantidadConTipo {
    return _equipos
        .where(
          (EquipoProteccionModel equipo) =>
              equipo.tipoEquipoProteccionId != null,
        )
        .length;
  }

  /// Carga todos los equipos de protección
  /// desde el backend.
  Future<void> cargarEquipos() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<EquipoProteccionModel> resultado = await _repository
          .obtenerTodos();

      resultado.sort((
        EquipoProteccionModel primero,
        EquipoProteccionModel segundo,
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

      _equipos
        ..clear()
        ..addAll(resultado);

      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _equipos.clear();
      _equiposFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra un nuevo equipo de protección.
  ///
  /// Devuelve `true` cuando el registro
  /// se completa correctamente.
  Future<bool> crearEquipo(CrearEquipoProteccionRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final EquipoProteccionModel creado = await _repository.crear(request);

      _equipos.add(creado);

      _ordenarEquipos();
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

  /// Actualiza un equipo existente.
  ///
  /// Devuelve `true` cuando la actualización
  /// se completa correctamente.
  Future<bool> actualizarEquipo(
    int id,
    ActualizarEquipoProteccionRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final EquipoProteccionModel actualizado = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _equipos.indexWhere(
        (EquipoProteccionModel equipo) => equipo.id == id,
      );

      if (indice >= 0) {
        _equipos[indice] = actualizado;
      } else {
        _equipos.add(actualizado);
      }

      _ordenarEquipos();
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

  /// Elimina o desactiva un equipo.
  ///
  /// Devuelve `true` cuando la operación
  /// se realiza correctamente.
  Future<bool> eliminarEquipo(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _equipos.removeWhere((EquipoProteccionModel equipo) => equipo.id == id);

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

  /// Obtiene un equipo mediante su identificador.
  ///
  /// Primero lo busca en la lista local.
  /// Cuando no existe, consulta el backend.
  Future<EquipoProteccionModel?> obtenerEquipoPorId(int id) async {
    if (id <= 0) {
      _mensajeError =
          'El identificador del equipo de protección '
          'no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _equipos.indexWhere(
      (EquipoProteccionModel equipo) => equipo.id == id,
    );

    if (indiceLocal >= 0) {
      return _equipos[indiceLocal];
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      notifyListeners();
      return null;
    }
  }

  /// Actualiza el texto de búsqueda
  /// y vuelve a filtrar los equipos.
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

  /// Reemplaza un equipo existente o lo agrega
  /// cuando todavía no se encuentra cargado.
  void reemplazarEquipo(EquipoProteccionModel equipo) {
    final int indice = _equipos.indexWhere(
      (EquipoProteccionModel elemento) => elemento.id == equipo.id,
    );

    if (indice >= 0) {
      _equipos[indice] = equipo;
    } else {
      _equipos.add(equipo);
    }

    _ordenarEquipos();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Filtra los equipos por:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Tipo de equipo.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _equiposFiltrados.clear();

    if (criterio.isEmpty) {
      _equiposFiltrados.addAll(_equipos);
      return;
    }

    _equiposFiltrados.addAll(
      _equipos.where((EquipoProteccionModel equipo) {
        return equipo.codigo.toLowerCase().contains(criterio) ||
            equipo.nombre.toLowerCase().contains(criterio) ||
            equipo.descripcionVisible.toLowerCase().contains(criterio) ||
            equipo.tipoVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  /// Ordena los equipos primero por nombre
  /// y después por código.
  void _ordenarEquipos() {
    _equipos.sort((
      EquipoProteccionModel primero,
      EquipoProteccionModel segundo,
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

  /// Limpia el prefijo `Exception:` antes
  /// de mostrar el mensaje en la interfaz.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
