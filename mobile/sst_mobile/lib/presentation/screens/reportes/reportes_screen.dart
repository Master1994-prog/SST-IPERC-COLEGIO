import 'package:flutter/material.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();
  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();
  final SeguimientoIpercRepository _seguimientoRepository =
      SeguimientoIpercRepository();

  bool _cargando = true;
  String? _error;
  _ReporteResumen? _resumen;

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<MatrizIpercModel> matrices =
          await _matrizRepository.obtenerMatrices();

      final List<DetalleIpercModel> detalles = await _cargarDetalles(matrices);

      final List<SeguimientoIpercModel> seguimientos =
          await _seguimientoRepository.obtenerTodos();

      if (!mounted) return;

      setState(() {
        _resumen = _ReporteResumen(
          matrices: matrices,
          detalles: detalles,
          seguimientos: seguimientos,
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<List<DetalleIpercModel>> _cargarDetalles(
    List<MatrizIpercModel> matrices,
  ) async {
    if (matrices.isEmpty) {
      return <DetalleIpercModel>[];
    }

    final List<List<DetalleIpercModel>> resultados = await Future.wait(
      matrices
          .where((MatrizIpercModel matriz) => matriz.id > 0)
          .map(
            (MatrizIpercModel matriz) =>
                _detalleRepository.obtenerPorMatriz(matriz.id),
          ),
    );

    return resultados.expand((List<DetalleIpercModel> item) => item).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarReporte,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarReporte,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _error!.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _EmptyReportCard(
            icono: Icons.error_outline,
            titulo: 'No se pudo cargar el reporte',
            descripcion: _error!,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _cargarReporte,
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar nuevamente'),
          ),
        ],
      );
    }

    final _ReporteResumen resumen = _resumen ?? _ReporteResumen.vacio();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Resumen general',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _IndicadoresGrid(resumen: resumen),
        const SizedBox(height: 20),
        _SeccionReporte(
          titulo: 'Estado IPERC',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.assignment_outlined,
              titulo: 'Matrices activas',
              valor: resumen.matricesActivas.toString(),
              descripcion: 'Matrices disponibles para evaluación.',
            ),
            _ReporteFila(
              icono: Icons.list_alt_outlined,
              titulo: 'Filas IPERC registradas',
              valor: resumen.totalDetalles.toString(),
              descripcion: 'Tareas evaluadas dentro de las matrices.',
            ),
            _ReporteFila(
              icono: Icons.warning_amber_outlined,
              titulo: 'Sin evaluación residual',
              valor: resumen.detallesSinResidual.toString(),
              descripcion: 'Filas pendientes de revisar después del control.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionReporte(
          titulo: 'Controles y EPP',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.fact_check_outlined,
              titulo: 'Con controles asignados',
              valor: resumen.detallesConControles.toString(),
              descripcion: 'Filas que ya tienen medidas de control.',
            ),
            _ReporteFila(
              icono: Icons.health_and_safety_outlined,
              titulo: 'Con EPP asignado',
              valor: resumen.detallesConEpp.toString(),
              descripcion: 'Filas que ya tienen equipos de protección.',
            ),
            _ReporteFila(
              icono: Icons.rule_outlined,
              titulo: 'Sin controles ni EPP',
              valor: resumen.detallesSinControlesNiEpp.toString(),
              descripcion: 'Filas que requieren completar medidas.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionReporte(
          titulo: 'Seguimientos',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.timeline_outlined,
              titulo: 'Seguimientos registrados',
              valor: resumen.totalSeguimientos.toString(),
              descripcion: 'Avances registrados sobre los detalles IPERC.',
            ),
            _ReporteFila(
              icono: Icons.pending_actions_outlined,
              titulo: 'Pendientes',
              valor: resumen.seguimientosPendientes.toString(),
              descripcion: 'Seguimientos que aún no están verificados.',
            ),
            _ReporteFila(
              icono: Icons.verified_outlined,
              titulo: 'Verificados',
              valor: resumen.seguimientosVerificados.toString(),
              descripcion: 'Seguimientos revisados y confirmados.',
            ),
          ],
        ),
      ],
    );
  }
}

class _IndicadoresGrid extends StatelessWidget {
  const _IndicadoresGrid({required this.resumen});

  final _ReporteResumen resumen;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: <Widget>[
        _IndicadorCard(
          titulo: 'Matrices',
          valor: resumen.totalMatrices.toString(),
          icono: Icons.assignment,
        ),
        _IndicadorCard(
          titulo: 'Detalles',
          valor: resumen.totalDetalles.toString(),
          icono: Icons.list_alt,
        ),
        _IndicadorCard(
          titulo: 'Pendientes',
          valor: resumen.seguimientosPendientes.toString(),
          icono: Icons.pending_actions,
        ),
        _IndicadorCard(
          titulo: 'Avance',
          valor: '${resumen.porcentajeVerificado.toStringAsFixed(0)}%',
          icono: Icons.verified,
        ),
      ],
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}

class _SeccionReporte extends StatelessWidget {
  const _SeccionReporte({
    required this.titulo,
    required this.children,
  });

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index < children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReporteFila extends StatelessWidget {
  const _ReporteFila({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icono)),
      title: Text(titulo),
      subtitle: Text(descripcion),
      trailing: Text(
        valor,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(icono, size: 42),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(descripcion, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReporteResumen {
  const _ReporteResumen({
    required this.matrices,
    required this.detalles,
    required this.seguimientos,
  });

  factory _ReporteResumen.vacio() {
    return const _ReporteResumen(
      matrices: <MatrizIpercModel>[],
      detalles: <DetalleIpercModel>[],
      seguimientos: <SeguimientoIpercModel>[],
    );
  }

  final List<MatrizIpercModel> matrices;
  final List<DetalleIpercModel> detalles;
  final List<SeguimientoIpercModel> seguimientos;

  int get totalMatrices => matrices.length;

  int get matricesActivas {
    return matrices.where((MatrizIpercModel matriz) => matriz.activo).length;
  }

  int get totalDetalles => detalles.length;

  int get detallesConControles {
    return detalles.where((DetalleIpercModel detalle) {
      return detalle.tieneControles;
    }).length;
  }

  int get detallesConEpp {
    return detalles.where((DetalleIpercModel detalle) {
      return detalle.tieneEquiposProteccion;
    }).length;
  }

  int get detallesSinResidual {
    return detalles.where((DetalleIpercModel detalle) {
      return !detalle.tieneEvaluacionResidual;
    }).length;
  }

  int get detallesSinControlesNiEpp {
    return detalles.where((DetalleIpercModel detalle) {
      return !detalle.tieneControles && !detalle.tieneEquiposProteccion;
    }).length;
  }

  int get totalSeguimientos => seguimientos.length;

  int get seguimientosVerificados {
    return seguimientos.where((SeguimientoIpercModel seguimiento) {
      return seguimiento.verificado;
    }).length;
  }

  int get seguimientosPendientes {
    return totalSeguimientos - seguimientosVerificados;
  }

  double get porcentajeVerificado {
    if (totalSeguimientos == 0) {
      return 0;
    }

    return (seguimientosVerificados * 100) / totalSeguimientos;
  }
}