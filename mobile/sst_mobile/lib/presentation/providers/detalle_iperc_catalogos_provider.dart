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
/// Administra los catálogos necesarios para registrar un
/// detalle IPERC tanto online como offline.
///
/// Catálogos:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// Estrategia:
///
/// 1. Cargar primero desde SQLite.
/// 2. Mostrar inmediatamente los datos locales.
/// 3. Intentar actualizar desde el backend.
/// 4. Guardar la nueva información en SQLite.
/// 5. Si falla internet, continuar utilizando datos locales.
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

  // =============================================================
  // REPOSITORIOS
  // =============================================================

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

  // =============================================================
  // FECHAS DE ACTUALIZACIÓN
  // =============================================================

  DateTime? _ultimaActualizacionPeligros;

  DateTime? _ultimaActualizacionConsecuencias;

  DateTime? _ultimaActualizacionProbabilidades;

  DateTime? _ultimaActualizacionSeveridades;

  // =============================================================
  // GETTERS
  // =============================================================

  List<PeligroModel> get peligros {
    return List<PeligroModel>.unmodifiable(_peligros);
  }

  List<ConsecuenciaModel> get consecuencias {
    return List<ConsecuenciaModel>.unmodifiable(_consecuencias);
  }

  List<ProbabilidadModel> get probabilidades {
    return List<ProbabilidadModel>.unmodifiable(_probabilidades);
  }

  List<SeveridadModel> get severidades {
    return List<SeveridadModel>.unmodifiable(_severidades);
  }

  bool get cargando => _cargando;

  bool get cargandoLocal => _cargandoLocal;

  bool get actualizandoRemoto => _actualizandoRemoto;

  bool get cargado => _cargado;

  bool get usandoDatosLocales => _usandoDatosLocales;

  String? get error => _error;

  String? get advertencia => _advertencia;

  DateTime? get ultimaActualizacionPeligros {
    return _ultimaActualizacionPeligros;
  }

  DateTime? get ultimaActualizacionConsecuencias {
    return _ultimaActualizacionConsecuencias;
  }

  DateTime? get ultimaActualizacionProbabilidades {
    return _ultimaActualizacionProbabilidades;
  }

  DateTime? get ultimaActualizacionSeveridades {
    return _ultimaActualizacionSeveridades;
  }

  // =============================================================
  // ESTADOS DE DISPONIBILIDAD
  // =============================================================

  bool get tieneError {
    return _error != null && _error!.trim().isNotEmpty;
  }

  bool get tieneAdvertencia {
    return _advertencia != null && _advertencia!.trim().isNotEmpty;
  }

  bool get tienePeligros => _peligros.isNotEmpty;

  bool get tieneConsecuencias => _consecuencias.isNotEmpty;

  bool get tieneProbabilidades => _probabilidades.isNotEmpty;

  bool get tieneSeveridades => _severidades.isNotEmpty;

  /// Para registrar correctamente un detalle IPERC
  /// necesitamos los cuatro catálogos.
  bool get tieneCatalogos {
    return tienePeligros &&
        tieneConsecuencias &&
        tieneProbabilidades &&
        tieneSeveridades;
  }

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
      // PRIMERO: DATOS SQLITE
      // ---------------------------------------------------------

      await _cargarDesdeLocal();

      // ---------------------------------------------------------
      // DESPUÉS: ACTUALIZAR DESDE API
      // ---------------------------------------------------------

      await _actualizarDesdeRemoto(conservarLocalesEnError: true);

      _cargado = tieneCatalogos;

      if (!tieneCatalogos && _error == null) {
        _error = 'No existen todos los catálogos necesarios para IPERC.';
      }

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

    return _actualizarDesdeRemoto(conservarLocalesEnError: true);
  }

  // =============================================================
  // CARGAR DESDE SQLITE
  // =============================================================

  Future<void> _cargarDesdeLocal() async {
    _cargandoLocal = true;

    notifyListeners();

    try {
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _localDatasource.obtenerPeligros(),
            _localDatasource.obtenerConsecuencias(),
            _localDatasource.obtenerProbabilidades(),
            _localDatasource.obtenerSeveridades(),

            _localDatasource.obtenerFechaActualizacion('PELIGROS'),

            _localDatasource.obtenerFechaActualizacion('CONSECUENCIAS'),

            _localDatasource.obtenerFechaActualizacion('PROBABILIDADES'),

            _localDatasource.obtenerFechaActualizacion('SEVERIDADES'),
          ]);

      // ---------------------------------------------------------
      // PELIGROS
      // ---------------------------------------------------------

      final List<PeligroModel> peligrosLocales =
          (resultados[0] as List<dynamic>)
              .whereType<PeligroModel>()
              .where(
                (PeligroModel peligro) =>
                    peligro.id > 0 && peligro.estaDisponible,
              )
              .toList();

      // ---------------------------------------------------------
      // CONSECUENCIAS
      // ---------------------------------------------------------

      final List<ConsecuenciaModel> consecuenciasLocales =
          (resultados[1] as List<dynamic>)
              .whereType<ConsecuenciaModel>()
              .where(
                (ConsecuenciaModel consecuencia) =>
                    consecuencia.id > 0 && consecuencia.estaDisponible,
              )
              .toList();

      // ---------------------------------------------------------
      // PROBABILIDADES
      // ---------------------------------------------------------

      final List<ProbabilidadModel> probabilidadesLocales =
          (resultados[2] as List<dynamic>)
              .whereType<ProbabilidadModel>()
              .where(
                (ProbabilidadModel item) =>
                    item.id > 0 && item.valor >= 1 && item.valor <= 5,
              )
              .toList();

      // ---------------------------------------------------------
      // SEVERIDADES
      // ---------------------------------------------------------

      final List<SeveridadModel> severidadesLocales =
          (resultados[3] as List<dynamic>)
              .whereType<SeveridadModel>()
              .where(
                (SeveridadModel item) =>
                    item.id > 0 && item.valor >= 1 && item.valor <= 5,
              )
              .toList();

      _ordenarPeligros(peligrosLocales);

      _ordenarConsecuencias(consecuenciasLocales);

      _ordenarProbabilidades(probabilidadesLocales);

      _ordenarSeveridades(severidadesLocales);

      if (peligrosLocales.isNotEmpty) {
        _peligros = peligrosLocales;
      }

      if (consecuenciasLocales.isNotEmpty) {
        _consecuencias = consecuenciasLocales;
      }

      if (probabilidadesLocales.isNotEmpty) {
        _probabilidades = probabilidadesLocales;
      }

      if (severidadesLocales.isNotEmpty) {
        _severidades = severidadesLocales;
      }

      // ---------------------------------------------------------
      // FECHAS
      // ---------------------------------------------------------

      _ultimaActualizacionPeligros = resultados[4] as DateTime?;

      _ultimaActualizacionConsecuencias = resultados[5] as DateTime?;

      _ultimaActualizacionProbabilidades = resultados[6] as DateTime?;

      _ultimaActualizacionSeveridades = resultados[7] as DateTime?;

      _usandoDatosLocales =
          peligrosLocales.isNotEmpty ||
          consecuenciasLocales.isNotEmpty ||
          probabilidadesLocales.isNotEmpty ||
          severidadesLocales.isNotEmpty;

      if (_usandoDatosLocales) {
        _advertencia = 'Se muestran catálogos almacenados localmente.';
      }
    } catch (error) {
      _advertencia =
          'No se pudieron cargar los catálogos locales: '
          '${_limpiarError(error)}';
    } finally {
      _cargandoLocal = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR DESDE BACKEND
  // =============================================================

  Future<bool> _actualizarDesdeRemoto({
    required bool conservarLocalesEnError,
  }) async {
    if (_actualizandoRemoto) {
      return tieneCatalogos;
    }

    _actualizandoRemoto = true;

    _error = null;

    notifyListeners();

    try {
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _peligroRepository.obtenerActivos(),
            _consecuenciaRepository.obtenerActivos(),
            _probabilidadRepository.obtenerTodas(),
            _severidadRepository.obtenerTodas(),
          ]);

      // ---------------------------------------------------------
      // PELIGROS
      // ---------------------------------------------------------

      final List<PeligroModel> peligrosRemotos =
          (resultados[0] as List<dynamic>)
              .whereType<PeligroModel>()
              .where(
                (PeligroModel peligro) =>
                    peligro.id > 0 && peligro.estaDisponible,
              )
              .toList();

      // ---------------------------------------------------------
      // CONSECUENCIAS
      // ---------------------------------------------------------

      final List<ConsecuenciaModel> consecuenciasRemotas =
          (resultados[1] as List<dynamic>)
              .whereType<ConsecuenciaModel>()
              .where(
                (ConsecuenciaModel consecuencia) =>
                    consecuencia.id > 0 && consecuencia.estaDisponible,
              )
              .toList();

      // ---------------------------------------------------------
      // PROBABILIDADES
      // ---------------------------------------------------------

      final List<ProbabilidadModel> probabilidadesRemotas =
          (resultados[2] as List<dynamic>)
              .whereType<ProbabilidadModel>()
              .where(
                (ProbabilidadModel item) =>
                    item.id > 0 && item.valor >= 1 && item.valor <= 5,
              )
              .toList();

      // ---------------------------------------------------------
      // SEVERIDADES
      // ---------------------------------------------------------

      final List<SeveridadModel> severidadesRemotas =
          (resultados[3] as List<dynamic>)
              .whereType<SeveridadModel>()
              .where(
                (SeveridadModel item) =>
                    item.id > 0 && item.valor >= 1 && item.valor <= 5,
              )
              .toList();

      // ---------------------------------------------------------
      // ORDENAR
      // ---------------------------------------------------------

      _ordenarPeligros(peligrosRemotos);

      _ordenarConsecuencias(consecuenciasRemotas);

      _ordenarProbabilidades(probabilidadesRemotas);

      _ordenarSeveridades(severidadesRemotas);

      // ---------------------------------------------------------
      // VALIDAR CATÁLOGOS
      // ---------------------------------------------------------

      if (peligrosRemotos.isEmpty) {
        throw StateError('El backend no devolvió peligros activos.');
      }

      if (consecuenciasRemotas.isEmpty) {
        throw StateError('El backend no devolvió consecuencias activas.');
      }

      if (probabilidadesRemotas.isEmpty) {
        throw StateError('El backend no devolvió probabilidades válidas.');
      }

      if (severidadesRemotas.isEmpty) {
        throw StateError('El backend no devolvió severidades válidas.');
      }

      // ---------------------------------------------------------
      // Guardar todos los catálogos en la base de datos local.
      // ---------------------------------------------------------

      await _localDatasource.guardarCatalogos(
        peligros: peligrosRemotos,
        consecuencias: consecuenciasRemotas,
        probabilidades: probabilidadesRemotas,
        severidades: severidadesRemotas,
      );

      // ---------------------------------------------------------
      // ACTUALIZAR MEMORIA
      // ---------------------------------------------------------

      _peligros = peligrosRemotos;

      _consecuencias = consecuenciasRemotas;

      _probabilidades = probabilidadesRemotas;

      _severidades = severidadesRemotas;

      final DateTime ahora = DateTime.now().toUtc();

      _ultimaActualizacionPeligros = ahora;

      _ultimaActualizacionConsecuencias = ahora;

      _ultimaActualizacionProbabilidades = ahora;

      _ultimaActualizacionSeveridades = ahora;

      _usandoDatosLocales = false;

      _advertencia = null;

      _error = null;

      _cargado = true;

      return true;
    } catch (error) {
      final String mensaje = _limpiarError(error);

      if (conservarLocalesEnError && tieneCatalogos) {
        _usandoDatosLocales = true;

        _advertencia =
            'No se pudo actualizar desde el servidor. '
            'Se mantienen los catálogos locales. '
            '$mensaje';

        _error = null;

        return true;
      }

      _error =
          'No se pudieron cargar los catálogos IPERC. '
          '$mensaje';

      return false;
    } finally {
      _actualizandoRemoto = false;

      notifyListeners();
    }
  }

  // =============================================================
  // BUSCAR PELIGRO
  // =============================================================

  PeligroModel? buscarPeligroPorId(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final PeligroModel peligro in _peligros) {
      if (peligro.id == id) {
        return peligro;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR CONSECUENCIA
  // =============================================================

  ConsecuenciaModel? buscarConsecuenciaPorId(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final ConsecuenciaModel consecuencia in _consecuencias) {
      if (consecuencia.id == id) {
        return consecuencia;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR PROBABILIDAD POR ID
  // =============================================================

  ProbabilidadModel? buscarProbabilidadPorId(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final ProbabilidadModel item in _probabilidades) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR SEVERIDAD POR ID
  // =============================================================

  SeveridadModel? buscarSeveridadPorId(int? id) {
    if (id == null || id <= 0) {
      return null;
    }

    for (final SeveridadModel item in _severidades) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR PROBABILIDAD POR VALOR
  // =============================================================

  ProbabilidadModel? buscarProbabilidadPorValor(int valor) {
    for (final ProbabilidadModel item in _probabilidades) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR SEVERIDAD POR VALOR
  // =============================================================

  SeveridadModel? buscarSeveridadPorValor(int valor) {
    for (final SeveridadModel item in _severidades) {
      if (item.valor == valor) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // BÚSQUEDA TEXTO
  // =============================================================

  List<PeligroModel> buscarPeligros(String texto) {
    final String consulta = texto.trim().toLowerCase();

    if (consulta.isEmpty) {
      return peligros;
    }

    return _peligros.where((PeligroModel peligro) {
      final String contenido = <String>[
        peligro.codigo,
        peligro.nombre,
        peligro.descripcion ?? '',
        peligro.tipoPeligroNombre ?? '',
        peligro.categoriaPeligroNombre ?? '',
      ].join(' ').toLowerCase();

      return contenido.contains(consulta);
    }).toList();
  }

  List<ConsecuenciaModel> buscarConsecuencias(String texto) {
    final String consulta = texto.trim().toLowerCase();

    if (consulta.isEmpty) {
      return consecuencias;
    }

    return _consecuencias.where((ConsecuenciaModel consecuencia) {
      final String contenido = <String>[
        consecuencia.codigo,
        consecuencia.nombre,
        consecuencia.descripcion ?? '',
        consecuencia.clasificacion ?? '',
      ].join(' ').toLowerCase();

      return contenido.contains(consulta);
    }).toList();
  }

  // =============================================================
  // LIMPIAR CATÁLOGOS
  // =============================================================

  Future<void> limpiarCatalogosLocales() async {
    await _localDatasource.limpiarCatalogos();

    _peligros = <PeligroModel>[];

    _consecuencias = <ConsecuenciaModel>[];

    _probabilidades = <ProbabilidadModel>[];

    _severidades = <SeveridadModel>[];

    _cargado = false;

    _usandoDatosLocales = false;

    _ultimaActualizacionPeligros = null;

    _ultimaActualizacionConsecuencias = null;

    _ultimaActualizacionProbabilidades = null;

    _ultimaActualizacionSeveridades = null;

    _error = null;

    _advertencia = null;

    notifyListeners();
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void limpiarError() {
    if (_error == null && _advertencia == null) {
      return;
    }

    _error = null;

    _advertencia = null;

    notifyListeners();
  }

  // =============================================================
  // ORDENAR PELIGROS
  // =============================================================

  void _ordenarPeligros(List<PeligroModel> lista) {
    lista.sort((PeligroModel primero, PeligroModel segundo) {
      final int comparacionNombre = primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );

      if (comparacionNombre != 0) {
        return comparacionNombre;
      }

      return primero.codigo.toLowerCase().compareTo(
        segundo.codigo.toLowerCase(),
      );
    });
  }

  // =============================================================
  // ORDENAR CONSECUENCIAS
  // =============================================================

  void _ordenarConsecuencias(List<ConsecuenciaModel> lista) {
    lista.sort((ConsecuenciaModel primero, ConsecuenciaModel segundo) {
      final int comparacionNombre = primero.nombre.toLowerCase().compareTo(
        segundo.nombre.toLowerCase(),
      );

      if (comparacionNombre != 0) {
        return comparacionNombre;
      }

      return primero.codigo.toLowerCase().compareTo(
        segundo.codigo.toLowerCase(),
      );
    });
  }

  // =============================================================
  // ORDENAR PROBABILIDADES
  // =============================================================

  void _ordenarProbabilidades(List<ProbabilidadModel> lista) {
    lista.sort((ProbabilidadModel primero, ProbabilidadModel segundo) {
      return primero.valor.compareTo(segundo.valor);
    });
  }

  // =============================================================
  // ORDENAR SEVERIDADES
  // =============================================================

  void _ordenarSeveridades(List<SeveridadModel> lista) {
    lista.sort((SeveridadModel primero, SeveridadModel segundo) {
      return primero.valor.compareTo(segundo.valor);
    });
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  String _limpiarError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'Bad state: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Error desconocido.' : mensaje;
  }
}
