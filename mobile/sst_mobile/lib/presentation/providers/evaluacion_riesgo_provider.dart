import 'package:flutter/foundation.dart';

import '../../data/models/evaluacion_riesgo_model.dart';
import '../../data/repositories/evaluacion_riesgo_repository.dart';

/// Provider para calcular y registrar evaluaciones de riesgo IPERC.
class EvaluacionRiesgoProvider extends ChangeNotifier {
  EvaluacionRiesgoProvider({EvaluacionRiesgoRepository? repository})
      : _repository = repository ?? EvaluacionRiesgoRepository();

  final EvaluacionRiesgoRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  EvaluacionRiesgoModel? _ultimaEvaluacion;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  EvaluacionRiesgoModel? get ultimaEvaluacion => _ultimaEvaluacion;

  List<ProbabilidadIpercOption> get probabilidades => probabilidadesIperc;
  List<SeveridadIpercOption> get severidades => severidadesIperc;
  List<NivelRiesgoIpercOption> get niveles => nivelesRiesgoIperc;

  int calcularValor({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
  }) {
    return probabilidad.valor * severidad.valor;
  }

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

  Future<EvaluacionRiesgoModel?> crearEvaluacion({
    required ProbabilidadIpercOption probabilidad,
    required SeveridadIpercOption severidad,
    String? observaciones,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final NivelRiesgoIpercOption nivel = calcularNivel(
        probabilidad: probabilidad,
        severidad: severidad,
      );

      final CrearEvaluacionRiesgoRequest request =
          CrearEvaluacionRiesgoRequest(
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
      _setLoading(false);
    }
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  void limpiarUltimaEvaluacion() {
    _ultimaEvaluacion = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
