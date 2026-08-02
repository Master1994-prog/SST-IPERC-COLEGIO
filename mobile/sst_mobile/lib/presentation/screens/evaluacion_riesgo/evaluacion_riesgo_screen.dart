import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/evaluacion_riesgo_model.dart';
import '../../providers/evaluacion_riesgo_provider.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';

/// Pantalla para calcular y registrar una evaluación de riesgo IPERC 5×5.
class EvaluacionRiesgoScreen extends StatelessWidget {
  const EvaluacionRiesgoScreen({super.key});

  static const String routeName = '/evaluacion-riesgo';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EvaluacionRiesgoProvider>(
      create: (_) {
        return EvaluacionRiesgoProvider()..cargarDatosIniciales();
      },
      child: const _EvaluacionRiesgoView(),
    );
  }
}

/// Vista principal de la evaluación.
class _EvaluacionRiesgoView extends StatefulWidget {
  const _EvaluacionRiesgoView();

  @override
  State<_EvaluacionRiesgoView> createState() {
    return _EvaluacionRiesgoViewState();
  }
}

class _EvaluacionRiesgoViewState extends State<_EvaluacionRiesgoView> {
  final TextEditingController _observacionesController =
      TextEditingController();

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  /// Envía la evaluación seleccionada al backend.
  Future<void> _guardar(EvaluacionRiesgoProvider provider) async {
    final EvaluacionRiesgoModel? evaluacion = await provider.guardarEvaluacion(
      observaciones: _observacionesController.text,
    );

    if (!mounted) {
      return;
    }

    if (evaluacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo guardar la evaluación.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evaluación de riesgo registrada correctamente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Limpia todos los campos del formulario.
  void _limpiar(EvaluacionRiesgoProvider provider) {
    _observacionesController.clear();
    provider.limpiarFormulario();
  }

  /// Abre la tabla visual de la matriz 5×5.
  void _abrirMatriz() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MatrizRiesgoScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EvaluacionRiesgoProvider>(
      builder:
          (
            BuildContext context,
            EvaluacionRiesgoProvider provider,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Evaluación de riesgo 5×5'),
                actions: <Widget>[
                  IconButton(
                    tooltip: 'Ver matriz 5×5',
                    onPressed: provider.guardando ? null : _abrirMatriz,
                    icon: const Icon(Icons.grid_on_outlined),
                  ),
                  IconButton(
                    tooltip: 'Limpiar formulario',
                    onPressed: provider.guardando
                        ? null
                        : () => _limpiar(provider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              body: SafeArea(
                child: provider.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _FormularioEvaluacion(
                        provider: provider,
                        observacionesController: _observacionesController,
                        onGuardar: () => _guardar(provider),
                      ),
              ),
            );
          },
    );
  }
}

/// Formulario de selección de probabilidad y severidad.
class _FormularioEvaluacion extends StatelessWidget {
  const _FormularioEvaluacion({
    required this.provider,
    required this.observacionesController,
    required this.onGuardar,
  });

  final EvaluacionRiesgoProvider provider;
  final TextEditingController observacionesController;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final ResultadoRiesgoCalculado? resultado = provider.resultadoCalculado;

    return ListView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        Text(
          'Matriz IPERC 5×5',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Selecciona la probabilidad y la severidad. '
          'El valor y el nivel de riesgo se calcularán '
          'automáticamente.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Selección de probabilidad.
        DropdownButtonFormField<ProbabilidadIpercOption>(
          initialValue: provider.probabilidadSeleccionada,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Probabilidad *',
            hintText: 'Selecciona una probabilidad',
            prefixIcon: Icon(Icons.timeline),
            border: OutlineInputBorder(),
          ),
          items: provider.probabilidades.map((ProbabilidadIpercOption opcion) {
            return DropdownMenuItem<ProbabilidadIpercOption>(
              value: opcion,
              child: Text(opcion.etiqueta, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: provider.guardando
              ? null
              : provider.seleccionarProbabilidad,
        ),

        if (provider.probabilidadSeleccionada != null) ...[
          const SizedBox(height: 8),
          _DescripcionSeleccion(
            icono: Icons.info_outline,
            descripcion: provider.probabilidadSeleccionada!.descripcion,
          ),
        ],

        const SizedBox(height: 18),

        // Selección de severidad.
        DropdownButtonFormField<SeveridadIpercOption>(
          initialValue: provider.severidadSeleccionada,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Severidad *',
            hintText: 'Selecciona una severidad',
            prefixIcon: Icon(Icons.warning_amber_outlined),
            border: OutlineInputBorder(),
          ),
          items: provider.severidades.map((SeveridadIpercOption opcion) {
            return DropdownMenuItem<SeveridadIpercOption>(
              value: opcion,
              child: Text(opcion.etiqueta, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: provider.guardando ? null : provider.seleccionarSeveridad,
        ),

        if (provider.severidadSeleccionada != null) ...[
          const SizedBox(height: 8),
          _DescripcionSeleccion(
            icono: Icons.info_outline,
            descripcion: provider.severidadSeleccionada!.descripcion,
          ),
        ],

        const SizedBox(height: 20),

        // Resultado calculado automáticamente.
        if (resultado != null) _ResultadoCard(resultado: resultado),

        // Mensaje de error del provider.
        if (provider.error != null) ...[
          const SizedBox(height: 16),
          _MensajeError(mensaje: provider.error!),
        ],

        const SizedBox(height: 18),

        // Observaciones opcionales.
        TextField(
          controller: observacionesController,
          enabled: !provider.guardando,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Ingresa observaciones adicionales',
            prefixIcon: Icon(Icons.notes),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 8),

        // Botón para registrar la evaluación.
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: provider.guardando || resultado == null
                ? null
                : onGuardar,
            icon: provider.guardando
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              provider.guardando ? 'Guardando...' : 'Guardar evaluación',
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// Muestra la descripción de una opción seleccionada.
class _DescripcionSeleccion extends StatelessWidget {
  const _DescripcionSeleccion({required this.icono, required this.descripcion});

  final IconData icono;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descripcion,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que presenta el resultado calculado.
class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.resultado});

  final ResultadoRiesgoCalculado resultado;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(resultado.nivel.colorHex);

    final Brightness brightness = ThemeData.estimateBrightnessForColor(color);

    final Color foreground = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Icon(
              _obtenerIcono(resultado.nivel.nombre),
              size: 38,
              color: foreground,
            ),
            const SizedBox(height: 8),
            Text(
              'Resultado: ${resultado.valor}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nivel ${resultado.nivel.nombre}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${resultado.probabilidad.valor} × '
              '${resultado.severidad.valor} = '
              '${resultado.valor}',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              resultado.nivel.aceptable
                  ? 'Riesgo aceptable'
                  : 'Requiere medidas de control',
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _obtenerIcono(String nivel) {
    final String texto = nivel.toLowerCase();

    if (texto.contains('bajo')) {
      return Icons.check_circle_outline;
    }

    if (texto.contains('medio')) {
      return Icons.info_outline;
    }

    if (texto.contains('alto')) {
      return Icons.warning_amber_outlined;
    }

    return Icons.dangerous_outlined;
  }

  static Color _colorDesdeHex(String hex) {
    String limpio = hex.replaceAll('#', '').trim();

    if (limpio.length == 6) {
      limpio = 'FF$limpio';
    }

    final int? valor = int.tryParse(limpio, radix: 16);

    return Color(valor ?? 0xFF9E9E9E);
  }
}

/// Presenta un mensaje de error dentro del formulario.
class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
