import '../datasources/remote/usuario_remote_datasource.dart';
import '../models/usuario_model.dart';

/// Repositorio para gestionar usuarios del sistema SST/IPERC.
class UsuarioRepository {
  UsuarioRepository({UsuarioRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? UsuarioRemoteDatasource();

  final UsuarioRemoteDatasource _remoteDatasource;

  /// Obtiene todos los usuarios activos.
  ///
  /// Permite filtrar por institución, sede, área y rol.
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

  /// Obtiene un usuario por su identificador.
  Future<UsuarioModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo usuario.
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
    int usuarioRegistroId = 1,
  }) {
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

  /// Actualiza los datos generales del usuario.
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
    int usuarioActualizacionId = 1,
  }) {
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

  /// Cambia la contraseña del usuario.
  Future<String> cambiarPassword({
    required int id,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.cambiarPassword(
      id: id,
      nuevaPassword: nuevaPassword,
      debeCambiarPassword: debeCambiarPassword,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  /// Reemplaza los roles asignados al usuario.
  Future<UsuarioModel> actualizarRoles({
    required int id,
    required List<int> rolIds,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.actualizarRoles(
      id: id,
      rolIds: rolIds,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  /// Activa o desactiva un usuario.
  Future<String> cambiarEstado({
    required int id,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.cambiarEstado(
      id: id,
      activo: activo,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  /// Realiza la eliminación lógica de un usuario.
  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  /// Busca usuarios por nombre, usuario, documento,
  /// correo, teléfono o rol.
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

  /// Ordena usuarios por apellidos y nombres.
  List<UsuarioModel> ordenarPorNombre(List<UsuarioModel> usuarios) {
    final List<UsuarioModel> resultado = List<UsuarioModel>.from(usuarios);

    resultado.sort((UsuarioModel primero, UsuarioModel segundo) {
      final String nombrePrimero = '${primero.apellidos} ${primero.nombres}'
          .trim()
          .toLowerCase();

      final String nombreSegundo = '${segundo.apellidos} ${segundo.nombres}'
          .trim()
          .toLowerCase();

      return nombrePrimero.compareTo(nombreSegundo);
    });

    return resultado;
  }

  /// Filtra usuarios por rol.
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

  /// Filtra usuarios por área.
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

  /// Filtra usuarios por institución.
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
}
