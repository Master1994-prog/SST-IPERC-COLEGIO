import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/control_model.dart';
import '../models/detalle_iperc_model.dart';
import '../models/matriz_iperc_model.dart';
import '../models/seguimiento_iperc_model.dart';
import 'reporte_dashboard_export_service.dart';

/// ===============================================================
/// REPORTES ESPECIFICOS PROFESIONALES SST/IPERC
/// ===============================================================
///
/// Mejoras incluidas:
/// - resumen visual por reporte;
/// - tarjetas de indicadores;
/// - graficos circulares tipo donut/progreso;
/// - tablas profesionales;
/// - A4 vertical, horizontal y mixto;
/// - los cuadros permanecen dentro del PDF;
/// - si no entra en la misma hoja, continua automaticamente
///   en la siguiente usando MultiPage.
/// ===============================================================
class ReporteEspecificoProfesionalService {
  Future<Uint8List> generarPdfMatrices(
    List<MatrizIpercModel> matrices, {
    required ReportePdfFormato formato,
  }) async {
    final pw.Document doc = _documento();

    final int vigentes = matrices.where((m) => m.activo).length;
    final int inactivas = matrices.where((m) => !m.activo).length;

    _agregarDocumento(
      doc,
      formato: formato,
      titulo: 'MATRICES IPERC',
      subtitulo:
          'Registro de matrices de identificacion de peligros y evaluacion de riesgos',
      resumen: <_ResumenCard>[
        _ResumenCard(
          'Total',
          matrices.length.toString(),
          const PdfColor.fromInt(0xFF4B8DFF),
        ),
        _ResumenCard(
          'Vigentes',
          vigentes.toString(),
          const PdfColor.fromInt(0xFF37D39B),
        ),
        _ResumenCard(
          'Inactivas',
          inactivas.toString(),
          const PdfColor.fromInt(0xFFFFAE57),
        ),
      ],
      circulares: <_CircularChartData>[
        _CircularChartData(
          titulo: 'Vigentes',
          valor: vigentes.toDouble(),
          total: matrices.isEmpty ? 1 : matrices.length.toDouble(),
          color: const PdfColor.fromInt(0xFF37D39B),
        ),
        _CircularChartData(
          titulo: 'Inactivas',
          valor: inactivas.toDouble(),
          total: matrices.isEmpty ? 1 : matrices.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFFAE57),
        ),
      ],
      tablaHeaders: const <String>[
        'Codigo',
        'Nombre',
        'Institucion',
        'Area',
        'Actividad',
        'Version',
        'Estado',
        'Fecha',
      ],
      tablaData: matrices.map((MatrizIpercModel m) {
        return <String>[
          _textoSeguro(m.codigo),
          _textoSeguro(m.nombre),
          _textoSeguro(m.institucionVisible),
          _textoSeguro(m.areaVisible),
          _textoSeguro(m.actividadVisible),
          m.version?.toString() ?? '-',
          _estadoMatriz(m),
          _fecha(m.fechaEvaluacion),
        ];
      }).toList(),
    );

    return doc.save();
  }

  Future<Uint8List> generarPdfRiesgos(
    List<DetalleIpercModel> detalles, {
    required ReportePdfFormato formato,
  }) async {
    final pw.Document doc = _documento();

    final int criticos = detalles
        .where((d) => d.valorRiesgoActual >= 17)
        .length;
    final int altos = detalles
        .where((d) => d.valorRiesgoActual >= 10 && d.valorRiesgoActual <= 16)
        .length;
    final int medios = detalles
        .where((d) => d.valorRiesgoActual >= 5 && d.valorRiesgoActual <= 9)
        .length;
    final int bajos = detalles.where((d) => d.valorRiesgoActual <= 4).length;

    _agregarDocumento(
      doc,
      formato: formato,
      titulo: 'EVALUACION DE RIESGOS IPERC',
      subtitulo: 'Riesgo inicial, residual y estado de implementacion',
      resumen: <_ResumenCard>[
        _ResumenCard(
          'Riesgos',
          detalles.length.toString(),
          const PdfColor.fromInt(0xFF4B8DFF),
        ),
        _ResumenCard(
          'Criticos',
          criticos.toString(),
          const PdfColor.fromInt(0xFFFF4B65),
        ),
        _ResumenCard(
          'Altos',
          altos.toString(),
          const PdfColor.fromInt(0xFFFF934B),
        ),
        _ResumenCard(
          'Bajos/Medios',
          '${bajos + medios}',
          const PdfColor.fromInt(0xFF37D39B),
        ),
      ],
      circulares: <_CircularChartData>[
        _CircularChartData(
          titulo: 'Criticos',
          valor: criticos.toDouble(),
          total: detalles.isEmpty ? 1 : detalles.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFF4B65),
        ),
        _CircularChartData(
          titulo: 'Altos',
          valor: altos.toDouble(),
          total: detalles.isEmpty ? 1 : detalles.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFF934B),
        ),
        _CircularChartData(
          titulo: 'Medios',
          valor: medios.toDouble(),
          total: detalles.isEmpty ? 1 : detalles.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFFD35A),
        ),
        _CircularChartData(
          titulo: 'Bajos',
          valor: bajos.toDouble(),
          total: detalles.isEmpty ? 1 : detalles.length.toDouble(),
          color: const PdfColor.fromInt(0xFF37D39B),
        ),
      ],
      tablaHeaders: const <String>[
        'Matriz',
        'Tarea',
        'Peligro',
        'Consecuencia',
        'Inicial',
        'Residual',
        'Nivel actual',
        'Estado',
      ],
      tablaData: detalles.map((DetalleIpercModel d) {
        final int? residual = d.evaluacionResidual?.valorRiesgo;

        return <String>[
          _textoSeguro(d.matrizIpercCodigo),
          _textoSeguro(d.tarea),
          _textoSeguro(d.peligroVisible),
          _textoSeguro(d.consecuenciaVisible),
          '${d.evaluacionInicial.valorRiesgo}',
          residual?.toString() ?? 'Sin evaluacion',
          _textoSeguro(d.nivelRiesgoActual),
          _estadoDetalle(d),
        ];
      }).toList(),
    );

    return doc.save();
  }

  Future<Uint8List> generarPdfControles(
    List<ControlModel> controles, {
    required ReportePdfFormato formato,
  }) async {
    final pw.Document doc = _documento();

    final int disponibles = controles.where((c) => c.estaDisponible).length;
    final int activos = controles.where((c) => c.activo).length;
    final int inactivos = controles.length - activos;

    _agregarDocumento(
      doc,
      formato: formato,
      titulo: 'CONTROLES SST',
      subtitulo:
          'Medidas de control para eliminacion, reduccion y control del riesgo',
      resumen: <_ResumenCard>[
        _ResumenCard(
          'Total',
          controles.length.toString(),
          const PdfColor.fromInt(0xFF4B8DFF),
        ),
        _ResumenCard(
          'Disponibles',
          disponibles.toString(),
          const PdfColor.fromInt(0xFF37D39B),
        ),
        _ResumenCard(
          'Activos',
          activos.toString(),
          const PdfColor.fromInt(0xFF53A6FF),
        ),
        _ResumenCard(
          'Inactivos',
          inactivos.toString(),
          const PdfColor.fromInt(0xFFFFAE57),
        ),
      ],
      circulares: <_CircularChartData>[
        _CircularChartData(
          titulo: 'Disponibles',
          valor: disponibles.toDouble(),
          total: controles.isEmpty ? 1 : controles.length.toDouble(),
          color: const PdfColor.fromInt(0xFF37D39B),
        ),
        _CircularChartData(
          titulo: 'Activos',
          valor: activos.toDouble(),
          total: controles.isEmpty ? 1 : controles.length.toDouble(),
          color: const PdfColor.fromInt(0xFF53A6FF),
        ),
      ],
      tablaHeaders: const <String>[
        'Codigo',
        'Control',
        'Clasificacion',
        'Descripcion',
        'Activo',
        'Estado',
      ],
      tablaData: controles.map((ControlModel c) {
        return <String>[
          _textoSeguro(c.codigo.isEmpty ? '-' : c.codigo),
          _textoSeguro(c.nombre),
          _textoSeguro(c.clasificacionVisible),
          _textoSeguro(c.descripcionVisible),
          c.activo ? 'Si' : 'No',
          c.estado ? 'Vigente' : 'Inactivo',
        ];
      }).toList(),
    );

    return doc.save();
  }

  Future<Uint8List> generarPdfSeguimientos(
    List<SeguimientoIpercModel> seguimientos, {
    required ReportePdfFormato formato,
    int pendientesSincronizar = 0,
  }) async {
    final pw.Document doc = _documento();

    final int verificados = seguimientos.where((s) => s.verificado).length;
    final int pendientes = seguimientos.length - verificados;

    final double avancePromedio = seguimientos.isEmpty
        ? 0
        : seguimientos.fold<double>(
                0,
                (total, s) => total + s.porcentajeAvance,
              ) /
              seguimientos.length;

    _agregarDocumento(
      doc,
      formato: formato,
      titulo: 'SEGUIMIENTOS IPERC',
      subtitulo: 'Avance, verificacion y cumplimiento de acciones',
      resumen: <_ResumenCard>[
        _ResumenCard(
          'Total',
          seguimientos.length.toString(),
          const PdfColor.fromInt(0xFF4B8DFF),
        ),
        _ResumenCard(
          'Verificados',
          verificados.toString(),
          const PdfColor.fromInt(0xFF37D39B),
        ),
        _ResumenCard(
          'Pendientes',
          pendientes.toString(),
          const PdfColor.fromInt(0xFFFFAE57),
        ),
        _ResumenCard(
          'Avance prom.',
          '${avancePromedio.toStringAsFixed(0)}%',
          const PdfColor.fromInt(0xFFB889FF),
        ),
      ],
      circulares: <_CircularChartData>[
        _CircularChartData(
          titulo: 'Verificados',
          valor: verificados.toDouble(),
          total: seguimientos.isEmpty ? 1 : seguimientos.length.toDouble(),
          color: const PdfColor.fromInt(0xFF37D39B),
        ),
        _CircularChartData(
          titulo: 'Pendientes',
          valor: pendientes.toDouble(),
          total: seguimientos.isEmpty ? 1 : seguimientos.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFFAE57),
        ),
        _CircularChartData(
          titulo: 'Avance',
          valor: avancePromedio,
          total: 100,
          color: const PdfColor.fromInt(0xFFB889FF),
          porcentajeExplicito: true,
        ),
      ],
      extraResumen: pendientesSincronizar > 0
          ? '$pendientesSincronizar seguimiento(s) pendiente(s) de sincronizar'
          : null,
      tablaHeaders: const <String>[
        'Detalle IPERC',
        'Fecha',
        'Responsable',
        'Descripcion',
        'Avance',
        'Estado',
        'Verificacion',
        'Observaciones',
      ],
      tablaData: seguimientos.map((SeguimientoIpercModel s) {
        return <String>[
          _textoSeguro(s.detalleVisible),
          _fecha(s.fechaSeguimiento),
          _textoSeguro(
            (s.usuarioNombre?.trim().isNotEmpty ?? false)
                ? s.usuarioNombre!
                : 'Usuario ${s.usuarioId}',
          ),
          _textoSeguro(s.descripcion.trim().isEmpty ? '-' : s.descripcion),
          '${s.porcentajeAvance.toStringAsFixed(0)}%',
          s.verificado ? 'Verificado' : 'Pendiente',
          _fecha(s.fechaVerificacion),
          _textoSeguro(
            s.observaciones?.trim().isNotEmpty ?? false
                ? s.observaciones!
                : '-',
          ),
        ];
      }).toList(),
    );

    return doc.save();
  }

  Future<Uint8List> generarPdfMapas({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
    required ReportePdfFormato formato,
  }) async {
    final pw.Document doc = _documento();

    final Map<String, List<DetalleIpercModel>> porArea =
        <String, List<DetalleIpercModel>>{};

    final Map<int, MatrizIpercModel> matrizPorId = <int, MatrizIpercModel>{
      for (final MatrizIpercModel m in matrices) m.id: m,
    };

    for (final DetalleIpercModel d in detalles) {
      final MatrizIpercModel? matriz = matrizPorId[d.matrizIpercId];

      final String area = matriz?.areaVisible.trim().isNotEmpty == true
          ? matriz!.areaVisible
          : 'Sin area';

      porArea.putIfAbsent(area, () => <DetalleIpercModel>[]).add(d);
    }

    final List<List<String>> data = porArea.entries.map((
      MapEntry<String, List<DetalleIpercModel>> entry,
    ) {
      final List<DetalleIpercModel> riesgos = entry.value;

      riesgos.sort(
        (a, b) => b.valorRiesgoActual.compareTo(a.valorRiesgoActual),
      );

      final DetalleIpercModel mayor = riesgos.first;

      final int criticos = riesgos
          .where((r) => r.valorRiesgoActual >= 17)
          .length;

      return <String>[
        _textoSeguro(entry.key),
        riesgos.length.toString(),
        criticos.toString(),
        _textoSeguro(mayor.peligroVisible),
        mayor.valorRiesgoActual.toString(),
        _textoSeguro(mayor.nivelRiesgoActual),
      ];
    }).toList();

    data.sort((a, b) => int.parse(b[4]).compareTo(int.parse(a[4])));

    final int totalAreas = porArea.length;
    final int totalCriticos = detalles
        .where((d) => d.valorRiesgoActual >= 17)
        .length;

    _agregarDocumento(
      doc,
      formato: formato,
      titulo: 'MAPA DE RIESGOS',
      subtitulo: 'Resumen de riesgos identificados por area y criticidad',
      resumen: <_ResumenCard>[
        _ResumenCard(
          'Areas',
          totalAreas.toString(),
          const PdfColor.fromInt(0xFF4B8DFF),
        ),
        _ResumenCard(
          'Riesgos',
          detalles.length.toString(),
          const PdfColor.fromInt(0xFFFFAE57),
        ),
        _ResumenCard(
          'Criticos',
          totalCriticos.toString(),
          const PdfColor.fromInt(0xFFFF4B65),
        ),
      ],
      circulares: <_CircularChartData>[
        _CircularChartData(
          titulo: 'Areas criticas',
          valor: porArea.values
              .where((list) => list.any((d) => d.valorRiesgoActual >= 17))
              .length
              .toDouble(),
          total: totalAreas == 0 ? 1 : totalAreas.toDouble(),
          color: const PdfColor.fromInt(0xFFFF4B65),
        ),
        _CircularChartData(
          titulo: 'Criticos',
          valor: totalCriticos.toDouble(),
          total: detalles.isEmpty ? 1 : detalles.length.toDouble(),
          color: const PdfColor.fromInt(0xFFFF934B),
        ),
      ],
      tablaHeaders: const <String>[
        'Area / Zona',
        'Riesgos',
        'Criticos',
        'Peligro principal',
        'Valor max.',
        'Nivel',
      ],
      tablaData: data,
    );

    return doc.save();
  }

  pw.Document _documento() {
    return pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );
  }

  void _agregarDocumento(
    pw.Document doc, {
    required ReportePdfFormato formato,
    required String titulo,
    required String subtitulo,
    required List<_ResumenCard> resumen,
    required List<_CircularChartData> circulares,
    required List<String> tablaHeaders,
    required List<List<String>> tablaData,
    String? extraResumen,
  }) {
    // -----------------------------------------------------------
    // FORMATO MIXTO
    // -----------------------------------------------------------
    // La primera parte es A4 vertical y la tabla A4 horizontal.
    // Como cambia la orientación, la tabla empieza en otra hoja.
    if (formato == ReportePdfFormato.mixto) {
      doc.addPage(
        _resumenContinuable(
          PdfPageFormat.a4,
          titulo: titulo,
          subtitulo: subtitulo,
          resumen: resumen,
          circulares: circulares,
          extraResumen: extraResumen,
        ),
      );

      doc.addPage(
        _tablaDetalle(
          PdfPageFormat.a4.landscape,
          titulo: titulo,
          headers: tablaHeaders,
          data: tablaData,
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // VERTICAL / HORIZONTAL
    // -----------------------------------------------------------
    // Todo se coloca en UN MISMO MultiPage:
    //
    // encabezado
    // tarjetas
    // graficos
    // tabla
    //
    // Si queda espacio, la tabla sube a la misma hoja.
    // Si no queda espacio, MultiPage la continúa en la siguiente.
    final PdfPageFormat pageFormat = formato == ReportePdfFormato.horizontal
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    doc.addPage(
      _reporteCompleto(
        pageFormat,
        titulo: titulo,
        subtitulo: subtitulo,
        resumen: resumen,
        circulares: circulares,
        tablaHeaders: tablaHeaders,
        tablaData: tablaData,
        extraResumen: extraResumen,
      ),
    );
  }

  /// Reporte completo en un solo flujo de páginas.
  ///
  /// Esto elimina el gran espacio en blanco que aparecía entre
  /// los gráficos y la tabla.
  pw.MultiPage _reporteCompleto(
    PdfPageFormat pageFormat, {
    required String titulo,
    required String subtitulo,
    required List<_ResumenCard> resumen,
    required List<_CircularChartData> circulares,
    required List<String> tablaHeaders,
    required List<List<String>> tablaData,
    String? extraResumen,
  }) {
    return pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(22, 22, 22, 28),
      footer: (pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey500),
        ),
      ),
      build: (_) {
        return <pw.Widget>[
          ..._widgetsResumen(
            titulo: titulo,
            subtitulo: subtitulo,
            resumen: resumen,
            circulares: circulares,
            extraResumen: extraResumen,
          ),

          // La tabla comienza inmediatamente después del resumen.
          pw.SizedBox(height: 14),

          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),

          pw.SizedBox(height: 8),

          if (tablaData.isEmpty)
            pw.Text(
              'No hay datos registrados para este reporte.',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey700,
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: tablaHeaders,
              data: tablaData,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 7,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF23384A),
              ),
              cellStyle: const pw.TextStyle(fontSize: 6.3),
              cellPadding: const pw.EdgeInsets.all(4),
              cellAlignment: pw.Alignment.centerLeft,
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF4F7FA),
              ),
            ),
        ];
      },
    );
  }

  /// Construye las tarjetas y gráficos del resumen para poder
  /// reutilizarlos dentro de un MultiPage completo.
  List<pw.Widget> _widgetsResumen({
    required String titulo,
    required String subtitulo,
    required List<_ResumenCard> resumen,
    required List<_CircularChartData> circulares,
    String? extraResumen,
  }) {
    return <pw.Widget>[
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF0A1830),
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFF214C86)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              titulo,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              subtitulo,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF9EB5D5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 14),

      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF06101F),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Wrap(
          spacing: 9,
          runSpacing: 9,
          children: resumen.map(_card).toList(),
        ),
      ),

      if (circulares.isNotEmpty) ...<pw.Widget>[
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF0B172A),
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFF203652)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Gráficos circulares',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: circulares.map(_circularCard).toList(),
              ),
            ],
          ),
        ),
      ],

      if (extraResumen != null) ...<pw.Widget>[
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(11),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF2A2411),
            borderRadius: pw.BorderRadius.circular(9),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFF705622)),
          ),
          child: pw.Text(
            extraResumen,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFFFFCB72),
              fontSize: 9,
            ),
          ),
        ),
      ],
    ];
  }

  /// Resumen en MultiPage para que, si no hay espacio en la hoja,
  /// el contenido continue automaticamente en la siguiente.
  pw.MultiPage _resumenContinuable(
    PdfPageFormat pageFormat, {
    required String titulo,
    required String subtitulo,
    required List<_ResumenCard> resumen,
    required List<_CircularChartData> circulares,
    String? extraResumen,
  }) {
    return pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(22),
      build: (_) {
        return <pw.Widget>[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF0A1830),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF214C86)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  subtitulo,
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFF9EB5D5),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF06101F),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Wrap(
              spacing: 9,
              runSpacing: 9,
              children: resumen.map(_card).toList(),
            ),
          ),

          if (circulares.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0B172A),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFF203652),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Graficos circulares',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: circulares.map(_circularCard).toList(),
                  ),
                ],
              ),
            ),
          ],

          if (extraResumen != null) ...<pw.Widget>[
            pw.SizedBox(height: 15),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF2A2411),
                borderRadius: pw.BorderRadius.circular(9),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFF705622),
                ),
              ),
              child: pw.Text(
                extraResumen,
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFFFFCB72),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ];
      },
    );
  }

  pw.Widget _card(_ResumenCard item) {
    return pw.Container(
      width: 122,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0B172A),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF203652)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            item.valor,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            item.titulo,
            style: pw.TextStyle(
              color: item.color,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con grafico circular tipo progreso.
  pw.Widget _circularCard(_CircularChartData item) {
    final double total = item.total <= 0 ? 1 : item.total;
    final double ratio = (item.valor / total).clamp(0.0, 1.0).toDouble();
    final String porcentaje = item.porcentajeExplicito
        ? '${item.valor.toStringAsFixed(0)}%'
        : '${(ratio * 100).toStringAsFixed(0)}%';

    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF102039),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: <pw.Widget>[
          _graficoCircular(
            ratio: ratio,
            color: item.color,
            centerText: porcentaje,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            item.titulo,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFFAFC1D9),
              fontSize: 8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            item.porcentajeExplicito
                ? 'Valor: ${item.valor.toStringAsFixed(0)}%'
                : '${item.valor.toStringAsFixed(0)} de ${item.total.toStringAsFixed(0)}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: item.color,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Grafico circular compatible con el paquete pdf.
  ///
  /// Se utiliza el widget nativo CircularProgressIndicator en lugar
  /// de PdfGraphics.drawArc(), ya que drawArc no forma parte de la
  /// API disponible en la version actual del paquete.
  pw.Widget _graficoCircular({
    required double ratio,
    required PdfColor color,
    required String centerText,
  }) {
    final double value = ratio.clamp(0.0, 1.0).toDouble();

    return pw.SizedBox(
      width: 78,
      height: 78,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: <pw.Widget>[
          pw.CircularProgressIndicator(
            value: value,
            color: color,
            backgroundColor: const PdfColor.fromInt(0xFF20324C),
            strokeWidth: 8,
          ),
          pw.Container(
            width: 48,
            height: 48,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0B172A),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              centerText,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.MultiPage _tablaDetalle(
    PdfPageFormat pageFormat, {
    required String titulo,
    required List<String> headers,
    required List<List<String>> data,
  }) {
    return pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(20, 28, 20, 28),
      header: (_) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.Text(
            'Sistema SST/IPERC',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.blueGrey600,
            ),
          ),
        ],
      ),
      footer: (pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Pagina ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey500),
        ),
      ),
      build: (_) {
        if (data.isEmpty) {
          return <pw.Widget>[
            pw.SizedBox(height: 25),
            pw.Text(
              'No hay datos registrados para este reporte.',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey700,
              ),
            ),
          ];
        }

        return <pw.Widget>[
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF23384A),
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.3),
            cellPadding: const pw.EdgeInsets.all(4),
            cellAlignment: pw.Alignment.centerLeft,
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF4F7FA),
            ),
          ),
        ];
      },
    );
  }

  String _estadoMatriz(MatrizIpercModel m) {
    final String estado = _textoSeguro(m.estadoMatriz ?? '').trim();

    if (estado.isEmpty || estado.toLowerCase() == 'true') {
      return m.activo ? 'Vigente' : 'Inactiva';
    }

    return estado;
  }

  String _estadoDetalle(DetalleIpercModel d) {
    final String estado = _textoSeguro(d.estadoImplementacionNombre).trim();

    if (estado.isEmpty) {
      return 'Pendiente';
    }

    if (estado.toLowerCase() == 'enproceso') {
      return 'En proceso';
    }

    return estado;
  }

  String _fecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    final String d = fecha.day.toString().padLeft(2, '0');
    final String m = fecha.month.toString().padLeft(2, '0');

    return '$d/$m/${fecha.year}';
  }

  String _textoSeguro(String valor) {
    String texto = valor;

    if (texto.contains('\u00C3') || texto.contains('\u00C2')) {
      try {
        texto = utf8.decode(latin1.encode(texto), allowMalformed: false);
      } catch (_) {}
    }

    return texto;
  }
}

class _ResumenCard {
  const _ResumenCard(this.titulo, this.valor, this.color);

  final String titulo;
  final String valor;
  final PdfColor color;
}

class _CircularChartData {
  const _CircularChartData({
    required this.titulo,
    required this.valor,
    required this.total,
    required this.color,
    this.porcentajeExplicito = false,
  });

  final String titulo;
  final double valor;
  final double total;
  final PdfColor color;
  final bool porcentajeExplicito;
}
