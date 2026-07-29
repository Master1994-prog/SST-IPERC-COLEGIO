import 'package:flutter/foundation.dart';

import '../../data/models/consecuencia_model.dart';
import '../../data/repositories/consecuencia_repository.dart';

/// Provider encargado de administrar el estado del módulo
/// de consecuencias.
///
/// Esta clase:
///
/// - Carga consecuencias desde el repositorio.
/// - Mantiene la lista completa.
/// - Permite buscar y filtrar.
/// - Registra nuevas consecuencias.
/// - Actualiza consecuencias existentes.
/// - Elimina consecuencias.
/// - Notifica los cambios a la interfaz mediante ChangeNotifier.
class ConsecuenciaProvider extends ChangeNotifier {
  /// Constructor del provider.
  ///
  /// Permite recibir un repositorio personalizado para pruebas.
  /// Cuando no se envía ninguno, se crea uno por defecto.
  ConsecuenciaProvider({ConsecuenciaRepository? repository})
    : _repository = repository ?? ConsecuenciaRepository();

  /// Repositorio utilizado para acceder a los datos.
  final ConsecuenciaRepository _repository;

  /// Lista completa de consecuencias obtenidas del backend.
  final List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];

  /// Lista visible después de aplicar una búsqueda.
  final List<ConsecuenciaModel> _consecuenciasFiltradas = <ConsecuenciaModel>[];

  /// Indica si se están cargando datos.
  bool _cargando = false;

  /// Indica si se está registrando o actualizando.
  bool _guardando = false;

  /// Indica si se está eliminando una consecuencia.
  bool _eliminando = false;

  /// Mensaje de error actual.
  String? _mensajeError;

  /// Texto usado para filtrar la lista.
  String _textoBusqueda = '';

  /// Devuelve una copia de solo lectura de la lista completa.
  List<ConsecuenciaModel> get consecuencias =>
      List<ConsecuenciaModel>.unmodifiable(_consecuencias);

  /// Devuelve una copia de solo lectura de la lista filtrada.
  List<ConsecuenciaModel> get consecuenciasFiltradas =>
      List<ConsecuenciaModel>.unmodifiable(_consecuenciasFiltradas);

  /// Indica si se están cargando consecuencias.
  bool get cargando => _cargando;

  /// Indica si se está guardando una consecuencia.
  bool get guardando => _guardando;

  /// Indica si se está eliminando una consecuencia.
  bool get eliminando => _eliminando;

  /// Devuelve el mensaje de error actual.
  String? get mensajeError => _mensajeError;

  /// Devuelve el texto de búsqueda actual.
  String get textoBusqueda => _textoBusqueda;

  /// Indica si existe un mensaje de error.
  bool get tieneError {
    return _mensajeError != null && _mensajeError!.trim().isNotEmpty;
  }

  /// Indica si existen consecuencias cargadas.
  bool get tieneConsecuencias {
    return _consecuencias.isNotEmpty;
  }

  /// Indica si existen resultados después del filtro.
  bool get tieneResultados {
    return _consecuenciasFiltradas.isNotEmpty;
  }

  /// Cantidad total de consecuencias.
  int get cantidadTotal {
    return _consecuencias.length;
  }

  /// Cantidad de consecuencias activas.
  int get cantidadActivas {
    return _consecuencias
        .where((ConsecuenciaModel consecuencia) => consecuencia.estaDisponible)
        .length;
  }

  /// Cantidad de consecuencias inactivas.
  int get cantidadInactivas {
    return _consecuencias
        .where((ConsecuenciaModel consecuencia) => !consecuencia.estaDisponible)
        .length;
  }

  /// Cantidad de consecuencias que pueden ocasionar fatalidad.
  int get cantidadFatalidades {
    return _consecuencias
        .where((ConsecuenciaModel consecuencia) => consecuencia.fatalidad)
        .length;
  }

  /// Cantidad de consecuencias que pueden ocasionar
  /// incapacidad permanente.
  int get cantidadIncapacidadesPermanentes {
    return _consecuencias
        .where(
          (ConsecuenciaModel consecuencia) =>
              consecuencia.incapacidadPermanente,
        )
        .length;
  }

  /// Carga todas las consecuencias desde el backend.
  Future<void> cargarConsecuencias() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final List<ConsecuenciaModel> resultado = await _repository
          .obtenerTodos();

      resultado.sort((ConsecuenciaModel primera, ConsecuenciaModel segunda) {
        final int comparacionNombre = primera.nombre.toLowerCase().compareTo(
          segunda.nombre.toLowerCase(),
        );

        if (comparacionNombre != 0) {
          return comparacionNombre;
        }

        return primera.codigo.toLowerCase().compareTo(
          segunda.codigo.toLowerCase(),
        );
      });

      _consecuencias
        ..clear()
        ..addAll(resultado);

      _aplicarFiltro();
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);

      _consecuencias.clear();
      _consecuenciasFiltradas.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Registra una nueva consecuencia.
  ///
  /// Devuelve true cuando la operación fue correcta.
  Future<bool> crearConsecuencia(CrearConsecuenciaRequest request) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ConsecuenciaModel creada = await _repository.crear(request);

      _consecuencias.add(creada);

      _ordenarConsecuencias();
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

  /// Actualiza una consecuencia existente.
  ///
  /// Devuelve true cuando la operación finaliza correctamente.
  Future<bool> actualizarConsecuencia(
    int id,
    ActualizarConsecuenciaRequest request,
  ) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final ConsecuenciaModel actualizada = await _repository.actualizar(
        id,
        request,
      );

      final int indice = _consecuencias.indexWhere(
        (ConsecuenciaModel consecuencia) => consecuencia.id == id,
      );

      if (indice >= 0) {
        _consecuencias[indice] = actualizada;
      } else {
        _consecuencias.add(actualizada);
      }

      _ordenarConsecuencias();
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

  /// Elimina o desactiva una consecuencia.
  ///
  /// Devuelve true cuando la operación fue exitosa.
  Future<bool> eliminarConsecuencia(int id) async {
    if (_eliminando) {
      return false;
    }

    _eliminando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      await _repository.eliminar(id);

      _consecuencias.removeWhere(
        (ConsecuenciaModel consecuencia) => consecuencia.id == id,
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

  /// Obtiene una consecuencia por su identificador.
  ///
  /// Primero busca en memoria. Si no la encuentra,
  /// consulta el backend.
  Future<ConsecuenciaModel?> obtenerConsecuenciaPorId(int id) async {
    if (id <= 0) {
      _mensajeError = 'El identificador de la consecuencia no es válido.';

      notifyListeners();
      return null;
    }

    final int indiceLocal = _consecuencias.indexWhere(
      (ConsecuenciaModel consecuencia) => consecuencia.id == id,
    );

    if (indiceLocal >= 0) {
      return _consecuencias[indiceLocal];
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _mensajeError = _limpiarMensaje(error);
      notifyListeners();
      return null;
    }
  }

  /// Aplica una búsqueda sobre las consecuencias cargadas.
  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Elimina el texto de búsqueda y muestra toda la lista.
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

  /// Reemplaza o agrega una consecuencia en la lista local.
  void reemplazarConsecuencia(ConsecuenciaModel consecuencia) {
    final int indice = _consecuencias.indexWhere(
      (ConsecuenciaModel elemento) => elemento.id == consecuencia.id,
    );

    if (indice >= 0) {
      _consecuencias[indice] = consecuencia;
    } else {
      _consecuencias.add(consecuencia);
    }

    _ordenarConsecuencias();
    _aplicarFiltro();
    notifyListeners();
  }

  /// Filtra las consecuencias usando el texto de búsqueda.
  void _aplicarFiltro() {
    final String criterio = _textoBusqueda.toLowerCase();

    _consecuenciasFiltradas.clear();

    if (criterio.isEmpty) {
      _consecuenciasFiltradas.addAll(_consecuencias);
      return;
    }

    _consecuenciasFiltradas.addAll(
      _consecuencias.where((ConsecuenciaModel consecuencia) {
        return consecuencia.codigo.toLowerCase().contains(criterio) ||
            consecuencia.nombre.toLowerCase().contains(criterio) ||
            consecuencia.descripcionVisible.toLowerCase().contains(criterio) ||
            consecuencia.clasificacionVisible.toLowerCase().contains(
              criterio,
            ) ||
            consecuencia.gravedadVisible.toLowerCase().contains(criterio);
      }),
    );
  }

  /// Ordena las consecuencias por nombre y luego por código.
  void _ordenarConsecuencias() {
    _consecuencias.sort((ConsecuenciaModel primera, ConsecuenciaModel segunda) {
      final int comparacionNombre = primera.nombre.toLowerCase().compareTo(
        segunda.nombre.toLowerCase(),
      );

      if (comparacionNombre != 0) {
        return comparacionNombre;
      }

      return primera.codigo.toLowerCase().compareTo(
        segunda.codigo.toLowerCase(),
      );
    });
  }

  /// Elimina el prefijo "Exception:" del mensaje mostrado.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
