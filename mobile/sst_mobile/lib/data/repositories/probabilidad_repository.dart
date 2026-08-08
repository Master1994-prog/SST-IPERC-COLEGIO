import '../datasources/remote/probabilidad_remote_datasource.dart';
import '../models/probabilidad_model.dart';

/// ===============================================================
/// REPOSITORIO - PROBABILIDAD
/// ===============================================================
///
/// Esta clase sirve como intermediaria entre:
///
/// - La interfaz de usuario.
/// - El datasource remoto.
/// - El modelo ProbabilidadModel.
///
/// La pantalla de Detalle IPERC debería utilizar este repositorio
/// y no llamar directamente al datasource.
/// ===============================================================
class ProbabilidadRepository {
  /// Constructor.
  ///
  /// Permite inyectar un datasource para pruebas.
  /// Si no se proporciona uno, crea el datasource por defecto.
  ProbabilidadRepository({ProbabilidadRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ProbabilidadRemoteDatasource();

  /// Datasource encargado de comunicarse con la API.
  final ProbabilidadRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  /// Obtiene todas las probabilidades desde el backend.
  ///
  /// La lista normalmente contendrá valores del 1 al 5.
  Future<List<ProbabilidadModel>> obtenerTodas() {
    return _remoteDatasource.obtenerTodas();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  /// Obtiene una probabilidad mediante su identificador.
  Future<ProbabilidadModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  // =============================================================
  // ORDENAR POR VALOR
  // =============================================================

  /// Ordena las probabilidades desde el menor
  /// valor hasta el mayor.
  ///
  /// Ejemplo:
  ///
  /// 1 - Rara
  /// 2 - Poco probable
  /// 3 - Posible
  /// 4 - Probable
  /// 5 - Casi segura
  List<ProbabilidadModel> ordenarPorValor(
    List<ProbabilidadModel> probabilidades,
  ) {
    final List<ProbabilidadModel> resultado = List<ProbabilidadModel>.from(
      probabilidades,
    );

    resultado.sort((ProbabilidadModel primero, ProbabilidadModel segundo) {
      return primero.valor.compareTo(segundo.valor);
    });

    return resultado;
  }

  // =============================================================
  // BUSCAR
  // =============================================================

  /// Busca probabilidades dentro de una lista ya cargada.
  ///
  /// Permite buscar por:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Valor.
  List<ProbabilidadModel> buscarEnLista(
    List<ProbabilidadModel> probabilidades,
    String texto,
  ) {
    final String criterio = texto.trim().toLowerCase();

    if (criterio.isEmpty) {
      return List<ProbabilidadModel>.from(probabilidades);
    }

    return probabilidades.where((ProbabilidadModel probabilidad) {
      return probabilidad.nombre.toLowerCase().contains(criterio) ||
          probabilidad.descripcion.toLowerCase().contains(criterio) ||
          probabilidad.valor.toString().contains(criterio);
    }).toList();
  }

  // =============================================================
  // OBTENER POR VALOR
  // =============================================================

  /// Busca una probabilidad por su valor numérico.
  ///
  /// Por ejemplo:
  ///
  /// valor = 4
  ///
  /// devolverá la probabilidad cuyo valor sea 4.
  ProbabilidadModel? obtenerPorValor(
    List<ProbabilidadModel> probabilidades,
    int valor,
  ) {
    for (final ProbabilidadModel probabilidad in probabilidades) {
      if (probabilidad.valor == valor) {
        return probabilidad;
      }
    }

    return null;
  }
}
