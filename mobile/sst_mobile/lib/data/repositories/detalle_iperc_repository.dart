import '../datasources/remote/detalle_iperc_remote_datasource.dart';
import '../models/detalle_iperc_model.dart';

/// Intermediario entre la interfaz y el origen remoto de Detalle IPERC.
class DetalleIpercRepository {
  DetalleIpercRepository({
    DetalleIpercRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? DetalleIpercRemoteDatasource();

  final DetalleIpercRemoteDatasource _remoteDatasource;

  Future<List<DetalleIpercModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  Future<List<DetalleIpercModel>> obtenerPorMatriz(int matrizIpercId) {
    return _remoteDatasource.obtenerPorMatriz(matrizIpercId);
  }

  Future<DetalleIpercModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<DetalleIpercModel> crear(CrearDetalleIpercRequest request) {
    return _remoteDatasource.crear(request);
  }

  Future<DetalleIpercModel> actualizar(
    int id,
    ActualizarDetalleIpercRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }
}
