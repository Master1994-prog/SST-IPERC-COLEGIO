/// Representa una evaluación de riesgo IPERC.
class EvaluacionRiesgoModel {
  const EvaluacionRiesgoModel({
    required this.id,
    required this.probabilidadId,
    required this.severidadId,
    required this.nivelRiesgoId,
    required this.valor,
    required this.esAceptable,
    required this.requiereAccion,
    this.observaciones,
  });

  final int id;
  final int probabilidadId;
  final int severidadId;
  final int nivelRiesgoId;
  final int valor;
  final bool esAceptable;
  final bool requiereAccion;
  final String? observaciones;

  factory EvaluacionRiesgoModel.fromJson(Map<String, dynamic> json) {
    return EvaluacionRiesgoModel(
      id: _toInt(json['id'] ?? json['Id']),
      probabilidadId: _toInt(json['probabilidadId'] ?? json['ProbabilidadId']),
      severidadId: _toInt(json['severidadId'] ?? json['SeveridadId']),
      nivelRiesgoId: _toInt(json['nivelRiesgoId'] ?? json['NivelRiesgoId']),
      valor: _toInt(json['valor'] ?? json['Valor']),
      esAceptable: _toBool(json['esAceptable'] ?? json['EsAceptable']),
      requiereAccion: _toBool(json['requiereAccion'] ?? json['RequiereAccion']),
      observaciones: _toNullableString(
        json['observaciones'] ?? json['Observaciones'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    final String texto = value?.toString().toLowerCase().trim() ?? '';

    return texto == 'true' || texto == '1' || texto == 'si';
  }

  static String? _toNullableString(dynamic value) {
    final String texto = value?.toString().trim() ?? '';
    return texto.isEmpty ? null : texto;
  }
}

/// Solicitud para registrar una evaluación de riesgo.
class CrearEvaluacionRiesgoRequest {
  const CrearEvaluacionRiesgoRequest({
    required this.probabilidadId,
    required this.severidadId,
    required this.nivelRiesgoId,
    this.observaciones,
  });

  final int probabilidadId;
  final int severidadId;
  final int nivelRiesgoId;
  final String? observaciones;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'probabilidadId': probabilidadId,
      'severidadId': severidadId,
      'nivelRiesgoId': nivelRiesgoId,
      'observaciones': _nullableText(observaciones),
    };
  }

  String? _nullableText(String? value) {
    final String texto = value?.trim() ?? '';
    return texto.isEmpty ? null : texto;
  }
}

/// Solicitud para actualizar una evaluación existente.
class ActualizarEvaluacionRiesgoRequest {
  const ActualizarEvaluacionRiesgoRequest({
    required this.probabilidadId,
    required this.severidadId,
    required this.nivelRiesgoId,
    this.observaciones,
  });

  final int probabilidadId;
  final int severidadId;
  final int nivelRiesgoId;
  final String? observaciones;

  Map<String, dynamic> toJson() {
    final String texto = observaciones?.trim() ?? '';

    return <String, dynamic>{
      'probabilidadId': probabilidadId,
      'severidadId': severidadId,
      'nivelRiesgoId': nivelRiesgoId,
      'observaciones': texto.isEmpty ? null : texto,
    };
  }
}

/// Opción de probabilidad para evitar escribir identificadores.
class ProbabilidadIpercOption {
  const ProbabilidadIpercOption({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  final int id;
  final int valor;
  final String nombre;
  final String descripcion;

  String get etiqueta => '$valor - $nombre';
}

/// Opción de severidad para evitar escribir identificadores.
class SeveridadIpercOption {
  const SeveridadIpercOption({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  final int id;
  final int valor;
  final String nombre;
  final String descripcion;

  String get etiqueta => '$valor - $nombre';
}

/// Nivel obtenido después de calcular probabilidad por severidad.
class NivelRiesgoIpercOption {
  const NivelRiesgoIpercOption({
    required this.id,
    required this.nombre,
    required this.desde,
    required this.hasta,
    required this.colorHex,
    required this.aceptable,
  });

  final int id;
  final String nombre;
  final int desde;
  final int hasta;
  final String colorHex;
  final bool aceptable;

  bool contiene(int valor) {
    return valor >= desde && valor <= hasta;
  }
}

/// Resultado completo del cálculo de riesgo.
class ResultadoRiesgoCalculado {
  const ResultadoRiesgoCalculado({
    required this.probabilidad,
    required this.severidad,
    required this.valor,
    required this.nivel,
  });

  final ProbabilidadIpercOption probabilidad;
  final SeveridadIpercOption severidad;
  final int valor;
  final NivelRiesgoIpercOption nivel;
}

// Alias para mantener compatibilidad con pantallas anteriores.
typedef ProbabilidadRiesgoModel = ProbabilidadIpercOption;
typedef SeveridadRiesgoModel = SeveridadIpercOption;
typedef NivelRiesgoModel = NivelRiesgoIpercOption;

/// Catálogo local de probabilidades.
const List<ProbabilidadIpercOption> probabilidadesIperc =
    <ProbabilidadIpercOption>[
      ProbabilidadIpercOption(
        id: 1,
        valor: 1,
        nombre: 'Rara',
        descripcion: 'Puede ocurrir solo en circunstancias excepcionales.',
      ),
      ProbabilidadIpercOption(
        id: 2,
        valor: 2,
        nombre: 'Poco probable',
        descripcion: 'Podría ocurrir en algún momento.',
      ),
      ProbabilidadIpercOption(
        id: 3,
        valor: 3,
        nombre: 'Posible',
        descripcion: 'Puede ocurrir ocasionalmente.',
      ),
      ProbabilidadIpercOption(
        id: 4,
        valor: 4,
        nombre: 'Probable',
        descripcion: 'Puede ocurrir frecuentemente.',
      ),
      ProbabilidadIpercOption(
        id: 5,
        valor: 5,
        nombre: 'Muy probable',
        descripcion: 'Se espera que ocurra con frecuencia.',
      ),
    ];

/// Catálogo local de severidades.
const List<SeveridadIpercOption> severidadesIperc = <SeveridadIpercOption>[
  SeveridadIpercOption(
    id: 1,
    valor: 1,
    nombre: 'Insignificante',
    descripcion: 'Evento leve sin pérdida de jornada.',
  ),
  SeveridadIpercOption(
    id: 2,
    valor: 2,
    nombre: 'Menor',
    descripcion: 'Evento menor con atención básica.',
  ),
  SeveridadIpercOption(
    id: 3,
    valor: 3,
    nombre: 'Moderada',
    descripcion: 'Evento con descanso médico o afectación moderada.',
  ),
  SeveridadIpercOption(
    id: 4,
    valor: 4,
    nombre: 'Mayor',
    descripcion: 'Evento grave o incapacidad temporal significativa.',
  ),
  SeveridadIpercOption(
    id: 5,
    valor: 5,
    nombre: 'Catastrófica',
    descripcion: 'Evento con consecuencia permanente o muy severa.',
  ),
];

/// Rangos utilizados por la matriz IPERC 5×5.
const List<NivelRiesgoIpercOption> nivelesRiesgoIperc =
    <NivelRiesgoIpercOption>[
      NivelRiesgoIpercOption(
        id: 1,
        nombre: 'Bajo',
        desde: 1,
        hasta: 4,
        colorHex: '#4CAF50',
        aceptable: true,
      ),
      NivelRiesgoIpercOption(
        id: 2,
        nombre: 'Medio',
        desde: 5,
        hasta: 9,
        colorHex: '#FFC107',
        aceptable: true,
      ),
      NivelRiesgoIpercOption(
        id: 3,
        nombre: 'Alto',
        desde: 10,
        hasta: 16,
        colorHex: '#FF9800',
        aceptable: false,
      ),
      NivelRiesgoIpercOption(
        id: 4,
        nombre: 'Crítico',
        desde: 17,
        hasta: 25,
        colorHex: '#F44336',
        aceptable: false,
      ),
    ];

/// Devuelve el nivel correspondiente al valor calculado.
NivelRiesgoIpercOption obtenerNivelRiesgoIperc(int valor) {
  return nivelesRiesgoIperc.firstWhere((NivelRiesgoIpercOption nivel) {
    return nivel.contiene(valor);
  }, orElse: () => nivelesRiesgoIperc.last);
}
