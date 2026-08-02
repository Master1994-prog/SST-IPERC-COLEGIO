import '../datasources/local/detalle_iperc_local_datasource.dart';
import '../models/detalle_iperc_local_model.dart';

/// Repositorio para administrar los detalles IPERC almacenados en SQLite.
///
/// Las pantallas y providers deben utilizar este repositorio en lugar de
/// acceder directamente al datasource.
class DetalleIpercLocalRepository {
  DetalleIpercLocalRepository({DetalleIpercLocalDatasource? datasource})
    : _datasource = datasource ?? DetalleIpercLocalDatasource();

  final DetalleIpercLocalDatasource _datasource;

  /// Registra un detalle IPERC localmente.
  ///
  /// El datasource también agregará la operación a la cola de sincronización.
  Future<void> crear(DetalleIpercLocalModel detalle) async {
    _validarDetalle(detalle);
    await _datasource.crear(detalle);
  }

  /// Busca un detalle por su identificador local.
  Future<DetalleIpercLocalModel?> obtenerPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    return _datasource.obtenerPorIdLocal(id);
  }

  /// Busca un detalle por el identificador asignado por el servidor.
  Future<DetalleIpercLocalModel?> obtenerPorIdServidor(
    String idServidor,
  ) async {
    final String id = idServidor.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador del servidor es obligatorio.');
    }

    return _datasource.obtenerPorIdServidor(id);
  }

  /// Lista los detalles activos pertenecientes a una matriz local.
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

  /// Lista todos los detalles IPERC activos almacenados localmente.
  Future<List<DetalleIpercLocalModel>> listarTodos() async {
    return _datasource.listarTodos();
  }

  /// Lista los detalles que todavía no se han sincronizado.
  Future<List<DetalleIpercLocalModel>> listarPendientes() async {
    return _datasource.listarPendientes();
  }

  /// Actualiza un detalle y lo deja pendiente de sincronización.
  Future<void> actualizar(DetalleIpercLocalModel detalle) async {
    _validarDetalle(detalle);
    await _datasource.actualizar(detalle);
  }

  /// Elimina lógicamente un detalle local.
  ///
  /// La eliminación definitiva ocurrirá después de que el backend confirme
  /// la sincronización.
  Future<void> eliminar(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    await _datasource.eliminar(id);
  }

  /// Marca un detalle como sincronizado y guarda su identificador remoto.
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

    await _datasource.marcarComoSincronizado(
      idLocal: local,
      idServidor: servidor,
    );
  }

  /// Confirma que el backend eliminó el registro y lo borra de SQLite.
  Future<void> confirmarEliminacionSincronizada(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local es obligatorio.');
    }

    await _datasource.confirmarEliminacionSincronizada(id);
  }

  /// Guarda o actualiza un detalle recibido desde el backend.
  ///
  /// No agrega operaciones a la cola porque los datos ya están sincronizados.
  Future<void> guardarDesdeServidor(DetalleIpercLocalModel detalle) async {
    _validarDetalle(detalle);

    if (detalle.idServidor == null || detalle.idServidor!.trim().isEmpty) {
      throw ArgumentError(
        'El detalle recibido debe contener el identificador del servidor.',
      );
    }

    await _datasource.guardarDesdeServidor(detalle);
  }

  /// Devuelve la cantidad de detalles pendientes de sincronización.
  Future<int> contarPendientes() async {
    return _datasource.contarPendientes();
  }

  /// Indica si existen registros pendientes.
  Future<bool> tienePendientes() async {
    final int total = await contarPendientes();
    return total > 0;
  }

  /// Valida la información mínima necesaria del detalle IPERC.
  void _validarDetalle(DetalleIpercLocalModel detalle) {
    if (detalle.idLocal.trim().isEmpty) {
      throw ArgumentError('El identificador local del detalle es obligatorio.');
    }

    if (detalle.matrizIdLocal.trim().isEmpty) {
      throw ArgumentError(
        'El identificador local de la matriz es obligatorio.',
      );
    }

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

    final bool tieneSeveridadResidual = detalle.severidadResidual != null;
    final bool tieneFrecuenciaResidual = detalle.frecuenciaResidual != null;
    final bool tieneValorResidual = detalle.valorRiesgoResidual != null;

    final bool evaluacionResidualIncompleta =
        tieneSeveridadResidual || tieneFrecuenciaResidual || tieneValorResidual;

    if (evaluacionResidualIncompleta &&
        !(tieneSeveridadResidual &&
            tieneFrecuenciaResidual &&
            tieneValorResidual)) {
      throw ArgumentError(
        'La evaluación residual debe incluir severidad, '
        'frecuencia y valor de riesgo.',
      );
    }

    if (tieneSeveridadResidual &&
        tieneFrecuenciaResidual &&
        tieneValorResidual) {
      final int severidad = detalle.severidadResidual!;
      final int frecuencia = detalle.frecuenciaResidual!;
      final int valor = detalle.valorRiesgoResidual!;

      if (severidad < 1 || severidad > 5) {
        throw ArgumentError(
          'La severidad residual debe encontrarse entre 1 y 5.',
        );
      }

      if (frecuencia < 1 || frecuencia > 5) {
        throw ArgumentError(
          'La frecuencia residual debe encontrarse entre 1 y 5.',
        );
      }

      if (valor != severidad * frecuencia) {
        throw ArgumentError(
          'El valor del riesgo residual debe ser igual a '
          'severidad × frecuencia.',
        );
      }

      if (detalle.nivelRiesgoResidual == null ||
          detalle.nivelRiesgoResidual!.trim().isEmpty) {
        throw ArgumentError('El nivel de riesgo residual es obligatorio.');
      }
    }
  }
}
