/// ===============================================================
/// MODELO LOCAL - MATRIZ IPERC
/// ===============================================================
///
/// Representa una matriz IPERC almacenada en SQLite.
///
/// Guarda los identificadores necesarios para poder crear
/// posteriormente la matriz en el backend cuando vuelva internet.
/// ===============================================================
class MatrizIpercLocalModel {
  const MatrizIpercLocalModel({
    required this.idLocal,
    this.idServidor,

    required this.institucionId,
    this.sedeId,
    this.areaId,
    this.procesoId,
    this.actividadId,
    this.puestoTrabajoId,

    this.codigo,
    required this.nombre,
    this.descripcion,

    required this.fechaEvaluacion,

    this.estadoMatriz = 'BORRADOR',

    this.sincronizado = false,
    this.eliminado = false,

    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaSincronizacion,
  });

  // =============================================================
  // IDENTIFICADORES
  // =============================================================

  /// ID generado en el dispositivo.
  final String idLocal;

  /// ID asignado por el backend luego de sincronizar.
  final String? idServidor;

  // =============================================================
  // RELACIONES
  // =============================================================

  final String institucionId;

  /// Sede seleccionada.
  final String? sedeId;

  final String? areaId;

  final String? procesoId;

  /// Actividad seleccionada.
  final String? actividadId;

  final String? puestoTrabajoId;

  // =============================================================
  // DATOS
  // =============================================================

  final String? codigo;

  final String nombre;

  final String? descripcion;

  final DateTime fechaEvaluacion;

  final String estadoMatriz;

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  final bool sincronizado;

  final bool eliminado;

  final DateTime fechaRegistro;

  final DateTime? fechaActualizacion;

  final DateTime? fechaSincronizacion;

  // =============================================================
  // SQLITE
  // =============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_local': idLocal,
      'id_servidor': idServidor,

      'institucion_id': institucionId,
      'sede_id': sedeId,
      'area_id': areaId,
      'proceso_id': procesoId,
      'actividad_id': actividadId,
      'puesto_trabajo_id': puestoTrabajoId,

      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,

      'fecha_evaluacion': fechaEvaluacion.toIso8601String(),

      'estado_matriz': estadoMatriz,

      'sincronizado': sincronizado ? 1 : 0,

      'eliminado': eliminado ? 1 : 0,

      'fecha_registro': fechaRegistro.toIso8601String(),

      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),

      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
    };
  }

  // =============================================================
  // DESDE SQLITE
  // =============================================================

  factory MatrizIpercLocalModel.fromMap(Map<String, dynamic> map) {
    return MatrizIpercLocalModel(
      idLocal: map['id_local']?.toString() ?? '',

      idServidor: _nullableString(map['id_servidor']),

      institucionId: map['institucion_id']?.toString() ?? '',

      sedeId: _nullableString(map['sede_id']),

      areaId: _nullableString(map['area_id']),

      procesoId: _nullableString(map['proceso_id']),

      actividadId: _nullableString(map['actividad_id']),

      puestoTrabajoId: _nullableString(map['puesto_trabajo_id']),

      codigo: _nullableString(map['codigo']),

      nombre: map['nombre']?.toString() ?? '',

      descripcion: _nullableString(map['descripcion']),

      fechaEvaluacion: DateTime.parse(map['fecha_evaluacion'].toString()),

      estadoMatriz: map['estado_matriz']?.toString() ?? 'BORRADOR',

      sincronizado: _boolValue(map['sincronizado']),

      eliminado: _boolValue(map['eliminado']),

      fechaRegistro: DateTime.parse(map['fecha_registro'].toString()),

      fechaActualizacion: _nullableDate(map['fecha_actualizacion']),

      fechaSincronizacion: _nullableDate(map['fecha_sincronizacion']),
    );
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  MatrizIpercLocalModel copyWith({
    String? idServidor,

    String? sedeId,
    String? areaId,
    String? procesoId,
    String? actividadId,
    String? puestoTrabajoId,

    String? codigo,
    String? nombre,
    String? descripcion,

    String? estadoMatriz,

    bool? sincronizado,
    bool? eliminado,

    DateTime? fechaActualizacion,
    DateTime? fechaSincronizacion,
  }) {
    return MatrizIpercLocalModel(
      idLocal: idLocal,

      idServidor: idServidor ?? this.idServidor,

      institucionId: institucionId,

      sedeId: sedeId ?? this.sedeId,

      areaId: areaId ?? this.areaId,

      procesoId: procesoId ?? this.procesoId,

      actividadId: actividadId ?? this.actividadId,

      puestoTrabajoId: puestoTrabajoId ?? this.puestoTrabajoId,

      codigo: codigo ?? this.codigo,

      nombre: nombre ?? this.nombre,

      descripcion: descripcion ?? this.descripcion,

      fechaEvaluacion: fechaEvaluacion,

      estadoMatriz: estadoMatriz ?? this.estadoMatriz,

      sincronizado: sincronizado ?? this.sincronizado,

      eliminado: eliminado ?? this.eliminado,

      fechaRegistro: fechaRegistro,

      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,

      fechaSincronizacion: fechaSincronizacion ?? this.fechaSincronizacion,
    );
  }

  // =============================================================
  // AUXILIARES
  // =============================================================

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String texto = value.toString().trim();

    return texto.isEmpty ? null : texto;
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value.toInt() == 1;
    }

    final String texto = value.toString().trim().toLowerCase();

    return texto == '1' || texto == 'true';
  }
}
