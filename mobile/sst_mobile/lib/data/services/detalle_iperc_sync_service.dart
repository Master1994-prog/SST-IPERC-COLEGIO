import '../mappers/detalle_iperc_sync_mapper.dart';
import '../models/detalle_iperc_local_model.dart';
import '../models/detalle_iperc_model.dart';
import '../models/evaluacion_riesgo_model.dart';
import '../repositories/detalle_iperc_local_repository.dart';
import '../repositories/detalle_iperc_repository.dart';
import '../repositories/evaluacion_riesgo_repository.dart';

/// Resultado general de una sincronización de detalles IPERC.
class DetalleIpercSyncResult {
  const DetalleIpercSyncResult({
    required this.total,
    required this.sincronizados,
    required this.fallidos,
    required this.errores,
  });

  final int total;
  final int sincronizados;
  final int fallidos;
  final List<String> errores;

  bool get exitoso {
    return fallidos == 0;
  }

  bool get parcialmenteExitoso {
    return sincronizados > 0 && fallidos > 0;
  }

  bool get sinPendientes {
    return total == 0;
  }
}

/// Sincroniza los detalles IPERC almacenados localmente con el backend.
///
/// El proceso se ejecuta en este orden:
///
/// 1. Obtener registros pendientes.
/// 2. Resolver creación, actualización o eliminación.
/// 3. Crear las evaluaciones que todavía no existen.
/// 4. Enviar el detalle al backend.
/// 5. Marcar el registro local como sincronizado.
class DetalleIpercSyncService {
  DetalleIpercSyncService({
    DetalleIpercLocalRepository? localRepository,
    DetalleIpercRepository? remoteRepository,
    EvaluacionRiesgoRepository? evaluacionRepository,
  }) : _localRepository = localRepository ?? DetalleIpercLocalRepository(),
       _remoteRepository = remoteRepository ?? DetalleIpercRepository(),
       _evaluacionRepository =
           evaluacionRepository ?? EvaluacionRiesgoRepository();

  final DetalleIpercLocalRepository _localRepository;
  final DetalleIpercRepository _remoteRepository;
  final EvaluacionRiesgoRepository _evaluacionRepository;

  bool _sincronizando = false;

  bool get sincronizando {
    return _sincronizando;
  }

  /// Sincroniza un único detalle utilizando su identificador local.
  ///
  /// Este método se utiliza desde el sincronizador general de la aplicación
  /// cuando procesa una operación DETALLE_IPERC de la cola.
  Future<void> sincronizarPorIdLocal(String idLocal) async {
    final String id = idLocal.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador local del detalle es obligatorio.');
    }

    final DetalleIpercLocalModel? detalle = await _localRepository
        .obtenerPorIdLocal(id);

    /*
   * El registro puede no existir cuando una eliminación ya fue
   * confirmada anteriormente. En ese caso no se vuelve a procesar.
   */
    if (detalle == null) {
      return;
    }

    await _sincronizarDetalle(detalle);
  }

  /// Sincroniza todos los detalles pendientes.
  Future<DetalleIpercSyncResult> sincronizarPendientes() async {
    if (_sincronizando) {
      return const DetalleIpercSyncResult(
        total: 0,
        sincronizados: 0,
        fallidos: 0,
        errores: <String>[
          'Ya existe una sincronización de detalles IPERC en ejecución.',
        ],
      );
    }

    _sincronizando = true;

    int sincronizados = 0;
    int fallidos = 0;

    final List<String> errores = <String>[];

    try {
      final List<DetalleIpercLocalModel> pendientes = await _localRepository
          .listarPendientes();

      for (final DetalleIpercLocalModel detalle in pendientes) {
        try {
          await _sincronizarDetalle(detalle);
          sincronizados++;
        } catch (error) {
          fallidos++;

          errores.add('Detalle ${detalle.idLocal}: ${_limpiarError(error)}');
        }
      }

      return DetalleIpercSyncResult(
        total: pendientes.length,
        sincronizados: sincronizados,
        fallidos: fallidos,
        errores: errores,
      );
    } finally {
      _sincronizando = false;
    }
  }

  /// Sincroniza un único detalle.
  Future<void> _sincronizarDetalle(DetalleIpercLocalModel detalle) async {
    if (detalle.eliminado) {
      await _sincronizarEliminacion(detalle);
      return;
    }

    final DetalleIpercLocalModel detallePreparado = await _prepararEvaluaciones(
      detalle,
    );

    final bool requiereCreacion = DetalleIpercSyncMapper.requiereCreacion(
      detallePreparado,
    );

    if (requiereCreacion) {
      await _sincronizarCreacion(detallePreparado);
      return;
    }

    await _sincronizarActualizacion(detallePreparado);
  }

  /// Crea las evaluaciones inicial y residual cuando todavía no existen.
  Future<DetalleIpercLocalModel> _prepararEvaluaciones(
    DetalleIpercLocalModel detalle,
  ) async {
    int? evaluacionInicialId = detalle.evaluacionInicialId;

    int? evaluacionResidualId = detalle.evaluacionResidualId;

    if (evaluacionInicialId == null || evaluacionInicialId <= 0) {
      final EvaluacionRiesgoModel evaluacionInicial = await _crearEvaluacion(
        frecuencia: detalle.frecuenciaInicial,
        severidad: detalle.severidadInicial,
        observaciones: 'Evaluación inicial sincronizada desde el dispositivo.',
      );

      evaluacionInicialId = evaluacionInicial.id;
    }

    final bool tieneEvaluacionResidual =
        detalle.severidadResidual != null &&
        detalle.frecuenciaResidual != null &&
        detalle.valorRiesgoResidual != null;

    if (tieneEvaluacionResidual &&
        (evaluacionResidualId == null || evaluacionResidualId <= 0)) {
      final EvaluacionRiesgoModel evaluacionResidual = await _crearEvaluacion(
        frecuencia: detalle.frecuenciaResidual!,
        severidad: detalle.severidadResidual!,
        observaciones: 'Evaluación residual sincronizada desde el dispositivo.',
      );

      evaluacionResidualId = evaluacionResidual.id;
    }

    return detalle.copyWith(
      evaluacionInicialId: evaluacionInicialId,
      evaluacionResidualId: evaluacionResidualId,
    );
  }

  /// Registra una evaluación de riesgo en el backend.
  Future<EvaluacionRiesgoModel> _crearEvaluacion({
    required int frecuencia,
    required int severidad,
    required String observaciones,
  }) async {
    final ProbabilidadIpercOption probabilidad = _obtenerProbabilidad(
      frecuencia,
    );

    final SeveridadIpercOption severidadOption = _obtenerSeveridad(severidad);

    final int valor = probabilidad.valor * severidadOption.valor;

    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    final CrearEvaluacionRiesgoRequest request = CrearEvaluacionRiesgoRequest(
      probabilidadId: probabilidad.id,
      severidadId: severidadOption.id,
      nivelRiesgoId: nivel.id,
      observaciones: observaciones,
    );

    return _evaluacionRepository.crear(request);
  }

  /// Crea un detalle que todavía no existe en el backend.
  Future<void> _sincronizarCreacion(DetalleIpercLocalModel detalle) async {
    final CrearDetalleIpercRequest request =
        DetalleIpercSyncMapper.toCrearRequest(detalle);

    final DetalleIpercModel creado = await _remoteRepository.crear(request);

    if (creado.id <= 0) {
      throw StateError(
        'El backend no devolvió un identificador válido para el detalle.',
      );
    }

    await _localRepository.marcarComoSincronizado(
      idLocal: detalle.idLocal,
      idServidor: creado.id.toString(),
    );
  }

  /// Actualiza un detalle que ya existe en el backend.
  Future<void> _sincronizarActualizacion(DetalleIpercLocalModel detalle) async {
    final int idServidor = DetalleIpercSyncMapper.obtenerIdServidor(detalle);

    final ActualizarDetalleIpercRequest request =
        DetalleIpercSyncMapper.toActualizarRequest(detalle);

    final DetalleIpercModel actualizado = await _remoteRepository.actualizar(
      request,
    );

    final int idConfirmado = actualizado.id > 0 ? actualizado.id : idServidor;

    await _localRepository.marcarComoSincronizado(
      idLocal: detalle.idLocal,
      idServidor: idConfirmado.toString(),
    );
  }

  /// Elimina un registro del backend o confirma su eliminación local.
  Future<void> _sincronizarEliminacion(DetalleIpercLocalModel detalle) async {
    final String idServidorTexto = detalle.idServidor?.trim() ?? '';

    final int? idServidor = int.tryParse(idServidorTexto);

    /*
     * Cuando nunca llegó al servidor no es necesario ejecutar DELETE.
     * Se elimina directamente de SQLite.
     */
    if (idServidor == null || idServidor <= 0) {
      await _localRepository.confirmarEliminacionSincronizada(detalle.idLocal);

      return;
    }

    await _remoteRepository.eliminar(idServidor);

    await _localRepository.confirmarEliminacionSincronizada(detalle.idLocal);
  }

  /// Busca la opción de probabilidad correspondiente al valor local.
  ProbabilidadIpercOption _obtenerProbabilidad(int valor) {
    if (valor < 1 || valor > 5) {
      throw FormatException(
        'La frecuencia o probabilidad debe encontrarse entre 1 y 5.',
      );
    }

    return probabilidadesIperc.firstWhere(
      (ProbabilidadIpercOption opcion) => opcion.valor == valor,
    );
  }

  /// Busca la opción de severidad correspondiente al valor local.
  SeveridadIpercOption _obtenerSeveridad(int valor) {
    if (valor < 1 || valor > 5) {
      throw FormatException('La severidad debe encontrarse entre 1 y 5.');
    }

    return severidadesIperc.firstWhere(
      (SeveridadIpercOption opcion) => opcion.valor == valor,
    );
  }

  String _limpiarError(Object error) {
    final String texto = error.toString().trim();

    if (texto.startsWith('Exception: ')) {
      return texto.substring('Exception: '.length);
    }

    if (texto.startsWith('FormatException: ')) {
      return texto.substring('FormatException: '.length);
    }

    return texto.isEmpty ? 'Error desconocido.' : texto;
  }
}
