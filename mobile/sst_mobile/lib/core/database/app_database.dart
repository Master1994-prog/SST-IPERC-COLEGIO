import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// ===============================================================
/// BASE DE DATOS LOCAL
/// ===============================================================
///
/// Administra SQLite para el funcionamiento offline del sistema
/// SST / IPERC.
///
/// Historial:
///
/// Versión 1:
/// - Base inicial.
///
/// Versión 2:
/// - sede_id.
/// - controles.
/// - EPP.
/// - datos de implementación.
///
/// Versión 3:
/// - matriz_id_servidor.
/// - item.
/// - tarea.
/// - evaluacion_inicial_id.
/// - evaluacion_residual_id.
///
/// Versión 4:
/// - probabilidad_inicial_id.
/// - severidad_inicial_id.
/// - probabilidad_residual_id.
/// - severidad_residual_id.
///
/// Versión 5:
/// - actividad_id en matrices_iperc_local.
///
/// Versión 6:
/// - seguimientos_iperc_local.
///
/// Versión 7:
/// - mapas_riesgo_local.
/// ===============================================================
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'sst_local.db';

  // =============================================================
  // VERSIÓN ACTUAL
  // =============================================================

  static const int databaseVersion = 7;

  Database? _database;

  // =============================================================
  // OBTENER BASE DE DATOS
  // =============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  // =============================================================
  // INICIALIZAR
  // =============================================================

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

  // =============================================================
  // CONFIGURAR
  // =============================================================

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // =============================================================
  // CREAR BASE DE DATOS
  // =============================================================

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((Transaction txn) async {
      await _createConfiguracionesTable(txn);

      await _createMatricesIpercTable(txn);

      await _createDetallesIpercTable(txn);

      await _createSeguimientosIpercTable(txn);

      await _createMapasRiesgoTable(txn);

      await _createSyncQueueTable(txn);

      await _createIndexes(txn);
    });
  }

  // =============================================================
  // CONFIGURACIONES
  // =============================================================

  Future<void> _createConfiguracionesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');
  }

  // =============================================================
  // MATRICES IPERC LOCAL
  // =============================================================

  Future<void> _createMatricesIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE matrices_iperc_local (

        id_local TEXT PRIMARY KEY,

        id_servidor TEXT,

        -- =====================================================
        -- RELACIONES
        -- =====================================================

        institucion_id TEXT NOT NULL,

        sede_id TEXT,

        area_id TEXT,

        proceso_id TEXT,

        actividad_id TEXT,

        puesto_trabajo_id TEXT,

        -- =====================================================
        -- DATOS DE MATRIZ
        -- =====================================================

        codigo TEXT,

        nombre TEXT NOT NULL,

        descripcion TEXT,

        fecha_evaluacion TEXT NOT NULL,

        estado_matriz TEXT NOT NULL
          DEFAULT 'BORRADOR',

        -- =====================================================
        -- SINCRONIZACIÓN
        -- =====================================================

        sincronizado INTEGER NOT NULL
          DEFAULT 0,

        eliminado INTEGER NOT NULL
          DEFAULT 0,

        fecha_registro TEXT NOT NULL,

        fecha_actualizacion TEXT,

        fecha_sincronizacion TEXT
      )
    ''');
  }

  // =============================================================
  // DETALLES IPERC LOCAL
  // =============================================================

  Future<void> _createDetallesIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE detalles_iperc_local (

        id_local TEXT PRIMARY KEY,

        id_servidor TEXT,

        matriz_id_local TEXT NOT NULL,

        matriz_id_servidor INTEGER,

        item INTEGER NOT NULL
          DEFAULT 1,

        tarea TEXT NOT NULL
          DEFAULT '',

        actividad_id TEXT,

        peligro_id TEXT,

        consecuencia_id TEXT,

        actividad_descripcion TEXT,

        peligro_descripcion TEXT,

        consecuencia_descripcion TEXT,

        -- =====================================================
        -- EVALUACIÓN INICIAL
        -- =====================================================

        evaluacion_inicial_id INTEGER,

        probabilidad_inicial_id INTEGER,

        severidad_inicial_id INTEGER,

        severidad_inicial INTEGER NOT NULL,

        frecuencia_inicial INTEGER NOT NULL,

        valor_riesgo_inicial INTEGER NOT NULL,

        nivel_riesgo_inicial TEXT NOT NULL,

        -- =====================================================
        -- CONTROLES / EPP
        -- =====================================================

        control_ids_json TEXT NOT NULL
          DEFAULT '[]',

        equipo_proteccion_ids_json TEXT NOT NULL
          DEFAULT '[]',

        control_descripcion TEXT,

        -- =====================================================
        -- EVALUACIÓN RESIDUAL
        -- =====================================================

        evaluacion_residual_id INTEGER,

        probabilidad_residual_id INTEGER,

        severidad_residual_id INTEGER,

        severidad_residual INTEGER,

        frecuencia_residual INTEGER,

        valor_riesgo_residual INTEGER,

        nivel_riesgo_residual TEXT,

        -- =====================================================
        -- IMPLEMENTACIÓN
        -- =====================================================

        responsable_implementacion_id TEXT,

        fecha_compromiso TEXT,

        fecha_implementacion TEXT,

        estado_implementacion TEXT,

        observaciones TEXT,

        -- =====================================================
        -- SINCRONIZACIÓN
        -- =====================================================

        sincronizado INTEGER NOT NULL
          DEFAULT 0,

        eliminado INTEGER NOT NULL
          DEFAULT 0,

        fecha_registro TEXT NOT NULL,

        fecha_actualizacion TEXT,

        fecha_sincronizacion TEXT,

        FOREIGN KEY (
          matriz_id_local
        )
        REFERENCES matrices_iperc_local(
          id_local
        )
        ON DELETE CASCADE
      )
    ''');
  }

  // =============================================================
  // SEGUIMIENTOS IPERC LOCAL
  // =============================================================

  Future<void> _createSeguimientosIpercTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS seguimientos_iperc_local (

        id_local TEXT PRIMARY KEY,

        id_servidor INTEGER,

        -- =====================================================
        -- DETALLE IPERC PADRE
        -- =====================================================

        detalle_iperc_id_local TEXT NOT NULL,

        detalle_iperc_id_servidor INTEGER,

        detalle_item INTEGER,

        detalle_tarea TEXT,

        -- =====================================================
        -- SEGUIMIENTO
        -- =====================================================

        fecha_seguimiento TEXT NOT NULL,

        usuario_id INTEGER NOT NULL,

        usuario_nombre TEXT,

        descripcion TEXT NOT NULL,

        porcentaje_avance REAL NOT NULL
          DEFAULT 0
          CHECK (
            porcentaje_avance >= 0
            AND porcentaje_avance <= 100
          ),

        verificado INTEGER NOT NULL
          DEFAULT 0
          CHECK (
            verificado IN (0, 1)
          ),

        fecha_verificacion TEXT,

        observaciones TEXT,

        -- =====================================================
        -- EVIDENCIA
        -- =====================================================

        archivo TEXT,

        nombre_archivo TEXT,

        tipo_archivo TEXT,

        -- =====================================================
        -- SINCRONIZACIÓN
        -- =====================================================

        sincronizado INTEGER NOT NULL
          DEFAULT 0
          CHECK (
            sincronizado IN (0, 1)
          ),

        eliminado INTEGER NOT NULL
          DEFAULT 0
          CHECK (
            eliminado IN (0, 1)
          ),

        fecha_registro TEXT NOT NULL,

        fecha_actualizacion TEXT,

        fecha_sincronizacion TEXT,

        FOREIGN KEY (
          detalle_iperc_id_local
        )
        REFERENCES detalles_iperc_local(
          id_local
        )
        ON DELETE CASCADE
      )
    ''');
  }

  // =============================================================
  // MAPAS DE RIESGO LOCAL
  // =============================================================

  Future<void> _createMapasRiesgoTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mapas_riesgo_local (
        id_local TEXT PRIMARY KEY,
        id_servidor INTEGER,
        matriz_iperc_id_servidor INTEGER NOT NULL,
        codigo TEXT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        ubicacion TEXT,
        archivo_url_servidor TEXT,
        archivo_local TEXT,
        tipo_archivo TEXT,
        marcadores_json TEXT,
        fecha_elaboracion TEXT NOT NULL,
        fecha_revision TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        estado_mapa TEXT NOT NULL DEFAULT 'Borrador',
        activo INTEGER NOT NULL DEFAULT 1,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        eliminado INTEGER NOT NULL DEFAULT 0,
        fecha_registro TEXT NOT NULL,
        fecha_actualizacion TEXT,
        fecha_sincronizacion TEXT
      )
    ''');
  }

  // =============================================================
  // COLA DE SINCRONIZACIÓN
  // =============================================================

  Future<void> _createSyncQueueTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE sincronizaciones_pendientes (

        id INTEGER PRIMARY KEY AUTOINCREMENT,

        entidad TEXT NOT NULL,

        entidad_id_local TEXT NOT NULL,

        operacion TEXT NOT NULL,

        datos_json TEXT NOT NULL,

        estado TEXT NOT NULL
          DEFAULT 'PENDIENTE',

        numero_intentos INTEGER NOT NULL
          DEFAULT 0,

        ultimo_error TEXT,

        fecha_creacion TEXT NOT NULL,

        fecha_ultimo_intento TEXT,

        fecha_sincronizacion TEXT
      )
    ''');
  }

  // =============================================================
  // ÍNDICES
  // =============================================================

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_sincronizado
      ON matrices_iperc_local(
        sincronizado,
        eliminado
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_institucion
      ON matrices_iperc_local(
        institucion_id
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_sede
      ON matrices_iperc_local(
        sede_id
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_area
      ON matrices_iperc_local(
        area_id
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_matrices_iperc_actividad
      ON matrices_iperc_local(
        actividad_id
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_detalles_iperc_matriz
      ON detalles_iperc_local(
        matriz_id_local
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_detalles_iperc_matriz_servidor
      ON detalles_iperc_local(
        matriz_id_servidor
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_detalles_iperc_sincronizado
      ON detalles_iperc_local(
        sincronizado,
        eliminado
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_seguimientos_iperc_detalle_local
      ON seguimientos_iperc_local(
        detalle_iperc_id_local
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_seguimientos_iperc_detalle_servidor
      ON seguimientos_iperc_local(
        detalle_iperc_id_servidor
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_seguimientos_iperc_sincronizado
      ON seguimientos_iperc_local(
        sincronizado,
        eliminado
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_sincronizaciones_estado
      ON sincronizaciones_pendientes(
        estado,
        fecha_creacion
      )
    ''');

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

  // =============================================================
  // MIGRACIONES
  // =============================================================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((Transaction txn) async {
      // -------------------------------------------------------
      // V1 → V2
      // -------------------------------------------------------

      if (oldVersion < 2) {
        await _upgradeToVersion2(txn);
      }

      // -------------------------------------------------------
      // V2 → V3
      // -------------------------------------------------------

      if (oldVersion < 3) {
        await _upgradeToVersion3(txn);
      }

      // -------------------------------------------------------
      // V3 → V4
      // -------------------------------------------------------

      if (oldVersion < 4) {
        await _upgradeToVersion4(txn);
      }

      // -------------------------------------------------------
      // V4 → V5
      // -------------------------------------------------------

      if (oldVersion < 5) {
        await _upgradeToVersion5(txn);
      }

      // -------------------------------------------------------
      // V5 → V6
      // -------------------------------------------------------

      if (oldVersion < 6) {
        await _upgradeToVersion6(txn);
      }

      if (oldVersion < 7) {
        await _upgradeToVersion7(txn);
      }

      await _createIndexes(txn);
    });
  }

  // =============================================================
  // MIGRACIÓN V1 → V2
  // =============================================================

  Future<void> _upgradeToVersion2(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE matrices_iperc_local
      ADD COLUMN sede_id TEXT
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN control_ids_json
      TEXT NOT NULL DEFAULT '[]'
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN equipo_proteccion_ids_json
      TEXT NOT NULL DEFAULT '[]'
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

  // =============================================================
  // MIGRACIÓN V2 → V3
  // =============================================================

  Future<void> _upgradeToVersion3(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN matriz_id_servidor INTEGER
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN item INTEGER NOT NULL
      DEFAULT 1
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN tarea TEXT NOT NULL
      DEFAULT ''
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN evaluacion_inicial_id INTEGER
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN evaluacion_residual_id INTEGER
    ''');
  }

  // =============================================================
  // MIGRACIÓN V3 → V4
  // =============================================================

  Future<void> _upgradeToVersion4(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN probabilidad_inicial_id INTEGER
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN severidad_inicial_id INTEGER
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN probabilidad_residual_id INTEGER
    ''');

    await db.execute('''
      ALTER TABLE detalles_iperc_local
      ADD COLUMN severidad_residual_id INTEGER
    ''');

    // ----------------------------------------------------------
    // COMPATIBILIDAD TEMPORAL
    // ----------------------------------------------------------
    //
    // Los registros creados con versiones anteriores usaban el
    // valor 1..5 como identificador.
    //
    // Se copia temporalmente ese valor para mantener los datos
    // existentes utilizables.

    await db.execute('''
      UPDATE detalles_iperc_local
      SET probabilidad_inicial_id =
          frecuencia_inicial
      WHERE probabilidad_inicial_id IS NULL
    ''');

    await db.execute('''
      UPDATE detalles_iperc_local
      SET severidad_inicial_id =
          severidad_inicial
      WHERE severidad_inicial_id IS NULL
    ''');

    await db.execute('''
      UPDATE detalles_iperc_local
      SET probabilidad_residual_id =
          frecuencia_residual
      WHERE probabilidad_residual_id IS NULL
        AND frecuencia_residual IS NOT NULL
    ''');

    await db.execute('''
      UPDATE detalles_iperc_local
      SET severidad_residual_id =
          severidad_residual
      WHERE severidad_residual_id IS NULL
        AND severidad_residual IS NOT NULL
    ''');
  }

  // =============================================================
  // MIGRACIÓN V4 → V5
  // =============================================================

  /// Agrega la actividad seleccionada a la matriz IPERC local.
  ///
  /// No elimina ni modifica los registros existentes.
  ///
  /// Las matrices creadas anteriormente quedarán inicialmente con:
  ///
  /// actividad_id = NULL
  Future<void> _upgradeToVersion5(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE matrices_iperc_local
      ADD COLUMN actividad_id TEXT
    ''');
  }

  // =============================================================
  // MIGRACIÓN V5 → V6
  // =============================================================

  /// Agrega la tabla local de Seguimiento IPERC.
  ///
  /// Esta migración es aditiva:
  /// - No elimina tablas.
  /// - No modifica matrices existentes.
  /// - No modifica detalles existentes.
  /// - No borra la cola de sincronización.
  Future<void> _upgradeToVersion6(DatabaseExecutor db) async {
    await _createSeguimientosIpercTable(db);
  }

  // =============================================================
  // ELIMINAR BASE LOCAL
  // =============================================================

  /// Solo debe utilizarse durante desarrollo o pruebas.
  Future<void> deleteDatabaseFile() async {
    await close();

    final String databasesPath = await getDatabasesPath();

    final String path = join(databasesPath, databaseName);

    await deleteDatabase(path);
  }

  // =============================================================
  // CERRAR BASE DE DATOS
  // =============================================================

  Future<void> close() async {
    final Database? db = _database;

    if (db == null) {
      return;
    }

    await db.close();

    _database = null;
  }

  // =============================================================
  // MIGRACIÓN V6 → V7
  // =============================================================

  Future<void> _upgradeToVersion7(DatabaseExecutor db) async {
    await _createMapasRiesgoTable(db);
  }
}
