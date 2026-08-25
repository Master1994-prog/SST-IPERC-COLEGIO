import '../datasources/remote/usuario_remote_datasource.dart';
import '../models/usuario_model.dart';

/// ===============================================================
/// REPOSITORIO DE USUARIOS - SST EDURISK
/// ===============================================================
///
/// Centraliza las operaciones del módulo de usuarios.
///
/// IMPORTANTE:
/// Los identificadores de auditoría ya NO utilizan valores fijos.
///
/// El usuario que realiza cada operación debe enviarse explícitamente
/// desde la sesión autenticada.
///
/// El backend también debe validar el usuario real desde el JWT.
/// ===============================================================
class UsuarioRepository {
  UsuarioRepository({UsuarioRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? UsuarioRemoteDatasource();

  final UsuarioRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER TODOS
  // =============================================================

  Future<List<UsuarioModel>> obtenerTodos({
    int? institucionId,
    int? sedeId,
    int? areaId,
    int? rolId,
  }) {
    return _remoteDatasource.obtenerTodos(
      institucionId: institucionId,
      sedeId: sedeId,
      areaId: areaId,
      rolId: rolId,
    );
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<UsuarioModel> obtenerPorId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'El identificador del usuario no es válido.',
      );
    }

    return _remoteDatasource.obtenerPorId(id);
  }

  // =============================================================
  // CREAR USUARIO
  // =============================================================

  Future<UsuarioModel> crear({
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
    required int usuarioRegistroId,
  }) {
    _validarUsuarioAuditoria(usuarioRegistroId, campo: 'usuarioRegistroId');

    return _remoteDatasource.crear(
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
  }

  // =============================================================
  // ACTUALIZAR USUARIO
  // =============================================================

  Future<UsuarioModel> actualizar({
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
    required int usuarioActualizacionId,
  }) {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    return _remoteDatasource.actualizar(
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
  }

  // =============================================================
  // CAMBIAR CONTRASEÑA
  // =============================================================

  Future<String> cambiarPassword({
    required int id,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
    required int usuarioActualizacionId,
  }) {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    return _remoteDatasource.cambiarPassword(
      id: id,
      nuevaPassword: nuevaPassword,
      debeCambiarPassword: debeCambiarPassword,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  // =============================================================
  // ACTUALIZAR ROLES
  // =============================================================

  Future<UsuarioModel> actualizarRoles({
    required int id,
    required List<int> rolIds,
    required int usuarioActualizacionId,
  }) {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    return _remoteDatasource.actualizarRoles(
      id: id,
      rolIds: rolIds,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<String> cambiarEstado({
    required int id,
    required bool activo,
    required int usuarioActualizacionId,
  }) {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    return _remoteDatasource.cambiarEstado(
      id: id,
      activo: activo,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<String> eliminar({required int id, required int usuarioId}) {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(usuarioId, campo: 'usuarioId');

    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  // =============================================================
  // BÚSQUEDA LOCAL
  // =============================================================

  List<UsuarioModel> buscarEnLista(List<UsuarioModel> usuarios, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<UsuarioModel>.from(usuarios);
    }

    return usuarios.where((UsuarioModel usuario) {
      final bool coincideRol = usuario.roles.any(
        (rol) =>
            rol.nombre.toLowerCase().contains(criterio) ||
            rol.codigo.toLowerCase().contains(criterio),
      );

      return usuario.nombreVisible.toLowerCase().contains(criterio) ||
          usuario.nombreUsuario.toLowerCase().contains(criterio) ||
          usuario.numeroDocumento.toLowerCase().contains(criterio) ||
          usuario.tipoDocumento.toLowerCase().contains(criterio) ||
          usuario.correo.toLowerCase().contains(criterio) ||
          usuario.telefono.toLowerCase().contains(criterio) ||
          coincideRol;
    }).toList();
  }

  // =============================================================
  // ORDENAR
  // =============================================================

  List<UsuarioModel> ordenarPorNombre(List<UsuarioModel> usuarios) {
    final List<UsuarioModel> resultado = List<UsuarioModel>.from(usuarios);

    resultado.sort((UsuarioModel primero, UsuarioModel segundo) {
      final String nombrePrimero =
          '${primero.apellidos} '
                  '${primero.nombres}'
              .trim()
              .toLowerCase();

      final String nombreSegundo =
          '${segundo.apellidos} '
                  '${segundo.nombres}'
              .trim()
              .toLowerCase();

      return nombrePrimero.compareTo(nombreSegundo);
    });

    return resultado;
  }

  // =============================================================
  // FILTRAR POR ROL
  // =============================================================

  List<UsuarioModel> filtrarPorRol(List<UsuarioModel> usuarios, {int? rolId}) {
    if (rolId == null || rolId <= 0) {
      return List<UsuarioModel>.from(usuarios);
    }

    return usuarios
        .where(
          (UsuarioModel usuario) => usuario.roles.any((rol) => rol.id == rolId),
        )
        .toList();
  }

  // =============================================================
  // FILTRAR POR ÁREA
  // =============================================================

  List<UsuarioModel> filtrarPorArea(
    List<UsuarioModel> usuarios, {
    int? areaId,
  }) {
    if (areaId == null || areaId <= 0) {
      return List<UsuarioModel>.from(usuarios);
    }

    return usuarios
        .where((UsuarioModel usuario) => usuario.areaId == areaId)
        .toList();
  }

  // =============================================================
  // FILTRAR POR INSTITUCIÓN
  // =============================================================

  List<UsuarioModel> filtrarPorInstitucion(
    List<UsuarioModel> usuarios, {
    int? institucionId,
  }) {
    if (institucionId == null || institucionId <= 0) {
      return List<UsuarioModel>.from(usuarios);
    }

    return usuarios
        .where((UsuarioModel usuario) => usuario.institucionId == institucionId)
        .toList();
  }

  // =============================================================
  // VALIDACIONES INTERNAS
  // =============================================================

  void _validarIdUsuario(int id) {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'El identificador del usuario no es válido.',
      );
    }
  }

  void _validarUsuarioAuditoria(int usuarioId, {required String campo}) {
    if (usuarioId <= 0) {
      throw ArgumentError.value(
        usuarioId,
        campo,
        'No se pudo identificar al usuario autenticado.',
      );
    }
  }
}
