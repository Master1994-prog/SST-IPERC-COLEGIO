import '../datasources/remote/solicitud_seguridad_remote_datasource.dart';
import '../models/solicitud_seguridad_model.dart';

class SolicitudSeguridadRepository {
  SolicitudSeguridadRepository({
    SolicitudSeguridadRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? SolicitudSeguridadRemoteDatasource();

  final SolicitudSeguridadRemoteDatasource _remoteDatasource;

  Future<List<SolicitudAccesoModel>> obtenerSolicitudesAcceso({
    String? estado,
  }) {
    return _remoteDatasource.obtenerSolicitudesAcceso(estado: estado);
  }

  Future<List<SolicitudRecuperacionModel>> obtenerSolicitudesRecuperacion({
    String? estado,
  }) {
    return _remoteDatasource.obtenerSolicitudesRecuperacion(estado: estado);
  }

  Future<String> aprobarAcceso(int id) {
    return _remoteDatasource.cambiarEstadoAcceso(id: id, estado: 'APROBADA');
  }

  Future<String> rechazarAcceso(int id) {
    return _remoteDatasource.cambiarEstadoAcceso(id: id, estado: 'RECHAZADA');
  }

  Future<String> atenderRecuperacion(int id) {
    return _remoteDatasource.cambiarEstadoRecuperacion(
      id: id,
      estado: 'ATENDIDA',
    );
  }

  Future<String> rechazarRecuperacion(int id) {
    return _remoteDatasource.cambiarEstadoRecuperacion(
      id: id,
      estado: 'RECHAZADA',
    );
  }
}
