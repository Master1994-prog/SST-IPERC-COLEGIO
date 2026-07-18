class CatalogoItemModel {
  const CatalogoItemModel({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory CatalogoItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogoItemModel(
      id: _toInt(json['id']),
      nombre:
          json['nombre']?.toString() ??
          json['descripcion']?.toString() ??
          'Sin nombre',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
