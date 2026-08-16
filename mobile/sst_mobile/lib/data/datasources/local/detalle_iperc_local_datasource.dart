import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/detalle_iperc_local_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - DETALLES IPERC
/// ===============================================================
///
/// Administra el almacenamiento local de los detalles IPERC.
///
/// Permite:
///
/// - Crear.
/// - Consultar.
/// - Actualizar.
/// - Eliminar lógicamente.
/// - Marcar sincronización.
/// - Confirmar eliminación.
/// - Guardar datos recibidos del servidor.
///
/// Cada cambio local genera una operación dentro de:
///
/// sincronizaciones_pendientes
///
/// Al reemplazar operaciones pendientes se eliminan únicamente:
///
/// - PENDIENTE
/// - ERROR
///
/// Nunca se elimina una operación SINCRONIZANDO porque podría
/// existir una petición HTTP actualmente en curso.
/// ===============================================================
class DetalleIpercLocalDatasource {
  DetalleIpercLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tablaDetalles = 'detalles_iperc_local';

  static const String _tablaSincronizaciones = 'sincronizaciones_pendientes';

  static const String _entidad = 'DETALLE_IPERC';

  // =============================================================
  // CREAR
  // =============================================================

  Future<void> crear(DetalleIpercLocalModel detalle) async {
    final String idLocal = detalle.idLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'El identificador local del detalle IPERC es obligatorio.',
      );
    }

    final String matrizIdLocal = detalle.matrizIdLocal.trim();

    if (matrizIdLocal.isEmpty) {
      throw ArgumentError(
        'El detalle IPERC debe pertenecer a una matriz local.',
      );
    }

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      await txn.insert(
        _tablaDetalles,
        detalle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _guardarOperacionPendiente(
        txn,
        detalle: detalle,
        operacion: 'CREAR',
      );
    });
  }

  // =============================================================
  // OBTENER POR ID LOCAL
  // =============================================================

  Future<DetalleIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'id_local = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return DetalleIpercLocalModel.fromMap(resultado.first);
  }

  // =============================================================
  // OBTENER POR ID SERVIDOR
  // =============================================================

  Future<DetalleIpercLocalModel?> obtenerPorIdServidor(
    String idServidor,
  ) async {
    final String id = idServidor.trim();

    if (id.isEmpty) {
      return null;
    }

    final int? idNumerico = int.tryParse(id);

    if (idNumerico == null || idNumerico <= 0) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'id_servidor = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return DetalleIpercLocalModel.fromMap(resultado.first);
  }

  // =============================================================
  // LISTAR POR MATRIZ
  // =============================================================

  Future<List<DetalleIpercLocalModel>> listarPorMatriz(
    String matrizIdLocal,
  ) async {
    final String idMatriz = matrizIdLocal.trim();

    if (idMatriz.isEmpty) {
      return <DetalleIpercLocalModel>[];
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: '''
        matriz_id_local = ?
        AND eliminado = 0
      ''',
      whereArgs: <Object?>[idMatriz],
      orderBy: 'fecha_registro ASC, id_local ASC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // LISTAR TODOS
  // =============================================================

  Future<List<DetalleIpercLocalModel>> listarTodos() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'eliminado = 0',
      orderBy: 'fecha_registro DESC, id_local ASC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // LISTAR PENDIENTES
  // =============================================================

  /// Incluye registros eliminados localmente porque su eliminación
  /// también puede necesitar sincronización.
  Future<List<DetalleIpercLocalModel>> listarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'sincronizado = 0',
      orderBy: 'fecha_registro ASC, id_local ASC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> actualizar(DetalleIpercLocalModel detalle) async {
    final String idLocal = detalle.idLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'El identificador local del detalle IPERC es obligatorio.',
      );
    }

    final Database db = await _appDatabase.database;

    final DateTime ahora = DateTime.now().toUtc();

    final DetalleIpercLocalModel detalleActualizado = detalle.copyWith(
      sincronizado: false,
      fechaActualizacion: ahora,
    );

    await db.transaction((Transaction txn) async {
      final int filasAfectadas = await txn.update(
        _tablaDetalles,
        detalleActualizado.toMap(),
        where: 'id_local = ?',
        whereArgs: <Object?>[idLocal],
      );

      if (filasAfectadas == 0) {
        throw StateError('No existe el detalle IPERC local $idLocal.');
      }

      // -------------------------------------------------------
      // DETERMINAR OPERACIÓN
      // -------------------------------------------------------
      //
      // Si todavía no existe en el servidor, se mantiene CREAR.
      // Si ya tiene ID remoto, se utiliza ACTUALIZAR.
      // -------------------------------------------------------

      final String idServidor = detalle.idServidor?.trim() ?? '';

      final int? idServidorNumerico = int.tryParse(idServidor);

      final bool existeEnServidor =
          idServidorNumerico != null && idServidorNumerico > 0;

      final String operacion = existeEnServidor ? 'ACTUALIZAR' : 'CREAR';

      await _guardarOperacionPendiente(
        txn,
        detalle: detalleActualizado,
        operacion: operacion,
      );
    });
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> eliminar(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'El identificador local del detalle IPERC es obligatorio.',
      );
    }

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      final List<Map<String, dynamic>> resultado = await txn.query(
        _tablaDetalles,
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );

      if (resultado.isEmpty) {
        throw StateError('No existe el detalle IPERC local $id.');
      }

      final DetalleIpercLocalModel detalle = DetalleIpercLocalModel.fromMap(
        resultado.first,
      );

      if (detalle.eliminado) {
        return;
      }

      final DateTime ahora = DateTime.now().toUtc();

      final DetalleIpercLocalModel detalleEliminado = detalle.copyWith(
        eliminado: true,
        sincronizado: false,
        fechaActualizacion: ahora,
      );

      final int filasAfectadas = await txn.update(
        _tablaDetalles,
        detalleEliminado.toMap(),
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
      );

      if (filasAfectadas == 0) {
        throw StateError(
          'No se pudo marcar como eliminado '
          'el detalle IPERC local $id.',
        );
      }

      // -------------------------------------------------------
      // REEMPLAZAR OPERACIONES ANTERIORES
      // -------------------------------------------------------
      //
      // Elimina PENDIENTE y ERROR.
      //
      // SINCRONIZANDO no se toca porque podría existir una
      // petición en curso.
      // -------------------------------------------------------

      await _eliminarOperacionesReemplazables(txn, idLocal: id);

      await _insertarOperacionPendiente(
        txn,
        detalle: detalleEliminado,
        operacion: 'ELIMINAR',
      );
    });
  }

  // =============================================================
  // MARCAR COMO SINCRONIZADO
  // =============================================================

  Future<void> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
  }) async {
    final String id = idLocal.trim();

    final String servidor = idServidor.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'El identificador local del detalle IPERC es obligatorio.',
      );
    }

    final int? servidorNumerico = int.tryParse(servidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw ArgumentError(
        'El identificador del servidor '
        'del detalle IPERC no es válido.',
      );
    }

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      final int filasAfectadas = await txn.update(
        _tablaDetalles,
        <String, Object?>{
          'id_servidor': servidor,
          'sincronizado': 1,
          'fecha_sincronizacion': ahora,
          'fecha_actualizacion': ahora,
        },
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
      );

      if (filasAfectadas == 0) {
        throw StateError('No existe el detalle IPERC local $id.');
      }

      // Puede ser invocado desde:
      //
      // - sincronización directa: PENDIENTE / ERROR;
      // - SyncService general: SINCRONIZANDO.
      //
      // Por eso se aceptan los tres estados.
      await txn.update(
        _tablaSincronizaciones,
        <String, Object?>{
          'estado': 'SINCRONIZADO',
          'ultimo_error': null,
          'fecha_sincronizacion': ahora,
        },
        where: '''
            entidad = ?
            AND entidad_id_local = ?
            AND estado IN (
              'PENDIENTE',
              'ERROR',
              'SINCRONIZANDO'
            )
          ''',
        whereArgs: <Object?>[_entidad, id],
      );
    });
  }

  // =============================================================
  // CONFIRMAR ELIMINACIÓN SINCRONIZADA
  // =============================================================

  Future<void> confirmarEliminacionSincronizada(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return;
    }

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.update(
        _tablaSincronizaciones,
        <String, Object?>{
          'estado': 'SINCRONIZADO',
          'ultimo_error': null,
          'fecha_sincronizacion': ahora,
        },
        where: '''
            entidad = ?
            AND entidad_id_local = ?
            AND estado IN (
              'PENDIENTE',
              'ERROR',
              'SINCRONIZANDO'
            )
          ''',
        whereArgs: <Object?>[_entidad, id],
      );

      await txn.delete(
        _tablaDetalles,
        where: '''
            id_local = ?
            AND eliminado = 1
          ''',
        whereArgs: <Object?>[id],
      );
    });
  }

  // =============================================================
  // GUARDAR DESDE SERVIDOR
  // =============================================================

  /// Guarda o reemplaza un detalle recibido desde el backend.
  ///
  /// Esta operación no crea operaciones nuevas en la cola.
  Future<void> guardarDesdeServidor(DetalleIpercLocalModel detalle) async {
    final String idLocal = detalle.idLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'El detalle recibido del servidor '
        'no contiene un ID local válido.',
      );
    }

    final String idServidor = detalle.idServidor?.trim() ?? '';

    final int? servidorNumerico = int.tryParse(idServidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw ArgumentError(
        'El detalle recibido del servidor '
        'no contiene un ID remoto válido.',
      );
    }

    final Database db = await _appDatabase.database;

    final DateTime ahora = DateTime.now().toUtc();

    final DetalleIpercLocalModel detalleSincronizado = detalle.copyWith(
      sincronizado: true,
      eliminado: false,
      fechaSincronizacion: ahora,
      fechaActualizacion: ahora,
    );

    await db.insert(
      _tablaDetalles,
      detalleSincronizado.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> contarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM $_tablaDetalles
      WHERE sincronizado = 0
      ''');

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  // =============================================================
  // GUARDAR OPERACIÓN PENDIENTE
  // =============================================================

  Future<void> _guardarOperacionPendiente(
    DatabaseExecutor db, {
    required DetalleIpercLocalModel detalle,
    required String operacion,
  }) async {
    await _eliminarOperacionesReemplazables(db, idLocal: detalle.idLocal);

    await _insertarOperacionPendiente(
      db,
      detalle: detalle,
      operacion: operacion,
    );
  }

  // =============================================================
  // ELIMINAR OPERACIONES REEMPLAZABLES
  // =============================================================

  Future<void> _eliminarOperacionesReemplazables(
    DatabaseExecutor db, {
    required String idLocal,
  }) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return;
    }

    await db.delete(
      _tablaSincronizaciones,
      where: '''
        entidad = ?
        AND entidad_id_local = ?
        AND estado IN ('PENDIENTE', 'ERROR')
      ''',
      whereArgs: <Object?>[_entidad, id],
    );
  }

  // =============================================================
  // INSERTAR OPERACIÓN
  // =============================================================

  Future<void> _insertarOperacionPendiente(
    DatabaseExecutor db, {
    required DetalleIpercLocalModel detalle,
    required String operacion,
  }) async {
    final String idLocal = detalle.idLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError('El detalle IPERC no tiene un ID local válido.');
    }

    final String operacionLimpia = operacion.trim().toUpperCase();

    const Set<String> operacionesValidas = <String>{
      'CREAR',
      'ACTUALIZAR',
      'ELIMINAR',
    };

    if (!operacionesValidas.contains(operacionLimpia)) {
      throw ArgumentError(
        'La operación de detalle IPERC '
        'no es válida: $operacionLimpia.',
      );
    }

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.insert(_tablaSincronizaciones, <String, Object?>{
      'entidad': _entidad,
      'entidad_id_local': idLocal,
      'operacion': operacionLimpia,
      'datos_json': jsonEncode(detalle.toMap()),
      'estado': 'PENDIENTE',
      'numero_intentos': 0,
      'ultimo_error': null,
      'fecha_creacion': ahora,
      'fecha_ultimo_intento': null,
      'fecha_sincronizacion': null,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
