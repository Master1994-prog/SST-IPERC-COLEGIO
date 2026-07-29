import '../datasources/remote/peligro_remote_datasource.dart';
import '../models/peligro_model.dart';

class PeligroRepository {
  PeligroRepository({PeligroRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? PeligroRemoteDatasource();

  final PeligroRemoteDatasource _remoteDatasource;

  Future<List<PeligroModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  Future<List<PeligroModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  Future<PeligroModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  Future<PeligroModel> crear(CrearPeligroRequest request) {
    return _remoteDatasource.crear(request);
  }

  Future<PeligroModel> actualizar(int id, ActualizarPeligroRequest request) {
    return _remoteDatasource.actualizar(id, request);
  }

  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  Future<List<PeligroModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
