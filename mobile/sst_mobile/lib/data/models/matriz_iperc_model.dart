class MatrizIpercModel {
  const MatrizIpercModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    this.objetivo,
    this.alcance,
    this.version,
    this.estadoMatriz,
    this.observaciones,
    this.institucionId,
    this.institucionNombre,
    this.sedeId,
    this.areaId,
    this.areaNombre,
    this.procesoId,
    this.actividadId,
    this.actividadNombre,
    this.puestoTrabajoId,
    this.responsableId,
    this.aprobadorId,
    this.fechaEvaluacion,
    this.fechaRevision,
    this.fechaAprobacion,
    this.fechaRegistro,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? objetivo;
  final String? alcance;
  final int? version;
  final String? estadoMatriz;
  final String? observaciones;
  final int? institucionId;
  final String? institucionNombre;
  final int? sedeId;
  final int? areaId;
  final String? areaNombre;
  final int? procesoId;
  final int? actividadId;
  final String? actividadNombre;
  final int? puestoTrabajoId;
  final int? responsableId;
  final int? aprobadorId;
  final bool activo;
  final DateTime? fechaEvaluacion;
  final DateTime? fechaRevision;
  final DateTime? fechaAprobacion;
  final DateTime? fechaRegistro;

  factory MatrizIpercModel.fromJson(Map<String, dynamic> json) {
    final String? estado = _toNullableString(
      json['estadoMatriz'] ?? json['EstadoMatriz'] ?? json['estado'],
    );

    return MatrizIpercModel(
      id: _toInt(json['id'] ?? json['Id']),
      codigo: _toString(json['codigo'] ?? json['Codigo'], 'Sin codigo'),
      nombre: _toString(json['nombre'] ?? json['Nombre'], 'Sin nombre'),
      objetivo: _toNullableString(json['objetivo'] ?? json['Objetivo']),
      alcance: _toNullableString(json['alcance'] ?? json['Alcance']),
      version: _toNullableInt(json['version'] ?? json['Version']),
      estadoMatriz: estado,
      observaciones: _toNullableString(
        json['observaciones'] ?? json['Observaciones'],
      ),
      institucionId: _toNullableInt(
        json['institucionId'] ?? json['InstitucionId'],
      ),
      institucionNombre: _toNullableString(
        json['institucionNombre'] ?? json['InstitucionNombre'],
      ),
      sedeId: _toNullableInt(json['sedeId'] ?? json['SedeId']),
      areaId: _toNullableInt(json['areaId'] ?? json['AreaId']),
      areaNombre: _toNullableString(json['areaNombre'] ?? json['AreaNombre']),
      procesoId: _toNullableInt(json['procesoId'] ?? json['ProcesoId']),
      actividadId: _toNullableInt(
        json['actividadId'] ?? json['ActividadId'],
      ),
      actividadNombre: _toNullableString(
        json['actividadNombre'] ?? json['ActividadNombre'],
      ),
      puestoTrabajoId: _toNullableInt(
        json['puestoTrabajoId'] ?? json['PuestoTrabajoId'],
      ),
      responsableId: _toNullableInt(
        json['responsableId'] ?? json['ResponsableId'],
      ),
      aprobadorId: _toNullableInt(
        json['aprobadorId'] ?? json['AprobadorId'],
      ),
      activo: _leerActivo(json, estado),
      fechaEvaluacion: _toDateTime(
        json['fechaEvaluacion'] ?? json['FechaEvaluacion'],
      ),
      fechaRevision: _toDateTime(json['fechaRevision'] ?? json['FechaRevision']),
      fechaAprobacion: _toDateTime(
        json['fechaAprobacion'] ?? json['FechaAprobacion'],
      ),
      fechaRegistro: _toDateTime(json['fechaRegistro'] ?? json['FechaRegistro']),
    );
  }

  String get institucionVisible {
    return _textoVisible(institucionNombre, institucionId);
  }

  String get areaVisible {
    return _textoVisible(areaNombre, areaId);
  }

  String get actividadVisible {
    return _textoVisible(actividadNombre, actividadId);
  }

  static String _textoVisible(String? nombre, int? id) {
    final String texto = nombre?.trim() ?? '';

    if (texto.isNotEmpty) {
      return texto;
    }

    if (id == null || id <= 0) {
      return 'No asignada';
    }

    return 'ID $id';
  }

  static String _toString(dynamic value, String fallback) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  static String? _toNullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    final String text = value?.toString() ?? '';

    if (text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static bool _leerActivo(Map<String, dynamic> json, String? estado) {
    final dynamic activo = json['activo'] ?? json['Activo'];

    if (activo != null) {
      return _toBool(activo);
    }

    final String estadoTexto = estado?.toLowerCase().trim() ?? '';

    if (estadoTexto == 'cerrada' ||
        estadoTexto == 'cerrado' ||
        estadoTexto == 'inactiva' ||
        estadoTexto == 'inactivo') {
      return false;
    }

    return true;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    final String texto = value?.toString().toLowerCase().trim() ?? '';

    return texto == 'true' ||
        texto == '1' ||
        texto == 'activo' ||
        texto == 'activa';
  }
}
