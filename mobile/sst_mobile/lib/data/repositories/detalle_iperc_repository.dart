import '../datasources/remote/detalle_iperc_remote_datasource.dart';
import '../models/detalle_iperc_model.dart';

/// ===============================================================
/// REPOSITORIO - DETALLE IPERC
/// ===============================================================
///
/// Esta clase sirve como intermediaria entre:
///
/// - La interfaz de usuario
/// - El datasource remoto
///
/// La pantalla NO debería llamar directamente al datasource.
/// En su lugar, debe usar este repositorio.
///
/// Aquí también podemos agregar filtros y búsquedas locales.
/// ===============================================================
class DetalleIpercRepository {
  /// Constructor.
  ///
  /// Permite inyectar un datasource para pruebas.
  /// Si no se proporciona uno, crea el datasource por defecto.
  DetalleIpercRepository({DetalleIpercRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? DetalleIpercRemoteDatasource();

  /// Datasource encargado de comunicarse con la API.
  final DetalleIpercRemoteDatasource _remoteDatasource;

  // =============================================================
  // OBTENER TODOS
  // =============================================================

  /// Obtiene todos los detalles IPERC registrados.
  Future<List<DetalleIpercModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  /// Obtiene un detalle IPERC por su identificador.
  Future<DetalleIpercModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  // =============================================================
  // OBTENER POR MATRIZ
  // =============================================================

  /// Obtiene únicamente los detalles asociados
  /// a una Matriz IPERC específica.
  Future<List<DetalleIpercModel>> obtenerPorMatriz(int matrizIpercId) {
    return _remoteDatasource.obtenerPorMatriz(matrizIpercId);
  }

  // =============================================================
  // CREAR
  // =============================================================

  /// Registra un nuevo detalle IPERC.
  ///
  /// Recibe el Request utilizado por las pantallas
  /// y providers existentes.
  Future<DetalleIpercModel> crear(CrearDetalleIpercRequest request) {
    return _remoteDatasource.crear(
      matrizIpercId: request.matrizIpercId,
      item: request.item,
      tarea: request.tarea,
      peligroId: request.peligroId,
      consecuenciaId: request.consecuenciaId,
      descripcionPeligro: request.descripcionPeligro,
      probabilidadInicialId: request.probabilidadInicialId,
      severidadInicialId: request.severidadInicialId,
      observacionesEvaluacionInicial: request.observacionesEvaluacionInicial,
      probabilidadResidualId: request.probabilidadResidualId,
      severidadResidualId: request.severidadResidualId,
      observacionesEvaluacionResidual: request.observacionesEvaluacionResidual,
      controlIds: request.controlIds,
      equipoProteccionIds: request.equipoProteccionIds,
      responsableImplementacionId: request.responsableImplementacionId,
      fechaCompromiso: request.fechaCompromiso,
      fechaImplementacion: request.fechaImplementacion,
      estadoImplementacion: request.estadoImplementacion,
    );
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  /// Actualiza un detalle IPERC.
  ///
  /// El datasource devuelve un mensaje, pero las pantallas antiguas
  /// esperan nuevamente el DetalleIpercModel.
  ///
  /// Por eso después de actualizar recuperamos el registro.
  Future<DetalleIpercModel> actualizar(
    ActualizarDetalleIpercRequest request,
  ) async {
    await _remoteDatasource.actualizar(
      id: request.id,
      matrizIpercId: request.matrizIpercId,
      item: request.item,
      tarea: request.tarea,
      peligroId: request.peligroId,
      consecuenciaId: request.consecuenciaId,
      descripcionPeligro: request.descripcionPeligro,
      probabilidadInicialId: request.probabilidadInicialId,
      severidadInicialId: request.severidadInicialId,
      observacionesEvaluacionInicial: request.observacionesEvaluacionInicial,
      probabilidadResidualId: request.probabilidadResidualId,
      severidadResidualId: request.severidadResidualId,
      observacionesEvaluacionResidual: request.observacionesEvaluacionResidual,
      controlIds: request.controlIds,
      equipoProteccionIds: request.equipoProteccionIds,
      responsableImplementacionId: request.responsableImplementacionId,
      fechaCompromiso: request.fechaCompromiso,
      fechaImplementacion: request.fechaImplementacion,
      estadoImplementacion: request.estadoImplementacion,
    );

    /// Recuperamos el detalle actualizado.
    return obtenerPorId(request.id);
  }

  // =============================================================
  // ELIMINAR / CERRAR
  // =============================================================

  /// Nombre utilizado por código nuevo.
  Future<String> cerrar(int id) {
    return _remoteDatasource.cerrar(id);
  }

  /// Alias utilizado por código antiguo.
  ///
  /// En realidad el backend NO elimina el detalle.
  /// Lo cambia a estado Cerrado.
  Future<String> eliminar(int id) {
    return cerrar(id);
  }
  // =============================================================
  // ORDENAR POR ITEM
  // =============================================================

  /// Ordena los detalles por número de item.
  List<DetalleIpercModel> ordenarPorItem(List<DetalleIpercModel> detalles) {
    final List<DetalleIpercModel> resultado = List<DetalleIpercModel>.from(
      detalles,
    );

    resultado.sort((DetalleIpercModel primero, DetalleIpercModel segundo) {
      return primero.item.compareTo(segundo.item);
    });

    return resultado;
  }

  // =============================================================
  // FILTRAR POR MATRIZ
  // =============================================================

  /// Filtra localmente los detalles según
  /// la Matriz IPERC seleccionada.
  List<DetalleIpercModel> filtrarPorMatriz(
    List<DetalleIpercModel> detalles, {
    required int matrizIpercId,
  }) {
    if (matrizIpercId <= 0) {
      return List<DetalleIpercModel>.from(detalles);
    }

    return detalles
        .where(
          (DetalleIpercModel detalle) => detalle.matrizIpercId == matrizIpercId,
        )
        .toList();
  }

  // =============================================================
  // FILTRAR POR ESTADO
  // =============================================================

  /// Filtra los detalles según el estado
  /// de implementación.
  ///
  /// Estados:
  ///
  /// 0 = Pendiente
  /// 1 = EnProceso
  /// 2 = Implementado
  /// 3 = Verificado
  /// 4 = Cerrado
  List<DetalleIpercModel> filtrarPorEstadoImplementacion(
    List<DetalleIpercModel> detalles, {
    required int estado,
  }) {
    return detalles
        .where(
          (DetalleIpercModel detalle) =>
              detalle.estadoImplementacionId == estado,
        )
        .toList();
  }

  // =============================================================
  // OBTENER ABIERTOS
  // =============================================================

  /// Devuelve todos los detalles que todavía
  /// NO están cerrados.
  List<DetalleIpercModel> obtenerAbiertos(List<DetalleIpercModel> detalles) {
    return detalles
        .where((DetalleIpercModel detalle) => !detalle.estaCerrado)
        .toList();
  }

  // =============================================================
  // OBTENER CERRADOS
  // =============================================================

  /// Devuelve únicamente los detalles cerrados.
  List<DetalleIpercModel> obtenerCerrados(List<DetalleIpercModel> detalles) {
    return detalles
        .where((DetalleIpercModel detalle) => detalle.estaCerrado)
        .toList();
  }

  // =============================================================
  // FILTRAR RIESGOS QUE REQUIEREN ACCIÓN
  // =============================================================

  /// Devuelve los detalles cuyo nivel de riesgo actual
  /// requiere implementar medidas de control.
  ///
  /// Si existe evaluación residual, utiliza esa evaluación.
  /// Si no existe, utiliza la evaluación inicial.
  List<DetalleIpercModel> obtenerQueRequierenAccion(
    List<DetalleIpercModel> detalles,
  ) {
    return detalles
        .where((DetalleIpercModel detalle) => detalle.requiereAccion)
        .toList();
  }

  // =============================================================
  // FILTRAR CON EVALUACIÓN RESIDUAL
  // =============================================================

  /// Devuelve los detalles que ya tienen
  /// evaluación residual registrada.
  List<DetalleIpercModel> obtenerConEvaluacionResidual(
    List<DetalleIpercModel> detalles,
  ) {
    return detalles
        .where((DetalleIpercModel detalle) => detalle.tieneEvaluacionResidual)
        .toList();
  }
}
