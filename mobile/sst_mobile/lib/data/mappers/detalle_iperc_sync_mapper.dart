import '../models/detalle_iperc_local_model.dart';
import '../models/detalle_iperc_model.dart';

/// Convierte un detalle IPERC almacenado en SQLite en solicitudes
/// compatibles con el backend.
///
/// También valida que el registro local contenga todos los identificadores
/// numéricos necesarios antes de intentar sincronizarlo.
abstract final class DetalleIpercSyncMapper {
  /// Convierte un registro local en una solicitud para crear el detalle.
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
      evaluacionInicialId: detalle.evaluacionInicialId!,
      evaluacionResidualId: detalle.evaluacionResidualId,
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

  /// Convierte un registro local en una solicitud para actualizarlo.
  static ActualizarDetalleIpercRequest toActualizarRequest(
    DetalleIpercLocalModel detalle,
  ) {
    _validarDetalleParaSincronizar(detalle);

    return ActualizarDetalleIpercRequest(
      matrizIpercId: detalle.matrizIdServidor!,
      item: detalle.item,
      tarea: detalle.tarea.trim(),
      peligroId: _requerirId(detalle.peligroId, 'peligro'),
      consecuenciaId: _requerirId(detalle.consecuenciaId, 'consecuencia'),
      descripcionPeligro: _textoOpcional(detalle.peligroDescripcion),
      evaluacionInicialId: detalle.evaluacionInicialId!,
      evaluacionResidualId: detalle.evaluacionResidualId,
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

  /// Devuelve el identificador remoto del detalle.
  ///
  /// Se usa para actualizar o eliminar un registro ya creado en el backend.
  static int obtenerIdServidor(DetalleIpercLocalModel detalle) {
    return _requerirId(detalle.idServidor, 'detalle IPERC del servidor');
  }

  /// Determina si el registro todavía no existe en el backend.
  static bool requiereCreacion(DetalleIpercLocalModel detalle) {
    final String id = detalle.idServidor?.trim() ?? '';

    return id.isEmpty || int.tryParse(id) == null || int.parse(id) <= 0;
  }

  /// Determina si el registro debe eliminarse en el backend.
  static bool requiereEliminacion(DetalleIpercLocalModel detalle) {
    return detalle.eliminado;
  }

  /// Valida la información mínima necesaria para crear o actualizar.
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

    if (detalle.evaluacionInicialId == null ||
        detalle.evaluacionInicialId! <= 0) {
      throw const FormatException(
        'No se pudo preparar la evaluación inicial para la sincronización.',
      );
    }

    final int? evaluacionResidualId = detalle.evaluacionResidualId;

    final bool tieneEvaluacionResidual =
        detalle.severidadResidual != null ||
        detalle.frecuenciaResidual != null ||
        detalle.valorRiesgoResidual != null;

    if (tieneEvaluacionResidual &&
        (evaluacionResidualId == null || evaluacionResidualId <= 0)) {
      throw const FormatException(
        'La evaluación residual todavía no tiene un identificador válido del servidor.',
      );
    }
  }

  /// Convierte un identificador textual local en entero.
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

  /// Convierte un identificador opcional.
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

  /// Convierte listas de identificadores almacenadas como String.
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

  /// Convierte el estado textual local al valor numérico del backend.
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
