import 'package:flutter/foundation.dart';

import '../../data/models/control_model.dart';
import '../../data/repositories/control_repository.dart';

/// Provider encargado de administrar el estado del módulo
/// de medidas de control.
///
/// Esta clase permite:
///
/// - Cargar controles desde el backend.
/// - Mantener la lista completa.
/// - Filtrar controles por texto.
/// - Registrar nuevos controles.
/// - Actualizar controles existentes.
/// - Eliminar controles.
/// - Notificar cambios a la interfaz.
class ControlProvider extends ChangeNotifier {
  /// Constructor del provider.
  ///
  /// Permite recibir un repositorio personalizado para pruebas.
  /// Cuando no se proporciona ninguno, se crea uno por defecto.
  ControlProvider({ControlRepository? repository})
    : _repository = repository ?? ControlRepository();

  /// Repositorio utilizado para acceder a los datos.
  final ControlRepository _repository;

  /// Lista completa de controles cargados.
  final List<ControlModel> _controles = <ControlModel>[];

  /// Lista visible después de aplicar el filtro.
  final List<ControlModel> _controlesFiltrados = <ControlModel>[];

  /// Indica si se están cargando datos.
  bool _cargando = false;

  /// Indica si se está registrando o actualizando.
  bool _guardando = false;

  /// Indica si se está eliminando un control.
  bool _eliminando = false;

  /// Mensaje de error actual.
  String? _mensajeError;

  /// Texto utilizado para buscar.
  String _textoBusqueda = '';

  /// Devuelve una copia de solo lectura
  /// de la lista completa.
  List<ControlModel> get controles {
    return List<ControlModel>.unmodifiable(_controles);
  }

  /// Devuelve una copia de solo lectura
  /// de la lista filtrada.
  List<ControlModel> get controlesFiltrados {
    return List<ControlModel>.unmodifiable(_controlesFiltrados);
  }

  /// Indica si se están cargando controles.
  bool get cargando => _cargando;

  /// Indica si se está guardando un control.
  bool get guardando => _guardando;

  /// Indica si se está eliminando un control.
  bool get eliminando => _eliminando;

  /// Devuelve el mensaje de error actual.
  String? get mensajeError => _mensajeError;

  /// Devuelve el texto actual de búsqueda.
  String get textoBusqueda => _textoBusqueda;

  /// Indica si existe un error pendiente.
  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  /// Indica si existen controles cargados.
  bool get tieneControles {
    return _controles.isNotEmpty;
  }

  /// Indica si el filtro produjo resultados.
  bool get tieneResultados {
    return _controlesFiltrados.isNotEmpty;
  }

  /// Cantidad total de controles.
  int get cantidadTotal {
    return _controles.length;
  }

  /// Cantidad de controles activos.
  int get cantidadActivos {
    return _controles
        .where((ControlModel control) => control.estaDisponible)
        .length;
  }

  /// Cantidad de controles inactivos.
  int get cantidadInactivos {
    return _controles
        .where((ControlModel control) => !control.estaDisponible)
        .length;
  }

  /// Cantidad de controles que tienen clasificación.
  int get cantidadClasificados {
    return _controles
        .where((ControlModel control) => control.clasificacionControlId != null)
        .length;
  }

  /// Carga todos los controles desde el backend.
  Future<void> cargarControles() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<ControlModel> resultado = await _repository.obtenerTodos();

      resultado.sort((ControlModel primero, ControlModel segundo) {
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

      _controles
        ..clear()
        ..addAll(resultado);

      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _controles.clear();
      _controlesFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra una nueva medida de control.
  ///
  /// Devuelve `true` cuando la operación
  /// finaliza correctamente.
  Future<bool> crearControl(CrearControlRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ControlModel creado = await _repository.crear(request);

      _controles.add(creado);

      _ordenarControles();
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

  /// Actualiza una medida de control existente.
  ///
  /// Devuelve `true` cuando la actualización
  /// finaliza correctamente.
  Future<bool> actualizarControl(
    int id,
    ActualizarControlRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ControlModel actualizado = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _controles.indexWhere(
        (ControlModel control) => control.id == id,
      );

      if (indice >= 0) {
        _controles[indice] = actualizado;
      } else {
        _controles.add(actualizado);
      }

      _ordenarControles();
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

  /// Elimina o desactiva una medida de control.
  ///
  /// Devuelve `true` cuando la operación
  /// fue exitosa.
  Future<bool> eliminarControl(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _controles.removeWhere((ControlModel control) => control.id == id);

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

  /// Obtiene un control por su identificador.
  ///
  /// Primero busca en la lista local. Si no existe,
  /// consulta el backend.
  Future<ControlModel?> obtenerControlPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador del control no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _controles.indexWhere(
      (ControlModel control) => control.id == id,
    );

    if (indiceLocal >= 0) {
      return _controles[indiceLocal];
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

  /// Limpia la búsqueda y muestra
  /// nuevamente todos los controles.
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

  /// Reemplaza un control existente o lo agrega
  /// cuando todavía no está en memoria.
  void reemplazarControl(ControlModel control) {
    final int indice = _controles.indexWhere(
      (ControlModel elemento) => elemento.id == control.id,
    );

    if (indice >= 0) {
      _controles[indice] = control;
    } else {
      _controles.add(control);
    }

    _ordenarControles();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Filtra la lista utilizando:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Clasificación.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _controlesFiltrados.clear();

    if (criterio.isEmpty) {
      _controlesFiltrados.addAll(_controles);
      return;
    }

    _controlesFiltrados.addAll(
      _controles.where((ControlModel control) {
        return control.codigo.toLowerCase().contains(criterio) ||
            control.nombre.toLowerCase().contains(criterio) ||
            control.descripcionVisible.toLowerCase().contains(criterio) ||
            control.clasificacionVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  /// Ordena los controles por nombre
  /// y luego por código.
  void _ordenarControles() {
    _controles.sort((ControlModel primero, ControlModel segundo) {
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

  /// Limpia el prefijo `Exception:` del error
  /// antes de mostrarlo en la interfaz.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
