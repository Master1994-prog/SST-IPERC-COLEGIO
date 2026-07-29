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
}
