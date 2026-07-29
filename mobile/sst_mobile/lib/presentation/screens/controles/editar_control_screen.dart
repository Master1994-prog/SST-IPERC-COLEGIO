import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/clasificacion_control_model.dart';
import '../../../data/models/control_model.dart';
import '../../providers/clasificacion_control_provider.dart';
import '../../providers/control_provider.dart';

/// Pantalla utilizada para editar una medida de control.
///
/// La clasificación se selecciona desde el catálogo
/// de clasificaciones activas.
class EditarControlScreen extends StatefulWidget {
  const EditarControlScreen({
    super.key,
    required this.control,
    required this.usuarioActualizacionId,
  });

  /// Control que será actualizado.
  final ControlModel control;

  /// Identificador del usuario autenticado.
  final int usuarioActualizacionId;

  @override
  State<EditarControlScreen> createState() {
    return _EditarControlScreenState();
  }
}

class _EditarControlScreenState extends State<EditarControlScreen> {
  /// Clave principal del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código.
  late final TextEditingController _codigoController;

  /// Controlador del nombre.
  late final TextEditingController _nombreController;

  /// Controlador de la descripción.
  late final TextEditingController _descripcionController;

  /// Clasificación seleccionada.
  int? _clasificacionControlId;

  /// Estado actual del control.
  late bool _activo;

  /// Evita guardar varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(text: widget.control.codigo);

    _nombreController = TextEditingController(text: widget.control.nombre);

    _descripcionController = TextEditingController(
      text: widget.control.descripcion ?? '',
    );

    _clasificacionControlId = widget.control.clasificacionControlId;

    _activo = widget.control.activo;

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

  /// Valida el formulario y actualiza el control.
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

    if (widget.usuarioActualizacionId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El usuario que actualiza no es válido.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final ControlProvider provider = context.read<ControlProvider>();

    setState(() {
      _guardando = true;
    });

    final ActualizarControlRequest request = ActualizarControlRequest(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      clasificacionControlId: clasificacionSeleccionada,
      activo: _activo,
      usuarioActualizacionId: widget.usuarioActualizacionId,
    );

    final bool actualizado = await provider.actualizarControl(
      widget.control.id,
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
          const SnackBar(content: Text('Control actualizado correctamente.')),
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
            provider.mensajeError ?? 'No se pudo actualizar el control.',
          ),
        ),
      );
  }

  /// Valida el nombre.
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

  /// Comprueba si existen modificaciones.
  bool _hayCambios() {
    final String nombreActual = _nombreController.text.trim();

    final String descripcionActual = _descripcionController.text.trim();

    final String nombreOriginal = widget.control.nombre.trim();

    final String descripcionOriginal = widget.control.descripcion?.trim() ?? '';

    return nombreActual != nombreOriginal ||
        descripcionActual != descripcionOriginal ||
        _clasificacionControlId != widget.control.clasificacionControlId ||
        _activo != widget.control.activo;
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
        appBar: AppBar(title: const Text('Editar control')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoControl(
                  codigo: widget.control.codigo,
                  nombre: widget.control.nombre,
                  clasificacion: widget.control.clasificacionVisible,
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.health_and_safety_outlined,
                  titulo: 'Información del control',
                  descripcion:
                      'Actualiza la medida utilizada '
                      'para reducir o controlar un peligro.',
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
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
                      'Selecciona la clasificación '
                      'correspondiente dentro de la '
                      'jerarquía de controles.',
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

                        /*
                     * Verifica que la clasificación actual
                     * exista dentro del catálogo activo.
                     */
                        final bool existeSeleccionActual =
                            _clasificacionControlId == null ||
                            provider.clasificaciones.any((
                              ClasificacionControlModel clasificacion,
                            ) {
                              return clasificacion.id ==
                                  _clasificacionControlId;
                            });

                        final int? valorSeleccionado = existeSeleccionActual
                            ? _clasificacionControlId
                            : null;

                        return DropdownButtonFormField<int>(
                          initialValue: valorSeleccionado,
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

/// Encabezado que muestra los datos actuales.
class _EncabezadoControl extends StatelessWidget {
  const _EncabezadoControl({
    required this.codigo,
    required this.nombre,
    required this.clasificacion,
  });

  final String codigo;
  final String nombre;
  final String clasificacion;

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
              Icons.health_and_safety_outlined,
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
                const SizedBox(height: 3),
                Text(
                  clasificacion,
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

/// Campo mostrado mientras se cargan las clasificaciones.
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

/// Tarjeta informativa inferior.
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
