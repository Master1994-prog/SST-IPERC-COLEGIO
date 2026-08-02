import 'package:flutter/material.dart';

import '../../../core/services/reporte_iperc_pdf_service.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';

/// Pantalla de reportes básicos del sistema IPERC/SST.
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
  final ReporteIpercPdfService _pdfService = const ReporteIpercPdfService();

  bool _cargando = true;
  bool _exportandoPdf = false;
  String? _error;
  _ReporteResumen? _resumen;
  int? _matrizSeleccionadaId;
  String _nivelSeleccionado = 'Todos';

  static const List<String> _nivelesDisponibles = <String>[
    'Todos',
    'Bajo',
    'Medio',
    'Alto',
    'Crítico',
    'Sin nivel',
  ];

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
      final List<MatrizIpercModel> matrices = await _matrizRepository
          .obtenerMatrices();
      final List<DetalleIpercModel> detalles = await _cargarDetalles(matrices);
      final List<SeguimientoIpercModel> seguimientos =
          await _seguimientoRepository.obtenerTodos();

      if (!mounted) {
        return;
      }

      setState(() {
        _resumen = _ReporteResumen(
          matrices: matrices,
          detalles: detalles,
          seguimientos: seguimientos,
        );
        if (_matrizSeleccionadaId != null &&
            !matrices.any(
              (MatrizIpercModel matriz) => matriz.id == _matrizSeleccionadaId,
            )) {
          _matrizSeleccionadaId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  Future<void> _exportarPdf() async {
    final _ReporteResumen resumen = _resumen ?? _ReporteResumen.vacio();
    final List<DetalleIpercModel> detalles = _obtenerDetallesFiltrados(resumen);

    if (detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay evaluaciones para exportar con estos filtros.'),
        ),
      );
      return;
    }

    setState(() => _exportandoPdf = true);
    try {
      await _pdfService.exportar(
        matrices: resumen.matrices,
        detalles: detalles,
        filtroMatriz: _nombreFiltroMatriz(resumen.matrices),
        filtroNivel: _nivelSeleccionado,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportandoPdf = false);
      }
    }
  }

  String _nombreFiltroMatriz(List<MatrizIpercModel> matrices) {
    if (_matrizSeleccionadaId == null) {
      return 'Todas las matrices';
    }
    for (final MatrizIpercModel matriz in matrices) {
      if (matriz.id == _matrizSeleccionadaId) {
        return '${matriz.codigo} - ${matriz.nombre}';
      }
    }
    return 'Matriz $_matrizSeleccionadaId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Exportar reporte a PDF',
            onPressed: _cargando || _exportandoPdf ? null : _exportarPdf,
            icon: _exportandoPdf
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
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
    final List<DetalleIpercModel> detallesFiltrados = _obtenerDetallesFiltrados(
      resumen,
    );
    final _ReporteResumen resumenFiltrado = _crearResumenFiltrado(
      resumen,
      detallesFiltrados,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _FiltrosReporte(
          matrices: resumen.matrices,
          matrizSeleccionadaId: _matrizSeleccionadaId,
          nivelSeleccionado: _nivelSeleccionado,
          niveles: _nivelesDisponibles,
          onMatrizChanged: (int? valor) {
            setState(() {
              _matrizSeleccionadaId = valor;
            });
          },
          onNivelChanged: (String? valor) {
            setState(() {
              _nivelSeleccionado = valor ?? 'Todos';
            });
          },
          onLimpiar: () {
            setState(() {
              _matrizSeleccionadaId = null;
              _nivelSeleccionado = 'Todos';
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Resumen general',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _IndicadoresGrid(resumen: resumenFiltrado),
        const SizedBox(height: 20),
        _SeccionReporte(
          titulo: 'Niveles de riesgo inicial',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.check_circle_outline,
              titulo: 'Riesgo bajo',
              valor: resumenFiltrado.riesgosInicialesBajos.toString(),
              descripcion: 'Evaluaciones iniciales de nivel bajo.',
            ),
            _ReporteFila(
              icono: Icons.warning_amber_outlined,
              titulo: 'Riesgo medio',
              valor: resumenFiltrado.riesgosInicialesMedios.toString(),
              descripcion: 'Evaluaciones iniciales de nivel medio.',
            ),
            _ReporteFila(
              icono: Icons.error_outline,
              titulo: 'Riesgo alto',
              valor: resumenFiltrado.riesgosInicialesAltos.toString(),
              descripcion: 'Evaluaciones iniciales de nivel alto.',
            ),
            _ReporteFila(
              icono: Icons.dangerous_outlined,
              titulo: 'Riesgo crítico',
              valor: resumenFiltrado.riesgosInicialesCriticos.toString(),
              descripcion: 'Evaluaciones iniciales de nivel crítico.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionReporte(
          titulo: 'Resultado después de controles',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.health_and_safety_outlined,
              titulo: 'Riesgos residuales aceptables',
              valor: resumenFiltrado.residualesAceptables.toString(),
              descripcion: 'Evaluaciones residuales marcadas como aceptables.',
            ),
            _ReporteFila(
              icono: Icons.report_problem_outlined,
              titulo: 'Riesgos residuales no aceptables',
              valor: resumenFiltrado.residualesNoAceptables.toString(),
              descripcion: 'Evaluaciones que todavía requieren acción.',
            ),
            _ReporteFila(
              icono: Icons.pending_actions_outlined,
              titulo: 'Pendientes de evaluación residual',
              valor: resumenFiltrado.detallesSinResidual.toString(),
              descripcion: 'Filas aún no reevaluadas después del control.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SeccionReporte(
          titulo: 'Estado IPERC',
          children: <Widget>[
            _ReporteFila(
              icono: Icons.assignment_outlined,
              titulo: 'Matrices activas',
              valor: resumenFiltrado.matricesActivas.toString(),
              descripcion: 'Matrices disponibles para evaluación.',
            ),
            _ReporteFila(
              icono: Icons.list_alt_outlined,
              titulo: 'Filas IPERC registradas',
              valor: resumenFiltrado.totalDetalles.toString(),
              descripcion: 'Tareas evaluadas dentro de las matrices.',
            ),
            _ReporteFila(
              icono: Icons.warning_amber_outlined,
              titulo: 'Sin evaluación residual',
              valor: resumenFiltrado.detallesSinResidual.toString(),
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
              valor: resumenFiltrado.detallesConControles.toString(),
              descripcion: 'Filas que ya tienen medidas de control.',
            ),
            _ReporteFila(
              icono: Icons.health_and_safety_outlined,
              titulo: 'Con EPP asignado',
              valor: resumenFiltrado.detallesConEpp.toString(),
              descripcion: 'Filas que ya tienen equipos de protección.',
            ),
            _ReporteFila(
              icono: Icons.rule_outlined,
              titulo: 'Sin controles ni EPP',
              valor: resumenFiltrado.detallesSinControlesNiEpp.toString(),
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
              valor: resumenFiltrado.totalSeguimientos.toString(),
              descripcion: 'Avances registrados sobre los detalles IPERC.',
            ),
            _ReporteFila(
              icono: Icons.pending_actions_outlined,
              titulo: 'Pendientes',
              valor: resumenFiltrado.seguimientosPendientes.toString(),
              descripcion: 'Seguimientos que aún no están verificados.',
            ),
            _ReporteFila(
              icono: Icons.verified_outlined,
              titulo: 'Verificados',
              valor: resumenFiltrado.seguimientosVerificados.toString(),
              descripcion: 'Seguimientos revisados y confirmados.',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Evaluaciones IPERC',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('${detallesFiltrados.length} resultado(s) según los filtros.'),
        const SizedBox(height: 10),
        if (detallesFiltrados.isEmpty)
          const _EmptyReportCard(
            icono: Icons.search_off,
            titulo: 'Sin evaluaciones',
            descripcion:
                'No existen evaluaciones que coincidan con los filtros.',
          )
        else
          ...detallesFiltrados.map(
            (DetalleIpercModel detalle) => _EvaluacionReporteCard(
              detalle: detalle,
              matriz: resumen.matrizDeDetalle(detalle),
            ),
          ),
      ],
    );
  }

  List<DetalleIpercModel> _obtenerDetallesFiltrados(_ReporteResumen resumen) {
    final List<DetalleIpercModel> resultado = resumen.detalles.where((
      DetalleIpercModel detalle,
    ) {
      final bool coincideMatriz =
          _matrizSeleccionadaId == null ||
          detalle.matrizIpercId == _matrizSeleccionadaId;
      final String nivel = _clasificarNivel(
        detalle.evaluacionInicial?.nivelRiesgoNombre,
      );
      final bool coincideNivel =
          _nivelSeleccionado == 'Todos' || nivel == _nivelSeleccionado;

      return coincideMatriz && coincideNivel;
    }).toList();

    resultado.sort((DetalleIpercModel a, DetalleIpercModel b) {
      final int porMatriz = a.matrizIpercId.compareTo(b.matrizIpercId);
      return porMatriz != 0 ? porMatriz : a.item.compareTo(b.item);
    });

    return resultado;
  }

  _ReporteResumen _crearResumenFiltrado(
    _ReporteResumen resumen,
    List<DetalleIpercModel> detallesFiltrados,
  ) {
    final Set<int> detalleIds = detallesFiltrados
        .map((DetalleIpercModel detalle) => detalle.id)
        .toSet();

    final List<MatrizIpercModel> matricesFiltradas =
        _matrizSeleccionadaId == null
        ? resumen.matrices
        : resumen.matrices.where((MatrizIpercModel matriz) {
            return matriz.id == _matrizSeleccionadaId;
          }).toList();

    final List<SeguimientoIpercModel> seguimientosFiltrados = resumen
        .seguimientos
        .where((SeguimientoIpercModel seguimiento) {
          return detalleIds.contains(seguimiento.detalleIpercId);
        })
        .toList();

    return _ReporteResumen(
      matrices: matricesFiltradas,
      detalles: detallesFiltrados,
      seguimientos: seguimientosFiltrados,
    );
  }
}

class _FiltrosReporte extends StatelessWidget {
  const _FiltrosReporte({
    required this.matrices,
    required this.matrizSeleccionadaId,
    required this.nivelSeleccionado,
    required this.niveles,
    required this.onMatrizChanged,
    required this.onNivelChanged,
    required this.onLimpiar,
  });

  final List<MatrizIpercModel> matrices;
  final int? matrizSeleccionadaId;
  final String nivelSeleccionado;
  final List<String> niveles;
  final ValueChanged<int?> onMatrizChanged;
  final ValueChanged<String?> onNivelChanged;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Filtros del reporte',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey<String>(
                'matriz-${matrizSeleccionadaId ?? 'todas'}',
              ),
              initialValue: matrizSeleccionadaId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Matriz IPERC',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Todas las matrices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...matrices.map(
                  (MatrizIpercModel matriz) => DropdownMenuItem<int?>(
                    value: matriz.id,
                    child: Text(
                      '${matriz.codigo} - ${matriz.nombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              selectedItemBuilder: (BuildContext context) {
                final List<String> textos = <String>[
                  'Todas las matrices',
                  ...matrices.map(
                    (MatrizIpercModel matriz) =>
                        '${matriz.codigo} - ${matriz.nombre}',
                  ),
                ];

                return textos
                    .map(
                      (String texto) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: onMatrizChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('nivel-$nivelSeleccionado'),
              initialValue: nivelSeleccionado,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nivel de riesgo inicial',
                prefixIcon: Icon(Icons.warning_amber_outlined),
                border: OutlineInputBorder(),
              ),
              items: niveles
                  .map(
                    (String nivel) => DropdownMenuItem<String>(
                      value: nivel,
                      child: Text(
                        nivel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (BuildContext context) {
                return niveles
                    .map(
                      (String nivel) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nivel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: onNivelChanged,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLimpiar,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluacionReporteCard extends StatelessWidget {
  const _EvaluacionReporteCard({required this.detalle, required this.matriz});

  final DetalleIpercModel detalle;
  final MatrizIpercModel? matriz;

  @override
  Widget build(BuildContext context) {
    final EvaluacionDetalleIpercModel? inicial = detalle.evaluacionInicial;
    final EvaluacionDetalleIpercModel? residual = detalle.evaluacionResidual;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _colorDesdeHex(
            inicial?.color,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            detalle.item.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          detalle.peligroVisible,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${matriz?.codigo ?? detalle.matrizIpercCodigo ?? 'Matriz'}'
          ' · ${detalle.tarea}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          const Divider(),
          _DatoDetalle(
            etiqueta: 'Matriz',
            valor: matriz == null
                ? detalle.matrizIpercCodigo ?? 'ID ${detalle.matrizIpercId}'
                : '${matriz!.codigo} - ${matriz!.nombre}',
          ),
          _DatoDetalle(etiqueta: 'Tarea', valor: detalle.tarea),
          _DatoDetalle(
            etiqueta: 'Consecuencia',
            valor: detalle.consecuenciaVisible,
          ),
          _EvaluacionBloque(titulo: 'Evaluación inicial', evaluacion: inicial),
          _EvaluacionBloque(
            titulo: 'Evaluación residual',
            evaluacion: residual,
          ),
          _DatoDetalle(
            etiqueta: 'Controles',
            valor: detalle.tieneControles
                ? '${detalle.controlIds.length} asignado(s)'
                : 'Sin controles asignados',
          ),
          _DatoDetalle(
            etiqueta: 'EPP',
            valor: detalle.tieneEquiposProteccion
                ? '${detalle.equipoProteccionIds.length} asignado(s)'
                : 'Sin EPP asignado',
          ),
          _DatoDetalle(
            etiqueta: 'Estado',
            valor: detalle.estadoImplementacionNombre,
          ),
        ],
      ),
    );
  }
}

class _EvaluacionBloque extends StatelessWidget {
  const _EvaluacionBloque({required this.titulo, required this.evaluacion});

  final String titulo;
  final EvaluacionDetalleIpercModel? evaluacion;

  @override
  Widget build(BuildContext context) {
    if (evaluacion == null) {
      return _DatoDetalle(etiqueta: titulo, valor: 'Pendiente');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorDesdeHex(
          evaluacion!.color,
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorDesdeHex(
            evaluacion!.color,
            Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${evaluacion!.probabilidadNombre} '
            '(${evaluacion!.valorProbabilidad}) × '
            '${evaluacion!.severidadNombre} '
            '(${evaluacion!.valorSeveridad})',
          ),
          Text(
            '${evaluacion!.nivelRiesgoNombre} '
            '· Valor ${evaluacion!.valorRiesgo}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            evaluacion!.esAceptable
                ? 'Riesgo aceptable'
                : 'Riesgo no aceptable',
          ),
          if ((evaluacion!.observaciones ?? '').trim().isNotEmpty)
            Text('Observación: ${evaluacion!.observaciones!.trim()}'),
        ],
      ),
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}

class _SeccionReporte extends StatelessWidget {
  const _SeccionReporte({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  MatrizIpercModel? matrizDeDetalle(DetalleIpercModel detalle) {
    for (final MatrizIpercModel matriz in matrices) {
      if (matriz.id == detalle.matrizIpercId) {
        return matriz;
      }
    }

    return null;
  }

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

  int _cantidadInicialPorNivel(String nivel) {
    return detalles.where((DetalleIpercModel detalle) {
      return _clasificarNivel(detalle.evaluacionInicial?.nivelRiesgoNombre) ==
          nivel;
    }).length;
  }

  int get riesgosInicialesBajos => _cantidadInicialPorNivel('Bajo');
  int get riesgosInicialesMedios => _cantidadInicialPorNivel('Medio');
  int get riesgosInicialesAltos => _cantidadInicialPorNivel('Alto');
  int get riesgosInicialesCriticos => _cantidadInicialPorNivel('Crítico');

  int get residualesAceptables {
    return detalles.where((DetalleIpercModel detalle) {
      return detalle.evaluacionResidual?.esAceptable == true;
    }).length;
  }

  int get residualesNoAceptables {
    return detalles.where((DetalleIpercModel detalle) {
      final EvaluacionDetalleIpercModel? residual = detalle.evaluacionResidual;
      return residual != null && !residual.esAceptable;
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

String _clasificarNivel(String? nombre) {
  final String texto = nombre?.trim().toLowerCase() ?? '';

  if (texto.isEmpty || texto == 'sin nivel') {
    return 'Sin nivel';
  }

  if (texto.contains('crít') ||
      texto.contains('crit') ||
      texto.contains('intolerable')) {
    return 'Crítico';
  }

  if (texto.contains('alto') ||
      texto.contains('importante') ||
      texto.contains('significativo')) {
    return 'Alto';
  }

  if (texto.contains('medio') ||
      texto.contains('moderado') ||
      texto.contains('tolerable')) {
    return 'Medio';
  }

  if (texto.contains('bajo') || texto.contains('trivial')) {
    return 'Bajo';
  }

  return 'Sin nivel';
}

Color _colorDesdeHex(String? valor, Color predeterminado) {
  String texto = valor?.trim().replaceFirst('#', '') ?? '';

  if (texto.length == 6) {
    texto = 'FF$texto';
  }

  if (texto.length != 8) {
    return predeterminado;
  }

  final int? color = int.tryParse(texto, radix: 16);
  return color == null ? predeterminado : Color(color);
}
