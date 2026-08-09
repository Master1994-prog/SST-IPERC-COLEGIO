import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/matriz_iperc_local_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - MATRICES IPERC
/// ===============================================================
///
/// Administra las matrices IPERC almacenadas en SQLite.
///
/// También mantiene la relación entre:
///
/// matriz local
///     ↓
/// detalles locales
///
/// Cuando una matriz obtiene su ID del backend, ese ID se propaga
/// automáticamente a todos sus detalles.
/// ===============================================================
class MatrizIpercLocalDatasource {
  MatrizIpercLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tableName = 'matrices_iperc_local';

  static const String _detalleTableName = 'detalles_iperc_local';

  // =============================================================
  // INSERTAR
  // =============================================================

  Future<void> insert(MatrizIpercLocalModel matriz) async {
    final Database db = await _appDatabase.database;

    await db.insert(
      _tableName,
      matriz.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =============================================================
  // OBTENER TODAS
  // =============================================================

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

  // =============================================================
  // PENDIENTES DE SINCRONIZACIÓN
  // =============================================================

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

  // =============================================================
  // OBTENER POR ID LOCAL
  // =============================================================

  Future<MatrizIpercLocalModel?> getById(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'id_local = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MatrizIpercLocalModel.fromMap(result.first);
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> update(MatrizIpercLocalModel matriz) async {
    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      matriz.toMap(),
      where: 'id_local = ?',
      whereArgs: <Object>[matriz.idLocal],
    );
  }

  // =============================================================
  // MARCAR COMO SINCRONIZADA
  // =============================================================

  /// Confirma que una matriz fue registrada correctamente
  /// en el backend.
  ///
  /// Además de guardar el ID del servidor en la matriz,
  /// actualiza automáticamente todos los detalles que todavía
  /// tengan:
  ///
  /// matriz_id_servidor = NULL
  ///
  /// De esta manera los detalles pueden sincronizarse después
  /// utilizando el ID real de la matriz.
  Future<void> markAsSynchronized({
    required String idLocal,
    required String idServidor,
  }) async {
    final String matrizIdLocal = idLocal.trim();

    final String servidorTexto = idServidor.trim();

    if (matrizIdLocal.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    if (servidorTexto.isEmpty) {
      throw ArgumentError('El identificador del servidor es obligatorio.');
    }

    final int? matrizIdServidor = int.tryParse(servidorTexto);

    if (matrizIdServidor == null || matrizIdServidor <= 0) {
      throw FormatException(
        'El identificador del servidor de la matriz '
        'no es válido: $servidorTexto.',
      );
    }

    final Database db = await _appDatabase.database;

    final DateTime ahora = DateTime.now().toUtc();

    await db.transaction((Transaction txn) async {
      // -------------------------------------------------------
      // 1. ACTUALIZAR MATRIZ
      // -------------------------------------------------------

      final int matricesActualizadas = await txn.update(
        _tableName,
        <String, dynamic>{
          'id_servidor': servidorTexto,

          'sincronizado': 1,

          'fecha_sincronizacion': ahora.toIso8601String(),

          'fecha_actualizacion': ahora.toIso8601String(),
        },
        where: 'id_local = ?',
        whereArgs: <Object>[matrizIdLocal],
      );

      if (matricesActualizadas <= 0) {
        throw StateError(
          'No se encontró la matriz local '
          '$matrizIdLocal para confirmar la sincronización.',
        );
      }

      // -------------------------------------------------------
      // 2. PROPAGAR ID DEL SERVIDOR A LOS DETALLES
      // -------------------------------------------------------
      //
      // Todos los detalles creados mientras la matriz estaba
      // offline conocen su matrizIdLocal, pero todavía pueden
      // no conocer el ID asignado por MySQL.
      //
      // Aquí se corrige automáticamente esa relación.
      // -------------------------------------------------------

      await txn.update(
        _detalleTableName,
        <String, dynamic>{
          'matriz_id_servidor': matrizIdServidor,

          'fecha_actualizacion': ahora.toIso8601String(),
        },
        where:
            'matriz_id_local = ? '
            'AND eliminado = ? '
            'AND (matriz_id_servidor IS NULL '
            'OR matriz_id_servidor <= 0)',
        whereArgs: <Object>[matrizIdLocal, 0],
      );
    });
  }

  // =============================================================
  // OBTENER ID DEL SERVIDOR
  // =============================================================

  /// Obtiene el ID del backend para una matriz local.
  ///
  /// Retorna null cuando la matriz todavía no fue sincronizada.
  Future<int?> getServerId(String idLocal) async {
    final MatrizIpercLocalModel? matriz = await getById(idLocal);

    if (matriz == null) {
      return null;
    }

    final String texto = matriz.idServidor?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? idServidor = int.tryParse(texto);

    if (idServidor == null || idServidor <= 0) {
      return null;
    }

    return idServidor;
  }

  // =============================================================
  // SABER SI ESTÁ SINCRONIZADA
  // =============================================================

  Future<bool> isSynchronized(String idLocal) async {
    final MatrizIpercLocalModel? matriz = await getById(idLocal);

    if (matriz == null) {
      return false;
    }

    final int? servidor = int.tryParse(matriz.idServidor?.trim() ?? '');

    return matriz.sincronizado && servidor != null && servidor > 0;
  }

  // =============================================================
  // ELIMINACIÓN LÓGICA
  // =============================================================

  Future<void> deleteLogical(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    final Database db = await _appDatabase.database;

    final DateTime ahora = DateTime.now().toUtc();

    await db.update(
      _tableName,
      <String, dynamic>{
        'eliminado': 1,

        'sincronizado': 0,

        'fecha_actualizacion': ahora.toIso8601String(),
      },
      where: 'id_local = ?',
      whereArgs: <Object>[id],
    );
  }
}
