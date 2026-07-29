import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/clasificacion_control_model.dart';
import '../../providers/clasificacion_control_provider.dart';

/// Pantalla utilizada para registrar una nueva
/// clasificación de control.
class NuevaClasificacionControlScreen extends StatefulWidget {
  const NuevaClasificacionControlScreen({super.key});

  @override
  State<NuevaClasificacionControlScreen> createState() {
    return _NuevaClasificacionControlScreenState();
  }
}

class _NuevaClasificacionControlScreenState
    extends State<NuevaClasificacionControlScreen> {
  /// Clave principal del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código.
  final TextEditingController _codigoController = TextEditingController();

  /// Controlador del nombre.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador de la descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Controlador de la prioridad.
  final TextEditingController _prioridadController = TextEditingController(
    text: '1',
  );

  /// Estado inicial de la clasificación.
  bool _activo = true;

  /// Evita guardar varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController.text = _generarCodigoCorrelativo();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _prioridadController.dispose();

    super.dispose();
  }

  /// Genera el siguiente código disponible.
  String _generarCodigoCorrelativo() {
    final ClasificacionControlProvider provider = context
        .read<ClasificacionControlProvider>();

    int mayorNumero = 0;
    final RegExp formato = RegExp(r'^CC-(\d+)$', caseSensitive: false);

    for (final ClasificacionControlModel clasificacion
        in provider.clasificaciones) {
      final RegExpMatch? coincidencia = formato.firstMatch(
        clasificacion.codigo.trim(),
      );

      if (coincidencia == null) {
        continue;
      }

      final int numero = int.tryParse(coincidencia.group(1) ?? '') ?? 0;

      if (numero > mayorNumero) {
        mayorNumero = numero;
      }
    }

    final int siguienteNumero = mayorNumero + 1;

    return 'CC-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Valida y registra la nueva clasificación.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final int? prioridad = int.tryParse(_prioridadController.text.trim());

    if (prioridad == null || prioridad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La prioridad ingresada no es válida.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final ClasificacionControlProvider provider = context
        .read<ClasificacionControlProvider>();

    setState(() {
      _guardando = true;
    });

    final CrearClasificacionControlRequest request =
        CrearClasificacionControlRequest(
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          prioridad: prioridad,
          activo: _activo,
        );

    final bool creado = await provider.crearClasificacion(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (creado) {
      final NavigatorState navigator = Navigator.of(context);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Clasificación registrada correctamente.'),
          ),
        );

      navigator.pop(true);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            provider.mensajeError ?? 'No se pudo registrar la clasificación.',
          ),
        ),
      );
  }

  /// Valida el código.
  String? _validarCodigo(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el código.';
    }

    if (texto.length > 20) {
      return 'El código no puede superar los 20 caracteres.';
    }

    final RegExp formato = RegExp(r'^[A-Za-z0-9\-_]+$');

    if (!formato.hasMatch(texto)) {
      return 'Usa letras, números, guiones o guion bajo.';
    }

    return null;
  }

  /// Valida el nombre.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre de la clasificación.';
    }

    if (texto.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }

    if (texto.length > 150) {
      return 'El nombre no puede superar los 150 caracteres.';
    }

    return null;
  }

  /// Valida la descripción.
  String? _validarDescripcion(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 1000) {
      return 'La descripción no puede superar los 1000 caracteres.';
    }

    return null;
  }

  /// Valida la prioridad.
  String? _validarPrioridad(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa la prioridad.';
    }

    final int? prioridad = int.tryParse(texto);

    if (prioridad == null) {
      return 'La prioridad debe ser un número entero.';
    }

    if (prioridad < 0) {
      return 'La prioridad no puede ser negativa.';
    }

    return null;
  }

  /// Determina si existen cambios sin guardar.
  bool _hayCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _prioridadController.text.trim() != '1' ||
        !_activo;
  }

  /// Solicita confirmación antes de salir.
  Future<bool> _confirmarSalida() async {
    if (!_hayCambios()) {
      return true;
    }

    final bool? salir = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Descartar cambios'),
          content: const Text(
            'Hay información sin guardar. '
            '¿Deseas salir de todas formas?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        final NavigatorState navigator = Navigator.of(context);

        final bool salir = await _confirmarSalida();

        if (!mounted || !salir) {
          return;
        }

        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nueva clasificación')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                const _EncabezadoFormulario(),

                const SizedBox(height: 22),

                TextFormField(
                  controller: _codigoController,
                  enabled: !_guardando,
                  readOnly: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 20,
                  validator: _validarCodigo,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\-_]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Código generado',
                    helperText: 'El código se genera automáticamente.',
                    prefixIcon: const Icon(Icons.qr_code_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Generar código',
                      onPressed: _guardando
                          ? null
                          : () {
                              setState(() {
                                _codigoController.text =
                                    _generarCodigoCorrelativo();
                              });
                            },
                      icon: const Icon(Icons.autorenew),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _nombreController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: _validarNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ejemplo: Control de ingeniería',
                    prefixIcon: Icon(Icons.tune_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _descripcionController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  validator: _validarDescripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Describe los controles incluidos '
                        'en esta clasificación.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _prioridadController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: _validarPrioridad,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    hintText: 'Ejemplo: 1',
                    helperText:
                        'Un número menor representa '
                        'una prioridad mayor.',
                    prefixIcon: Icon(Icons.low_priority_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                SwitchListTile(
                  value: _activo,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _activo = valor;
                          });
                        },
                  title: const Text('Clasificación activa'),
                  subtitle: Text(
                    _activo
                        ? 'Estará disponible en los formularios de controles.'
                        : 'No podrá seleccionarse en nuevos controles.',
                  ),
                  secondary: Icon(
                    _activo
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                const SizedBox(height: 20),

                const _InformacionCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () async {
                          final NavigatorState navigator = Navigator.of(
                            context,
                          );

                          final bool salir = await _confirmarSalida();

                          if (!mounted || !salir) {
                            return;
                          }

                          navigator.pop();
                        },
                  child: const Text('Cancelar'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado principal del formulario.
class _EncabezadoFormulario extends StatelessWidget {
  const _EncabezadoFormulario();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.tune_outlined,
            color: colorScheme.onPrimaryContainer,
            size: 29,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Información de la clasificación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Registra una categoría de la '
                'jerarquía de controles SST.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta informativa del formulario.
class _InformacionCard extends StatelessWidget {
  const _InformacionCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'La prioridad organiza la jerarquía de '
              'controles. Por ejemplo: eliminación 1, '
              'sustitución 2 y controles de ingeniería 3.',
            ),
          ),
        ],
      ),
    );
  }
}
