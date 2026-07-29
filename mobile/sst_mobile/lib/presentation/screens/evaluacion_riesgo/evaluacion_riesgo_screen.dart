import 'package:flutter/material.dart';

import '../../../data/models/evaluacion_riesgo_model.dart';
import '../../../data/repositories/evaluacion_riesgo_repository.dart';

/// Pantalla autónoma para calcular y registrar una evaluación IPERC 5x5.
///
/// No depende de EvaluacionRiesgoProvider. De esta manera se evita el error
/// producido cuando la pantalla y el provider pertenecen a versiones distintas.
class EvaluacionRiesgoScreen extends StatefulWidget {
  const EvaluacionRiesgoScreen({super.key});

  static const String routeName = '/evaluacion-riesgo';

  @override
  State<EvaluacionRiesgoScreen> createState() =>
      _EvaluacionRiesgoScreenState();
}

class _EvaluacionRiesgoScreenState extends State<EvaluacionRiesgoScreen> {
  final EvaluacionRiesgoRepository _repository =
      EvaluacionRiesgoRepository();
  final TextEditingController _observacionesController =
      TextEditingController();

  _ProbabilidadOption? _probabilidadSeleccionada;
  _SeveridadOption? _severidadSeleccionada;
  bool _guardando = false;
  String? _error;

  int? get _valorCalculado {
    final _ProbabilidadOption? probabilidad = _probabilidadSeleccionada;
    final _SeveridadOption? severidad = _severidadSeleccionada;

    if (probabilidad == null || severidad == null) {
      return null;
    }

    return probabilidad.valor * severidad.valor;
  }

  _NivelRiesgoOption? get _nivelCalculado {
    final int? valor = _valorCalculado;

    if (valor == null) {
      return null;
    }

    return _nivelesRiesgo.firstWhere(
      (_NivelRiesgoOption nivel) => nivel.contiene(valor),
      orElse: () => _nivelesRiesgo.last,
    );
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final _ProbabilidadOption? probabilidad = _probabilidadSeleccionada;
    final _SeveridadOption? severidad = _severidadSeleccionada;
    final _NivelRiesgoOption? nivel = _nivelCalculado;

    if (probabilidad == null || severidad == null || nivel == null) {
      setState(() {
        _error = 'Selecciona la probabilidad y la severidad.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final CrearEvaluacionRiesgoRequest request =
          CrearEvaluacionRiesgoRequest(
        probabilidadId: probabilidad.id,
        severidadId: severidad.id,
        nivelRiesgoId: nivel.id,
        observaciones: _textoOpcional(_observacionesController.text),
      );

      final EvaluacionRiesgoModel evaluacion =
          await _repository.crear(request);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evaluación registrada correctamente. ID: ${evaluacion.id}',
          ),
        ),
      );

      _limpiar();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _mensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _limpiar() {
    _observacionesController.clear();

    setState(() {
      _probabilidadSeleccionada = null;
      _severidadSeleccionada = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int? valor = _valorCalculado;
    final _NivelRiesgoOption? nivel = _nivelCalculado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de riesgo'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Limpiar',
            onPressed: _guardando ? null : _limpiar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Matriz IPERC 5x5',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona la probabilidad y la severidad. '
            'El nivel de riesgo se calculará automáticamente.',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<_ProbabilidadOption>(
            initialValue: _probabilidadSeleccionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Probabilidad *',
              prefixIcon: Icon(Icons.timeline),
              border: OutlineInputBorder(),
            ),
            items: _probabilidades
                .map(
                  (_ProbabilidadOption opcion) =>
                      DropdownMenuItem<_ProbabilidadOption>(
                    value: opcion,
                    child: Text(opcion.etiqueta),
                  ),
                )
                .toList(),
            onChanged: _guardando
                ? null
                : (_ProbabilidadOption? value) {
                    setState(() {
                      _probabilidadSeleccionada = value;
                      _error = null;
                    });
                  },
          ),
          if (_probabilidadSeleccionada != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _probabilidadSeleccionada!.descripcion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<_SeveridadOption>(
            initialValue: _severidadSeleccionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Severidad *',
              prefixIcon: Icon(Icons.warning_amber_outlined),
              border: OutlineInputBorder(),
            ),
            items: _severidades
                .map(
                  (_SeveridadOption opcion) =>
                      DropdownMenuItem<_SeveridadOption>(
                    value: opcion,
                    child: Text(opcion.etiqueta),
                  ),
                )
                .toList(),
            onChanged: _guardando
                ? null
                : (_SeveridadOption? value) {
                    setState(() {
                      _severidadSeleccionada = value;
                      _error = null;
                    });
                  },
          ),
          if (_severidadSeleccionada != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _severidadSeleccionada!.descripcion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          if (valor != null && nivel != null)
            _ResultadoCard(valor: valor, nivel: nivel),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            _MensajeError(mensaje: _error!),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _observacionesController,
            enabled: !_guardando,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _guardando || nivel == null ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _guardando ? 'Guardando...' : 'Guardar evaluación',
            ),
          ),
        ],
      ),
    );
  }

  static String? _textoOpcional(String value) {
    final String texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  static String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({
    required this.valor,
    required this.nivel,
  });

  final int valor;
  final _NivelRiesgoOption nivel;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);
    final Color foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Text(
              'Resultado: $valor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nivel ${nivel.nombre}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              nivel.aceptable
                  ? 'Riesgo aceptable'
                  : 'Requiere medidas de control',
              style: TextStyle(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorDesdeHex(String hex) {
    final String limpio = hex.replaceAll('#', '');
    final int? valor = int.tryParse('FF$limpio', radix: 16);
    return Color(valor ?? 0xFF9E9E9E);
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilidadOption {
  const _ProbabilidadOption({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  final int id;
  final int valor;
  final String nombre;
  final String descripcion;

  String get etiqueta => '$valor - $nombre';
}

class _SeveridadOption {
  const _SeveridadOption({
    required this.id,
    required this.valor,
    required this.nombre,
    required this.descripcion,
  });

  final int id;
  final int valor;
  final String nombre;
  final String descripcion;

  String get etiqueta => '$valor - $nombre';
}

class _NivelRiesgoOption {
  const _NivelRiesgoOption({
    required this.id,
    required this.nombre,
    required this.desde,
    required this.hasta,
    required this.colorHex,
    required this.aceptable,
  });

  final int id;
  final String nombre;
  final int desde;
  final int hasta;
  final String colorHex;
  final bool aceptable;

  bool contiene(int valor) {
    return valor >= desde && valor <= hasta;
  }
}

const List<_ProbabilidadOption> _probabilidades = <_ProbabilidadOption>[
  _ProbabilidadOption(
    id: 1,
    valor: 1,
    nombre: 'Rara',
    descripcion: 'Puede ocurrir solo en circunstancias excepcionales.',
  ),
  _ProbabilidadOption(
    id: 2,
    valor: 2,
    nombre: 'Poco probable',
    descripcion: 'Podría ocurrir en algún momento.',
  ),
  _ProbabilidadOption(
    id: 3,
    valor: 3,
    nombre: 'Posible',
    descripcion: 'Puede ocurrir ocasionalmente.',
  ),
  _ProbabilidadOption(
    id: 4,
    valor: 4,
    nombre: 'Probable',
    descripcion: 'Puede ocurrir frecuentemente.',
  ),
  _ProbabilidadOption(
    id: 5,
    valor: 5,
    nombre: 'Muy probable',
    descripcion: 'Se espera que ocurra con frecuencia.',
  ),
];

const List<_SeveridadOption> _severidades = <_SeveridadOption>[
  _SeveridadOption(
    id: 1,
    valor: 1,
    nombre: 'Insignificante',
    descripcion: 'Evento leve sin pérdida de jornada.',
  ),
  _SeveridadOption(
    id: 2,
    valor: 2,
    nombre: 'Menor',
    descripcion: 'Evento menor con atención básica.',
  ),
  _SeveridadOption(
    id: 3,
    valor: 3,
    nombre: 'Moderada',
    descripcion: 'Evento con descanso médico o afectación moderada.',
  ),
  _SeveridadOption(
    id: 4,
    valor: 4,
    nombre: 'Mayor',
    descripcion: 'Evento grave o incapacidad temporal significativa.',
  ),
  _SeveridadOption(
    id: 5,
    valor: 5,
    nombre: 'Catastrófica',
    descripcion: 'Evento con consecuencia permanente o muy severa.',
  ),
];

const List<_NivelRiesgoOption> _nivelesRiesgo =
    <_NivelRiesgoOption>[
  _NivelRiesgoOption(
    id: 1,
    nombre: 'Bajo',
    desde: 1,
    hasta: 4,
    colorHex: '#4CAF50',
    aceptable: true,
  ),
  _NivelRiesgoOption(
    id: 2,
    nombre: 'Medio',
    desde: 5,
    hasta: 9,
    colorHex: '#FFC107',
    aceptable: true,
  ),
  _NivelRiesgoOption(
    id: 3,
    nombre: 'Alto',
    desde: 10,
    hasta: 16,
    colorHex: '#FF9800',
    aceptable: false,
  ),
  _NivelRiesgoOption(
    id: 4,
    nombre: 'Crítico',
    desde: 17,
    hasta: 25,
    colorHex: '#F44336',
    aceptable: false,
  ),
];
