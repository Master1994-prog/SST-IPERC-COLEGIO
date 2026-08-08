import '../datasources/remote/sede_remote_datasource.dart';
import '../models/sede_model.dart';

/// Repositorio para gestionar sedes.
class SedeRepository {
  SedeRepository({SedeRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? SedeRemoteDatasource();

  final SedeRemoteDatasource _remoteDatasource;

  /// Obtiene todas las sedes activas.
  ///
  /// Cuando se envía [institucionId], filtra las sedes
  /// pertenecientes a esa institución.
  Future<List<SedeModel>> obtenerTodas({int? institucionId}) {
    return _remoteDatasource.obtenerTodas(institucionId: institucionId);
  }

  /// Obtiene una sede por su identificador.
  Future<SedeModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Busca sedes por nombre, código, dirección
  /// o descripción.
  List<SedeModel> buscarEnLista(List<SedeModel> sedes, String texto) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<SedeModel>.from(sedes);
    }

    return sedes.where((SedeModel sede) {
      return sede.nombre.toLowerCase().contains(criterio) ||
          sede.codigo.toLowerCase().contains(criterio) ||
          sede.direccion.toLowerCase().contains(criterio) ||
          sede.descripcion.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Ordena las sedes alfabéticamente por nombre.
  List<SedeModel> ordenarPorNombre(List<SedeModel> sedes) {
    final List<SedeModel> resultado = List<SedeModel>.from(sedes);

    resultado.sort((SedeModel primero, SedeModel segundo) {
      return primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );
    });

    return resultado;
  }

  /// Filtra sedes localmente por institución.
  List<SedeModel> filtrarPorInstitucion(
    List<SedeModel> sedes, {
    int? institucionId,
  }) {
    if (institucionId == null || institucionId <= 0) {
      return List<SedeModel>.from(sedes);
    }

    return sedes
        .where((SedeModel sede) => sede.institucionId == institucionId)
        .toList();
  }

  /// Devuelve solamente sedes activas.
  List<SedeModel> obtenerActivas(List<SedeModel> sedes) {
    return sedes.where((SedeModel sede) => sede.activo).toList();
  }
}
