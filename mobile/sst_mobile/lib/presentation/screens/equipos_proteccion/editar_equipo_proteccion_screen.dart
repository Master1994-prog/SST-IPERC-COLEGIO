import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/equipo_proteccion_model.dart';
import '../../../data/models/tipo_equipo_proteccion_model.dart';
import '../../providers/equipo_proteccion_provider.dart';
import '../../providers/tipo_equipo_proteccion_provider.dart';

/// Pantalla utilizada para editar un Equipo de Protección Personal.
///
/// Permite actualizar:
///
/// - Código.
/// - Nombre.
/// - Descripción.
/// - Tipo de EPP.
/// - Estado activo.
///
/// Los demás campos requeridos por el backend se envían
/// con valores iniciales hasta agregarlos visualmente
/// al formulario.
class EditarEquipoProteccionScreen extends StatefulWidget {
  const EditarEquipoProteccionScreen({
    super.key,
    required this.equipo,
    required this.usuarioActualizacionId,
  });

  /// Equipo de protección que será editado.
  final EquipoProteccionModel equipo;

  /// Identificador del usuario autenticado.
  ///
  /// Se conserva para la futura auditoría del sistema,
  /// aunque UpdateEquipoProteccionDto todavía no recibe
  /// esta propiedad.
  final int usuarioActualizacionId;

  @override
  State<EditarEquipoProteccionScreen> createState() {
    return _EditarEquipoProteccionScreenState();
  }
}

class _EditarEquipoProteccionScreenState
    extends State<EditarEquipoProteccionScreen> {
  /// Clave utilizada para validar el formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código actual.
  late final TextEditingController _codigoController;

  /// Controlador del nombre.
  late final TextEditingController _nombreController;

  /// Controlador de la descripción.
  late final TextEditingController _descripcionController;

  /// Identificador del tipo de EPP seleccionado.
  int? _tipoEquipoProteccionId;

  /// Estado activo del equipo.
  late bool _activo;

  /// Evita ejecutar el guardado varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    // Carga los valores actuales del equipo.
    _codigoController = TextEditingController(text: widget.equipo.codigo);

    _nombreController = TextEditingController(text: widget.equipo.nombre);

    _descripcionController = TextEditingController(
      text: widget.equipo.descripcion ?? '',
    );

    _tipoEquipoProteccionId = widget.equipo.tipoEquipoProteccionId;

    _activo = widget.equipo.activo;

    /*
     * Los tipos activos se cargan después de construir
     * la primera vista para garantizar que el provider
     * se encuentre disponible.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<TipoEquipoProteccionProvider>().cargarTiposActivos();
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Valida el formulario y actualiza el EPP.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final int? tipoSeleccionado = _tipoEquipoProteccionId;

    if (tipoSeleccionado == null || tipoSeleccionado <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de equipo de protección.'),
        ),
      );

      return;
    }

    if (widget.equipo.codigo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El equipo no tiene un código válido.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final EquipoProteccionProvider provider = context
        .read<EquipoProteccionProvider>();

    setState(() {
      _guardando = true;
    });

    /*
     * Este request coincide con UpdateEquipoProteccionDto.
     *
     * No se envía usuarioActualizacionId porque el DTO
     * actual del backend no contiene esa propiedad.
     */
    final ActualizarEquipoProteccionRequest request =
        ActualizarEquipoProteccionRequest(
          codigo: widget.equipo.codigo,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          tipoEquipoProteccionId: tipoSeleccionado,

          // Campos opcionales del DTO.
          marca: null,
          modelo: null,
          normaTecnica: null,
          vidaUtilMeses: null,

          // Valores actuales iniciales.
          requiereCapacitacion: false,
          requiereMantenimiento: false,
          activo: _activo,
          esGlobal: true,
          colegioId: null,
        );

    final bool actualizado = await provider.actualizarEquipo(
      widget.equipo.id,
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
            content: Text('Equipo de protección actualizado correctamente.'),
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
            provider.mensajeError ??
                'No se pudo actualizar el equipo de protección.',
          ),
        ),
      );
  }

  /// Valida el nombre del equipo.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre del equipo de protección.';
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

    if (texto.length > 2000) {
      return 'La descripción no puede superar los 2000 caracteres.';
    }

    return null;
  }

  /// Comprueba si el usuario modificó algún dato.
  bool _hayCambios() {
    final String nombreActual = _nombreController.text.trim();

    final String descripcionActual = _descripcionController.text.trim();

    final String nombreOriginal = widget.equipo.nombre.trim();

    final String descripcionOriginal = widget.equipo.descripcion?.trim() ?? '';

    return nombreActual != nombreOriginal ||
        descripcionActual != descripcionOriginal ||
        _tipoEquipoProteccionId != widget.equipo.tipoEquipoProteccionId ||
        _activo != widget.equipo.activo;
  }

  /// Solicita confirmación antes de cerrar la pantalla
  /// cuando existen cambios sin guardar.
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
        appBar: AppBar(title: const Text('Editar equipo de protección')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoEquipo(
                  codigo: widget.equipo.codigo,
                  nombre: widget.equipo.nombre,
                  tipo: widget.equipo.tipoVisible,
                ),

                const SizedBox(height: 22),

                const _TituloSeccion(
                  icono: Icons.engineering_outlined,
                  titulo: 'Información del equipo',
                  descripcion:
                      'Actualiza los datos principales '
                      'del equipo de protección.',
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
                    labelText: 'Nombre del equipo',
                    hintText: 'Ejemplo: Casco de seguridad',
                    prefixIcon: Icon(Icons.engineering_outlined),
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
                  maxLength: 2000,
                  validator: _validarDescripcion,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText:
                        'Describe las características '
                        'y el uso del equipo.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const _TituloSeccion(
                  icono: Icons.category_outlined,
                  titulo: 'Tipo de equipo de protección',
                  descripcion:
                      'Selecciona el tipo de EPP '
                      'asociado al equipo.',
                ),

                const SizedBox(height: 18),

                Consumer<TipoEquipoProteccionProvider>(
                  builder:
                      (
                        BuildContext context,
                        TipoEquipoProteccionProvider provider,
                        Widget? child,
                      ) {
                        if (provider.cargando && !provider.tieneTipos) {
                          return const _CampoCargandoTipos();
                        }

                        if (provider.tieneError && !provider.tieneTipos) {
                          return _CampoErrorTipos(
                            mensaje:
                                provider.mensajeError ??
                                'No se pudieron cargar '
                                    'los tipos de EPP.',
                            onReintentar: provider.cargarTiposActivos,
                          );
                        }

                        if (!provider.tieneTipos) {
                          return const _CampoSinTipos();
                        }

                        /*
                     * Comprueba que el tipo actual exista
                     * dentro de la lista de opciones.
                     */
                        final bool existeTipoSeleccionado =
                            _tipoEquipoProteccionId == null ||
                            provider.tipos.any((
                              TipoEquipoProteccionModel tipo,
                            ) {
                              return tipo.id == _tipoEquipoProteccionId;
                            });

                        final int? valorSeleccionado = existeTipoSeleccionado
                            ? _tipoEquipoProteccionId
                            : null;

                        return DropdownButtonFormField<int>(
                          initialValue: valorSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de EPP',
                            hintText: 'Selecciona un tipo de protección',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: provider.tipos.map((
                            TipoEquipoProteccionModel tipo,
                          ) {
                            return DropdownMenuItem<int>(
                              value: tipo.id,
                              child: Text(
                                tipo.nombreCompleto,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _guardando
                              ? null
                              : (int? valor) {
                                  setState(() {
                                    _tipoEquipoProteccionId = valor;
                                  });
                                },
                          validator: (int? valor) {
                            if (valor == null) {
                              return 'Selecciona un tipo de EPP.';
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
                  title: const Text('Equipo activo'),
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

                const SizedBox(height: 14),

                const _InformacionActualizacionCard(),
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

/// Encabezado que muestra la información actual del EPP.
class _EncabezadoEquipo extends StatelessWidget {
  const _EncabezadoEquipo({
    required this.codigo,
    required this.nombre,
    required this.tipo,
  });

  final String codigo;
  final String nombre;
  final String tipo;

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.engineering_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 31,
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
                  tipo,
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

/// Tarjeta informativa de la actualización.
class _InformacionActualizacionCard extends StatelessWidget {
  const _InformacionActualizacionCard();

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
              'El código actual del EPP se conservará. '
              'Los cambios se enviarán al backend '
              'al seleccionar Guardar cambios.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo mostrado mientras se cargan los tipos.
class _CampoCargandoTipos extends StatelessWidget {
  const _CampoCargandoTipos();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Tipo de EPP',
        prefixIcon: Icon(Icons.category_outlined),
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
          Expanded(child: Text('Cargando tipos de EPP...')),
        ],
      ),
    );
  }
}

/// Campo mostrado cuando ocurre un error.
class _CampoErrorTipos extends StatelessWidget {
  const _CampoErrorTipos({required this.mensaje, required this.onReintentar});

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
                  'No se pudieron cargar los tipos',
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

/// Campo mostrado cuando no existen tipos activos.
class _CampoSinTipos extends StatelessWidget {
  const _CampoSinTipos();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Tipo de EPP',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      child: Text('No existen tipos de EPP activos.'),
    );
  }
}
