import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/sync_constants.dart';
import '../datasources/local/mapa_riesgo_local_datasource.dart';
import '../datasources/local/sync_queue_local_datasource.dart';
import '../datasources/remote/mapa_riesgo_remote_datasource.dart';
import '../models/mapa_riesgo_local_model.dart';
import '../models/mapa_riesgo_model.dart';
import '../models/sync_queue_model.dart';

/// ===============================================================
/// REPOSITORIO HÍBRIDO - MAPAS DE RIESGO
/// ===============================================================
///
/// Online:
/// - sube plano;
/// - crea/actualiza backend;
/// - actualiza SQLite.
///
/// Offline:
/// - guarda plano + marcadores en SQLite;
/// - agrega MAPA_RIESGO a sincronizaciones_pendientes.
/// ===============================================================
class MapaRiesgoRepository {
  MapaRiesgoRepository({
    MapaRiesgoRemoteDatasource? remote,
    MapaRiesgoLocalDatasource? local,
    SyncQueueLocalDatasource? syncQueue,
  }) : _remote = remote ?? MapaRiesgoRemoteDatasource(),
       _local = local ?? MapaRiesgoLocalDatasource(),
       _syncQueue = syncQueue ?? SyncQueueLocalDatasource();

  final MapaRiesgoRemoteDatasource _remote;
  final MapaRiesgoLocalDatasource _local;
  final SyncQueueLocalDatasource _syncQueue;

  static const Uuid _uuid = Uuid();

  Future<List<MapaRiesgoLocalModel>> obtenerLocalesPorMatriz(
    int matrizIpercIdServidor,
  ) {
    return _local.obtenerPorMatriz(matrizIpercIdServidor);
  }

  Future<List<MapaRiesgoLocalModel>> refrescarDesdeServidor(
    int matrizIpercIdServidor,
  ) async {
    final List<MapaRiesgoModel> remotos = await _remote.obtenerPorMatriz(
      matrizIpercIdServidor,
    );

    for (final MapaRiesgoModel remoto in remotos) {
      final MapaRiesgoLocalModel? existente = await _local.obtenerPorServidor(
        remoto.id,
      );

      String? archivoLocal = existente?.archivoLocal;

      if (remoto.archivoUrl != null && remoto.archivoUrl!.trim().isNotEmpty) {
        archivoLocal = await _descargarPlano(
          remoto: remoto,
          existente: existente,
        );
      }

      await _local.guardar(
        MapaRiesgoLocalModel.fromRemote(
          remoto,
          idLocal: existente?.idLocal ?? _uuid.v4(),
          archivoLocal: archivoLocal,
        ),
      );
    }

    return _local.obtenerPorMatriz(matrizIpercIdServidor);
  }

  Future<MapaRiesgoLocalModel> guardarEnServidor({
    required int matrizIpercId,
    required String nombre,
    required String marcadoresJson,
    String? descripcion,
    String? ubicacion,
    String? archivoLocal,
    int? mapaIdServidor,
    String? codigo,
    String? archivoUrlServidor,
    String? tipoArchivo,
    int version = 1,
    String estadoMapa = 'Vigente',
  }) async {
    String? urlServidor = archivoUrlServidor;
    String? mime = tipoArchivo;

    if (archivoLocal != null && archivoLocal.trim().isNotEmpty) {
      final Map<String, String> subida = await _remote.subirPlano(archivoLocal);

      urlServidor = subida['archivoUrl'];
      mime = subida['tipoArchivo'];
    }

    final MapaRiesgoModel model = MapaRiesgoModel(
      id: mapaIdServidor ?? 0,
      codigo: codigo ?? '',
      nombre: nombre,
      descripcion: descripcion,
      ubicacion: ubicacion,
      archivoUrl: urlServidor,
      tipoArchivo: mime,
      marcadoresJson: marcadoresJson,
      fechaElaboracion: DateTime.now(),
      fechaRevision: DateTime.now(),
      version: version,
      estadoMapa: estadoMapa,
      activo: true,
      matrizIpercId: matrizIpercId,
    );

    late MapaRiesgoModel remoto;

    if (mapaIdServidor != null && mapaIdServidor > 0) {
      await _remote.actualizar(model);

      final List<MapaRiesgoModel> recarga = await _remote.obtenerPorMatriz(
        matrizIpercId,
      );

      remoto = recarga.firstWhere(
        (MapaRiesgoModel item) => item.id == mapaIdServidor,
        orElse: () => model,
      );
    } else {
      remoto = await _remote.crear(model);
    }

    final MapaRiesgoLocalModel? existente = remoto.id > 0
        ? await _local.obtenerPorServidor(remoto.id)
        : null;

    final MapaRiesgoLocalModel local = MapaRiesgoLocalModel.fromRemote(
      remoto,
      idLocal: existente?.idLocal ?? _uuid.v4(),
      archivoLocal: archivoLocal ?? existente?.archivoLocal,
    );

    await _local.guardar(local);

    return local;
  }

  /// Guarda el mapa aunque no exista conexión.
  ///
  /// La imagen permanece dentro del almacenamiento privado de la app
  /// y su ruta se incorpora a datos_json para subirla posteriormente.
  Future<MapaRiesgoLocalModel> guardarPendienteOffline({
    required int matrizIpercId,
    required String nombre,
    required String marcadoresJson,
    required String archivoLocal,
    String? descripcion,
    String? ubicacion,
    MapaRiesgoLocalModel? existente,
    int version = 1,
    String estadoMapa = 'Vigente',
  }) async {
    final String ruta = archivoLocal.trim();

    if (ruta.isEmpty || !await File(ruta).exists()) {
      throw StateError('El archivo local del plano no existe.');
    }

    final DateTime ahora = DateTime.now().toUtc();

    final String idLocal = existente?.idLocal ?? _uuid.v4();

    final MapaRiesgoLocalModel local = MapaRiesgoLocalModel(
      idLocal: idLocal,
      idServidor: existente?.idServidor,
      matrizIpercIdServidor: matrizIpercId,
      nombre: nombre,
      codigo: existente?.codigo,
      descripcion: descripcion,
      ubicacion: ubicacion,
      archivoUrlServidor: existente?.archivoUrlServidor,
      archivoLocal: ruta,
      tipoArchivo: existente?.tipoArchivo,
      marcadoresJson: marcadoresJson,
      fechaElaboracion: existente?.fechaElaboracion ?? ahora,
      fechaRevision: ahora,
      version: existente?.version ?? version,
      estadoMapa: estadoMapa,
      activo: true,
      sincronizado: false,
      eliminado: false,
      fechaRegistro: existente?.fechaRegistro ?? ahora,
      fechaActualizacion: ahora,
      fechaSincronizacion: existente?.fechaSincronizacion,
    );

    await _local.guardar(local);

    final String operacion = local.idServidor != null && local.idServidor! > 0
        ? SyncConstants.actualizar
        : SyncConstants.crear;

    final Map<String, dynamic> queueData = <String, dynamic>{
      'matrizIpercId': matrizIpercId,
      'nombre': nombre,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'marcadoresJson': marcadoresJson,
      'archivoLocal': ruta,
      'mapaIdServidor': local.idServidor,
      'codigo': local.codigo,
      'archivoUrlServidor': local.archivoUrlServidor,
      'tipoArchivo': local.tipoArchivo,
      'version': local.version,
      'estadoMapa': estadoMapa,
    };

    await _syncQueue.insert(
      SyncQueueModel(
        entidad: SyncConstants.mapaRiesgo,
        entidadIdLocal: idLocal,
        operacion: operacion,
        datosJson: jsonEncode(queueData),
        fechaCreacion: ahora,
      ),
    );

    return local;
  }

  Future<String?> _descargarPlano({
    required MapaRiesgoModel remoto,
    required MapaRiesgoLocalModel? existente,
  }) async {
    final String archivoUrl = remoto.archivoUrl!.trim();

    if (existente != null &&
        existente.archivoUrlServidor == archivoUrl &&
        existente.archivoLocal != null) {
      final File cached = File(existente.archivoLocal!);

      if (await cached.exists()) {
        return cached.path;
      }
    }

    final Directory directory = await getApplicationDocumentsDirectory();

    final Directory mapasDir = Directory(
      p.join(directory.path, 'mapas_riesgo_cache'),
    );

    if (!await mapasDir.exists()) {
      await mapasDir.create(recursive: true);
    }

    String extension = p.extension(Uri.parse(archivoUrl).path);

    if (extension.isEmpty) {
      extension = '.jpg';
    }

    final String destino = p.join(mapasDir.path, 'mapa_${remoto.id}$extension');

    await Dio().download(_remote.resolverUrlArchivo(archivoUrl), destino);

    return destino;
  }
}
