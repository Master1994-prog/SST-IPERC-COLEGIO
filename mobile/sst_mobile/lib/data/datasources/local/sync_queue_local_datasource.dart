import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/sync_queue_model.dart';

class SyncQueueLocalDatasource {
  SyncQueueLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tableName = 'sincronizaciones_pendientes';

  // =============================================================
  // INSERTAR
  // =============================================================

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

  // =============================================================
  // OBTENER PENDIENTES
  // =============================================================

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

  // =============================================================
  // SINCRONIZANDO
  // =============================================================

  Future<void> markAsSynchronizing(int id) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': 'SINCRONIZANDO',
        'fecha_ultimo_intento': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // =============================================================
  // SINCRONIZADO
  // =============================================================

  Future<void> markAsSynchronized(int id) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': 'SINCRONIZADO',
        'fecha_sincronizacion': DateTime.now().toUtc().toIso8601String(),
        'ultimo_error': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // =============================================================
  // ERROR
  // =============================================================

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
        'ultimo_error': error.trim(),
        'numero_intentos': numeroIntentos,
        'fecha_ultimo_intento': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> countPending() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $_tableName
      WHERE estado = ?
         OR estado = ?
      ''',
      <Object>['PENDIENTE', 'ERROR'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =============================================================
  // ÚLTIMO ERROR
  // =============================================================

  Future<String?> getLastError() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      columns: <String>['ultimo_error'],
      where:
          'estado = ? '
          'AND ultimo_error IS NOT NULL '
          'AND TRIM(ultimo_error) <> ?',
      whereArgs: <Object>['ERROR', ''],
      orderBy: 'fecha_ultimo_intento DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final String texto = rows.first['ultimo_error']?.toString().trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // ERRORES ACTUALES
  // =============================================================

  Future<List<String>> getCurrentErrors() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      columns: <String>['entidad', 'entidad_id_local', 'ultimo_error'],
      where:
          'estado = ? '
          'AND ultimo_error IS NOT NULL '
          'AND TRIM(ultimo_error) <> ?',
      whereArgs: <Object>['ERROR', ''],
      orderBy: 'fecha_ultimo_intento DESC, id DESC',
    );

    final List<String> errores = <String>[];

    for (final Map<String, Object?> row in rows) {
      final String entidad = row['entidad']?.toString().trim() ?? '';

      final String idLocal = row['entidad_id_local']?.toString().trim() ?? '';

      final String error = row['ultimo_error']?.toString().trim() ?? '';

      if (error.isEmpty) {
        continue;
      }

      String titulo = entidad.isEmpty ? 'Registro' : entidad;

      if (idLocal.isNotEmpty) {
        titulo = '$titulo [$idLocal]';
      }

      errores.add('$titulo: $error');
    }

    return errores;
  }

  // =============================================================
  // REINTENTAR ERRORES
  // =============================================================

  Future<void> resetErrorsToPending() async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{'estado': 'PENDIENTE'},
      where: 'estado = ?',
      whereArgs: <Object>['ERROR'],
    );
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> deleteById(int id) async {
    final Database db = await _appDatabase.database;

    await db.delete(_tableName, where: 'id = ?', whereArgs: <Object>[id]);
  }
}
