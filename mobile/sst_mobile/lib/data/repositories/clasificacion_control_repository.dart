import '../datasources/remote/clasificacion_control_remote_datasource.dart';
import '../models/clasificacion_control_model.dart';

/// Repositorio del catálogo Clasificaciones de Control.
///
/// Funciona como intermediario entre:
///
/// - La capa de presentación.
/// - El datasource remoto.
/// - Los modelos del módulo.
class ClasificacionControlRepository {
  /// Constructor.
  ///
  /// Permite inyectar un datasource personalizado
  /// para pruebas unitarias.
  ClasificacionControlRepository({
    ClasificacionControlRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? ClasificacionControlRemoteDatasource();

  /// Fuente remota del módulo.
  final ClasificacionControlRemoteDatasource _remoteDatasource;

  /// Obtiene todas las clasificaciones registradas.
  Future<List<ClasificacionControlModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene únicamente las clasificaciones activas.
  Future<List<ClasificacionControlModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene una clasificación por su identificador.
  Future<ClasificacionControlModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra una nueva clasificación.
  Future<ClasificacionControlModel> crear(
    CrearClasificacionControlRequest request,
  ) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza una clasificación existente.
  Future<ClasificacionControlModel> actualizar(
    int id,
    ActualizarClasificacionControlRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva una clasificación.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca clasificaciones por código, nombre,
  /// descripción o prioridad.
  Future<List<ClasificacionControlModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
