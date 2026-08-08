import 'package:flutter/foundation.dart';

import '../../data/models/detalle_iperc_model.dart';
import '../../data/models/matriz_iperc_model.dart';
import '../../data/models/seguimiento_iperc_model.dart';

import '../../data/repositories/detalle_iperc_repository.dart';
import '../../data/repositories/matriz_iperc_repository.dart';
import '../../data/repositories/seguimiento_iperc_repository.dart';

/// ===============================================================
/// PROVIDER - DASHBOARD
/// ===============================================================
///
/// Administra los indicadores principales
/// mostrados en la pantalla de inicio.
///
/// Obtiene información de:
///
/// - Matrices IPERC.
/// - Detalles IPERC.
/// - Seguimientos IPERC.
/// ===============================================================
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    MatrizIpercRepository? matrizRepository,
    DetalleIpercRepository? detalleRepository,
    SeguimientoIpercRepository? seguimientoRepository,
  }) : _matrizRepository = matrizRepository ?? MatrizIpercRepository(),
       _detalleRepository = detalleRepository ?? DetalleIpercRepository(),
       _seguimientoRepository =
           seguimientoRepository ?? SeguimientoIpercRepository();

  // =============================================================
  // REPOSITORIOS
  // =============================================================

  final MatrizIpercRepository _matrizRepository;

  final DetalleIpercRepository _detalleRepository;

  final SeguimientoIpercRepository _seguimientoRepository;

  // =============================================================
  // ESTADO INTERNO
  // =============================================================

  bool _cargando = false;

  String? _error;

  int _cantidadMatrices = 0;

  int _cantidadRiesgosCriticos = 0;

  int _cantidadSeguimientosPendientes = 0;

  int _cantidadSeguimientosVerificados = 0;

  // =============================================================
  // GETTERS
  // =============================================================

  bool get cargando => _cargando;

  String? get error => _error;

  /// Indica si existe un error
  /// que deba mostrarse.
  bool get tieneError {
    final String mensaje = _error?.trim() ?? '';

    return mensaje.isNotEmpty;
  }

  int get cantidadMatrices => _cantidadMatrices;

  int get cantidadRiesgosCriticos => _cantidadRiesgosCriticos;

  int get cantidadSeguimientosPendientes => _cantidadSeguimientosPendientes;

  int get cantidadSeguimientosVerificados => _cantidadSeguimientosVerificados;

  // =============================================================
  // CARGAR RESUMEN
  // =============================================================

  /// Carga simultáneamente toda la información
  /// necesaria para el panel principal.
  Future<void> cargarResumen() async {
    /// Evitamos ejecutar dos cargas
    /// simultáneamente.
    if (_cargando) {
      return;
    }

    _cargando = true;

    _error = null;

    notifyListeners();

    try {
      /// Ejecutamos las consultas en paralelo
      /// para reducir el tiempo de carga.
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _matrizRepository.obtenerMatrices(),

            _detalleRepository.obtenerTodos(),

            _seguimientoRepository.obtenerTodos(),
          ]);

      final List<MatrizIpercModel> matrices =
          resultados[0] as List<MatrizIpercModel>;

      final List<DetalleIpercModel> detalles =
          resultados[1] as List<DetalleIpercModel>;

      final List<SeguimientoIpercModel> seguimientos =
          resultados[2] as List<SeguimientoIpercModel>;

      // ---------------------------------------------------------
      // MATRICES
      // ---------------------------------------------------------

      _cantidadMatrices = matrices.length;

      // ---------------------------------------------------------
      // RIESGOS CRÍTICOS
      // ---------------------------------------------------------

      _cantidadRiesgosCriticos = detalles.where(_esRiesgoCritico).length;

      // ---------------------------------------------------------
      // SEGUIMIENTOS PENDIENTES
      // ---------------------------------------------------------

      _cantidadSeguimientosPendientes = seguimientos.where((
        SeguimientoIpercModel seguimiento,
      ) {
        return !seguimiento.verificado;
      }).length;

      // ---------------------------------------------------------
      // SEGUIMIENTOS VERIFICADOS
      // ---------------------------------------------------------

      _cantidadSeguimientosVerificados = seguimientos.where((
        SeguimientoIpercModel seguimiento,
      ) {
        return seguimiento.verificado;
      }).length;
    } catch (error) {
      /// Guardamos un mensaje limpio
      /// para mostrarlo en la interfaz.
      _error = _obtenerMensajeError(error);
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // DETERMINAR RIESGO CRÍTICO
  // =============================================================

  /// Determina si el detalle tiene
  /// un nivel de riesgo crítico.
  ///
  /// Se consideran:
  ///
  /// - Evaluación inicial.
  /// - Evaluación residual.
  ///
  /// No calculamos rangos manuales.
  /// Respetamos el nivel enviado por el backend.
  bool _esRiesgoCritico(DetalleIpercModel detalle) {
    /// evaluacionInicial NO puede ser null
    /// en el modelo actual.
    final String inicial = detalle.evaluacionInicial.nivelRiesgoNombre
        .trim()
        .toLowerCase();

    /// evaluacionResidual sí puede ser null.
    final String residual =
        detalle.evaluacionResidual?.nivelRiesgoNombre.trim().toLowerCase() ??
        '';

    return _contieneCritico(inicial) || _contieneCritico(residual);
  }

  // =============================================================
  // BUSCAR PALABRA CRÍTICO
  // =============================================================

  bool _contieneCritico(String texto) {
    return texto.contains('crítico') || texto.contains('critico');
  }

  // =============================================================
  // MANEJO DE ERRORES
  // =============================================================

  /// Limpia mensajes técnicos provenientes
  /// de Exception, Dio y StateError.
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

    if (mensaje.isEmpty) {
      return 'No se pudo cargar '
          'el resumen del sistema.';
    }

    return mensaje;
  }
}
