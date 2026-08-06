import '../datasources/remote/institucion_remote_datasource.dart';
import '../models/institucion_model.dart';

/// Repositorio de instituciones.
class InstitucionRepository {
  InstitucionRepository({InstitucionRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? InstitucionRemoteDatasource();

  final InstitucionRemoteDatasource _remoteDatasource;

  Future<List<InstitucionModel>> obtenerTodas() {
    return _remoteDatasource.obtenerTodas();
  }
}
