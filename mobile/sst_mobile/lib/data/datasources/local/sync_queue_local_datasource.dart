import 'package:sqflite/sqflite.dart';

import '../../../core/constants/sync_constants.dart';
import '../../../core/database/app_database.dart';
import '../../models/sync_queue_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - COLA DE SINCRONIZACIÓN
/// ===============================================================
///
/// Tabla:
///
/// sincronizaciones_pendientes
///
/// Estados:
///
/// - PENDIENTE
/// - SINCRONIZANDO
/// - SINCRONIZADO
/// - ERROR
///
/// Reglas importantes:
///
/// 1. Nunca borrar una operación SINCRONIZANDO desde métodos de
///    limpieza normal.
/// 2. ERROR y PENDIENTE pueden reemplazarse por una nueva operación
///    equivalente.
/// 3. SINCRONIZANDO solo vuelve a PENDIENTE durante el arranque de
///    una nueva sesión mediante recoverInterruptedSynchronizations().
/// ===============================================================
class SyncQueueLocalDatasource {
  SyncQueueLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tableName = 'sincronizaciones_pendientes';

  // =============================================================
  // INSERTAR
  // =============================================================

  Future<int> insert(SyncQueueModel item) async {
    final String entidad = item.entidad.trim().toUpperCase();

    final String entidadIdLocal = item.entidadIdLocal.trim();

    final String operacion = item.operacion.trim().toUpperCase();

    if (entidad.isEmpty) {
      throw const FormatException(
        'La entidad de sincronización es obligatoria.',
      );
    }

    if (entidadIdLocal.isEmpty) {
      throw const FormatException(
        'El identificador local de sincronización es obligatorio.',
      );
    }

    final bool operacionValida =
        operacion == SyncConstants.crear ||
        operacion == SyncConstants.actualizar ||
        operacion == SyncConstants.eliminar;

    if (!operacionValida) {
      throw FormatException(
        'La operación de sincronización no es válida: $operacion.',
      );
    }

    final Database db = await _appDatabase.database;

    final Map<String, dynamic> data = item.toMap();

    data.remove('id');

    data['entidad'] = entidad;
    data['entidad_id_local'] = entidadIdLocal;
    data['operacion'] = operacion;

    // Las nuevas operaciones siempre ingresan como PENDIENTE.
    data['estado'] = SyncConstants.pendiente;

    data['ultimo_error'] = null;

    return db.transaction<int>((Transaction txn) async {
      // -------------------------------------------------------
      // EVITAR DUPLICADOS REEMPLAZABLES
      // -------------------------------------------------------
      //
      // Solo eliminamos operaciones equivalentes que todavía
      // están PENDIENTE o ERROR.
      //
      // Nunca tocamos SINCRONIZANDO.

      await txn.delete(
        _tableName,
        where:
            'entidad = ? '
            'AND entidad_id_local = ? '
            'AND operacion = ? '
            'AND (estado = ? OR estado = ?)',
        whereArgs: <Object>[
          entidad,
          entidadIdLocal,
          operacion,
          SyncConstants.pendiente,
          SyncConstants.error,
        ],
      );

      return txn.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // =============================================================
  // OBTENER PENDIENTES
  // =============================================================

  Future<List<SyncQueueModel>> getPending() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'estado = ? OR estado = ?',
      whereArgs: <Object>[SyncConstants.pendiente, SyncConstants.error],
      orderBy: 'fecha_creacion ASC, id ASC',
    );

    return result.map(SyncQueueModel.fromMap).toList();
  }

  // =============================================================
  // MARCAR SINCRONIZANDO
  // =============================================================

  Future<void> markAsSynchronizing(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'El ID de cola debe ser mayor que cero.',
      );
    }

    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': SyncConstants.sincronizando,
        'fecha_ultimo_intento': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // =============================================================
  // MARCAR SINCRONIZADO
  // =============================================================

  Future<void> markAsSynchronized(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'El ID de cola debe ser mayor que cero.',
      );
    }

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': SyncConstants.sincronizado,
        'fecha_sincronizacion': ahora,
        'ultimo_error': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // =============================================================
  // MARCAR ERROR
  // =============================================================

  Future<void> markAsError({
    required int id,
    required String error,
    required int numeroIntentos,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'El ID de cola debe ser mayor que cero.',
      );
    }

    final String mensaje = error.trim();

    final Database db = await _appDatabase.database;

    await db.update(
      _tableName,
      <String, dynamic>{
        'estado': SyncConstants.error,
        'ultimo_error': mensaje.isEmpty ? 'Error de sincronización.' : mensaje,
        'numero_intentos': numeroIntentos < 0 ? 0 : numeroIntentos,
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
      <Object>[SyncConstants.pendiente, SyncConstants.error],
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
      whereArgs: <Object>[SyncConstants.error, ''],
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
      whereArgs: <Object>[SyncConstants.error, ''],
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
      <String, dynamic>{'estado': SyncConstants.pendiente},
      where: 'estado = ?',
      whereArgs: <Object>[SyncConstants.error],
    );
  }

  // =============================================================
  // RECUPERAR SINCRONIZACIONES INTERRUMPIDAS
  // =============================================================

  /// Se debe ejecutar únicamente al iniciar una nueva sesión de
  /// la aplicación.
  ///
  /// Si la app se cerró mientras una fila estaba SINCRONIZANDO,
  /// la petición HTTP anterior ya no existe. Por eso puede volver
  /// de forma segura a PENDIENTE.
  Future<int> recoverInterruptedSynchronizations() async {
    final Database db = await _appDatabase.database;

    return db.update(
      _tableName,
      <String, dynamic>{'estado': SyncConstants.pendiente},
      where: 'estado = ?',
      whereArgs: <Object>[SyncConstants.sincronizando],
    );
  }

  // =============================================================
  // EXISTE OPERACIÓN SINCRONIZANDO
  // =============================================================

  Future<bool> hasSynchronizingOperation({
    required String entidad,
    required String entidadIdLocal,
  }) async {
    final String entidadNormalizada = entidad.trim().toUpperCase();

    final String idLocal = entidadIdLocal.trim();

    if (entidadNormalizada.isEmpty || idLocal.isEmpty) {
      return false;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      columns: <String>['id'],
      where:
          'entidad = ? '
          'AND entidad_id_local = ? '
          'AND estado = ?',
      whereArgs: <Object>[
        entidadNormalizada,
        idLocal,
        SyncConstants.sincronizando,
      ],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  // =============================================================
  // ELIMINAR PENDIENTES DE UNA ENTIDAD / ID LOCAL
  // =============================================================

  /// Elimina únicamente PENDIENTE y ERROR.
  ///
  /// Nunca elimina SINCRONIZANDO ni SINCRONIZADO.
  Future<int> deletePendingByEntityAndLocalId({
    required String entidad,
    required String entidadIdLocal,
  }) async {
    final String entidadNormalizada = entidad.trim().toUpperCase();

    final String idLocal = entidadIdLocal.trim();

    if (entidadNormalizada.isEmpty || idLocal.isEmpty) {
      return 0;
    }

    final Database db = await _appDatabase.database;

    return db.delete(
      _tableName,
      where:
          'entidad = ? '
          'AND entidad_id_local = ? '
          'AND (estado = ? OR estado = ?)',
      whereArgs: <Object>[
        entidadNormalizada,
        idLocal,
        SyncConstants.pendiente,
        SyncConstants.error,
      ],
    );
  }

  // =============================================================
  // ELIMINAR PENDIENTES DE VARIOS IDS
  // =============================================================

  /// Versión masiva usada, por ejemplo, al cancelar una matriz
  /// offline junto con sus detalles que nunca llegaron al backend.
  Future<int> deletePendingByEntityAndLocalIds({
    required String entidad,
    required Iterable<String> entidadIdsLocales,
  }) async {
    final String entidadNormalizada = entidad.trim().toUpperCase();

    if (entidadNormalizada.isEmpty) {
      return 0;
    }

    final Set<String> ids = entidadIdsLocales
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    if (ids.isEmpty) {
      return 0;
    }

    final Database db = await _appDatabase.database;

    return db.transaction<int>((Transaction txn) async {
      int eliminados = 0;

      for (final String idLocal in ids) {
        eliminados += await txn.delete(
          _tableName,
          where:
              'entidad = ? '
              'AND entidad_id_local = ? '
              'AND (estado = ? OR estado = ?)',
          whereArgs: <Object>[
            entidadNormalizada,
            idLocal,
            SyncConstants.pendiente,
            SyncConstants.error,
          ],
        );
      }

      return eliminados;
    });
  }

  // =============================================================
  // ELIMINAR POR ID
  // =============================================================

  Future<void> deleteById(int id) async {
    if (id <= 0) {
      return;
    }

    final Database db = await _appDatabase.database;

    await db.delete(_tableName, where: 'id = ?', whereArgs: <Object>[id]);
  }

  // =============================================================
  // ELIMINAR SINCRONIZADOS
  // =============================================================

  Future<int> deleteSynchronized() async {
    final Database db = await _appDatabase.database;

    return db.delete(
      _tableName,
      where: 'estado = ?',
      whereArgs: <Object>[SyncConstants.sincronizado],
    );
  }
}
