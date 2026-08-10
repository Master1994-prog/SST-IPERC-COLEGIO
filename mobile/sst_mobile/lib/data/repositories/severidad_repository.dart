import '../datasources/remote/severidad_remote_datasource.dart';
import '../models/severidad_model.dart';

class SeveridadRepository {
  SeveridadRepository({SeveridadRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? SeveridadRemoteDatasource();

  final SeveridadRemoteDatasource _remoteDatasource;

  Future<List<SeveridadModel>> obtenerTodas() async {
    final List<SeveridadModel> datos = await _remoteDatasource.obtenerTodas();

    datos.sort(
      (SeveridadModel a, SeveridadModel b) => a.valor.compareTo(b.valor),
    );

    return datos;
  }

  Future<SeveridadModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  SeveridadModel? obtenerPorValor(List<SeveridadModel> lista, int valor) {
    for (final SeveridadModel item in lista) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }
}
