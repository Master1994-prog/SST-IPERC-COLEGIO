import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/consecuencia_model.dart';
import '../../models/peligro_model.dart';
import '../../models/probabilidad_model.dart';
import '../../models/severidad_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - CATÁLOGOS DETALLE IPERC
/// ===============================================================
///
/// Guarda en SQLite los catálogos necesarios para trabajar
/// completamente offline:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// También almacena la fecha de actualización de cada catálogo.
/// ===============================================================
class DetalleIpercCatalogosLocalDatasource {
  DetalleIpercCatalogosLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  // =============================================================
  // TABLAS
  // =============================================================

  static const String _tablaPeligros = 'peligros_iperc_catalogo_local';

  static const String _tablaConsecuencias =
      'consecuencias_iperc_catalogo_local';

  static const String _tablaProbabilidades =
      'probabilidades_iperc_catalogo_local';

  static const String _tablaSeveridades = 'severidades_iperc_catalogo_local';

  static const String _tablaMetadata = 'catalogos_iperc_metadata';

  // =============================================================
  // PREPARAR TABLAS
  // =============================================================

  Future<void> prepararTablas() async {
    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      // -------------------------------------------------------
      // PELIGROS
      // -------------------------------------------------------

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaPeligros (
            id INTEGER PRIMARY KEY,
            codigo TEXT NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            tipo_peligro_id INTEGER NOT NULL,
            tipo_peligro_nombre TEXT,
            categoria_peligro_id INTEGER,
            categoria_peligro_nombre TEXT,
            fuente TEXT,
            medio TEXT,
            receptor TEXT,
            requisito_legal TEXT,
            recomendaciones TEXT,
            activo INTEGER NOT NULL DEFAULT 1,
            estado INTEGER NOT NULL DEFAULT 1,
            datos_json TEXT NOT NULL,
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      // -------------------------------------------------------
      // CONSECUENCIAS
      // -------------------------------------------------------

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaConsecuencias (
            id INTEGER PRIMARY KEY,
            codigo TEXT NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            clasificacion TEXT,
            incapacidad_permanente INTEGER NOT NULL DEFAULT 0,
            fatalidad INTEGER NOT NULL DEFAULT 0,
            activo INTEGER NOT NULL DEFAULT 1,
            estado INTEGER NOT NULL DEFAULT 1,
            datos_json TEXT NOT NULL,
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      // -------------------------------------------------------
      // PROBABILIDADES
      // -------------------------------------------------------

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaProbabilidades (
            id INTEGER PRIMARY KEY,
            valor INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            datos_json TEXT NOT NULL,
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      // -------------------------------------------------------
      // SEVERIDADES
      // -------------------------------------------------------

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaSeveridades (
            id INTEGER PRIMARY KEY,
            valor INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            datos_json TEXT NOT NULL,
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      // -------------------------------------------------------
      // METADATA
      // -------------------------------------------------------

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaMetadata (
            catalogo TEXT PRIMARY KEY,
            fecha_actualizacion TEXT NOT NULL,
            cantidad_registros INTEGER NOT NULL DEFAULT 0
          )
        ''');

      // =======================================================
      // ÍNDICES
      // =======================================================

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_peligros_nombre
          ON $_tablaPeligros(nombre)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_peligros_activo
          ON $_tablaPeligros(activo, estado)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_consecuencias_nombre
          ON $_tablaConsecuencias(nombre)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_consecuencias_activo
          ON $_tablaConsecuencias(activo, estado)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_probabilidades_valor
          ON $_tablaProbabilidades(valor)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_severidades_valor
          ON $_tablaSeveridades(valor)
        ''');
    });
  }

  // =============================================================
  // GUARDAR PELIGROS
  // =============================================================

  Future<void> guardarPeligros(List<PeligroModel> peligros) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaPeligros);

      final Batch batch = txn.batch();

      for (final PeligroModel peligro in peligros) {
        if (peligro.id <= 0) {
          continue;
        }

        batch.insert(_tablaPeligros, <String, Object?>{
          'id': peligro.id,
          'codigo': peligro.codigo,
          'nombre': peligro.nombre,
          'descripcion': peligro.descripcion,
          'tipo_peligro_id': peligro.tipoPeligroId,
          'tipo_peligro_nombre': peligro.tipoPeligroNombre,
          'categoria_peligro_id': peligro.categoriaPeligroId,
          'categoria_peligro_nombre': peligro.categoriaPeligroNombre,
          'fuente': peligro.fuente,
          'medio': peligro.medio,
          'receptor': peligro.receptor,
          'requisito_legal': peligro.requisitoLegal,
          'recomendaciones': peligro.recomendaciones,
          'activo': peligro.activo ? 1 : 0,
          'estado': peligro.estado ? 1 : 0,
          'datos_json': jsonEncode(peligro.toJson()),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'PELIGROS',
        cantidad: peligros.length,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR CONSECUENCIAS
  // =============================================================

  Future<void> guardarConsecuencias(
    List<ConsecuenciaModel> consecuencias,
  ) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaConsecuencias);

      final Batch batch = txn.batch();

      for (final ConsecuenciaModel consecuencia in consecuencias) {
        if (consecuencia.id <= 0) {
          continue;
        }

        batch.insert(_tablaConsecuencias, <String, Object?>{
          'id': consecuencia.id,
          'codigo': consecuencia.codigo,
          'nombre': consecuencia.nombre,
          'descripcion': consecuencia.descripcion,
          'clasificacion': consecuencia.clasificacion,
          'incapacidad_permanente': consecuencia.incapacidadPermanente ? 1 : 0,
          'fatalidad': consecuencia.fatalidad ? 1 : 0,
          'activo': consecuencia.activo ? 1 : 0,
          'estado': consecuencia.estado ? 1 : 0,
          'datos_json': jsonEncode(consecuencia.toJson()),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'CONSECUENCIAS',
        cantidad: consecuencias.length,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR PROBABILIDADES
  // =============================================================

  Future<void> guardarProbabilidades(
    List<ProbabilidadModel> probabilidades,
  ) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaProbabilidades);

      final Batch batch = txn.batch();

      for (final ProbabilidadModel probabilidad in probabilidades) {
        if (probabilidad.id <= 0 ||
            probabilidad.valor < 1 ||
            probabilidad.valor > 5) {
          continue;
        }

        batch.insert(_tablaProbabilidades, <String, Object?>{
          'id': probabilidad.id,
          'valor': probabilidad.valor,
          'nombre': probabilidad.nombre,
          'descripcion': probabilidad.descripcion,
          'datos_json': jsonEncode(<String, dynamic>{
            'id': probabilidad.id,
            'valor': probabilidad.valor,
            'nombre': probabilidad.nombre,
            'descripcion': probabilidad.descripcion,
          }),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'PROBABILIDADES',
        cantidad: probabilidades.length,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR SEVERIDADES
  // =============================================================

  Future<void> guardarSeveridades(List<SeveridadModel> severidades) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaSeveridades);

      final Batch batch = txn.batch();

      for (final SeveridadModel severidad in severidades) {
        if (severidad.id <= 0 || severidad.valor < 1 || severidad.valor > 5) {
          continue;
        }

        batch.insert(_tablaSeveridades, <String, Object?>{
          'id': severidad.id,
          'valor': severidad.valor,
          'nombre': severidad.nombre,
          'descripcion': severidad.descripcion,
          'datos_json': jsonEncode(<String, dynamic>{
            'id': severidad.id,
            'valor': severidad.valor,
            'nombre': severidad.nombre,
            'descripcion': severidad.descripcion,
          }),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'SEVERIDADES',
        cantidad: severidades.length,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR TODOS LOS CATÁLOGOS
  // =============================================================

  Future<void> guardarCatalogos({
    required List<PeligroModel> peligros,
    required List<ConsecuenciaModel> consecuencias,
    required List<ProbabilidadModel> probabilidades,
    required List<SeveridadModel> severidades,
  }) async {
    await guardarPeligros(peligros);

    await guardarConsecuencias(consecuencias);

    await guardarProbabilidades(probabilidades);

    await guardarSeveridades(severidades);
  }

  // =============================================================
  // OBTENER PELIGROS
  // =============================================================

  Future<List<PeligroModel>> obtenerPeligros() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaPeligros,
      where: 'activo = ? AND estado = ?',
      whereArgs: <Object>[1, 1],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    final List<PeligroModel> resultados = <PeligroModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final String jsonTexto = row['datos_json']?.toString() ?? '';

        if (jsonTexto.trim().isEmpty) {
          continue;
        }

        final dynamic decoded = jsonDecode(jsonTexto);

        if (decoded is! Map) {
          continue;
        }

        final PeligroModel peligro = PeligroModel.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        if (peligro.id > 0 && peligro.estaDisponible) {
          resultados.add(peligro);
        }
      } catch (_) {
        // Un registro inválido no detiene toda la carga.
      }
    }

    return resultados;
  }

  // =============================================================
  // OBTENER CONSECUENCIAS
  // =============================================================

  Future<List<ConsecuenciaModel>> obtenerConsecuencias() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaConsecuencias,
      where: 'activo = ? AND estado = ?',
      whereArgs: <Object>[1, 1],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    final List<ConsecuenciaModel> resultados = <ConsecuenciaModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final String jsonTexto = row['datos_json']?.toString() ?? '';

        if (jsonTexto.trim().isEmpty) {
          continue;
        }

        final dynamic decoded = jsonDecode(jsonTexto);

        if (decoded is! Map) {
          continue;
        }

        final ConsecuenciaModel consecuencia = ConsecuenciaModel.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        if (consecuencia.id > 0 && consecuencia.estaDisponible) {
          resultados.add(consecuencia);
        }
      } catch (_) {
        // Se omite únicamente el registro inválido.
      }
    }

    return resultados;
  }

  // =============================================================
  // OBTENER PROBABILIDADES
  // =============================================================

  Future<List<ProbabilidadModel>> obtenerProbabilidades() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaProbabilidades,
      orderBy: 'valor ASC',
    );

    final List<ProbabilidadModel> resultados = <ProbabilidadModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final ProbabilidadModel probabilidad = ProbabilidadModel(
          id: _intValue(row['id']),
          valor: _intValue(row['valor']),
          nombre: row['nombre']?.toString().trim() ?? '',
          descripcion: row['descripcion']?.toString().trim() ?? '',
        );

        if (probabilidad.id > 0 &&
            probabilidad.valor >= 1 &&
            probabilidad.valor <= 5) {
          resultados.add(probabilidad);
        }
      } catch (_) {
        // Se omite únicamente el registro inválido.
      }
    }

    return resultados;
  }

  // =============================================================
  // OBTENER SEVERIDADES
  // =============================================================

  Future<List<SeveridadModel>> obtenerSeveridades() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaSeveridades,
      orderBy: 'valor ASC',
    );

    final List<SeveridadModel> resultados = <SeveridadModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final SeveridadModel severidad = SeveridadModel(
          id: _intValue(row['id']),
          valor: _intValue(row['valor']),
          nombre: row['nombre']?.toString().trim() ?? '',
          descripcion: row['descripcion']?.toString().trim() ?? '',
        );

        if (severidad.id > 0 && severidad.valor >= 1 && severidad.valor <= 5) {
          resultados.add(severidad);
        }
      } catch (_) {
        // Se omite únicamente el registro inválido.
      }
    }

    return resultados;
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<PeligroModel?> obtenerPeligroPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaPeligros,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _peligroDesdeFila(rows.first);
  }

  Future<ConsecuenciaModel?> obtenerConsecuenciaPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaConsecuencias,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _consecuenciaDesdeFila(rows.first);
  }

  Future<ProbabilidadModel?> obtenerProbabilidadPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaProbabilidades,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final Map<String, Object?> row = rows.first;

    return ProbabilidadModel(
      id: _intValue(row['id']),
      valor: _intValue(row['valor']),
      nombre: row['nombre']?.toString().trim() ?? '',
      descripcion: row['descripcion']?.toString().trim() ?? '',
    );
  }

  Future<SeveridadModel?> obtenerSeveridadPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaSeveridades,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final Map<String, Object?> row = rows.first;

    return SeveridadModel(
      id: _intValue(row['id']),
      valor: _intValue(row['valor']),
      nombre: row['nombre']?.toString().trim() ?? '',
      descripcion: row['descripcion']?.toString().trim() ?? '',
    );
  }

  // =============================================================
  // CONTADORES
  // =============================================================

  Future<int> contarPeligros() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    return Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM $_tablaPeligros
            WHERE activo = 1
              AND estado = 1
          '''),
        ) ??
        0;
  }

  Future<int> contarConsecuencias() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    return Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM $_tablaConsecuencias
            WHERE activo = 1
              AND estado = 1
          '''),
        ) ??
        0;
  }

  Future<int> contarProbabilidades() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    return Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM $_tablaProbabilidades
          '''),
        ) ??
        0;
  }

  Future<int> contarSeveridades() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    return Sqflite.firstIntValue(
          await db.rawQuery('''
            SELECT COUNT(*)
            FROM $_tablaSeveridades
          '''),
        ) ??
        0;
  }

  // =============================================================
  // TIENE CATÁLOGOS COMPLETOS
  // =============================================================

  Future<bool> tieneCatalogos() async {
    final int peligros = await contarPeligros();

    final int consecuencias = await contarConsecuencias();

    final int probabilidades = await contarProbabilidades();

    final int severidades = await contarSeveridades();

    return peligros > 0 &&
        consecuencias > 0 &&
        probabilidades > 0 &&
        severidades > 0;
  }

  // =============================================================
  // FECHA DE ACTUALIZACIÓN
  // =============================================================

  Future<DateTime?> obtenerFechaActualizacion(String catalogo) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> rows = await db.query(
      _tablaMetadata,
      columns: <String>['fecha_actualizacion'],
      where: 'catalogo = ?',
      whereArgs: <Object>[catalogo.trim().toUpperCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      rows.first['fecha_actualizacion']?.toString() ?? '',
    );
  }

  // =============================================================
  // LIMPIAR CATÁLOGOS
  // =============================================================

  Future<void> limpiarCatalogos() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaPeligros);

      await txn.delete(_tablaConsecuencias);

      await txn.delete(_tablaProbabilidades);

      await txn.delete(_tablaSeveridades);

      await txn.delete(_tablaMetadata);
    });
  }

  // =============================================================
  // AUXILIARES
  // =============================================================

  Future<void> _guardarMetadata(
    DatabaseExecutor db, {
    required String catalogo,
    required int cantidad,
    required String fecha,
  }) async {
    await db.insert(_tablaMetadata, <String, Object?>{
      'catalogo': catalogo.trim().toUpperCase(),
      'fecha_actualizacion': fecha,
      'cantidad_registros': cantidad,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  PeligroModel? _peligroDesdeFila(Map<String, Object?> row) {
    try {
      final dynamic decoded = jsonDecode(row['datos_json']?.toString() ?? '');

      if (decoded is! Map) {
        return null;
      }

      return PeligroModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  ConsecuenciaModel? _consecuenciaDesdeFila(Map<String, Object?> row) {
    try {
      final dynamic decoded = jsonDecode(row['datos_json']?.toString() ?? '');

      if (decoded is! Map) {
        return null;
      }

      return ConsecuenciaModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
