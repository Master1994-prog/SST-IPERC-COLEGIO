import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/detalle_iperc_local_model.dart';

/// Administra el almacenamiento local de los detalles IPERC.
///
/// Permite crear, consultar, actualizar y eliminar lógicamente evaluaciones.
/// Cada modificación genera una operación pendiente de sincronización.
class DetalleIpercLocalDatasource {
  DetalleIpercLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tablaDetalles = 'detalles_iperc_local';
  static const String _tablaSincronizaciones = 'sincronizaciones_pendientes';
  static const String _entidad = 'DETALLE_IPERC';

  /// Guarda un nuevo detalle IPERC local.
  ///
  /// También registra una operación CREAR en la cola de sincronización.
  Future<void> crear(DetalleIpercLocalModel detalle) async {
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

  /// Obtiene un detalle usando su identificador local.
  Future<DetalleIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'id_local = ?',
      whereArgs: <Object?>[idLocal],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return DetalleIpercLocalModel.fromMap(resultado.first);
  }

  /// Obtiene un detalle mediante el identificador asignado por el servidor.
  Future<DetalleIpercLocalModel?> obtenerPorIdServidor(
    String idServidor,
  ) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'id_servidor = ?',
      whereArgs: <Object?>[idServidor],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return DetalleIpercLocalModel.fromMap(resultado.first);
  }

  /// Lista los detalles activos de una matriz IPERC.
  Future<List<DetalleIpercLocalModel>> listarPorMatriz(
    String matrizIdLocal,
  ) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: '''
        matriz_id_local = ?
        AND eliminado = 0
      ''',
      whereArgs: <Object?>[matrizIdLocal],
      orderBy: 'fecha_registro ASC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  /// Lista todos los detalles locales que no han sido eliminados.
  Future<List<DetalleIpercLocalModel>> listarTodos() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'eliminado = 0',
      orderBy: 'fecha_registro DESC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  /// Lista los detalles que todavía necesitan sincronización.
  ///
  /// Incluye los registros eliminados localmente porque su eliminación
  /// también debe notificarse al backend.
  Future<List<DetalleIpercLocalModel>> listarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tablaDetalles,
      where: 'sincronizado = 0',
      orderBy: 'fecha_registro ASC',
    );

    return resultado
        .map(DetalleIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  /// Actualiza un detalle y lo deja pendiente de sincronización.
  Future<void> actualizar(DetalleIpercLocalModel detalle) async {
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
        whereArgs: <Object?>[detalle.idLocal],
      );

      if (filasAfectadas == 0) {
        throw StateError(
          'No existe el detalle IPERC local ${detalle.idLocal}.',
        );
      }

      /*
       * Si todavía no se ha creado en el servidor, se conserva CREAR.
       * De lo contrario, se registra ACTUALIZAR.
       */
      final String operacion =
          detalle.idServidor == null || detalle.idServidor!.trim().isEmpty
          ? 'CREAR'
          : 'ACTUALIZAR';

      await _guardarOperacionPendiente(
        txn,
        detalle: detalleActualizado,
        operacion: operacion,
      );
    });
  }

  /// Elimina lógicamente un detalle IPERC.
  ///
  /// Si el registro nunca llegó al servidor, también se conserva localmente
  /// como eliminado hasta que la cola pueda resolver la operación.
  Future<void> eliminar(String idLocal) async {
    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      final List<Map<String, dynamic>> resultado = await txn.query(
        _tablaDetalles,
        where: 'id_local = ?',
        whereArgs: <Object?>[idLocal],
        limit: 1,
      );

      if (resultado.isEmpty) {
        throw StateError('No existe el detalle IPERC local $idLocal.');
      }

      final DetalleIpercLocalModel detalle = DetalleIpercLocalModel.fromMap(
        resultado.first,
      );

      final DateTime ahora = DateTime.now().toUtc();

      final DetalleIpercLocalModel detalleEliminado = detalle.copyWith(
        eliminado: true,
        sincronizado: false,
        fechaActualizacion: ahora,
      );

      await txn.update(
        _tablaDetalles,
        detalleEliminado.toMap(),
        where: 'id_local = ?',
        whereArgs: <Object?>[idLocal],
      );

      /*
       * Se quitan las operaciones anteriores para que la eliminación sea
       * la única acción pendiente del registro.
       */
      await txn.delete(
        _tablaSincronizaciones,
        where: '''
          entidad = ?
          AND entidad_id_local = ?
          AND estado = 'PENDIENTE'
        ''',
        whereArgs: <Object?>[_entidad, idLocal],
      );

      await _guardarOperacionPendiente(
        txn,
        detalle: detalleEliminado,
        operacion: 'ELIMINAR',
      );
    });
  }

  /// Marca un detalle como sincronizado correctamente.
  Future<void> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
  }) async {
    final Database db = await _appDatabase.database;
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      final int filasAfectadas = await txn.update(
        _tablaDetalles,
        <String, Object?>{
          'id_servidor': idServidor,
          'sincronizado': 1,
          'fecha_sincronizacion': ahora,
          'fecha_actualizacion': ahora,
        },
        where: 'id_local = ?',
        whereArgs: <Object?>[idLocal],
      );

      if (filasAfectadas == 0) {
        throw StateError('No existe el detalle IPERC local $idLocal.');
      }

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
          AND estado = 'PENDIENTE'
        ''',
        whereArgs: <Object?>[_entidad, idLocal],
      );
    });
  }

  /// Marca como sincronizada una eliminación confirmada por el backend.
  ///
  /// Después elimina definitivamente el registro local.
  Future<void> confirmarEliminacionSincronizada(String idLocal) async {
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
          AND estado = 'PENDIENTE'
        ''',
        whereArgs: <Object?>[_entidad, idLocal],
      );

      await txn.delete(
        _tablaDetalles,
        where: 'id_local = ? AND eliminado = 1',
        whereArgs: <Object?>[idLocal],
      );
    });
  }

  /// Guarda o reemplaza un detalle recibido desde el backend.
  ///
  /// Esta operación no crea elementos en la cola porque el registro ya
  /// procede del servidor.
  Future<void> guardarDesdeServidor(DetalleIpercLocalModel detalle) async {
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

  /// Cuenta los detalles IPERC pendientes de sincronizar.
  Future<int> contarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM $_tablaDetalles
      WHERE sincronizado = 0
      ''');

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  /// Registra una operación en la cola de sincronización.
  ///
  /// Antes elimina cualquier operación pendiente equivalente para evitar
  /// duplicados.
  Future<void> _guardarOperacionPendiente(
    DatabaseExecutor db, {
    required DetalleIpercLocalModel detalle,
    required String operacion,
  }) async {
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.delete(
      _tablaSincronizaciones,
      where: '''
        entidad = ?
        AND entidad_id_local = ?
        AND estado = 'PENDIENTE'
      ''',
      whereArgs: <Object?>[_entidad, detalle.idLocal],
    );

    await db.insert(_tablaSincronizaciones, <String, Object?>{
      'entidad': _entidad,
      'entidad_id_local': detalle.idLocal,
      'operacion': operacion,
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
