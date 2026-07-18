class MatrizIpercModel {
  const MatrizIpercModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
    this.objetivo,
    this.institucionId,
    this.areaId,
    this.actividadId,
    this.fechaRegistro,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? objetivo;
  final int? institucionId;
  final int? areaId;
  final int? actividadId;
  final bool activo;
  final DateTime? fechaRegistro;

  factory MatrizIpercModel.fromJson(Map<String, dynamic> json) {
    return MatrizIpercModel(
      id: _toInt(json['id']),
      codigo: json['codigo']?.toString() ?? 'Sin código',
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      objetivo: json['objetivo']?.toString(),
      institucionId: _toNullableInt(json['institucionId']),
      areaId: _toNullableInt(json['areaId']),
      actividadId: _toNullableInt(json['actividadId']),
      activo: _toBool(json['activo'] ?? json['estado']),
      fechaRegistro: DateTime.tryParse(json['fechaRegistro']?.toString() ?? ''),
    );
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

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    final String texto = value?.toString().toLowerCase() ?? '';

    return texto == 'true' || texto == '1';
  }
}
