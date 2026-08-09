import '../models/detalle_iperc_local_model.dart';
import '../models/detalle_iperc_model.dart';

/// ===============================================================
/// MAPPER DE SINCRONIZACIÓN - DETALLE IPERC
/// ===============================================================
///
/// Convierte un detalle almacenado en SQLite en solicitudes
/// compatibles con el backend.
///
/// IMPORTANTE:
///
/// Ya NO usamos:
///
/// frecuenciaInicial
/// severidadInicial
/// frecuenciaResidual
/// severidadResidual
///
/// como si fueran IDs del catálogo.
///
/// Ahora usamos:
///
/// probabilidadInicialId
/// severidadInicialId
/// probabilidadResidualId
/// severidadResidualId
///
/// Los valores 1..5 siguen utilizándose únicamente para:
///
/// - cálculo local;
/// - visualización;
/// - validación de la matriz 5x5.
///
/// El backend es quien crea/recalcula EvaluacionRiesgo.
/// ===============================================================
abstract final class DetalleIpercSyncMapper {
  // =============================================================
  // CREAR
  // =============================================================

  /// Convierte un detalle offline en una solicitud de creación.
  static CrearDetalleIpercRequest toCrearRequest(
    DetalleIpercLocalModel detalle,
  ) {
    _validarDetalleParaSincronizar(detalle);

    return CrearDetalleIpercRequest(
      // ---------------------------------------------------------
      // MATRIZ
      // ---------------------------------------------------------
      matrizIpercId: detalle.matrizIdServidor!,

      item: detalle.item,

      tarea: detalle.tarea.trim(),

      // ---------------------------------------------------------
      // PELIGRO / CONSECUENCIA
      // ---------------------------------------------------------
      peligroId: _requerirIdTexto(detalle.peligroId, 'peligro'),

      consecuenciaId: _requerirIdTexto(detalle.consecuenciaId, 'consecuencia'),

      descripcionPeligro: _textoOpcional(detalle.peligroDescripcion),

      // ---------------------------------------------------------
      // EVALUACIÓN INICIAL
      // ---------------------------------------------------------

      /// Ahora utilizamos el ID real almacenado en SQLite.
      probabilidadInicialId: _requerirIdCatalogo(
        detalle.probabilidadInicialId,
        'probabilidad inicial',
      ),

      severidadInicialId: _requerirIdCatalogo(
        detalle.severidadInicialId,
        'severidad inicial',
      ),

      observacionesEvaluacionInicial: _textoOpcional(detalle.observaciones),

      // ---------------------------------------------------------
      // EVALUACIÓN RESIDUAL
      // ---------------------------------------------------------
      probabilidadResidualId: detalle.tieneEvaluacionResidual
          ? _requerirIdCatalogo(
              detalle.probabilidadResidualId,
              'probabilidad residual',
            )
          : null,

      severidadResidualId: detalle.tieneEvaluacionResidual
          ? _requerirIdCatalogo(
              detalle.severidadResidualId,
              'severidad residual',
            )
          : null,

      observacionesEvaluacionResidual: null,

      // ---------------------------------------------------------
      // CONTROLES
      // ---------------------------------------------------------
      controlIds: _convertirListaIds(detalle.controlIds, nombre: 'control'),

      // ---------------------------------------------------------
      // EPP
      // ---------------------------------------------------------
      equipoProteccionIds: _convertirListaIds(
        detalle.equipoProteccionIds,
        nombre: 'equipo de protección',
      ),

      // ---------------------------------------------------------
      // IMPLEMENTACIÓN
      // ---------------------------------------------------------
      responsableImplementacionId: _idOpcionalTexto(
        detalle.responsableImplementacionId,
        nombre: 'responsable de implementación',
      ),

      fechaCompromiso: detalle.fechaCompromiso,

      fechaImplementacion: detalle.fechaImplementacion,

      estadoImplementacion: _convertirEstado(detalle.estadoImplementacion),
    );
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  /// Convierte un detalle offline en una solicitud de actualización.
  static ActualizarDetalleIpercRequest toActualizarRequest(
    DetalleIpercLocalModel detalle,
  ) {
    _validarDetalleParaSincronizar(detalle);

    return ActualizarDetalleIpercRequest(
      // ---------------------------------------------------------
      // ID DEL DETALLE EN EL BACKEND
      // ---------------------------------------------------------
      id: obtenerIdServidor(detalle),

      // ---------------------------------------------------------
      // MATRIZ
      // ---------------------------------------------------------
      matrizIpercId: detalle.matrizIdServidor!,

      item: detalle.item,

      tarea: detalle.tarea.trim(),

      // ---------------------------------------------------------
      // PELIGRO
      // ---------------------------------------------------------
      peligroId: _requerirIdTexto(detalle.peligroId, 'peligro'),

      consecuenciaId: _requerirIdTexto(detalle.consecuenciaId, 'consecuencia'),

      descripcionPeligro: _textoOpcional(detalle.peligroDescripcion),

      // ---------------------------------------------------------
      // EVALUACIÓN INICIAL
      // ---------------------------------------------------------
      probabilidadInicialId: _requerirIdCatalogo(
        detalle.probabilidadInicialId,
        'probabilidad inicial',
      ),

      severidadInicialId: _requerirIdCatalogo(
        detalle.severidadInicialId,
        'severidad inicial',
      ),

      observacionesEvaluacionInicial: _textoOpcional(detalle.observaciones),

      // ---------------------------------------------------------
      // EVALUACIÓN RESIDUAL
      // ---------------------------------------------------------
      probabilidadResidualId: detalle.tieneEvaluacionResidual
          ? _requerirIdCatalogo(
              detalle.probabilidadResidualId,
              'probabilidad residual',
            )
          : null,

      severidadResidualId: detalle.tieneEvaluacionResidual
          ? _requerirIdCatalogo(
              detalle.severidadResidualId,
              'severidad residual',
            )
          : null,

      observacionesEvaluacionResidual: null,

      // ---------------------------------------------------------
      // CONTROLES
      // ---------------------------------------------------------
      controlIds: _convertirListaIds(detalle.controlIds, nombre: 'control'),

      // ---------------------------------------------------------
      // EPP
      // ---------------------------------------------------------
      equipoProteccionIds: _convertirListaIds(
        detalle.equipoProteccionIds,
        nombre: 'equipo de protección',
      ),

      // ---------------------------------------------------------
      // IMPLEMENTACIÓN
      // ---------------------------------------------------------
      responsableImplementacionId: _idOpcionalTexto(
        detalle.responsableImplementacionId,
        nombre: 'responsable de implementación',
      ),

      fechaCompromiso: detalle.fechaCompromiso,

      fechaImplementacion: detalle.fechaImplementacion,

      estadoImplementacion: _convertirEstado(detalle.estadoImplementacion),
    );
  }

  // =============================================================
  // OBTENER ID SERVIDOR
  // =============================================================

  static int obtenerIdServidor(DetalleIpercLocalModel detalle) {
    return _requerirIdTexto(detalle.idServidor, 'detalle IPERC del servidor');
  }

  // =============================================================
  // ¿REQUIERE CREACIÓN?
  // =============================================================

  static bool requiereCreacion(DetalleIpercLocalModel detalle) {
    final String texto = detalle.idServidor?.trim() ?? '';

    final int? id = int.tryParse(texto);

    return texto.isEmpty || id == null || id <= 0;
  }

  // =============================================================
  // ¿REQUIERE ELIMINACIÓN?
  // =============================================================

  static bool requiereEliminacion(DetalleIpercLocalModel detalle) {
    return detalle.eliminado;
  }

  // =============================================================
  // VALIDACIÓN GENERAL
  // =============================================================

  static void _validarDetalleParaSincronizar(DetalleIpercLocalModel detalle) {
    // -----------------------------------------------------------
    // ID LOCAL
    // -----------------------------------------------------------

    if (detalle.idLocal.trim().isEmpty) {
      throw const FormatException('El detalle no tiene identificador local.');
    }

    // -----------------------------------------------------------
    // MATRIZ
    // -----------------------------------------------------------

    final int? matrizId = detalle.matrizIdServidor;

    if (matrizId == null || matrizId <= 0) {
      throw const FormatException(
        'La matriz todavía no tiene un identificador válido del servidor.',
      );
    }

    // -----------------------------------------------------------
    // ITEM
    // -----------------------------------------------------------

    if (detalle.item <= 0) {
      throw const FormatException('El número de ítem debe ser mayor que cero.');
    }

    // -----------------------------------------------------------
    // TAREA
    // -----------------------------------------------------------

    if (detalle.tarea.trim().isEmpty) {
      throw const FormatException('La tarea es obligatoria para sincronizar.');
    }

    // -----------------------------------------------------------
    // PELIGRO / CONSECUENCIA
    // -----------------------------------------------------------

    _requerirIdTexto(detalle.peligroId, 'peligro');

    _requerirIdTexto(detalle.consecuenciaId, 'consecuencia');

    // -----------------------------------------------------------
    // VALIDAR VALORES 1..5
    // -----------------------------------------------------------
    //
    // Aunque ya no los enviamos como IDs,
    // seguimos validando los valores de la matriz local.

    _validarEscala(detalle.frecuenciaInicial, 'probabilidad inicial');

    _validarEscala(detalle.severidadInicial, 'severidad inicial');

    // -----------------------------------------------------------
    // VALIDAR IDs REALES INICIALES
    // -----------------------------------------------------------

    _requerirIdCatalogo(detalle.probabilidadInicialId, 'probabilidad inicial');

    _requerirIdCatalogo(detalle.severidadInicialId, 'severidad inicial');

    // -----------------------------------------------------------
    // VALIDAR CÁLCULO INICIAL
    // -----------------------------------------------------------

    final int calculadoInicial =
        detalle.frecuenciaInicial * detalle.severidadInicial;

    if (detalle.valorRiesgoInicial != calculadoInicial) {
      throw FormatException(
        'El riesgo inicial almacenado no coincide con '
        'el cálculo esperado: '
        '${detalle.frecuenciaInicial} x '
        '${detalle.severidadInicial} = '
        '$calculadoInicial.',
      );
    }

    // -----------------------------------------------------------
    // EVALUACIÓN RESIDUAL
    // -----------------------------------------------------------

    final bool tieneProbabilidadResidual = detalle.frecuenciaResidual != null;

    final bool tieneSeveridadResidual = detalle.severidadResidual != null;

    if (tieneProbabilidadResidual != tieneSeveridadResidual) {
      throw const FormatException(
        'La evaluación residual debe tener probabilidad y severidad.',
      );
    }

    if (detalle.tieneEvaluacionResidual) {
      // ---------------------------------------------------------
      // VALIDAR VALORES RESIDUALES 1..5
      // ---------------------------------------------------------

      _validarEscala(detalle.frecuenciaResidual!, 'probabilidad residual');

      _validarEscala(detalle.severidadResidual!, 'severidad residual');

      // ---------------------------------------------------------
      // VALIDAR IDs REALES RESIDUALES
      // ---------------------------------------------------------

      _requerirIdCatalogo(
        detalle.probabilidadResidualId,
        'probabilidad residual',
      );

      _requerirIdCatalogo(detalle.severidadResidualId, 'severidad residual');

      // ---------------------------------------------------------
      // VALIDAR CÁLCULO RESIDUAL
      // ---------------------------------------------------------

      final int calculadoResidual =
          detalle.frecuenciaResidual! * detalle.severidadResidual!;

      final int? guardadoResidual = detalle.valorRiesgoResidual;

      if (guardadoResidual != null && guardadoResidual != calculadoResidual) {
        throw FormatException(
          'El riesgo residual almacenado no coincide con '
          'el cálculo esperado: '
          '${detalle.frecuenciaResidual} x '
          '${detalle.severidadResidual} = '
          '$calculadoResidual.',
        );
      }
    }
  }

  // =============================================================
  // VALIDAR ESCALA 1..5
  // =============================================================

  static int _validarEscala(int valor, String nombre) {
    if (valor < 1 || valor > 5) {
      throw FormatException('La $nombre debe estar entre 1 y 5.');
    }

    return valor;
  }

  // =============================================================
  // ID DE CATÁLOGO
  // =============================================================

  /// Valida un ID numérico real de catálogo.
  ///
  /// A diferencia del valor 1..5, un ID puede ser:
  ///
  /// 1, 5, 17, 28, etc.
  static int _requerirIdCatalogo(int? id, String nombre) {
    if (id == null || id <= 0) {
      throw FormatException('El identificador real de $nombre es obligatorio.');
    }

    return id;
  }

  // =============================================================
  // ID TEXTO OBLIGATORIO
  // =============================================================

  static int _requerirIdTexto(String? value, String nombre) {
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

  // =============================================================
  // ID TEXTO OPCIONAL
  // =============================================================

  static int? _idOpcionalTexto(String? value, {required String nombre}) {
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

  // =============================================================
  // LISTA DE IDS
  // =============================================================

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

  // =============================================================
  // ESTADO IMPLEMENTACIÓN
  // =============================================================

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

  // =============================================================
  // TEXTO OPCIONAL
  // =============================================================

  static String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
