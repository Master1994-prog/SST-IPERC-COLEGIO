import 'package:flutter/material.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// Mapa dinámico de riesgos agrupado por las áreas de las matrices IPERC.
class MapasRiesgoScreen extends StatefulWidget {
  const MapasRiesgoScreen({super.key});

  @override
  State<MapasRiesgoScreen> createState() => _MapasRiesgoScreenState();
}

class _MapasRiesgoScreenState extends State<MapasRiesgoScreen> {
  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();
  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  bool _cargando = true;
  String? _error;
  int? _matrizSeleccionadaId;
  List<MatrizIpercModel> _matrices = <MatrizIpercModel>[];
  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<MatrizIpercModel> matrices = await _matrizRepository
          .obtenerMatrices();
      final List<List<DetalleIpercModel>> resultados = await Future.wait(
        matrices
            .where((MatrizIpercModel matriz) => matriz.id > 0)
            .map(
              (MatrizIpercModel matriz) =>
                  _detalleRepository.obtenerPorMatriz(matriz.id),
            ),
      );

      if (!mounted) return;
      setState(() {
        _matrices = matrices;
        _detalles = resultados.expand((lista) => lista).toList();
        if (_matrizSeleccionadaId != null &&
            !matrices.any((matriz) => matriz.id == _matrizSeleccionadaId)) {
          _matrizSeleccionadaId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<_ZonaRiesgo> get _zonas {
    final Iterable<MatrizIpercModel> matrices = _matrizSeleccionadaId == null
        ? _matrices
        : _matrices.where((matriz) => matriz.id == _matrizSeleccionadaId);

    return matrices.map((MatrizIpercModel matriz) {
      final List<DetalleIpercModel> detalles = _detalles
          .where((detalle) => detalle.matrizIpercId == matriz.id)
          .toList();
      return _ZonaRiesgo(matriz: matriz, detalles: detalles);
    }).toList()..sort((a, b) => b.valorMayor.compareTo(a.valorMayor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapas de riesgo'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _cargar, child: _contenido()),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar nuevamente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final List<_ZonaRiesgo> zonas = _zonas;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DropdownButtonFormField<int?>(
          key: ValueKey<int?>(_matrizSeleccionadaId),
          initialValue: _matrizSeleccionadaId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Matriz IPERC',
            prefixIcon: Icon(Icons.assignment_outlined),
            border: OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las matrices'),
            ),
            ..._matrices.map(
              (matriz) => DropdownMenuItem<int?>(
                value: matriz.id,
                child: Text(
                  '${matriz.codigo} - ${matriz.nombre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (int? valor) {
            setState(() => _matrizSeleccionadaId = valor);
          },
        ),
        const SizedBox(height: 16),
        const _LeyendaRiesgo(),
        const SizedBox(height: 16),
        Text(
          '${zonas.length} zona${zonas.length == 1 ? '' : 's'} identificada${zonas.length == 1 ? '' : 's'}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (zonas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No existen matrices para construir el mapa de riesgos.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...zonas.map((zona) => _ZonaRiesgoCard(zona: zona)),
      ],
    );
  }
}

class _ZonaRiesgo {
  const _ZonaRiesgo({required this.matriz, required this.detalles});

  final MatrizIpercModel matriz;
  final List<DetalleIpercModel> detalles;

  Iterable<EvaluacionDetalleIpercModel> get evaluaciones => detalles
      .map((detalle) => detalle.evaluacionResidual ?? detalle.evaluacionInicial)
      .whereType<EvaluacionDetalleIpercModel>();

  int get valorMayor => evaluaciones.fold<int>(
    0,
    (mayor, evaluacion) =>
        evaluacion.valorRiesgo > mayor ? evaluacion.valorRiesgo : mayor,
  );

  String get nivelMayor {
    if (evaluaciones.isEmpty) return 'Sin evaluar';
    return evaluaciones
        .reduce((a, b) => a.valorRiesgo >= b.valorRiesgo ? a : b)
        .nivelRiesgoNombre;
  }

  Color get color => _colorRiesgo(
    evaluaciones.isEmpty
        ? '#9E9E9E'
        : evaluaciones
              .reduce((a, b) => a.valorRiesgo >= b.valorRiesgo ? a : b)
              .color,
  );
}

class _ZonaRiesgoCard extends StatelessWidget {
  const _ZonaRiesgoCard({required this.zona});

  final _ZonaRiesgo zona;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: zona.color,
          foregroundColor: Colors.white,
          child: const Icon(Icons.location_on),
        ),
        title: Text(
          zona.matriz.areaVisible,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${zona.matriz.codigo} · ${zona.detalles.length} riesgo(s) · ${zona.nivelMayor}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: zona.detalles.isEmpty
            ? const <Widget>[
                ListTile(
                  title: Text('Esta zona todavía no tiene evaluaciones.'),
                ),
              ]
            : zona.detalles.map((detalle) {
                final EvaluacionDetalleIpercModel? evaluacion =
                    detalle.evaluacionResidual ?? detalle.evaluacionInicial;
                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _colorRiesgo(evaluacion?.color ?? '#9E9E9E'),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: Text(detalle.peligroVisible),
                  subtitle: Text(
                    '${detalle.tarea}\n${detalle.consecuenciaVisible}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    evaluacion == null
                        ? 'S/E'
                        : '${evaluacion.valorRiesgo}\n${evaluacion.nivelRiesgoNombre}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  isThreeLine: true,
                );
              }).toList(),
      ),
    );
  }
}

class _LeyendaRiesgo extends StatelessWidget {
  const _LeyendaRiesgo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const <Widget>[
        _LeyendaItem(texto: 'Bajo', color: Colors.green),
        _LeyendaItem(texto: 'Medio', color: Colors.amber),
        _LeyendaItem(texto: 'Alto', color: Colors.orange),
        _LeyendaItem(texto: 'Crítico', color: Colors.red),
        _LeyendaItem(texto: 'Sin evaluar', color: Colors.grey),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  const _LeyendaItem({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 7),
      label: Text(texto),
      visualDensity: VisualDensity.compact,
    );
  }
}

Color _colorRiesgo(String hexadecimal) {
  final String limpio = hexadecimal.replaceAll('#', '').trim();
  final String completo = limpio.length == 6 ? 'FF$limpio' : limpio;
  return Color(int.tryParse(completo, radix: 16) ?? 0xFF9E9E9E);
}
