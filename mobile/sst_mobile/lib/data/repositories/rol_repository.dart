import '../datasources/remote/rol_remote_datasource.dart';
import '../models/rol_model.dart';

/// Repositorio para gestionar los roles del sistema SST/IPERC.
class RolRepository {
  RolRepository({RolRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? RolRemoteDatasource();

  final RolRemoteDatasource _remoteDatasource;

  /// Obtiene todos los roles activos.
  ///
  /// Cuando [esGlobal] tiene un valor, filtra por alcance.
  Future<List<RolModel>> obtenerTodos({bool? esGlobal}) {
    return _remoteDatasource.obtenerTodos(esGlobal: esGlobal);
  }

  /// Obtiene un rol por su identificador.
  Future<RolModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo rol.
  Future<RolModel> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool esGlobal,
    int usuarioRegistroId = 1,
  }) {
    return _remoteDatasource.crear(
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      esGlobal: esGlobal,
      usuarioRegistroId: usuarioRegistroId,
    );
  }

  /// Actualiza un rol existente.
  Future<RolModel> actualizar({
    required int id,
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool activo,
    required bool esGlobal,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.actualizar(
      id: id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      activo: activo,
      esGlobal: esGlobal,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  /// Activa o desactiva un rol.
  Future<RolModel> cambiarEstado({
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

  /// Elimina lógicamente un rol.
  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  /// Busca roles por código, nombre o descripción.
  List<RolModel> buscarEnLista(List<RolModel> roles, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<RolModel>.from(roles);
    }

    return roles.where((RolModel rol) {
      return rol.codigo.toLowerCase().contains(criterio) ||
          rol.nombre.toLowerCase().contains(criterio) ||
          rol.descripcion.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Ordena los roles alfabéticamente por nombre.
  List<RolModel> ordenarPorNombre(List<RolModel> roles) {
    final List<RolModel> resultado = List<RolModel>.from(roles);

    resultado.sort((RolModel primero, RolModel segundo) {
      return primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );
    });

    return resultado;
  }

  /// Filtra solamente roles globales.
  List<RolModel> obtenerGlobales(List<RolModel> roles) {
    return roles.where((RolModel rol) => rol.esGlobal).toList();
  }

  /// Filtra solamente roles locales.
  List<RolModel> obtenerLocales(List<RolModel> roles) {
    return roles.where((RolModel rol) => !rol.esGlobal).toList();
  }
}
