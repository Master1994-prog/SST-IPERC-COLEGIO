import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/network/network_info.dart';
import '../../data/models/seguimiento_iperc_local_model.dart';
import '../../data/models/seguimiento_iperc_model.dart';
import '../../data/repositories/seguimiento_iperc_offline_repository.dart';
import '../../data/repositories/seguimiento_iperc_repository.dart';

/// ===============================================================
/// PROVIDER - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Administra el estado del módulo Seguimiento IPERC tanto para:
///
/// - Modo ONLINE.
/// - Modo OFFLINE.
///
/// IMPORTANTE:
///
/// Este provider mantiene temporalmente dos colecciones:
///
/// 1. `_seguimientos`
///    Registros obtenidos desde el backend.
///
/// 2. `_seguimientosLocales`
///    Registros almacenados en SQLite.
///
/// Esto permite actualizar el módulo por etapas sin romper las
/// pantallas online existentes. En el siguiente paso la pantalla se
/// adaptará para mostrar ambas fuentes de manera unificada.
///
/// El provider conserva los métodos públicos que ya utilizaban las
/// pantallas antiguas:
///
/// - cargarTodos()
/// - cargarPorDetalle(...)
/// - refrescar()
/// - crear(...)
/// - actualizar(...)
/// - verificar(...)
/// - eliminar(...)
///
/// y agrega métodos específicos para el flujo local.
///
/// ===============================================================
class SeguimientoIpercProvider extends ChangeNotifier {
  SeguimientoIpercProvider({
    SeguimientoIpercRepository? repository,
    SeguimientoIpercOfflineRepository? offlineRepository,
    NetworkInfo? networkInfo,
  }) : _repository = repository ?? SeguimientoIpercRepository(),
       _offlineRepository =
           offlineRepository ?? SeguimientoIpercOfflineRepository(),
       _networkInfo = networkInfo ?? NetworkInfo.instance;

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  /// Repositorio remoto.
  final SeguimientoIpercRepository _repository;

  /// Repositorio local SQLite.
  final SeguimientoIpercOfflineRepository _offlineRepository;

  /// Servicio de conectividad.
  final NetworkInfo _networkInfo;

  // =============================================================
  // DATOS
  // =============================================================

  /// Seguimientos provenientes del backend.
  final List<SeguimientoIpercModel> _seguimientos = <SeguimientoIpercModel>[];

  /// Seguimientos almacenados en SQLite.
  final List<SeguimientoIpercLocalModel> _seguimientosLocales =
      <SeguimientoIpercLocalModel>[];

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = false;

  bool _procesando = false;

  bool _isConnected = false;

  String? _error;

  String _terminoBusqueda = '';

  /// Filtro remoto actualmente aplicado.
  int? _detalleIpercIdActual;

  /// Filtro local actualmente aplicado.
  String? _detalleIpercIdLocalActual;

  // =============================================================
  // GETTERS - ESTADO
  // =============================================================

  bool get cargando => _cargando;

  bool get procesando => _procesando;

  bool get isConnected => _isConnected;

  bool get isOffline => !_isConnected;

  String? get error => _error;

  String get terminoBusqueda => _terminoBusqueda;

  bool get tieneError {
    return _error != null && _error!.trim().isNotEmpty;
  }

  // =============================================================
  // GETTERS - REMOTO
  // =============================================================

  /// Se conserva por compatibilidad con la pantalla online existente.
  UnmodifiableListView<SeguimientoIpercModel> get seguimientos {
    return UnmodifiableListView<SeguimientoIpercModel>(_seguimientos);
  }

  /// Se conserva por compatibilidad con la pantalla actual.
  List<SeguimientoIpercModel> get seguimientosFiltrados {
    final String termino = _normalizar(_terminoBusqueda);

    if (termino.isEmpty) {
      return List<SeguimientoIpercModel>.unmodifiable(_seguimientos);
    }

    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) {
          final String contenido = _normalizar(
            '${seguimiento.detalleVisible} '
            '${seguimiento.descripcion} '
            '${seguimiento.observaciones ?? ''} '
            '${seguimiento.estadoVisible}',
          );

          return contenido.contains(termino);
        })
        .toList(growable: false);
  }

  // =============================================================
  // GETTERS - LOCAL
  // =============================================================

  UnmodifiableListView<SeguimientoIpercLocalModel> get seguimientosLocales {
    return UnmodifiableListView<SeguimientoIpercLocalModel>(
      _seguimientosLocales,
    );
  }

  List<SeguimientoIpercLocalModel> get seguimientosLocalesFiltrados {
    final String termino = _normalizar(_terminoBusqueda);

    if (termino.isEmpty) {
      return List<SeguimientoIpercLocalModel>.unmodifiable(
        _seguimientosLocales,
      );
    }

    return _seguimientosLocales
        .where((SeguimientoIpercLocalModel seguimiento) {
          final String contenido = _normalizar(
            '${seguimiento.detalleVisible} '
            '${seguimiento.descripcion} '
            '${seguimiento.observaciones ?? ''} '
            '${seguimiento.estadoVisible}',
          );

          return contenido.contains(termino);
        })
        .toList(growable: false);
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  /// Indica si existe al menos un registro visible en cualquiera de
  /// los dos orígenes.
  bool get tieneSeguimientos {
    return _seguimientos.isNotEmpty || _seguimientosLocales.isNotEmpty;
  }

  /// Cantidad remota.
  int get total => _seguimientos.length;

  /// Cantidad local.
  int get totalLocales => _seguimientosLocales.length;

  int get pendientes {
    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) => !seguimiento.verificado)
        .length;
  }

  int get verificados {
    return _seguimientos
        .where((SeguimientoIpercModel seguimiento) => seguimiento.verificado)
        .length;
  }

  int get pendientesLocales {
    return _seguimientosLocales
        .where(
          (SeguimientoIpercLocalModel seguimiento) => !seguimiento.verificado,
        )
        .length;
  }

  int get verificadosLocales {
    return _seguimientosLocales
        .where(
          (SeguimientoIpercLocalModel seguimiento) => seguimiento.verificado,
        )
        .length;
  }

  int get pendientesSincronizacion {
    return _seguimientosLocales
        .where(
          (SeguimientoIpercLocalModel seguimiento) =>
              seguimiento.pendienteSincronizacion,
        )
        .length;
  }

  // =============================================================
  // ACTUALIZAR CONECTIVIDAD
  // =============================================================

  Future<bool> comprobarConexion() async {
    _isConnected = await _networkInfo.isConnected;

    notifyListeners();

    return _isConnected;
  }

  // =============================================================
  // CARGAR TODOS
  // =============================================================

  /// Carga Seguimiento IPERC.
  ///
  /// Siempre consulta SQLite.
  ///
  /// Si existe Internet también consulta el backend.
  Future<void> cargarTodos() async {
    if (_cargando) {
      return;
    }

    _detalleIpercIdActual = null;
    _detalleIpercIdLocalActual = null;

    _cargando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      // ---------------------------------------------------------
      // CARGAR DATOS LOCALES
      // ---------------------------------------------------------

      final List<SeguimientoIpercLocalModel> locales = await _offlineRepository
          .getAll();

      _seguimientosLocales
        ..clear()
        ..addAll(locales);

      _ordenarLocales();

      // ---------------------------------------------------------
      // CARGAR REMOTO SOLO CON CONEXIÓN
      // ---------------------------------------------------------

      if (_isConnected) {
        final List<SeguimientoIpercModel> remotos = await _repository
            .obtenerTodos();

        _seguimientos
          ..clear()
          ..addAll(remotos);

        _ordenarRemotos();
      } else {
        _seguimientos.clear();
      }
    } catch (error) {
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // CARGAR POR DETALLE REMOTO
  // =============================================================

  /// Método original utilizado por las pantallas online.
  ///
  /// Si no hay conexión, mantiene disponibles los datos locales,
  /// pero para filtrar correctamente los registros offline debe
  /// utilizarse `cargarPorDetalleLocal`.
  Future<void> cargarPorDetalle(int detalleIpercId) async {
    if (_cargando) {
      return;
    }

    if (detalleIpercId <= 0) {
      _error = 'El identificador del detalle IPERC no es válido.';

      notifyListeners();

      return;
    }

    _detalleIpercIdActual = detalleIpercId;
    _detalleIpercIdLocalActual = null;

    _cargando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      // ---------------------------------------------------------
      // LOCALES QUE YA CONOCEN EL ID REMOTO DEL DETALLE
      // ---------------------------------------------------------

      final List<SeguimientoIpercLocalModel> locales = await _offlineRepository
          .getByDetalleServidor(detalleIpercId);

      _seguimientosLocales
        ..clear()
        ..addAll(locales);

      _ordenarLocales();

      // ---------------------------------------------------------
      // BACKEND
      // ---------------------------------------------------------

      if (_isConnected) {
        final List<SeguimientoIpercModel> resultado = await _repository
            .obtenerPorDetalle(detalleIpercId);

        _seguimientos
          ..clear()
          ..addAll(resultado);

        _ordenarRemotos();
      } else {
        _seguimientos.clear();
      }
    } catch (error) {
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // CARGAR POR DETALLE LOCAL
  // =============================================================

  /// Carga seguimientos usando el UUID local del Detalle IPERC.
  ///
  /// Este método permite trabajar incluso si el detalle todavía no
  /// tiene ID en MySQL.
  Future<void> cargarPorDetalleLocal(String detalleIpercIdLocal) async {
    if (_cargando) {
      return;
    }

    final String detalleLocal = detalleIpercIdLocal.trim();

    if (detalleLocal.isEmpty) {
      _error = 'El identificador local del detalle IPERC no es válido.';

      notifyListeners();

      return;
    }

    _detalleIpercIdActual = null;
    _detalleIpercIdLocalActual = detalleLocal;

    _cargando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      final List<SeguimientoIpercLocalModel> locales = await _offlineRepository
          .getByDetalleLocal(detalleLocal);

      _seguimientosLocales
        ..clear()
        ..addAll(locales);

      _ordenarLocales();

      // No existe una consulta remota posible si únicamente tenemos
      // un UUID local del Detalle IPERC.
      _seguimientos.clear();
    } catch (error) {
      _error = _limpiarMensaje(error);
    } finally {
      _cargando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // REFRESCAR
  // =============================================================

  Future<void> refrescar() async {
    final String? detalleLocal = _detalleIpercIdLocalActual;

    if (detalleLocal != null && detalleLocal.isNotEmpty) {
      await cargarPorDetalleLocal(detalleLocal);

      return;
    }

    final int? detalleServidor = _detalleIpercIdActual;

    if (detalleServidor != null && detalleServidor > 0) {
      await cargarPorDetalle(detalleServidor);

      return;
    }

    await cargarTodos();
  }

  // =============================================================
  // CREAR ONLINE
  // =============================================================

  /// Mantiene el método existente para compatibilidad con el
  /// formulario actual.
  Future<bool> crear(CrearSeguimientoIpercRequest request) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      if (!_isConnected) {
        throw StateError(
          'No hay conexión. Para registrar el seguimiento '
          'offline debe utilizarse el Detalle IPERC local.',
        );
      }

      final SeguimientoIpercModel creado = await _repository.crear(request);

      _seguimientos.insert(0, creado);

      _ordenarRemotos();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // CREAR OFFLINE
  // =============================================================

  /// Registra un seguimiento en SQLite.
  ///
  /// El usuario NO se recibe como parámetro porque el repositorio
  /// obtiene el usuario autenticado directamente desde
  /// FlutterSecureStorage.
  Future<bool> crearOffline({
    required String detalleIpercIdLocal,
    required DateTime fechaSeguimiento,
    required String descripcion,
    required double porcentajeAvance,
    String? observaciones,
    String? archivo,
    String? nombreArchivo,
    String? tipoArchivo,
  }) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      final SeguimientoIpercLocalModel creado = await _offlineRepository
          .createOffline(
            detalleIpercIdLocal: detalleIpercIdLocal,
            fechaSeguimiento: fechaSeguimiento,
            descripcion: descripcion,
            porcentajeAvance: porcentajeAvance,
            observaciones: observaciones,
            archivo: archivo,
            nombreArchivo: nombreArchivo,
            tipoArchivo: tipoArchivo,
          );

      _seguimientosLocales.insert(0, creado);

      _ordenarLocales();

      _isConnected = await _networkInfo.isConnected;

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR ONLINE
  // =============================================================

  Future<bool> actualizar(
    int id,
    ActualizarSeguimientoIpercRequest request,
  ) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      if (!_isConnected) {
        throw StateError(
          'No hay conexión para actualizar este seguimiento remoto.',
        );
      }

      final SeguimientoIpercModel actualizado = await _repository.actualizar(
        id,
        request,
      );

      final int index = _seguimientos.indexWhere(
        (SeguimientoIpercModel seguimiento) => seguimiento.id == id,
      );

      if (index >= 0) {
        _seguimientos[index] = actualizado;
      } else {
        _seguimientos.add(actualizado);
      }

      _ordenarRemotos();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ACTUALIZAR OFFLINE
  // =============================================================

  Future<bool> actualizarOffline({
    required String idLocal,
    required DateTime fechaSeguimiento,
    required String descripcion,
    required double porcentajeAvance,
    String? observaciones,
    String? archivo,
    String? nombreArchivo,
    String? tipoArchivo,
  }) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      final SeguimientoIpercLocalModel actualizado = await _offlineRepository
          .updateOffline(
            idLocal: idLocal,
            fechaSeguimiento: fechaSeguimiento,
            descripcion: descripcion,
            porcentajeAvance: porcentajeAvance,
            observaciones: observaciones,
            archivo: archivo,
            nombreArchivo: nombreArchivo,
            tipoArchivo: tipoArchivo,
          );

      final int index = _seguimientosLocales.indexWhere(
        (SeguimientoIpercLocalModel seguimiento) =>
            seguimiento.idLocal == idLocal,
      );

      if (index >= 0) {
        _seguimientosLocales[index] = actualizado;
      } else {
        _seguimientosLocales.add(actualizado);
      }

      _ordenarLocales();

      _isConnected = await _networkInfo.isConnected;

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // VERIFICAR ONLINE
  // =============================================================

  Future<bool> verificar(int id) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      if (!_isConnected) {
        throw StateError(
          'No hay conexión para verificar este seguimiento remoto.',
        );
      }

      await _repository.verificar(id);

      await refrescar();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // VERIFICAR OFFLINE
  // =============================================================

  Future<bool> verificarOffline({required String idLocal}) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      final SeguimientoIpercLocalModel actualizado = await _offlineRepository
          .verifyOffline(idLocal: idLocal);

      final int index = _seguimientosLocales.indexWhere(
        (SeguimientoIpercLocalModel seguimiento) =>
            seguimiento.idLocal == idLocal,
      );

      if (index >= 0) {
        _seguimientosLocales[index] = actualizado;
      }

      _ordenarLocales();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // QUITAR VERIFICACIÓN OFFLINE
  // =============================================================

  Future<bool> quitarVerificacionOffline({required String idLocal}) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      final SeguimientoIpercLocalModel actualizado = await _offlineRepository
          .unverifyOffline(idLocal: idLocal);

      final int index = _seguimientosLocales.indexWhere(
        (SeguimientoIpercLocalModel seguimiento) =>
            seguimiento.idLocal == idLocal,
      );

      if (index >= 0) {
        _seguimientosLocales[index] = actualizado;
      }

      _ordenarLocales();

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ELIMINAR ONLINE
  // =============================================================

  Future<bool> eliminar(int id) async {
    if (_procesando || id <= 0) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      _isConnected = await _networkInfo.isConnected;

      if (!_isConnected) {
        throw StateError(
          'No hay conexión para eliminar este seguimiento remoto.',
        );
      }

      await _repository.eliminar(id);

      _seguimientos.removeWhere(
        (SeguimientoIpercModel seguimiento) => seguimiento.id == id,
      );

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // ELIMINAR OFFLINE
  // =============================================================

  Future<bool> eliminarOffline({required String idLocal}) async {
    if (_procesando) {
      return false;
    }

    _procesando = true;
    _error = null;

    notifyListeners();

    try {
      await _offlineRepository.deleteOffline(idLocal: idLocal);

      _seguimientosLocales.removeWhere(
        (SeguimientoIpercLocalModel seguimiento) =>
            seguimiento.idLocal == idLocal,
      );

      return true;
    } catch (error) {
      _error = _limpiarMensaje(error);

      return false;
    } finally {
      _procesando = false;

      notifyListeners();
    }
  }

  // =============================================================
  // BÚSQUEDA
  // =============================================================

  void buscar(String valor) {
    _terminoBusqueda = valor.trim();

    notifyListeners();
  }

  void limpiarBusqueda() {
    if (_terminoBusqueda.isEmpty) {
      return;
    }

    _terminoBusqueda = '';

    notifyListeners();
  }

  // =============================================================
  // ERROR
  // =============================================================

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }

  // =============================================================
  // ORDENAR
  // =============================================================

  void _ordenarRemotos() {
    _seguimientos.sort(
      (SeguimientoIpercModel a, SeguimientoIpercModel b) =>
          b.fechaSeguimiento.compareTo(a.fechaSeguimiento),
    );
  }

  void _ordenarLocales() {
    _seguimientosLocales.sort(
      (SeguimientoIpercLocalModel a, SeguimientoIpercLocalModel b) =>
          b.fechaSeguimiento.compareTo(a.fechaSeguimiento),
    );
  }

  // =============================================================
  // HELPERS
  // =============================================================

  String _limpiarMensaje(Object error) {
    return error
        .toString()
        .replaceFirst('Exception:', '')
        .replaceFirst('Bad state:', '')
        .trim();
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}
