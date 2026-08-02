import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/detalle_iperc_model.dart';
import '../../data/models/matriz_iperc_model.dart';

/// Genera y abre el diálogo del sistema para guardar o imprimir el reporte.
class ReporteIpercPdfService {
  const ReporteIpercPdfService();

  Future<void> exportar({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
    required String filtroMatriz,
    required String filtroNivel,
  }) async {
    final String fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final String nombre =
        'reporte_iperc_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      name: nombre,
      format: PdfPageFormat.a4.landscape,
      onLayout: (PdfPageFormat formato) {
        return _crearDocumento(
          formato: formato,
          matrices: matrices,
          detalles: detalles,
          filtroMatriz: filtroMatriz,
          filtroNivel: filtroNivel,
          fecha: fecha,
        );
      },
    );
  }

  Future<Uint8List> _crearDocumento({
    required PdfPageFormat formato,
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
    required String filtroMatriz,
    required String filtroNivel,
    required String fecha,
  }) async {
    final pw.Document documento = pw.Document(
      title: 'Reporte IPERC',
      author: 'Sistema SST/IPERC',
      creator: 'Aplicación móvil SST/IPERC',
    );

    final Map<int, MatrizIpercModel> matricesPorId = <int, MatrizIpercModel>{
      for (final MatrizIpercModel matriz in matrices) matriz.id: matriz,
    };

    documento.addPage(
      pw.MultiPage(
        pageFormat: formato,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) => _encabezado(fecha),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'REPORTE DE IDENTIFICACIÓN DE PELIGROS Y EVALUACIÓN DE RIESGOS',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _filtros(filtroMatriz, filtroNivel),
          pw.SizedBox(height: 10),
          _resumen(detalles),
          pw.SizedBox(height: 14),
          pw.Text(
            'Evaluaciones IPERC (${detalles.length})',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _tabla(detalles, matricesPorId),
        ],
      ),
    );

    return documento.save();
  }

  pw.Widget _encabezado(String fecha) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'SISTEMA DE SEGURIDAD Y SALUD EN EL TRABAJO',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Generado: $fecha', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _filtros(String matriz, String nivel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      color: PdfColors.grey200,
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(child: pw.Text('Matriz: $matriz')),
          pw.Expanded(child: pw.Text('Nivel inicial: $nivel')),
        ],
      ),
    );
  }

  pw.Widget _resumen(List<DetalleIpercModel> detalles) {
    int bajo = 0;
    int medio = 0;
    int alto = 0;
    int critico = 0;

    for (final DetalleIpercModel detalle in detalles) {
      switch (_clasificarNivel(detalle.evaluacionInicial?.nivelRiesgoNombre)) {
        case 'Bajo':
          bajo++;
          break;
        case 'Medio':
          medio++;
          break;
        case 'Alto':
          alto++;
          break;
        case 'Crítico':
          critico++;
          break;
      }
    }

    return pw.Row(
      children: <pw.Widget>[
        _indicador('Total', detalles.length, PdfColors.blue700),
        _indicador('Bajo', bajo, PdfColors.green700),
        _indicador('Medio', medio, PdfColors.amber700),
        _indicador('Alto', alto, PdfColors.orange800),
        _indicador('Crítico', critico, PdfColors.red700),
      ],
    );
  }

  pw.Widget _indicador(String titulo, int valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 2),
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Column(
          children: <pw.Widget>[
            pw.Text(
              '$valor',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(titulo, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  pw.Widget _tabla(
    List<DetalleIpercModel> detalles,
    Map<int, MatrizIpercModel> matrices,
  ) {
    const List<String> encabezados = <String>[
      'Ítem',
      'Matriz',
      'Tarea',
      'Peligro',
      'Consecuencia',
      'Riesgo inicial',
      'Riesgo residual',
      'Controles / EPP',
      'Estado',
    ];

    final List<List<String>> filas = detalles.map((DetalleIpercModel detalle) {
      final MatrizIpercModel? matriz = matrices[detalle.matrizIpercId];
      return <String>[
        detalle.item.toString(),
        matriz?.codigo ??
            detalle.matrizIpercCodigo ??
            '${detalle.matrizIpercId}',
        detalle.tarea,
        detalle.peligroVisible,
        detalle.consecuenciaVisible,
        _evaluacionTexto(detalle.evaluacionInicial),
        _evaluacionTexto(detalle.evaluacionResidual),
        '${detalle.controlIds.length} / ${detalle.equipoProteccionIds.length}',
        detalle.estadoImplementacionNombre,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: encabezados,
      data: filas,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 6.5),
      cellPadding: const pw.EdgeInsets.all(3),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(25),
        1: pw.FixedColumnWidth(55),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(1.0),
        7: pw.FixedColumnWidth(48),
        8: pw.FixedColumnWidth(62),
      },
    );
  }

  String _evaluacionTexto(EvaluacionDetalleIpercModel? evaluacion) {
    if (evaluacion == null) {
      return 'Pendiente';
    }

    return '${evaluacion.nivelRiesgoNombre} (${evaluacion.valorRiesgo})\n'
        'P:${evaluacion.valorProbabilidad} × S:${evaluacion.valorSeveridad}';
  }

  String _clasificarNivel(String? nombre) {
    final String texto = nombre?.trim().toLowerCase() ?? '';
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
}
