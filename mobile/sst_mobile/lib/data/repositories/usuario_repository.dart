import '../datasources/remote/usuario_remote_datasource.dart';
import '../models/usuario_model.dart';

/// Intermediario entre la interfaz y el datasource.
class UsuarioRepository {
  UsuarioRepository({UsuarioRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? UsuarioRemoteDatasource();

  final UsuarioRemoteDatasource _remoteDatasource;

  /// Obtiene los usuarios activos.
  Future<List<UsuarioModel>> obtenerTodos({
    int? institucionId,
    int? sedeId,
    int? areaId,
  }) {
    return _remoteDatasource.obtenerTodos(
      institucionId: institucionId,
      sedeId: sedeId,
      areaId: areaId,
    );
  }

  /// Obtiene un usuario mediante su ID.
  Future<UsuarioModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Busca sobre la lista cargada.
  List<UsuarioModel> buscarEnLista(List<UsuarioModel> usuarios, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<UsuarioModel>.from(usuarios);
    }

    return usuarios.where((UsuarioModel usuario) {
      return usuario.nombreVisible.toLowerCase().contains(criterio) ||
          usuario.nombreUsuario.toLowerCase().contains(criterio) ||
          usuario.correoVisible.toLowerCase().contains(criterio);
    }).toList();
  }
}
