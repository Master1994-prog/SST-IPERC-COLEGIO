import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/models/seguimiento_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../../data/datasources/local/detalle_iperc_local_datasource.dart';
import '../../../data/datasources/local/seguimiento_iperc_local_datasource.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/evaluacion_riesgo_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';
import '../../../data/repositories/usuario_repository.dart';
import '../../../data/services/reporte_dashboard_export_service.dart';
import '../../../data/services/reporte_especifico_profesional_service.dart';
import '../../../data/services/reporte_export_service.dart';

import '../controles/controles_screen.dart';
import '../iperc/matrices_iperc_screen.dart';
import '../mapas_riesgo/mapas_riesgo_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../seguimientos/seguimientos_screen.dart';

/// ===============================================================
/// REPORTES SST/IPERC - DASHBOARD EJECUTIVO
/// ===============================================================
///
/// La parte superior funciona como vista previa interactiva.
/// Debajo se conservan los reportes específicos PDF / Excel.
///
/// El informe ejecutivo permite:
/// - A4 vertical.
/// - A4 horizontal.
/// - Mixto: dashboard vertical + tablas horizontales.
/// ===============================================================
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({required this.rol, super.key});

  final String rol;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  final ControlRepository _controlRepository = ControlRepository();

  final SeguimientoIpercRepository _seguimientoRepository =
      SeguimientoIpercRepository();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final Map<int, String> _nombresUsuarios = <int, String>{};

  final SeguimientoIpercLocalDatasource _seguimientoLocalDatasource =
      SeguimientoIpercLocalDatasource();

  final EvaluacionRiesgoRepository _evaluacionRepository =
      EvaluacionRiesgoRepository();

  final ReporteExportService _reporteExportService = ReporteExportService();

  final ReporteDashboardExportService _dashboardExportService =
      ReporteDashboardExportService();

  final ReporteEspecificoProfesionalService _reporteProfesionalService =
      ReporteEspecificoProfesionalService();

  final MatrizIpercLocalDatasource _matrizLocalDatasource =
      MatrizIpercLocalDatasource();

  final DetalleIpercLocalDatasource _detalleLocalDatasource =
      DetalleIpercLocalDatasource();

  bool _cargando = true;
  String? _error;

  List<MatrizIpercModel> _matrices = <MatrizIpercModel>[];

  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];

  int _totalSeguimientos = 0;
  int _seguimientosVerificados = 0;
  double _avancePromedioSeguimientos = 0;
  int _seguimientosPendientesSincronizar = 0;

  List<SeguimientoIpercModel> _seguimientosReporte = <SeguimientoIpercModel>[];

  ReportePdfFormato _formato = ReportePdfFormato.mixto;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<List<MatrizIpercModel>> _cargarMatricesHibridas() async {
    final Map<String, MatrizIpercModel> datos = <String, MatrizIpercModel>{};

    try {
      final List<MatrizIpercModel> remotas = await _matrizRepository
          .obtenerMatrices();

      for (final MatrizIpercModel m in remotas) {
        datos['S:${m.id}'] = m;
      }
    } catch (_) {}

    try {
      final List<MatrizIpercLocalModel> locales = await _matrizLocalDatasource
          .getAll();

      for (final MatrizIpercLocalModel local in locales) {
        final int idServidor = int.tryParse(local.idServidor ?? '') ?? 0;

        final MatrizIpercModel convertido = MatrizIpercModel(
          id: idServidor,
          codigo: local.codigo?.trim().isNotEmpty == true
              ? local.codigo!
              : 'LOCAL-${local.idLocal.length <= 8 ? local.idLocal : local.idLocal.substring(0, 8)}',
          nombre: local.nombre,
          objetivo: local.descripcion,
          alcance: null,
          version: null,
          estadoMatriz: local.estadoMatriz,
          observaciones: null,
          institucionId: int.tryParse(local.institucionId),
          institucionNombre: null,
          sedeId: int.tryParse(local.sedeId ?? ''),
          areaId: int.tryParse(local.areaId ?? ''),
          areaNombre: null,
          procesoId: int.tryParse(local.procesoId ?? ''),
          actividadId: int.tryParse(local.actividadId ?? ''),
          actividadNombre: null,
          puestoTrabajoId: int.tryParse(local.puestoTrabajoId ?? ''),
          responsableId: null,
          aprobadorId: null,
          activo: !local.eliminado,
          fechaEvaluacion: local.fechaEvaluacion,
          fechaRevision: null,
          fechaAprobacion: null,
          fechaRegistro: local.fechaRegistro,
        );

        final String key = idServidor > 0
            ? 'S:$idServidor'
            : 'L:${local.idLocal}';

        datos[key] = convertido;
      }
    } catch (_) {}

    final List<MatrizIpercModel> lista = datos.values.toList();

    lista.sort(
      (MatrizIpercModel a, MatrizIpercModel b) => b.codigo.compareTo(a.codigo),
    );

    return lista;
  }

  Future<List<DetalleIpercModel>> _cargarDetallesHibridos() async {
    final Map<String, DetalleIpercModel> datos = <String, DetalleIpercModel>{};

    try {
      final List<DetalleIpercModel> remotos = await _detalleRepository
          .obtenerTodos();

      for (final DetalleIpercModel d in remotos) {
        datos['S:${d.id}'] = d;
      }
    } catch (_) {}

    final Map<String, MatrizIpercLocalModel> matricesLocales =
        <String, MatrizIpercLocalModel>{};

    try {
      for (final MatrizIpercLocalModel m
          in await _matrizLocalDatasource.getAll()) {
        matricesLocales[m.idLocal] = m;
      }

      final List<DetalleIpercLocalModel> locales = await _detalleLocalDatasource
          .listarTodos();

      for (final DetalleIpercLocalModel local in locales) {
        final int idServidor = int.tryParse(local.idServidor ?? '') ?? 0;

        final MatrizIpercLocalModel? matrizLocal =
            matricesLocales[local.matrizIdLocal];

        final int matrizServidor =
            local.matrizIdServidor ??
            int.tryParse(matrizLocal?.idServidor ?? '') ??
            0;

        final String matrizCodigo =
            matrizLocal?.codigo?.trim().isNotEmpty == true
            ? matrizLocal!.codigo!
            : 'LOCAL';

        final EvaluacionDetalleIpercModel inicial = EvaluacionDetalleIpercModel(
          id: local.evaluacionInicialId ?? 0,
          probabilidadId: local.probabilidadInicialId ?? 0,
          probabilidadNombre: '',
          valorProbabilidad: local.frecuenciaInicial,
          severidadId: local.severidadInicialId ?? 0,
          severidadNombre: '',
          valorSeveridad: local.severidadInicial,
          nivelRiesgoId: 0,
          nivelRiesgoNombre: local.nivelRiesgoInicial,
          color: '',
          valorRiesgo: local.valorRiesgoInicial,
          esAceptable: local.valorRiesgoInicial <= 9,
          requiereAccion: local.valorRiesgoInicial >= 10,
          observaciones: local.observaciones,
        );

        EvaluacionDetalleIpercModel? residual;

        if (local.tieneEvaluacionResidual) {
          residual = EvaluacionDetalleIpercModel(
            id: local.evaluacionResidualId ?? 0,
            probabilidadId: local.probabilidadResidualId ?? 0,
            probabilidadNombre: '',
            valorProbabilidad: local.frecuenciaResidual ?? 0,
            severidadId: local.severidadResidualId ?? 0,
            severidadNombre: '',
            valorSeveridad: local.severidadResidual ?? 0,
            nivelRiesgoId: 0,
            nivelRiesgoNombre: local.nivelRiesgoResidual ?? '',
            color: '',
            valorRiesgo: local.valorRiesgoResidual ?? 0,
            esAceptable: (local.valorRiesgoResidual ?? 0) <= 9,
            requiereAccion: (local.valorRiesgoResidual ?? 0) >= 10,
            observaciones: local.observaciones,
          );
        }

        final DetalleIpercModel convertido = DetalleIpercModel(
          id: idServidor,
          matrizIpercId: matrizServidor,
          matrizIpercCodigo: matrizCodigo,
          item: local.item,
          tarea: local.tarea,
          peligroId: int.tryParse(local.peligroId ?? '') ?? 0,
          peligroNombre: local.peligroDescripcion ?? 'Peligro',
          consecuenciaId: int.tryParse(local.consecuenciaId ?? '') ?? 0,
          consecuenciaNombre: local.consecuenciaDescripcion ?? 'Consecuencia',
          descripcionPeligro: local.peligroDescripcion,
          evaluacionInicialId: local.evaluacionInicialId ?? 0,
          evaluacionInicial: inicial,
          evaluacionResidualId: local.evaluacionResidualId,
          evaluacionResidual: residual,
          controlIds: local.controlIds
              .map((e) => int.tryParse(e) ?? 0)
              .where((e) => e > 0)
              .toList(),
          equipoProteccionIds: local.equipoProteccionIds
              .map((e) => int.tryParse(e) ?? 0)
              .where((e) => e > 0)
              .toList(),
          responsableImplementacionId: int.tryParse(
            local.responsableImplementacionId ?? '',
          ),
          fechaCompromiso: local.fechaCompromiso,
          fechaImplementacion: local.fechaImplementacion,
          estadoImplementacionId: 0,
          estadoImplementacionNombre: local.estadoImplementacion ?? 'Pendiente',
        );

        final String key = idServidor > 0
            ? 'S:$idServidor'
            : 'L:${local.idLocal}';

        datos[key] = convertido;
      }
    } catch (_) {}

    return datos.values.toList();
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<MatrizIpercModel> matrices = await _cargarMatricesHibridas();

      final List<DetalleIpercModel> detalles = await _cargarDetallesHibridos();

      final _SeguimientosReporteData seguimientoData =
          await _cargarSeguimientosCombinados();

      if (!mounted) {
        return;
      }

      setState(() {
        _matrices = matrices;
        _detalles = detalles;
        _seguimientosReporte = seguimientoData.seguimientos;
        _totalSeguimientos = seguimientoData.seguimientos.length;
        _seguimientosVerificados = seguimientoData.seguimientos
            .where((SeguimientoIpercModel e) => e.verificado)
            .length;
        _avancePromedioSeguimientos = seguimientoData.avancePromedio;
        _seguimientosPendientesSincronizar =
            seguimientoData.pendientesSincronizar;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _mensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  /// Carga el catálogo de usuarios para mostrar nombres reales
  /// en la columna Responsable del reporte.
  Future<void> _cargarNombresUsuarios() async {
    if (_nombresUsuarios.isNotEmpty) {
      return;
    }

    try {
      final List<UsuarioModel> usuarios = await _usuarioRepository
          .obtenerTodos();

      for (final UsuarioModel usuario in usuarios) {
        final String nombre = usuario.nombreVisible.trim();

        if (usuario.id > 0 && nombre.isNotEmpty) {
          _nombresUsuarios[usuario.id] = nombre;
        }
      }
    } catch (_) {
      // Si estamos offline, se utiliza usuarioNombre guardado
      // dentro del propio seguimiento local/remoto.
    }
  }

  String? _nombreResponsable({required int usuarioId, String? usuarioNombre}) {
    final String nombreGuardado = usuarioNombre?.trim() ?? '';

    if (nombreGuardado.isNotEmpty &&
        !nombreGuardado.toLowerCase().startsWith('usuario ')) {
      return nombreGuardado;
    }

    final String? catalogo = _nombresUsuarios[usuarioId];

    if (catalogo != null && catalogo.trim().isNotEmpty) {
      return catalogo.trim();
    }

    return nombreGuardado.isEmpty ? null : nombreGuardado;
  }

  SeguimientoIpercModel _seguimientoConNombre(SeguimientoIpercModel item) {
    final String? nombre = _nombreResponsable(
      usuarioId: item.usuarioId,
      usuarioNombre: item.usuarioNombre,
    );

    return SeguimientoIpercModel(
      id: item.id,
      detalleIpercId: item.detalleIpercId,
      detalleItem: item.detalleItem,
      detalleTarea: item.detalleTarea,
      fechaSeguimiento: item.fechaSeguimiento,
      usuarioId: item.usuarioId,
      usuarioNombre: nombre,
      descripcion: item.descripcion,
      porcentajeAvance: item.porcentajeAvance,
      verificado: item.verificado,
      fechaVerificacion: item.fechaVerificacion,
      observaciones: item.observaciones,
      archivo: item.archivo,
      nombreArchivo: item.nombreArchivo,
      tipoArchivo: item.tipoArchivo,
    );
  }

  /// Combina servidor + SQLite evitando duplicados.
  ///
  /// Si un seguimiento local ya tiene id_servidor, reemplaza al remoto
  /// porque puede contener un cambio offline mas reciente.
  Future<_SeguimientosReporteData> _cargarSeguimientosCombinados() async {
    await _cargarNombresUsuarios();

    final Map<String, SeguimientoIpercModel> unificados =
        <String, SeguimientoIpercModel>{};

    try {
      final List<SeguimientoIpercModel> remotos = await _seguimientoRepository
          .obtenerTodos();

      for (final SeguimientoIpercModel item in remotos) {
        unificados['S:${item.id}'] = _seguimientoConNombre(item);
      }
    } catch (_) {
      // El reporte puede continuar usando SQLite.
    }

    int pendientesSincronizar = 0;

    try {
      final List<SeguimientoIpercLocalModel> locales =
          await _seguimientoLocalDatasource.listarTodos();

      for (final SeguimientoIpercLocalModel local in locales) {
        if (!local.sincronizado) {
          pendientesSincronizar++;
        }

        final String key = local.idServidor != null && local.idServidor! > 0
            ? 'S:${local.idServidor}'
            : 'L:${local.idLocal}';

        unificados[key] = SeguimientoIpercModel(
          id: local.idServidor ?? 0,
          detalleIpercId: local.detalleIpercIdServidor ?? 0,
          detalleItem: local.detalleItem,
          detalleTarea: local.detalleTarea,
          fechaSeguimiento: local.fechaSeguimiento,
          usuarioId: local.usuarioId,
          usuarioNombre: _nombreResponsable(
            usuarioId: local.usuarioId,
            usuarioNombre: local.usuarioNombre,
          ),
          descripcion: local.descripcion,
          porcentajeAvance: local.porcentajeAvance,
          verificado: local.verificado,
          fechaVerificacion: local.fechaVerificacion,
          observaciones: local.observaciones,
          archivo: local.archivo,
          nombreArchivo: local.nombreArchivo,
          tipoArchivo: local.tipoArchivo,
        );
      }
    } catch (_) {
      // Si SQLite no esta disponible, se conserva lo obtenido del servidor.
    }

    final List<SeguimientoIpercModel> lista = unificados.values.toList()
      ..sort(
        (SeguimientoIpercModel a, SeguimientoIpercModel b) =>
            b.fechaSeguimiento.compareTo(a.fechaSeguimiento),
      );

    double avancePromedio = 0;

    if (lista.isNotEmpty) {
      final double suma = lista.fold<double>(
        0,
        (double total, SeguimientoIpercModel item) =>
            total + item.porcentajeAvance,
      );

      avancePromedio = suma / lista.length;
    }

    return _SeguimientosReporteData(
      seguimientos: lista,
      avancePromedio: avancePromedio,
      pendientesSincronizar: pendientesSincronizar,
    );
  }

  _DashboardResumen get _resumen {
    int bajos = 0;
    int medios = 0;
    int altos = 0;
    int criticos = 0;
    int controlados = 0;

    double inicial = 0;
    double residual = 0;
    int residualCount = 0;

    for (final DetalleIpercModel detalle in _detalles) {
      final int actual = detalle.valorRiesgoActual;

      if (actual <= 4) {
        bajos++;
      } else if (actual <= 9) {
        medios++;
      } else if (actual <= 16) {
        altos++;
      } else {
        criticos++;
      }

      inicial += detalle.evaluacionInicial.valorRiesgo;

      final int? valorResidual = detalle.evaluacionResidual?.valorRiesgo;

      if (valorResidual != null) {
        residual += valorResidual;
        residualCount++;

        if (valorResidual < detalle.evaluacionInicial.valorRiesgo) {
          controlados++;
        }
      }
    }

    final double promedioInicial = _detalles.isEmpty
        ? 0
        : inicial / _detalles.length;

    final double promedioResidual = residualCount == 0
        ? promedioInicial
        : residual / residualCount;

    final double reduccion = promedioInicial <= 0
        ? 0
        : ((promedioInicial - promedioResidual) / promedioInicial * 100)
              .clamp(0, 100)
              .toDouble();

    return _DashboardResumen(
      totalMatrices: _matrices.length,
      totalRiesgos: _detalles.length,
      bajos: bajos,
      medios: medios,
      altos: altos,
      criticos: criticos,
      controlados: controlados,
      pendientes: _detalles.length - controlados,
      promedioInicial: promedioInicial,
      promedioResidual: promedioResidual,
      reduccion: reduccion,
      totalSeguimientos: _totalSeguimientos,
      seguimientosVerificados: _seguimientosVerificados,
      avancePromedioSeguimientos: _avancePromedioSeguimientos,
      seguimientosPendientesSincronizar: _seguimientosPendientesSincronizar,
    );
  }

  Future<Uint8List> _generarEjecutivo() {
    return _dashboardExportService.generarInformeEjecutivo(
      matrices: _matrices,
      detalles: _detalles,
      formato: _formato,
      totalSeguimientos: _totalSeguimientos,
      seguimientosVerificados: _seguimientosVerificados,
    );
  }

  Future<void> _abrirVistaPreviaPdf() async {
    if (_matrices.isEmpty && _detalles.isEmpty) {
      _mensaje('No hay datos para generar el informe.');
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _VistaPreviaPdfScreen(
          titulo: 'Informe ejecutivo SST/IPERC',
          buildPdf: _generarEjecutivo,
        ),
      ),
    );
  }

  Future<void> _compartirInformeEjecutivo() async {
    try {
      _mensaje('Generando informe ejecutivo...');

      final Uint8List bytes = await _generarEjecutivo();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'informe_ejecutivo_sst_iperc.pdf',
      );
    } catch (error) {
      _mensaje(
        'No se pudo generar el informe: '
        '${_mensajeError(error)}',
        error: true,
      );
    }
  }

  Future<void> _exportarMatricesPdf() async {
    try {
      final Uint8List bytes = await _reporteProfesionalService
          .generarPdfMatrices(_matrices, formato: _formato);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_matrices_iperc.pdf',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarMatricesExcel() async {
    try {
      final Uint8List bytes = _reporteExportService.generarExcelMatrices(
        _matrices,
      );

      await _compartirExcel(
        bytes,
        'reporte_matrices_iperc.xlsx',
        'Reporte de matrices IPERC',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarEvaluacionPdf() async {
    try {
      final Uint8List bytes = await _reporteProfesionalService
          .generarPdfRiesgos(_detalles, formato: _formato);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_evaluacion_riesgos.pdf',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarEvaluacionExcel() async {
    try {
      final evaluaciones = await _evaluacionRepository.obtenerTodos();

      final Uint8List bytes = _reporteExportService
          .generarExcelEvaluacionRiesgos(evaluaciones);

      await _compartirExcel(
        bytes,
        'reporte_evaluacion_riesgos.xlsx',
        'Evaluación de riesgos IPERC',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarControlesPdf() async {
    try {
      final controles = await _controlRepository.obtenerTodos();

      final Uint8List bytes = await _reporteProfesionalService
          .generarPdfControles(controles, formato: _formato);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_controles_sst.pdf',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarControlesExcel() async {
    try {
      final controles = await _controlRepository.obtenerTodos();

      final Uint8List bytes = _reporteExportService.generarExcelControles(
        controles,
      );

      await _compartirExcel(
        bytes,
        'reporte_controles_sst.xlsx',
        'Controles SST',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarSeguimientosPdf() async {
    try {
      if (_seguimientosReporte.isEmpty) {
        final _SeguimientosReporteData datos =
            await _cargarSeguimientosCombinados();

        _seguimientosReporte = datos.seguimientos;
      }

      final Uint8List bytes = await _reporteProfesionalService
          .generarPdfSeguimientos(
            _seguimientosReporte,
            formato: _formato,
            pendientesSincronizar: _seguimientosPendientesSincronizar,
          );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_seguimientos_iperc.pdf',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarSeguimientosExcel() async {
    try {
      if (_seguimientosReporte.isEmpty) {
        final _SeguimientosReporteData datos =
            await _cargarSeguimientosCombinados();

        _seguimientosReporte = datos.seguimientos;
      }

      final Uint8List bytes = _reporteExportService.generarExcelSeguimientos(
        _seguimientosReporte,
      );

      await _compartirExcel(
        bytes,
        'reporte_seguimientos_iperc.xlsx',
        'Seguimientos IPERC',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarMapasPdf() async {
    try {
      final Uint8List bytes = await _reporteProfesionalService.generarPdfMapas(
        matrices: _matrices,
        detalles: _detalles,
        formato: _formato,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_mapa_riesgos.pdf',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _exportarMapasExcel() async {
    try {
      final Uint8List bytes = _reporteExportService.generarExcelMapasRiesgo(
        matrices: _matrices,
        detalles: _detalles,
      );

      await _compartirExcel(
        bytes,
        'reporte_mapa_riesgos.xlsx',
        'Mapa de riesgos SST/IPERC',
      );
    } catch (error) {
      _mensaje(_mensajeError(error), error: true);
    }
  }

  Future<void> _compartirExcel(
    Uint8List bytes,
    String nombre,
    String titulo,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        title: titulo,
        subject: titulo,
        files: <XFile>[
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: <String>[nombre],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _DashboardResumen resumen = _resumen;

    return Scaffold(
      backgroundColor: const Color(0xFF030812),
      appBar: AppBar(
        title: const Text('Reportes SST/IPERC'),
        backgroundColor: const Color(0xFF071120),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_error != null) _errorCard(_error!),

                  _heroDashboard(resumen),
                  const SizedBox(height: 14),
                  _selectorFormato(),
                  const SizedBox(height: 14),
                  _gridIndicadores(resumen),
                  const SizedBox(height: 14),
                  _distribucionRiesgos(resumen),
                  const SizedBox(height: 14),
                  _comparacionRiesgo(resumen),
                  const SizedBox(height: 14),
                  _rankingRiesgos(),
                  const SizedBox(height: 14),
                  _seguimientosCard(resumen),
                  const SizedBox(height: 18),
                  _accionesEjecutivo(),
                  const SizedBox(height: 28),

                  const Text(
                    'Reportes específicos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _reporteCard(
                    icon: Icons.assignment_outlined,
                    title: 'Matrices IPERC',
                    description:
                        'Matrices registradas, institución, área, actividad y estado.',
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatricesIpercScreen(rol: widget.rol),
                      ),
                    ),
                    onPdf: _exportarMatricesPdf,
                    onExcel: _exportarMatricesExcel,
                  ),
                  _reporteCard(
                    icon: Icons.grid_view_outlined,
                    title: 'Evaluación de riesgos',
                    description: 'Matriz 5×5 y evaluaciones de riesgo.',
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatrizRiesgoScreen(),
                      ),
                    ),
                    onPdf: _exportarEvaluacionPdf,
                    onExcel: _exportarEvaluacionExcel,
                  ),
                  _reporteCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Controles SST',
                    description: 'Medidas de control registradas.',
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ControlesScreen(rol: widget.rol, soloLectura: true),
                      ),
                    ),
                    onPdf: _exportarControlesPdf,
                    onExcel: _exportarControlesExcel,
                  ),
                  _reporteCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Seguimientos IPERC',
                    description: 'Avances, verificaciones y observaciones.',
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SeguimientosScreen(rol: widget.rol),
                      ),
                    ),
                    onPdf: _exportarSeguimientosPdf,
                    onExcel: _exportarSeguimientosExcel,
                  ),
                  _reporteCard(
                    icon: Icons.map_outlined,
                    title: 'Mapas de riesgo',
                    description: 'Riesgos identificados por área y zona.',
                    onView: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MapasRiesgoScreen(),
                      ),
                    ),
                    onPdf: _exportarMapasPdf,
                    onExcel: _exportarMapasExcel,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _heroDashboard(_DashboardResumen r) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF2563EB), Color(0xFF6D5DFC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Dashboard SST / IPERC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resumen ejecutivo de riesgos',
                      style: TextStyle(color: Color(0xFF91A4C2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _miniLineChart(),
          const SizedBox(height: 10),
          Text(
            '${r.totalMatrices} matrices · '
            '${r.totalRiesgos} riesgos evaluados',
            style: const TextStyle(
              color: Color(0xFF9CB2D2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorFormato() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Formato del informe ejecutivo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ReportePdfFormato>(
            segments: const <ButtonSegment<ReportePdfFormato>>[
              ButtonSegment<ReportePdfFormato>(
                value: ReportePdfFormato.vertical,
                icon: Icon(Icons.stay_current_portrait),
                label: Text('Vertical'),
              ),
              ButtonSegment<ReportePdfFormato>(
                value: ReportePdfFormato.horizontal,
                icon: Icon(Icons.stay_current_landscape),
                label: Text('Horizontal'),
              ),
              ButtonSegment<ReportePdfFormato>(
                value: ReportePdfFormato.mixto,
                icon: Icon(Icons.auto_awesome_mosaic),
                label: Text('Mixto'),
              ),
            ],
            selected: <ReportePdfFormato>{_formato},
            onSelectionChanged: (Set<ReportePdfFormato> value) {
              setState(() {
                _formato = value.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _gridIndicadores(_DashboardResumen r) {
    final List<_Kpi> items = <_Kpi>[
      _Kpi(
        'Riesgos',
        '${r.totalRiesgos}',
        Icons.warning_amber_rounded,
        const Color(0xFF579BFF),
      ),
      _Kpi(
        'Críticos',
        '${r.criticos}',
        Icons.error_outline,
        const Color(0xFFFF526E),
      ),
      _Kpi(
        'Controlados',
        '${r.controlados}',
        Icons.verified_outlined,
        const Color(0xFF4BD7A5),
      ),
      _Kpi(
        'Pendientes',
        '${r.pendientes}',
        Icons.pending_actions_outlined,
        const Color(0xFFFFA755),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, int index) {
        final _Kpi item = items[index];

        return _panel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: item.color.withValues(alpha: 0.15),
                foregroundColor: item.color,
                child: Icon(item.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.label,
                      style: const TextStyle(color: Color(0xFF9DB0CD)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _distribucionRiesgos(_DashboardResumen r) {
    final int total = r.totalRiesgos == 0 ? 1 : r.totalRiesgos;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Distribución de riesgos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _nivelBar('Bajo', r.bajos, total, const Color(0xFF40D69D)),
          _nivelBar('Medio', r.medios, total, const Color(0xFFFFD054)),
          _nivelBar('Alto', r.altos, total, const Color(0xFFFF9650)),
          _nivelBar('Crítico', r.criticos, total, const Color(0xFFFF506C)),
        ],
      ),
    );
  }

  Widget _nivelBar(String label, int value, int total, Color color) {
    final double progress = (value / total).clamp(0, 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFB8C7DD)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: const Color(0xFF1A2940),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparacionRiesgo(_DashboardResumen r) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Efectividad de controles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  'Inicial',
                  r.promedioInicial.toStringAsFixed(1),
                  const Color(0xFFFF885E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  'Residual',
                  r.promedioResidual.toStringAsFixed(1),
                  const Color(0xFF5AA9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  'Reducción',
                  '${r.reduccion.toStringAsFixed(0)}%',
                  const Color(0xFF54DDAE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D3351)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF93A8C7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _rankingRiesgos() {
    final List<DetalleIpercModel> top = List<DetalleIpercModel>.from(_detalles)
      ..sort(
        (DetalleIpercModel a, DetalleIpercModel b) =>
            b.valorRiesgoActual.compareTo(a.valorRiesgoActual),
      );

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Riesgos prioritarios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            const Text(
              'No hay riesgos registrados.',
              style: TextStyle(color: Color(0xFF93A8C7)),
            )
          else
            ...top.take(5).toList().asMap().entries.map((
              MapEntry<int, DetalleIpercModel> entry,
            ) {
              final DetalleIpercModel d = entry.value;

              final Color color = _riskColor(d.valorRiesgoActual);

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: color.withValues(alpha: 0.18),
                      foregroundColor: color,
                      child: Text('${entry.key + 1}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            d.peligroVisible,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            d.tarea,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8195B3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${d.valorRiesgoActual}',
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _seguimientosCard(_DashboardResumen r) {
    final double progress = r.totalSeguimientos == 0
        ? 0
        : r.seguimientosVerificados / r.totalSeguimientos;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Seguimientos IPERC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${r.seguimientosVerificados} de '
                '${r.totalSeguimientos} verificados',
                style: const TextStyle(color: Color(0xFFB8C7DD)),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF50D9A8),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF1B2940),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF50D9A8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accionesEjecutivo() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Informe ejecutivo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _abrirVistaPreviaPdf,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Vista previa'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _compartirInformeEjecutivo,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Generar PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reporteCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onView,
    required VoidCallback onPdf,
    required VoidCallback onExcel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: const Color(0xFF102D55),
                  foregroundColor: const Color(0xFF70B3FF),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Color(0xFF95A9C8))),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver'),
                ),
                FilledButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onExcel,
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF081421),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF19304D)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _miniLineChart() {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(painter: _DashboardLinePainter()),
    );
  }

  Widget _errorCard(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF35121B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A263B)),
        ),
        child: Text(message, style: const TextStyle(color: Color(0xFFFFA4B5))),
      ),
    );
  }

  Color _riskColor(int value) {
    if (value <= 4) {
      return const Color(0xFF3ED69D);
    }

    if (value <= 9) {
      return const Color(0xFFFFD054);
    }

    if (value <= 16) {
      return const Color(0xFFFF9650);
    }

    return const Color(0xFFFF506C);
  }

  void _mensaje(String text, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? Colors.red.shade700 : null,
          content: Text(text),
        ),
      );
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

class _VistaPreviaPdfScreen extends StatelessWidget {
  const _VistaPreviaPdfScreen({required this.titulo, required this.buildPdf});

  final String titulo;
  final Future<Uint8List> Function() buildPdf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: PdfPreview(
        build: (_) => buildPdf(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'informe_ejecutivo_sst_iperc.pdf',
      ),
    );
  }
}

class _SeguimientosReporteData {
  const _SeguimientosReporteData({
    required this.seguimientos,
    required this.avancePromedio,
    required this.pendientesSincronizar,
  });

  final List<SeguimientoIpercModel> seguimientos;
  final double avancePromedio;
  final int pendientesSincronizar;
}

class _DashboardResumen {
  const _DashboardResumen({
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
    required this.reduccion,
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
  final double reduccion;
  final int totalSeguimientos;
  final int seguimientosVerificados;
  final double avancePromedioSeguimientos;
  final int seguimientosPendientesSincronizar;
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _DashboardLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..color = const Color(0xFF2379FF).withValues(alpha: 0.18)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint line = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF2563EB),
          Color(0xFF45C7FF),
          Color(0xFF6D5DFC),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.65,
        size.width * 0.18,
        size.height * 0.35,
        size.width * 0.34,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.62,
        size.width * 0.55,
        size.height * 0.15,
        size.width * 0.70,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.50,
        size.width * 0.88,
        size.height * 0.20,
        size.width,
        size.height * 0.10,
      );

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
