import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/mapa_riesgo_local_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - MAPAS DE RIESGO
/// ===============================================================
class MapaRiesgoLocalDatasource {
  MapaRiesgoLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String table = 'mapas_riesgo_local';

  Future<List<MapaRiesgoLocalModel>> obtenerTodos() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      table,
      where: 'eliminado = 0',
      orderBy: 'fecha_actualizacion DESC, fecha_registro DESC',
    );

    return rows.map(MapaRiesgoLocalModel.fromMap).toList(growable: false);
  }

  Future<List<MapaRiesgoLocalModel>> obtenerPorMatriz(
    int matrizIpercIdServidor,
  ) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      table,
      where: 'matriz_iperc_id_servidor = ? AND eliminado = 0',
      whereArgs: <Object>[matrizIpercIdServidor],
      orderBy: 'fecha_actualizacion DESC, fecha_registro DESC',
    );

    return rows.map(MapaRiesgoLocalModel.fromMap).toList(growable: false);
  }

  Future<MapaRiesgoLocalModel?> obtenerPorLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      table,
      where: 'id_local = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return MapaRiesgoLocalModel.fromMap(rows.first);
  }

  Future<MapaRiesgoLocalModel?> obtenerPorServidor(int idServidor) async {
    if (idServidor <= 0) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      table,
      where: 'id_servidor = ?',
      whereArgs: <Object>[idServidor],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return MapaRiesgoLocalModel.fromMap(rows.first);
  }

  Future<void> guardar(MapaRiesgoLocalModel model) async {
    final Database db = await _appDatabase.database;

    await db.insert(
      table,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> marcarSincronizado({
    required String idLocal,
    required int idServidor,
    String? codigo,
    String? archivoUrlServidor,
    String? tipoArchivo,
  }) async {
    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.update(
      table,
      <String, dynamic>{
        'id_servidor': idServidor,
        'codigo': ?codigo,
        'archivo_url_servidor': ?archivoUrlServidor,
        'tipo_archivo': ?tipoArchivo,
        'sincronizado': 1,
        'eliminado': 0,
        'fecha_actualizacion': ahora,
        'fecha_sincronizacion': ahora,
      },
      where: 'id_local = ?',
      whereArgs: <Object>[idLocal],
    );
  }

  Future<void> marcarPendiente(String idLocal) async {
    final Database db = await _appDatabase.database;

    await db.update(
      table,
      <String, dynamic>{
        'sincronizado': 0,
        'fecha_actualizacion': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id_local = ?',
      whereArgs: <Object>[idLocal],
    );
  }
}
