import 'package:flutter/foundation.dart';

import '../../data/datasources/local/detalle_iperc_catalogos_local_datasource.dart';
import '../../data/models/consecuencia_model.dart';
import '../../data/models/peligro_model.dart';
import '../../data/repositories/consecuencia_repository.dart';
import '../../data/repositories/peligro_repository.dart';

/// Administra los catálogos necesarios para registrar detalles IPERC.
///
/// Estrategia:
///
/// 1. Carga inmediatamente los catálogos guardados en SQLite.
/// 2. Intenta obtener información actualizada desde el backend.
/// 3. Guarda en SQLite los datos recibidos.
/// 4. Si no hay conexión, mantiene disponibles los datos locales.
class DetalleIpercCatalogosProvider extends ChangeNotifier {
  DetalleIpercCatalogosProvider({
    PeligroRepository? peligroRepository,
    ConsecuenciaRepository? consecuenciaRepository,
    DetalleIpercCatalogosLocalDatasource? localDatasource,
  }) : _peligroRepository = peligroRepository ?? PeligroRepository(),
       _consecuenciaRepository =
           consecuenciaRepository ?? ConsecuenciaRepository(),
       _localDatasource =
           localDatasource ?? DetalleIpercCatalogosLocalDatasource();

  final PeligroRepository _peligroRepository;
  final ConsecuenciaRepository _consecuenciaRepository;
  final DetalleIpercCatalogosLocalDatasource _localDatasource;

  List<PeligroModel> _peligros = <PeligroModel>[];
  List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];

  bool _cargando = false;
  bool _cargandoLocal = false;
  bool _actualizandoRemoto = false;
  bool _cargado = false;
  bool _usandoDatosLocales = false;

  String? _error;
  String? _advertencia;

  DateTime? _ultimaActualizacionPeligros;
  DateTime? _ultimaActualizacionConsecuencias;

  // ============================================================
  // GETTERS
  // ============================================================

  List<PeligroModel> get peligros {
    return List<PeligroModel>.unmodifiable(_peligros);
  }

  List<ConsecuenciaModel> get consecuencias {
    return List<ConsecuenciaModel>.unmodifiable(_consecuencias);
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

  bool get tieneError {
    return _error != null && _error!.trim().isNotEmpty;
  }

  bool get tieneAdvertencia {
    return _advertencia != null && _advertencia!.trim().isNotEmpty;
  }

  bool get tienePeligros => _peligros.isNotEmpty;

  bool get tieneConsecuencias => _consecuencias.isNotEmpty;

  bool get tieneCatalogos {
    return tienePeligros && tieneConsecuencias;
  }

  // ============================================================
  // CARGA PRINCIPAL
  // ============================================================

  /// Carga los catálogos locales y después intenta actualizarlos
  /// desde el backend.
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
      await _cargarDesdeLocal();

      await _actualizarDesdeRemoto(conservarLocalesEnError: true);

      _cargado = tieneCatalogos;

      if (!tieneCatalogos && _error == null) {
        _error = 'No existen peligros y consecuencias disponibles.';
      }

      return tieneCatalogos;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Fuerza la actualización desde el backend.
  ///
  /// Si falla, conserva los registros locales existentes.
  Future<bool> recargar() async {
    if (_cargando || _actualizandoRemoto) {
      return tieneCatalogos;
    }

    _error = null;
    _advertencia = null;

    notifyListeners();

    return _actualizarDesdeRemoto(conservarLocalesEnError: true);
  }

  // ============================================================
  // CARGA LOCAL
  // ============================================================

  Future<void> _cargarDesdeLocal() async {
    _cargandoLocal = true;

    notifyListeners();

    try {
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _localDatasource.obtenerPeligros(),
            _localDatasource.obtenerConsecuencias(),
            _localDatasource.obtenerFechaActualizacion('PELIGROS'),
            _localDatasource.obtenerFechaActualizacion('CONSECUENCIAS'),
          ]);

      final List<PeligroModel> peligrosLocales =
          (resultados[0] as List<dynamic>)
              .whereType<PeligroModel>()
              .where(
                (PeligroModel peligro) =>
                    peligro.id > 0 && peligro.estaDisponible,
              )
              .toList();

      final List<ConsecuenciaModel> consecuenciasLocales =
          (resultados[1] as List<dynamic>)
              .whereType<ConsecuenciaModel>()
              .where(
                (ConsecuenciaModel consecuencia) =>
                    consecuencia.id > 0 && consecuencia.estaDisponible,
              )
              .toList();

      _ordenarPeligros(peligrosLocales);
      _ordenarConsecuencias(consecuenciasLocales);

      if (peligrosLocales.isNotEmpty) {
        _peligros = peligrosLocales;
      }

      if (consecuenciasLocales.isNotEmpty) {
        _consecuencias = consecuenciasLocales;
      }

      _ultimaActualizacionPeligros = resultados[2] as DateTime?;

      _ultimaActualizacionConsecuencias = resultados[3] as DateTime?;

      _usandoDatosLocales =
          peligrosLocales.isNotEmpty || consecuenciasLocales.isNotEmpty;

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

  // ============================================================
  // ACTUALIZACIÓN REMOTA
  // ============================================================

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
          ]);

      final List<PeligroModel> peligrosRemotos =
          (resultados[0] as List<dynamic>)
              .whereType<PeligroModel>()
              .where(
                (PeligroModel peligro) =>
                    peligro.id > 0 && peligro.estaDisponible,
              )
              .toList();

      final List<ConsecuenciaModel> consecuenciasRemotas =
          (resultados[1] as List<dynamic>)
              .whereType<ConsecuenciaModel>()
              .where(
                (ConsecuenciaModel consecuencia) =>
                    consecuencia.id > 0 && consecuencia.estaDisponible,
              )
              .toList();

      _ordenarPeligros(peligrosRemotos);
      _ordenarConsecuencias(consecuenciasRemotas);

      if (peligrosRemotos.isEmpty) {
        throw StateError('El backend no devolvió peligros activos.');
      }

      if (consecuenciasRemotas.isEmpty) {
        throw StateError('El backend no devolvió consecuencias activas.');
      }

      await _localDatasource.guardarCatalogos(
        peligros: peligrosRemotos,
        consecuencias: consecuenciasRemotas,
      );

      _peligros = peligrosRemotos;
      _consecuencias = consecuenciasRemotas;

      final DateTime ahora = DateTime.now().toUtc();

      _ultimaActualizacionPeligros = ahora;
      _ultimaActualizacionConsecuencias = ahora;

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

  // ============================================================
  // BÚSQUEDAS
  // ============================================================

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

  // ============================================================
  // LIMPIEZA
  // ============================================================

  Future<void> limpiarCatalogosLocales() async {
    await _localDatasource.limpiarCatalogos();

    _peligros = <PeligroModel>[];
    _consecuencias = <ConsecuenciaModel>[];

    _cargado = false;
    _usandoDatosLocales = false;

    _ultimaActualizacionPeligros = null;
    _ultimaActualizacionConsecuencias = null;

    _error = null;
    _advertencia = null;

    notifyListeners();
  }

  void limpiarError() {
    if (_error == null && _advertencia == null) {
      return;
    }

    _error = null;
    _advertencia = null;

    notifyListeners();
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

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
