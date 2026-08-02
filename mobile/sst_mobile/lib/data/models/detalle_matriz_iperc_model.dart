/// Representa un detalle evaluado dentro de una Matriz IPERC.
///
/// Incluye la actividad, tarea, peligro, consecuencia, evaluación
/// de riesgo, controles y seguimiento.
class DetalleMatrizIpercModel {
  const DetalleMatrizIpercModel({
    required this.id,
    required this.matrizIpercId,
    required this.item,
    required this.actividad,
    required this.tarea,
    required this.peligro,
    required this.consecuencia,
    required this.probabilidad,
    required this.valorProbabilidad,
    required this.severidad,
    required this.valorSeveridad,
    required this.valorRiesgo,
    required this.nivelRiesgo,
    required this.colorNivel,
    required this.aceptable,
    required this.controles,
    required this.equiposProteccion,
    required this.medidasControl,
    required this.responsable,
    required this.estado,
    required this.observaciones,
    required this.fechaEvaluacion,
  });

  /// Identificador del detalle IPERC.
  final String id;

  /// Identificador de la matriz a la que pertenece.
  final String matrizIpercId;

  /// Número de orden dentro de la matriz.
  final int item;

  /// Actividad evaluada.
  final String actividad;

  /// Tarea específica evaluada.
  final String tarea;

  /// Peligro identificado.
  final String peligro;

  /// Consecuencia relacionada con el peligro.
  final String consecuencia;

  /// Nombre de la probabilidad.
  final String probabilidad;

  /// Valor numérico de la probabilidad.
  final int valorProbabilidad;

  /// Nombre de la severidad.
  final String severidad;

  /// Valor numérico de la severidad.
  final int valorSeveridad;

  /// Resultado de probabilidad por severidad.
  final int valorRiesgo;

  /// Nombre del nivel de riesgo.
  final String nivelRiesgo;

  /// Color hexadecimal del nivel de riesgo.
  final String colorNivel;

  /// Indica si el nivel de riesgo es aceptable.
  final bool aceptable;

  /// Controles registrados para reducir el riesgo.
  final List<String> controles;

  /// Equipos de protección personal asignados.
  final List<String> equiposProteccion;

  /// Medidas adicionales propuestas.
  final String medidasControl;

  /// Persona responsable de aplicar las medidas.
  final String responsable;

  /// Estado del detalle o de su seguimiento.
  final String estado;

  /// Observaciones de la evaluación.
  final String observaciones;

  /// Fecha en la que se realizó la evaluación.
  final DateTime? fechaEvaluacion;

  /// Crea el modelo utilizando la respuesta del backend.
  factory DetalleMatrizIpercModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> evaluacion = _convertirMapa(
      _primerValor(<dynamic>[json['evaluacionRiesgo'], json['evaluacion']]),
    );

    final Map<String, dynamic> probabilidad = _convertirMapa(
      _primerValor(<dynamic>[evaluacion['probabilidad'], json['probabilidad']]),
    );

    final Map<String, dynamic> severidad = _convertirMapa(
      _primerValor(<dynamic>[evaluacion['severidad'], json['severidad']]),
    );

    final Map<String, dynamic> nivel = _convertirMapa(
      _primerValor(<dynamic>[
        evaluacion['nivelRiesgo'],
        json['nivelRiesgo'],
        json['nivel'],
      ]),
    );

    final Map<String, dynamic> peligro = _convertirMapa(json['peligro']);

    final Map<String, dynamic> consecuencia = _convertirMapa(
      json['consecuencia'],
    );

    final Map<String, dynamic> actividad = _convertirMapa(json['actividad']);

    final int valorProbabilidad = _convertirEntero(
      _primerValor(<dynamic>[
        evaluacion['valorProbabilidad'],
        evaluacion['probabilidadValor'],
        probabilidad['valor'],
        json['valorProbabilidad'],
      ]),
    );

    final int valorSeveridad = _convertirEntero(
      _primerValor(<dynamic>[
        evaluacion['valorSeveridad'],
        evaluacion['severidadValor'],
        severidad['valor'],
        json['valorSeveridad'],
      ]),
    );

    final int valorRiesgoRecibido = _convertirEntero(
      _primerValor(<dynamic>[
        evaluacion['valor'],
        evaluacion['valorRiesgo'],
        json['valorRiesgo'],
        json['valor'],
      ]),
    );

    final int valorCalculado = valorProbabilidad * valorSeveridad;

    return DetalleMatrizIpercModel(
      id: _convertirTexto(json['id']),
      matrizIpercId: _convertirTexto(
        _primerValor(<dynamic>[
          json['matrizIpercId'],
          json['matrizIPERCId'],
          json['matrizId'],
        ]),
      ),
      item: _convertirEntero(json['item']),
      actividad: _convertirTexto(
        _primerValor(<dynamic>[
          json['actividadNombre'],
          actividad['nombre'],
          json['actividad'],
        ]),
        valorPorDefecto: 'Sin actividad',
      ),
      tarea: _convertirTexto(
        _primerValor(<dynamic>[json['tarea'], json['descripcionTarea']]),
        valorPorDefecto: 'Sin tarea',
      ),
      peligro: _convertirTexto(
        _primerValor(<dynamic>[
          json['peligroNombre'],
          peligro['nombre'],
          json['peligro'],
        ]),
        valorPorDefecto: 'Sin peligro',
      ),
      consecuencia: _convertirTexto(
        _primerValor(<dynamic>[
          json['consecuenciaNombre'],
          consecuencia['nombre'],
          json['consecuencia'],
        ]),
        valorPorDefecto: 'Sin consecuencia',
      ),
      probabilidad: _convertirTexto(
        _primerValor(<dynamic>[
          evaluacion['probabilidadNombre'],
          probabilidad['nombre'],
          json['probabilidadNombre'],
        ]),
        valorPorDefecto: 'No evaluada',
      ),
      valorProbabilidad: valorProbabilidad,
      severidad: _convertirTexto(
        _primerValor(<dynamic>[
          evaluacion['severidadNombre'],
          severidad['nombre'],
          json['severidadNombre'],
        ]),
        valorPorDefecto: 'No evaluada',
      ),
      valorSeveridad: valorSeveridad,
      valorRiesgo: valorRiesgoRecibido > 0
          ? valorRiesgoRecibido
          : valorCalculado,
      nivelRiesgo: _convertirTexto(
        _primerValor(<dynamic>[
          evaluacion['nivelRiesgoNombre'],
          nivel['nombre'],
          json['nivelRiesgoNombre'],
        ]),
        valorPorDefecto: 'Sin nivel',
      ),
      colorNivel: _normalizarColor(
        _convertirTexto(
          _primerValor(<dynamic>[
            evaluacion['color'],
            nivel['color'],
            nivel['colorHex'],
            json['colorNivel'],
          ]),
          valorPorDefecto: '#9E9E9E',
        ),
      ),
      aceptable: _convertirBooleano(
        _primerValor(<dynamic>[
          evaluacion['aceptable'],
          nivel['aceptable'],
          json['aceptable'],
        ]),
      ),
      controles: _convertirListaNombres(
        _primerValor(<dynamic>[
          json['controles'],
          json['detalleIpercControles'],
          json['detalleIPERCControles'],
        ]),
      ),
      equiposProteccion: _convertirListaNombres(
        _primerValor(<dynamic>[
          json['equiposProteccion'],
          json['equiposProteccionPersonal'],
          json['epp'],
          json['detalleIpercEpp'],
          json['detalleIPERCEPP'],
        ]),
      ),
      medidasControl: _convertirTexto(
        _primerValor(<dynamic>[
          json['medidasControl'],
          json['medidasDeControl'],
          json['controlPropuesto'],
        ]),
      ),
      responsable: _convertirTexto(
        _primerValor(<dynamic>[json['responsable'], json['responsableNombre']]),
        valorPorDefecto: 'Sin responsable',
      ),
      estado: _convertirTexto(
        _primerValor(<dynamic>[
          json['estadoSeguimiento'],
          json['estadoAvance'],
          json['estado'],
        ]),
        valorPorDefecto: 'Pendiente',
      ),
      observaciones: _convertirTexto(
        _primerValor(<dynamic>[
          evaluacion['observaciones'],
          json['observaciones'],
        ]),
      ),
      fechaEvaluacion: _convertirFecha(
        _primerValor(<dynamic>[
          evaluacion['fechaEvaluacion'],
          evaluacion['fechaRegistro'],
          json['fechaEvaluacion'],
          json['fechaRegistro'],
        ]),
      ),
    );
  }

  /// Devuelve el cálculo completo en formato legible.
  String get calculoRiesgo {
    return '$valorProbabilidad × $valorSeveridad = $valorRiesgo';
  }

  /// Devuelve una descripción corta para mostrar en una lista.
  String get descripcionResumen {
    return '$peligro — Riesgo $nivelRiesgo ($valorRiesgo)';
  }

  /// Indica si existen medidas de control registradas.
  bool get tieneControles {
    return controles.isNotEmpty || medidasControl.trim().isNotEmpty;
  }

  /// Indica si existen equipos de protección registrados.
  bool get tieneEquiposProteccion {
    return equiposProteccion.isNotEmpty;
  }

  /// Convierte el modelo a un mapa local.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'matrizIpercId': matrizIpercId,
      'item': item,
      'actividad': actividad,
      'tarea': tarea,
      'peligro': peligro,
      'consecuencia': consecuencia,
      'probabilidad': probabilidad,
      'valorProbabilidad': valorProbabilidad,
      'severidad': severidad,
      'valorSeveridad': valorSeveridad,
      'valorRiesgo': valorRiesgo,
      'nivelRiesgo': nivelRiesgo,
      'colorNivel': colorNivel,
      'aceptable': aceptable,
      'controles': controles,
      'equiposProteccion': equiposProteccion,
      'medidasControl': medidasControl,
      'responsable': responsable,
      'estado': estado,
      'observaciones': observaciones,
      'fechaEvaluacion': fechaEvaluacion?.toIso8601String(),
    };
  }
}

/// Convierte un valor dinámico en un mapa seguro.
Map<String, dynamic> _convertirMapa(dynamic valor) {
  if (valor is Map<String, dynamic>) {
    return valor;
  }

  if (valor is Map) {
    return Map<String, dynamic>.from(valor);
  }

  return <String, dynamic>{};
}

/// Retorna el primer valor que no sea nulo.
dynamic _primerValor(List<dynamic> valores) {
  for (final dynamic valor in valores) {
    if (valor != null) {
      return valor;
    }
  }

  return null;
}

/// Convierte un valor dinámico en texto.
String _convertirTexto(dynamic valor, {String valorPorDefecto = ''}) {
  if (valor == null) {
    return valorPorDefecto;
  }

  if (valor is Map) {
    final dynamic nombre = valor['nombre'];

    if (nombre != null) {
      return nombre.toString().trim();
    }

    return valorPorDefecto;
  }

  final String texto = valor.toString().trim();

  return texto.isEmpty ? valorPorDefecto : texto;
}

/// Convierte un valor dinámico en entero.
int _convertirEntero(dynamic valor) {
  if (valor is int) {
    return valor;
  }

  if (valor is num) {
    return valor.toInt();
  }

  return int.tryParse(valor?.toString() ?? '') ?? 0;
}

/// Convierte un valor dinámico en booleano.
bool _convertirBooleano(dynamic valor) {
  if (valor is bool) {
    return valor;
  }

  if (valor is num) {
    return valor != 0;
  }

  final String texto = valor?.toString().trim().toLowerCase() ?? '';

  return texto == 'true' || texto == '1' || texto == 'si' || texto == 'sí';
}

/// Convierte un valor dinámico en fecha.
DateTime? _convertirFecha(dynamic valor) {
  if (valor is DateTime) {
    return valor;
  }

  return DateTime.tryParse(valor?.toString() ?? '');
}

/// Obtiene los nombres contenidos en una lista recibida desde la API.
List<String> _convertirListaNombres(dynamic valor) {
  if (valor is! List) {
    return <String>[];
  }

  return valor
      .map<String>((dynamic elemento) {
        if (elemento is String) {
          return elemento.trim();
        }

        final Map<String, dynamic> mapa = _convertirMapa(elemento);

        final Map<String, dynamic> control = _convertirMapa(
          _primerValor(<dynamic>[
            mapa['control'],
            mapa['equipoProteccion'],
            mapa['epp'],
          ]),
        );

        return _convertirTexto(
          _primerValor(<dynamic>[
            mapa['nombre'],
            mapa['controlNombre'],
            mapa['equipoProteccionNombre'],
            control['nombre'],
          ]),
        );
      })
      .where((String nombre) => nombre.isNotEmpty)
      .toList();
}

/// Asegura que el color hexadecimal comience con #.
String _normalizarColor(String color) {
  final String valor = color.trim();

  if (valor.isEmpty) {
    return '#9E9E9E';
  }

  return valor.startsWith('#') ? valor : '#$valor';
}
