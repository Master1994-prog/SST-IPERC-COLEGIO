import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/local/detalle_iperc_local_datasource.dart';
import '../../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../../data/datasources/local/seguimiento_iperc_local_datasource.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_local_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
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
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';

/// ===============================================================
/// REPORTES SST/IPERC - SST EDURISK
/// ===============================================================
///
/// Pantalla armonizada con la identidad visual SST EduRisk:
/// - Azul como color principal.
/// - Fondo claro.
/// - Tarjetas blancas.
/// - Verde, amarillo, naranja y rojo solo para estados/riesgos.
/// - Gráfico lineal con datos reales.
/// - Gráfico circular de distribución de riesgos.
/// - Funciona con información híbrida: backend + SQLite.
/// ===============================================================
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({required this.rol, super.key});

  final String rol;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  // =============================================================
  // REPOSITORIOS Y DATASOURCES
  // =============================================================

  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  final ControlRepository _controlRepository = ControlRepository();

  final SeguimientoIpercRepository _seguimientoRepository =
      SeguimientoIpercRepository();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final EvaluacionRiesgoRepository _evaluacionRepository =
      EvaluacionRiesgoRepository();

  final MatrizIpercLocalDatasource _matrizLocalDatasource =
      MatrizIpercLocalDatasource();

  final DetalleIpercLocalDatasource _detalleLocalDatasource =
      DetalleIpercLocalDatasource();

  final SeguimientoIpercLocalDatasource _seguimientoLocalDatasource =
      SeguimientoIpercLocalDatasource();

  final ReporteExportService _reporteExportService = ReporteExportService();

  final ReporteDashboardExportService _dashboardExportService =
      ReporteDashboardExportService();

  final ReporteEspecificoProfesionalService _reporteProfesionalService =
      ReporteEspecificoProfesionalService();

  final Map<int, String> _nombresUsuarios = <int, String>{};

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = true;
  String? _error;

  List<MatrizIpercModel> _matrices = <MatrizIpercModel>[];
  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];
  List<SeguimientoIpercModel> _seguimientosReporte = <SeguimientoIpercModel>[];

  int _totalSeguimientos = 0;
  int _seguimientosVerificados = 0;
  double _avancePromedioSeguimientos = 0;
  int _seguimientosPendientesSincronizar = 0;

  ReportePdfFormato _formato = ReportePdfFormato.mixto;

  // =============================================================
  // COLORES DE RIESGO
  // =============================================================

  static const Color _riesgoBajo = AppColors.green;
  static const Color _riesgoMedio = AppColors.yellow;
  static const Color _riesgoAlto = Color(0xFFF28C28);
  static const Color _riesgoCritico = AppColors.riskOrange;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  // =============================================================
  // CARGA HÍBRIDA: MATRICES
  // =============================================================

  Future<List<MatrizIpercModel>> _cargarMatricesHibridas() async {
    final Map<String, MatrizIpercModel> datos = <String, MatrizIpercModel>{};

    try {
      final List<MatrizIpercModel> remotas = await _matrizRepository
          .obtenerMatrices();

      for (final MatrizIpercModel matriz in remotas) {
        datos['S:${matriz.id}'] = matriz;
      }
    } catch (_) {
      // Si no hay backend, se continúa con SQLite.
    }

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
    } catch (_) {
      // Si SQLite falla, se conserva lo remoto.
    }

    final List<MatrizIpercModel> lista = datos.values.toList();

    lista.sort(
      (MatrizIpercModel a, MatrizIpercModel b) => b.codigo.compareTo(a.codigo),
    );

    return lista;
  }

  // =============================================================
  // CARGA HÍBRIDA: DETALLES
  // =============================================================

  Future<List<DetalleIpercModel>> _cargarDetallesHibridos() async {
    final Map<String, DetalleIpercModel> datos = <String, DetalleIpercModel>{};

    try {
      final List<DetalleIpercModel> remotos = await _detalleRepository
          .obtenerTodos();

      for (final DetalleIpercModel detalle in remotos) {
        datos['S:${detalle.id}'] = detalle;
      }
    } catch (_) {
      // Se continúa con SQLite.
    }

    final Map<String, MatrizIpercLocalModel> matricesLocales =
        <String, MatrizIpercLocalModel>{};

    try {
      for (final MatrizIpercLocalModel matriz
          in await _matrizLocalDatasource.getAll()) {
        matricesLocales[matriz.idLocal] = matriz;
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
              .map((String e) => int.tryParse(e) ?? 0)
              .where((int e) => e > 0)
              .toList(),
          equipoProteccionIds: local.equipoProteccionIds
              .map((String e) => int.tryParse(e) ?? 0)
              .where((int e) => e > 0)
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
    } catch (_) {
      // Se conserva lo obtenido del servidor.
    }

    return datos.values.toList();
  }

  // =============================================================
  // CARGA HÍBRIDA: SEGUIMIENTOS
  // =============================================================

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
      // Offline: se usa el nombre almacenado en cada seguimiento.
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
      // El reporte puede continuar con SQLite.
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
      // Se conserva lo remoto.
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

  // =============================================================
  // CARGA PRINCIPAL
  // =============================================================

  Future<void> _cargarDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<MatrizIpercModel> matrices = await _cargarMatricesHibridas();

      final List<DetalleIpercModel> detalles = await _cargarDetallesHibridos();

      final _SeguimientosReporteData seguimientos =
          await _cargarSeguimientosCombinados();

      if (!mounted) {
        return;
      }

      setState(() {
        _matrices = matrices;
        _detalles = detalles;
        _seguimientosReporte = seguimientos.seguimientos;
        _totalSeguimientos = seguimientos.seguimientos.length;
        _seguimientosVerificados = seguimientos.seguimientos
            .where((SeguimientoIpercModel e) => e.verificado)
            .length;
        _avancePromedioSeguimientos = seguimientos.avancePromedio;
        _seguimientosPendientesSincronizar = seguimientos.pendientesSincronizar;
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

  // =============================================================
  // RESUMEN DEL DASHBOARD
  // =============================================================

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

  // =============================================================
  // INFORME EJECUTIVO
  // =============================================================

  Future<Uint8List> _generarEjecutivo() {
    return _dashboardExportService.generarInformeEjecutivo(
      matrices: _matrices,
      detalles: _detalles,
      seguimientos: _seguimientosReporte,
      formato: _formato,
      totalSeguimientos: _totalSeguimientos,
      seguimientosVerificados: _seguimientosVerificados,
      avancePromedioSeguimientos: _avancePromedioSeguimientos,
      seguimientosPendientesSincronizar: _seguimientosPendientesSincronizar,
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
        'No se pudo generar el informe: ${_mensajeError(error)}',
        error: true,
      );
    }
  }

  // =============================================================
  // EXPORTACIONES ESPECÍFICAS
  // =============================================================

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

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final _DashboardResumen resumen = _resumen;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reportes SST/IPERC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBright),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _cargarDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                children: <Widget>[
                  if (_error != null) ...<Widget>[
                    _errorCard(_error!),
                    const SizedBox(height: 14),
                  ],

                  _heroDashboard(resumen),
                  const SizedBox(height: 16),

                  _selectorFormato(),
                  const SizedBox(height: 16),

                  _gridIndicadores(resumen),
                  const SizedBox(height: 16),

                  _graficosDashboard(resumen),
                  const SizedBox(height: 16),

                  _distribucionRiesgos(resumen),
                  const SizedBox(height: 16),

                  _comparacionRiesgo(resumen),
                  const SizedBox(height: 16),

                  _rankingRiesgos(),
                  const SizedBox(height: 16),

                  _seguimientosCard(resumen),
                  const SizedBox(height: 16),

                  _accionesEjecutivo(),
                  const SizedBox(height: 30),

                  _tituloSeccion(
                    icon: Icons.folder_copy_outlined,
                    titulo: 'Reportes específicos',
                    subtitulo: 'Consulta, genera PDF o exporta a Excel.',
                  ),
                  const SizedBox(height: 14),

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
                        builder: (_) =>
                            SeguimientosIpercScreen(rol: widget.rol),
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

  // =============================================================
  // HERO
  // =============================================================

  Widget _heroDashboard(_DashboardResumen r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryBright],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Reporte general SST / IPERC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resumen ejecutivo de riesgos y seguimientos',
                      style: TextStyle(
                        color: Color(0xFFE4EEFF),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _heroChip(
                icon: Icons.dashboard_outlined,
                text: '${r.totalMatrices} matrices',
              ),
              _heroChip(
                icon: Icons.warning_amber_rounded,
                text: '${r.totalRiesgos} riesgos',
              ),
              _heroChip(
                icon: Icons.fact_check_outlined,
                text: '${r.totalSeguimientos} seguimientos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SELECTOR DE FORMATO
  // =============================================================

  Widget _selectorFormato() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.description_outlined,
            title: 'Formato del informe ejecutivo',
            subtitle: 'El formato seleccionado se utilizará al generar el PDF.',
          ),
          const SizedBox(height: 14),
          SegmentedButton<ReportePdfFormato>(
            showSelectedIcon: false,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }

                return AppColors.primary;
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }

                return AppColors.surface;
              }),
              side: WidgetStateProperty.all(
                const BorderSide(color: AppColors.border),
              ),
            ),
            segments: const <ButtonSegment<ReportePdfFormato>>[
              ButtonSegment<ReportePdfFormato>(
                value: ReportePdfFormato.vertical,
                icon: Icon(Icons.stay_current_portrait),
                label: Text('Vertical'),
              ),
              ButtonSegment<ReportePdfFormato>(
                value: ReportePdfFormato.horizontal,
                icon: Icon(Icons.stay_current_landscape),
                label: Text('Horiz.'),
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

  // =============================================================
  // INDICADORES
  // =============================================================

  Widget _gridIndicadores(_DashboardResumen r) {
    final List<_Kpi> items = <_Kpi>[
      _Kpi(
        'Matrices',
        '${r.totalMatrices}',
        Icons.dashboard_customize_outlined,
        AppColors.primaryBright,
      ),
      _Kpi(
        'Riesgos',
        '${r.totalRiesgos}',
        Icons.warning_amber_rounded,
        _riesgoAlto,
      ),
      _Kpi(
        'Controlados',
        '${r.controlados}',
        Icons.verified_outlined,
        AppColors.green,
      ),
      _Kpi(
        'Críticos',
        '${r.criticos}',
        Icons.priority_high_rounded,
        AppColors.riskOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columnas = constraints.maxWidth >= 760 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            mainAxisExtent: 126,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, int index) {
            final _Kpi item = items[index];

            return _panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =============================================================
  // GRÁFICOS
  // =============================================================

  Widget _graficosDashboard(_DashboardResumen r) {
    final List<_GraficoMes> meses = _crearSerieMensual();

    final Widget lineal = _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.show_chart_rounded,
            title: 'Evolución mensual',
            subtitle: 'Matrices IPERC y seguimientos de los últimos 6 meses.',
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              _ChartLegendDot(
                color: AppColors.primaryBright,
                label: 'Matrices',
              ),
              _ChartLegendDot(color: AppColors.green, label: 'Seguimientos'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(painter: _MonthlyLinePainter(datos: meses)),
          ),
          const SizedBox(height: 8),
          Row(
            children: meses
                .map(
                  (_GraficoMes mes) => Expanded(
                    child: Text(
                      mes.etiqueta,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    final List<int> valores = <int>[r.bajos, r.medios, r.altos, r.criticos];

    const List<Color> colores = <Color>[
      _riesgoBajo,
      _riesgoMedio,
      _riesgoAlto,
      _riesgoCritico,
    ];

    final Widget circular = _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.donut_large_rounded,
            title: 'Distribución de riesgos',
            subtitle: 'Participación porcentual por nivel de riesgo.',
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 174,
              height: 174,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CustomPaint(
                    size: const Size.square(174),
                    painter: _RiskDonutPainter(
                      valores: valores,
                      colores: colores,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${r.totalRiesgos}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'riesgos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: <Widget>[
              _ChartLegendDot(color: _riesgoBajo, label: 'Bajo ${r.bajos}'),
              _ChartLegendDot(color: _riesgoMedio, label: 'Medio ${r.medios}'),
              _ChartLegendDot(color: _riesgoAlto, label: 'Alto ${r.altos}'),
              _ChartLegendDot(
                color: _riesgoCritico,
                label: 'Crítico ${r.criticos}',
              ),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: lineal),
              const SizedBox(width: 14),
              Expanded(child: circular),
            ],
          );
        }

        return Column(
          children: <Widget>[lineal, const SizedBox(height: 14), circular],
        );
      },
    );
  }

  List<_GraficoMes> _crearSerieMensual() {
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

    return List<_GraficoMes>.generate(6, (int index) {
      final DateTime mes = DateTime(ahora.year, ahora.month - 5 + index, 1);

      final int matrices = _matrices.where((MatrizIpercModel item) {
        final DateTime? fecha = item.fechaRegistro ?? item.fechaEvaluacion;

        return fecha != null &&
            fecha.year == mes.year &&
            fecha.month == mes.month;
      }).length;

      final int seguimientos = _seguimientosReporte.where((
        SeguimientoIpercModel item,
      ) {
        final DateTime fecha = item.fechaSeguimiento;

        return fecha.year == mes.year && fecha.month == mes.month;
      }).length;

      return _GraficoMes(
        etiqueta: nombres[mes.month - 1],
        matrices: matrices,
        seguimientos: seguimientos,
      );
    });
  }

  // =============================================================
  // DISTRIBUCIÓN EN BARRAS
  // =============================================================

  Widget _distribucionRiesgos(_DashboardResumen r) {
    final int total = r.totalRiesgos == 0 ? 1 : r.totalRiesgos;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.stacked_bar_chart_rounded,
            title: 'Detalle por nivel de riesgo',
            subtitle: 'Cantidad y proporción de riesgos evaluados.',
          ),
          const SizedBox(height: 16),
          _nivelBar('Bajo', r.bajos, total, _riesgoBajo),
          _nivelBar('Medio', r.medios, total, _riesgoMedio),
          _nivelBar('Alto', r.altos, total, _riesgoAlto),
          _nivelBar('Crítico', r.criticos, total, _riesgoCritico),
        ],
      ),
    );
  }

  Widget _nivelBar(String label, int value, int total, Color color) {
    final double progress = (value / total).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // EFECTIVIDAD
  // =============================================================

  Widget _comparacionRiesgo(_DashboardResumen r) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.health_and_safety_outlined,
            title: 'Efectividad de controles',
            subtitle: 'Comparación del riesgo inicial frente al residual.',
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  'Inicial',
                  r.promedioInicial.toStringAsFixed(1),
                  _riesgoAlto,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  'Residual',
                  r.promedioResidual.toStringAsFixed(1),
                  AppColors.primaryBright,
                  Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  'Reducción',
                  '${r.reduccion.toStringAsFixed(0)}%',
                  AppColors.green,
                  Icons.verified_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // RANKING
  // =============================================================

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
          _panelHeader(
            icon: Icons.priority_high_rounded,
            title: 'Riesgos prioritarios',
            subtitle: 'Los riesgos con mayor valoración actual.',
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const _EmptyReportMessage(
              icon: Icons.shield_outlined,
              text: 'No hay riesgos registrados.',
            )
          else
            ...top.take(5).toList().asMap().entries.map((
              MapEntry<int, DetalleIpercModel> entry,
            ) {
              final DetalleIpercModel detalle = entry.value;

              final Color color = _riskColor(detalle.valorRiesgoActual);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            detalle.peligroVisible,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            detalle.tarea,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${detalle.valorRiesgoActual}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
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

  // =============================================================
  // SEGUIMIENTOS
  // =============================================================

  Widget _seguimientosCard(_DashboardResumen r) {
    final double progress = r.totalSeguimientos == 0
        ? 0
        : r.seguimientosVerificados / r.totalSeguimientos;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.fact_check_outlined,
            title: 'Seguimientos IPERC',
            subtitle: 'Avance y estado de verificación.',
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${r.seguimientosVerificados} de '
                  '${r.totalSeguimientos} verificados',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _statusPill(
                icon: Icons.percent_rounded,
                label:
                    'Avance ${r.avancePromedioSeguimientos.toStringAsFixed(0)}%',
                color: AppColors.primaryBright,
              ),
              _statusPill(
                icon: Icons.cloud_upload_outlined,
                label: '${r.seguimientosPendientesSincronizar} por sincronizar',
                color: r.seguimientosPendientesSincronizar > 0
                    ? _riesgoAlto
                    : AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ACCIONES DEL INFORME EJECUTIVO
  // =============================================================

  Widget _accionesEjecutivo() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _panelHeader(
            icon: Icons.file_present_outlined,
            title: 'Informe ejecutivo',
            subtitle: 'Visualiza o genera el reporte general SST/IPERC.',
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _abrirVistaPreviaPdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Vista previa'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _compartirInformeEjecutivo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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

  // =============================================================
  // REPORTES ESPECÍFICOS
  // =============================================================

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBright.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onView,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver'),
                ),
                FilledButton.icon(
                  onPressed: onPdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onExcel,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5EC),
                    foregroundColor: AppColors.green,
                  ),
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

  // =============================================================
  // COMPONENTES VISUALES
  // =============================================================

  Widget _tituloSeccion({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryBright.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panelHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryBright.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.riskOrange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riskOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.riskOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(int value) {
    if (value <= 4) {
      return _riesgoBajo;
    }

    if (value <= 9) {
      return _riesgoMedio;
    }

    if (value <= 16) {
      return _riesgoAlto;
    }

    return _riesgoCritico;
  }

  void _mensaje(String text, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? AppColors.riskOrange : AppColors.navyDark,
          content: Text(text),
        ),
      );
  }

  String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

// ===============================================================
// VISTA PREVIA PDF
// ===============================================================

class _VistaPreviaPdfScreen extends StatelessWidget {
  const _VistaPreviaPdfScreen({required this.titulo, required this.buildPdf});

  final String titulo;
  final Future<Uint8List> Function() buildPdf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
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

// ===============================================================
// MODELOS AUXILIARES
// ===============================================================

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

class _GraficoMes {
  const _GraficoMes({
    required this.etiqueta,
    required this.matrices,
    required this.seguimientos,
  });

  final String etiqueta;
  final int matrices;
  final int seguimientos;
}

// ===============================================================
// LEYENDA
// ===============================================================

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyReportMessage extends StatelessWidget {
  const _EmptyReportMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.textSecondary, size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// GRÁFICO LINEAL
// ===============================================================

class _MonthlyLinePainter extends CustomPainter {
  const _MonthlyLinePainter({required this.datos});

  final List<_GraficoMes> datos;

  @override
  void paint(Canvas canvas, Size size) {
    if (datos.isEmpty) {
      return;
    }

    const double top = 10;
    const double bottom = 10;
    const double left = 8;
    const double right = 8;

    final double ancho = math.max(1, size.width - left - right);

    final double alto = math.max(1, size.height - top - bottom);

    int maximo = 1;

    for (final _GraficoMes mes in datos) {
      maximo = math.max(maximo, math.max(mes.matrices, mes.seguimientos));
    }

    final Paint grid = Paint()
      ..color = AppColors.border.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final double y = top + (alto * i / 4);

      canvas.drawLine(Offset(left, y), Offset(left + ancho, y), grid);
    }

    void dibujarSerie(int Function(_GraficoMes mes) valor, Color color) {
      final Paint linea = Paint()
        ..color = color
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final Paint punto = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final Paint centro = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final Path path = Path();

      for (int i = 0; i < datos.length; i++) {
        final double x = datos.length == 1
            ? left + ancho / 2
            : left + ancho * i / (datos.length - 1);

        final double ratio = valor(datos[i]) / maximo;

        final double y = top + alto - (alto * ratio);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 4.1, punto);

        canvas.drawCircle(Offset(x, y), 1.8, centro);
      }

      canvas.drawPath(path, linea);
    }

    dibujarSerie((_GraficoMes mes) => mes.matrices, AppColors.primaryBright);

    dibujarSerie((_GraficoMes mes) => mes.seguimientos, AppColors.green);
  }

  @override
  bool shouldRepaint(covariant _MonthlyLinePainter oldDelegate) {
    return oldDelegate.datos != datos;
  }
}

// ===============================================================
// GRÁFICO CIRCULAR
// ===============================================================

class _RiskDonutPainter extends CustomPainter {
  const _RiskDonutPainter({required this.valores, required this.colores});

  final List<int> valores;
  final List<Color> colores;

  @override
  void paint(Canvas canvas, Size size) {
    final int total = valores.fold<int>(
      0,
      (int anterior, int actual) => anterior + actual,
    );

    final double lado = math.min(size.width, size.height);

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: lado * 0.37,
    );

    final Paint fondo = Paint()
      ..color = const Color(0xFFE8EDF5)
      ..strokeWidth = lado * 0.14
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, 0, math.pi * 2, false, fondo);

    if (total <= 0) {
      return;
    }

    double inicio = -math.pi / 2;

    for (int i = 0; i < valores.length && i < colores.length; i++) {
      final int valor = valores[i];

      if (valor <= 0) {
        continue;
      }

      final double barrido = math.pi * 2 * valor / total;

      final Paint segmento = Paint()
        ..color = colores[i]
        ..strokeWidth = lado * 0.14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, inicio, barrido, false, segmento);

      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _RiskDonutPainter oldDelegate) {
    return oldDelegate.valores != valores || oldDelegate.colores != colores;
  }
}
