import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/seguimiento_iperc_local_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Administra los seguimientos IPERC almacenados en SQLite.
///
/// Permite:
///
/// - Crear seguimientos.
/// - Consultar por ID local.
/// - Consultar por ID de servidor.
/// - Listar por Detalle IPERC.
/// - Actualizar.
/// - Eliminar lógicamente.
/// - Marcar como sincronizado.
/// - Confirmar una eliminación sincronizada.
/// - Guardar información recibida desde el servidor.
///
/// Cada cambio local genera una operación dentro de:
///
/// `sincronizaciones_pendientes`
///
/// Entidad utilizada:
///
/// `SEGUIMIENTO_IPERC`
/// ===============================================================
class SeguimientoIpercLocalDatasource {
  SeguimientoIpercLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tabla = 'seguimientos_iperc_local';

  static const String _tablaSincronizaciones = 'sincronizaciones_pendientes';

  static const String _entidad = 'SEGUIMIENTO_IPERC';

  // =============================================================
  // CREAR
  // =============================================================

  Future<void> crear(SeguimientoIpercLocalModel seguimiento) async {
    _validarSeguimiento(seguimiento, exigirIdLocal: true);

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      await txn.insert(
        _tabla,
        seguimiento.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _guardarOperacionPendiente(
        txn,
        seguimiento: seguimiento,
        operacion: 'CREAR',
      );
    });
  }

  // =============================================================
  // OBTENER POR ID LOCAL
  // =============================================================

  Future<SeguimientoIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: 'id_local = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return SeguimientoIpercLocalModel.fromMap(resultado.first);
  }

  // =============================================================
  // OBTENER POR ID SERVIDOR
  // =============================================================

  Future<SeguimientoIpercLocalModel?> obtenerPorIdServidor(
    int idServidor,
  ) async {
    if (idServidor <= 0) {
      return null;
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: 'id_servidor = ?',
      whereArgs: <Object?>[idServidor],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return SeguimientoIpercLocalModel.fromMap(resultado.first);
  }

  // =============================================================
  // LISTAR POR DETALLE
  // =============================================================

  Future<List<SeguimientoIpercLocalModel>> listarPorDetalleLocal(
    String detalleIpercIdLocal,
  ) async {
    final String detalleId = detalleIpercIdLocal.trim();

    if (detalleId.isEmpty) {
      return <SeguimientoIpercLocalModel>[];
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: '''
        detalle_iperc_id_local = ?
        AND eliminado = 0
      ''',
      whereArgs: <Object?>[detalleId],
      orderBy: 'fecha_seguimiento DESC, fecha_registro DESC',
    );

    return resultado
        .map(SeguimientoIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  Future<List<SeguimientoIpercLocalModel>> listarPorDetalleServidor(
    int detalleIpercIdServidor,
  ) async {
    if (detalleIpercIdServidor <= 0) {
      return <SeguimientoIpercLocalModel>[];
    }

    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: '''
        detalle_iperc_id_servidor = ?
        AND eliminado = 0
      ''',
      whereArgs: <Object?>[detalleIpercIdServidor],
      orderBy: 'fecha_seguimiento DESC, fecha_registro DESC',
    );

    return resultado
        .map(SeguimientoIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // LISTAR TODOS
  // =============================================================

  Future<List<SeguimientoIpercLocalModel>> listarTodos() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: 'eliminado = 0',
      orderBy: 'fecha_seguimiento DESC, fecha_registro DESC',
    );

    return resultado
        .map(SeguimientoIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // LISTAR PENDIENTES
  // =============================================================

  /// Incluye registros eliminados porque su eliminación también
  /// puede requerir sincronización con el backend.
  Future<List<SeguimientoIpercLocalModel>> listarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.query(
      _tabla,
      where: 'sincronizado = 0',
      orderBy: 'fecha_registro ASC, id_local ASC',
    );

    return resultado
        .map(SeguimientoIpercLocalModel.fromMap)
        .toList(growable: false);
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> actualizar(SeguimientoIpercLocalModel seguimiento) async {
    _validarSeguimiento(seguimiento, exigirIdLocal: true);

    final String idLocal = seguimiento.idLocal.trim();

    final DateTime ahora = DateTime.now().toUtc();

    final SeguimientoIpercLocalModel actualizado = seguimiento.copyWith(
      sincronizado: false,
      fechaActualizacion: ahora,
    );

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      final int filas = await txn.update(
        _tabla,
        actualizado.toMap(),
        where: 'id_local = ?',
        whereArgs: <Object?>[idLocal],
      );

      if (filas == 0) {
        throw StateError(
          'No existe el seguimiento IPERC '
          'local $idLocal.',
        );
      }

      final bool existeEnServidor =
          seguimiento.idServidor != null && seguimiento.idServidor! > 0;

      final String operacion = existeEnServidor ? 'ACTUALIZAR' : 'CREAR';

      await _guardarOperacionPendiente(
        txn,
        seguimiento: actualizado,
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
        'El identificador local del '
        'seguimiento IPERC es obligatorio.',
      );
    }

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      final List<Map<String, dynamic>> resultado = await txn.query(
        _tabla,
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );

      if (resultado.isEmpty) {
        throw StateError(
          'No existe el seguimiento '
          'IPERC local $id.',
        );
      }

      final SeguimientoIpercLocalModel seguimiento =
          SeguimientoIpercLocalModel.fromMap(resultado.first);

      if (seguimiento.eliminado) {
        return;
      }

      final DateTime ahora = DateTime.now().toUtc();

      final SeguimientoIpercLocalModel eliminado = seguimiento.copyWith(
        eliminado: true,
        sincronizado: false,
        fechaActualizacion: ahora,
      );

      final int filas = await txn.update(
        _tabla,
        eliminado.toMap(),
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
      );

      if (filas == 0) {
        throw StateError(
          'No se pudo marcar como eliminado '
          'el seguimiento IPERC local $id.',
        );
      }

      await _eliminarOperacionesReemplazables(txn, idLocal: id);

      await _insertarOperacionPendiente(
        txn,
        seguimiento: eliminado,
        operacion: 'ELIMINAR',
      );
    });
  }

  // =============================================================
  // MARCAR COMO SINCRONIZADO
  // =============================================================

  Future<void> marcarComoSincronizado({
    required String idLocal,
    required int idServidor,
    int? detalleIpercIdServidor,
  }) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'El identificador local del '
        'seguimiento IPERC es obligatorio.',
      );
    }

    if (idServidor <= 0) {
      throw ArgumentError(
        'El identificador del servidor '
        'del seguimiento IPERC no es válido.',
      );
    }

    if (detalleIpercIdServidor != null && detalleIpercIdServidor <= 0) {
      throw ArgumentError(
        'El identificador del detalle '
        'IPERC en el servidor no es válido.',
      );
    }

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      final Map<String, Object?> valores = <String, Object?>{
        'id_servidor': idServidor,
        'sincronizado': 1,
        'fecha_sincronizacion': ahora,
        'fecha_actualizacion': ahora,
      };

      if (detalleIpercIdServidor != null) {
        valores['detalle_iperc_id_servidor'] = detalleIpercIdServidor;
      }

      final int filas = await txn.update(
        _tabla,
        valores,
        where: 'id_local = ?',
        whereArgs: <Object?>[id],
      );

      if (filas == 0) {
        throw StateError(
          'No existe el seguimiento '
          'IPERC local $id.',
        );
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
        _tabla,
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

  /// Guarda un seguimiento obtenido del backend sin crear una
  /// nueva operación en la cola.
  Future<void> guardarDesdeServidor(
    SeguimientoIpercLocalModel seguimiento,
  ) async {
    _validarSeguimiento(
      seguimiento,
      exigirIdLocal: true,
      exigirIdServidor: true,
    );

    final DateTime ahora = DateTime.now().toUtc();

    final SeguimientoIpercLocalModel sincronizado = seguimiento.copyWith(
      sincronizado: true,
      eliminado: false,
      fechaActualizacion: ahora,
      fechaSincronizacion: ahora,
    );

    final Database db = await _appDatabase.database;

    await db.insert(
      _tabla,
      sincronizado.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =============================================================
  // ACTUALIZAR ID DEL DETALLE SERVIDOR
  // =============================================================

  /// Se utilizará cuando el Detalle IPERC padre termine de
  /// sincronizarse y obtenga su identificador remoto.
  Future<void> actualizarDetalleServidor({
    required String detalleIpercIdLocal,
    required int detalleIpercIdServidor,
  }) async {
    final String detalleLocal = detalleIpercIdLocal.trim();

    if (detalleLocal.isEmpty || detalleIpercIdServidor <= 0) {
      return;
    }

    final Database db = await _appDatabase.database;

    await db.update(
      _tabla,
      <String, Object?>{'detalle_iperc_id_servidor': detalleIpercIdServidor},
      where: '''
        detalle_iperc_id_local = ?
        AND (
          detalle_iperc_id_servidor IS NULL
          OR detalle_iperc_id_servidor <= 0
        )
      ''',
      whereArgs: <Object?>[detalleLocal],
    );
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> contarPendientes() async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM $_tabla
      WHERE sincronizado = 0
      ''');

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  // =============================================================
  // GUARDAR OPERACIÓN PENDIENTE
  // =============================================================

  Future<void> _guardarOperacionPendiente(
    DatabaseExecutor db, {
    required SeguimientoIpercLocalModel seguimiento,
    required String operacion,
  }) async {
    final String idLocal = seguimiento.idLocal.trim();

    await _eliminarOperacionesReemplazables(db, idLocal: idLocal);

    await _insertarOperacionPendiente(
      db,
      seguimiento: seguimiento,
      operacion: operacion,
    );
  }

  Future<void> _insertarOperacionPendiente(
    DatabaseExecutor db, {
    required SeguimientoIpercLocalModel seguimiento,
    required String operacion,
  }) async {
    final String tipoOperacion = operacion.trim().toUpperCase();

    if (!_operacionValida(tipoOperacion)) {
      throw ArgumentError(
        'Operación de sincronización '
        'no válida: $tipoOperacion.',
      );
    }

    final String idLocal = seguimiento.idLocal.trim();

    if (idLocal.isEmpty) {
      throw ArgumentError(
        'El seguimiento IPERC no contiene '
        'identificador local.',
      );
    }

    final String datosJson = jsonEncode(seguimiento.toMap());

    await db.insert(_tablaSincronizaciones, <String, Object?>{
      'entidad': _entidad,
      'entidad_id_local': idLocal,
      'operacion': tipoOperacion,
      'datos_json': datosJson,
      'estado': 'PENDIENTE',
      'numero_intentos': 0,
      'ultimo_error': null,
      'fecha_creacion': DateTime.now().toUtc().toIso8601String(),
      'fecha_ultimo_intento': null,
      'fecha_sincronizacion': null,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // =============================================================
  // ELIMINAR OPERACIONES REEMPLAZABLES
  // =============================================================

  Future<void> _eliminarOperacionesReemplazables(
    DatabaseExecutor db, {
    required String idLocal,
  }) async {
    await db.delete(
      _tablaSincronizaciones,
      where: '''
        entidad = ?
        AND entidad_id_local = ?
        AND estado IN (
          'PENDIENTE',
          'ERROR'
        )
      ''',
      whereArgs: <Object?>[_entidad, idLocal],
    );
  }

  // =============================================================
  // VALIDACIONES
  // =============================================================

  void _validarSeguimiento(
    SeguimientoIpercLocalModel seguimiento, {
    bool exigirIdLocal = false,
    bool exigirIdServidor = false,
  }) {
    if (exigirIdLocal && seguimiento.idLocal.trim().isEmpty) {
      throw ArgumentError(
        'El identificador local del '
        'seguimiento IPERC es obligatorio.',
      );
    }

    if (exigirIdServidor &&
        (seguimiento.idServidor == null || seguimiento.idServidor! <= 0)) {
      throw ArgumentError(
        'El seguimiento IPERC no contiene '
        'un identificador remoto válido.',
      );
    }

    if (seguimiento.detalleIpercIdLocal.trim().isEmpty) {
      throw ArgumentError(
        'El seguimiento IPERC debe pertenecer '
        'a un Detalle IPERC local.',
      );
    }

    if (seguimiento.detalleIpercIdServidor != null &&
        seguimiento.detalleIpercIdServidor! <= 0) {
      throw ArgumentError(
        'El identificador remoto del Detalle '
        'IPERC no es válido.',
      );
    }

    if (seguimiento.usuarioId <= 0) {
      throw ArgumentError(
        'El usuario del seguimiento IPERC '
        'no es válido.',
      );
    }

    if (seguimiento.descripcion.trim().isEmpty) {
      throw ArgumentError(
        'La descripción del seguimiento '
        'IPERC es obligatoria.',
      );
    }

    if (seguimiento.porcentajeAvance < 0 ||
        seguimiento.porcentajeAvance > 100) {
      throw ArgumentError(
        'El porcentaje de avance debe '
        'estar entre 0 y 100.',
      );
    }

    if (seguimiento.verificado && seguimiento.fechaVerificacion == null) {
      throw ArgumentError(
        'Un seguimiento verificado debe '
        'tener fecha de verificación.',
      );
    }
  }

  bool _operacionValida(String operacion) {
    return operacion == 'CREAR' ||
        operacion == 'ACTUALIZAR' ||
        operacion == 'ELIMINAR';
  }
}
