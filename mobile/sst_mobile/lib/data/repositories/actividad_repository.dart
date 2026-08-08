import '../datasources/remote/actividad_remote_datasource.dart';
import '../models/actividad_model.dart';

/// Repositorio para gestionar actividades.
class ActividadRepository {
  ActividadRepository({ActividadRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ActividadRemoteDatasource();

  final ActividadRemoteDatasource _remoteDatasource;

  Future<List<ActividadModel>> obtenerTodas({int? procesoId}) {
    return _remoteDatasource.obtenerTodas(procesoId: procesoId);
  }

  Future<ActividadModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<ActividadModel> crear({
    required String nombre,
    required String descripcion,
    required int procesoId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) {
    return _remoteDatasource.crear(
      nombre: nombre,
      descripcion: descripcion,
      procesoId: procesoId,
      usuarioRegistroId: usuarioRegistroId,
      colegioId: colegioId,
    );
  }

  Future<ActividadModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int procesoId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) {
    return _remoteDatasource.actualizar(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      procesoId: procesoId,
      activo: activo,
      usuarioActualizacionId: usuarioActualizacionId,
    );
  }

  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  List<ActividadModel> buscarEnLista(
    List<ActividadModel> actividades,
    String texto,
  ) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<ActividadModel>.from(actividades);
    }

    return actividades.where((ActividadModel actividad) {
      return actividad.nombre.toLowerCase().contains(criterio) ||
          actividad.descripcion.toLowerCase().contains(criterio) ||
          actividad.procesoNombre.toLowerCase().contains(criterio) ||
          actividad.areaNombre.toLowerCase().contains(criterio);
    }).toList();
  }
}
