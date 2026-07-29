import '../datasources/remote/tipo_peligro_remote_datasource.dart';
import '../models/tipo_peligro_model.dart';

/// Repositorio del catálogo Tipos de Peligro.
///
/// Sirve como intermediario entre la capa de presentación
/// y la fuente de datos remota.
class TipoPeligroRepository {
  TipoPeligroRepository({TipoPeligroRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? TipoPeligroRemoteDatasource();

  /// Fuente de datos remota.
  final TipoPeligroRemoteDatasource _remoteDatasource;

  /// Obtiene todos los tipos de peligro.
  Future<List<TipoPeligroModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene solamente los tipos activos.
  Future<List<TipoPeligroModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene un tipo de peligro por su identificador.
  Future<TipoPeligroModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo tipo de peligro.
  Future<TipoPeligroModel> crear(CrearTipoPeligroRequest request) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza un tipo de peligro existente.
  Future<TipoPeligroModel> actualizar(
    int id,
    ActualizarTipoPeligroRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva un tipo de peligro.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca tipos de peligro.
  Future<List<TipoPeligroModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
