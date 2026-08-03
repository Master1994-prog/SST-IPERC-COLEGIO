import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/consecuencia_model.dart';
import '../../models/peligro_model.dart';

/// Administra el almacenamiento local de los catálogos usados
/// para registrar detalles IPERC sin conexión.
///
/// Guarda en SQLite:
///
/// - Peligros activos.
/// - Consecuencias activas.
/// - Fecha de la última actualización de cada catálogo.
class DetalleIpercCatalogosLocalDatasource {
  DetalleIpercCatalogosLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tablaPeligros = 'peligros_iperc_catalogo_local';

  static const String _tablaConsecuencias =
      'consecuencias_iperc_catalogo_local';

  static const String _tablaMetadata = 'catalogos_iperc_metadata';

  // ============================================================
  // PREPARACIÓN DE TABLAS
  // ============================================================

  /// Garantiza que las tablas de catálogos existan.
  ///
  /// Se utiliza CREATE TABLE IF NOT EXISTS para mantener
  /// compatibilidad con instalaciones anteriores.
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
    });
  }

  // ============================================================
  // GUARDADO
  // ============================================================

  /// Reemplaza el catálogo local de peligros.
  ///
  /// El reemplazo se ejecuta dentro de una transacción para evitar
  /// dejar información incompleta si ocurre un error.
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

      await txn.insert(_tablaMetadata, <String, Object?>{
        'catalogo': 'PELIGROS',
        'fecha_actualizacion': ahora,
        'cantidad_registros': peligros.length,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Reemplaza el catálogo local de consecuencias.
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

      await txn.insert(_tablaMetadata, <String, Object?>{
        'catalogo': 'CONSECUENCIAS',
        'fecha_actualizacion': ahora,
        'cantidad_registros': consecuencias.length,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Guarda ambos catálogos.
  Future<void> guardarCatalogos({
    required List<PeligroModel> peligros,
    required List<ConsecuenciaModel> consecuencias,
  }) async {
    await guardarPeligros(peligros);
    await guardarConsecuencias(consecuencias);
  }

  // ============================================================
  // CONSULTAS
  // ============================================================

  /// Obtiene los peligros disponibles almacenados localmente.
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
        // Un registro local inválido no debe impedir cargar el resto.
      }
    }

    return resultados;
  }

  /// Obtiene las consecuencias disponibles almacenadas localmente.
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
        // Se omite únicamente el registro dañado.
      }
    }

    return resultados;
  }

  /// Busca un peligro local por su identificador.
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

  /// Busca una consecuencia local por su identificador.
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

  /// Indica si existen ambos catálogos almacenados.
  Future<bool> tieneCatalogos() async {
    final int peligros = await contarPeligros();
    final int consecuencias = await contarConsecuencias();

    return peligros > 0 && consecuencias > 0;
  }

  Future<int> contarPeligros() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final int? cantidad = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*)
        FROM $_tablaPeligros
        WHERE activo = 1 AND estado = 1
        '''),
    );

    return cantidad ?? 0;
  }

  Future<int> contarConsecuencias() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final int? cantidad = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*)
        FROM $_tablaConsecuencias
        WHERE activo = 1 AND estado = 1
        '''),
    );

    return cantidad ?? 0;
  }

  /// Obtiene la fecha de la última actualización del catálogo.
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

  // ============================================================
  // ELIMINACIÓN
  // ============================================================

  /// Elimina todos los catálogos almacenados localmente.
  Future<void> limpiarCatalogos() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaPeligros);
      await txn.delete(_tablaConsecuencias);
      await txn.delete(_tablaMetadata);
    });
  }

  // ============================================================
  // CONVERSIÓN
  // ============================================================

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
}
