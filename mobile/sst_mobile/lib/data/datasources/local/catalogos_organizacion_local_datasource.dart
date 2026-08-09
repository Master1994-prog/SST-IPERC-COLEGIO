import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../models/catalogo_item_model.dart';

/// ===============================================================
/// CATÁLOGOS DE ORGANIZACIÓN - SQLITE
/// ===============================================================
///
/// Guarda localmente los catálogos que necesita el formulario
/// "Nueva matriz IPERC":
///
/// - Instituciones.
/// - Sedes.
/// - Áreas.
/// - Puestos de trabajo.
/// - Procesos.
/// - Actividades.
///
/// De esta manera el formulario puede funcionar aunque no exista
/// conexión con el backend.
/// ===============================================================
class CatalogosOrganizacionLocalDatasource {
  CatalogosOrganizacionLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  // =============================================================
  // NOMBRES DE TABLAS
  // =============================================================

  static const String _tablaInstituciones = 'instituciones_catalogo_local';

  static const String _tablaSedes = 'sedes_catalogo_local';

  static const String _tablaAreas = 'areas_catalogo_local';

  static const String _tablaPuestos = 'puestos_trabajo_catalogo_local';

  static const String _tablaProcesos = 'procesos_catalogo_local';

  static const String _tablaActividades = 'actividades_catalogo_local';

  // =============================================================
  // PREPARAR TABLAS
  // =============================================================

  Future<void> prepararTablas() async {
    final Database db = await _appDatabase.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaInstituciones (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaSedes (
        id INTEGER PRIMARY KEY,
        padre_id INTEGER,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaAreas (
        id INTEGER PRIMARY KEY,
        padre_id INTEGER,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaPuestos (
        id INTEGER PRIMARY KEY,
        padre_id INTEGER,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaProcesos (
        id INTEGER PRIMARY KEY,
        padre_id INTEGER,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablaActividades (
        id INTEGER PRIMARY KEY,
        padre_id INTEGER,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL,
        fecha_actualizacion_local TEXT NOT NULL
      )
    ''');
  }

  // =============================================================
  // GUARDAR INSTITUCIONES
  // =============================================================

  Future<void> guardarInstituciones(List<CatalogoItemModel> items) async {
    await prepararTablas();

    await _guardarLista(tabla: _tablaInstituciones, items: items);
  }

  // =============================================================
  // GUARDAR SEDES
  // =============================================================

  Future<void> guardarSedes(
    List<CatalogoItemModel> items, {
    required int institucionId,
  }) async {
    await prepararTablas();

    await _guardarLista(
      tabla: _tablaSedes,
      items: items,
      padreId: institucionId,
    );
  }

  // =============================================================
  // GUARDAR ÁREAS
  // =============================================================

  Future<void> guardarAreas(
    List<CatalogoItemModel> items, {
    required int institucionId,
  }) async {
    await prepararTablas();

    await _guardarLista(
      tabla: _tablaAreas,
      items: items,
      padreId: institucionId,
    );
  }

  // =============================================================
  // GUARDAR PUESTOS DE TRABAJO
  // =============================================================

  Future<void> guardarPuestosTrabajo(
    List<CatalogoItemModel> items, {
    required int areaId,
  }) async {
    await prepararTablas();

    await _guardarLista(tabla: _tablaPuestos, items: items, padreId: areaId);
  }

  // =============================================================
  // GUARDAR PROCESOS
  // =============================================================

  Future<void> guardarProcesos(
    List<CatalogoItemModel> items, {
    required int areaId,
  }) async {
    await prepararTablas();

    await _guardarLista(tabla: _tablaProcesos, items: items, padreId: areaId);
  }

  // =============================================================
  // GUARDAR ACTIVIDADES
  // =============================================================

  Future<void> guardarActividades(
    List<CatalogoItemModel> items, {
    int? procesoId,
  }) async {
    await prepararTablas();

    await _guardarLista(
      tabla: _tablaActividades,
      items: items,
      padreId: procesoId,
    );
  }

  // =============================================================
  // OBTENER INSTITUCIONES
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerInstituciones() async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaInstituciones);
  }

  // =============================================================
  // OBTENER SEDES
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerSedes({
    required int institucionId,
  }) async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaSedes, padreId: institucionId);
  }

  // =============================================================
  // OBTENER ÁREAS
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerAreas({
    required int institucionId,
  }) async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaAreas, padreId: institucionId);
  }

  // =============================================================
  // OBTENER PUESTOS
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerPuestosTrabajo({
    required int areaId,
  }) async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaPuestos, padreId: areaId);
  }

  // =============================================================
  // OBTENER PROCESOS
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerProcesos({required int areaId}) async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaProcesos, padreId: areaId);
  }

  // =============================================================
  // OBTENER ACTIVIDADES
  // =============================================================

  Future<List<CatalogoItemModel>> obtenerActividades({int? procesoId}) async {
    await prepararTablas();

    return _obtenerLista(tabla: _tablaActividades, padreId: procesoId);
  }

  // =============================================================
  // GUARDAR LISTA GENÉRICA
  // =============================================================

  Future<void> _guardarLista({
    required String tabla,
    required List<CatalogoItemModel> items,
    int? padreId,
  }) async {
    final Database db = await _appDatabase.database;

    final DateTime ahora = DateTime.now().toUtc();

    await db.transaction((Transaction txn) async {
      // -------------------------------------------------------
      // Eliminamos solo los registros del mismo padre.
      // -------------------------------------------------------

      if (padreId == null) {
        await txn.delete(tabla);
      } else {
        await txn.delete(
          tabla,
          where: 'padre_id = ?',
          whereArgs: <Object?>[padreId],
        );
      }

      // -------------------------------------------------------
      // Insertar nuevos registros.
      // -------------------------------------------------------

      for (final CatalogoItemModel item in items) {
        await txn.insert(tabla, <String, dynamic>{
          'id': item.id,
          if (tabla != _tablaInstituciones) 'padre_id': padreId,
          'nombre': item.nombre,
          'datos_json': jsonEncode(<String, dynamic>{
            'id': item.id,
            'nombre': item.nombre,
          }),
          'fecha_actualizacion_local': ahora.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // =============================================================
  // LEER LISTA GENÉRICA
  // =============================================================

  Future<List<CatalogoItemModel>> _obtenerLista({
    required String tabla,
    int? padreId,
  }) async {
    final Database db = await _appDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      tabla,
      where: padreId == null ? null : 'padre_id = ?',
      whereArgs: padreId == null ? null : <Object?>[padreId],
      orderBy: 'nombre ASC',
    );

    final List<CatalogoItemModel> resultado = <CatalogoItemModel>[];

    for (final Map<String, dynamic> row in rows) {
      try {
        final dynamic json = jsonDecode(row['datos_json'].toString());

        if (json is Map) {
          resultado.add(
            CatalogoItemModel.fromJson(Map<String, dynamic>.from(json)),
          );
        }
      } catch (_) {
        // Si un registro local está dañado,
        // se ignora sin romper todo el catálogo.
      }
    }

    return resultado;
  }

  // =============================================================
  // LIMPIAR TODOS LOS CAMPOS
  // =============================================================

  Future<void> limpiarTodo() async {
    await prepararTablas();

    final Database db = await _appDatabase.database;

    await db.transaction((Transaction txn) async {
      await txn.delete(_tablaInstituciones);

      await txn.delete(_tablaSedes);

      await txn.delete(_tablaAreas);

      await txn.delete(_tablaPuestos);

      await txn.delete(_tablaProcesos);

      await txn.delete(_tablaActividades);
    });
  }
}
