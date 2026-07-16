import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/sync_queue_model.dart';

class SyncQueueLocalDatasource {
  SyncQueueLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tableName = 'sincronizaciones_pendientes';

  Future<int> insert(SyncQueueModel item) async {
    final Database db = await _appDatabase.database;

    final Map<String, dynamic> data = item.toMap();
    data.remove('id');

    return db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueModel>> getPending() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'estado = ? OR estado = ?',
      whereArgs: <Object>['PENDIENTE', 'ERROR'],
      orderBy: 'fecha_creacion ASC',
    );

    return result.map(SyncQueueModel.fromMap).toList();
  }

  Future<void> markAsSynchronizing(int id) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': 'SINCRONIZANDO',
        'fecha_ultimo_intento': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> markAsSynchronized(int id) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': 'SINCRONIZADO',
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
        'ultimo_error': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> markAsError({
    required int id,
    required String error,
    required int numeroIntentos,
  }) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': 'ERROR',
        'ultimo_error': error,
        'numero_intentos': numeroIntentos,
        'fecha_ultimo_intento': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<int> countPending() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> result = await db.rawQuery(
      '''
        SELECT COUNT(*) AS total
        FROM $_tableName
        WHERE estado = ? OR estado = ?
      ''',
      <Object>['PENDIENTE', 'ERROR'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteById(int id) async {
    final Database db = await _appDatabase.database;

    await db.delete(_tableName, where: 'id = ?', whereArgs: <Object>[id]);
  }
}
