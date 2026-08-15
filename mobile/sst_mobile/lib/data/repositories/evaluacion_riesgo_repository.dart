import '../datasources/remote/evaluacion_riesgo_remote_datasource.dart';
import '../models/evaluacion_riesgo_model.dart';

/// Intermediario entre la interfaz y la API.
class EvaluacionRiesgoRepository {
  EvaluacionRiesgoRepository({
    EvaluacionRiesgoRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? EvaluacionRiesgoRemoteDatasource();

  final EvaluacionRiesgoRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  Future<List<EvaluacionRiesgoModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<EvaluacionRiesgoModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  // =============================================================
  // CREAR
  // =============================================================

  Future<EvaluacionRiesgoModel> crear(CrearEvaluacionRiesgoRequest request) {
    return _remoteDatasource.crear(request);
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> actualizar(int id, ActualizarEvaluacionRiesgoRequest request) {
    return _remoteDatasource.actualizar(id, request);
  }
}
