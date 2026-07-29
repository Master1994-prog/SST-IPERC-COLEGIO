import '../datasources/remote/categoria_peligro_remote_datasource.dart';
import '../models/categoria_peligro_model.dart';

/// Repositorio del catálogo Categorías de Peligro.
///
/// Sirve como intermediario entre la interfaz de usuario
/// y la fuente de datos remota.
class CategoriaPeligroRepository {
  CategoriaPeligroRepository({
    CategoriaPeligroRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? CategoriaPeligroRemoteDatasource();

  final CategoriaPeligroRemoteDatasource _remoteDatasource;

  /// Obtiene todas las categorías.
  Future<List<CategoriaPeligroModel>> obtenerTodas() {
    return _remoteDatasource.obtenerTodas();
  }

  /// Obtiene solamente las categorías activas.
  Future<List<CategoriaPeligroModel>> obtenerActivas() {
    return _remoteDatasource.obtenerActivas();
  }

  /// Obtiene una categoría por ID.
  Future<CategoriaPeligroModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra una categoría.
  Future<CategoriaPeligroModel> crear(CrearCategoriaPeligroRequest request) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza una categoría.
  Future<CategoriaPeligroModel> actualizar(
    int id,
    ActualizarCategoriaPeligroRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva una categoría.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca categorías.
  Future<List<CategoriaPeligroModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
