import 'package:flutter/foundation.dart';

import '../../data/datasources/local/detalle_iperc_catalogos_local_datasource.dart';
import '../../data/models/consecuencia_model.dart';
import '../../data/models/peligro_model.dart';
import '../../data/models/probabilidad_model.dart';
import '../../data/models/severidad_model.dart';
import '../../data/repositories/consecuencia_repository.dart';
import '../../data/repositories/peligro_repository.dart';
import '../../data/repositories/probabilidad_repository.dart';
import '../../data/repositories/severidad_repository.dart';

/// ===============================================================
/// PROVIDER - CATÁLOGOS DETALLE IPERC
/// ===============================================================
///
/// Trabaja con:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// Estrategia:
///
/// 1. Leer SQLite.
/// 2. Mostrar lo disponible.
/// 3. Consultar cada endpoint por separado.
/// 4. Guardar inmediatamente cada catálogo exitoso.
/// 5. Si uno falla, los demás continúan funcionando.
/// ===============================================================
class DetalleIpercCatalogosProvider extends ChangeNotifier {
  DetalleIpercCatalogosProvider({
    PeligroRepository? peligroRepository,
    ConsecuenciaRepository? consecuenciaRepository,
    ProbabilidadRepository? probabilidadRepository,
    SeveridadRepository? severidadRepository,
    DetalleIpercCatalogosLocalDatasource? localDatasource,
  }) : _peligroRepository = peligroRepository ?? PeligroRepository(),
       _consecuenciaRepository =
           consecuenciaRepository ?? ConsecuenciaRepository(),
       _probabilidadRepository =
           probabilidadRepository ?? ProbabilidadRepository(),
       _severidadRepository = severidadRepository ?? SeveridadRepository(),
       _localDatasource =
           localDatasource ?? DetalleIpercCatalogosLocalDatasource();

  final PeligroRepository _peligroRepository;
  final ConsecuenciaRepository _consecuenciaRepository;
  final ProbabilidadRepository _probabilidadRepository;
  final SeveridadRepository _severidadRepository;

  final DetalleIpercCatalogosLocalDatasource _localDatasource;

  // =============================================================
  // CATÁLOGOS
  // =============================================================

  List<PeligroModel> _peligros = <PeligroModel>[];

  List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];

  List<ProbabilidadModel> _probabilidades = <ProbabilidadModel>[];

  List<SeveridadModel> _severidades = <SeveridadModel>[];

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = false;
  bool _cargandoLocal = false;
  bool _actualizandoRemoto = false;

  bool _cargado = false;
  bool _usandoDatosLocales = false;

  String? _error;
  String? _advertencia;

  DateTime? _ultimaActualizacionPeligros;
  DateTime? _ultimaActualizacionConsecuencias;
  DateTime? _ultimaActualizacionProbabilidades;
  DateTime? _ultimaActualizacionSeveridades;

  // =============================================================
  // GETTERS
  // =============================================================

  List<PeligroModel> get peligros => List<PeligroModel>.unmodifiable(_peligros);

  List<ConsecuenciaModel> get consecuencias =>
      List<ConsecuenciaModel>.unmodifiable(_consecuencias);

  List<ProbabilidadModel> get probabilidades =>
      List<ProbabilidadModel>.unmodifiable(_probabilidades);

  List<SeveridadModel> get severidades =>
      List<SeveridadModel>.unmodifiable(_severidades);

  bool get cargando => _cargando;

  bool get cargandoLocal => _cargandoLocal;

  bool get actualizandoRemoto => _actualizandoRemoto;

  bool get cargado => _cargado;

  bool get usandoDatosLocales => _usandoDatosLocales;

  String? get error => _error;

  String? get advertencia => _advertencia;

  DateTime? get ultimaActualizacionPeligros => _ultimaActualizacionPeligros;

  DateTime? get ultimaActualizacionConsecuencias =>
      _ultimaActualizacionConsecuencias;

  DateTime? get ultimaActualizacionProbabilidades =>
      _ultimaActualizacionProbabilidades;

  DateTime? get ultimaActualizacionSeveridades =>
      _ultimaActualizacionSeveridades;

  // =============================================================
  // DISPONIBILIDAD
  // =============================================================

  bool get tienePeligros => _peligros.isNotEmpty;

  bool get tieneConsecuencias => _consecuencias.isNotEmpty;

  bool get tieneProbabilidades => _probabilidades.isNotEmpty;

  bool get tieneSeveridades => _severidades.isNotEmpty;

  bool get tieneCatalogos =>
      tienePeligros &&
      tieneConsecuencias &&
      tieneProbabilidades &&
      tieneSeveridades;

  bool get tieneError => _error != null && _error!.trim().isNotEmpty;

  bool get tieneAdvertencia =>
      _advertencia != null && _advertencia!.trim().isNotEmpty;

  // =============================================================
  // CARGA PRINCIPAL
  // =============================================================

  Future<bool> cargar({bool forzar = false}) async {
    if (_cargando) {
      return tieneCatalogos;
    }

    if (_cargado && !forzar && tieneCatalogos) {
      return true;
    }

    _cargando = true;

    _error = null;
    _advertencia = null;

    notifyListeners();

    try {
      // ---------------------------------------------------------
      // 1. SQLITE
      // ---------------------------------------------------------

      await _cargarDesdeLocal();

      // ---------------------------------------------------------
      // 2. BACKEND
      // ---------------------------------------------------------

      await _actualizarDesdeRemoto();

      _cargado = tieneCatalogos;

      _actualizarEstadoFinal();

      return tieneCatalogos;
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // RECARGAR
  // =============================================================

  Future<bool> recargar() async {
    if (_cargando || _actualizandoRemoto) {
      return tieneCatalogos;
    }

    _error = null;
    _advertencia = null;

    notifyListeners();

    await _actualizarDesdeRemoto();

    _cargado = tieneCatalogos;

    _actualizarEstadoFinal();

    notifyListeners();

    return tieneCatalogos;
  }

  // =============================================================
  // CARGAR SQLITE
  // =============================================================

  Future<void> _cargarDesdeLocal() async {
    _cargandoLocal = true;

    notifyListeners();

    try {
      final List<PeligroModel> peligros = await _localDatasource
          .obtenerPeligros();

      final List<ConsecuenciaModel> consecuencias = await _localDatasource
          .obtenerConsecuencias();

      final List<ProbabilidadModel> probabilidades = await _localDatasource
          .obtenerProbabilidades();

      final List<SeveridadModel> severidades = await _localDatasource
          .obtenerSeveridades();

      if (peligros.isNotEmpty) {
        _peligros = peligros;
      }

      if (consecuencias.isNotEmpty) {
        _consecuencias = consecuencias;
      }

      if (probabilidades.isNotEmpty) {
        _probabilidades = probabilidades;
      }

      if (severidades.isNotEmpty) {
        _severidades = severidades;
      }

      _ordenar();

      _ultimaActualizacionPeligros = await _localDatasource
          .obtenerFechaActualizacion('PELIGROS');

      _ultimaActualizacionConsecuencias = await _localDatasource
          .obtenerFechaActualizacion('CONSECUENCIAS');

      _ultimaActualizacionProbabilidades = await _localDatasource
          .obtenerFechaActualizacion('PROBABILIDADES');

      _ultimaActualizacionSeveridades = await _localDatasource
          .obtenerFechaActualizacion('SEVERIDADES');

      _usandoDatosLocales =
          _peligros.isNotEmpty ||
          _consecuencias.isNotEmpty ||
          _probabilidades.isNotEmpty ||
          _severidades.isNotEmpty;
    } catch (error) {
      _advertencia =
          'No se pudieron leer completamente los catálogos locales: '
          '${_limpiarError(error)}';
    } finally {
      _cargandoLocal = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR BACKEND
  // =============================================================

  Future<void> _actualizarDesdeRemoto() async {
    _actualizandoRemoto = true;

    notifyListeners();

    final List<String> errores = <String>[];

    // ===========================================================
    // PELIGROS
    // ===========================================================

    try {
      final List<PeligroModel> resultado = await _peligroRepository
          .obtenerActivos();

      final List<PeligroModel> validos = resultado
          .where((PeligroModel item) => item.id > 0 && item.estaDisponible)
          .toList();

      if (validos.isNotEmpty) {
        _peligros = validos;

        await _localDatasource.guardarPeligros(validos);

        _ultimaActualizacionPeligros = DateTime.now().toUtc();
      } else {
        errores.add('Peligros: no existen registros activos.');
      }
    } catch (error) {
      errores.add('Peligros: ${_limpiarError(error)}');
    }

    // ===========================================================
    // CONSECUENCIAS
    // ===========================================================

    try {
      final List<ConsecuenciaModel> resultado = await _consecuenciaRepository
          .obtenerActivos();

      final List<ConsecuenciaModel> validos = resultado
          .where((ConsecuenciaModel item) => item.id > 0 && item.estaDisponible)
          .toList();

      if (validos.isNotEmpty) {
        _consecuencias = validos;

        await _localDatasource.guardarConsecuencias(validos);

        _ultimaActualizacionConsecuencias = DateTime.now().toUtc();
      } else {
        errores.add('Consecuencias: no existen registros activos.');
      }
    } catch (error) {
      errores.add('Consecuencias: ${_limpiarError(error)}');
    }

    // ===========================================================
    // PROBABILIDADES
    // ===========================================================

    try {
      final List<ProbabilidadModel> resultado = await _probabilidadRepository
          .obtenerTodas();

      final List<ProbabilidadModel> validos = resultado
          .where(
            (ProbabilidadModel item) =>
                item.id > 0 && item.valor >= 1 && item.valor <= 5,
          )
          .toList();

      if (validos.isNotEmpty) {
        _probabilidades = validos;

        await _localDatasource.guardarProbabilidades(validos);

        _ultimaActualizacionProbabilidades = DateTime.now().toUtc();
      } else {
        errores.add('Probabilidades: no existen valores válidos del 1 al 5.');
      }
    } catch (error) {
      errores.add('Probabilidades: ${_limpiarError(error)}');
    }

    // ===========================================================
    // SEVERIDADES
    // ===========================================================

    try {
      final List<SeveridadModel> resultado = await _severidadRepository
          .obtenerTodas();

      final List<SeveridadModel> validos = resultado
          .where(
            (SeveridadModel item) =>
                item.id > 0 && item.valor >= 1 && item.valor <= 5,
          )
          .toList();

      if (validos.isNotEmpty) {
        _severidades = validos;

        await _localDatasource.guardarSeveridades(validos);

        _ultimaActualizacionSeveridades = DateTime.now().toUtc();
      } else {
        errores.add('Severidades: no existen valores válidos del 1 al 5.');
      }
    } catch (error) {
      errores.add('Severidades: ${_limpiarError(error)}');
    }

    _ordenar();

    _actualizandoRemoto = false;

    // ===========================================================
    // RESULTADO
    // ===========================================================

    if (errores.isEmpty) {
      _error = null;
      _advertencia = null;

      _usandoDatosLocales = false;

      notifyListeners();

      return;
    }

    if (tieneCatalogos) {
      _error = null;

      _advertencia =
          'Algunos catálogos no pudieron actualizarse:\n'
          '${errores.join('\n')}';

      _usandoDatosLocales = true;
    } else {
      _error =
          'No se pudieron cargar todos los catálogos IPERC:\n'
          '${errores.join('\n')}';
    }

    notifyListeners();
  }

  // =============================================================
  // BÚSQUEDAS
  // =============================================================

  PeligroModel? buscarPeligroPorId(int? id) {
    if (id == null) {
      return null;
    }

    for (final PeligroModel item in _peligros) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  ConsecuenciaModel? buscarConsecuenciaPorId(int? id) {
    if (id == null) {
      return null;
    }

    for (final ConsecuenciaModel item in _consecuencias) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  ProbabilidadModel? buscarProbabilidadPorId(int? id) {
    if (id == null) {
      return null;
    }

    for (final ProbabilidadModel item in _probabilidades) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  ProbabilidadModel? buscarProbabilidadPorValor(int valor) {
    for (final ProbabilidadModel item in _probabilidades) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }

  SeveridadModel? buscarSeveridadPorId(int? id) {
    if (id == null) {
      return null;
    }

    for (final SeveridadModel item in _severidades) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  SeveridadModel? buscarSeveridadPorValor(int valor) {
    for (final SeveridadModel item in _severidades) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // ORDENAR
  // =============================================================

  void _ordenar() {
    _peligros.sort(
      (PeligroModel a, PeligroModel b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    _consecuencias.sort(
      (ConsecuenciaModel a, ConsecuenciaModel b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    _probabilidades.sort(
      (ProbabilidadModel a, ProbabilidadModel b) => a.valor.compareTo(b.valor),
    );

    _severidades.sort(
      (SeveridadModel a, SeveridadModel b) => a.valor.compareTo(b.valor),
    );
  }

  // =============================================================
  // ESTADO FINAL
  // =============================================================

  void _actualizarEstadoFinal() {
    if (tieneCatalogos) {
      _error = null;

      return;
    }

    final List<String> faltantes = <String>[];

    if (!tienePeligros) {
      faltantes.add('Peligros');
    }

    if (!tieneConsecuencias) {
      faltantes.add('Consecuencias');
    }

    if (!tieneProbabilidades) {
      faltantes.add('Probabilidades');
    }

    if (!tieneSeveridades) {
      faltantes.add('Severidades');
    }

    _error =
        'Faltan catálogos IPERC: '
        '${faltantes.join(', ')}.';
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void limpiarError() {
    _error = null;
    _advertencia = null;

    notifyListeners();
  }

  // =============================================================
  // LIMPIAR SQLITE
  // =============================================================

  Future<void> limpiarCatalogosLocales() async {
    await _localDatasource.limpiarCatalogos();

    _peligros = <PeligroModel>[];

    _consecuencias = <ConsecuenciaModel>[];

    _probabilidades = <ProbabilidadModel>[];

    _severidades = <SeveridadModel>[];

    _cargado = false;
    _usandoDatosLocales = false;

    _error = null;
    _advertencia = null;

    notifyListeners();
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'FormatException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Error desconocido.' : mensaje;
  }
}
