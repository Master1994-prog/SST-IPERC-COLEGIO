import '../datasources/remote/matriz_iperc_remote_datasource.dart';
import '../models/matriz_iperc_model.dart';

class MatrizIpercRepository {
  MatrizIpercRepository({MatrizIpercRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? MatrizIpercRemoteDatasource();

  final MatrizIpercRemoteDatasource _remoteDatasource;

  Future<List<MatrizIpercModel>> obtenerMatrices() {
    return _remoteDatasource.obtenerMatrices();
  }

  Future<MatrizIpercModel> obtenerMatrizPorId(int id) {
    return _remoteDatasource.obtenerMatrizPorId(id);
  }

  Future<String> crear(Map<String, dynamic> datos) {
    return _remoteDatasource.create(datos);
  }

  Future<MatrizIpercModel> actualizar(int id, Map<String, dynamic> datos) {
    return _remoteDatasource.actualizar(id, datos);
  }
}
