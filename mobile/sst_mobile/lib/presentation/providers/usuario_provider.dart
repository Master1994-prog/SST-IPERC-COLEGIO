import 'package:flutter/foundation.dart';

import '../../core/services/secure_storage_service.dart';
import '../../data/models/rol_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/rol_repository.dart';
import '../../data/repositories/usuario_repository.dart';

/// ===============================================================
/// PROVIDER DE USUARIOS - SST EDURISK
/// ===============================================================
///
/// Maneja:
/// - listado de usuarios;
/// - búsqueda;
/// - filtros;
/// - creación;
/// - edición;
/// - activar / desactivar;
/// - eliminación lógica;
/// - cambio de contraseña;
/// - asignación de roles;
/// - carga de roles;
/// - auditoría con el ID real del usuario autenticado.
///
/// IMPORTANTE:
/// Ya no se utilizan IDs fijos como `1`.
/// El identificador de auditoría se obtiene desde SecureStorageService.
/// ===============================================================
class UsuarioProvider extends ChangeNotifier {
  UsuarioProvider({
    UsuarioRepository? repository,
    RolRepository? rolRepository,
    SecureStorageService? secureStorage,
  }) : _repository = repository ?? UsuarioRepository(),
       _rolRepository = rolRepository ?? RolRepository(),
       _secureStorage = secureStorage ?? SecureStorageService.instance;

  final UsuarioRepository _repository;
  final RolRepository _rolRepository;
  final SecureStorageService _secureStorage;

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

  int? _rolFiltroId;

  // =============================================================
  // GETTERS
  // =============================================================

  List<UsuarioModel> get usuarios => List<UsuarioModel>.unmodifiable(_usuarios);

  List<UsuarioModel> get usuariosFiltrados =>
      List<UsuarioModel>.unmodifiable(_usuariosFiltrados);

  List<RolModel> get roles => List<RolModel>.unmodifiable(_roles);

  bool get cargando => _cargando;

  bool get guardando => _guardando;

  String? get error => _error;

  String get textoBusqueda => _textoBusqueda;

  int? get rolFiltroId => _rolFiltroId;

  bool get tieneUsuarios => _usuariosFiltrados.isNotEmpty;

  bool get tieneRoles => _roles.isNotEmpty;

  // =============================================================
  // ID DEL USUARIO AUTENTICADO
  // =============================================================

  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String? usuarioIdTexto = await _secureStorage.getUsuarioId();

    final int? usuarioId = int.tryParse(usuarioIdTexto?.trim() ?? '');

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'No se pudo identificar al usuario autenticado. '
        'Cierra sesión y vuelve a ingresar.',
      );
    }

    return usuarioId;
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
    await Future.wait<void>(<Future<void>>[cargarRoles(), cargarUsuarios()]);
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
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioRegistroId = await _obtenerUsuarioAutenticadoId();

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
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioActualizacionId = await _obtenerUsuarioAutenticadoId();

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
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioActualizacionId = await _obtenerUsuarioAutenticadoId();

      await _repository.actualizarRoles(
        id: usuarioId,
        rolIds: rolIds,
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
  // CAMBIAR CONTRASEÑA
  // =============================================================

  Future<bool> cambiarPassword({
    required int usuarioId,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioActualizacionId = await _obtenerUsuarioAutenticadoId();

      await _repository.cambiarPassword(
        id: usuarioId,
        nuevaPassword: nuevaPassword,
        debeCambiarPassword: debeCambiarPassword,
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
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<bool> cambiarEstado({
    required int usuarioId,
    required bool activo,
  }) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioActualizacionId = await _obtenerUsuarioAutenticadoId();

      await _repository.cambiarEstado(
        id: usuarioId,
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
  // ELIMINAR USUARIO
  // =============================================================

  Future<bool> eliminarUsuario({required int usuarioId}) async {
    if (_guardando) {
      return false;
    }

    _guardando = true;
    _error = null;

    notifyListeners();

    try {
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

      await _repository.eliminar(
        id: usuarioId,
        usuarioId: usuarioAutenticadoId,
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
    _rolFiltroId = rolId;

    _aplicarFiltro();

    notifyListeners();
  }

  void limpiarFiltroRol() {
    if (_rolFiltroId == null) {
      return;
    }

    _rolFiltroId = null;

    _aplicarFiltro();

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
  // FILTRAR BÚSQUEDA + ROL
  // =============================================================

  void _aplicarFiltro() {
    List<UsuarioModel> resultado = _repository.buscarEnLista(
      _usuarios,
      _textoBusqueda,
    );

    resultado = _repository.filtrarPorRol(resultado, rolId: _rolFiltroId);

    resultado = _repository.ordenarPorNombre(resultado);

    _usuariosFiltrados
      ..clear()
      ..addAll(resultado);
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarMensaje(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'ArgumentError: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}
