import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Administra la base de datos SQLite del aplicativo.
///
/// Esta base permite registrar información cuando el dispositivo
/// no tiene conexión a internet.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'sst_local.db';
  static const int databaseVersion = 1;

  Database? _database;

  /// Retorna una única instancia de la base de datos.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  /// Crea o abre la base de datos local.
  Future<Database> _initializeDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, databaseName);

    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Activa las relaciones mediante claves foráneas.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea las tablas la primera vez que se inicia la aplicación.
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((Transaction txn) async {
      await _createConfiguracionesTable(txn);
      await _createMatricesIpercTable(txn);
      await _createDetallesIpercTable(txn);
      await _createSyncQueueTable(txn);
    });
  }

  /// Tabla para configuraciones locales.
  Future<void> _createConfiguracionesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');
  }

  /// Cabecera de las matrices IPERC creadas localmente.
  Future<void> _createMatricesIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE matrices_iperc_local (
        id_local TEXT PRIMARY KEY,
        id_servidor TEXT,

        institucion_id TEXT NOT NULL,
        area_id TEXT,
        proceso_id TEXT,
        puesto_trabajo_id TEXT,

        codigo TEXT,
        nombre TEXT NOT NULL,
        descripcion TEXT,

        fecha_evaluacion TEXT NOT NULL,
        estado_matriz TEXT NOT NULL DEFAULT 'BORRADOR',

        sincronizado INTEGER NOT NULL DEFAULT 0,
        eliminado INTEGER NOT NULL DEFAULT 0,

        fecha_registro TEXT NOT NULL,
        fecha_actualizacion TEXT,
        fecha_sincronizacion TEXT
      )
    ''');
  }

  /// Detalles de cada peligro evaluado dentro de una matriz IPERC.
  Future<void> _createDetallesIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalles_iperc_local (
        id_local TEXT PRIMARY KEY,
        id_servidor TEXT,

        matriz_id_local TEXT NOT NULL,

        actividad_id TEXT,
        peligro_id TEXT,
        consecuencia_id TEXT,

        actividad_descripcion TEXT,
        peligro_descripcion TEXT,
        consecuencia_descripcion TEXT,

        severidad_inicial INTEGER NOT NULL,
        frecuencia_inicial INTEGER NOT NULL,
        valor_riesgo_inicial INTEGER NOT NULL,
        nivel_riesgo_inicial TEXT NOT NULL,

        control_descripcion TEXT,

        severidad_residual INTEGER,
        frecuencia_residual INTEGER,
        valor_riesgo_residual INTEGER,
        nivel_riesgo_residual TEXT,

        observaciones TEXT,

        sincronizado INTEGER NOT NULL DEFAULT 0,
        eliminado INTEGER NOT NULL DEFAULT 0,

        fecha_registro TEXT NOT NULL,
        fecha_actualizacion TEXT,
        fecha_sincronizacion TEXT,

        FOREIGN KEY (matriz_id_local)
          REFERENCES matrices_iperc_local(id_local)
          ON DELETE CASCADE
      )
    ''');
  }

  /// Cola de operaciones pendientes de enviar al backend.
  Future<void> _createSyncQueueTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE sincronizaciones_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        entidad TEXT NOT NULL,
        entidad_id_local TEXT NOT NULL,
        operacion TEXT NOT NULL,

        datos_json TEXT NOT NULL,

        estado TEXT NOT NULL DEFAULT 'PENDIENTE',
        numero_intentos INTEGER NOT NULL DEFAULT 0,

        ultimo_error TEXT,

        fecha_creacion TEXT NOT NULL,
        fecha_ultimo_intento TEXT,
        fecha_sincronizacion TEXT
      )
    ''');
  }

  /// Aquí se agregarán futuras migraciones de SQLite.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejemplo futuro:
    //
    // if (oldVersion < 2) {
    //   await db.execute(
    //     'ALTER TABLE matrices_iperc_local ADD COLUMN nueva_columna TEXT',
    //   );
    // }
  }

  /// Elimina toda la base local.
  ///
  /// Usar únicamente durante pruebas o desarrollo.
  Future<void> deleteDatabaseFile() async {
    await close();

    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, databaseName);

    await deleteDatabase(path);
  }

  /// Cierra la conexión SQLite.
  Future<void> close() async {
    final Database? db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
