/// ===============================================================
/// CONSTANTES DE SINCRONIZACIÓN
/// ===============================================================
///
/// Centraliza los valores utilizados por:
///
/// - sincronizaciones_pendientes.
/// - SyncService.
/// - repositorios offline.
/// - servicios de sincronización.
///
/// Evita escribir cadenas como:
///
/// 'CREAR'
/// 'ACTUALIZAR'
/// 'ELIMINAR'
///
/// en distintos archivos y reduce errores por diferencias de texto.
/// ===============================================================
class SyncConstants {
  SyncConstants._();

  // =============================================================
  // ESTADOS DE LA COLA
  // =============================================================

  /// La operación todavía no ha sido procesada.
  static const String pendiente = 'PENDIENTE';

  /// La operación está siendo enviada al backend.
  static const String sincronizando = 'SINCRONIZANDO';

  /// La operación terminó correctamente.
  static const String sincronizado = 'SINCRONIZADO';

  /// La operación falló y puede ser reintentada.
  static const String error = 'ERROR';

  // =============================================================
  // TIPOS DE OPERACIÓN
  // =============================================================

  static const String crear = 'CREAR';

  static const String actualizar = 'ACTUALIZAR';

  static const String eliminar = 'ELIMINAR';

  // =============================================================
  // ENTIDADES SINCRONIZABLES
  // =============================================================

  /// Matriz IPERC principal.
  static const String matrizIperc = 'MATRIZ_IPERC';

  /// Detalle perteneciente a una Matriz IPERC.
  static const String detalleIperc = 'DETALLE_IPERC';

  /// Seguimiento perteneciente a un Detalle IPERC.
  static const String seguimientoIperc = 'SEGUIMIENTO_IPERC';
}
