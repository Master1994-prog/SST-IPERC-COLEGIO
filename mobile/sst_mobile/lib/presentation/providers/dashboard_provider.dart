import 'package:flutter/foundation.dart';

import '../../data/models/detalle_iperc_model.dart';
import '../../data/models/matriz_iperc_model.dart';
import '../../data/models/seguimiento_iperc_model.dart';
import '../../data/repositories/detalle_iperc_repository.dart';
import '../../data/repositories/matriz_iperc_repository.dart';
import '../../data/repositories/seguimiento_iperc_repository.dart';

/// Administra los indicadores mostrados en la pantalla de inicio.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    MatrizIpercRepository? matrizRepository,
    DetalleIpercRepository? detalleRepository,
    SeguimientoIpercRepository? seguimientoRepository,
  }) : _matrizRepository = matrizRepository ?? MatrizIpercRepository(),
       _detalleRepository = detalleRepository ?? DetalleIpercRepository(),
       _seguimientoRepository =
           seguimientoRepository ?? SeguimientoIpercRepository();

  final MatrizIpercRepository _matrizRepository;
  final DetalleIpercRepository _detalleRepository;
  final SeguimientoIpercRepository _seguimientoRepository;

  bool _cargando = false;
  String? _error;

  int _cantidadMatrices = 0;
  int _cantidadRiesgosCriticos = 0;
  int _cantidadSeguimientosPendientes = 0;
  int _cantidadSeguimientosVerificados = 0;

  bool get cargando => _cargando;

  String? get error => _error;

  bool get tieneError => _error != null && _error!.trim().isNotEmpty;

  int get cantidadMatrices => _cantidadMatrices;

  int get cantidadRiesgosCriticos => _cantidadRiesgosCriticos;

  int get cantidadSeguimientosPendientes => _cantidadSeguimientosPendientes;

  int get cantidadSeguimientosVerificados => _cantidadSeguimientosVerificados;

  /// Carga simultáneamente la información requerida por el panel.
  Future<void> cargarResumen() async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
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

      _cantidadMatrices = matrices.length;

      _cantidadRiesgosCriticos = detalles.where(_esRiesgoCritico).length;

      _cantidadSeguimientosPendientes = seguimientos
          .where((SeguimientoIpercModel seguimiento) => !seguimiento.verificado)
          .length;

      _cantidadSeguimientosVerificados = seguimientos
          .where((SeguimientoIpercModel seguimiento) => seguimiento.verificado)
          .length;
    } catch (error) {
      _error = _obtenerMensajeError(error);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Determina si la evaluación inicial o residual posee
  /// un nivel clasificado explícitamente como crítico.
  ///
  /// No se calcula un rango manual: se respeta el nombre
  /// que devuelve el backend.
  bool _esRiesgoCritico(DetalleIpercModel detalle) {
    final String inicial =
        detalle.evaluacionInicial?.nivelRiesgoNombre.trim().toLowerCase() ?? '';

    final String residual =
        detalle.evaluacionResidual?.nivelRiesgoNombre.trim().toLowerCase() ??
        '';

    return _contieneCritico(inicial) || _contieneCritico(residual);
  }

  bool _contieneCritico(String texto) {
    return texto.contains('crítico') || texto.contains('critico');
  }

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

    return mensaje.isEmpty
        ? 'No se pudo cargar el resumen del sistema.'
        : mensaje;
  }
}
