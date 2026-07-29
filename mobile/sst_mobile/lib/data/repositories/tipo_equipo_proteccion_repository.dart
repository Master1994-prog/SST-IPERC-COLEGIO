import '../datasources/remote/tipo_equipo_proteccion_remote_datasource.dart';
import '../models/tipo_equipo_proteccion_model.dart';

/// Repositorio del catálogo Tipos de Equipo de Protección.
///
/// Esta clase funciona como intermediaria entre:
///
/// - La capa de presentación.
/// - El datasource remoto.
/// - Los modelos del catálogo.
///
/// De esta manera, los providers y las pantallas
/// no se comunican directamente con Dio ni con la API.
class TipoEquipoProteccionRepository {
  /// Constructor del repositorio.
  ///
  /// Permite inyectar un datasource personalizado
  /// para pruebas unitarias.
  TipoEquipoProteccionRepository({
    TipoEquipoProteccionRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? TipoEquipoProteccionRemoteDatasource();

  /// Fuente remota encargada de comunicarse
  /// con el backend.
  final TipoEquipoProteccionRemoteDatasource _remoteDatasource;

  /// Obtiene todos los tipos de EPP registrados.
  ///
  /// Puede incluir registros activos e inactivos,
  /// según la respuesta del backend.
  Future<List<TipoEquipoProteccionModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene únicamente los tipos disponibles.
  ///
  /// Un tipo se considera disponible cuando:
  ///
  /// - `activo` es verdadero.
  /// - `estado` es verdadero.
  Future<List<TipoEquipoProteccionModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene un tipo de EPP por su identificador.
  ///
  /// [id] debe ser mayor que cero.
  Future<TipoEquipoProteccionModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo tipo de equipo de protección.
  ///
  /// [request] contiene:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Estado activo.
  /// - Usuario que registra.
  Future<TipoEquipoProteccionModel> crear(
    CrearTipoEquipoProteccionRequest request,
  ) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza un tipo de EPP existente.
  ///
  /// [id] identifica el registro que será modificado.
  ///
  /// [request] contiene los nuevos datos.
  Future<TipoEquipoProteccionModel> actualizar(
    int id,
    ActualizarTipoEquipoProteccionRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva un tipo de EPP.
  ///
  /// La acción exacta depende del backend.
  /// Normalmente se realiza una eliminación lógica.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca tipos de EPP mediante un texto.
  ///
  /// La búsqueda puede considerar:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  ///
  /// Cuando [texto] está vacío, devuelve todos
  /// los registros.
  Future<List<TipoEquipoProteccionModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
