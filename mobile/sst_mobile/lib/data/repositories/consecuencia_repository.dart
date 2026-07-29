import '../datasources/remote/consecuencia_remote_datasource.dart';
import '../models/consecuencia_model.dart';

/// Repositorio encargado de administrar las operaciones
/// relacionadas con las consecuencias.
///
/// Esta clase funciona como intermediaria entre:
///
/// - La capa de presentación.
/// - El datasource remoto.
/// - Los modelos de datos.
///
/// Las pantallas y providers no deben comunicarse directamente
/// con Dio ni con la API. Deben hacerlo mediante este repositorio.
class ConsecuenciaRepository {
  /// Constructor del repositorio.
  ///
  /// Permite recibir un datasource personalizado para facilitar
  /// pruebas unitarias. Cuando no se envía ninguno, se utiliza
  /// [ConsecuenciaRemoteDatasource] por defecto.
  ConsecuenciaRepository({ConsecuenciaRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ConsecuenciaRemoteDatasource();

  /// Fuente remota que realiza las peticiones al backend.
  final ConsecuenciaRemoteDatasource _remoteDatasource;

  /// Obtiene todas las consecuencias registradas.
  ///
  /// Incluye consecuencias activas e inactivas, dependiendo
  /// de la respuesta entregada por el backend.
  Future<List<ConsecuenciaModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene únicamente las consecuencias disponibles.
  ///
  /// Una consecuencia se considera disponible cuando:
  ///
  /// - `activo` es verdadero.
  /// - `estado` es verdadero.
  Future<List<ConsecuenciaModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene una consecuencia por su identificador.
  ///
  /// [id] debe ser mayor que cero.
  ///
  /// Lanza una excepción cuando la consecuencia no existe
  /// o cuando ocurre un problema de conexión.
  Future<ConsecuenciaModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra una nueva consecuencia en el backend.
  ///
  /// [request] contiene:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Clasificación.
  /// - Indicador de incapacidad permanente.
  /// - Indicador de fatalidad.
  /// - Estado activo.
  /// - Usuario que registra.
  Future<ConsecuenciaModel> crear(CrearConsecuenciaRequest request) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza una consecuencia existente.
  ///
  /// [id] identifica la consecuencia que será modificada.
  ///
  /// [request] contiene la nueva información y el identificador
  /// del usuario que realiza la actualización.
  Future<ConsecuenciaModel> actualizar(
    int id,
    ActualizarConsecuenciaRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva una consecuencia.
  ///
  /// La acción exacta depende de la implementación del backend.
  /// Normalmente el backend realiza una eliminación lógica.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca consecuencias utilizando un texto.
  ///
  /// La búsqueda puede considerar:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Clasificación.
  /// - Nivel de gravedad.
  ///
  /// Cuando [texto] está vacío, devuelve todas las consecuencias.
  Future<List<ConsecuenciaModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
