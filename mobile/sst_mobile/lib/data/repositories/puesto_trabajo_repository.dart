import '../datasources/remote/puesto_trabajo_remote_datasource.dart';
import '../models/puesto_trabajo_model.dart';

/// Repositorio para gestionar puestos de trabajo.
class PuestoTrabajoRepository {
  PuestoTrabajoRepository({PuestoTrabajoRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? PuestoTrabajoRemoteDatasource();

  final PuestoTrabajoRemoteDatasource _remoteDatasource;

  /// Obtiene todos los puestos de trabajo.
  ///
  /// Cuando se envía [areaId], filtra los resultados por área.
  Future<List<PuestoTrabajoModel>> obtenerTodos({int? areaId}) {
    return _remoteDatasource.obtenerTodos(areaId: areaId);
  }

  /// Obtiene un puesto de trabajo por su identificador.
  Future<PuestoTrabajoModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo puesto de trabajo.
  Future<PuestoTrabajoModel> crear({
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

  /// Actualiza un puesto de trabajo existente.
  Future<PuestoTrabajoModel> actualizar({
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

  /// Realiza la eliminación lógica de un puesto de trabajo.
  Future<String> eliminar({required int id, int usuarioId = 1}) {
    return _remoteDatasource.eliminar(id: id, usuarioId: usuarioId);
  }

  /// Filtra una lista local de puestos de trabajo.
  List<PuestoTrabajoModel> buscarEnLista(
    List<PuestoTrabajoModel> puestos,
    String texto,
  ) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<PuestoTrabajoModel>.from(puestos);
    }

    return puestos.where((PuestoTrabajoModel puesto) {
      return puesto.nombre.toLowerCase().contains(criterio) ||
          puesto.descripcion.toLowerCase().contains(criterio) ||
          puesto.areaNombre.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Ordena los puestos alfabéticamente por nombre.
  List<PuestoTrabajoModel> ordenarPorNombre(List<PuestoTrabajoModel> puestos) {
    final List<PuestoTrabajoModel> resultado = List<PuestoTrabajoModel>.from(
      puestos,
    );

    resultado.sort((PuestoTrabajoModel primero, PuestoTrabajoModel segundo) {
      return primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );
    });

    return resultado;
  }

  /// Filtra localmente los puestos por área.
  List<PuestoTrabajoModel> filtrarPorArea(
    List<PuestoTrabajoModel> puestos, {
    int? areaId,
  }) {
    if (areaId == null || areaId <= 0) {
      return List<PuestoTrabajoModel>.from(puestos);
    }

    return puestos
        .where((PuestoTrabajoModel puesto) => puesto.areaId == areaId)
        .toList();
  }
}
