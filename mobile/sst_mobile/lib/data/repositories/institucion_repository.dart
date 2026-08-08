import '../datasources/remote/institucion_remote_datasource.dart';
import '../models/institucion_model.dart';

/// Repositorio para gestionar instituciones.
class InstitucionRepository {
  InstitucionRepository({InstitucionRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? InstitucionRemoteDatasource();

  final InstitucionRemoteDatasource _remoteDatasource;

  /// Obtiene todas las instituciones activas.
  Future<List<InstitucionModel>> obtenerTodas() {
    return _remoteDatasource.obtenerTodas();
  }

  /// Obtiene una institución por su identificador.
  Future<InstitucionModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Busca instituciones por nombre, código o descripción.
  List<InstitucionModel> buscarEnLista(
    List<InstitucionModel> instituciones,
    String texto,
  ) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<InstitucionModel>.from(instituciones);
    }

    return instituciones.where((InstitucionModel institucion) {
      return institucion.nombre.toLowerCase().contains(criterio) ||
          institucion.codigo.toLowerCase().contains(criterio) ||
          institucion.descripcion.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Ordena las instituciones por nombre.
  List<InstitucionModel> ordenarPorNombre(
    List<InstitucionModel> instituciones,
  ) {
    final List<InstitucionModel> resultado = List<InstitucionModel>.from(
      instituciones,
    );

    resultado.sort((InstitucionModel primero, InstitucionModel segundo) {
      return primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );
    });

    return resultado;
  }

  /// Devuelve solo instituciones activas.
  List<InstitucionModel> obtenerActivas(List<InstitucionModel> instituciones) {
    return instituciones
        .where((InstitucionModel institucion) => institucion.activo)
        .toList();
  }
}
