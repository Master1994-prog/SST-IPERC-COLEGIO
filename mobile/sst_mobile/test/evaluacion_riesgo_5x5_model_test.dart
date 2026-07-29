import 'package:flutter_test/flutter_test.dart';
import 'package:sst_mobile/data/models/evaluacion_riesgo_5x5_model.dart';

void main() {
  group('EvaluacionRiesgo5x5Calculator', () {
    test('calcula correctamente los cuatro niveles de riesgo', () {
      expect(
        EvaluacionRiesgo5x5Calculator.calcular(
          probabilidad: 1,
          severidad: 4,
        ).nivel.nombre,
        'Bajo',
      );
      expect(
        EvaluacionRiesgo5x5Calculator.calcular(
          probabilidad: 3,
          severidad: 3,
        ).nivel.nombre,
        'Medio',
      );
      expect(
        EvaluacionRiesgo5x5Calculator.calcular(
          probabilidad: 4,
          severidad: 4,
        ).nivel.nombre,
        'Alto',
      );
      expect(
        EvaluacionRiesgo5x5Calculator.calcular(
          probabilidad: 5,
          severidad: 5,
        ).nivel.nombre,
        'Crítico',
      );
    });

    test('multiplica probabilidad por severidad', () {
      final EvaluacionRiesgo5x5Model resultado =
          EvaluacionRiesgo5x5Calculator.calcular(
            probabilidad: 4,
            severidad: 3,
          );

      expect(resultado.valor, 12);
      expect(resultado.requiereAccion, isTrue);
    });

    test('rechaza valores fuera del rango de la matriz', () {
      expect(
        () => EvaluacionRiesgo5x5Calculator.nivelParaValor(0),
        throwsRangeError,
      );
      expect(
        () => EvaluacionRiesgo5x5Calculator.nivelParaValor(26),
        throwsRangeError,
      );
    });
  });
}
