import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Administra la base de datos SQLite del aplicativo.
///
/// Permite registrar matrices y evaluaciones IPERC cuando el dispositivo
/// no tiene conexión a internet y sincronizarlas posteriormente.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'sst_local.db';

  /// Versión 2:
  /// agrega controles y equipos de protección a los detalles IPERC.
  static const int databaseVersion = 2;

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

  /// Crea todas las tablas durante la primera instalación.
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((Transaction txn) async {
      await _createConfiguracionesTable(txn);
      await _createMatricesIpercTable(txn);
      await _createDetallesIpercTable(txn);
      await _createSyncQueueTable(txn);
      await _createIndexes(txn);
    });
  }

  /// Tabla para configuraciones locales del aplicativo.
  Future<void> _createConfiguracionesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');
  }

  /// Cabecera de las matrices IPERC almacenadas localmente.
  Future<void> _createMatricesIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE matrices_iperc_local (
        id_local TEXT PRIMARY KEY,
        id_servidor TEXT,

        institucion_id TEXT NOT NULL,
        sede_id TEXT,
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

  /// Detalles y evaluaciones de riesgos de cada matriz IPERC.
  ///
  /// Los identificadores de controles y EPP se almacenan como JSON.
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

        control_ids_json TEXT NOT NULL DEFAULT '[]',
        equipo_proteccion_ids_json TEXT NOT NULL DEFAULT '[]',
        control_descripcion TEXT,

        severidad_residual INTEGER,
        frecuencia_residual INTEGER,
        valor_riesgo_residual INTEGER,
        nivel_riesgo_residual TEXT,

        responsable_implementacion_id TEXT,
        fecha_compromiso TEXT,
        fecha_implementacion TEXT,
        estado_implementacion TEXT,

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

  /// Crea índices para acelerar las consultas y la sincronización.
  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_sincronizado
      ON matrices_iperc_local(sincronizado, eliminado)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_detalles_iperc_matriz
      ON detalles_iperc_local(matriz_id_local)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_detalles_iperc_sincronizado
      ON detalles_iperc_local(sincronizado, eliminado)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_sincronizaciones_estado
      ON sincronizaciones_pendientes(estado, fecha_creacion)
    ''');

    /// Evita colocar varias veces la misma operación pendiente.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS
      idx_sincronizacion_operacion_unica
      ON sincronizaciones_pendientes(
        entidad,
        entidad_id_local,
        operacion
      )
      WHERE estado = 'PENDIENTE'
    ''');
  }

  /// Ejecuta las migraciones cuando aumenta la versión de SQLite.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((Transaction txn) async {
      if (oldVersion < 2) {
        await _upgradeToVersion2(txn);
      }

      await _createIndexes(txn);
    });
  }

  /// Actualiza una base de datos versión 1 a versión 2.
  Future<void> _upgradeToVersion2(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE matrices_iperc_local
      ADD COLUMN sede_id TEXT
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN control_ids_json TEXT NOT NULL DEFAULT '[]'
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN equipo_proteccion_ids_json TEXT NOT NULL DEFAULT '[]'
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN responsable_implementacion_id TEXT
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN fecha_compromiso TEXT
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN fecha_implementacion TEXT
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN estado_implementacion TEXT
    ''');
  }

  /// Elimina toda la base de datos local.
  ///
  /// Debe utilizarse únicamente durante pruebas o desarrollo.
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
