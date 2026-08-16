import '../datasources/local/detalle_iperc_local_datasource.dart';
import '../models/detalle_iperc_local_model.dart';

/// ===============================================================
/// REPOSITORIO LOCAL - DETALLE IPERC
/// ===============================================================
///
/// Administra los detalles IPERC almacenados en SQLite.
///
/// Responsabilidades:
///
/// - Crear.
/// - Consultar.
/// - Actualizar.
/// - Eliminar.
/// - Validar datos antes de enviarlos al datasource.
/// - Confirmar sincronización.
/// - Guardar información recibida desde el backend.
///
/// IMPORTANTE:
///
/// Los IDs reales de Probabilidad y Severidad se validan por separado
/// de sus valores IPERC 1..5.
///
/// Ejemplo:
///
/// probabilidadInicialId = 8
/// frecuenciaInicial = 3
///
/// Nunca se debe asumir:
///
/// ID catálogo == valor IPERC
/// ===============================================================
class DetalleIpercLocalRepository {
  DetalleIpercLocalRepository({DetalleIpercLocalDatasource? datasource})
    : _datasource = datasource ?? DetalleIpercLocalDatasource();

  final DetalleIpercLocalDatasource _datasource;

  // =============================================================
  // CREAR
  // =============================================================

  Future<void> crear(DetalleIpercLocalModel detalle) async {
    _validarDetalle(detalle, exigirIdsCatalogo: true);

    await _datasource.crear(detalle);
  }

  // =============================================================
  // OBTENER POR ID LOCAL
  // =============================================================

  Future<DetalleIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    return _datasource.obtenerPorIdLocal(id);
  }

  // =============================================================
  // OBTENER POR ID SERVIDOR
  // =============================================================

  Future<DetalleIpercLocalModel?> obtenerPorIdServidor(
    String idServidor,
  ) async {
    final String id = idServidor.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador del servidor es obligatorio.');
    }

    final int? idNumerico = int.tryParse(id);

    if (idNumerico == null || idNumerico <= 0) {
      throw ArgumentError('El identificador del servidor no es válido.');
    }

    return _datasource.obtenerPorIdServidor(id);
  }

  // =============================================================
  // LISTAR POR MATRIZ
  // =============================================================

  Future<List<DetalleIpercLocalModel>> listarPorMatriz(
    String matrizIdLocal,
  ) async {
    final String matrizId = matrizIdLocal.trim();

    if (matrizId.isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    return _datasource.listarPorMatriz(matrizId);
  }

  // =============================================================
  // LISTAR TODOS
  // =============================================================

  Future<List<DetalleIpercLocalModel>> listarTodos() async {
    return _datasource.listarTodos();
  }

  // =============================================================
  // LISTAR PENDIENTES
  // =============================================================

  Future<List<DetalleIpercLocalModel>> listarPendientes() async {
    return _datasource.listarPendientes();
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> actualizar(DetalleIpercLocalModel detalle) async {
    _validarDetalle(detalle, exigirIdsCatalogo: true);

    await _datasource.actualizar(detalle);
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> eliminar(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    await _datasource.eliminar(id);
  }

  // =============================================================
  // MARCAR COMO SINCRONIZADO
  // =============================================================

  Future<void> marcarComoSincronizado({
    required String idLocal,
    required String idServidor,
  }) async {
    final String local = idLocal.trim();

    final String servidor = idServidor.trim();

    if (local.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    if (servidor.isEmpty) {
      throw ArgumentError(
        'El identificador asignado por el servidor es obligatorio.',
      );
    }

    final int? servidorNumerico = int.tryParse(servidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw ArgumentError(
        'El identificador asignado por el servidor no es válido.',
      );
    }

    await _datasource.marcarComoSincronizado(
      idLocal: local,
      idServidor: servidor,
    );
  }

  // =============================================================
  // CONFIRMAR ELIMINACIÓN
  // =============================================================

  Future<void> confirmarEliminacionSincronizada(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    await _datasource.confirmarEliminacionSincronizada(id);
  }

  // =============================================================
  // GUARDAR DESDE SERVIDOR
  // =============================================================

  Future<void> guardarDesdeServidor(DetalleIpercLocalModel detalle) async {
    // -----------------------------------------------------------
    // VALIDACIÓN ESTRUCTURAL
    // -----------------------------------------------------------
    //
    // Para datos recibidos del backend no exigimos de forma
    // estricta todos los IDs de catálogo antiguos.
    //
    // Esto evita rechazar registros históricos mientras la
    // aplicación todavía mantiene compatibilidad con versiones
    // anteriores.
    // -----------------------------------------------------------

    _validarDetalle(detalle, exigirIdsCatalogo: false);

    final String idServidor = detalle.idServidor?.trim() ?? '';

    if (idServidor.isEmpty) {
      throw ArgumentError(
        'El detalle recibido debe contener '
        'el identificador del servidor.',
      );
    }

    final int? servidorNumerico = int.tryParse(idServidor);

    if (servidorNumerico == null || servidorNumerico <= 0) {
      throw ArgumentError(
        'El identificador del servidor '
        'del detalle no es válido.',
      );
    }

    await _datasource.guardarDesdeServidor(detalle);
  }

  // =============================================================
  // CONTAR PENDIENTES
  // =============================================================

  Future<int> contarPendientes() async {
    return _datasource.contarPendientes();
  }

  // =============================================================
  // TIENE PENDIENTES
  // =============================================================

  Future<bool> tienePendientes() async {
    final int total = await contarPendientes();

    return total > 0;
  }

  // =============================================================
  // VALIDACIÓN GENERAL
  // =============================================================

  void _validarDetalle(
    DetalleIpercLocalModel detalle, {
    required bool exigirIdsCatalogo,
  }) {
    // ===========================================================
    // IDENTIFICADORES PRINCIPALES
    // ===========================================================

    if (detalle.idLocal.trim().isEmpty) {
      throw ArgumentError('El identificador local del detalle es obligatorio.');
    }

    if (detalle.matrizIdLocal.trim().isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

    if (detalle.matrizIdServidor != null && detalle.matrizIdServidor! <= 0) {
      throw ArgumentError(
        'El identificador de la matriz en el servidor no es válido.',
      );
    }

    if (detalle.idServidor != null && detalle.idServidor!.trim().isNotEmpty) {
      final int? idServidor = int.tryParse(detalle.idServidor!.trim());

      if (idServidor == null || idServidor <= 0) {
        throw ArgumentError(
          'El identificador del detalle en el servidor no es válido.',
        );
      }
    }

    // ===========================================================
    // ÍTEM / TAREA
    // ===========================================================

    if (detalle.item <= 0) {
      throw ArgumentError('El número de ítem debe ser mayor que cero.');
    }

    if (detalle.tarea.trim().isEmpty) {
      throw ArgumentError('La tarea del detalle IPERC es obligatoria.');
    }

    // ===========================================================
    // PELIGRO
    // ===========================================================

    final int? peligroId = _idPositivoOpcional(detalle.peligroId);

    if (peligroId == null) {
      throw ArgumentError('El detalle debe contener un peligro válido.');
    }

    // ===========================================================
    // CONSECUENCIA
    // ===========================================================

    final int? consecuenciaId = _idPositivoOpcional(detalle.consecuenciaId);

    if (consecuenciaId == null) {
      throw ArgumentError('El detalle debe contener una consecuencia válida.');
    }

    // ===========================================================
    // EVALUACIÓN INICIAL - IDS REALES
    // ===========================================================

    if (exigirIdsCatalogo) {
      if (detalle.probabilidadInicialId == null ||
          detalle.probabilidadInicialId! <= 0) {
        throw ArgumentError(
          'El ID real de la probabilidad inicial es obligatorio.',
        );
      }

      if (detalle.severidadInicialId == null ||
          detalle.severidadInicialId! <= 0) {
        throw ArgumentError(
          'El ID real de la severidad inicial es obligatorio.',
        );
      }
    } else {
      if (detalle.probabilidadInicialId != null &&
          detalle.probabilidadInicialId! <= 0) {
        throw ArgumentError('El ID de probabilidad inicial no es válido.');
      }

      if (detalle.severidadInicialId != null &&
          detalle.severidadInicialId! <= 0) {
        throw ArgumentError('El ID de severidad inicial no es válido.');
      }
    }

    // ===========================================================
    // EVALUACIÓN INICIAL - VALORES 1..5
    // ===========================================================

    if (detalle.severidadInicial < 1 || detalle.severidadInicial > 5) {
      throw ArgumentError('La severidad inicial debe encontrarse entre 1 y 5.');
    }

    if (detalle.frecuenciaInicial < 1 || detalle.frecuenciaInicial > 5) {
      throw ArgumentError(
        'La frecuencia inicial debe encontrarse entre 1 y 5.',
      );
    }

    final int riesgoInicialEsperado =
        detalle.severidadInicial * detalle.frecuenciaInicial;

    if (detalle.valorRiesgoInicial != riesgoInicialEsperado) {
      throw ArgumentError(
        'El valor del riesgo inicial debe ser igual a '
        'severidad × frecuencia.',
      );
    }

    if (detalle.nivelRiesgoInicial.trim().isEmpty) {
      throw ArgumentError('El nivel del riesgo inicial es obligatorio.');
    }

    // ===========================================================
    // CONTROLES
    // ===========================================================

    _validarListaIds(detalle.controlIds, nombre: 'control');

    // ===========================================================
    // EPP
    // ===========================================================

    _validarListaIds(
      detalle.equipoProteccionIds,
      nombre: 'equipo de protección',
    );

    // ===========================================================
    // EVALUACIÓN RESIDUAL
    // ===========================================================

    final bool tieneProbabilidadResidual = detalle.frecuenciaResidual != null;

    final bool tieneSeveridadResidual = detalle.severidadResidual != null;

    final bool tieneValorResidual = detalle.valorRiesgoResidual != null;

    final bool tieneNivelResidual =
        detalle.nivelRiesgoResidual != null &&
        detalle.nivelRiesgoResidual!.trim().isNotEmpty;

    final bool tieneProbabilidadResidualId =
        detalle.probabilidadResidualId != null;

    final bool tieneSeveridadResidualId = detalle.severidadResidualId != null;

    final bool existeCualquierDatoResidual =
        tieneProbabilidadResidual ||
        tieneSeveridadResidual ||
        tieneValorResidual ||
        tieneNivelResidual ||
        tieneProbabilidadResidualId ||
        tieneSeveridadResidualId;

    if (existeCualquierDatoResidual) {
      if (!tieneProbabilidadResidual ||
          !tieneSeveridadResidual ||
          !tieneValorResidual ||
          !tieneNivelResidual) {
        throw ArgumentError(
          'La evaluación residual debe incluir '
          'probabilidad, severidad, valor y nivel de riesgo.',
        );
      }

      if (exigirIdsCatalogo) {
        if (detalle.probabilidadResidualId == null ||
            detalle.probabilidadResidualId! <= 0) {
          throw ArgumentError(
            'El ID real de la probabilidad residual es obligatorio.',
          );
        }

        if (detalle.severidadResidualId == null ||
            detalle.severidadResidualId! <= 0) {
          throw ArgumentError(
            'El ID real de la severidad residual es obligatorio.',
          );
        }
      } else {
        if (detalle.probabilidadResidualId != null &&
            detalle.probabilidadResidualId! <= 0) {
          throw ArgumentError('El ID de probabilidad residual no es válido.');
        }

        if (detalle.severidadResidualId != null &&
            detalle.severidadResidualId! <= 0) {
          throw ArgumentError('El ID de severidad residual no es válido.');
        }
      }

      final int probabilidad = detalle.frecuenciaResidual!;

      final int severidad = detalle.severidadResidual!;

      final int valor = detalle.valorRiesgoResidual!;

      if (probabilidad < 1 || probabilidad > 5) {
        throw ArgumentError(
          'La probabilidad residual debe encontrarse entre 1 y 5.',
        );
      }

      if (severidad < 1 || severidad > 5) {
        throw ArgumentError(
          'La severidad residual debe encontrarse entre 1 y 5.',
        );
      }

      if (valor != probabilidad * severidad) {
        throw ArgumentError(
          'El valor del riesgo residual debe ser igual a '
          'severidad × probabilidad.',
        );
      }
    }

    // ===========================================================
    // RESPONSABLE
    // ===========================================================

    final String responsable =
        detalle.responsableImplementacionId?.trim() ?? '';

    if (responsable.isNotEmpty) {
      final int? responsableId = int.tryParse(responsable);

      if (responsableId == null || responsableId <= 0) {
        throw ArgumentError(
          'El identificador del responsable '
          'de implementación no es válido.',
        );
      }
    }

    // ===========================================================
    // EVALUACIONES REMOTAS OPCIONALES
    // ===========================================================

    if (detalle.evaluacionInicialId != null &&
        detalle.evaluacionInicialId! <= 0) {
      throw ArgumentError(
        'El identificador de evaluación inicial no es válido.',
      );
    }

    if (detalle.evaluacionResidualId != null &&
        detalle.evaluacionResidualId! <= 0) {
      throw ArgumentError(
        'El identificador de evaluación residual no es válido.',
      );
    }
  }

  // =============================================================
  // VALIDAR LISTA DE IDS
  // =============================================================

  void _validarListaIds(List<String> ids, {required String nombre}) {
    for (final String idTexto in ids) {
      final String id = idTexto.trim();

      if (id.isEmpty) {
        throw ArgumentError('Existe un $nombre sin identificador válido.');
      }

      final int? valor = int.tryParse(id);

      if (valor == null || valor <= 0) {
        throw ArgumentError('El identificador de $nombre no es válido: $id.');
      }
    }
  }

  // =============================================================
  // ID POSITIVO OPCIONAL
  // =============================================================

  int? _idPositivoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      return null;
    }

    return id;
  }
}
