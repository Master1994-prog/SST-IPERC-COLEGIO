import '../datasources/remote/evaluacion_riesgo_remote_datasource.dart';
import '../models/evaluacion_riesgo_model.dart';

/// Intermediario entre la interfaz y la API.
class EvaluacionRiesgoRepository {
  EvaluacionRiesgoRepository({
    EvaluacionRiesgoRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? EvaluacionRiesgoRemoteDatasource();

  final EvaluacionRiesgoRemoteDatasource _remoteDatasource;

  Future<EvaluacionRiesgoModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<EvaluacionRiesgoModel> crear(CrearEvaluacionRiesgoRequest request) {
    return _remoteDatasource.crear(request);
  }

  Future<void> actualizar(int id, ActualizarEvaluacionRiesgoRequest request) {
    return _remoteDatasource.actualizar(id, request);
  }
}
