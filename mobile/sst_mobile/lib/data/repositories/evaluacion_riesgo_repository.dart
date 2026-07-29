import '../datasources/remote/evaluacion_riesgo_remote_datasource.dart';
import '../models/evaluacion_riesgo_model.dart';

/// Intermediario entre la interfaz y la API de evaluaciones de riesgo.
class EvaluacionRiesgoRepository {
  EvaluacionRiesgoRepository({
    EvaluacionRiesgoRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
            remoteDatasource ?? EvaluacionRiesgoRemoteDatasource();

  final EvaluacionRiesgoRemoteDatasource _remoteDatasource;

  Future<EvaluacionRiesgoModel> crear(CrearEvaluacionRiesgoRequest request) {
    return _remoteDatasource.crear(request);
  }
}
