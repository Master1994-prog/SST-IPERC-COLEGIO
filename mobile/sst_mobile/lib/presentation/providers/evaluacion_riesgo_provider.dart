import 'package:flutter/foundation.dart';

import '../../data/models/evaluacion_riesgo_model.dart';
import '../../data/repositories/evaluacion_riesgo_repository.dart';

/// Maneja el cálculo y registro de evaluaciones IPERC.
class EvaluacionRiesgoProvider extends ChangeNotifier {
  EvaluacionRiesgoProvider({EvaluacionRiesgoRepository? repository})
    : _repository = repository ?? EvaluacionRiesgoRepository();

  final EvaluacionRiesgoRepository _repository;

  bool _cargando = false;
  bool _guardando = false;
  String? _errorMessage;

  EvaluacionRiesgoModel? _ultimaEvaluacion;

  ProbabilidadIpercOption? _probabilidadSeleccionada;

  SeveridadIpercOption? _severidadSeleccionada;

  bool get isLoading => _cargando || _guardando;

  bool get cargando => _cargando;

  bool get guardando => _guardando;

  String? get error => _errorMessage;

  String? get errorMessage => _errorMessage;

  EvaluacionRiesgoModel? get ultimaEvaluacion {
    return _ultimaEvaluacion;
  }

  List<ProbabilidadIpercOption> get probabilidades {
    return probabilidadesIperc;
  }

  List<SeveridadIpercOption> get severidades {
    return severidadesIperc;
  }

  List<NivelRiesgoIpercOption> get nivelesRiesgo {
    return nivelesRiesgoIperc;
  }

  ProbabilidadIpercOption? get probabilidadSeleccionada {
    return _probabilidadSeleccionada;
  }

  SeveridadIpercOption? get severidadSeleccionada {
    return _severidadSeleccionada;
  }

  ResultadoRiesgoCalculado? get resultadoCalculado {
    final ProbabilidadIpercOption? probabilidad = _probabilidadSeleccionada;

    final SeveridadIpercOption? severidad = _severidadSeleccionada;

    if (probabilidad == null || severidad == null) {
      return null;
    }

    return calcularResultado(probabilidad: probabilidad, severidad: severidad);
  }

  /// Inicializa los catálogos locales.
  Future<void> cargarDatosIniciales() async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Los catálogos están definidos localmente.
      // No es necesario escribir IDs.
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void seleccionarProbabilidad(ProbabilidadIpercOption? probabilidad) {
    _probabilidadSeleccionada = probabilidad;
    _ultimaEvaluacion = null;
    _errorMessage = null;
    notifyListeners();
  }

  void seleccionarSeveridad(SeveridadIpercOption? severidad) {
    _severidadSeleccionada = severidad;
    _ultimaEvaluacion = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Calcula probabilidad por severidad.
  int calcularValor({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
  }) {
    return probabilidad.valor * severidad.valor;
  }

  /// Obtiene el nivel de riesgo correspondiente.
  NivelRiesgoIpercOption calcularNivel({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
  }) {
    final int valor = calcularValor(
      probabilidad: probabilidad,
      severidad: severidad,
    );

    return obtenerNivelRiesgoIperc(valor);
  }

  ResultadoRiesgoCalculado calcularResultado({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
  }) {
    final int valor = calcularValor(
      probabilidad: probabilidad,
      severidad: severidad,
    );

    return ResultadoRiesgoCalculado(
      probabilidad: probabilidad,
      severidad: severidad,
      valor: valor,
      nivel: obtenerNivelRiesgoIperc(valor),
    );
  }

  /// Registra la evaluación en la API.
  Future<EvaluacionRiesgoModel?> crearEvaluacion({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
    String? observaciones,
  }) async {
    _guardando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final NivelRiesgoIpercOption nivel = calcularNivel(
        probabilidad: probabilidad,
        severidad: severidad,
      );

      final CrearEvaluacionRiesgoRequest request = CrearEvaluacionRiesgoRequest(
        probabilidadId: probabilidad.id,
        severidadId: severidad.id,
        nivelRiesgoId: nivel.id,
        observaciones: observaciones,
      );

      _ultimaEvaluacion = await _repository.crear(request);

      notifyListeners();
      return _ultimaEvaluacion;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');

      notifyListeners();
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// Guarda utilizando las opciones seleccionadas.
  Future<EvaluacionRiesgoModel?> guardarEvaluacion({
    String? observaciones,
  }) async {
    final ProbabilidadIpercOption? probabilidad = _probabilidadSeleccionada;

    final SeveridadIpercOption? severidad = _severidadSeleccionada;

    if (probabilidad == null || severidad == null) {
      _errorMessage = 'Selecciona la probabilidad y la severidad.';

      notifyListeners();
      return null;
    }

    return crearEvaluacion(
      probabilidad: probabilidad,
      severidad: severidad,
      observaciones: observaciones,
    );
  }

  /// Restablece todos los campos.
  void limpiarFormulario() {
    _probabilidadSeleccionada = null;
    _severidadSeleccionada = null;
    _ultimaEvaluacion = null;
    _errorMessage = null;
    notifyListeners();
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpiarUltimaEvaluacion() {
    _ultimaEvaluacion = null;
    notifyListeners();
  }
}
