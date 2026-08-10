import '../datasources/remote/probabilidad_remote_datasource.dart';
import '../models/probabilidad_model.dart';

class ProbabilidadRepository {
  ProbabilidadRepository({ProbabilidadRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ProbabilidadRemoteDatasource();

  final ProbabilidadRemoteDatasource _remoteDatasource;

  Future<List<ProbabilidadModel>> obtenerTodas() async {
    final List<ProbabilidadModel> datos = await _remoteDatasource
        .obtenerTodas();

    datos.sort(
      (ProbabilidadModel a, ProbabilidadModel b) => a.valor.compareTo(b.valor),
    );

    return datos;
  }

  Future<ProbabilidadModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  ProbabilidadModel? obtenerPorValor(List<ProbabilidadModel> lista, int valor) {
    for (final ProbabilidadModel item in lista) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }
}
