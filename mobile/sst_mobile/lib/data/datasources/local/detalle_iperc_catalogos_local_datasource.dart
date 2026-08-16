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
/// Guarda en SQLite los catálogos necesarios para trabajar offline:
///
/// - Peligros.
/// - Consecuencias.
/// - Probabilidades.
/// - Severidades.
///
/// CAMBIO IMPORTANTE:
///
/// El almacenamiento local ya no descarta registros únicamente porque
/// el backend entregue un código vacío o porque algún dato secundario
/// venga incompleto.
///
/// Para trabajar offline nos interesa principalmente conservar:
///
/// - ID real del servidor.
/// - Nombre.
/// - Estado activo.
/// - Escala IPERC 1..5.
///
/// Si falta un código se genera uno local de respaldo.
///
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
      await txn.execute('''
          CREATE TABLE IF NOT EXISTS $_tablaPeligros (
            id INTEGER PRIMARY KEY,
            codigo TEXT NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            tipo_peligro_id INTEGER NOT NULL DEFAULT 0,
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

  // =============================================================
  // GUARDAR PELIGROS
  // =============================================================

  Future<void> guardarPeligros(List<PeligroModel> peligros) async {
    final List<PeligroModel> validos = peligros
        .where(
          (PeligroModel item) =>
              item.id > 0 &&
              item.estaDisponible &&
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
      final Batch batch = txn.batch();

      // Primero insertamos/reemplazamos.
      //
      // Después eliminamos obsoletos. Así evitamos dejar la tabla
      // vacía si una operación intermedia falla.
      for (final PeligroModel peligro in validos) {
        final String codigo = peligro.codigo.trim().isNotEmpty
            ? peligro.codigo.trim()
            : 'PEL-${peligro.id}';

        final Map<String, dynamic> json = Map<String, dynamic>.from(
          peligro.toJson(),
        );

        // Aseguramos que la reconstrucción desde SQLite también
        // tenga los valores mínimos necesarios.
        json['codigo'] = codigo;
        json['nombre'] = peligro.nombre.trim();
        json['tipoPeligroId'] = peligro.tipoPeligroId;

        batch.insert(_tablaPeligros, <String, Object?>{
          'id': peligro.id,
          'codigo': codigo,
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
          'datos_json': jsonEncode(json),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      // Limpiar registros que ya no vienen del backend.
      final String placeholders = List<String>.filled(
        validos.length,
        '?',
      ).join(',');

      await txn.delete(
        _tablaPeligros,
        where: 'id NOT IN ($placeholders)',
        whereArgs: validos.map<Object>((PeligroModel item) => item.id).toList(),
      );

      await _guardarMetadata(
        txn,
        catalogo: 'PELIGROS',
        cantidad: validos.length,
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
    final List<ConsecuenciaModel> validos = consecuencias
        .where(
          (ConsecuenciaModel item) =>
              item.id > 0 &&
              item.estaDisponible &&
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
      final Batch batch = txn.batch();

      for (final ConsecuenciaModel consecuencia in validos) {
        final String codigo = consecuencia.codigo.trim().isNotEmpty
            ? consecuencia.codigo.trim()
            : 'CON-${consecuencia.id}';

        final Map<String, dynamic> json = Map<String, dynamic>.from(
          consecuencia.toJson(),
        );

        json['codigo'] = codigo;
        json['nombre'] = consecuencia.nombre.trim();

        batch.insert(_tablaConsecuencias, <String, Object?>{
          'id': consecuencia.id,
          'codigo': codigo,
          'nombre': consecuencia.nombre.trim(),
          'descripcion': consecuencia.descripcion,
          'clasificacion': consecuencia.clasificacion,
          'incapacidad_permanente': consecuencia.incapacidadPermanente ? 1 : 0,
          'fatalidad': consecuencia.fatalidad ? 1 : 0,
          'activo': consecuencia.activo ? 1 : 0,
          'estado': consecuencia.estado ? 1 : 0,
          'datos_json': jsonEncode(json),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      final String placeholders = List<String>.filled(
        validos.length,
        '?',
      ).join(',');

      await txn.delete(
        _tablaConsecuencias,
        where: 'id NOT IN ($placeholders)',
        whereArgs: validos
            .map<Object>((ConsecuenciaModel item) => item.id)
            .toList(),
      );

      await _guardarMetadata(
        txn,
        catalogo: 'CONSECUENCIAS',
        cantidad: validos.length,
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
    final List<ProbabilidadModel> validos = probabilidades
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList(growable: false);

    if (!_escalaProbabilidadesCompleta(validos)) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();

      for (final ProbabilidadModel item in validos) {
        final String nombre = item.nombre.trim().isNotEmpty
            ? item.nombre.trim()
            : 'Probabilidad ${item.valor}';

        batch.insert(_tablaProbabilidades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': nombre,
          'descripcion': item.descripcion.trim(),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      final String placeholders = List<String>.filled(
        validos.length,
        '?',
      ).join(',');

      await txn.delete(
        _tablaProbabilidades,
        where: 'id NOT IN ($placeholders)',
        whereArgs: validos
            .map<Object>((ProbabilidadModel item) => item.id)
            .toList(),
      );

      await _guardarMetadata(
        txn,
        catalogo: 'PROBABILIDADES',
        cantidad: validos.length,
        fecha: ahora,
      );
    });
  }

  // =============================================================
  // GUARDAR SEVERIDADES
  // =============================================================

  Future<void> guardarSeveridades(List<SeveridadModel> severidades) async {
    final List<SeveridadModel> validos = severidades
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList(growable: false);

    if (!_escalaSeveridadesCompleta(validos)) {
      return;
    }

    await prepararTablas();

    final Database db = await _appDatabase.database;

    final String ahora = DateTime.now().toUtc().toIso8601String();

    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();

      for (final SeveridadModel item in validos) {
        final String nombre = item.nombre.trim().isNotEmpty
            ? item.nombre.trim()
            : 'Severidad ${item.valor}';

        batch.insert(_tablaSeveridades, <String, Object?>{
          'id': item.id,
          'valor': item.valor,
          'nombre': nombre,
          'descripcion': item.descripcion.trim(),
          'fecha_actualizacion_local': ahora,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);

      final String placeholders = List<String>.filled(
        validos.length,
        '?',
      ).join(',');

      await txn.delete(
        _tablaSeveridades,
        where: 'id NOT IN ($placeholders)',
        whereArgs: validos
            .map<Object>((SeveridadModel item) => item.id)
            .toList(),
      );

      await _guardarMetadata(
        txn,
        catalogo: 'SEVERIDADES',
        cantidad: validos.length,
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

        if (item.id > 0 &&
            item.estaDisponible &&
            item.nombre.trim().isNotEmpty) {
          resultado.add(item);
        }
      } catch (_) {
        // Solo se ignora el registro dañado.
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

        if (item.id > 0 &&
            item.estaDisponible &&
            item.nombre.trim().isNotEmpty) {
          resultado.add(item);
        }
      } catch (_) {
        // Solo se ignora el registro dañado.
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
        .map((Map<String, Object?> row) {
          final int valor = _intValue(row['valor']);

          return ProbabilidadModel(
            id: _intValue(row['id']),
            valor: valor,
            nombre: row['nombre']?.toString().trim().isNotEmpty == true
                ? row['nombre']!.toString().trim()
                : 'Probabilidad $valor',
            descripcion: row['descripcion']?.toString().trim() ?? '',
          );
        })
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList(growable: false);
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
        .map((Map<String, Object?> row) {
          final int valor = _intValue(row['valor']);

          return SeveridadModel(
            id: _intValue(row['id']),
            valor: valor,
            nombre: row['nombre']?.toString().trim().isNotEmpty == true
                ? row['nombre']!.toString().trim()
                : 'Severidad $valor',
            descripcion: row['descripcion']?.toString().trim() ?? '',
          );
        })
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .toList(growable: false);
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

  // =============================================================
  // CONTADORES
  // =============================================================

  Future<int> contarPeligros() {
    return _contarTabla(_tablaPeligros);
  }

  Future<int> contarConsecuencias() {
    return _contarTabla(_tablaConsecuencias);
  }

  Future<int> contarProbabilidades() {
    return _contarTabla(_tablaProbabilidades);
  }

  Future<int> contarSeveridades() {
    return _contarTabla(_tablaSeveridades);
  }

  // =============================================================
  // ESTADO LOCAL
  // =============================================================

  Future<bool> tieneCatalogosCompletos() async {
    final List<PeligroModel> peligros = await obtenerPeligros();

    final List<ConsecuenciaModel> consecuencias = await obtenerConsecuencias();

    final List<ProbabilidadModel> probabilidades =
        await obtenerProbabilidades();

    final List<SeveridadModel> severidades = await obtenerSeveridades();

    return peligros.isNotEmpty &&
        consecuencias.isNotEmpty &&
        _escalaProbabilidadesCompleta(probabilidades) &&
        _escalaSeveridadesCompleta(severidades);
  }

  // =============================================================
  // RESUMEN PARA DIAGNÓSTICO
  // =============================================================

  /// Permite comprobar fácilmente cuántos registros realmente
  /// quedaron almacenados en SQLite.
  Future<Map<String, int>> obtenerResumenLocal() async {
    return <String, int>{
      'peligros': await contarPeligros(),
      'consecuencias': await contarConsecuencias(),
      'probabilidades': await contarProbabilidades(),
      'severidades': await contarSeveridades(),
    };
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
  // METADATA INTERNA
  // =============================================================

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

  // =============================================================
  // CONTAR TABLA
  // =============================================================

  Future<int> _contarTabla(String tabla) async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    final List<Map<String, Object?>> resultado = await db.rawQuery(
      'SELECT COUNT(*) FROM $tabla',
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  // =============================================================
  // VALIDAR ESCALAS
  // =============================================================

  bool _escalaProbabilidadesCompleta(List<ProbabilidadModel> items) {
    final Set<int> valores = items
        .where(
          (ProbabilidadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((ProbabilidadModel item) => item.valor)
        .toSet();

    return valores.containsAll(const <int>{1, 2, 3, 4, 5});
  }

  bool _escalaSeveridadesCompleta(List<SeveridadModel> items) {
    final Set<int> valores = items
        .where(
          (SeveridadModel item) =>
              item.id > 0 && item.valor >= 1 && item.valor <= 5,
        )
        .map((SeveridadModel item) => item.valor)
        .toSet();

    return valores.containsAll(const <int>{1, 2, 3, 4, 5});
  }

  // =============================================================
  // PARSE ENTERO
  // =============================================================

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
