import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tipo_equipo_proteccion_model.dart';
import '../../providers/tipo_equipo_proteccion_provider.dart';

/// Pantalla para actualizar un tipo de
/// Equipo de Protección Personal.
class EditarTipoEquipoProteccionScreen extends StatefulWidget {
  const EditarTipoEquipoProteccionScreen({super.key, required this.tipo});

  /// Tipo de EPP que será actualizado.
  final TipoEquipoProteccionModel tipo;

  @override
  State<EditarTipoEquipoProteccionScreen> createState() {
    return _EditarTipoEquipoProteccionScreenState();
  }
}

class _EditarTipoEquipoProteccionScreenState
    extends State<EditarTipoEquipoProteccionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _ordenController;
  late final TextEditingController _colegioIdController;

  late bool _activo;
  late bool _esGlobal;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(text: widget.tipo.codigo);

    _nombreController = TextEditingController(text: widget.tipo.nombre);

    _descripcionController = TextEditingController(
      text: widget.tipo.descripcion ?? '',
    );

    _ordenController = TextEditingController(
      text: widget.tipo.orden.toString(),
    );

    _colegioIdController = TextEditingController(
      text: widget.tipo.colegioId?.toString() ?? '',
    );

    _activo = widget.tipo.activo;
    _esGlobal = widget.tipo.esGlobal;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    _colegioIdController.dispose();

    super.dispose();
  }

  /// Valida y actualiza el registro.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final int? orden = int.tryParse(_ordenController.text.trim());

    if (orden == null || orden < 0) {
      return;
    }

    final int? colegioId = _esGlobal
        ? null
        : int.tryParse(_colegioIdController.text.trim());

    if (!_esGlobal && (colegioId == null || colegioId <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un colegio propietario válido.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final TipoEquipoProteccionProvider provider = context
        .read<TipoEquipoProteccionProvider>();

    setState(() {
      _guardando = true;
    });

    final ActualizarTipoEquipoProteccionRequest request =
        ActualizarTipoEquipoProteccionRequest(
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          orden: orden,
          activo: _activo,
          esGlobal: _esGlobal,
          colegioId: colegioId,
        );

    final bool actualizado = await provider.actualizarTipo(
      widget.tipo.id,
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
            content: Text('Tipo de EPP actualizado correctamente.'),
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
            provider.mensajeError ?? 'No se pudo actualizar el tipo de EPP.',
          ),
        ),
      );
  }

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
      return 'Utiliza letras, números, guiones o guion bajo.';
    }

    return null;
  }

  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del tipo de EPP.';
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

  String? _validarOrden(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el orden.';
    }

    final int? orden = int.tryParse(texto);

    if (orden == null) {
      return 'El orden debe ser un número entero.';
    }

    if (orden < 0) {
      return 'El orden no puede ser negativo.';
    }

    return null;
  }

  String? _validarColegio(String? valor) {
    if (_esGlobal) {
      return null;
    }

    final int? colegioId = int.tryParse(valor?.trim() ?? '');

    if (colegioId == null || colegioId <= 0) {
      return 'Ingresa un colegio válido.';
    }

    return null;
  }

  /// Comprueba si existen modificaciones.
  bool _hayCambios() {
    return _codigoController.text.trim() != widget.tipo.codigo.trim() ||
        _nombreController.text.trim() != widget.tipo.nombre.trim() ||
        _descripcionController.text.trim() !=
            (widget.tipo.descripcion?.trim() ?? '') ||
        _ordenController.text.trim() != widget.tipo.orden.toString() ||
        _activo != widget.tipo.activo ||
        _esGlobal != widget.tipo.esGlobal ||
        _colegioIdController.text.trim() !=
            (widget.tipo.colegioId?.toString() ?? '');
  }

  /// Confirma la salida cuando existen cambios.
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
        appBar: AppBar(title: const Text('Editar tipo de EPP')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoTipo(
                  codigo: widget.tipo.codigo,
                  nombre: widget.tipo.nombre,
                ),

                const SizedBox(height: 22),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
                  textCapitalization: TextCapitalization.characters,
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
                  maxLength: 150,
                  validator: _validarNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ejemplo: Protección corporal',
                    prefixIcon: Icon(Icons.category_outlined),
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
                    hintText: 'Describe los equipos incluidos en este tipo.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _ordenController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.number,
                  validator: _validarOrden,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    hintText: 'Ejemplo: 1',
                    prefixIcon: Icon(Icons.format_list_numbered),
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
                  title: const Text('Tipo activo'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible en los formularios de EPP.'
                        : 'No estará disponible para nuevos registros.',
                  ),
                  secondary: Icon(
                    _activo
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                SwitchListTile(
                  value: _esGlobal,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _esGlobal = valor;

                            if (valor) {
                              _colegioIdController.clear();
                            }
                          });
                        },
                  title: const Text('Catálogo global'),
                  subtitle: Text(
                    _esGlobal
                        ? 'Disponible para todos los colegios.'
                        : 'Pertenecerá solamente a un colegio.',
                  ),
                  secondary: Icon(
                    _esGlobal ? Icons.public : Icons.school_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                if (!_esGlobal) ...<Widget>[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _colegioIdController,
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    validator: _validarColegio,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'ID del colegio',
                      hintText: 'Identificador del colegio propietario',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

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
class _EncabezadoTipo extends StatelessWidget {
  const _EncabezadoTipo({required this.codigo, required this.nombre});

  final String codigo;
  final String nombre;

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
              Icons.category_outlined,
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
              'El estado activo controla si el tipo '
              'puede seleccionarse en los formularios '
              'de equipos de protección.',
            ),
          ),
        ],
      ),
    );
  }
}
