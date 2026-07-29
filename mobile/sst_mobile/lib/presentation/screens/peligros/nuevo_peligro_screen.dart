import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/peligro_model.dart';
import '../../../data/models/tipo_peligro_model.dart';
import '../../providers/peligro_provider.dart';
import '../../providers/tipo_peligro_provider.dart';

/// Pantalla para registrar un nuevo peligro SST.
class NuevoPeligroScreen extends StatefulWidget {
  const NuevoPeligroScreen({required this.usuarioRegistroId, super.key});

  /// Se conserva temporalmente para mantener compatibilidad
  /// con la pantalla actual de peligros.
  ///
  /// El DTO actual del backend ya no utiliza este campo.
  final int usuarioRegistroId;

  @override
  State<NuevoPeligroScreen> createState() {
    return _NuevoPeligroScreenState();
  }
}

class _NuevoPeligroScreenState extends State<NuevoPeligroScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController = TextEditingController();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  final TextEditingController _fuenteController = TextEditingController();

  final TextEditingController _medioController = TextEditingController();

  final TextEditingController _receptorController = TextEditingController();

  final TextEditingController _requisitoLegalController =
      TextEditingController();

  final TextEditingController _recomendacionesController =
      TextEditingController();

  int? _tipoPeligroId;

  bool _guardando = false;
  bool _cargandoTipos = true;

  String? _errorTipos;

  late final String _codigoInicial;

  @override
  void initState() {
    super.initState();

    _codigoInicial = _generarCodigoCorrelativo();
    _codigoController.text = _codigoInicial;

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

  /// Genera un código correlativo con formato PEL-001.
  String _generarCodigoCorrelativo() {
    final List<PeligroModel> peligros = context.read<PeligroProvider>().peligros;
    final RegExp formato = RegExp(r'^PEL-(\d+)$', caseSensitive: false);

    int mayorNumero = 0;

    for (final PeligroModel peligro in peligros) {
      final RegExpMatch? coincidencia = formato.firstMatch(
        peligro.codigo.trim(),
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

    return 'PEL-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Valida y registra el peligro.
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

    final CrearPeligroRequest request = CrearPeligroRequest(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      tipoPeligroId: _tipoPeligroId!,
      fuente: _fuenteController.text,
      medio: _medioController.text,
      receptor: _receptorController.text,
      requisitoLegal: _requisitoLegalController.text,
      recomendaciones: _recomendacionesController.text,
    );

    final bool creado = await provider.crearPeligro(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (creado) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Peligro registrado correctamente.')),
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
            provider.mensajeError ?? 'No se pudo registrar el peligro.',
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

  /// Verifica si el formulario contiene cambios.
  bool _hayCambios() {
    return _codigoController.text.trim() != _codigoInicial ||
        _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _fuenteController.text.trim().isNotEmpty ||
        _medioController.text.trim().isNotEmpty ||
        _receptorController.text.trim().isNotEmpty ||
        _requisitoLegalController.text.trim().isNotEmpty ||
        _recomendacionesController.text.trim().isNotEmpty ||
        _tipoPeligroId != null;
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
        appBar: AppBar(title: const Text('Nuevo peligro')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                const _TituloSeccion(
                  icono: Icons.warning_amber_rounded,
                  titulo: 'Información del peligro',
                  descripcion:
                      'Registra los datos principales del peligro identificado.',
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Código generado',
                    helperText: 'El código se genera automáticamente.',
                    prefixIcon: const Icon(Icons.qr_code_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Generar otro código',
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
                    hintText:
                        'Describe detalladamente el peligro identificado.',
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
                      'Selecciona el tipo. La categoría se obtendrá automáticamente.',
                ),

                const SizedBox(height: 18),

                _construirSelectorTipo(),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.hub_outlined,
                  titulo: 'Fuente, medio y receptor',
                  descripcion:
                      'Describe cómo se origina y cómo afecta el peligro.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _fuenteController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Fuente',
                    hintText: 'Ejemplo: Instalación eléctrica defectuosa',
                    prefixIcon: Icon(Icons.electric_bolt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _medioController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Medio',
                    hintText: 'Ejemplo: Contacto directo o indirecto',
                    prefixIcon: Icon(Icons.route_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _receptorController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 300,
                  validator: _validarCampo300,
                  decoration: const InputDecoration(
                    labelText: 'Receptor',
                    hintText: 'Ejemplo: Personal administrativo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.gavel_outlined,
                  titulo: 'Gestión y cumplimiento',
                  descripcion: 'Registra requisitos legales y recomendaciones.',
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
                    hintText:
                        'Medidas generales recomendadas para tratar el peligro.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.fact_check_outlined),
                    border: OutlineInputBorder(),
                  ),
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

  /// Construye el selector de tipos de peligro.
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

            if (_errorTipos != null && provider.tipos.isEmpty) {
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

            final List<TipoPeligroModel> tipos = provider.tipos.where((
              TipoPeligroModel tipo,
            ) {
              return tipo.estaDisponible;
            }).toList();

            return DropdownButtonFormField<int>(
              initialValue: _tipoPeligroId,
              isExpanded: true,
              validator: _validarTipoPeligro,
              decoration: const InputDecoration(
                labelText: 'Tipo de peligro',
                hintText: 'Selecciona un tipo de peligro',
                helperText: 'La categoría se determina automáticamente.',
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

/// Encabezado reutilizable de una sección.
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

/// Información complementaria del formulario.
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
              'El peligro se registrará activo. '
              'La categoría no se selecciona directamente, '
              'porque pertenece al tipo de peligro elegido.',
            ),
          ),
        ],
      ),
    );
  }
}
