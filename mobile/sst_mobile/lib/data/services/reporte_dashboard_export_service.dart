import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/detalle_iperc_model.dart';
import '../models/matriz_iperc_model.dart';
import '../models/seguimiento_iperc_model.dart';

/// Formato de pagina para el informe ejecutivo.
enum ReportePdfFormato { vertical, horizontal, mixto }

/// Servicio para generar el informe ejecutivo SST/IPERC.
///
/// IMPORTANTE:
/// Los textos estaticos con acentos usan escapes Unicode.
/// Esto evita problemas de codificacion al copiar el archivo
/// desde Windows/PowerShell.
// PDF_EDURISK_LIGHT_V1
class ReporteDashboardExportService {
  Future<Uint8List> generarInformeEjecutivo({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
    required ReportePdfFormato formato,
    List<SeguimientoIpercModel> seguimientos = const <SeguimientoIpercModel>[],
    int totalSeguimientos = 0,
    int seguimientosVerificados = 0,
    double avancePromedioSeguimientos = 0,
    int seguimientosPendientesSincronizar = 0,
  }) async {
    final pw.Document documento = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );

    final _ResumenRiesgo resumen = _crearResumen(
      matrices: matrices,
      detalles: detalles,
      totalSeguimientos: totalSeguimientos,
      seguimientosVerificados: seguimientosVerificados,
      avancePromedioSeguimientos: avancePromedioSeguimientos,
      seguimientosPendientesSincronizar: seguimientosPendientesSincronizar,
    );

    if (formato == ReportePdfFormato.mixto) {
      documento.addPage(
        _paginaDashboard(
          pageFormat: PdfPageFormat.a4,
          resumen: resumen,
          detalles: detalles,
          matrices: matrices,
          seguimientos: seguimientos,
        ),
      );

      documento.addPage(
        _paginaDetalle(
          pageFormat: PdfPageFormat.a4.landscape,
          matrices: matrices,
          detalles: detalles,
        ),
      );
    } else {
      final PdfPageFormat pageFormat = formato == ReportePdfFormato.horizontal
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4;

      documento.addPage(
        _paginaDashboard(
          pageFormat: pageFormat,
          resumen: resumen,
          detalles: detalles,
          matrices: matrices,
          seguimientos: seguimientos,
        ),
      );

      documento.addPage(
        _paginaDetalle(
          pageFormat: pageFormat,
          matrices: matrices,
          detalles: detalles,
        ),
      );
    }

    return documento.save();
  }

  pw.Page _paginaDashboard({
    required PdfPageFormat pageFormat,
    required _ResumenRiesgo resumen,
    required List<DetalleIpercModel> detalles,
    required List<MatrizIpercModel> matrices,
    required List<SeguimientoIpercModel> seguimientos,
  }) {
    final bool horizontal = pageFormat.width > pageFormat.height;

    return pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.zero,
      build: (_) {
        return pw.Container(
          color: const PdfColor.fromInt(0xFFF6F8FC),
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              _encabezadoDashboard(resumen),
              pw.SizedBox(height: 12),
              _tarjetasResumen(resumen),
              pw.SizedBox(height: 12),

              // GRAFICOS_PDF_REPORTE_GENERAL_V1
              _seccionGraficos(
                resumen,
                matrices: matrices,
                seguimientos: seguimientos,
              ),
              pw.SizedBox(height: 10),
              if (horizontal)
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Expanded(
                        child: pw.Column(
                          children: <pw.Widget>[
                            _seccionComparacion(resumen),
                            pw.SizedBox(height: 10),
                            _seccionSeguimientos(resumen),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: _seccionCriticos(detalles, maxItems: 4),
                      ),
                    ],
                  ),
                )
              else ...<pw.Widget>[
                _seccionComparacion(resumen),
                pw.SizedBox(height: 11),
                _seccionCriticos(detalles, maxItems: 4),
                pw.SizedBox(height: 11),
                _seccionSeguimientos(resumen),
              ],
            ],
          ),
        );
      },
    );
  }

  pw.MultiPage _paginaDetalle({
    required PdfPageFormat pageFormat,
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
  }) {
    return pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(22, 28, 22, 28),
      header: (_) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'DETALLE SST / IPERC',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.Text(
            'Sistema SST/IPERC',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.blueGrey600,
            ),
          ),
        ],
      ),
      footer: (pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'P\u00E1gina ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey500),
        ),
      ),
      build: (_) {
        return <pw.Widget>[
          _tituloSeccionClaro('Matrices IPERC'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>[
              'C\u00F3digo',
              'Nombre',
              'Instituci\u00F3n',
              '\u00C1rea',
              'Actividad',
              'Versi\u00F3n',
              'Estado',
            ],
            data: matrices.map((MatrizIpercModel matriz) {
              return <String>[
                _textoSeguro(matriz.codigo),
                _textoSeguro(matriz.nombre),
                _textoSeguro(matriz.institucionVisible),
                _textoSeguro(matriz.areaVisible),
                _textoSeguro(matriz.actividadVisible),
                matriz.version?.toString() ?? '-',
                _estadoMatriz(matriz),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF083F85),
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.4),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 18),
          _tituloSeccionClaro('Detalle de riesgos'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>[
              'Matriz',
              'Tarea',
              'Peligro',
              'Consecuencia',
              'Inicial',
              'Residual',
              'Estado',
            ],
            data: detalles.map((DetalleIpercModel detalle) {
              final int inicial = detalle.evaluacionInicial.valorRiesgo;

              final int? residual = detalle.evaluacionResidual?.valorRiesgo;

              return <String>[
                _textoSeguro(detalle.matrizIpercCodigo),
                _textoSeguro(detalle.tarea),
                _textoSeguro(detalle.peligroVisible),
                _textoSeguro(detalle.consecuenciaVisible),
                '$inicial - '
                    '${_textoSeguro(detalle.evaluacionInicial.nivelRiesgoNombre)}',
                residual == null
                    ? 'Sin evaluaci\u00F3n'
                    : '$residual - '
                          '${_textoSeguro(detalle.evaluacionResidual!.nivelRiesgoNombre)}',
                _estadoImplementacion(detalle),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF083F85),
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.1),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ];
      },
    );
  }

  pw.Widget _encabezadoDashboard(_ResumenRiesgo resumen) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF083F85),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF0D60D6)),
      ),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'REPORTE EJECUTIVO SST / IPERC',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Dashboard de riesgos, controles y seguimiento',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFE6F0FF),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF0D60D6),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              '${resumen.totalMatrices} matrices',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tarjetasResumen(_ResumenRiesgo resumen) {
    return pw.Row(
      children: <pw.Widget>[
        pw.Expanded(
          child: _tarjetaDato(
            titulo: 'Riesgos',
            valor: resumen.totalRiesgos.toString(),
            color: const PdfColor.fromInt(0xFF0D60D6),
          ),
        ),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: _tarjetaDato(
            titulo: 'Cr\u00EDticos',
            valor: resumen.criticos.toString(),
            color: const PdfColor.fromInt(0xFFEC490F),
          ),
        ),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: _tarjetaDato(
            titulo: 'Controlados',
            valor: resumen.controlados.toString(),
            color: const PdfColor.fromInt(0xFF1DA041),
          ),
        ),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: _tarjetaDato(
            titulo: 'Pendientes',
            valor: resumen.pendientes.toString(),
            color: const PdfColor.fromInt(0xFFFEB81C),
          ),
        ),
      ],
    );
  }

  pw.Widget _tarjetaDato({
    required String titulo,
    required String valor,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFFFF),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD5DCE8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            valor,
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF172033),
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // GRAFICOS_PDF_REPORTE_GENERAL_V1
  pw.Widget _seccionGraficos(
    _ResumenRiesgo resumen, {
    required List<MatrizIpercModel> matrices,
    required List<SeguimientoIpercModel> seguimientos,
  }) {
    final List<_GraficoMesPdf> meses = _crearSerieMensual(
      matrices: matrices,
      seguimientos: seguimientos,
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          child: _panelOscuro(
            titulo: 'Evoluci\u00F3n mensual',
            child: pw.SvgImage(
              svg: _svgGraficoLineal(meses),
              height: 115,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _panelOscuro(
            titulo: 'Distribuci\u00F3n circular',
            child: pw.SvgImage(
              svg: _svgGraficoCircular(resumen),
              height: 115,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  List<_GraficoMesPdf> _crearSerieMensual({
    required List<MatrizIpercModel> matrices,
    required List<SeguimientoIpercModel> seguimientos,
  }) {
    final DateTime ahora = DateTime.now();

    const List<String> nombres = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return List<_GraficoMesPdf>.generate(6, (int index) {
      final DateTime mes = DateTime(ahora.year, ahora.month - 5 + index, 1);

      final int totalMatrices = matrices.where((MatrizIpercModel item) {
        final DateTime? fecha = item.fechaRegistro ?? item.fechaEvaluacion;

        return fecha != null &&
            fecha.year == mes.year &&
            fecha.month == mes.month;
      }).length;

      final int totalSeguimientos = seguimientos.where((
        SeguimientoIpercModel item,
      ) {
        final DateTime fecha = item.fechaSeguimiento;

        return fecha.year == mes.year && fecha.month == mes.month;
      }).length;

      return _GraficoMesPdf(
        etiqueta: nombres[mes.month - 1],
        matrices: totalMatrices,
        seguimientos: totalSeguimientos,
      );
    });
  }

  String _svgGraficoLineal(List<_GraficoMesPdf> datos) {
    const double width = 330;
    const double height = 115;
    const double left = 24;
    const double right = 8;
    const double top = 20;
    const double bottom = 24;

    final double plotWidth = width - left - right;
    final double plotHeight = height - top - bottom;

    int maximo = 1;

    for (final _GraficoMesPdf mes in datos) {
      maximo = math.max(maximo, math.max(mes.matrices, mes.seguimientos));
    }

    String puntos(int Function(_GraficoMesPdf mes) valor) {
      final List<String> salida = <String>[];

      for (int i = 0; i < datos.length; i++) {
        final double x = datos.length == 1
            ? left + plotWidth / 2
            : left + plotWidth * i / (datos.length - 1);

        final double y =
            top + plotHeight - (plotHeight * valor(datos[i]) / maximo);

        salida.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
      }

      return salida.join(' ');
    }

    final StringBuffer svg = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $width $height">',
      )
      ..writeln(
        '<rect width="$width" height="$height" rx="8" fill="#FFFFFF"/>',
      );

    for (int i = 0; i <= 4; i++) {
      final double y = top + plotHeight * i / 4;

      svg.writeln(
        '<line x1="$left" y1="${y.toStringAsFixed(1)}" '
        'x2="${(left + plotWidth).toStringAsFixed(1)}" '
        'y2="${y.toStringAsFixed(1)}" '
        'stroke="#D5DCE8" stroke-width="0.8"/>',
      );
    }

    svg
      ..writeln(
        '<circle cx="30" cy="10" r="3" fill="#0D60D6"/>'
        '<text x="37" y="13" fill="#5E687A" '
        'font-size="8">Matrices</text>',
      )
      ..writeln(
        '<circle cx="100" cy="10" r="3" fill="#1DA041"/>'
        '<text x="107" y="13" fill="#5E687A" '
        'font-size="8">Seguimientos</text>',
      )
      ..writeln(
        '<polyline fill="none" stroke="#0D60D6" stroke-width="2.4" '
        'stroke-linecap="round" stroke-linejoin="round" '
        'points="${puntos((_GraficoMesPdf e) => e.matrices)}"/>',
      )
      ..writeln(
        '<polyline fill="none" stroke="#1DA041" stroke-width="2.4" '
        'stroke-linecap="round" stroke-linejoin="round" '
        'points="${puntos((_GraficoMesPdf e) => e.seguimientos)}"/>',
      );

    for (int i = 0; i < datos.length; i++) {
      final double x = datos.length == 1
          ? left + plotWidth / 2
          : left + plotWidth * i / (datos.length - 1);

      final double yM =
          top + plotHeight - (plotHeight * datos[i].matrices / maximo);

      final double yS =
          top + plotHeight - (plotHeight * datos[i].seguimientos / maximo);

      svg
        ..writeln(
          '<circle cx="${x.toStringAsFixed(1)}" '
          'cy="${yM.toStringAsFixed(1)}" r="2.6" fill="#0D60D6"/>',
        )
        ..writeln(
          '<circle cx="${x.toStringAsFixed(1)}" '
          'cy="${yS.toStringAsFixed(1)}" r="2.6" fill="#1DA041"/>',
        )
        ..writeln(
          '<text x="${x.toStringAsFixed(1)}" y="108" '
          'text-anchor="middle" fill="#5E687A" '
          'font-size="7.5">${datos[i].etiqueta}</text>',
        );
    }

    svg.writeln('</svg>');

    return svg.toString();
  }

  String _svgGraficoCircular(_ResumenRiesgo resumen) {
    const double width = 330;
    const double height = 115;
    const double cx = 68;
    const double cy = 58;
    const double radius = 43;
    const double innerRadius = 25;

    final List<int> valores = <int>[
      resumen.bajos,
      resumen.medios,
      resumen.altos,
      resumen.criticos,
    ];

    const List<String> colores = <String>[
      '#1DA041',
      '#FEB81C',
      '#EC7A18',
      '#EC490F',
    ];

    const List<String> etiquetas = <String>['Bajo', 'Medio', 'Alto', 'Critico'];

    final int total = valores.fold<int>(
      0,
      (int anterior, int actual) => anterior + actual,
    );

    final StringBuffer svg = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $width $height">',
      )
      ..writeln(
        '<rect width="$width" height="$height" rx="8" fill="#FFFFFF"/>',
      );

    if (total <= 0) {
      svg.writeln('<circle cx="$cx" cy="$cy" r="$radius" fill="#E8EDF5"/>');
    } else {
      double inicio = -math.pi / 2;

      for (int i = 0; i < valores.length; i++) {
        final int valor = valores[i];

        if (valor <= 0) {
          continue;
        }

        final double barrido = math.pi * 2 * valor / total;
        final double fin = inicio + barrido;

        final double x1 = cx + radius * math.cos(inicio);
        final double y1 = cy + radius * math.sin(inicio);
        final double x2 = cx + radius * math.cos(fin);
        final double y2 = cy + radius * math.sin(fin);

        final int arcoGrande = barrido > math.pi ? 1 : 0;

        svg.writeln(
          '<path d="M $cx $cy '
          'L ${x1.toStringAsFixed(2)} ${y1.toStringAsFixed(2)} '
          'A $radius $radius 0 $arcoGrande 1 '
          '${x2.toStringAsFixed(2)} ${y2.toStringAsFixed(2)} Z" '
          'fill="${colores[i]}"/>',
        );

        inicio = fin;
      }
    }

    svg
      ..writeln('<circle cx="$cx" cy="$cy" r="$innerRadius" fill="#FFFFFF"/>')
      ..writeln(
        '<text x="$cx" y="56" text-anchor="middle" fill="#FFFFFF" '
        'font-size="14" font-weight="700">$total</text>',
      )
      ..writeln(
        '<text x="$cx" y="68" text-anchor="middle" fill="#5E687A" '
        'font-size="7">riesgos</text>',
      );

    for (int i = 0; i < etiquetas.length; i++) {
      final double y = 24 + i * 22;
      final double porcentaje = total <= 0 ? 0 : valores[i] * 100 / total;

      svg
        ..writeln(
          '<rect x="140" y="${(y - 7).toStringAsFixed(1)}" '
          'width="9" height="9" rx="2" fill="${colores[i]}"/>',
        )
        ..writeln(
          '<text x="156" y="$y" fill="#172033" font-size="8">'
          '${etiquetas[i]}: ${valores[i]} '
          '(${porcentaje.toStringAsFixed(0)}%)'
          '</text>',
        );
    }

    svg.writeln('</svg>');

    return svg.toString();
  }

  /// Distribucion rehecha:
  /// - muestra cantidad;
  /// - muestra porcentaje;
  /// - usa una barra rectangular limpia;
  /// - no usa Stack ni FractionallySizedBox.

  // ignore: unused_element
  pw.Widget _seccionDistribucion(
    _ResumenRiesgo resumen, {
    required double barWidth,
  }) {
    final int total = resumen.totalRiesgos == 0 ? 1 : resumen.totalRiesgos;

    return _panelOscuro(
      titulo: 'Distribuci\u00F3n de riesgos',
      child: pw.Column(
        children: <pw.Widget>[
          _filaDistribucion(
            nombre: 'Bajo',
            cantidad: resumen.bajos,
            total: total,
            color: const PdfColor.fromInt(0xFF1DA041),
            barWidth: barWidth,
          ),
          pw.SizedBox(height: 7),
          _filaDistribucion(
            nombre: 'Medio',
            cantidad: resumen.medios,
            total: total,
            color: const PdfColor.fromInt(0xFFFEB81C),
            barWidth: barWidth,
          ),
          pw.SizedBox(height: 7),
          _filaDistribucion(
            nombre: 'Alto',
            cantidad: resumen.altos,
            total: total,
            color: const PdfColor.fromInt(0xFFF28C28),
            barWidth: barWidth,
          ),
          pw.SizedBox(height: 7),
          _filaDistribucion(
            nombre: 'Cr\u00EDtico',
            cantidad: resumen.criticos,
            total: total,
            color: const PdfColor.fromInt(0xFFEC490F),
            barWidth: barWidth,
          ),
        ],
      ),
    );
  }

  pw.Widget _filaDistribucion({
    required String nombre,
    required int cantidad,
    required int total,
    required PdfColor color,
    required double barWidth,
  }) {
    final double ratio = (cantidad / total).clamp(0.0, 1.0).toDouble();

    final String porcentaje = '${(ratio * 100).toStringAsFixed(0)}%';

    return pw.Row(
      children: <pw.Widget>[
        pw.SizedBox(
          width: 48,
          child: pw.Text(
            nombre,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF172033),
              fontSize: 8,
            ),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Container(
          width: barWidth,
          height: 8,
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFE8EDF5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: barWidth * ratio,
              height: 8,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: 24,
          child: pw.Text(
            '$cantidad',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: color,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.SizedBox(
          width: 32,
          child: pw.Text(
            porcentaje,
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF5E687A),
              fontSize: 7.5,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _seccionComparacion(_ResumenRiesgo resumen) {
    return _panelOscuro(
      titulo: 'Reducci\u00F3n del riesgo',
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: _indicadorGrande(
              'Riesgo inicial promedio',
              resumen.promedioInicial.toStringAsFixed(1),
              const PdfColor.fromInt(0xFFF28C28),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _indicadorGrande(
              'Riesgo residual promedio',
              resumen.promedioResidual.toStringAsFixed(1),
              const PdfColor.fromInt(0xFF0D60D6),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _indicadorGrande(
              'Reducci\u00F3n estimada',
              '${resumen.reduccionPorcentaje.toStringAsFixed(0)}%',
              const PdfColor.fromInt(0xFF1DA041),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _indicadorGrande(String titulo, String valor, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F8FC),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            valor,
            style: pw.TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            titulo,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF5E687A),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _seccionCriticos(
    List<DetalleIpercModel> detalles, {
    required int maxItems,
  }) {
    final List<DetalleIpercModel> ordenados =
        List<DetalleIpercModel>.from(detalles)..sort(
          (DetalleIpercModel a, DetalleIpercModel b) =>
              b.valorRiesgoActual.compareTo(a.valorRiesgoActual),
        );

    final List<DetalleIpercModel> top = ordenados
        .take(maxItems)
        .toList(growable: false);

    return _panelOscuro(
      titulo: 'Riesgos prioritarios',
      child: top.isEmpty
          ? pw.Text(
              'No hay riesgos registrados.',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF5E687A),
                fontSize: 8,
              ),
            )
          : pw.Column(
              children: top.asMap().entries.map((
                MapEntry<int, DetalleIpercModel> entry,
              ) {
                final DetalleIpercModel item = entry.value;

                final PdfColor color = _colorPorValor(item.valorRiesgoActual);

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: <pw.Widget>[
                      pw.Container(
                        width: 20,
                        height: 20,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text(
                          '${entry.key + 1}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 7),
                      pw.Expanded(
                        child: pw.Text(
                          '${_textoSeguro(item.peligroVisible)} - '
                          '${_textoSeguro(item.tarea)}',
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFF172033),
                            fontSize: 7.4,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '${item.valorRiesgoActual}',
                        style: pw.TextStyle(
                          color: color,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  /// Seguimientos corregidos:
  /// - Total;
  /// - Verificados;
  /// - Pendientes;
  /// - Avance promedio;
  /// - porcentaje de verificacion;
  /// - pendientes de sincronizacion.
  pw.Widget _seccionSeguimientos(_ResumenRiesgo resumen) {
    final int total = resumen.totalSeguimientos;

    final int verificados = resumen.seguimientosVerificados.clamp(0, total);

    final int pendientes = (total - verificados).clamp(0, total);

    final double cumplimiento = total == 0
        ? 0
        : (verificados / total).clamp(0.0, 1.0).toDouble();

    const double barWidth = 240;

    return _panelOscuro(
      titulo: 'Seguimientos IPERC',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: _miniSeguimiento(
                  titulo: 'Total',
                  valor: '$total',
                  color: const PdfColor.fromInt(0xFF0D60D6),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _miniSeguimiento(
                  titulo: 'Verificados',
                  valor: '$verificados',
                  color: const PdfColor.fromInt(0xFF1DA041),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _miniSeguimiento(
                  titulo: 'Pendientes',
                  valor: '$pendientes',
                  color: const PdfColor.fromInt(0xFFFEB81C),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _miniSeguimiento(
                  titulo: 'Avance promedio',
                  valor:
                      '${resumen.avancePromedioSeguimientos.toStringAsFixed(0)}%',
                  color: const PdfColor.fromInt(0xFF0D60D6),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'Cumplimiento de verificaci\u00F3n',
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF172033),
                  fontSize: 7.5,
                ),
              ),
              pw.Text(
                '${(cumplimiento * 100).toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF1DA041),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            width: barWidth,
            height: 8,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE8EDF5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: barWidth * cumplimiento,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1DA041),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (resumen.seguimientosPendientesSincronizar > 0) ...<pw.Widget>[
            pw.SizedBox(height: 7),
            pw.Text(
              '${resumen.seguimientosPendientesSincronizar} '
              'seguimiento(s) pendiente(s) de sincronizar',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFFF28C28),
                fontSize: 7.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _miniSeguimiento({
    required String titulo,
    required String valor,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F8FC),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            valor,
            style: pw.TextStyle(
              color: color,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            titulo,
            maxLines: 1,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF5E687A),
              fontSize: 6,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _panelOscuro({required String titulo, required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFFFF),
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD5DCE8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            titulo,
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF172033),
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.Widget _tituloSeccionClaro(String titulo) {
    return pw.Text(
      titulo,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey900,
      ),
    );
  }

  _ResumenRiesgo _crearResumen({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
    required int totalSeguimientos,
    required int seguimientosVerificados,
    required double avancePromedioSeguimientos,
    required int seguimientosPendientesSincronizar,
  }) {
    int bajos = 0;
    int medios = 0;
    int altos = 0;
    int criticos = 0;
    int controlados = 0;

    double sumaInicial = 0;
    double sumaResidual = 0;
    int residualCount = 0;

    for (final DetalleIpercModel detalle in detalles) {
      final int valorActual = detalle.valorRiesgoActual;

      if (valorActual <= 4) {
        bajos++;
      } else if (valorActual <= 9) {
        medios++;
      } else if (valorActual <= 16) {
        altos++;
      } else {
        criticos++;
      }

      sumaInicial += detalle.evaluacionInicial.valorRiesgo;

      final int? residual = detalle.evaluacionResidual?.valorRiesgo;

      if (residual != null) {
        sumaResidual += residual;
        residualCount++;

        if (residual < detalle.evaluacionInicial.valorRiesgo) {
          controlados++;
        }
      }
    }

    final double promedioInicial = detalles.isEmpty
        ? 0
        : sumaInicial / detalles.length;

    final double promedioResidual = residualCount == 0
        ? promedioInicial
        : sumaResidual / residualCount;

    final double reduccionPorcentaje = promedioInicial <= 0
        ? 0
        : ((promedioInicial - promedioResidual) / promedioInicial * 100)
              .clamp(0, 100)
              .toDouble();

    return _ResumenRiesgo(
      totalMatrices: matrices.length,
      totalRiesgos: detalles.length,
      bajos: bajos,
      medios: medios,
      altos: altos,
      criticos: criticos,
      controlados: controlados,
      pendientes: detalles.length - controlados,
      promedioInicial: promedioInicial,
      promedioResidual: promedioResidual,
      reduccionPorcentaje: reduccionPorcentaje,
      totalSeguimientos: totalSeguimientos,
      seguimientosVerificados: seguimientosVerificados,
      avancePromedioSeguimientos: avancePromedioSeguimientos
          .clamp(0, 100)
          .toDouble(),
      seguimientosPendientesSincronizar: seguimientosPendientesSincronizar,
    );
  }

  String _estadoMatriz(MatrizIpercModel matriz) {
    final String valor = _textoSeguro(matriz.estadoMatriz ?? '').trim();

    final String lower = valor.toLowerCase();

    if (lower.isEmpty ||
        lower == 'true' ||
        lower == '1' ||
        lower == 'activo' ||
        lower == 'activa') {
      return matriz.activo ? 'Vigente' : 'Inactiva';
    }

    if (lower == 'false' ||
        lower == '0' ||
        lower == 'inactivo' ||
        lower == 'inactiva') {
      return 'Inactiva';
    }

    return valor;
  }

  String _estadoImplementacion(DetalleIpercModel detalle) {
    final String estado = _textoSeguro(
      detalle.estadoImplementacionNombre,
    ).trim();

    if (estado.isEmpty) {
      return 'Pendiente';
    }

    switch (estado.toLowerCase()) {
      case 'enproceso':
        return 'En proceso';
      case 'implementado':
        return 'Implementado';
      case 'verificado':
        return 'Verificado';
      default:
        return estado;
    }
  }

  /// Repara texto que accidentalmente haya quedado como
  /// UTF-8 interpretado como Latin-1, por ejemplo:
  /// "CrÃ­tico" -> "Crítico".
  String _textoSeguro(String valor) {
    String texto = valor;

    if (texto.contains('\u00C3') || texto.contains('\u00C2')) {
      try {
        texto = utf8.decode(latin1.encode(texto), allowMalformed: false);
      } catch (_) {
        // Mantener el texto original si no es reparable.
      }
    }

    return texto;
  }

  PdfColor _colorPorValor(int valor) {
    if (valor <= 4) {
      return const PdfColor.fromInt(0xFF1DA041);
    }

    if (valor <= 9) {
      return const PdfColor.fromInt(0xFFFEB81C);
    }

    if (valor <= 16) {
      return const PdfColor.fromInt(0xFFF28C28);
    }

    return const PdfColor.fromInt(0xFFEC490F);
  }
}

class _GraficoMesPdf {
  const _GraficoMesPdf({
    required this.etiqueta,
    required this.matrices,
    required this.seguimientos,
  });

  final String etiqueta;
  final int matrices;
  final int seguimientos;
}

class _ResumenRiesgo {
  const _ResumenRiesgo({
    required this.totalMatrices,
    required this.totalRiesgos,
    required this.bajos,
    required this.medios,
    required this.altos,
    required this.criticos,
    required this.controlados,
    required this.pendientes,
    required this.promedioInicial,
    required this.promedioResidual,
    required this.reduccionPorcentaje,
    required this.totalSeguimientos,
    required this.seguimientosVerificados,
    required this.avancePromedioSeguimientos,
    required this.seguimientosPendientesSincronizar,
  });

  final int totalMatrices;
  final int totalRiesgos;
  final int bajos;
  final int medios;
  final int altos;
  final int criticos;
  final int controlados;
  final int pendientes;
  final double promedioInicial;
  final double promedioResidual;
  final double reduccionPorcentaje;

  final int totalSeguimientos;
  final int seguimientosVerificados;
  final double avancePromedioSeguimientos;
  final int seguimientosPendientesSincronizar;
}
