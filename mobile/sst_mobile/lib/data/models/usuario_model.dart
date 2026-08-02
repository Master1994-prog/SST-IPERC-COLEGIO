/// Representa un usuario que puede seleccionarse como responsable.
///
/// No contiene contraseña ni información sensible.
class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.activo,
    this.correo,
    this.telefono,
    this.institucionId,
    this.sedeId,
    this.areaId,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;
  final String nombreUsuario;
  final String? correo;
  final String? telefono;
  final int? institucionId;
  final int? sedeId;
  final int? areaId;
  final bool activo;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final String nombres = _texto(json['nombres'] ?? json['Nombres']);

    final String apellidos = _texto(json['apellidos'] ?? json['Apellidos']);

    final String nombreCompletoRecibido = _texto(
      json['nombreCompleto'] ?? json['NombreCompleto'],
    );

    return UsuarioModel(
      id: _entero(json['id'] ?? json['Id']),
      nombres: nombres,
      apellidos: apellidos,
      nombreCompleto: nombreCompletoRecibido.isNotEmpty
          ? nombreCompletoRecibido
          : '$nombres $apellidos'.trim(),
      nombreUsuario: _texto(json['nombreUsuario'] ?? json['NombreUsuario']),
      correo: _textoNullable(json['correo'] ?? json['Correo']),
      telefono: _textoNullable(json['telefono'] ?? json['Telefono']),
      institucionId: _enteroNullable(
        json['institucionId'] ?? json['InstitucionId'],
      ),
      sedeId: _enteroNullable(json['sedeId'] ?? json['SedeId']),
      areaId: _enteroNullable(json['areaId'] ?? json['AreaId']),
      activo: _booleano(
        json['activo'] ?? json['Activo'],
        valorPredeterminado: true,
      ),
    );
  }

  /// Convierte una respuesta del backend en una lista.
  static List<UsuarioModel> listaDesdeJson(dynamic data) {
    final List<dynamic> elementos = _extraerLista(data);

    return elementos
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              UsuarioModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((UsuarioModel usuario) => usuario.id > 0)
        .toList();
  }

  /// Nombre utilizado en la lista de responsables.
  String get nombreVisible {
    if (nombreCompleto.trim().isNotEmpty) {
      return nombreCompleto.trim();
    }

    if (nombreUsuario.trim().isNotEmpty) {
      return nombreUsuario.trim();
    }

    return 'Usuario #$id';
  }

  String get correoVisible {
    final String valor = correo?.trim() ?? '';

    return valor.isEmpty ? 'Sin correo registrado' : valor;
  }

  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final List<dynamic> opciones = <dynamic>[
        mapa['data'],
        mapa['items'],
        mapa['result'],
        mapa['results'],
        mapa['value'],
        mapa['usuarios'],
      ];

      for (final dynamic opcion in opciones) {
        if (opcion is List) {
          return opcion;
        }
      }
    }

    return <dynamic>[];
  }

  static int _entero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static int? _enteroNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final int convertido = _entero(valor);

    return convertido > 0 ? convertido : null;
  }

  static String _texto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  static String? _textoNullable(dynamic valor) {
    final String convertido = _texto(valor);

    return convertido.isEmpty ? null : convertido;
  }

  static bool _booleano(dynamic valor, {required bool valorPredeterminado}) {
    if (valor is bool) {
      return valor;
    }

    if (valor is num) {
      return valor != 0;
    }

    final String texto = valor?.toString().trim().toLowerCase() ?? '';

    if (<String>{'true', '1', 'si', 'sí'}.contains(texto)) {
      return true;
    }

    if (<String>{'false', '0', 'no'}.contains(texto)) {
      return false;
    }

    return valorPredeterminado;
  }
}
