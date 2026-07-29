/// Elemento de una escala de valoración IPERC.
class EscalaRiesgoModel {
  const EscalaRiesgoModel({
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  final int valor;
  final String nombre;
  final String descripcion;
}

/// Rango utilizado para interpretar el resultado de la evaluación.
class NivelRiesgo5x5Model {
  const NivelRiesgo5x5Model({
    required this.nombre,
    required this.desde,
    required this.hasta,
    required this.colorHex,
    required this.aceptable,
    required this.accion,
  });

  final String nombre;
  final int desde;
  final int hasta;
  final String colorHex;
  final bool aceptable;
  final String accion;

  bool contiene(int valor) {
    return valor >= desde && valor <= hasta;
  }
}

/// Resultado completo de cruzar probabilidad y severidad.
class EvaluacionRiesgo5x5Model {
  const EvaluacionRiesgo5x5Model({
    required this.probabilidad,
    required this.severidad,
    required this.nivel,
  });

  final EscalaRiesgoModel probabilidad;
  final EscalaRiesgoModel severidad;
  final NivelRiesgo5x5Model nivel;

  int get valor {
    return probabilidad.valor * severidad.valor;
  }

  bool get requiereAccion {
    return !nivel.aceptable;
  }
}

/// Calculadora local de la matriz IPERC 5×5.
///
/// Los valores y rangos coinciden con los datos iniciales configurados
/// actualmente en el backend. El cálculo no necesita conexión a internet.
class EvaluacionRiesgo5x5Calculator {
  EvaluacionRiesgo5x5Calculator._();

  static const List<EscalaRiesgoModel> probabilidades =
      <EscalaRiesgoModel>[
        EscalaRiesgoModel(
          valor: 1,
          nombre: 'Rara',
          descripcion: 'Puede ocurrir solo en circunstancias excepcionales.',
        ),
        EscalaRiesgoModel(
          valor: 2,
          nombre: 'Poco probable',
          descripcion: 'Podría ocurrir en algún momento.',
        ),
        EscalaRiesgoModel(
          valor: 3,
          nombre: 'Posible',
          descripcion: 'Puede ocurrir ocasionalmente.',
        ),
        EscalaRiesgoModel(
          valor: 4,
          nombre: 'Probable',
          descripcion: 'Puede ocurrir frecuentemente.',
        ),
        EscalaRiesgoModel(
          valor: 5,
          nombre: 'Muy probable',
          descripcion: 'Se espera que ocurra con frecuencia.',
        ),
      ];

  static const List<EscalaRiesgoModel> severidades = <EscalaRiesgoModel>[
    EscalaRiesgoModel(
      valor: 1,
      nombre: 'Insignificante',
      descripcion: 'Afectación leve sin pérdida de jornada.',
    ),
    EscalaRiesgoModel(
      valor: 2,
      nombre: 'Menor',
      descripcion: 'Afectación menor que requiere atención básica.',
    ),
    EscalaRiesgoModel(
      valor: 3,
      nombre: 'Moderada',
      descripcion: 'Afectación con descanso médico o impacto moderado.',
    ),
    EscalaRiesgoModel(
      valor: 4,
      nombre: 'Mayor',
      descripcion: 'Afectación grave o incapacidad temporal significativa.',
    ),
    EscalaRiesgoModel(
      valor: 5,
      nombre: 'Catastrófica',
      descripcion: 'Consecuencia muy grave o incapacidad permanente.',
    ),
  ];

  static const List<NivelRiesgo5x5Model> niveles =
      <NivelRiesgo5x5Model>[
        NivelRiesgo5x5Model(
          nombre: 'Bajo',
          desde: 1,
          hasta: 4,
          colorHex: '#4CAF50',
          aceptable: true,
          accion: 'Mantener los controles y realizar seguimiento periódico.',
        ),
        NivelRiesgo5x5Model(
          nombre: 'Medio',
          desde: 5,
          hasta: 9,
          colorHex: '#FFC107',
          aceptable: true,
          accion: 'Revisar y mejorar los controles existentes.',
        ),
        NivelRiesgo5x5Model(
          nombre: 'Alto',
          desde: 10,
          hasta: 16,
          colorHex: '#FF9800',
          aceptable: false,
          accion: 'Implementar controles antes de continuar la actividad.',
        ),
        NivelRiesgo5x5Model(
          nombre: 'Crítico',
          desde: 17,
          hasta: 25,
          colorHex: '#F44336',
          aceptable: false,
          accion: 'Detener la actividad hasta reducir el nivel de riesgo.',
        ),
      ];

  static EvaluacionRiesgo5x5Model calcular({
    required int probabilidad,
    required int severidad,
  }) {
    final EscalaRiesgoModel probabilidadSeleccionada = probabilidades
        .firstWhere((EscalaRiesgoModel item) => item.valor == probabilidad);
    final EscalaRiesgoModel severidadSeleccionada = severidades.firstWhere(
      (EscalaRiesgoModel item) => item.valor == severidad,
    );
    final int valor = probabilidad * severidad;

    return EvaluacionRiesgo5x5Model(
      probabilidad: probabilidadSeleccionada,
      severidad: severidadSeleccionada,
      nivel: nivelParaValor(valor),
    );
  }

  static NivelRiesgo5x5Model nivelParaValor(int valor) {
    if (valor < 1 || valor > 25) {
      throw RangeError.range(valor, 1, 25, 'valor');
    }

    return niveles.firstWhere(
      (NivelRiesgo5x5Model nivel) => nivel.contiene(valor),
    );
  }
}
