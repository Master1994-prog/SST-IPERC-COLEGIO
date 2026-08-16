import '../datasources/remote/matriz_iperc_remote_datasource.dart';
import '../models/matriz_iperc_model.dart';

class MatrizIpercRepository {
  MatrizIpercRepository({MatrizIpercRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? MatrizIpercRemoteDatasource();

  final MatrizIpercRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER MATRICES
  // =============================================================

  Future<List<MatrizIpercModel>> obtenerMatrices() {
    return _remoteDatasource.obtenerMatrices();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<MatrizIpercModel> obtenerMatrizPorId(int id) {
    return _remoteDatasource.obtenerMatrizPorId(id);
  }

  // =============================================================
  // CREAR
  // =============================================================

  Future<String> crear(Map<String, dynamic> datos) {
    return _remoteDatasource.create(datos);
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<MatrizIpercModel> actualizar(int id, Map<String, dynamic> datos) {
    return _remoteDatasource.actualizar(id, datos);
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> eliminar(int id, {required int usuarioEliminacionId}) {
    return _remoteDatasource.eliminar(
      id,
      usuarioEliminacionId: usuarioEliminacionId,
    );
  }
}
