class MatrizIpercLocalModel {
  const MatrizIpercLocalModel({
    required this.idLocal,
    this.idServidor,
    required this.institucionId,
    this.areaId,
    this.procesoId,
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

  final String idLocal;
  final String? idServidor;

  final String institucionId;
  final String? areaId;
  final String? procesoId;
  final String? puestoTrabajoId;

  final String? codigo;
  final String nombre;
  final String? descripcion;

  final DateTime fechaEvaluacion;
  final String estadoMatriz;

  final bool sincronizado;
  final bool eliminado;

  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final DateTime? fechaSincronizacion;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id_local': idLocal,
      'id_servidor': idServidor,
      'institucion_id': institucionId,
      'area_id': areaId,
      'proceso_id': procesoId,
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

  factory MatrizIpercLocalModel.fromMap(Map<String, dynamic> map) {
    return MatrizIpercLocalModel(
      idLocal: map['id_local'] as String,
      idServidor: map['id_servidor'] as String?,
      institucionId: map['institucion_id'] as String,
      areaId: map['area_id'] as String?,
      procesoId: map['proceso_id'] as String?,
      puestoTrabajoId: map['puesto_trabajo_id'] as String?,
      codigo: map['codigo'] as String?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      fechaEvaluacion: DateTime.parse(map['fecha_evaluacion'] as String),
      estadoMatriz: map['estado_matriz'] as String,
      sincronizado: (map['sincronizado'] as int) == 1,
      eliminado: (map['eliminado'] as int) == 1,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
      fechaActualizacion: map['fecha_actualizacion'] == null
          ? null
          : DateTime.parse(map['fecha_actualizacion'] as String),
      fechaSincronizacion: map['fecha_sincronizacion'] == null
          ? null
          : DateTime.parse(map['fecha_sincronizacion'] as String),
    );
  }

  MatrizIpercLocalModel copyWith({
    String? idServidor,
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
      areaId: areaId,
      procesoId: procesoId,
      puestoTrabajoId: puestoTrabajoId,
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
}
