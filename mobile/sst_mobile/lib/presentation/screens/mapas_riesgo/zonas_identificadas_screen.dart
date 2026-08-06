import 'package:flutter/material.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// Muestra un resumen de las zonas o áreas identificadas
/// mediante las matrices IPERC registradas.
class ZonasIdentificadasScreen extends StatefulWidget {
  const ZonasIdentificadasScreen({super.key});

  @override
  State<ZonasIdentificadasScreen> createState() {
    return _ZonasIdentificadasScreenState();
  }
}

class _ZonasIdentificadasScreenState extends State<ZonasIdentificadasScreen> {
  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  bool _cargando = true;
  String? _error;

  List<MatrizIpercModel> _matrices = <MatrizIpercModel>[];

  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];

  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_cargando && _matrices.isNotEmpty) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<MatrizIpercModel> matrices = await _matrizRepository
          .obtenerMatrices();

      final List<List<DetalleIpercModel>> resultados =
          await Future.wait<List<DetalleIpercModel>>(
            matrices.where((MatrizIpercModel matriz) => matriz.id > 0).map((
              MatrizIpercModel matriz,
            ) {
              return _detalleRepository.obtenerPorMatriz(matriz.id);
            }),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _matrices = matrices;
        _detalles = resultados
            .expand((List<DetalleIpercModel> lista) => lista)
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  List<_ZonaIdentificada> get _zonas {
    final Map<String, List<MatrizIpercModel>> matricesPorArea =
        <String, List<MatrizIpercModel>>{};

    for (final MatrizIpercModel matriz in _matrices) {
      final String area = matriz.areaVisible.trim();

      matricesPorArea
          .putIfAbsent(
            area.isEmpty ? 'Área no asignada' : area,
            () => <MatrizIpercModel>[],
          )
          .add(matriz);
    }

    final List<_ZonaIdentificada> zonas = matricesPorArea.entries.map((
      MapEntry<String, List<MatrizIpercModel>> entry,
    ) {
      final Set<int> idsMatrices = entry.value
          .map((MatrizIpercModel matriz) => matriz.id)
          .toSet();

      final List<DetalleIpercModel> detalles = _detalles.where((
        DetalleIpercModel detalle,
      ) {
        return idsMatrices.contains(detalle.matrizIpercId);
      }).toList();

      return _ZonaIdentificada(
        nombreArea: entry.key,
        matrices: entry.value,
        detalles: detalles,
      );
    }).toList();

    zonas.sort((_ZonaIdentificada primero, _ZonaIdentificada segundo) {
      return segundo.valorMayor.compareTo(primero.valorMayor);
    });

    final String criterio = _busqueda.trim().toLowerCase();

    if (criterio.isEmpty) {
      return zonas;
    }

    return zonas.where((_ZonaIdentificada zona) {
      return zona.nombreArea.toLowerCase().contains(criterio) ||
          zona.nivelMayor.toLowerCase().contains(criterio) ||
          zona.matrices.any((MatrizIpercModel matriz) {
            return matriz.codigo.toLowerCase().contains(criterio) ||
                matriz.nombre.toLowerCase().contains(criterio);
          });
    }).toList();
  }

  int get _totalZonas {
    final Set<String> areas = _matrices
        .map((MatrizIpercModel matriz) => matriz.areaVisible.trim())
        .where((String area) => area.isNotEmpty)
        .toSet();

    return areas.length;
  }

  int get _zonasCriticas {
    return _zonas.where((_ZonaIdentificada zona) => zona.esCritica).length;
  }

  int get _zonasSinEvaluar {
    return _zonas
        .where((_ZonaIdentificada zona) => zona.evaluaciones.isEmpty)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final List<_ZonaIdentificada> zonas = _zonas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas identificadas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _construirContenido(zonas),
      ),
    );
  }

  Widget _construirContenido(List<_ZonaIdentificada> zonas) {
    if (_cargando && _matrices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _matrices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.cloud_off_outlined,
            size: 70,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar las zonas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _construirResumen(),

        const SizedBox(height: 16),

        TextField(
          onChanged: (String value) {
            setState(() {
              _busqueda = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'Buscar zona',
            hintText: 'Área, matriz o nivel de riesgo',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 16),

        const _LeyendaZonas(),

        const SizedBox(height: 18),

        Text(
          '${zonas.length} '
          '${zonas.length == 1 ? 'zona encontrada' : 'zonas encontradas'}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (zonas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                children: <Widget>[
                  Icon(Icons.location_off_outlined, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'No existen zonas que coincidan con la búsqueda.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...zonas.map((_ZonaIdentificada zona) {
            return _ZonaIdentificadaCard(zona: zona);
          }),
      ],
    );
  }

  Widget _construirResumen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(child: const Icon(Icons.location_city_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resumen de zonas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: <Widget>[
                _ResumenZonaItem(
                  icono: Icons.apartment,
                  titulo: 'Total de zonas',
                  valor: _totalZonas.toString(),
                ),
                _ResumenZonaItem(
                  icono: Icons.warning_amber_outlined,
                  titulo: 'Zonas críticas',
                  valor: _zonasCriticas.toString(),
                ),
                _ResumenZonaItem(
                  icono: Icons.assignment_outlined,
                  titulo: 'Matrices',
                  valor: _matrices.length.toString(),
                ),
                _ResumenZonaItem(
                  icono: Icons.help_outline,
                  titulo: 'Sin evaluar',
                  valor: _zonasSinEvaluar.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerMensajeError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'DioException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}

class _ZonaIdentificada {
  const _ZonaIdentificada({
    required this.nombreArea,
    required this.matrices,
    required this.detalles,
  });

  final String nombreArea;
  final List<MatrizIpercModel> matrices;
  final List<DetalleIpercModel> detalles;

  Iterable<EvaluacionDetalleIpercModel> get evaluaciones {
    return detalles.map((DetalleIpercModel detalle) {
      return detalle.evaluacionResidual ?? detalle.evaluacionInicial;
    }).whereType<EvaluacionDetalleIpercModel>();
  }

  int get valorMayor {
    return evaluaciones.fold<int>(0, (
      int mayor,
      EvaluacionDetalleIpercModel evaluacion,
    ) {
      return evaluacion.valorRiesgo > mayor ? evaluacion.valorRiesgo : mayor;
    });
  }

  String get nivelMayor {
    if (evaluaciones.isEmpty) {
      return 'Sin evaluar';
    }

    return evaluaciones.reduce((
      EvaluacionDetalleIpercModel primero,
      EvaluacionDetalleIpercModel segundo,
    ) {
      return primero.valorRiesgo >= segundo.valorRiesgo ? primero : segundo;
    }).nivelRiesgoNombre;
  }

  String get colorMayor {
    if (evaluaciones.isEmpty) {
      return '#9E9E9E';
    }

    return evaluaciones.reduce((
      EvaluacionDetalleIpercModel primero,
      EvaluacionDetalleIpercModel segundo,
    ) {
      return primero.valorRiesgo >= segundo.valorRiesgo ? primero : segundo;
    }).color;
  }

  bool get esCritica {
    final String nivel = nivelMayor.toLowerCase();

    return nivel.contains('crítico') || nivel.contains('critico');
  }

  int get cantidadEvaluadas {
    return evaluaciones.length;
  }

  int get cantidadPendientes {
    return detalles.length - cantidadEvaluadas;
  }
}

class _ZonaIdentificadaCard extends StatelessWidget {
  const _ZonaIdentificadaCard({required this.zona});

  final _ZonaIdentificada zona;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(zona.colorMayor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: _colorTexto(color),
          child: const Icon(Icons.location_on),
        ),
        title: Text(
          zona.nombreArea,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${zona.matrices.length} '
          '${zona.matrices.length == 1 ? 'matriz' : 'matrices'} · '
          '${zona.detalles.length} '
          '${zona.detalles.length == 1 ? 'riesgo' : 'riesgos'} · '
          '${zona.nivelMayor}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            zona.valorMayor == 0 ? 'S/E' : zona.valorMayor.toString(),
            style: TextStyle(
              color: _colorTexto(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: <Widget>[
                _ZonaDatoFila(
                  etiqueta: 'Nivel más alto',
                  valor: zona.nivelMayor,
                ),
                _ZonaDatoFila(
                  etiqueta: 'Riesgos evaluados',
                  valor: zona.cantidadEvaluadas.toString(),
                ),
                _ZonaDatoFila(
                  etiqueta: 'Riesgos pendientes',
                  valor: zona.cantidadPendientes.toString(),
                ),
                _ZonaDatoFila(
                  etiqueta: 'Matrices',
                  valor: zona.matrices
                      .map((MatrizIpercModel matriz) {
                        return matriz.codigo;
                      })
                      .join(', '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenZonaItem extends StatelessWidget {
  const _ResumenZonaItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(child: Icon(icono)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZonaDatoFila extends StatelessWidget {
  const _ZonaDatoFila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 145,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor.isEmpty ? 'No registrado' : valor)),
        ],
      ),
    );
  }
}

class _LeyendaZonas extends StatelessWidget {
  const _LeyendaZonas();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _LeyendaZonaItem(texto: 'Bajo', color: Colors.green),
        _LeyendaZonaItem(texto: 'Medio', color: Colors.amber),
        _LeyendaZonaItem(texto: 'Alto', color: Colors.orange),
        _LeyendaZonaItem(texto: 'Crítico', color: Colors.red),
        _LeyendaZonaItem(texto: 'Sin evaluar', color: Colors.grey),
      ],
    );
  }
}

class _LeyendaZonaItem extends StatelessWidget {
  const _LeyendaZonaItem({required this.texto, required this.color});

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

Color _colorDesdeHex(String valor) {
  String hexadecimal = valor.trim().replaceFirst('#', '');

  if (hexadecimal.length == 6) {
    hexadecimal = 'FF$hexadecimal';
  }

  final int? numero = int.tryParse(hexadecimal, radix: 16);

  return numero == null ? const Color(0xFF9E9E9E) : Color(numero);
}

Color _colorTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
