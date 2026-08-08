import '../datasources/remote/severidad_remote_datasource.dart';
import '../models/severidad_model.dart';

/// ===============================================================
/// REPOSITORIO - SEVERIDAD
/// ===============================================================
///
/// Esta clase sirve como intermediaria entre:
///
/// - La interfaz de usuario.
/// - El datasource remoto.
/// - El modelo SeveridadModel.
///
/// La pantalla de Detalle IPERC utilizará este repositorio
/// para cargar las opciones de severidad.
/// ===============================================================
class SeveridadRepository {
  /// Constructor.
  ///
  /// Permite inyectar un datasource para pruebas.
  /// Si no se proporciona uno, crea el datasource por defecto.
  SeveridadRepository({SeveridadRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? SeveridadRemoteDatasource();

  /// Datasource encargado de comunicarse con la API.
  final SeveridadRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  /// Obtiene todas las severidades desde el backend.
  ///
  /// La lista normalmente tendrá valores del 1 al 5.
  Future<List<SeveridadModel>> obtenerTodas() {
    return _remoteDatasource.obtenerTodas();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  /// Obtiene una severidad mediante su identificador.
  Future<SeveridadModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  // =============================================================
  // ORDENAR POR VALOR
  // =============================================================

  /// Ordena las severidades de menor a mayor.
  ///
  /// Ejemplo:
  ///
  /// 1
  /// 2
  /// 3
  /// 4
  /// 5
  List<SeveridadModel> ordenarPorValor(List<SeveridadModel> severidades) {
    final List<SeveridadModel> resultado = List<SeveridadModel>.from(
      severidades,
    );

    resultado.sort((SeveridadModel primero, SeveridadModel segundo) {
      return primero.valor.compareTo(segundo.valor);
    });

    return resultado;
  }

  // =============================================================
  // BUSCAR
  // =============================================================

  /// Busca severidades dentro de una lista ya cargada.
  ///
  /// Permite buscar por:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Valor.
  List<SeveridadModel> buscarEnLista(
    List<SeveridadModel> severidades,
    String texto,
  ) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<SeveridadModel>.from(severidades);
    }

    return severidades.where((SeveridadModel severidad) {
      return severidad.nombre.toLowerCase().contains(criterio) ||
          severidad.descripcion.toLowerCase().contains(criterio) ||
          severidad.valor.toString().contains(criterio);
    }).toList();
  }

  // =============================================================
  // OBTENER POR VALOR
  // =============================================================

  /// Busca una severidad por su valor numérico.
  ///
  /// Por ejemplo:
  ///
  /// valor = 5
  ///
  /// devolverá la severidad cuyo valor sea 5.
  SeveridadModel? obtenerPorValor(List<SeveridadModel> severidades, int valor) {
    for (final SeveridadModel severidad in severidades) {
      if (severidad.valor == valor) {
        return severidad;
      }
    }

    return null;
  }
}
