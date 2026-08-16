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
/// Cada catálogo se guarda independientemente.
///
/// IMPORTANTE:
///
/// Antes de reemplazar una tabla local se valida primero la lista
/// recibida. Así evitamos borrar un catálogo offline válido cuando
/// el backend devuelve elementos inválidos o incompletos.
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
        CREATE INDEX IF NOT EXISTS idx_catalogo_peligros_nombre
        ON $_tablaPeligros(nombre)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_catalogo_consecuencias_nombre
        ON $_tablaConsecuencias(nombre)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_catalogo_probabilidades_valor
        ON $_tablaProbabilidades(valor)
      ''');

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_catalogo_severidades_valor
        ON $_tablaSeveridades(valor)
      ''');
    });
  }

  Future<void> guardarPeligros(List<PeligroModel> peligros) async {
    final List<PeligroModel> validos = peligros
        .where(
          (PeligroModel item) =>
              item.id > 0 &&
              item.estaDisponible &&
              item.codigo.trim().isNotEmpty &&
              item.nombre.trim().isNotEmpty &&
              item.tipoPeligroId > 0,
        )
        .toList(growable: false);

    if (validos.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaPeligros);

      final Batch batch = txn.batch();

      for (final PeligroModel peligro in validos) {
        batch.insert(_tablaPeligros, <String, Object?>{
          'id': peligro.id,
          'codigo': peligro.codigo.trim(),
          'nombre': peligro.nombre.trim(),
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
        cantidad: validos.length,
        fecha: ahora,
      );
    });
  }

  Future<void> guardarConsecuencias(
    List<ConsecuenciaModel> consecuencias,
  ) async {
    final List<ConsecuenciaModel> validos = consecuencias
        .where(
          (ConsecuenciaModel item) =>
              item.id > 0 &&
              item.estaDisponible &&
              item.codigo.trim().isNotEmpty &&
              item.nombre.trim().isNotEmpty,
        )
        .toList(growable: false);

    if (validos.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaConsecuencias);

      final Batch batch = txn.batch();

      for (final ConsecuenciaModel consecuencia in validos) {
        batch.insert(_tablaConsecuencias, <String, Object?>{
          'id': consecuencia.id,
          'codigo': consecuencia.codigo.trim(),
          'nombre': consecuencia.nombre.trim(),
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
        cantidad: validos.length,
        fecha: ahora,
      );
    });
  }

  Future<void> guardarProbabilidades(
    List<ProbabilidadModel> probabilidades,
  ) async {
    final List<ProbabilidadModel> validos = probabilidades
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 &&
              item.valor >= 1 &&
              item.valor <= 5 &&
              item.nombre.trim().isNotEmpty,
        )
        .toList(growable: false);

    if (validos.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaProbabilidades);

      final Batch batch = txn.batch();

      for (final ProbabilidadModel item in validos) {
        batch.insert(_tablaProbabilidades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': item.nombre.trim(),
          'descripcion': item.descripcion,
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'PROBABILIDADES',
        cantidad: validos.length,
        fecha: ahora,
      );
    });
  }

  Future<void> guardarSeveridades(List<SeveridadModel> severidades) async {
    final List<SeveridadModel> validos = severidades
        .where(
          (SeveridadModel item) =>
              item.id > 0 &&
              item.valor >= 1 &&
              item.valor <= 5 &&
              item.nombre.trim().isNotEmpty,
        )
        .toList(growable: false);

    if (validos.isEmpty) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;
    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaSeveridades);

      final Batch batch = txn.batch();

      for (final SeveridadModel item in validos) {
        batch.insert(_tablaSeveridades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': item.nombre.trim(),
          'descripcion': item.descripcion,
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      await _guardarMetadata(
        txn,
        catalogo: 'SEVERIDADES',
        cantidad: validos.length,
        fecha: ahora,
      );
    });
  }

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
        // Se ignora solamente el registro local dañado.
      }
    }

    return resultado;
  }

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
        // Se ignora solamente el registro local dañado.
      }
    }

    return resultado;
  }

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
              item.id > 0 &&
              item.valor >= 1 &&
              item.valor <= 5 &&
              item.nombre.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

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
              item.id > 0 &&
              item.valor >= 1 &&
              item.valor <= 5 &&
              item.nombre.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

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
    final int peligros = await contarPeligros();
    final int consecuencias = await contarConsecuencias();
    final int probabilidades = await contarProbabilidades();
    final int severidades = await contarSeveridades();

    return peligros > 0 &&
        consecuencias > 0 &&
        probabilidades > 0 &&
        severidades > 0;
  }

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

  Future<void> _guardarMetadata(
    Transaction txn, {
    required String catalogo,
    required int cantidad,
    required String fecha,
  }) async {
    await txn.insert(_tablaMetadata, <String, Object?>{
      'catalogo': catalogo.trim().toUpperCase(),
      'fecha_actualizacion': fecha,
      'cantidad_registros': cantidad,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> _contarTabla(String tabla) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> resultado = await db.rawQuery(
      'SELECT COUNT(*) FROM $tabla',
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
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
