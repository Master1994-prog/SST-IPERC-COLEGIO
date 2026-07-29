import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tipo_equipo_proteccion_model.dart';
import '../../providers/tipo_equipo_proteccion_provider.dart';

/// Pantalla utilizada para registrar un nuevo
/// tipo de Equipo de Protección Personal.
class NuevoTipoEquipoProteccionScreen extends StatefulWidget {
  const NuevoTipoEquipoProteccionScreen({super.key});

  @override
  State<NuevoTipoEquipoProteccionScreen> createState() {
    return _NuevoTipoEquipoProteccionScreenState();
  }
}

class _NuevoTipoEquipoProteccionScreenState
    extends State<NuevoTipoEquipoProteccionScreen> {
  /// Clave del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código.
  final TextEditingController _codigoController = TextEditingController();

  /// Controlador del nombre.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador de la descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Controlador del orden.
  final TextEditingController _ordenController = TextEditingController();

  /// Código propuesto al abrir el formulario.
  late final String _codigoInicial;

  /// Orden propuesto al abrir el formulario.
  late final String _ordenInicial;

  /// Indica si pertenece al catálogo global.
  bool _esGlobal = true;

  /// Colegio propietario cuando el tipo no es global.
  int? _colegioId;

  /// Evita envíos repetidos.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoInicial = _generarCodigoCorrelativo();
    _ordenInicial = _generarSiguienteOrden().toString();

    _codigoController.text = _codigoInicial;
    _ordenController.text = _ordenInicial;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();

    super.dispose();
  }

  /// Genera el siguiente código correlativo.
  ///
  /// Ejemplo: EPP-TIPO-001
  String _generarCodigoCorrelativo() {
    final TipoEquipoProteccionProvider provider = context
        .read<TipoEquipoProteccionProvider>();

    int mayorNumero = 0;
    final RegExp formato = RegExp(r'^EPP-TIPO-(\d+)$');

    for (final TipoEquipoProteccionModel tipo in provider.tipos) {
      final RegExpMatch? coincidencia = formato.firstMatch(
        tipo.codigo.trim().toUpperCase(),
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

    return 'EPP-TIPO-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Propone el siguiente orden disponible.
  int _generarSiguienteOrden() {
    final TipoEquipoProteccionProvider provider = context
        .read<TipoEquipoProteccionProvider>();

    if (provider.tipos.isEmpty) {
      return 1;
    }

    int mayorOrden = 0;

    for (final TipoEquipoProteccionModel tipo in provider.tipos) {
      if (tipo.orden > mayorOrden) {
        mayorOrden = tipo.orden;
      }
    }

    return mayorOrden + 1;
  }

  /// Valida el formulario y registra el tipo.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El orden ingresado no es válido.')),
      );

      return;
    }

    if (!_esGlobal && (_colegioId == null || _colegioId! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el colegio propietario.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final TipoEquipoProteccionProvider provider = context
        .read<TipoEquipoProteccionProvider>();

    setState(() {
      _guardando = true;
    });

    final CrearTipoEquipoProteccionRequest request =
        CrearTipoEquipoProteccionRequest(
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          orden: orden,
          esGlobal: _esGlobal,
          colegioId: _esGlobal ? null : _colegioId,
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
            content: Text('Tipo de EPP registrado correctamente.'),
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
            provider.mensajeError ?? 'No se pudo registrar el tipo de EPP.',
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
      return 'Utiliza letras, números, guiones o guion bajo.';
    }

    return null;
  }

  /// Valida el nombre.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del tipo de EPP.';
    }

    if (texto.length < 3) {
      return 'El nombre debe contener al menos 3 caracteres.';
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

  /// Valida el orden.
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

  /// Determina si existen cambios sin guardar.
  bool _tieneCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _codigoController.text.trim() != _codigoInicial ||
        _ordenController.text.trim() != _ordenInicial ||
        !_esGlobal ||
        _colegioId != null;
  }

  /// Solicita confirmación antes de salir.
  Future<bool> _confirmarSalida() async {
    if (!_tieneCambios()) {
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
        appBar: AppBar(title: const Text('Nuevo tipo de EPP')),
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
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
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
                      tooltip: 'Generar siguiente código',
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
                  maxLength: 150,
                  textInputAction: TextInputAction.next,
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
                    hintText:
                        'Describe los equipos que pertenecen a este tipo.',
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
                  textInputAction: TextInputAction.done,
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

                const SizedBox(height: 20),

                SwitchListTile(
                  value: _esGlobal,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _esGlobal = valor;

                            if (valor) {
                              _colegioId = null;
                            }
                          });
                        },
                  title: const Text('Catálogo global'),
                  subtitle: Text(
                    _esGlobal
                        ? 'Estará disponible para todos los colegios.'
                        : 'Pertenecerá únicamente a un colegio.',
                  ),
                  secondary: Icon(
                    _esGlobal ? Icons.public : Icons.school_outlined,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                if (!_esGlobal) ...<Widget>[
                  const SizedBox(height: 12),

                  TextFormField(
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'ID del colegio',
                      hintText: 'Ingresa el identificador del colegio',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String valor) {
                      _colegioId = int.tryParse(valor.trim());
                    },
                    validator: (String? valor) {
                      if (_esGlobal) {
                        return null;
                      }

                      final int? colegioId = int.tryParse(valor?.trim() ?? '');

                      if (colegioId == null || colegioId <= 0) {
                        return 'Ingresa un colegio válido.';
                      }

                      return null;
                    },
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
            Icons.category_outlined,
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
                'Información del tipo de EPP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Registra una categoría que permita '
                'clasificar los equipos de protección.',
              ),
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
              'El orden determina la posición del tipo '
              'dentro del catálogo. Los números menores '
              'se mostrarán primero.',
            ),
          ),
        ],
      ),
    );
  }
}
