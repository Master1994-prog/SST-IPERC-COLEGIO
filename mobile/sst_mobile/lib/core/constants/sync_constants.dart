/// ===============================================================
/// CONSTANTES DE SINCRONIZACIÓN
/// ===============================================================
class SyncConstants {
  SyncConstants._();

  // ESTADOS
  static const String pendiente = 'PENDIENTE';
  static const String sincronizando = 'SINCRONIZANDO';
  static const String sincronizado = 'SINCRONIZADO';
  static const String error = 'ERROR';

  // OPERACIONES
  static const String crear = 'CREAR';
  static const String actualizar = 'ACTUALIZAR';
  static const String eliminar = 'ELIMINAR';

  // ENTIDADES
  static const String matrizIperc = 'MATRIZ_IPERC';
  static const String detalleIperc = 'DETALLE_IPERC';
  static const String seguimientoIperc = 'SEGUIMIENTO_IPERC';

  /// Plano + posiciones de marcadores del mapa de riesgo.
  static const String mapaRiesgo = 'MAPA_RIESGO';
}
