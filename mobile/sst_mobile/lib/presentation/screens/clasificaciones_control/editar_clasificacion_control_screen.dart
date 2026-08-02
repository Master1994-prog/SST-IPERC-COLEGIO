import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/clasificacion_control_model.dart';
import '../../providers/clasificacion_control_provider.dart';

/// Pantalla utilizada para actualizar
/// una clasificación de control existente.
class EditarClasificacionControlScreen extends StatefulWidget {
  const EditarClasificacionControlScreen({
    required this.clasificacion,
    super.key,
  });

  /// Clasificación que será modificada.
  final ClasificacionControlModel clasificacion;

  @override
  State<EditarClasificacionControlScreen> createState() {
    return _EditarClasificacionControlScreenState();
  }
}

class _EditarClasificacionControlScreenState
    extends State<EditarClasificacionControlScreen> {
  /// Clave principal del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código.
  late final TextEditingController _codigoController;

  /// Controlador del nombre.
  late final TextEditingController _nombreController;

  /// Controlador de la descripción.
  late final TextEditingController _descripcionController;

  /// Controlador de la prioridad.
  late final TextEditingController _prioridadController;

  /// Estado activo de la clasificación.
  late bool _activo;

  /// Evita guardar varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(
      text: widget.clasificacion.codigo,
    );

    _nombreController = TextEditingController(
      text: widget.clasificacion.nombre,
    );

    _descripcionController = TextEditingController(
      text: widget.clasificacion.descripcion ?? '',
    );

    _prioridadController = TextEditingController(
      text: widget.clasificacion.prioridad.toString(),
    );

    _activo = widget.clasificacion.activo;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _prioridadController.dispose();

    super.dispose();
  }

  /// Valida y actualiza la clasificación.
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

    final ActualizarClasificacionControlRequest request =
        ActualizarClasificacionControlRequest(
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          prioridad: prioridad,
          activo: _activo,
        );

    final bool actualizado = await provider.actualizarClasificacion(
      widget.clasificacion.id,
      request,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (actualizado) {
      final NavigatorState navigator = Navigator.of(context);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Clasificación actualizada correctamente.'),
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
            provider.mensajeError ?? 'No se pudo actualizar la clasificación.',
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
    return _nombreController.text.trim() !=
            widget.clasificacion.nombre.trim() ||
        _descripcionController.text.trim() !=
            (widget.clasificacion.descripcion?.trim() ?? '') ||
        _prioridadController.text.trim() !=
            widget.clasificacion.prioridad.toString() ||
        _activo != widget.clasificacion.activo;
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
            'Hay cambios sin guardar. '
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
        appBar: AppBar(title: const Text('Editar clasificación')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoClasificacion(
                  codigo: widget.clasificacion.codigo,
                  nombre: widget.clasificacion.nombre,
                  prioridad: widget.clasificacion.prioridad,
                ),

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
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    helperText: 'El código no se edita para evitar duplicados.',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                    border: OutlineInputBorder(),
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
                        'Un número menor representa una prioridad mayor.',
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
                        ? 'Disponible en los formularios de controles.'
                        : 'No estará disponible para nuevos controles.',
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
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado con los datos actuales.
class _EncabezadoClasificacion extends StatelessWidget {
  const _EncabezadoClasificacion({
    required this.codigo,
    required this.nombre,
    required this.prioridad,
  });

  final String codigo;
  final String nombre;
  final int prioridad;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.tune_outlined,
              size: 30,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  codigo,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Prioridad $prioridad',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
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
              'Las clasificaciones activas podrán '
              'seleccionarse al registrar o editar controles.',
            ),
          ),
        ],
      ),
    );
  }
}
