import '../../data/datasources/local/detalle_iperc_catalogos_local_datasource.dart';
import '../../data/models/consecuencia_model.dart';
import '../../data/models/peligro_model.dart';
import '../../data/models/probabilidad_model.dart';
import '../../data/models/severidad_model.dart';
import '../../data/repositories/consecuencia_repository.dart';
import '../../data/repositories/peligro_repository.dart';
import '../../data/repositories/probabilidad_repository.dart';
import '../../data/repositories/severidad_repository.dart';
import '../network/network_info.dart';

/// ===============================================================
/// SERVICIO - PRECARGA DE CATÁLOGOS IPERC
/// ===============================================================
///
/// Descarga y guarda en SQLite los catálogos necesarios para que:
///
/// "Agregar peligro evaluado"
///
/// pueda abrirse posteriormente sin conexión a Internet.
///
/// Catálogos almacenados:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// La precarga es tolerante a fallos:
///
/// - Si un catálogo falla, los demás siguen descargándose.
/// - Nunca elimina un catálogo local válido por una respuesta vacía.
/// - Probabilidad y Severidad solo se guardan si contienen la escala
///   completa 1, 2, 3, 4 y 5.
///
/// Este servicio no muestra mensajes en pantalla. Está pensado para
/// ejecutarse silenciosamente después de un login online correcto.
/// ===============================================================
class IpercCatalogPreloadService {
  IpercCatalogPreloadService({
    NetworkInfo? networkInfo,
    PeligroRepository? peligroRepository,
    ConsecuenciaRepository? consecuenciaRepository,
    ProbabilidadRepository? probabilidadRepository,
    SeveridadRepository? severidadRepository,
    DetalleIpercCatalogosLocalDatasource? localDatasource,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _peligroRepository = peligroRepository ?? PeligroRepository(),
       _consecuenciaRepository =
           consecuenciaRepository ?? ConsecuenciaRepository(),
       _probabilidadRepository =
           probabilidadRepository ?? ProbabilidadRepository(),
       _severidadRepository = severidadRepository ?? SeveridadRepository(),
       _localDatasource =
           localDatasource ?? DetalleIpercCatalogosLocalDatasource();

  final NetworkInfo _networkInfo;

  final PeligroRepository _peligroRepository;

  final ConsecuenciaRepository _consecuenciaRepository;

  final ProbabilidadRepository _probabilidadRepository;

  final SeveridadRepository _severidadRepository;

  final DetalleIpercCatalogosLocalDatasource _localDatasource;

  /// Evita ejecutar dos precargas simultáneas.
  bool _ejecutando = false;

  // =============================================================
  // PRECARGAR
  // =============================================================

  /// Descarga todos los catálogos disponibles.
  ///
  /// Retorna `true` cuando al terminar existen localmente los cuatro
  /// catálogos necesarios para utilizar el formulario IPERC offline.
  Future<bool> preload() async {
    if (_ejecutando) {
      return _catalogosLocalesCompletos();
    }

    _ejecutando = true;

    try {
      // ---------------------------------------------------------
      // VERIFICAR INTERNET REAL
      // ---------------------------------------------------------

      final bool conectado = await _networkInfo.isConnected;

      if (!conectado) {
        return _catalogosLocalesCompletos();
      }

      // ---------------------------------------------------------
      // PREPARAR TABLAS SQLITE
      // ---------------------------------------------------------

      await _localDatasource.prepararTablas();

      // Cada catálogo se descarga por separado.
      // Un fallo no cancela los demás.
      await _precargarPeligros();
      await _precargarConsecuencias();
      await _precargarProbabilidades();
      await _precargarSeveridades();

      return _catalogosLocalesCompletos();
    } finally {
      _ejecutando = false;
    }
  }

  // =============================================================
  // PELIGROS
  // =============================================================

  Future<void> _precargarPeligros() async {
    try {
      final List<PeligroModel> resultado = await _peligroRepository
          .obtenerActivos();

      final List<PeligroModel> validos = resultado
          .where(
            (PeligroModel item) =>
                item.id > 0 &&
                item.estaDisponible &&
                item.codigo.trim().isNotEmpty &&
                item.nombre.trim().isNotEmpty &&
                item.tipoPeligroId > 0,
          )
          .toList(growable: false);

      if (validos.isEmpty) {
        return;
      }

      await _localDatasource.guardarPeligros(validos);
    } catch (_) {
      // El formulario podrá usar el último catálogo local válido.
    }
  }

  // =============================================================
  // CONSECUENCIAS
  // =============================================================

  Future<void> _precargarConsecuencias() async {
    try {
      final List<ConsecuenciaModel> resultado = await _consecuenciaRepository
          .obtenerActivos();

      final List<ConsecuenciaModel> validos = resultado
          .where(
            (ConsecuenciaModel item) =>
                item.id > 0 &&
                item.estaDisponible &&
                item.codigo.trim().isNotEmpty &&
                item.nombre.trim().isNotEmpty,
          )
          .toList(growable: false);

      if (validos.isEmpty) {
        return;
      }

      await _localDatasource.guardarConsecuencias(validos);
    } catch (_) {
      // Se conserva SQLite.
    }
  }

  // =============================================================
  // PROBABILIDADES
  // =============================================================

  Future<void> _precargarProbabilidades() async {
    try {
      final List<ProbabilidadModel> resultado = await _probabilidadRepository
          .obtenerTodas();

      final List<ProbabilidadModel> validos = resultado
          .where(
            (ProbabilidadModel item) =>
                item.id > 0 &&
                item.valor >= 1 &&
                item.valor <= 5 &&
                item.nombre.trim().isNotEmpty,
          )
          .toList(growable: false);

      // Nunca sustituimos una escala buena por una incompleta.
      if (!_escalaProbabilidadesCompleta(validos)) {
        return;
      }

      await _localDatasource.guardarProbabilidades(validos);
    } catch (_) {
      // Se conserva SQLite.
    }
  }

  // =============================================================
  // SEVERIDADES
  // =============================================================

  Future<void> _precargarSeveridades() async {
    try {
      final List<SeveridadModel> resultado = await _severidadRepository
          .obtenerTodas();

      final List<SeveridadModel> validos = resultado
          .where(
            (SeveridadModel item) =>
                item.id > 0 &&
                item.valor >= 1 &&
                item.valor <= 5 &&
                item.nombre.trim().isNotEmpty,
          )
          .toList(growable: false);

      if (!_escalaSeveridadesCompleta(validos)) {
        return;
      }

      await _localDatasource.guardarSeveridades(validos);
    } catch (_) {
      // Se conserva SQLite.
    }
  }

  // =============================================================
  // COMPROBAR SQLITE
  // =============================================================

  Future<bool> _catalogosLocalesCompletos() async {
    try {
      final List<PeligroModel> peligros = await _localDatasource
          .obtenerPeligros();

      final List<ConsecuenciaModel> consecuencias = await _localDatasource
          .obtenerConsecuencias();

      final List<ProbabilidadModel> probabilidades = await _localDatasource
          .obtenerProbabilidades();

      final List<SeveridadModel> severidades = await _localDatasource
          .obtenerSeveridades();

      return peligros.isNotEmpty &&
          consecuencias.isNotEmpty &&
          _escalaProbabilidadesCompleta(probabilidades) &&
          _escalaSeveridadesCompleta(severidades);
    } catch (_) {
      return false;
    }
  }

  // =============================================================
  // VALIDAR ESCALA 1..5
  // =============================================================

  bool _escalaProbabilidadesCompleta(List<ProbabilidadModel> items) {
    final Set<int> valores = items
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((ProbabilidadModel item) => item.valor)
        .toSet();

    return _contieneEscalaCompleta(valores);
  }

  bool _escalaSeveridadesCompleta(List<SeveridadModel> items) {
    final Set<int> valores = items
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((SeveridadModel item) => item.valor)
        .toSet();

    return _contieneEscalaCompleta(valores);
  }

  bool _contieneEscalaCompleta(Set<int> valores) {
    return valores.contains(1) &&
        valores.contains(2) &&
        valores.contains(3) &&
        valores.contains(4) &&
        valores.contains(5);
  }
}
