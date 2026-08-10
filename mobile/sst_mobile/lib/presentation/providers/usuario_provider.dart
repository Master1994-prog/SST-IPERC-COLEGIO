import 'package:flutter/foundation.dart';

import '../../data/models/rol_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/rol_repository.dart';
import '../../data/repositories/usuario_repository.dart';

/// ===============================================================
/// PROVIDER DE USUARIOS
/// ===============================================================
///
/// Maneja:
///
/// - Listado de usuarios.
/// - Búsqueda.
/// - Filtros.
/// - Creación.
/// - Edición.
/// - Activar / desactivar.
/// - Eliminar.
/// - Cambio de contraseña.
/// - Asignación de roles.
/// - Carga de roles.
/// ===============================================================
class UsuarioProvider extends ChangeNotifier {
  UsuarioProvider({UsuarioRepository? repository, RolRepository? rolRepository})
    : _repository = repository ?? UsuarioRepository(),
      _rolRepository = rolRepository ?? RolRepository();

  final UsuarioRepository _repository;

  final RolRepository _rolRepository;

  // =============================================================
  // USUARIOS
  // =============================================================

  final List<UsuarioModel> _usuarios = <UsuarioModel>[];

  final List<UsuarioModel> _usuariosFiltrados = <UsuarioModel>[];

  // =============================================================
  // ROLES
  // =============================================================

  final List<RolModel> _roles = <RolModel>[];

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = false;

  bool _guardando = false;

  String? _error;

  String _textoBusqueda = '';

  // =============================================================
  // GETTERS
  // =============================================================

  List<UsuarioModel> get usuarios {
    return List<UsuarioModel>.unmodifiable(_usuarios);
  }

  List<UsuarioModel> get usuariosFiltrados {
    return List<UsuarioModel>.unmodifiable(_usuariosFiltrados);
  }

  List<RolModel> get roles {
    return List<RolModel>.unmodifiable(_roles);
  }

  bool get cargando => _cargando;

  bool get guardando => _guardando;

  String? get error => _error;

  String get textoBusqueda => _textoBusqueda;

  bool get tieneUsuarios {
    return _usuariosFiltrados.isNotEmpty;
  }

  bool get tieneRoles {
    return _roles.isNotEmpty;
  }

  // =============================================================
  // CARGAR USUARIOS
  // =============================================================

  Future<void> cargarUsuarios({
    int? institucionId,
    int? sedeId,
    int? areaId,
    int? rolId,
  }) async {
    if (_cargando) {
      return;
    }

    _cargando = true;

    _error = null;

    notifyListeners();

    try {
      final List<UsuarioModel> resultado = await _repository.obtenerTodos(
        institucionId: institucionId,
        sedeId: sedeId,
        areaId: areaId,
        rolId: rolId,
      );

      final List<UsuarioModel> ordenados = _repository.ordenarPorNombre(
        resultado,
      );

      _usuarios
        ..clear()
        ..addAll(ordenados);

      _aplicarFiltro();
    } catch (error) {
      _error = _limpiarMensaje(error);

      _usuarios.clear();

      _usuariosFiltrados.clear();
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // CARGAR ROLES
  // =============================================================

  Future<void> cargarRoles({bool? esGlobal}) async {
    try {
      final List<RolModel> resultado = await _rolRepository.obtenerTodos(
        esGlobal: esGlobal,
      );

      final List<RolModel> ordenados = _rolRepository.ordenarPorNombre(
        resultado,
      );

      _roles
        ..clear()
        ..addAll(ordenados);

      notifyListeners();
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();
    }
  }

  // =============================================================
  // CARGAR TODOS
  // =============================================================

  Future<void> cargarTodo() async {
    await cargarRoles();

    await cargarUsuarios();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<UsuarioModel?> obtenerPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    for (final UsuarioModel usuario in _usuarios) {
      if (usuario.id == id) {
        return usuario;
      }
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();

      return null;
    }
  }

  // =============================================================
  // CREAR USUARIO
  // =============================================================

  Future<bool> crearUsuario({
    required String nombres,
    required String apellidos,
    required String numeroDocumento,
    required String tipoDocumento,
    required String correo,
    required String telefono,
    required String nombreUsuario,
    required String password,
    required int institucionId,
    int? sedeId,
    int? areaId,
    required List<int> rolIds,
    bool debeCambiarPassword = true,
    int usuarioRegistroId = 1,
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;

    _error = null;

    notifyListeners();

    try {
      await _repository.crear(
        nombres: nombres,
        apellidos: apellidos,
        numeroDocumento: numeroDocumento,
        tipoDocumento: tipoDocumento,
        correo: correo,
        telefono: telefono,
        nombreUsuario: nombreUsuario,
        password: password,
        institucionId: institucionId,
        sedeId: sedeId,
        areaId: areaId,
        rolIds: rolIds,
        debeCambiarPassword: debeCambiarPassword,
        usuarioRegistroId: usuarioRegistroId,
      );

      await cargarUsuarios();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _guardando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR USUARIO
  // =============================================================

  Future<bool> actualizarUsuario({
    required int id,
    required String nombres,
    required String apellidos,
    required String numeroDocumento,
    required String tipoDocumento,
    required String correo,
    required String telefono,
    required String nombreUsuario,
    required int institucionId,
    int? sedeId,
    int? areaId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;

    _error = null;

    notifyListeners();

    try {
      await _repository.actualizar(
        id: id,
        nombres: nombres,
        apellidos: apellidos,
        numeroDocumento: numeroDocumento,
        tipoDocumento: tipoDocumento,
        correo: correo,
        telefono: telefono,
        nombreUsuario: nombreUsuario,
        institucionId: institucionId,
        sedeId: sedeId,
        areaId: areaId,
        activo: activo,
        usuarioActualizacionId: usuarioActualizacionId,
      );

      await cargarUsuarios();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _guardando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR ROLES
  // =============================================================

  Future<bool> actualizarRoles({
    required int usuarioId,
    required List<int> rolIds,
    int usuarioActualizacionId = 1,
  }) async {
    try {
      await _repository.actualizarRoles(
        id: usuarioId,
        rolIds: rolIds,
        usuarioActualizacionId: usuarioActualizacionId,
      );

      await cargarUsuarios();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();

      return false;
    }
  }

  // =============================================================
  // CAMBIAR CONTRASEÑA
  // =============================================================

  Future<bool> cambiarPassword({
    required int usuarioId,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
    int usuarioActualizacionId = 1,
  }) async {
    try {
      await _repository.cambiarPassword(
        id: usuarioId,
        nuevaPassword: nuevaPassword,
        debeCambiarPassword: debeCambiarPassword,
        usuarioActualizacionId: usuarioActualizacionId,
      );

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();

      return false;
    }
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<bool> cambiarEstado({
    required int usuarioId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    try {
      await _repository.cambiarEstado(
        id: usuarioId,
        activo: activo,
        usuarioActualizacionId: usuarioActualizacionId,
      );

      await cargarUsuarios();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();

      return false;
    }
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<bool> eliminarUsuario({
    required int usuarioId,
    int usuarioRegistroId = 1,
  }) async {
    try {
      await _repository.eliminar(id: usuarioId, usuarioId: usuarioRegistroId);

      await cargarUsuarios();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      notifyListeners();

      return false;
    }
  }

  // =============================================================
  // BUSCAR
  // =============================================================

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

  // =============================================================
  // FILTRO POR ROL
  // =============================================================

  void filtrarPorRol({int? rolId}) {
    final List<UsuarioModel> resultado = _repository.filtrarPorRol(
      _usuarios,
      rolId: rolId,
    );

    _usuariosFiltrados
      ..clear()
      ..addAll(resultado);

    notifyListeners();
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }

  // =============================================================
  // FILTRAR BÚSQUEDA
  // =============================================================

  void _aplicarFiltro() {
    final List<UsuarioModel> resultado = _repository.buscarEnLista(
      _usuarios,
      _textoBusqueda,
    );

    _usuariosFiltrados
      ..clear()
      ..addAll(resultado);
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
