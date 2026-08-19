import 'dart:convert';
import 'dart:io';

import '../datasources/local/mapa_riesgo_local_datasource.dart';
import '../datasources/remote/mapa_riesgo_remote_datasource.dart';
import '../models/mapa_riesgo_model.dart';
import '../models/sync_queue_model.dart';
import '../../core/constants/sync_constants.dart';

/// ===============================================================
/// SINCRONIZACIÓN ESPECIALIZADA - MAPA DE RIESGO
/// ===============================================================
class MapaRiesgoSyncService {
  MapaRiesgoSyncService({
    MapaRiesgoLocalDatasource? localDatasource,
    MapaRiesgoRemoteDatasource? remoteDatasource,
  }) : _local = localDatasource ?? MapaRiesgoLocalDatasource(),
       _remote = remoteDatasource ?? MapaRiesgoRemoteDatasource();

  final MapaRiesgoLocalDatasource _local;
  final MapaRiesgoRemoteDatasource _remote;

  Future<void> synchronizeQueueItem(SyncQueueModel item) async {
    final String operacion = item.operacion.trim().toUpperCase();

    if (operacion != SyncConstants.crear &&
        operacion != SyncConstants.actualizar) {
      throw UnsupportedError(
        'Operación no soportada para MAPA_RIESGO: '
        '$operacion.',
      );
    }

    final dynamic decoded = jsonDecode(item.datosJson);

    if (decoded is! Map) {
      throw const FormatException(
        'Los datos del mapa de riesgo no son válidos.',
      );
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

    final int matrizIpercId = _requiredInt(
      data['matrizIpercId'],
      'matrizIpercId',
    );

    final String nombre = data['nombre']?.toString().trim() ?? '';

    if (nombre.isEmpty) {
      throw const FormatException('El mapa de riesgo no contiene nombre.');
    }

    final String marcadoresJson = data['marcadoresJson']?.toString() ?? '{}';

    String? archivoUrlServidor = _optionalText(data['archivoUrlServidor']);

    String? tipoArchivo = _optionalText(data['tipoArchivo']);

    final String? archivoLocal = _optionalText(data['archivoLocal']);

    // Si el plano sigue disponible en el teléfono,
    // lo subimos primero.
    if (archivoLocal != null) {
      final File file = File(archivoLocal);

      if (await file.exists()) {
        final Map<String, String> subida = await _remote.subirPlano(
          archivoLocal,
        );

        archivoUrlServidor = subida['archivoUrl'];

        tipoArchivo = subida['tipoArchivo'];
      } else if (archivoUrlServidor == null) {
        throw StateError('El archivo local del plano ya no existe.');
      }
    }

    int? mapaIdServidor = _optionalInt(data['mapaIdServidor']);

    // La fila local puede tener un ID remoto más reciente
    // que el JSON original de la cola.
    final local = await _local.obtenerPorLocal(item.entidadIdLocal);

    mapaIdServidor ??= local?.idServidor;

    final MapaRiesgoModel model = MapaRiesgoModel(
      id: mapaIdServidor ?? 0,
      codigo: _optionalText(data['codigo']) ?? local?.codigo ?? '',
      nombre: nombre,
      descripcion: _optionalText(data['descripcion']),
      ubicacion: _optionalText(data['ubicacion']),
      archivoUrl: archivoUrlServidor,
      tipoArchivo: tipoArchivo,
      marcadoresJson: marcadoresJson,
      fechaElaboracion: local?.fechaElaboracion ?? DateTime.now(),
      fechaRevision: DateTime.now(),
      version: _optionalInt(data['version']) ?? local?.version ?? 1,
      estadoMapa: _optionalText(data['estadoMapa']) ?? 'Vigente',
      activo: true,
      matrizIpercId: matrizIpercId,
    );

    late MapaRiesgoModel remoto;

    if (mapaIdServidor != null && mapaIdServidor > 0) {
      await _remote.actualizar(model);

      final List<MapaRiesgoModel> mapas = await _remote.obtenerPorMatriz(
        matrizIpercId,
      );

      remoto = mapas.firstWhere(
        (MapaRiesgoModel item) => item.id == mapaIdServidor,
        orElse: () => model,
      );
    } else {
      remoto = await _remote.crear(model);
    }

    if (remoto.id <= 0) {
      throw StateError('El backend no devolvió el ID del mapa de riesgo.');
    }

    await _local.marcarSincronizado(
      idLocal: item.entidadIdLocal,
      idServidor: remoto.id,
      codigo: remoto.codigo,
      archivoUrlServidor: remoto.archivoUrl ?? archivoUrlServidor,
      tipoArchivo: remoto.tipoArchivo ?? tipoArchivo,
    );
  }

  int _requiredInt(dynamic value, String field) {
    final int? number = _optionalInt(value);

    if (number == null || number <= 0) {
      throw FormatException('El campo $field no es válido.');
    }

    return number;
  }

  int? _optionalInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  String? _optionalText(dynamic value) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}
