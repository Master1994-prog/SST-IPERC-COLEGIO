import 'package:flutter/material.dart';

import '../../../data/models/evaluacion_riesgo_model.dart';

/// Pantalla visual para consultar la matriz de riesgo IPERC 5×5.
class MatrizRiesgoScreen extends StatelessWidget {
  const MatrizRiesgoScreen({super.key});

  static const String routeName = '/matriz-riesgo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matriz de riesgo 5×5')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            _DescripcionMatriz(),
            SizedBox(height: 16),
            _MatrizRiesgoTabla(),
            SizedBox(height: 16),
            _LeyendaRiesgo(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Explica cómo se obtiene el valor del riesgo.
class _DescripcionMatriz extends StatelessWidget {
  const _DescripcionMatriz();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.grid_on_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Probabilidad × Severidad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Selecciona la probabilidad y la severidad. '
                    'La intersección muestra el valor y el nivel '
                    'correspondiente del riesgo.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Construye la cuadrícula de cinco probabilidades por cinco severidades.
class _MatrizRiesgoTabla extends StatelessWidget {
  const _MatrizRiesgoTabla();

  @override
  Widget build(BuildContext context) {
    const List<int> severidades = <int>[1, 2, 3, 4, 5];

    // Se muestran en orden descendente para que el riesgo
    // más alto aparezca en la parte superior.
    const List<int> probabilidades = <int>[5, 4, 3, 2, 1];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Severidad',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Permite desplazamiento horizontal en celulares pequeños.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const _CeldaCabecera(
                        texto: 'P/S',
                        tooltip: 'Probabilidad / Severidad',
                      ),
                      ...severidades.map((int severidad) {
                        return _CeldaCabecera(
                          texto: severidad.toString(),
                          tooltip: 'Severidad $severidad',
                        );
                      }),
                    ],
                  ),
                  ...probabilidades.map((int probabilidad) {
                    return Row(
                      children: <Widget>[
                        _CeldaCabecera(
                          texto: probabilidad.toString(),
                          tooltip: 'Probabilidad $probabilidad',
                        ),
                        ...severidades.map((int severidad) {
                          final int valor = probabilidad * severidad;

                          final NivelRiesgoIpercOption nivel =
                              obtenerNivelRiesgoIperc(valor);

                          return _CeldaRiesgo(
                            valor: valor,
                            probabilidad: probabilidad,
                            severidad: severidad,
                            nivel: nivel,
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Probabilidad',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Celda utilizada para los encabezados.
class _CeldaCabecera extends StatelessWidget {
  const _CeldaCabecera({required this.texto, required this.tooltip});

  final String texto;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Celda que muestra el resultado calculado.
class _CeldaRiesgo extends StatelessWidget {
  const _CeldaRiesgo({
    required this.valor,
    required this.probabilidad,
    required this.severidad,
    required this.nivel,
  });

  final int valor;
  final int probabilidad;
  final int severidad;
  final NivelRiesgoIpercOption nivel;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);

    final Brightness brightness = ThemeData.estimateBrightnessForColor(color);

    final Color foreground = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Tooltip(
      message:
          '$probabilidad × $severidad = $valor\n'
          'Riesgo ${nivel.nombre}',
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
        ),
        child: Text(
          valor.toString(),
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Presenta los niveles y rangos de riesgo.
class _LeyendaRiesgo extends StatelessWidget {
  const _LeyendaRiesgo();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Leyenda',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...nivelesRiesgoIperc.map((NivelRiesgoIpercOption nivel) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemLeyenda(nivel: nivel),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Elemento individual de la leyenda.
class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({required this.nivel});

  final NivelRiesgoIpercOption nivel;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);

    return Row(
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${nivel.nombre}: ${nivel.desde} a ${nivel.hasta}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Icon(
          nivel.aceptable
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          color: nivel.aceptable ? Colors.green : Colors.red,
          size: 21,
        ),
      ],
    );
  }
}

/// Convierte un color hexadecimal en un objeto Color.
Color _colorDesdeHex(String hex) {
  String limpio = hex.replaceAll('#', '').trim();

  if (limpio.length == 6) {
    limpio = 'FF$limpio';
  }

  final int? valor = int.tryParse(limpio, radix: 16);

  return Color(valor ?? 0xFF9E9E9E);
}
