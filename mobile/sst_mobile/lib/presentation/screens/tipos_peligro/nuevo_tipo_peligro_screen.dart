import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tipo_peligro_model.dart';
import '../../providers/tipo_peligro_provider.dart';

/// Pantalla para registrar un nuevo tipo de peligro.
class NuevoTipoPeligroScreen extends StatefulWidget {
  const NuevoTipoPeligroScreen({super.key});

  @override
  State<NuevoTipoPeligroScreen> createState() {
    return _NuevoTipoPeligroScreenState();
  }
}

class _NuevoTipoPeligroScreenState extends State<NuevoTipoPeligroScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController = TextEditingController();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  bool _activo = true;
  bool _guardando = false;

  late final String _codigoInicial;

  @override
  void initState() {
    super.initState();
    _codigoInicial = _generarCodigoCorrelativo();
    _codigoController.text = _codigoInicial;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  /// Genera el siguiente código disponible.
  ///
  /// Ejemplo: si ya existe TIP-001, el siguiente será TIP-002.
  String _generarCodigoCorrelativo() {
    final List<TipoPeligroModel> tipos = context
        .read<TipoPeligroProvider>()
        .tipos;

    int mayorNumero = 0;

    for (final TipoPeligroModel tipo in tipos) {
      final RegExpMatch? coincidencia = RegExp(
        r'^TIP-(\d+)$',
        caseSensitive: false,
      ).firstMatch(tipo.codigo.trim());

      if (coincidencia == null) {
        continue;
      }

      final int numero = int.tryParse(coincidencia.group(1) ?? '') ?? 0;

      if (numero > mayorNumero) {
        mayorNumero = numero;
      }
    }

    final int siguienteNumero = mayorNumero + 1;

    return 'TIP-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Registra el tipo de peligro.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    FocusScope.of(context).unfocus();

    final TipoPeligroProvider provider = context.read<TipoPeligroProvider>();

    setState(() {
      _guardando = true;
    });

    final CrearTipoPeligroRequest request = CrearTipoPeligroRequest(
      codigo: _codigoController.text.trim(),
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      activo: _activo,
    );

    final bool creado = await provider.crearTipo(request);

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
            content: Text('Tipo de peligro registrado correctamente.'),
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
            provider.mensajeError ?? 'No se pudo registrar el tipo de peligro.',
          ),
        ),
      );
  }

  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del tipo de peligro.';
    }

    if (texto.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }

    if (texto.length > 150) {
      return 'El nombre no puede superar los 150 caracteres.';
    }

    return null;
  }

  String? _validarDescripcion(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 1000) {
      return 'La descripción no puede superar los 1000 caracteres.';
    }

    return null;
  }

  bool _hayCambios() {
    return _codigoController.text.trim() != _codigoInicial ||
        _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        !_activo;
  }

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
        appBar: AppBar(title: const Text('Nuevo tipo de peligro')),
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
                  readOnly: true,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Código generado',
                    helperText:
                        'Se genera automáticamente según los tipos existentes.',
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
                    labelText: 'Nombre del tipo de peligro',
                    hintText: 'Ejemplo: Eléctrico',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
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
                        'Describe las características '
                        'de este tipo de peligro.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
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
                  title: const Text('Tipo de peligro activo'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible para seleccionar '
                              'en nuevos peligros.'
                        : 'No estará disponible para '
                              'nuevos registros.',
                  ),
                  secondary: Icon(
                    _activo
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                const SizedBox(height: 18),

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

/// Encabezado principal.
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
            Icons.warning_amber_outlined,
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
                'Información del tipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Registra una clasificación general '
                'para organizar los peligros SST.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta informativa.
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
              'Ejemplos de tipos de peligro: físico, '
              'químico, biológico, ergonómico, '
              'psicosocial, mecánico y eléctrico.',
            ),
          ),
        ],
      ),
    );
  }
}
