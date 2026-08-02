import 'package:flutter/material.dart';

import '../../../data/models/evaluacion_riesgo_5x5_model.dart';

/// Calculadora y visualizador de la matriz de evaluación de riesgos 5×5.
class EvaluacionRiesgo5x5Screen extends StatefulWidget {
  const EvaluacionRiesgo5x5Screen({this.codigoMatriz, super.key});

  /// Código de la matriz desde la que se abrió la evaluación, si corresponde.
  final String? codigoMatriz;

  @override
  State<EvaluacionRiesgo5x5Screen> createState() {
    return _EvaluacionRiesgo5x5ScreenState();
  }
}

class _EvaluacionRiesgo5x5ScreenState extends State<EvaluacionRiesgo5x5Screen> {
  int _probabilidad = 1;
  int _severidad = 1;

  EvaluacionRiesgo5x5Model get _resultado {
    return EvaluacionRiesgo5x5Calculator.calcular(
      probabilidad: _probabilidad,
      severidad: _severidad,
    );
  }

  void _seleccionar({required int probabilidad, required int severidad}) {
    setState(() {
      _probabilidad = probabilidad;
      _severidad = severidad;
    });
  }

  @override
  Widget build(BuildContext context) {
    final EvaluacionRiesgo5x5Model resultado = _resultado;

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación de riesgo 5×5')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (widget.codigoMatriz != null) ...<Widget>[
            _MatrizOrigenCard(codigoMatriz: widget.codigoMatriz!),
            const SizedBox(height: 16),
          ],
          const _IntroduccionCard(),
          const SizedBox(height: 16),
          _SelectorEscala(
            titulo: '1. Probabilidad',
            subtitulo: 'Selecciona qué tan probable es que ocurra el evento.',
            opciones: EvaluacionRiesgo5x5Calculator.probabilidades,
            valorSeleccionado: _probabilidad,
            onSelected: (int valor) {
              setState(() {
                _probabilidad = valor;
              });
            },
          ),
          const SizedBox(height: 16),
          _SelectorEscala(
            titulo: '2. Severidad',
            subtitulo: 'Selecciona la magnitud de la consecuencia.',
            opciones: EvaluacionRiesgo5x5Calculator.severidades,
            valorSeleccionado: _severidad,
            onSelected: (int valor) {
              setState(() {
                _severidad = valor;
              });
            },
          ),
          const SizedBox(height: 16),
          _ResultadoCard(resultado: resultado),
          const SizedBox(height: 16),
          _Matriz5x5(
            probabilidadSeleccionada: _probabilidad,
            severidadSeleccionada: _severidad,
            onSelected: _seleccionar,
          ),
          const SizedBox(height: 16),
          const _LeyendaNiveles(),
        ],
      ),
    );
  }
}

class _MatrizOrigenCard extends StatelessWidget {
  const _MatrizOrigenCard({required this.codigoMatriz});

  final String codigoMatriz;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
        title: const Text('Matriz seleccionada'),
        subtitle: Text(codigoMatriz),
      ),
    );
  }
}

class _IntroduccionCard extends StatelessWidget {
  const _IntroduccionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'El valor del riesgo se obtiene multiplicando la probabilidad '
                'por la severidad. Puedes usar los selectores o tocar una '
                'celda de la matriz.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorEscala extends StatelessWidget {
  const _SelectorEscala({
    required this.titulo,
    required this.subtitulo,
    required this.opciones,
    required this.valorSeleccionado,
    required this.onSelected,
  });

  final String titulo;
  final String subtitulo;
  final List<EscalaRiesgoModel> opciones;
  final int valorSeleccionado;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final EscalaRiesgoModel seleccionada = opciones.firstWhere(
      (EscalaRiesgoModel opcion) => opcion.valor == valorSeleccionado,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              titulo,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitulo),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opciones.map((EscalaRiesgoModel opcion) {
                return ChoiceChip(
                  label: Text('${opcion.valor}'),
                  selected: opcion.valor == valorSeleccionado,
                  onSelected: (_) {
                    onSelected(opcion.valor);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              '${seleccionada.valor}. ${seleccionada.nombre}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(seleccionada.descripcion),
          ],
        ),
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.resultado});

  final EvaluacionRiesgo5x5Model resultado;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(resultado.nivel.colorHex);
    final Color foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Semantics(
      liveRegion: true,
      label:
          'Resultado ${resultado.valor}, riesgo ${resultado.nivel.nombre}, '
          '${resultado.nivel.aceptable ? 'aceptable' : 'no aceptable'}',
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                '${resultado.probabilidad.valor} × '
                '${resultado.severidad.valor} = ${resultado.valor}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Riesgo ${resultado.nivel.nombre}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                resultado.nivel.aceptable ? 'Aceptable' : 'No aceptable',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                resultado.nivel.accion,
                textAlign: TextAlign.center,
                style: TextStyle(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Matriz5x5 extends StatelessWidget {
  const _Matriz5x5({
    required this.probabilidadSeleccionada,
    required this.severidadSeleccionada,
    required this.onSelected,
  });

  final int probabilidadSeleccionada;
  final int severidadSeleccionada;
  final void Function({required int probabilidad, required int severidad})
  onSelected;

  @override
  Widget build(BuildContext context) {
    const double cellSize = 48;
    final List<int> probabilidades = <int>[5, 4, 3, 2, 1];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Matriz visual 5×5',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('P = probabilidad · S = severidad'),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(width: cellSize),
                      ...List<Widget>.generate(5, (int index) {
                        final int severidad = index + 1;
                        return SizedBox(
                          width: cellSize,
                          height: 34,
                          child: Center(
                            child: Text(
                              'S$severidad',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  ...probabilidades.map((int probabilidad) {
                    return Row(
                      children: <Widget>[
                        SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: Center(
                            child: Text(
                              'P$probabilidad',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ...List<Widget>.generate(5, (int index) {
                          final int severidad = index + 1;
                          final int valor = probabilidad * severidad;
                          final NivelRiesgo5x5Model nivel =
                              EvaluacionRiesgo5x5Calculator.nivelParaValor(
                                valor,
                              );
                          final bool seleccionada =
                              probabilidad == probabilidadSeleccionada &&
                              severidad == severidadSeleccionada;

                          return _CeldaRiesgo(
                            size: cellSize,
                            probabilidad: probabilidad,
                            severidad: severidad,
                            valor: valor,
                            nivel: nivel,
                            seleccionada: seleccionada,
                            onTap: () {
                              onSelected(
                                probabilidad: probabilidad,
                                severidad: severidad,
                              );
                            },
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CeldaRiesgo extends StatelessWidget {
  const _CeldaRiesgo({
    required this.size,
    required this.probabilidad,
    required this.severidad,
    required this.valor,
    required this.nivel,
    required this.seleccionada,
    required this.onTap,
  });

  final double size;
  final int probabilidad;
  final int severidad;
  final int valor;
  final NivelRiesgo5x5Model nivel;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);
    final Color foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Semantics(
      button: true,
      selected: seleccionada,
      label:
          'Probabilidad $probabilidad, severidad $severidad, '
          'valor $valor, riesgo ${nivel.nombre}',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: seleccionada
                ? const BorderSide(color: Colors.black, width: 3)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size - 4,
              height: size - 4,
              child: Center(
                child: seleccionada
                    ? Icon(Icons.check, color: foreground, size: 22)
                    : Text(
                        '$valor',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeyendaNiveles extends StatelessWidget {
  const _LeyendaNiveles();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Niveles de riesgo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...EvaluacionRiesgo5x5Calculator.niveles.map((
              NivelRiesgo5x5Model nivel,
            ) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _colorDesdeHex(nivel.colorHex),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${nivel.nombre}: ${nivel.desde}–${nivel.hasta} '
                        '(${nivel.aceptable ? 'aceptable' : 'no aceptable'})',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Color _colorDesdeHex(String hex) {
  final String limpio = hex.replaceFirst('#', '');
  return Color(int.parse('FF$limpio', radix: 16));
}
