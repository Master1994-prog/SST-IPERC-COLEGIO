import '../datasources/remote/area_remote_datasource.dart';
import '../models/area_model.dart';

/// Repositorio para gestionar las áreas.
class AreaRepository {
  AreaRepository({AreaRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? AreaRemoteDatasource();

  final AreaRemoteDatasource _remoteDatasource;

  Future<List<AreaModel>> obtenerTodas({int? institucionId}) {
    return _remoteDatasource.obtenerTodas(institucionId: institucionId);
  }

  Future<AreaModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<AreaModel> crear({
    required String nombre,
    required String descripcion,
    required int institucionId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) {
    return _remoteDatasource.crear(
      nombre: nombre,
      descripcion: descripcion,
      institucionId: institucionId,
      usuarioRegistroId: usuarioRegistroId,
      colegioId: colegioId,
    );
  }

  Future<AreaModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int institucionId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.actualizar(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      institucionId: institucionId,
      activo: activo,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  List<AreaModel> buscarEnLista(List<AreaModel> areas, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<AreaModel>.from(areas);
    }

    return areas.where((AreaModel area) {
      return area.nombre.toLowerCase().contains(criterio) ||
          area.descripcion.toLowerCase().contains(criterio) ||
          area.institucionNombre.toLowerCase().contains(criterio);
    }).toList();
  }
}
