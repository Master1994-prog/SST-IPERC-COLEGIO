import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/control_model.dart';
import '../models/detalle_iperc_model.dart';
import '../models/evaluacion_riesgo_model.dart';
import '../models/matriz_iperc_model.dart';
import '../models/seguimiento_iperc_model.dart';

class ReporteExportService {
  // =============================================================
  // MATRICES IPERC - PDF
  // =============================================================

  Future<Uint8List> generarPdfMatrices(List<MatrizIpercModel> matrices) async {
    final pw.Document documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _encabezadoPdf(
          'REPORTE DE MATRICES IPERC',
          'Sistema de Seguridad y Salud en el Trabajo',
        ),
        footer: _piePdf,
        build: (_) {
          if (matrices.isEmpty) {
            return <pw.Widget>[
              _sinDatosPdf('No hay matrices IPERC registradas.'),
            ];
          }

          return <pw.Widget>[
            _tituloSeccionPdf('Matrices registradas'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total de matrices: ${matrices.length}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                'Código',
                'Nombre',
                'Institución',
                'Área',
                'Actividad',
                'Versión',
                'Estado',
                'Fecha evaluación',
              ],
              data: matrices.map((MatrizIpercModel matriz) {
                return <String>[
                  matriz.codigo,
                  matriz.nombre,
                  matriz.institucionVisible,
                  matriz.areaVisible,
                  matriz.actividadVisible,
                  matriz.version?.toString() ?? '-',
                  _estadoMatriz(matriz),
                  _formatearFecha(matriz.fechaEvaluacion),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return documento.save();
  }

  // =============================================================
  // MATRICES IPERC - EXCEL
  // =============================================================

  Uint8List generarExcelMatrices(List<MatrizIpercModel> matrices) {
    final Excel excel = Excel.createExcel();

    const String nombreHoja = 'Matrices IPERC';

    final Sheet hoja = excel[nombreHoja];

    _eliminarSheetInicial(excel);

    hoja.frozenRows = 1;

    const List<String> encabezados = <String>[
      'Código',
      'Nombre',
      'Institución',
      'Área',
      'Actividad',
      'Versión',
      'Estado',
      'Objetivo',
      'Alcance',
      'Fecha evaluación',
      'Fecha revisión',
      'Fecha aprobación',
      'Fecha registro',
    ];

    _crearEncabezadosExcel(hoja, encabezados);

    for (final MatrizIpercModel matriz in matrices) {
      hoja.appendRow(<CellValue>[
        TextCellValue(matriz.codigo),
        TextCellValue(matriz.nombre),
        TextCellValue(matriz.institucionVisible),
        TextCellValue(matriz.areaVisible),
        TextCellValue(matriz.actividadVisible),
        TextCellValue(matriz.version?.toString() ?? '-'),
        TextCellValue(_estadoMatriz(matriz)),
        TextCellValue(_textoOpcional(matriz.objetivo)),
        TextCellValue(_textoOpcional(matriz.alcance)),
        TextCellValue(_formatearFecha(matriz.fechaEvaluacion)),
        TextCellValue(_formatearFecha(matriz.fechaRevision)),
        TextCellValue(_formatearFecha(matriz.fechaAprobacion)),
        TextCellValue(_formatearFecha(matriz.fechaRegistro)),
      ]);
    }

    hoja.setColumnWidth(0, 18);
    hoja.setColumnWidth(1, 32);
    hoja.setColumnWidth(2, 30);
    hoja.setColumnWidth(3, 25);
    hoja.setColumnWidth(4, 30);
    hoja.setColumnWidth(5, 12);
    hoja.setColumnWidth(6, 16);
    hoja.setColumnWidth(7, 40);
    hoja.setColumnWidth(8, 40);
    hoja.setColumnWidth(9, 20);
    hoja.setColumnWidth(10, 20);
    hoja.setColumnWidth(11, 20);
    hoja.setColumnWidth(12, 20);

    return _guardarExcel(excel, 'No se pudo generar el Excel de matrices.');
  }

  // =============================================================
  // CONTROLES SST - PDF
  // =============================================================

  Future<Uint8List> generarPdfControles(List<ControlModel> controles) async {
    final pw.Document documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _encabezadoPdf(
          'REPORTE DE CONTROLES SST',
          'Sistema de Seguridad y Salud en el Trabajo',
        ),
        footer: _piePdf,
        build: (_) {
          if (controles.isEmpty) {
            return <pw.Widget>[
              _sinDatosPdf('No hay controles SST registrados.'),
            ];
          }

          return <pw.Widget>[
            _tituloSeccionPdf('Controles registrados'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total de controles: ${controles.length}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                'Código',
                'Nombre',
                'Clasificación',
                'Descripción',
                'Activo',
                'Estado',
                'Fecha registro',
                'Actualización',
              ],
              data: controles.map((ControlModel control) {
                return <String>[
                  control.codigo.isEmpty ? '-' : control.codigo,
                  control.nombre,
                  control.clasificacionVisible,
                  control.descripcionVisible,
                  control.activo ? 'Sí' : 'No',
                  control.estado ? 'Vigente' : 'Inactivo',
                  _formatearFecha(control.fechaRegistro),
                  _formatearFecha(control.fechaActualizacion),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return documento.save();
  }

  // =============================================================
  // CONTROLES SST - EXCEL
  // =============================================================

  Uint8List generarExcelControles(List<ControlModel> controles) {
    final Excel excel = Excel.createExcel();

    final Sheet hoja = excel['Controles SST'];

    _eliminarSheetInicial(excel);

    hoja.frozenRows = 1;

    const List<String> encabezados = <String>[
      'Código',
      'Nombre',
      'Clasificación',
      'Descripción',
      'Activo',
      'Estado',
      'Fecha registro',
      'Última actualización',
    ];

    _crearEncabezadosExcel(hoja, encabezados);

    for (final ControlModel control in controles) {
      hoja.appendRow(<CellValue>[
        TextCellValue(control.codigo.isEmpty ? '-' : control.codigo),
        TextCellValue(control.nombre),
        TextCellValue(control.clasificacionVisible),
        TextCellValue(control.descripcionVisible),
        TextCellValue(control.activo ? 'Sí' : 'No'),
        TextCellValue(control.estado ? 'Vigente' : 'Inactivo'),
        TextCellValue(_formatearFecha(control.fechaRegistro)),
        TextCellValue(_formatearFecha(control.fechaActualizacion)),
      ]);
    }

    hoja.setColumnWidth(0, 18);
    hoja.setColumnWidth(1, 34);
    hoja.setColumnWidth(2, 28);
    hoja.setColumnWidth(3, 50);
    hoja.setColumnWidth(4, 12);
    hoja.setColumnWidth(5, 16);
    hoja.setColumnWidth(6, 20);
    hoja.setColumnWidth(7, 22);

    return _guardarExcel(excel, 'No se pudo generar el Excel de controles.');
  }

  // =============================================================
  // SEGUIMIENTOS IPERC - PDF
  // =============================================================

  Future<Uint8List> generarPdfSeguimientos(
    List<SeguimientoIpercModel> seguimientos,
  ) async {
    final pw.Document documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _encabezadoPdf(
          'REPORTE DE SEGUIMIENTOS IPERC',
          'Seguimiento de medidas y acciones SST',
        ),
        footer: _piePdf,
        build: (_) {
          if (seguimientos.isEmpty) {
            return <pw.Widget>[
              _sinDatosPdf('No hay seguimientos IPERC registrados.'),
            ];
          }

          final int verificados = seguimientos
              .where((SeguimientoIpercModel e) => e.verificado)
              .length;

          final int pendientes = seguimientos.length - verificados;

          return <pw.Widget>[
            _tituloSeccionPdf('Resumen'),
            pw.SizedBox(height: 8),
            pw.Row(
              children: <pw.Widget>[
                pw.Expanded(
                  child: _tarjetaResumenPdf(
                    titulo: 'Total',
                    cantidad: seguimientos.length,
                    color: PdfColors.blueGrey200,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _tarjetaResumenPdf(
                    titulo: 'Pendientes',
                    cantidad: pendientes,
                    color: PdfColors.amber400,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _tarjetaResumenPdf(
                    titulo: 'Verificados',
                    cantidad: verificados,
                    color: PdfColors.green400,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _tituloSeccionPdf('Seguimientos registrados'),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                'Detalle IPERC',
                'Fecha',
                'Responsable',
                'Descripción',
                'Avance',
                'Estado',
                'Verificación',
                'Observaciones',
              ],
              data: seguimientos.map((SeguimientoIpercModel seguimiento) {
                return <String>[
                  seguimiento.detalleVisible,
                  _formatearFecha(seguimiento.fechaSeguimiento),
                  _usuarioSeguimiento(seguimiento),
                  seguimiento.descripcion.isEmpty
                      ? '-'
                      : seguimiento.descripcion,
                  '${_formatearPorcentaje(seguimiento.porcentajeAvance)}%',
                  seguimiento.estadoVisible,
                  _formatearFecha(seguimiento.fechaVerificacion),
                  _textoOpcional(seguimiento.observaciones),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    return documento.save();
  }

  // =============================================================
  // SEGUIMIENTOS IPERC - EXCEL
  // =============================================================

  Uint8List generarExcelSeguimientos(List<SeguimientoIpercModel> seguimientos) {
    final Excel excel = Excel.createExcel();

    final Sheet hoja = excel['Seguimientos IPERC'];

    _eliminarSheetInicial(excel);

    hoja.frozenRows = 1;

    const List<String> encabezados = <String>[
      'ID',
      'Detalle IPERC',
      'Fecha seguimiento',
      'Responsable',
      'Descripción',
      'Porcentaje avance',
      'Estado',
      'Fecha verificación',
      'Observaciones',
      'Archivo',
    ];

    _crearEncabezadosExcel(hoja, encabezados);

    for (final SeguimientoIpercModel seguimiento in seguimientos) {
      hoja.appendRow(<CellValue>[
        IntCellValue(seguimiento.id),
        TextCellValue(seguimiento.detalleVisible),
        TextCellValue(_formatearFecha(seguimiento.fechaSeguimiento)),
        TextCellValue(_usuarioSeguimiento(seguimiento)),
        TextCellValue(
          seguimiento.descripcion.isEmpty ? '-' : seguimiento.descripcion,
        ),
        DoubleCellValue(seguimiento.porcentajeAvance),
        TextCellValue(seguimiento.estadoVisible),
        TextCellValue(_formatearFecha(seguimiento.fechaVerificacion)),
        TextCellValue(_textoOpcional(seguimiento.observaciones)),
        TextCellValue(_textoOpcional(seguimiento.nombreArchivo)),
      ]);
    }

    hoja.setColumnWidth(0, 10);
    hoja.setColumnWidth(1, 35);
    hoja.setColumnWidth(2, 20);
    hoja.setColumnWidth(3, 28);
    hoja.setColumnWidth(4, 50);
    hoja.setColumnWidth(5, 20);
    hoja.setColumnWidth(6, 16);
    hoja.setColumnWidth(7, 20);
    hoja.setColumnWidth(8, 45);
    hoja.setColumnWidth(9, 30);

    return _guardarExcel(excel, 'No se pudo generar el Excel de seguimientos.');
  }

  // =============================================================
  // EVALUACIÓN DE RIESGOS - PDF
  // =============================================================

  Future<Uint8List> generarPdfEvaluacionRiesgos(
    List<EvaluacionRiesgoModel> evaluaciones,
  ) async {
    final pw.Document documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _encabezadoPdf(
          'REPORTE DE EVALUACIÓN DE RIESGOS IPERC',
          'Matriz de evaluación de riesgos 5 x 5',
        ),
        footer: _piePdf,
        build: (_) {
          final _ConteoNiveles conteo = _contarEvaluaciones(evaluaciones);

          return <pw.Widget>[
            _tituloSeccionPdf('Resumen de evaluaciones'),
            pw.SizedBox(height: 8),
            _filaResumenRiesgosPdf(conteo),
            pw.SizedBox(height: 20),
            _tituloSeccionPdf('Matriz de riesgo 5 x 5'),
            pw.SizedBox(height: 8),
            _construirMatrizRiesgoPdf(),
            pw.SizedBox(height: 20),
            _tituloSeccionPdf('Evaluaciones registradas'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total: ${evaluaciones.length}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            if (evaluaciones.isEmpty)
              _sinDatosPdf('No hay evaluaciones de riesgo registradas.')
            else
              pw.TableHelper.fromTextArray(
                headers: const <String>[
                  'ID',
                  'Probabilidad',
                  'Severidad',
                  'Valor',
                  'Nivel',
                  'Aceptable',
                  'Requiere acción',
                  'Observaciones',
                ],
                data: evaluaciones.map((EvaluacionRiesgoModel evaluacion) {
                  return <String>[
                    evaluacion.id.toString(),
                    _probabilidadVisible(evaluacion.probabilidadId),
                    _severidadVisible(evaluacion.severidadId),
                    evaluacion.valor.toString(),
                    _nivelVisible(evaluacion.valor),
                    evaluacion.esAceptable ? 'Sí' : 'No',
                    evaluacion.requiereAccion ? 'Sí' : 'No',
                    _textoOpcional(evaluacion.observaciones),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.centerLeft,
              ),
          ];
        },
      ),
    );

    return documento.save();
  }

  // =============================================================
  // EVALUACIÓN DE RIESGOS - EXCEL
  // =============================================================

  Uint8List generarExcelEvaluacionRiesgos(
    List<EvaluacionRiesgoModel> evaluaciones,
  ) {
    final Excel excel = Excel.createExcel();

    final Sheet evaluacionesHoja = excel['Evaluaciones'];

    final Sheet matrizHoja = excel['Matriz 5x5'];

    final Sheet resumenHoja = excel['Resumen'];

    _eliminarSheetInicial(excel);

    // -----------------------------------------------------------
    // EVALUACIONES
    // -----------------------------------------------------------

    evaluacionesHoja.frozenRows = 1;

    const List<String> encabezados = <String>[
      'ID',
      'Probabilidad',
      'Severidad',
      'Valor',
      'Nivel de riesgo',
      'Aceptable',
      'Requiere acción',
      'Observaciones',
    ];

    _crearEncabezadosExcel(evaluacionesHoja, encabezados);

    int filaEvaluacion = 1;

    for (final EvaluacionRiesgoModel evaluacion in evaluaciones) {
      final CellStyle estiloNivel = _estiloExcelNivel(evaluacion.valor);

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaEvaluacion),
        IntCellValue(evaluacion.id),
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaEvaluacion),
        TextCellValue(_probabilidadVisible(evaluacion.probabilidadId)),
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: filaEvaluacion),
        TextCellValue(_severidadVisible(evaluacion.severidadId)),
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaEvaluacion),
        IntCellValue(evaluacion.valor),
        cellStyle: estiloNivel,
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaEvaluacion),
        TextCellValue(_nivelVisible(evaluacion.valor)),
        cellStyle: estiloNivel,
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: filaEvaluacion),
        TextCellValue(evaluacion.esAceptable ? 'Sí' : 'No'),
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: filaEvaluacion),
        TextCellValue(evaluacion.requiereAccion ? 'Sí' : 'No'),
      );

      evaluacionesHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: filaEvaluacion),
        TextCellValue(_textoOpcional(evaluacion.observaciones)),
      );

      filaEvaluacion++;
    }

    evaluacionesHoja.setColumnWidth(0, 10);
    evaluacionesHoja.setColumnWidth(1, 25);
    evaluacionesHoja.setColumnWidth(2, 25);
    evaluacionesHoja.setColumnWidth(3, 12);
    evaluacionesHoja.setColumnWidth(4, 20);
    evaluacionesHoja.setColumnWidth(5, 14);
    evaluacionesHoja.setColumnWidth(6, 18);
    evaluacionesHoja.setColumnWidth(7, 45);

    // -----------------------------------------------------------
    // MATRIZ 5 X 5
    // -----------------------------------------------------------

    final CellStyle estiloCabeceraMatriz = _estiloCabeceraExcel();

    final CellStyle estiloProbabilidad = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('CFD8DC'),
      fontColorHex: ExcelColor.fromHexString('000000'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    matrizHoja.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      TextCellValue('Probabilidad / Severidad'),
      cellStyle: estiloCabeceraMatriz,
    );

    for (int severidad = 1; severidad <= 5; severidad++) {
      matrizHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: severidad, rowIndex: 0),
        TextCellValue(_severidadVisible(severidad)),
        cellStyle: estiloCabeceraMatriz,
      );
    }

    for (int probabilidad = 1; probabilidad <= 5; probabilidad++) {
      matrizHoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: probabilidad),
        TextCellValue(_probabilidadVisible(probabilidad)),
        cellStyle: estiloProbabilidad,
      );

      for (int severidad = 1; severidad <= 5; severidad++) {
        final int valor = probabilidad * severidad;

        matrizHoja.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: severidad,
            rowIndex: probabilidad,
          ),
          TextCellValue('$valor - ${_nivelVisible(valor)}'),
          cellStyle: _estiloExcelNivel(valor),
        );
      }
    }

    matrizHoja.setColumnWidth(0, 30);

    for (int columna = 1; columna <= 5; columna++) {
      matrizHoja.setColumnWidth(columna, 22);
    }

    matrizHoja.frozenRows = 1;
    matrizHoja.frozenColumns = 1;

    // -----------------------------------------------------------
    // RESUMEN
    // -----------------------------------------------------------

    final _ConteoNiveles conteo = _contarEvaluaciones(evaluaciones);

    _crearResumenRiesgoExcel(resumenHoja, conteo);

    _agregarGraficosResumen(resumenHoja);

    return _guardarExcel(
      excel,
      'No se pudo generar el Excel de evaluación de riesgos.',
    );
  }

  // =============================================================
  // MAPAS DE RIESGO - PDF
  // =============================================================

  Future<Uint8List> generarPdfMapasRiesgo({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
  }) async {
    final pw.Document documento = pw.Document();

    final _ConteoNiveles conteo = _contarDetalles(detalles);

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _encabezadoPdf(
          'REPORTE DE MAPAS DE RIESGO',
          'Riesgos identificados por área y matriz IPERC',
        ),
        footer: _piePdf,
        build: (_) {
          if (matrices.isEmpty) {
            return <pw.Widget>[
              _sinDatosPdf(
                'No existen matrices para construir el mapa de riesgos.',
              ),
            ];
          }

          final List<pw.Widget> contenido = <pw.Widget>[
            _tituloSeccionPdf('Resumen general'),
            pw.SizedBox(height: 8),
            _filaResumenRiesgosPdf(conteo, incluirSinEvaluar: true),
            pw.SizedBox(height: 20),
          ];

          final List<MatrizIpercModel> matricesOrdenadas =
              List<MatrizIpercModel>.from(matrices);

          matricesOrdenadas.sort((MatrizIpercModel a, MatrizIpercModel b) {
            final int mayorA = _riesgoMayorMatriz(a.id, detalles);

            final int mayorB = _riesgoMayorMatriz(b.id, detalles);

            return mayorB.compareTo(mayorA);
          });

          for (final MatrizIpercModel matriz in matricesOrdenadas) {
            final List<DetalleIpercModel> detallesMatriz = detalles
                .where(
                  (DetalleIpercModel detalle) =>
                      detalle.matrizIpercId == matriz.id,
                )
                .toList();

            contenido.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  border: pw.Border.all(color: PdfColors.blueGrey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      matriz.areaVisible,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${matriz.codigo} - ${matriz.nombre}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            );

            contenido.add(pw.SizedBox(height: 6));

            if (detallesMatriz.isEmpty) {
              contenido.add(
                _sinDatosPdf('Esta zona todavía no tiene riesgos registrados.'),
              );
            } else {
              contenido.add(_tablaMapaPdf(matriz, detallesMatriz));
            }

            contenido.add(pw.SizedBox(height: 16));
          }

          return contenido;
        },
      ),
    );

    return documento.save();
  }

  // =============================================================
  // MAPAS DE RIESGO - EXCEL
  // =============================================================

  Uint8List generarExcelMapasRiesgo({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
  }) {
    final Excel excel = Excel.createExcel();

    final Sheet hoja = excel['Mapa de Riesgos'];

    final Sheet resumen = excel['Resumen'];

    _eliminarSheetInicial(excel);

    hoja.frozenRows = 1;

    const List<String> encabezados = <String>[
      'Área',
      'Código matriz',
      'Matriz IPERC',
      'Item',
      'Tarea',
      'Peligro',
      'Consecuencia',
      'Probabilidad',
      'Severidad',
      'Valor',
      'Nivel de riesgo',
      'Evaluación utilizada',
      'Aceptable',
      'Requiere acción',
      'Estado implementación',
    ];

    _crearEncabezadosExcel(hoja, encabezados);

    int fila = 1;

    for (final MatrizIpercModel matriz in matrices) {
      final Iterable<DetalleIpercModel> detallesMatriz = detalles.where(
        (DetalleIpercModel detalle) => detalle.matrizIpercId == matriz.id,
      );

      for (final DetalleIpercModel detalle in detallesMatriz) {
        final EvaluacionDetalleIpercModel evaluacion =
            detalle.evaluacionResidual ?? detalle.evaluacionInicial;

        final String tipoEvaluacion = detalle.evaluacionResidual != null
            ? 'Residual'
            : 'Inicial';

        final CellStyle estilo = _estiloExcelNivelPorNombre(
          evaluacion.nivelRiesgoNombre,
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: fila),
          TextCellValue(matriz.areaVisible),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: fila),
          TextCellValue(matriz.codigo),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: fila),
          TextCellValue(matriz.nombre),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: fila),
          IntCellValue(detalle.item),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: fila),
          TextCellValue(detalle.tarea),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: fila),
          TextCellValue(detalle.peligroVisible),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: fila),
          TextCellValue(detalle.consecuenciaVisible),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: fila),
          TextCellValue(
            '${evaluacion.valorProbabilidad} - '
            '${evaluacion.probabilidadNombre}',
          ),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: fila),
          TextCellValue(
            '${evaluacion.valorSeveridad} - '
            '${evaluacion.severidadNombre}',
          ),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: fila),
          IntCellValue(evaluacion.valorRiesgo),
          cellStyle: estilo,
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: fila),
          TextCellValue(_nivelDetalleVisible(evaluacion)),
          cellStyle: estilo,
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: fila),
          TextCellValue(tipoEvaluacion),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: fila),
          TextCellValue(evaluacion.esAceptable ? 'Sí' : 'No'),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: fila),
          TextCellValue(evaluacion.requiereAccion ? 'Sí' : 'No'),
        );

        hoja.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: fila),
          TextCellValue(
            detalle.estadoImplementacionNombre.trim().isEmpty
                ? EstadoImplementacionIperc.obtenerNombre(
                    detalle.estadoImplementacionId,
                  )
                : detalle.estadoImplementacionNombre,
          ),
        );

        fila++;
      }
    }

    hoja.setColumnWidth(0, 25);
    hoja.setColumnWidth(1, 18);
    hoja.setColumnWidth(2, 30);
    hoja.setColumnWidth(3, 10);
    hoja.setColumnWidth(4, 35);
    hoja.setColumnWidth(5, 35);
    hoja.setColumnWidth(6, 40);
    hoja.setColumnWidth(7, 25);
    hoja.setColumnWidth(8, 25);
    hoja.setColumnWidth(9, 12);
    hoja.setColumnWidth(10, 20);
    hoja.setColumnWidth(11, 20);
    hoja.setColumnWidth(12, 14);
    hoja.setColumnWidth(13, 18);
    hoja.setColumnWidth(14, 24);

    final _ConteoNiveles conteo = _contarDetalles(detalles);

    _crearResumenRiesgoExcel(resumen, conteo, incluirSinEvaluar: true);

    _agregarGraficosResumen(resumen, incluirSinEvaluar: true);

    return _guardarExcel(
      excel,
      'No se pudo generar el Excel del mapa de riesgos.',
    );
  }

  // =============================================================
  // TABLA MAPA DE RIESGO PDF
  // =============================================================

  static pw.Widget _tablaMapaPdf(
    MatrizIpercModel matriz,
    List<DetalleIpercModel> detalles,
  ) {
    final List<pw.TableRow> filas = <pw.TableRow>[
      pw.TableRow(
        children: <pw.Widget>[
          _celdaCabeceraPdf('Item'),
          _celdaCabeceraPdf('Tarea'),
          _celdaCabeceraPdf('Peligro'),
          _celdaCabeceraPdf('Consecuencia'),
          _celdaCabeceraPdf('Valor'),
          _celdaCabeceraPdf('Nivel'),
          _celdaCabeceraPdf('Evaluación'),
        ],
      ),
    ];

    for (final DetalleIpercModel detalle in detalles) {
      final EvaluacionDetalleIpercModel evaluacion =
          detalle.evaluacionResidual ?? detalle.evaluacionInicial;

      final PdfColor fondo = _colorPdfNivelPorNombre(
        evaluacion.nivelRiesgoNombre,
      );

      final PdfColor texto = _colorTextoPdfPorNombre(
        evaluacion.nivelRiesgoNombre,
      );

      filas.add(
        pw.TableRow(
          children: <pw.Widget>[
            _celdaMapaPdf(detalle.item.toString()),
            _celdaMapaPdf(detalle.tarea),
            _celdaMapaPdf(detalle.peligroVisible),
            _celdaMapaPdf(detalle.consecuenciaVisible),
            _celdaMapaPdf(
              evaluacion.valorRiesgo.toString(),
              colorFondo: fondo,
              colorTexto: texto,
              negrita: true,
            ),
            _celdaMapaPdf(
              _nivelDetalleVisible(evaluacion),
              colorFondo: fondo,
              colorTexto: texto,
              negrita: true,
            ),
            _celdaMapaPdf(
              detalle.evaluacionResidual != null ? 'Residual' : 'Inicial',
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(0.8),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(1.0),
      },
      children: filas,
    );
  }

  // =============================================================
  // MATRIZ 5 X 5 PDF
  // =============================================================

  static pw.Widget _construirMatrizRiesgoPdf() {
    final List<pw.TableRow> filas = <pw.TableRow>[];

    filas.add(
      pw.TableRow(
        children: <pw.Widget>[
          _celdaPdf(
            'Probabilidad /\nSeveridad',
            colorFondo: PdfColors.blueGrey700,
            colorTexto: PdfColors.white,
            negrita: true,
          ),
          for (int severidad = 1; severidad <= 5; severidad++)
            _celdaPdf(
              _severidadVisible(severidad),
              colorFondo: PdfColors.blueGrey700,
              colorTexto: PdfColors.white,
              negrita: true,
            ),
        ],
      ),
    );

    for (int probabilidad = 5; probabilidad >= 1; probabilidad--) {
      filas.add(
        pw.TableRow(
          children: <pw.Widget>[
            _celdaPdf(
              _probabilidadVisible(probabilidad),
              colorFondo: PdfColors.blueGrey100,
              negrita: true,
            ),
            for (int severidad = 1; severidad <= 5; severidad++)
              _celdaRiesgoPdf(probabilidad * severidad),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.7),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1.8),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
        4: pw.FlexColumnWidth(),
        5: pw.FlexColumnWidth(),
      },
      children: filas,
    );
  }

  // =============================================================
  // RESÚMENES PDF
  // =============================================================

  static pw.Widget _filaResumenRiesgosPdf(
    _ConteoNiveles conteo, {
    bool incluirSinEvaluar = false,
  }) {
    final List<pw.Widget> elementos = <pw.Widget>[
      pw.Expanded(
        child: _tarjetaResumenPdf(
          titulo: 'Bajo',
          cantidad: conteo.bajo,
          color: PdfColors.green400,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: _tarjetaResumenPdf(
          titulo: 'Medio',
          cantidad: conteo.medio,
          color: PdfColors.amber400,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: _tarjetaResumenPdf(
          titulo: 'Alto',
          cantidad: conteo.alto,
          color: PdfColors.orange500,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: _tarjetaResumenPdf(
          titulo: 'Crítico',
          cantidad: conteo.critico,
          color: PdfColors.red500,
          textoBlanco: true,
        ),
      ),
    ];

    if (incluirSinEvaluar) {
      elementos.add(pw.SizedBox(width: 6));

      elementos.add(
        pw.Expanded(
          child: _tarjetaResumenPdf(
            titulo: 'Sin evaluar',
            cantidad: conteo.sinEvaluar,
            color: PdfColors.grey400,
          ),
        ),
      );
    }

    return pw.Row(children: elementos);
  }

  static pw.Widget _tarjetaResumenPdf({
    required String titulo,
    required int cantidad,
    required PdfColor color,
    bool textoBlanco = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: <pw.Widget>[
          pw.Text(
            titulo,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: textoBlanco ? PdfColors.white : PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            cantidad.toString(),
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: textoBlanco ? PdfColors.white : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // EXCEL - RESUMEN Y GRÁFICOS
  // =============================================================

  static void _crearResumenRiesgoExcel(
    Sheet hoja,
    _ConteoNiveles conteo, {
    bool incluirSinEvaluar = false,
  }) {
    final CellStyle cabecera = _estiloCabeceraExcel();

    hoja.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue('Nivel de riesgo'),
      cellStyle: cabecera,
    );

    hoja.updateCell(
      CellIndex.indexByString('B1'),
      TextCellValue('Cantidad'),
      cellStyle: cabecera,
    );

    final List<_FilaResumen> filas = <_FilaResumen>[
      _FilaResumen(nombre: 'Bajo', cantidad: conteo.bajo, valorEstilo: 1),
      _FilaResumen(nombre: 'Medio', cantidad: conteo.medio, valorEstilo: 5),
      _FilaResumen(nombre: 'Alto', cantidad: conteo.alto, valorEstilo: 10),
      _FilaResumen(
        nombre: 'Crítico',
        cantidad: conteo.critico,
        valorEstilo: 20,
      ),
    ];

    if (incluirSinEvaluar) {
      filas.add(
        _FilaResumen(
          nombre: 'Sin evaluar',
          cantidad: conteo.sinEvaluar,
          valorEstilo: 0,
        ),
      );
    }

    for (int index = 0; index < filas.length; index++) {
      final int row = index + 1;
      final _FilaResumen item = filas[index];

      final CellStyle estilo = item.valorEstilo == 0
          ? _estiloExcelSinEvaluar()
          : _estiloExcelNivel(item.valorEstilo);

      hoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        TextCellValue(item.nombre),
        cellStyle: estilo,
      );

      hoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        IntCellValue(item.cantidad),
        cellStyle: estilo,
      );
    }

    hoja.setColumnWidth(0, 22);
    hoja.setColumnWidth(1, 15);
  }

  static void _agregarGraficosResumen(
    Sheet hoja, {
    bool incluirSinEvaluar = false,
  }) {
    final int ultimaFila = incluirSinEvaluar ? 6 : 5;

    final ColumnChart barras = ColumnChart(
      title: 'Cantidad por nivel de riesgo',
      series: <ChartSeries>[
        ChartSeries(
          name: 'Cantidad',
          categoriesRange: 'Resumen!\$A\$2:\$A\$$ultimaFila',
          valuesRange: 'Resumen!\$B\$2:\$B\$$ultimaFila',
        ),
      ],
      anchor: ChartAnchor.at(column: 3, row: 1, width: 10, height: 15),
      showLegend: false,
    );

    hoja.addChart(barras);

    final PieChart circular = PieChart(
      title: 'Distribución de riesgos',
      series: <ChartSeries>[
        ChartSeries(
          name: 'Distribución',
          categoriesRange: 'Resumen!\$A\$2:\$A\$$ultimaFila',
          valuesRange: 'Resumen!\$B\$2:\$B\$$ultimaFila',
        ),
      ],
      anchor: ChartAnchor.at(column: 3, row: 18, width: 10, height: 15),
      showLegend: true,
    );

    hoja.addChart(circular);
  }

  // =============================================================
  // CELDAS PDF
  // =============================================================

  static pw.Widget _celdaRiesgoPdf(int valor) {
    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    return _celdaPdf(
      '$valor\n${nivel.nombre}',
      colorFondo: _colorPdfNivel(valor),
      colorTexto: _colorTextoPdfNivel(valor),
      negrita: true,
    );
  }

  static pw.Widget _celdaPdf(
    String texto, {
    PdfColor colorFondo = PdfColors.white,
    PdfColor colorTexto = PdfColors.black,
    bool negrita = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: colorFondo,
      alignment: pw.Alignment.center,
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7,
          color: colorTexto,
          fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _celdaCabeceraPdf(String texto) {
    return _celdaMapaPdf(
      texto,
      colorFondo: PdfColors.blueGrey700,
      colorTexto: PdfColors.white,
      negrita: true,
    );
  }

  static pw.Widget _celdaMapaPdf(
    String texto, {
    PdfColor colorFondo = PdfColors.white,
    PdfColor colorTexto = PdfColors.black,
    bool negrita = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      color: colorFondo,
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 6.5,
          color: colorTexto,
          fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // =============================================================
  // ENCABEZADO / PIE PDF
  // =============================================================

  static pw.Widget _encabezadoPdf(String titulo, String subtitulo) {
    final DateFormat formato = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          titulo,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Fecha de generación: '
          '${formato.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.Divider(color: PdfColors.blueGrey400),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _piePdf(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Página ${context.pageNumber} '
        'de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  static pw.Widget _tituloSeccionPdf(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _sinDatosPdf(String mensaje) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Text(mensaje),
    );
  }

  // =============================================================
  // ESTILOS EXCEL
  // =============================================================

  static CellStyle _estiloCabeceraExcel() {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('455A64'),
      fontColorHex: ExcelColor.fromHexString('FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
  }

  static void _crearEncabezadosExcel(Sheet hoja, List<String> encabezados) {
    final CellStyle estilo = _estiloCabeceraExcel();

    for (int columna = 0; columna < encabezados.length; columna++) {
      hoja.updateCell(
        CellIndex.indexByColumnRow(columnIndex: columna, rowIndex: 0),
        TextCellValue(encabezados[columna]),
        cellStyle: estilo,
      );
    }
  }

  static CellStyle _estiloExcelNivel(int valor) {
    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    return _estiloExcelNivelPorNombre(nivel.nombre);
  }

  static CellStyle _estiloExcelNivelPorNombre(String nivel) {
    late ExcelColor fondo;

    ExcelColor texto = ExcelColor.fromHexString('000000');

    switch (nivel.toLowerCase().trim()) {
      case 'bajo':
        fondo = ExcelColor.fromHexString('4CAF50');
        break;

      case 'medio':
        fondo = ExcelColor.fromHexString('FFC107');
        break;

      case 'alto':
        fondo = ExcelColor.fromHexString('FF9800');
        break;

      case 'crítico':
      case 'critico':
        fondo = ExcelColor.fromHexString('F44336');

        texto = ExcelColor.fromHexString('FFFFFF');
        break;

      default:
        fondo = ExcelColor.fromHexString('E0E0E0');
    }

    return CellStyle(
      bold: true,
      backgroundColorHex: fondo,
      fontColorHex: texto,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
  }

  static CellStyle _estiloExcelSinEvaluar() {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('BDBDBD'),
      fontColorHex: ExcelColor.fromHexString('000000'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  // =============================================================
  // COLORES PDF
  // =============================================================

  static PdfColor _colorPdfNivel(int valor) {
    return _colorPdfNivelPorNombre(obtenerNivelRiesgoIperc(valor).nombre);
  }

  static PdfColor _colorPdfNivelPorNombre(String nombre) {
    switch (nombre.toLowerCase().trim()) {
      case 'bajo':
        return PdfColors.green400;

      case 'medio':
        return PdfColors.amber400;

      case 'alto':
        return PdfColors.orange500;

      case 'crítico':
      case 'critico':
        return PdfColors.red500;

      default:
        return PdfColors.grey400;
    }
  }

  static PdfColor _colorTextoPdfNivel(int valor) {
    return _colorTextoPdfPorNombre(obtenerNivelRiesgoIperc(valor).nombre);
  }

  static PdfColor _colorTextoPdfPorNombre(String nombre) {
    switch (nombre.toLowerCase().trim()) {
      case 'crítico':
      case 'critico':
        return PdfColors.white;

      default:
        return PdfColors.black;
    }
  }

  // =============================================================
  // CONTEOS
  // =============================================================

  static _ConteoNiveles _contarEvaluaciones(
    List<EvaluacionRiesgoModel> evaluaciones,
  ) {
    final _ConteoNiveles conteo = _ConteoNiveles();

    for (final EvaluacionRiesgoModel evaluacion in evaluaciones) {
      conteo.agregar(_nivelVisible(evaluacion.valor));
    }

    return conteo;
  }

  static _ConteoNiveles _contarDetalles(List<DetalleIpercModel> detalles) {
    final _ConteoNiveles conteo = _ConteoNiveles();

    for (final DetalleIpercModel detalle in detalles) {
      final EvaluacionDetalleIpercModel evaluacion =
          detalle.evaluacionResidual ?? detalle.evaluacionInicial;

      if (evaluacion.valorRiesgo <= 0 ||
          evaluacion.nivelRiesgoNombre.trim().isEmpty) {
        conteo.sinEvaluar++;
      } else {
        conteo.agregar(evaluacion.nivelRiesgoNombre);
      }
    }

    return conteo;
  }

  static int _riesgoMayorMatriz(
    int matrizId,
    List<DetalleIpercModel> detalles,
  ) {
    int mayor = 0;

    for (final DetalleIpercModel detalle in detalles) {
      if (detalle.matrizIpercId != matrizId) {
        continue;
      }

      if (detalle.valorRiesgoActual > mayor) {
        mayor = detalle.valorRiesgoActual;
      }
    }

    return mayor;
  }

  // =============================================================
  // UTILIDADES DE EVALUACIÓN
  // =============================================================

  static String _probabilidadVisible(int id) {
    for (final ProbabilidadIpercOption opcion in probabilidadesIperc) {
      if (opcion.id == id || opcion.valor == id) {
        return opcion.etiqueta;
      }
    }

    return 'Probabilidad $id';
  }

  static String _severidadVisible(int id) {
    for (final SeveridadIpercOption opcion in severidadesIperc) {
      if (opcion.id == id || opcion.valor == id) {
        return opcion.etiqueta;
      }
    }

    return 'Severidad $id';
  }

  static String _nivelVisible(int valor) {
    if (valor <= 0) {
      return 'Sin evaluar';
    }

    return obtenerNivelRiesgoIperc(valor).nombre;
  }

  static String _nivelDetalleVisible(EvaluacionDetalleIpercModel evaluacion) {
    final String nivel = evaluacion.nivelRiesgoNombre.trim();

    if (nivel.isNotEmpty) {
      return nivel;
    }

    if (evaluacion.valorRiesgo > 0) {
      return _nivelVisible(evaluacion.valorRiesgo);
    }

    return 'Sin evaluar';
  }

  // =============================================================
  // UTILIDADES GENERALES
  // =============================================================

  static void _eliminarSheetInicial(Excel excel) {
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
  }

  static Uint8List _guardarExcel(Excel excel, String mensajeError) {
    final List<int>? bytes = excel.save();

    if (bytes == null || bytes.isEmpty) {
      throw Exception(mensajeError);
    }

    return Uint8List.fromList(bytes);
  }

  static String _estadoMatriz(MatrizIpercModel matriz) {
    final String estado = matriz.estadoMatriz?.trim() ?? '';

    if (estado.isNotEmpty) {
      return estado;
    }

    return matriz.activo ? 'Activa' : 'Inactiva';
  }

  static String _usuarioSeguimiento(SeguimientoIpercModel seguimiento) {
    final String nombre = seguimiento.usuarioNombre?.trim() ?? '';

    if (nombre.isNotEmpty) {
      return nombre;
    }

    return 'Usuario '
        '${seguimiento.usuarioId}';
  }

  static String _formatearPorcentaje(double porcentaje) {
    if (porcentaje == porcentaje.roundToDouble()) {
      return porcentaje.toInt().toString();
    }

    return porcentaje.toStringAsFixed(1);
  }

  static String _textoOpcional(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? '-' : texto;
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}

// ===============================================================
// CLASE INTERNA - CONTEO DE RIESGOS
// ===============================================================

class _ConteoNiveles {
  int bajo = 0;
  int medio = 0;
  int alto = 0;
  int critico = 0;
  int sinEvaluar = 0;

  void agregar(String nivel) {
    switch (nivel.toLowerCase().trim()) {
      case 'bajo':
        bajo++;
        break;

      case 'medio':
        medio++;
        break;

      case 'alto':
        alto++;
        break;

      case 'crítico':
      case 'critico':
        critico++;
        break;

      default:
        sinEvaluar++;
        break;
    }
  }
}

// ===============================================================
// CLASE INTERNA - FILA RESUMEN EXCEL
// ===============================================================

class _FilaResumen {
  const _FilaResumen({
    required this.nombre,
    required this.cantidad,
    required this.valorEstilo,
  });

  final String nombre;
  final int cantidad;
  final int valorEstilo;
}
