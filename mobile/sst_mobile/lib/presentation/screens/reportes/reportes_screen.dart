import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/evaluacion_riesgo_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';
import '../../../data/services/reporte_export_service.dart';

import '../controles/controles_screen.dart';
import '../iperc/matrices_iperc_screen.dart';
import '../mapas_riesgo/mapas_riesgo_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../seguimientos/seguimientos_screen.dart';

/// ===============================================================
/// PANTALLA PRINCIPAL - REPORTES SST/IPERC
/// ===============================================================
///
/// Centraliza los reportes disponibles del sistema.
///
/// Reportes:
///
/// 1. Matrices IPERC
/// 2. Evaluación de riesgos
/// 3. Controles SST
/// 4. Seguimientos IPERC
/// 5. Mapas de riesgo
///
/// Todos permiten:
///
/// - Ver información.
/// - Exportar PDF.
/// - Exportar Excel.
/// ===============================================================
class ReportesScreen extends StatelessWidget {
  ReportesScreen({required this.rol, super.key});

  final String rol;

  // =============================================================
  // REPOSITORIOS
  // =============================================================

  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  final ControlRepository _controlRepository = ControlRepository();

  final SeguimientoIpercRepository _seguimientoRepository =
      SeguimientoIpercRepository();

  final EvaluacionRiesgoRepository _evaluacionRepository =
      EvaluacionRiesgoRepository();

  // =============================================================
  // SERVICIO DE EXPORTACIÓN
  // =============================================================

  final ReporteExportService _reporteExportService = ReporteExportService();

  // =============================================================
  // MATRICES IPERC - PDF
  // =============================================================

  Future<void> _exportarMatricesPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando PDF de matrices IPERC...');

      final List<MatrizIpercModel> matrices = await _matrizRepository
          .obtenerMatrices();

      if (matrices.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay matrices IPERC para exportar.');

        return;
      }

      final Uint8List bytes = await _reporteExportService.generarPdfMatrices(
        matrices,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_matrices_iperc.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(context, 'No se pudo generar el PDF de matrices', error);
    }
  }

  // =============================================================
  // MATRICES IPERC - EXCEL
  // =============================================================

  Future<void> _exportarMatricesExcel(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando Excel de matrices IPERC...');

      final List<MatrizIpercModel> matrices = await _matrizRepository
          .obtenerMatrices();

      if (matrices.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay matrices IPERC para exportar.');

        return;
      }

      final Uint8List bytes = _reporteExportService.generarExcelMatrices(
        matrices,
      );

      await _compartirExcel(
        bytes: bytes,
        nombreArchivo: 'reporte_matrices_iperc.xlsx',
        titulo: 'Reporte de matrices IPERC',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(context, 'No se pudo generar el Excel de matrices', error);
    }
  }

  // =============================================================
  // EVALUACIÓN DE RIESGOS - PDF
  // =============================================================

  Future<void> _exportarEvaluacionPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando PDF de evaluación de riesgos...');

      final evaluaciones = await _evaluacionRepository.obtenerTodos();

      final Uint8List bytes = await _reporteExportService
          .generarPdfEvaluacionRiesgos(evaluaciones);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_evaluacion_riesgos.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el PDF de evaluación de riesgos',
        error,
      );
    }
  }

  // =============================================================
  // EVALUACIÓN DE RIESGOS - EXCEL
  // =============================================================

  Future<void> _exportarEvaluacionExcel(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(
        messenger,
        'Generando Excel de evaluación de riesgos...',
      );

      final evaluaciones = await _evaluacionRepository.obtenerTodos();

      final Uint8List bytes = _reporteExportService
          .generarExcelEvaluacionRiesgos(evaluaciones);

      await _compartirExcel(
        bytes: bytes,
        nombreArchivo: 'reporte_evaluacion_riesgos.xlsx',
        titulo: 'Reporte de evaluación de riesgos IPERC',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el Excel de evaluación de riesgos',
        error,
      );
    }
  }

  // =============================================================
  // CONTROLES SST - PDF
  // =============================================================

  Future<void> _exportarControlesPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando PDF de controles SST...');

      final controles = await _controlRepository.obtenerTodos();

      if (controles.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay controles SST para exportar.');

        return;
      }

      final Uint8List bytes = await _reporteExportService.generarPdfControles(
        controles,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_controles_sst.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(context, 'No se pudo generar el PDF de controles', error);
    }
  }

  // =============================================================
  // CONTROLES SST - EXCEL
  // =============================================================

  Future<void> _exportarControlesExcel(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando Excel de controles SST...');

      final controles = await _controlRepository.obtenerTodos();

      if (controles.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay controles SST para exportar.');

        return;
      }

      final Uint8List bytes = _reporteExportService.generarExcelControles(
        controles,
      );

      await _compartirExcel(
        bytes: bytes,
        nombreArchivo: 'reporte_controles_sst.xlsx',
        titulo: 'Reporte de controles SST',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(context, 'No se pudo generar el Excel de controles', error);
    }
  }

  // =============================================================
  // SEGUIMIENTOS IPERC - PDF
  // =============================================================

  Future<void> _exportarSeguimientosPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando PDF de seguimientos IPERC...');

      final seguimientos = await _seguimientoRepository.obtenerTodos();

      if (seguimientos.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay seguimientos IPERC para exportar.');

        return;
      }

      final Uint8List bytes = await _reporteExportService
          .generarPdfSeguimientos(seguimientos);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_seguimientos_iperc.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el PDF de seguimientos',
        error,
      );
    }
  }

  // =============================================================
  // SEGUIMIENTOS IPERC - EXCEL
  // =============================================================

  Future<void> _exportarSeguimientosExcel(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando Excel de seguimientos IPERC...');

      final seguimientos = await _seguimientoRepository.obtenerTodos();

      if (seguimientos.isEmpty) {
        _mostrarSinDatos(messenger, 'No hay seguimientos IPERC para exportar.');

        return;
      }

      final Uint8List bytes = _reporteExportService.generarExcelSeguimientos(
        seguimientos,
      );

      await _compartirExcel(
        bytes: bytes,
        nombreArchivo: 'reporte_seguimientos_iperc.xlsx',
        titulo: 'Reporte de seguimientos IPERC',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el Excel de seguimientos',
        error,
      );
    }
  }

  // =============================================================
  // MAPAS DE RIESGO - CARGAR DATOS
  // =============================================================

  Future<_DatosMapaReporte> _cargarDatosMapa() async {
    final List<MatrizIpercModel> matrices = await _matrizRepository
        .obtenerMatrices();

    final List<DetalleIpercModel> detalles = await _detalleRepository
        .obtenerTodos();

    return _DatosMapaReporte(matrices: matrices, detalles: detalles);
  }

  // =============================================================
  // MAPAS DE RIESGO - PDF
  // =============================================================

  Future<void> _exportarMapasPdf(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando PDF del mapa de riesgos...');

      final _DatosMapaReporte datos = await _cargarDatosMapa();

      if (datos.matrices.isEmpty) {
        _mostrarSinDatos(
          messenger,
          'No hay matrices disponibles para generar el mapa de riesgos.',
        );

        return;
      }

      final Uint8List bytes = await _reporteExportService.generarPdfMapasRiesgo(
        matrices: datos.matrices,
        detalles: datos.detalles,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_mapa_riesgos.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el PDF del mapa de riesgos',
        error,
      );
    }
  }

  // =============================================================
  // MAPAS DE RIESGO - EXCEL
  // =============================================================

  Future<void> _exportarMapasExcel(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      _mostrarGenerando(messenger, 'Generando Excel del mapa de riesgos...');

      final _DatosMapaReporte datos = await _cargarDatosMapa();

      if (datos.matrices.isEmpty) {
        _mostrarSinDatos(
          messenger,
          'No hay matrices disponibles para generar el mapa de riesgos.',
        );

        return;
      }

      final Uint8List bytes = _reporteExportService.generarExcelMapasRiesgo(
        matrices: datos.matrices,
        detalles: datos.detalles,
      );

      await _compartirExcel(
        bytes: bytes,
        nombreArchivo: 'reporte_mapa_riesgos.xlsx',
        titulo: 'Reporte de mapas de riesgo SST/IPERC',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _mostrarError(
        context,
        'No se pudo generar el Excel del mapa de riesgos',
        error,
      );
    }
  }

  // =============================================================
  // COMPARTIR EXCEL
  // =============================================================

  Future<void> _compartirExcel({
    required Uint8List bytes,
    required String nombreArchivo,
    required String titulo,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        title: titulo,
        subject: titulo,
        text: '$titulo generado desde el sistema SST/IPERC.',
        files: <XFile>[
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.'
                'spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: <String>[nombreArchivo],
      ),
    );
  }

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _construirEncabezado(context),

          const SizedBox(height: 20),

          Text(
            'Reportes disponibles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // 1. MATRICES IPERC
          // =====================================================
          _ReporteExportacionCard(
            icono: Icons.assignment_outlined,
            titulo: 'Reporte de matrices IPERC',
            descripcion:
                'Consultar y exportar las matrices registradas, '
                'incluyendo institución, área, actividad, '
                'versión y estado actual.',
            textoVer: 'Ver matrices',
            onVer: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MatricesIpercScreen(rol: rol),
                ),
              );
            },
            onPdf: () {
              _exportarMatricesPdf(context);
            },
            onExcel: () {
              _exportarMatricesExcel(context);
            },
          ),

          const SizedBox(height: 12),

          // =====================================================
          // 2. EVALUACIÓN DE RIESGOS
          // =====================================================
          _ReporteExportacionCard(
            icono: Icons.grid_view_outlined,
            titulo: 'Reporte de evaluación de riesgos',
            descripcion:
                'Consultar y exportar la matriz 5×5, '
                'niveles de riesgo, resumen estadístico '
                'y evaluaciones registradas.',
            textoVer: 'Ver evaluación',
            onVer: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MatrizRiesgoScreen(),
                ),
              );
            },
            onPdf: () {
              _exportarEvaluacionPdf(context);
            },
            onExcel: () {
              _exportarEvaluacionExcel(context);
            },
          ),

          const SizedBox(height: 12),

          // =====================================================
          // 3. CONTROLES SST
          // =====================================================
          _ReporteExportacionCard(
            icono: Icons.health_and_safety_outlined,
            titulo: 'Reporte de controles SST',
            descripcion:
                'Consultar y exportar las medidas de control '
                'registradas para eliminar, reducir o '
                'controlar los riesgos.',
            textoVer: 'Ver controles',
            onVer: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ControlesScreen(rol: rol, soloLectura: true),
                ),
              );
            },
            onPdf: () {
              _exportarControlesPdf(context);
            },
            onExcel: () {
              _exportarControlesExcel(context);
            },
          ),

          const SizedBox(height: 12),

          // =====================================================
          // 4. SEGUIMIENTOS IPERC
          // =====================================================
          _ReporteExportacionCard(
            icono: Icons.fact_check_outlined,
            titulo: 'Reporte de seguimientos IPERC',
            descripcion:
                'Consultar y exportar responsables, fechas, '
                'porcentaje de avance, verificaciones '
                'y observaciones.',
            textoVer: 'Ver seguimientos',
            onVer: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SeguimientosScreen(rol: rol),
                ),
              );
            },
            onPdf: () {
              _exportarSeguimientosPdf(context);
            },
            onExcel: () {
              _exportarSeguimientosExcel(context);
            },
          ),

          const SizedBox(height: 12),

          // =====================================================
          // 5. MAPAS DE RIESGO
          // =====================================================
          _ReporteExportacionCard(
            icono: Icons.map_outlined,
            titulo: 'Reporte de mapas de riesgo',
            descripcion:
                'Consultar y exportar los riesgos identificados '
                'por área, incluyendo peligro, consecuencia, '
                'valor y nivel de riesgo.',
            textoVer: 'Ver mapas',
            onVer: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapasRiesgoScreen(),
                ),
              );
            },
            onPdf: () {
              _exportarMapasPdf(context);
            },
            onExcel: () {
              _exportarMapasExcel(context);
            },
          ),

          const SizedBox(height: 24),

          _construirAviso(),
        ],
      ),
    );
  }

  // =============================================================
  // ENCABEZADO
  // =============================================================

  Widget _construirEncabezado(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.bar_chart,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 16),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Centro de reportes SST/IPERC',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Consulta y exporta la información '
                    'registrada sobre matrices, riesgos, '
                    'controles, seguimientos y mapas '
                    'de riesgo.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // AVISO
  // =============================================================

  Widget _construirAviso() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: Colors.blue.shade700),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Todos los reportes principales SST/IPERC '
              'pueden consultarse y exportarse en PDF y Excel.',
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarGenerando(ScaffoldMessengerState messenger, String mensaje) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
      );
  }

  void _mostrarSinDatos(ScaffoldMessengerState messenger, String mensaje) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarError(BuildContext context, String titulo, Object error) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('$titulo: ${_mensajeError(error)}'),
        ),
      );
  }

  String _mensajeError(Object error) {
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

    if (mensaje.isEmpty) {
      return 'Ocurrió un error inesperado.';
    }

    return mensaje;
  }
}

// ===============================================================
// DATOS PARA REPORTE DE MAPA
// ===============================================================

class _DatosMapaReporte {
  const _DatosMapaReporte({required this.matrices, required this.detalles});

  final List<MatrizIpercModel> matrices;
  final List<DetalleIpercModel> detalles;
}

// ===============================================================
// TARJETA DE REPORTE
// ===============================================================

class _ReporteExportacionCard extends StatelessWidget {
  const _ReporteExportacionCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.textoVer,
    required this.onVer,
    required this.onPdf,
    required this.onExcel,
  });

  final IconData icono;

  final String titulo;

  final String descripcion;

  final String textoVer;

  final VoidCallback onVer;

  final VoidCallback onPdf;

  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(child: Icon(icono)),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(descripcion),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVer,
                icon: const Icon(Icons.visibility_outlined),
                label: Text(textoVer),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onExcel,
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
