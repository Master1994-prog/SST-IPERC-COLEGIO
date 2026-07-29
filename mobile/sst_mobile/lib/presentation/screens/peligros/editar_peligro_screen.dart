import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/peligro_model.dart';
import '../../../data/models/tipo_peligro_model.dart';
import '../../providers/peligro_provider.dart';
import '../../providers/tipo_peligro_provider.dart';

/// Pantalla para editar un peligro SST existente.
class EditarPeligroScreen extends StatefulWidget {
  const EditarPeligroScreen({
    required this.peligro,
    required this.usuarioActualizacionId,
    super.key,
  });

  /// Peligro que será actualizado.
  final PeligroModel peligro;

  /// Se conserva temporalmente para no romper
  /// la navegación actual desde PeligrosScreen.
  ///
  /// El DTO actual del backend no utiliza este dato.
  final int usuarioActualizacionId;

  @override
  State<EditarPeligroScreen> createState() {
    return _EditarPeligroScreenState();
  }
}

class _EditarPeligroScreenState extends State<EditarPeligroScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _fuenteController;
  late final TextEditingController _medioController;
  late final TextEditingController _receptorController;
  late final TextEditingController _requisitoLegalController;
  late final TextEditingController _recomendacionesController;

  late int? _tipoPeligroId;
  late bool _activo;

  bool _guardando = false;
  bool _cargandoTipos = true;

  String? _errorTipos;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(text: widget.peligro.codigo);

    _nombreController = TextEditingController(text: widget.peligro.nombre);

    _descripcionController = TextEditingController(
      text: widget.peligro.descripcion ?? '',
    );

    _fuenteController = TextEditingController(
      text: widget.peligro.fuente ?? '',
    );

    _medioController = TextEditingController(text: widget.peligro.medio ?? '');

    _receptorController = TextEditingController(
      text: widget.peligro.receptor ?? '',
    );

    _requisitoLegalController = TextEditingController(
      text: widget.peligro.requisitoLegal ?? '',
    );

    _recomendacionesController = TextEditingController(
      text: widget.peligro.recomendaciones ?? '',
    );

    _tipoPeligroId = widget.peligro.tipoPeligroId;
    _activo = widget.peligro.activo;

    Future<void>.microtask(_cargarTiposPeligro);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _fuenteController.dispose();
    _medioController.dispose();
    _receptorController.dispose();
    _requisitoLegalController.dispose();
    _recomendacionesController.dispose();

    super.dispose();
  }

  /// Carga los tipos de peligro activos.
  Future<void> _cargarTiposPeligro() async {
    final TipoPeligroProvider provider = context.read<TipoPeligroProvider>();

    setState(() {
      _cargandoTipos = true;
      _errorTipos = null;
    });

    await provider.cargarTiposActivos();

    if (!mounted) {
      return;
    }

    setState(() {
      _cargandoTipos = false;
      _errorTipos = provider.mensajeError;
    });
  }

  /// Valida y actualiza el peligro.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    if (_tipoPeligroId == null || _tipoPeligroId! <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Selecciona un tipo de peligro.')),
        );

      return;
    }

    FocusScope.of(context).unfocus();

    final PeligroProvider provider = context.read<PeligroProvider>();

    final NavigatorState navigator = Navigator.of(context);

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _guardando = true;
    });

    final ActualizarPeligroRequest request = ActualizarPeligroRequest(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      tipoPeligroId: _tipoPeligroId!,
      fuente: _fuenteController.text,
      medio: _medioController.text,
      receptor: _receptorController.text,
      requisitoLegal: _requisitoLegalController.text,
      recomendaciones: _recomendacionesController.text,
      activo: _activo,
    );

    final bool actualizado = await provider.actualizarPeligro(
      widget.peligro.id,
      request,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (actualizado) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Peligro actualizado correctamente.')),
        );

      navigator.pop(true);
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            provider.mensajeError ?? 'No se pudo actualizar el peligro.',
          ),
        ),
      );
  }

  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del peligro.';
    }

    if (texto.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }

    if (texto.length > 200) {
      return 'El nombre no puede superar los 200 caracteres.';
    }

    return null;
  }

  String? _validarDescripcion(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 1500) {
      return 'La descripción no puede superar los 1500 caracteres.';
    }

    return null;
  }

  String? _validarCampo300(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 300) {
      return 'Este campo no puede superar los 300 caracteres.';
    }

    return null;
  }

  String? _validarRequisitoLegal(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 1000) {
      return 'El requisito legal no puede superar los 1000 caracteres.';
    }

    return null;
  }

  String? _validarRecomendaciones(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 2000) {
      return 'Las recomendaciones no pueden superar los 2000 caracteres.';
    }

    return null;
  }

  String? _validarTipoPeligro(int? valor) {
    if (valor == null || valor <= 0) {
      return 'Selecciona un tipo de peligro.';
    }

    return null;
  }

  /// Comprueba si existen cambios sin guardar.
  bool _hayCambios() {
    return _nombreController.text.trim() != widget.peligro.nombre.trim() ||
        _descripcionController.text.trim() !=
            (widget.peligro.descripcion?.trim() ?? '') ||
        _fuenteController.text.trim() !=
            (widget.peligro.fuente?.trim() ?? '') ||
        _medioController.text.trim() != (widget.peligro.medio?.trim() ?? '') ||
        _receptorController.text.trim() !=
            (widget.peligro.receptor?.trim() ?? '') ||
        _requisitoLegalController.text.trim() !=
            (widget.peligro.requisitoLegal?.trim() ?? '') ||
        _recomendacionesController.text.trim() !=
            (widget.peligro.recomendaciones?.trim() ?? '') ||
        _tipoPeligroId != widget.peligro.tipoPeligroId ||
        _activo != widget.peligro.activo;
  }

  /// Solicita confirmación antes de abandonar la pantalla.
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
        appBar: AppBar(title: const Text('Editar peligro')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoPeligro(
                  codigo: widget.peligro.codigo,
                  nombre: widget.peligro.nombre,
                ),

                const SizedBox(height: 24),

                const _TituloSeccion(
                  icono: Icons.warning_amber_rounded,
                  titulo: 'Información del peligro',
                  descripcion:
                      'Actualiza los datos principales del peligro identificado.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 20,
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
                  maxLength: 200,
                  validator: _validarNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del peligro',
                    hintText: 'Ejemplo: Piso mojado',
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
                  maxLength: 1500,
                  validator: _validarDescripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Describe detalladamente el peligro.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.account_tree_outlined,
                  titulo: 'Clasificación',
                  descripcion:
                      'Selecciona el tipo. La categoría se determinará automáticamente.',
                ),

                const SizedBox(height: 18),

                _construirSelectorTipo(),

                const SizedBox(height: 12),

                _CategoriaActualCard(
                  categoria: widget.peligro.categoriaVisible,
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.hub_outlined,
                  titulo: 'Fuente, medio y receptor',
                  descripcion:
                      'Actualiza cómo se origina y cómo afecta el peligro.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _fuenteController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Fuente',
                    hintText: 'Elemento o condición que origina el peligro.',
                    prefixIcon: Icon(Icons.electric_bolt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _medioController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Medio',
                    hintText: 'Forma por la que se transmite.',
                    prefixIcon: Icon(Icons.route_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _receptorController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Receptor',
                    hintText: 'Persona o elemento expuesto.',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.gavel_outlined,
                  titulo: 'Gestión y cumplimiento',
                  descripcion:
                      'Actualiza requisitos legales y recomendaciones.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _requisitoLegalController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  validator: _validarRequisitoLegal,
                  decoration: const InputDecoration(
                    labelText: 'Requisito legal',
                    hintText: 'Norma o requisito aplicable.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.policy_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _recomendacionesController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  validator: _validarRecomendaciones,
                  decoration: const InputDecoration(
                    labelText: 'Recomendaciones',
                    hintText: 'Medidas recomendadas para tratar el peligro.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.fact_check_outlined),
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
                  title: const Text('Peligro activo'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible para utilizar en matrices IPERC.'
                        : 'No estará disponible para nuevos registros.',
                  ),
                  secondary: Icon(
                    _activo
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
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

  /// Selector de tipos de peligro.
  Widget _construirSelectorTipo() {
    return Consumer<TipoPeligroProvider>(
      builder:
          (BuildContext context, TipoPeligroProvider provider, Widget? child) {
            if (_cargandoTipos) {
              return const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipo de peligro',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando tipos de peligro...'),
                  ],
                ),
              );
            }

            final List<TipoPeligroModel> tipos = provider.tipos.where((
              TipoPeligroModel tipo,
            ) {
              return tipo.estaDisponible ||
                  tipo.id == widget.peligro.tipoPeligroId;
            }).toList();

            /*
         * Si el tipo actual no aparece en la respuesta,
         * se agrega temporalmente para evitar que el
         * Dropdown tenga un valor sin opción asociada.
         */
            final bool existeTipoActual = tipos.any((TipoPeligroModel tipo) {
              return tipo.id == widget.peligro.tipoPeligroId;
            });

            if (!existeTipoActual && widget.peligro.tipoPeligroId > 0) {
              tipos.add(
                TipoPeligroModel(
                  id: widget.peligro.tipoPeligroId,
                  codigo: '',
                  nombre: widget.peligro.tipoPeligroNombre ?? 'Tipo actual',
                  descripcion: null,
                  activo: true,
                  estado: true,
                ),
              );
            }

            if (_errorTipos != null && tipos.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tipo de peligro',
                      prefixIcon: const Icon(Icons.account_tree_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _errorTipos,
                    ),
                    child: const Text('No fue posible cargar los tipos.'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _cargarTiposPeligro,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a intentar'),
                  ),
                ],
              );
            }

            return DropdownButtonFormField<int>(
              initialValue: _tipoPeligroId,
              isExpanded: true,
              validator: _validarTipoPeligro,
              decoration: const InputDecoration(
                labelText: 'Tipo de peligro',
                hintText: 'Selecciona un tipo de peligro',
                helperText: 'La categoría se obtiene automáticamente.',
                prefixIcon: Icon(Icons.account_tree_outlined),
                border: OutlineInputBorder(),
              ),
              items: tipos.map((TipoPeligroModel tipo) {
                return DropdownMenuItem<int>(
                  value: tipo.id,
                  child: Text(
                    tipo.nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _guardando
                  ? null
                  : (int? valor) {
                      setState(() {
                        _tipoPeligroId = valor;
                      });
                    },
            );
          },
    );
  }
}

/// Encabezado del peligro actual.
class _EncabezadoPeligro extends StatelessWidget {
  const _EncabezadoPeligro({required this.codigo, required this.nombre});

  final String codigo;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
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
              Icons.warning_amber_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 30,
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
                  codigo.trim().isEmpty ? 'Sin código' : codigo,
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

/// Título reutilizable para las secciones.
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(descripcion, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Muestra la categoría actualmente derivada.
class _CategoriaActualCard extends StatelessWidget {
  const _CategoriaActualCard({required this.categoria});

  final String categoria;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.category_outlined,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Categoría actual: $categoria')),
        ],
      ),
    );
  }
}
