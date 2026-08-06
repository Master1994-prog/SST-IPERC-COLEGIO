import '../datasources/remote/proceso_remote_datasource.dart';
import '../models/proceso_model.dart';

/// Repositorio para gestionar procesos.
class ProcesoRepository {
  ProcesoRepository({ProcesoRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ProcesoRemoteDatasource();

  final ProcesoRemoteDatasource _remoteDatasource;

  Future<List<ProcesoModel>> obtenerTodos({int? areaId}) {
    return _remoteDatasource.obtenerTodos(areaId: areaId);
  }

  Future<ProcesoModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<ProcesoModel> crear({
    required String nombre,
    required String descripcion,
    required int areaId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) {
    return _remoteDatasource.crear(
      nombre: nombre,
      descripcion: descripcion,
      areaId: areaId,
      usuarioRegistroId: usuarioRegistroId,
      colegioId: colegioId,
    );
  }

  Future<ProcesoModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int areaId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.actualizar(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      areaId: areaId,
      activo: activo,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  List<ProcesoModel> buscarEnLista(List<ProcesoModel> procesos, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<ProcesoModel>.from(procesos);
    }

    return procesos.where((ProcesoModel proceso) {
      return proceso.nombre.toLowerCase().contains(criterio) ||
          proceso.descripcion.toLowerCase().contains(criterio) ||
          proceso.areaNombre.toLowerCase().contains(criterio);
    }).toList();
  }
}
