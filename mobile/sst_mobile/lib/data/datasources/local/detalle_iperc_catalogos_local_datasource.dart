import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/consecuencia_model.dart';
import '../../models/peligro_model.dart';
import '../../models/probabilidad_model.dart';
import '../../models/severidad_model.dart';

/// ===============================================================
/// DATASOURCE LOCAL - CATÁLOGOS IPERC
/// ===============================================================
///
/// Mantiene disponibles offline:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// Cada catálogo se guarda independientemente. Así, si por ejemplo
/// falla el endpoint de severidades, los peligros y consecuencias
/// que sí fueron descargados no se pierden.
/// ===============================================================
class DetalleIpercCatalogosLocalDatasource {
  DetalleIpercCatalogosLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

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

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaProbabilidades (
            id INTEGER PRIMARY KEY,
            valor INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaSeveridades (
            id INTEGER PRIMARY KEY,
            valor INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT NOT NULL DEFAULT '',
            fecha_actualizacion_local TEXT NOT NULL
          )
        ''');

      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaMetadata (
            catalogo TEXT PRIMARY KEY,
            fecha_actualizacion TEXT NOT NULL,
            cantidad_registros INTEGER NOT NULL DEFAULT 0
          )
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_peligros_nombre
          ON $_tablaPeligros(nombre)
        ''');

      await txn.execute('''
          CREATE INDEX IF NOT EXISTS
          idx_catalogo_consecuencias_nombre
          ON $_tablaConsecuencias(nombre)
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
    if (peligros.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaPeligros);

      final Batch batch = txn.batch();

      int cantidad = 0;

      for (final PeligroModel peligro in peligros) {
        if (peligro.id <= 0 || !peligro.estaDisponible) {
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

        cantidad++;
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'PELIGROS',
        cantidad: cantidad,
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
    if (consecuencias.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaConsecuencias);

      final Batch batch = txn.batch();

      int cantidad = 0;

      for (final ConsecuenciaModel consecuencia in consecuencias) {
        if (consecuencia.id <= 0 || !consecuencia.estaDisponible) {
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

        cantidad++;
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'CONSECUENCIAS',
        cantidad: cantidad,
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
    if (probabilidades.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaProbabilidades);

      final Batch batch = txn.batch();

      int cantidad = 0;

      for (final ProbabilidadModel item in probabilidades) {
        if (item.id <= 0 || item.valor < 1 || item.valor > 5) {
          continue;
        }

        batch.insert(_tablaProbabilidades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': item.nombre,
          'descripcion': item.descripcion,
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        cantidad++;
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'PROBABILIDADES',
        cantidad: cantidad,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR SEVERIDADES
  // =============================================================

  Future<void> guardarSeveridades(List<SeveridadModel> severidades) async {
    if (severidades.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaSeveridades);

      final Batch batch = txn.batch();

      int cantidad = 0;

      for (final SeveridadModel item in severidades) {
        if (item.id <= 0 || item.valor < 1 || item.valor > 5) {
          continue;
        }

        batch.insert(_tablaSeveridades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': item.nombre,
          'descripcion': item.descripcion,
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        cantidad++;
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'SEVERIDADES',
        cantidad: cantidad,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR TODOS
  // =============================================================

  Future<void> guardarCatalogos({
    required List<PeligroModel> peligros,
    required List<ConsecuenciaModel> consecuencias,
    required List<ProbabilidadModel> probabilidades,
    required List<SeveridadModel> severidades,
  }) async {
    if (peligros.isNotEmpty) {
      await guardarPeligros(peligros);
    }

    if (consecuencias.isNotEmpty) {
      await guardarConsecuencias(consecuencias);
    }

    if (probabilidades.isNotEmpty) {
      await guardarProbabilidades(probabilidades);
    }

    if (severidades.isNotEmpty) {
      await guardarSeveridades(severidades);
    }
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

    final List<PeligroModel> resultado = <PeligroModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final dynamic json = jsonDecode(row['datos_json']?.toString() ?? '');

        if (json is! Map) {
          continue;
        }

        final PeligroModel item = PeligroModel.fromJson(
          Map<String, dynamic>.from(json),
        );

        if (item.id > 0 && item.estaDisponible) {
          resultado.add(item);
        }
      } catch (_) {
        // Ignorar únicamente el registro dañado.
      }
    }

    return resultado;
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

    final List<ConsecuenciaModel> resultado = <ConsecuenciaModel>[];

    for (final Map<String, Object?> row in rows) {
      try {
        final dynamic json = jsonDecode(row['datos_json']?.toString() ?? '');

        if (json is! Map) {
          continue;
        }

        final ConsecuenciaModel item = ConsecuenciaModel.fromJson(
          Map<String, dynamic>.from(json),
        );

        if (item.id > 0 && item.estaDisponible) {
          resultado.add(item);
        }
      } catch (_) {
        // Ignorar únicamente el registro dañado.
      }
    }

    return resultado;
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

    return rows
        .map(
          (Map<String, Object?> row) => ProbabilidadModel(
            id: _intValue(row['id']),
            valor: _intValue(row['valor']),
            nombre: row['nombre']?.toString().trim() ?? '',
            descripcion: row['descripcion']?.toString().trim() ?? '',
          ),
        )
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList();
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

    return rows
        .map(
          (Map<String, Object?> row) => SeveridadModel(
            id: _intValue(row['id']),
            valor: _intValue(row['valor']),
            nombre: row['nombre']?.toString().trim() ?? '',
            descripcion: row['descripcion']?.toString().trim() ?? '',
          ),
        )
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList();
  }

  // =============================================================
  // METADATA
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

  Future<int> contarPeligros() async {
    return _contarTabla(_tablaPeligros);
  }

  Future<int> contarConsecuencias() async {
    return _contarTabla(_tablaConsecuencias);
  }

  Future<int> contarProbabilidades() async {
    return _contarTabla(_tablaProbabilidades);
  }

  Future<int> contarSeveridades() async {
    return _contarTabla(_tablaSeveridades);
  }

  Future<bool> tieneCatalogosCompletos() async {
    return await contarPeligros() > 0 &&
        await contarConsecuencias() > 0 &&
        await contarProbabilidades() > 0 &&
        await contarSeveridades() > 0;
  }

  // =============================================================
  // LIMPIAR
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
    Transaction txn, {
    required String catalogo,
    required int cantidad,
    required String fecha,
  }) async {
    await txn.insert(_tablaMetadata, <String, Object?>{
      'catalogo': catalogo,
      'fecha_actualizacion': fecha,
      'cantidad_registros': cantidad,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> _contarTabla(String tabla) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tabla'),
        ) ??
        0;
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
