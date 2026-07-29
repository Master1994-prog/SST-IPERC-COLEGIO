import '../datasources/remote/equipo_proteccion_remote_datasource.dart';
import '../models/equipo_proteccion_model.dart';

/// Repositorio del módulo Equipos de Protección Personal.
///
/// Esta clase funciona como intermediaria entre:
///
/// - La capa de presentación.
/// - El datasource remoto.
/// - Los modelos del módulo.
///
/// De esta manera, los providers y las pantallas
/// no se comunican directamente con Dio ni con la API.
class EquipoProteccionRepository {
  /// Constructor del repositorio.
  ///
  /// Permite inyectar un datasource personalizado para pruebas.
  /// Cuando no se envía ninguno, se utiliza el datasource remoto
  /// por defecto.
  EquipoProteccionRepository({
    EquipoProteccionRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? EquipoProteccionRemoteDatasource();

  /// Fuente remota encargada de comunicarse con el backend.
  final EquipoProteccionRemoteDatasource _remoteDatasource;

  /// Obtiene todos los equipos de protección registrados.
  ///
  /// Puede incluir equipos activos e inactivos,
  /// según la respuesta del backend.
  Future<List<EquipoProteccionModel>> obtenerTodos() {
    return _remoteDatasource.obtenerTodos();
  }

  /// Obtiene únicamente los equipos disponibles.
  ///
  /// Un equipo se considera disponible cuando:
  ///
  /// - `activo` es verdadero.
  /// - `estado` es verdadero.
  Future<List<EquipoProteccionModel>> obtenerActivos() {
    return _remoteDatasource.obtenerActivos();
  }

  /// Obtiene un equipo de protección por su identificador.
  ///
  /// [id] debe ser mayor que cero.
  Future<EquipoProteccionModel> obtenerPorId(int id) {
    return _remoteDatasource.obtenerPorId(id);
  }

  /// Registra un nuevo equipo de protección.
  ///
  /// [request] contiene:
  ///
  /// - Nombre.
  /// - Descripción.
  /// - Tipo de equipo.
  /// - Estado activo.
  /// - Usuario que registra.
  Future<EquipoProteccionModel> crear(CrearEquipoProteccionRequest request) {
    return _remoteDatasource.crear(request);
  }

  /// Actualiza un equipo de protección existente.
  ///
  /// [id] identifica el registro que será modificado.
  ///
  /// [request] contiene los datos actualizados.
  Future<EquipoProteccionModel> actualizar(
    int id,
    ActualizarEquipoProteccionRequest request,
  ) {
    return _remoteDatasource.actualizar(id, request);
  }

  /// Elimina o desactiva un equipo de protección.
  ///
  /// La acción exacta depende de la implementación
  /// del backend. Normalmente se realiza una
  /// eliminación lógica.
  Future<void> eliminar(int id) {
    return _remoteDatasource.eliminar(id);
  }

  /// Busca equipos de protección mediante un texto.
  ///
  /// La búsqueda puede considerar:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Tipo de equipo.
  ///
  /// Cuando [texto] está vacío, devuelve todos los equipos.
  Future<List<EquipoProteccionModel>> buscar(String texto) {
    return _remoteDatasource.buscar(texto);
  }
}
