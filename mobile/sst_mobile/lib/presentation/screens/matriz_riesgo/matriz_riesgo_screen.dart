import 'package:flutter/material.dart';

/// Pantalla visual para consultar la matriz básica de riesgo 5x5.
class MatrizRiesgoScreen extends StatelessWidget {
  const MatrizRiesgoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matriz de Riesgo 5x5')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _DescripcionMatriz(),
          SizedBox(height: 16),
          _MatrizRiesgoTabla(),
          SizedBox(height: 16),
          _LeyendaRiesgo(),
        ],
      ),
    );
  }
}

/// Explica brevemente cómo se calcula el nivel de riesgo.
class _DescripcionMatriz extends StatelessWidget {
  const _DescripcionMatriz();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Probabilidad x Severidad',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'La matriz permite calcular el valor del riesgo multiplicando '
              'la probabilidad por la severidad. El color ayuda a identificar '
              'si el riesgo es bajo, medio o alto.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Construye la matriz 5x5 con valores calculados automáticamente.
class _MatrizRiesgoTabla extends StatelessWidget {
  const _MatrizRiesgoTabla();

  @override
  Widget build(BuildContext context) {
    final List<int> severidades = <int>[1, 2, 3, 4, 5];
    final List<int> probabilidades = <int>[5, 4, 3, 2, 1];

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const _CeldaCabecera(texto: 'P/S'),
            ...severidades.map((int severidad) {
              return _CeldaCabecera(texto: severidad.toString());
            }),
          ],
        ),
        ...probabilidades.map((int probabilidad) {
          return Row(
            children: <Widget>[
              _CeldaCabecera(texto: probabilidad.toString()),
              ...severidades.map((int severidad) {
                final int valor = probabilidad * severidad;

                return _CeldaRiesgo(
                  valor: valor,
                  color: _obtenerColorRiesgo(valor),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

/// Celda de encabezado para probabilidad y severidad.
class _CeldaCabecera extends StatelessWidget {
  const _CeldaCabecera({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 52,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
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

/// Celda del resultado de riesgo.
class _CeldaRiesgo extends StatelessWidget {
  const _CeldaRiesgo({required this.valor, required this.color});

  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 52,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          valor.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Leyenda de colores de la matriz.
class _LeyendaRiesgo extends StatelessWidget {
  const _LeyendaRiesgo();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _ItemLeyenda(color: Colors.green, texto: 'Riesgo bajo: 1 a 5'),
            SizedBox(height: 8),
            _ItemLeyenda(color: Colors.orange, texto: 'Riesgo medio: 6 a 12'),
            SizedBox(height: 8),
            _ItemLeyenda(color: Colors.red, texto: 'Riesgo alto: 15 a 25'),
          ],
        ),
      ),
    );
  }
}

/// Item visual de la leyenda.
class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    );
  }
}

/// Define el color según el valor calculado del riesgo.
Color _obtenerColorRiesgo(int valor) {
  if (valor <= 5) {
    return Colors.green;
  }

  if (valor <= 12) {
    return Colors.orange;
  }

  return Colors.red;
}
