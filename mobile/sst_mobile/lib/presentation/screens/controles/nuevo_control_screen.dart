import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/clasificacion_control_model.dart';
import '../../../data/models/control_model.dart';
import '../../providers/clasificacion_control_provider.dart';
import '../../providers/control_provider.dart';

/// Pantalla para registrar una nueva medida de control.
///
/// La clasificación se selecciona desde el catálogo
/// de clasificaciones activas.
class NuevoControlScreen extends StatefulWidget {
  const NuevoControlScreen({super.key, required this.usuarioRegistroId});

  /// Identificador del usuario autenticado.
  final int usuarioRegistroId;

  @override
  State<NuevoControlScreen> createState() {
    return _NuevoControlScreenState();
  }
}

class _NuevoControlScreenState extends State<NuevoControlScreen> {
  /// Clave utilizada para validar el formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código generado.
  final TextEditingController _codigoController = TextEditingController();

  /// Controlador del nombre.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador de la descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Clasificación seleccionada.
  int? _clasificacionControlId;

  /// Estado inicial del control.
  bool _activo = true;

  /// Evita guardar varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController.text = _generarCodigoCorrelativo();

    /*
     * Carga las clasificaciones activas después
     * de construir la primera vista.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<ClasificacionControlProvider>()
          .cargarClasificacionesActivas();
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Genera un código correlativo con formato CTRL-001.
  String _generarCodigoCorrelativo() {
    final List<ControlModel> controles =
        context.read<ControlProvider>().controles;
    final RegExp formato = RegExp(r'^CTRL-(\d+)$', caseSensitive: false);

    int mayorNumero = 0;

    for (final ControlModel control in controles) {
      final RegExpMatch? coincidencia = formato.firstMatch(
        control.codigo.trim(),
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

    return 'CTRL-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Valida el formulario y registra el control.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final int? clasificacionSeleccionada = _clasificacionControlId;

    if (clasificacionSeleccionada == null || clasificacionSeleccionada <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una clasificación de control.'),
        ),
      );

      return;
    }

    if (widget.usuarioRegistroId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El usuario que registra no es válido.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final ControlProvider provider = context.read<ControlProvider>();

    setState(() {
      _guardando = true;
    });

    final CrearControlRequest request = CrearControlRequest(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      clasificacionControlId: clasificacionSeleccionada,
      activo: _activo,
      usuarioRegistroId: widget.usuarioRegistroId,
    );

    final bool creado = await provider.crearControl(request);

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
          const SnackBar(content: Text('Control registrado correctamente.')),
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
            provider.mensajeError ?? 'No se pudo registrar el control.',
          ),
        ),
      );
  }

  /// Valida el nombre del control.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del control.';
    }

    if (texto.length < 3) {
      return 'El nombre debe contener al menos 3 caracteres.';
    }

    if (texto.length > 200) {
      return 'El nombre no puede superar los 200 caracteres.';
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

  /// Comprueba si existe información sin guardar.
  bool _tieneCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _clasificacionControlId != null ||
        !_activo;
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
        appBar: AppBar(title: const Text('Nuevo control')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                const _TituloSeccion(
                  icono: Icons.health_and_safety_outlined,
                  titulo: 'Información del control',
                  descripcion:
                      'Registra la medida que permitirá '
                      'reducir o controlar un peligro.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
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
                    labelText: 'Nombre del control',
                    hintText: 'Ejemplo: Señalizar el área',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
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
                        'Describe cómo se aplicará '
                        'la medida de control.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const _TituloSeccion(
                  icono: Icons.account_tree_outlined,
                  titulo: 'Clasificación',
                  descripcion:
                      'Asocia el control con la jerarquía '
                      'de medidas preventivas.',
                ),

                const SizedBox(height: 18),

                Consumer<ClasificacionControlProvider>(
                  builder:
                      (
                        BuildContext context,
                        ClasificacionControlProvider provider,
                        Widget? child,
                      ) {
                        if (provider.cargando &&
                            !provider.tieneClasificaciones) {
                          return const _CampoCargandoClasificaciones();
                        }

                        if (provider.tieneError &&
                            !provider.tieneClasificaciones) {
                          return _CampoErrorClasificaciones(
                            mensaje:
                                provider.mensajeError ??
                                'No se pudieron cargar '
                                    'las clasificaciones.',
                            onReintentar: provider.cargarClasificacionesActivas,
                          );
                        }

                        if (!provider.tieneClasificaciones) {
                          return const _CampoSinClasificaciones();
                        }

                        return DropdownButtonFormField<int>(
                          initialValue: _clasificacionControlId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Clasificación de control',
                            hintText: 'Selecciona una clasificación',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: provider.clasificaciones.map((
                            ClasificacionControlModel clasificacion,
                          ) {
                            return DropdownMenuItem<int>(
                              value: clasificacion.id,
                              child: Text(
                                '${clasificacion.nombreCompleto} '
                                '· Prioridad '
                                '${clasificacion.prioridad}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _guardando
                              ? null
                              : (int? valor) {
                                  setState(() {
                                    _clasificacionControlId = valor;
                                  });
                                },
                          validator: (int? valor) {
                            if (valor == null || valor <= 0) {
                              return 'Selecciona una clasificación.';
                            }

                            return null;
                          },
                        );
                      },
                ),

                const SizedBox(height: 20),

                SwitchListTile(
                  value: _activo,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _activo = valor;
                          });
                        },
                  title: const Text('Control activo'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible para utilizarse '
                              'en matrices IPERC.'
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

/// Encabezado visual de una sección.
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
          width: 44,
          height: 44,
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

/// Campo mostrado durante la carga.
class _CampoCargandoClasificaciones extends StatelessWidget {
  const _CampoCargandoClasificaciones();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Clasificación de control',
        prefixIcon: Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Cargando clasificaciones...')),
        ],
      ),
    );
  }
}

/// Campo mostrado cuando ocurre un error.
class _CampoErrorClasificaciones extends StatelessWidget {
  const _CampoErrorClasificaciones({
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: colorScheme.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No se pudieron cargar las clasificaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(mensaje),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              onReintentar();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Campo mostrado cuando no existen clasificaciones activas.
class _CampoSinClasificaciones extends StatelessWidget {
  const _CampoSinClasificaciones();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Clasificación de control',
        prefixIcon: Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(),
      ),
      child: Text('No existen clasificaciones activas.'),
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
              'La clasificación permite ordenar el control '
              'según la jerarquía de medidas preventivas.',
            ),
          ),
        ],
      ),
    );
  }
}
