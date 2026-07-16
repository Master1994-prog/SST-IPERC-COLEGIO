import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/matriz_iperc_local_model.dart';

class MatrizIpercLocalDatasource {
  MatrizIpercLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tableName = 'matrices_iperc_local';

  Future<void> insert(MatrizIpercLocalModel matriz) async {
    final Database db = await _appDatabase.database;

    await db.insert(
      _tableName,
      matriz.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MatrizIpercLocalModel>> getAll() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'eliminado = ?',
      whereArgs: <Object>[0],
      orderBy: 'fecha_registro DESC',
    );

    return result.map(MatrizIpercLocalModel.fromMap).toList();
  }

  Future<List<MatrizIpercLocalModel>> getPendingSynchronization() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'sincronizado = ? AND eliminado = ?',
      whereArgs: <Object>[0, 0],
      orderBy: 'fecha_registro ASC',
    );

    return result.map(MatrizIpercLocalModel.fromMap).toList();
  }

  Future<MatrizIpercLocalModel?> getById(String idLocal) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'id_local = ?',
      whereArgs: <Object>[idLocal],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MatrizIpercLocalModel.fromMap(result.first);
  }

  Future<void> update(MatrizIpercLocalModel matriz) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      matriz.toMap(),
      where: 'id_local = ?',
      whereArgs: <Object>[matriz.idLocal],
    );
  }

  Future<void> markAsSynchronized({
    required String idLocal,
    required String idServidor,
  }) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'id_servidor': idServidor,
        'sincronizado': 1,
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
      },
      where: 'id_local = ?',
      whereArgs: <Object>[idLocal],
    );
  }

  Future<void> deleteLogical(String idLocal) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'eliminado': 1,
        'sincronizado': 0,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      },
      where: 'id_local = ?',
      whereArgs: <Object>[idLocal],
    );
  }
}
