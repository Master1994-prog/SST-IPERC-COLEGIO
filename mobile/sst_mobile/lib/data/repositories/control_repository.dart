import '../datasources/remote/control_remote_datasource.dart';
import '../models/control_model.dart';

/// Repositorio del módulo Controles.
///
/// Esta clase actúa como intermediaria entre:
///
/// - La capa de presentación.
/// - El datasource remoto.
/// - Los modelos del módulo.
///
/// De esta forma, los providers y las pantallas no se comunican
/// directamente con Dio ni con la API.
class ControlRepository {
  /// Constructor del repositorio.
  ///
  /// Permite inyectar un datasource personalizado para pruebas.
  /// Cuando no se envía ninguno, se crea uno por defecto.
  ControlRepository({ControlRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ControlRemoteDatasource();

  /// Fuente remota encargada de comunicarse con el backend.
  final ControlRemoteDatasource _remoteDatasource;

  /// Obtiene todos los controles registrados.
  ///
  /// Puede incluir controles activos e inactivos, dependiendo
  /// de la respuesta del backend.
  Future<List<ControlModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene únicamente los controles disponibles.
  ///
  /// Un control está disponible cuando:
  ///
  /// - `activo` es verdadero.
  /// - `estado` es verdadero.
  Future<List<ControlModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene un control por su identificador.
  ///
  /// [id] debe ser mayor que cero.
  Future<ControlModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra una nueva medida de control.
  ///
  /// [request] contiene:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Clasificación.
  /// - Estado activo.
  /// - Usuario que registra.
  Future<ControlModel> crear(CrearControlRequest request) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza una medida de control existente.
  ///
  /// [id] identifica el control que será modificado.
  ///
  /// [request] contiene los datos actualizados.
  Future<ControlModel> actualizar(int id, ActualizarControlRequest request) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva una medida de control.
  ///
  /// La acción concreta depende del backend.
  /// Generalmente se realiza una eliminación lógica.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca controles mediante un texto.
  ///
  /// La búsqueda puede considerar:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Clasificación.
  ///
  /// Cuando [texto] está vacío, devuelve todos los controles.
  Future<List<ControlModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
