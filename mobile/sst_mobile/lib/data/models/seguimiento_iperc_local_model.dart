/// ===============================================================
/// MODELO LOCAL - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Representa un seguimiento IPERC almacenado en SQLite.
///
/// Mantiene separados:
///
/// - El identificador generado localmente.
/// - El identificador asignado por el backend.
/// - El identificador local del Detalle IPERC.
/// - El identificador del Detalle IPERC en el backend.
///
/// Esto permite crear seguimientos aun cuando el Detalle IPERC todavía
/// no ha sido sincronizado.
///
/// Flujo:
///
/// Seguimiento local
///       ↓
/// SQLite
///       ↓
/// Cola de sincronización
///       ↓
/// Detalle IPERC obtiene ID servidor
///       ↓
/// Seguimiento se envía al backend
/// ===============================================================
class SeguimientoIpercLocalModel {
  const SeguimientoIpercLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.detalleIpercIdLocal,
    this.detalleIpercIdServidor,
    this.detalleItem,
    this.detalleTarea,
    required this.fechaSeguimiento,
    required this.usuarioId,
    this.usuarioNombre,
    required this.descripcion,
    required this.porcentajeAvance,
    this.verificado = false,
    this.fechaVerificacion,
    this.observaciones,
    this.archivo,
    this.nombreArchivo,
    this.tipoArchivo,
    this.sincronizado = false,
    this.eliminado = false,
    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  // =============================================================
  // IDENTIFICADORES
  // =============================================================

  /// Identificador generado por la aplicación.
  final String idLocal;

  /// Identificador asignado por el backend después de sincronizar.
  final int? idServidor;

  /// Identificador local del Detalle IPERC padre.
  final String detalleIpercIdLocal;

  /// Identificador real del Detalle IPERC en el backend.
  final int? detalleIpercIdServidor;

  // =============================================================
  // INFORMACIÓN VISIBLE DEL DETALLE
  // =============================================================

  /// Número de ítem del detalle. Se almacena para mostrar información
  /// útil incluso cuando no existe conexión.
  final int? detalleItem;

  /// Tarea del detalle IPERC.
  final String? detalleTarea;

  // =============================================================
  // SEGUIMIENTO
  // =============================================================

  final DateTime fechaSeguimiento;

  /// Usuario autenticado que registra el seguimiento.
  final int usuarioId;

  /// Nombre visible del usuario. Es informativo y puede ser nulo.
  final String? usuarioNombre;

  final String descripcion;

  /// Porcentaje de avance entre 0 y 100.
  final double porcentajeAvance;

  final bool verificado;

  final DateTime? fechaVerificacion;

  final String? observaciones;

  // =============================================================
  // EVIDENCIA
  // =============================================================

  /// Contenido o referencia del archivo según el formato que utilice
  /// actualmente el backend.
  final String? archivo;

  final String? nombreArchivo;

  final String? tipoArchivo;

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  final bool sincronizado;

  final bool eliminado;

  final DateTime fechaRegistro;

  final DateTime? fechaActualizacion;

  final DateTime? fechaSincronizacion;

  // =============================================================
  // GETTERS
  // =============================================================

  bool get tieneIdServidor {
    return idServidor != null && idServidor! > 0;
  }

  bool get tieneDetalleServidor {
    return detalleIpercIdServidor != null && detalleIpercIdServidor! > 0;
  }

  bool get pendienteSincronizacion {
    return !sincronizado;
  }

  bool get tieneEvidencia {
    return (archivo?.trim().isNotEmpty ?? false) ||
        (nombreArchivo?.trim().isNotEmpty ?? false);
  }

  String get detalleVisible {
    final String tarea = detalleTarea?.trim() ?? '';
    final String item = detalleItem == null ? '' : 'Item $detalleItem';

    if (item.isNotEmpty && tarea.isNotEmpty) {
      return '$item - $tarea';
    }

    if (tarea.isNotEmpty) {
      return tarea;
    }

    if (tieneDetalleServidor) {
      return 'Detalle IPERC $detalleIpercIdServidor';
    }

    return 'Detalle IPERC local';
  }

  String get estadoVisible {
    return verificado ? 'Verificado' : 'Pendiente';
  }

  // =============================================================
  // SQLITE
  // =============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_local': idLocal,
      'id_servidor': idServidor,
      'detalle_iperc_id_local': detalleIpercIdLocal,
      'detalle_iperc_id_servidor': detalleIpercIdServidor,
      'detalle_item': detalleItem,
      'detalle_tarea': _textoOpcional(detalleTarea),
      'fecha_seguimiento': fechaSeguimiento.toUtc().toIso8601String(),
      'usuario_id': usuarioId,
      'usuario_nombre': _textoOpcional(usuarioNombre),
      'descripcion': descripcion.trim(),
      'porcentaje_avance': porcentajeAvance,
      'verificado': verificado ? 1 : 0,
      'fecha_verificacion': fechaVerificacion?.toUtc().toIso8601String(),
      'observaciones': _textoOpcional(observaciones),
      'archivo': _textoOpcional(archivo),
      'nombre_archivo': _textoOpcional(nombreArchivo),
      'tipo_archivo': _textoOpcional(tipoArchivo),
      'sincronizado': sincronizado ? 1 : 0,
      'eliminado': eliminado ? 1 : 0,
      'fecha_registro': fechaRegistro.toUtc().toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toUtc().toIso8601String(),
      'fecha_sincronizacion': fechaSincronizacion?.toUtc().toIso8601String(),
    };
  }

  factory SeguimientoIpercLocalModel.fromMap(Map<String, dynamic> map) {
    return SeguimientoIpercLocalModel(
      idLocal: _stringValue(map['id_local']),
      idServidor: _nullableInt(map['id_servidor']),
      detalleIpercIdLocal: _stringValue(map['detalle_iperc_id_local']),
      detalleIpercIdServidor: _nullableInt(map['detalle_iperc_id_servidor']),
      detalleItem: _nullableInt(map['detalle_item']),
      detalleTarea: _nullableString(map['detalle_tarea']),
      fechaSeguimiento:
          _nullableDate(map['fecha_seguimiento']) ?? DateTime.now().toUtc(),
      usuarioId: _intValue(map['usuario_id']),
      usuarioNombre: _nullableString(map['usuario_nombre']),
      descripcion: _stringValue(map['descripcion']),
      porcentajeAvance: _doubleValue(map['porcentaje_avance']),
      verificado: _boolValue(map['verificado']),
      fechaVerificacion: _nullableDate(map['fecha_verificacion']),
      observaciones: _nullableString(map['observaciones']),
      archivo: _nullableString(map['archivo']),
      nombreArchivo: _nullableString(map['nombre_archivo']),
      tipoArchivo: _nullableString(map['tipo_archivo']),
      sincronizado: _boolValue(map['sincronizado']),
      eliminado: _boolValue(map['eliminado']),
      fechaRegistro:
          _nullableDate(map['fecha_registro']) ?? DateTime.now().toUtc(),
      fechaActualizacion: _nullableDate(map['fecha_actualizacion']),
      fechaSincronizacion: _nullableDate(map['fecha_sincronizacion']),
    );
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  SeguimientoIpercLocalModel copyWith({
    int? idServidor,
    int? detalleIpercIdServidor,
    int? detalleItem,
    String? detalleTarea,
    DateTime? fechaSeguimiento,
    int? usuarioId,
    String? usuarioNombre,
    String? descripcion,
    double? porcentajeAvance,
    bool? verificado,
    DateTime? fechaVerificacion,
    String? observaciones,
    String? archivo,
    String? nombreArchivo,
    String? tipoArchivo,
    bool? sincronizado,
    bool? eliminado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    DateTime? fechaSincronizacion,
  }) {
    return SeguimientoIpercLocalModel(
      idLocal: idLocal,
      idServidor: idServidor ?? this.idServidor,
      detalleIpercIdLocal: detalleIpercIdLocal,
      detalleIpercIdServidor:
          detalleIpercIdServidor ?? this.detalleIpercIdServidor,
      detalleItem: detalleItem ?? this.detalleItem,
      detalleTarea: detalleTarea ?? this.detalleTarea,
      fechaSeguimiento: fechaSeguimiento ?? this.fechaSeguimiento,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      descripcion: descripcion ?? this.descripcion,
      porcentajeAvance: porcentajeAvance ?? this.porcentajeAvance,
      verificado: verificado ?? this.verificado,
      fechaVerificacion: fechaVerificacion ?? this.fechaVerificacion,
      observaciones: observaciones ?? this.observaciones,
      archivo: archivo ?? this.archivo,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      sincronizado: sincronizado ?? this.sincronizado,
      eliminado: eliminado ?? this.eliminado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaSincronizacion: fechaSincronizacion ?? this.fechaSincronizacion,
    );
  }

  // =============================================================
  // COPY WITH PARA CAMPOS NULLABLES
  // =============================================================
  //
  // copyWith() conserva los valores nulos existentes para mantener
  // una API simple. Estos helpers permiten limpiar explícitamente
  // campos que deben quedar en NULL.

  SeguimientoIpercLocalModel limpiarVerificacion() {
    return SeguimientoIpercLocalModel(
      idLocal: idLocal,
      idServidor: idServidor,
      detalleIpercIdLocal: detalleIpercIdLocal,
      detalleIpercIdServidor: detalleIpercIdServidor,
      detalleItem: detalleItem,
      detalleTarea: detalleTarea,
      fechaSeguimiento: fechaSeguimiento,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      descripcion: descripcion,
      porcentajeAvance: porcentajeAvance,
      verificado: false,
      fechaVerificacion: null,
      observaciones: observaciones,
      archivo: archivo,
      nombreArchivo: nombreArchivo,
      tipoArchivo: tipoArchivo,
      sincronizado: sincronizado,
      eliminado: eliminado,
      fechaRegistro: fechaRegistro,
      fechaActualizacion: fechaActualizacion,
      fechaSincronizacion: fechaSincronizacion,
    );
  }

  SeguimientoIpercLocalModel marcarComoSincronizado({
    required int servidorId,
    int? detalleServidorId,
  }) {
    if (servidorId <= 0) {
      throw ArgumentError.value(
        servidorId,
        'servidorId',
        'Debe ser mayor que cero.',
      );
    }

    return SeguimientoIpercLocalModel(
      idLocal: idLocal,
      idServidor: servidorId,
      detalleIpercIdLocal: detalleIpercIdLocal,
      detalleIpercIdServidor: detalleServidorId ?? detalleIpercIdServidor,
      detalleItem: detalleItem,
      detalleTarea: detalleTarea,
      fechaSeguimiento: fechaSeguimiento,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      descripcion: descripcion,
      porcentajeAvance: porcentajeAvance,
      verificado: verificado,
      fechaVerificacion: fechaVerificacion,
      observaciones: observaciones,
      archivo: archivo,
      nombreArchivo: nombreArchivo,
      tipoArchivo: tipoArchivo,
      sincronizado: true,
      eliminado: eliminado,
      fechaRegistro: fechaRegistro,
      fechaActualizacion: fechaActualizacion,
      fechaSincronizacion: DateTime.now().toUtc(),
    );
  }
}

// ===============================================================
// HELPERS
// ===============================================================

String _stringValue(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _nullableString(dynamic value) {
  final String texto = value?.toString().trim() ?? '';

  return texto.isEmpty ? null : texto;
}

int _intValue(dynamic value, {int valorPredeterminado = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? valorPredeterminado;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double _doubleValue(dynamic value, {double valorPredeterminado = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? valorPredeterminado;
}

bool _boolValue(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final String texto = value?.toString().trim().toLowerCase() ?? '';

  return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
}

DateTime? _nullableDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

String? _textoOpcional(String? value) {
  final String texto = value?.trim() ?? '';

  return texto.isEmpty ? null : texto;
}
