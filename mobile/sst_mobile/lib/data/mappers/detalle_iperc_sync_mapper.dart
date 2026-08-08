import '../models/detalle_iperc_local_model.dart';
import '../models/detalle_iperc_model.dart';

/// Convierte un detalle IPERC almacenado en SQLite
/// en solicitudes compatibles con el backend.
///
/// El backend actual crea automáticamente las evaluaciones
/// inicial y residual.
///
/// Por eso ya NO enviamos:
/// - evaluacionInicialId
/// - evaluacionResidualId
///
/// Ahora enviamos:
/// - probabilidadInicialId
/// - severidadInicialId
/// - probabilidadResidualId
/// - severidadResidualId
abstract final class DetalleIpercSyncMapper {
  /// Convierte un registro local en una solicitud de creación.
  static CrearDetalleIpercRequest toCrearRequest(
    DetalleIpercLocalModel detalle,
  ) {
    _validarDetalleParaSincronizar(detalle);

    return CrearDetalleIpercRequest(
      matrizIpercId: detalle.matrizIdServidor!,
      item: detalle.item,
      tarea: detalle.tarea.trim(),
      peligroId: _requerirId(detalle.peligroId, 'peligro'),
      consecuenciaId: _requerirId(detalle.consecuenciaId, 'consecuencia'),
      descripcionPeligro: _textoOpcional(detalle.peligroDescripcion),

      // En el modelo local existente, frecuencia
      // representa la probabilidad de la matriz 5x5.
      probabilidadInicialId: _validarEscala(
        detalle.frecuenciaInicial,
        'probabilidad inicial',
      ),

      severidadInicialId: _validarEscala(
        detalle.severidadInicial,
        'severidad inicial',
      ),

      observacionesEvaluacionInicial: _textoOpcional(detalle.observaciones),

      probabilidadResidualId: detalle.frecuenciaResidual == null
          ? null
          : _validarEscala(
              detalle.frecuenciaResidual!,
              'probabilidad residual',
            ),

      severidadResidualId: detalle.severidadResidual == null
          ? null
          : _validarEscala(detalle.severidadResidual!, 'severidad residual'),

      observacionesEvaluacionResidual: null,

      controlIds: _convertirListaIds(detalle.controlIds, nombre: 'control'),

      equipoProteccionIds: _convertirListaIds(
        detalle.equipoProteccionIds,
        nombre: 'equipo de protección',
      ),

      responsableImplementacionId: _idOpcional(
        detalle.responsableImplementacionId,
        nombre: 'responsable de implementación',
      ),

      fechaCompromiso: detalle.fechaCompromiso,

      fechaImplementacion: detalle.fechaImplementacion,

      estadoImplementacion: _convertirEstado(detalle.estadoImplementacion),
    );
  }

  /// Convierte un registro local en una solicitud
  /// para actualizarlo.
  static ActualizarDetalleIpercRequest toActualizarRequest(
    DetalleIpercLocalModel detalle,
  ) {
    _validarDetalleParaSincronizar(detalle);

    return ActualizarDetalleIpercRequest(
      // Para actualizar, el ID remoto es obligatorio.
      id: obtenerIdServidor(detalle),

      matrizIpercId: detalle.matrizIdServidor!,

      item: detalle.item,

      tarea: detalle.tarea.trim(),

      peligroId: _requerirId(detalle.peligroId, 'peligro'),

      consecuenciaId: _requerirId(detalle.consecuenciaId, 'consecuencia'),

      descripcionPeligro: _textoOpcional(detalle.peligroDescripcion),

      probabilidadInicialId: _validarEscala(
        detalle.frecuenciaInicial,
        'probabilidad inicial',
      ),

      severidadInicialId: _validarEscala(
        detalle.severidadInicial,
        'severidad inicial',
      ),

      observacionesEvaluacionInicial: _textoOpcional(detalle.observaciones),

      probabilidadResidualId: detalle.frecuenciaResidual == null
          ? null
          : _validarEscala(
              detalle.frecuenciaResidual!,
              'probabilidad residual',
            ),

      severidadResidualId: detalle.severidadResidual == null
          ? null
          : _validarEscala(detalle.severidadResidual!, 'severidad residual'),

      observacionesEvaluacionResidual: null,

      controlIds: _convertirListaIds(detalle.controlIds, nombre: 'control'),

      equipoProteccionIds: _convertirListaIds(
        detalle.equipoProteccionIds,
        nombre: 'equipo de protección',
      ),

      responsableImplementacionId: _idOpcional(
        detalle.responsableImplementacionId,
        nombre: 'responsable de implementación',
      ),

      fechaCompromiso: detalle.fechaCompromiso,

      fechaImplementacion: detalle.fechaImplementacion,

      estadoImplementacion: _convertirEstado(detalle.estadoImplementacion),
    );
  }

  /// Obtiene el ID que el backend asignó al detalle.
  static int obtenerIdServidor(DetalleIpercLocalModel detalle) {
    return _requerirId(detalle.idServidor, 'detalle IPERC del servidor');
  }

  /// Indica si aún no existe en el backend.
  static bool requiereCreacion(DetalleIpercLocalModel detalle) {
    final String id = detalle.idServidor?.trim() ?? '';

    final int? valor = int.tryParse(id);

    return id.isEmpty || valor == null || valor <= 0;
  }

  /// Indica si debe cerrarse/eliminarse lógicamente.
  static bool requiereEliminacion(DetalleIpercLocalModel detalle) {
    return detalle.eliminado;
  }

  /// Valida los datos mínimos para sincronizar.
  static void _validarDetalleParaSincronizar(DetalleIpercLocalModel detalle) {
    if (detalle.idLocal.trim().isEmpty) {
      throw const FormatException('El detalle no tiene identificador local.');
    }

    final int? matrizId = detalle.matrizIdServidor;

    if (matrizId == null || matrizId <= 0) {
      throw const FormatException(
        'La matriz todavía no tiene un identificador válido del servidor.',
      );
    }

    if (detalle.item <= 0) {
      throw const FormatException('El número de ítem debe ser mayor que cero.');
    }

    if (detalle.tarea.trim().isEmpty) {
      throw const FormatException('La tarea es obligatoria para sincronizar.');
    }

    _requerirId(detalle.peligroId, 'peligro');

    _requerirId(detalle.consecuenciaId, 'consecuencia');

    _validarEscala(detalle.frecuenciaInicial, 'probabilidad inicial');

    _validarEscala(detalle.severidadInicial, 'severidad inicial');

    final bool tieneProbabilidadResidual = detalle.frecuenciaResidual != null;

    final bool tieneSeveridadResidual = detalle.severidadResidual != null;

    if (tieneProbabilidadResidual != tieneSeveridadResidual) {
      throw const FormatException(
        'La evaluación residual debe tener probabilidad y severidad.',
      );
    }

    if (detalle.frecuenciaResidual != null) {
      _validarEscala(detalle.frecuenciaResidual!, 'probabilidad residual');
    }

    if (detalle.severidadResidual != null) {
      _validarEscala(detalle.severidadResidual!, 'severidad residual');
    }
  }

  /// Valida valores de la escala IPERC 5x5.
  static int _validarEscala(int valor, String nombre) {
    if (valor < 1 || valor > 5) {
      throw FormatException('La $nombre debe estar entre 1 y 5.');
    }

    return valor;
  }

  static int _requerirId(String? value, String nombre) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      throw FormatException('El identificador de $nombre es obligatorio.');
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw FormatException(
        'El identificador de $nombre no es válido: $texto.',
      );
    }

    return id;
  }

  static int? _idOpcional(String? value, {required String nombre}) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw FormatException(
        'El identificador de $nombre no es válido: $texto.',
      );
    }

    return id;
  }

  static List<int> _convertirListaIds(
    List<String> values, {
    required String nombre,
  }) {
    final Set<int> ids = <int>{};

    for (final String value in values) {
      final String texto = value.trim();

      if (texto.isEmpty) {
        continue;
      }

      final int? id = int.tryParse(texto);

      if (id == null || id <= 0) {
        throw FormatException(
          'El identificador de $nombre no es válido: $texto.',
        );
      }

      ids.add(id);
    }

    return ids.toList(growable: false);
  }

  /// Convierte el texto guardado en SQLite
  /// al entero esperado por el backend.
  static int _convertirEstado(String? estado) {
    final String valor = estado?.trim().toUpperCase() ?? 'PENDIENTE';

    return switch (valor) {
      'EN_PROCESO' || 'EN PROCESO' => EstadoImplementacionIperc.enProceso,

      'IMPLEMENTADO' => EstadoImplementacionIperc.implementado,

      'VERIFICADO' => EstadoImplementacionIperc.verificado,

      'CERRADO' => EstadoImplementacionIperc.cerrado,

      _ => EstadoImplementacionIperc.pendiente,
    };
  }

  static String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
