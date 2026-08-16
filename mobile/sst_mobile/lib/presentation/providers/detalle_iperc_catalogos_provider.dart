import 'package:flutter/foundation.dart';

import '../../core/network/network_info.dart';
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
/// Administra los catálogos necesarios para registrar un peligro
/// evaluado en un Detalle IPERC:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// ESTRATEGIA ONLINE/OFFLINE:
///
/// 1. Siempre intenta leer SQLite primero.
/// 2. Comprueba si existe Internet real.
/// 3. Si NO hay Internet:
///    - Usa únicamente SQLite.
///    - NO intenta llamar al backend.
/// 4. Si hay Internet:
///    - Actualiza cada catálogo por separado.
///    - Guarda inmediatamente en SQLite cada catálogo válido.
/// 5. Una respuesta incompleta del servidor nunca sustituye una
///    escala local completa de Probabilidad o Severidad.
///
/// Esto evita que "Agregar peligro evaluado" muestre un error de
/// conexión cuando ya existen catálogos locales disponibles.
/// ===============================================================
class DetalleIpercCatalogosProvider extends ChangeNotifier {
  DetalleIpercCatalogosProvider({
    PeligroRepository? peligroRepository,
    ConsecuenciaRepository? consecuenciaRepository,
    ProbabilidadRepository? probabilidadRepository,
    SeveridadRepository? severidadRepository,
    DetalleIpercCatalogosLocalDatasource? localDatasource,
    NetworkInfo? networkInfo,
  }) : _peligroRepository = peligroRepository ?? PeligroRepository(),
       _consecuenciaRepository =
           consecuenciaRepository ?? ConsecuenciaRepository(),
       _probabilidadRepository =
           probabilidadRepository ?? ProbabilidadRepository(),
       _severidadRepository = severidadRepository ?? SeveridadRepository(),
       _localDatasource =
           localDatasource ?? DetalleIpercCatalogosLocalDatasource(),
       _networkInfo = networkInfo ?? NetworkInfo.instance;

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final PeligroRepository _peligroRepository;

  final ConsecuenciaRepository _consecuenciaRepository;

  final ProbabilidadRepository _probabilidadRepository;

  final SeveridadRepository _severidadRepository;

  final DetalleIpercCatalogosLocalDatasource _localDatasource;

  final NetworkInfo _networkInfo;

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

  bool _isConnected = false;

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

  bool get isConnected => _isConnected;

  bool get isOffline => !_isConnected;

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

  /// La matriz 5x5 solamente es segura si existe la escala completa:
  /// 1, 2, 3, 4 y 5.
  bool get tieneProbabilidades =>
      _escalaProbabilidadesCompleta(_probabilidades);

  bool get tieneSeveridades => _escalaSeveridadesCompleta(_severidades);

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
      // 1. LEER SQLITE SIEMPRE
      // ---------------------------------------------------------

      await _cargarDesdeLocal();

      // ---------------------------------------------------------
      // 2. COMPROBAR CONEXIÓN REAL
      // ---------------------------------------------------------

      _isConnected = await _networkInfo.isConnected;

      // ---------------------------------------------------------
      // 3. SIN INTERNET: NO LLAMAR AL BACKEND
      // ---------------------------------------------------------

      if (!_isConnected) {
        _cargado = tieneCatalogos;

        _usandoDatosLocales =
            tienePeligros ||
            tieneConsecuencias ||
            _probabilidades.isNotEmpty ||
            _severidades.isNotEmpty;

        _actualizarEstadoFinal(sinConexion: true);

        return tieneCatalogos;
      }

      // ---------------------------------------------------------
      // 4. CON INTERNET: ACTUALIZAR BACKEND
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

  /// Fuerza una nueva comprobación.
  ///
  /// Si el teléfono está offline, vuelve a leer SQLite pero NO hace
  /// peticiones HTTP.
  Future<bool> recargar() async {
    if (_cargando || _actualizandoRemoto) {
      return tieneCatalogos;
    }

    _error = null;
    _advertencia = null;

    notifyListeners();

    _cargando = true;

    try {
      await _cargarDesdeLocal();

      _isConnected = await _networkInfo.isConnected;

      if (!_isConnected) {
        _cargado = tieneCatalogos;

        _usandoDatosLocales =
            tienePeligros ||
            tieneConsecuencias ||
            _probabilidades.isNotEmpty ||
            _severidades.isNotEmpty;

        _actualizarEstadoFinal(sinConexion: true);

        return tieneCatalogos;
      }

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

      // ---------------------------------------------------------
      // REEMPLAZAR MEMORIA CON EL ESTADO REAL DE SQLITE
      // ---------------------------------------------------------
      //
      // No conservamos accidentalmente datos antiguos en memoria si
      // SQLite está vacío.
      // ---------------------------------------------------------

      _peligros = List<PeligroModel>.from(peligros);

      _consecuencias = List<ConsecuenciaModel>.from(consecuencias);

      _probabilidades = List<ProbabilidadModel>.from(probabilidades);

      _severidades = List<SeveridadModel>.from(severidades);

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
          'No se pudieron leer completamente los '
          'catálogos locales: '
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

    try {
      // =========================================================
      // PELIGROS
      // =========================================================

      try {
        final List<PeligroModel> resultado = await _peligroRepository
            .obtenerActivos();

        final List<PeligroModel> validos = resultado
            .where((PeligroModel item) => item.id > 0 && item.estaDisponible)
            .toList(growable: false);

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

      // =========================================================
      // CONSECUENCIAS
      // =========================================================

      try {
        final List<ConsecuenciaModel> resultado = await _consecuenciaRepository
            .obtenerActivos();

        final List<ConsecuenciaModel> validos = resultado
            .where(
              (ConsecuenciaModel item) => item.id > 0 && item.estaDisponible,
            )
            .toList(growable: false);

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

      // =========================================================
      // PROBABILIDADES
      // =========================================================

      try {
        final List<ProbabilidadModel> resultado = await _probabilidadRepository
            .obtenerTodas();

        final List<ProbabilidadModel> validos = resultado
            .where(
              (ProbabilidadModel item) =>
                  item.id > 0 && item.valor >= 1 && item.valor <= 5,
            )
            .toList(growable: false);

        if (_escalaProbabilidadesCompleta(validos)) {
          _probabilidades = validos;

          await _localDatasource.guardarProbabilidades(validos);

          _ultimaActualizacionProbabilidades = DateTime.now().toUtc();
        } else {
          errores.add(
            'Probabilidades: el backend no devolvió '
            'la escala completa 1, 2, 3, 4, 5.',
          );
        }
      } catch (error) {
        errores.add('Probabilidades: ${_limpiarError(error)}');
      }

      // =========================================================
      // SEVERIDADES
      // =========================================================

      try {
        final List<SeveridadModel> resultado = await _severidadRepository
            .obtenerTodas();

        final List<SeveridadModel> validos = resultado
            .where(
              (SeveridadModel item) =>
                  item.id > 0 && item.valor >= 1 && item.valor <= 5,
            )
            .toList(growable: false);

        if (_escalaSeveridadesCompleta(validos)) {
          _severidades = validos;

          await _localDatasource.guardarSeveridades(validos);

          _ultimaActualizacionSeveridades = DateTime.now().toUtc();
        } else {
          errores.add(
            'Severidades: el backend no devolvió '
            'la escala completa 1, 2, 3, 4, 5.',
          );
        }
      } catch (error) {
        errores.add('Severidades: ${_limpiarError(error)}');
      }

      _ordenar();

      // =========================================================
      // RESULTADO
      // =========================================================

      if (errores.isEmpty) {
        _error = null;
        _advertencia = null;
        _usandoDatosLocales = false;

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
            'No se pudieron cargar todos los '
            'catálogos IPERC:\n'
            '${errores.join('\n')}';
      }
    } finally {
      _actualizandoRemoto = false;

      notifyListeners();
    }
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
  // VALIDAR ESCALA DE PROBABILIDADES
  // =============================================================

  bool _escalaProbabilidadesCompleta(List<ProbabilidadModel> items) {
    final Set<int> valores = items
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((ProbabilidadModel item) => item.valor)
        .toSet();

    return valores.length == 5 &&
        valores.containsAll(const <int>{1, 2, 3, 4, 5});
  }

  // =============================================================
  // VALIDAR ESCALA DE SEVERIDADES
  // =============================================================

  bool _escalaSeveridadesCompleta(List<SeveridadModel> items) {
    final Set<int> valores = items
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((SeveridadModel item) => item.valor)
        .toSet();

    return valores.length == 5 &&
        valores.containsAll(const <int>{1, 2, 3, 4, 5});
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

  void _actualizarEstadoFinal({bool sinConexion = false}) {
    if (tieneCatalogos) {
      _error = null;

      // Offline con datos completos NO es un error.
      //
      // Tampoco mostramos la advertencia "no se pudo conectar",
      // porque el usuario ya puede continuar normalmente.
      if (sinConexion) {
        _advertencia = null;
        _usandoDatosLocales = true;
      }

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
      faltantes.add('Probabilidades (escala 1-5)');
    }

    if (!tieneSeveridades) {
      faltantes.add('Severidades (escala 1-5)');
    }

    if (sinConexion) {
      _error =
          'Los catálogos offline todavía no están '
          'completos. Faltan: '
          '${faltantes.join(', ')}. '
          'Conéctate una vez a Internet para descargarlos.';
    } else {
      _error =
          'Faltan catálogos IPERC: '
          '${faltantes.join(', ')}.';
    }
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
