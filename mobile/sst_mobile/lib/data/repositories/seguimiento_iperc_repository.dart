import '../datasources/remote/seguimiento_iperc_remote_datasource.dart';
import '../models/seguimiento_iperc_model.dart';

/// Intermediario entre la interfaz y el origen remoto de Seguimiento IPERC.
class SeguimientoIpercRepository {
  SeguimientoIpercRepository({
    SeguimientoIpercRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? SeguimientoIpercRemoteDatasource();

  final SeguimientoIpercRemoteDatasource _remoteDatasource;

  Future<List<SeguimientoIpercModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  Future<List<SeguimientoIpercModel>> obtenerPorDetalle(int detalleIpercId) {
    return _remoteDatasource.obtenerPorDetalle(detalleIpercId);
  }

  Future<SeguimientoIpercModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<SeguimientoIpercModel> crear(CrearSeguimientoIpercRequest request) {
    return _remoteDatasource.crear(request);
  }

  Future<SeguimientoIpercModel> actualizar(
    int id,
    ActualizarSeguimientoIpercRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  Future<void> verificar(int id) {
    return _remoteDatasource.verificar(id);
  }

  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }
}
