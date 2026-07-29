import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/equipo_proteccion_model.dart';
import '../../../data/models/tipo_equipo_proteccion_model.dart';
import '../../providers/equipo_proteccion_provider.dart';
import '../../providers/tipo_equipo_proteccion_provider.dart';

/// Pantalla utilizada para registrar un nuevo
/// Equipo de Protección Personal.
///
/// El formulario utiliza los campos requeridos por
/// CreateEquipoProteccionDto del backend.
class NuevoEquipoProteccionScreen extends StatefulWidget {
  const NuevoEquipoProteccionScreen({
    super.key,
    required this.usuarioRegistroId,
  });

  /// Usuario autenticado que realiza la operación.
  ///
  /// Actualmente el DTO del backend no recibe este campo,
  /// pero se conserva para integrarlo posteriormente
  /// con la auditoría del sistema.
  final int usuarioRegistroId;

  @override
  State<NuevoEquipoProteccionScreen> createState() {
    return _NuevoEquipoProteccionScreenState();
  }
}

class _NuevoEquipoProteccionScreenState
    extends State<NuevoEquipoProteccionScreen> {
  /// Clave utilizada para validar el formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controlador del código generado para el EPP.
  final TextEditingController _codigoController = TextEditingController();

  /// Controlador del nombre del EPP.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador de la descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Identificador del tipo de EPP seleccionado.
  int? _tipoEquipoProteccionId;

  /// Evita enviar el formulario varias veces.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _codigoController.text = _generarCodigoEpp();

    /*
     * Los tipos activos se cargan después de construir
     * la primera vista para que el Provider ya se encuentre
     * disponible en el árbol de widgets.
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

  /// Genera el siguiente código correlativo para EPP.
  String _generarCodigoEpp() {
    final List<EquipoProteccionModel> equipos = context
        .read<EquipoProteccionProvider>()
        .equipos;

    int mayorNumero = 0;

    for (final EquipoProteccionModel equipo in equipos) {
      final RegExpMatch? coincidencia = RegExp(
        r'^EPP-(\d+)$',
        caseSensitive: false,
      ).firstMatch(equipo.codigo.trim());

      if (coincidencia == null) {
        continue;
      }

      final int numero = int.tryParse(coincidencia.group(1) ?? '') ?? 0;

      if (numero > mayorNumero) {
        mayorNumero = numero;
      }
    }

    final int siguienteNumero = mayorNumero + 1;

    return 'EPP-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  /// Valida el formulario y registra el nuevo EPP.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final int? tipoSeleccionado = _tipoEquipoProteccionId;

    if (tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de equipo de protección.'),
        ),
      );

      return;
    }

    /*
     * Se conserva esta validación porque la pantalla recibe
     * el usuario autenticado, aunque el DTO todavía no lo envía.
     */
    if (widget.usuarioRegistroId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El usuario que realiza el registro no es válido.'),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    final EquipoProteccionProvider provider = context
        .read<EquipoProteccionProvider>();

    setState(() {
      _guardando = true;
    });

    final CrearEquipoProteccionRequest request = CrearEquipoProteccionRequest(
      codigo: _codigoController.text.trim(),
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      tipoEquipoProteccionId: tipoSeleccionado,

      // Campos opcionales del DTO del backend.
      marca: null,
      modelo: null,
      normaTecnica: null,
      vidaUtilMeses: null,

      // Valores iniciales.
      requiereCapacitacion: false,
      requiereMantenimiento: false,
      esGlobal: true,
      colegioId: null,
    );

    final bool creado = await provider.crearEquipo(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (creado) {
      final NavigatorState navigator = Navigator.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipo de protección registrado correctamente.'),
        ),
      );

      navigator.pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ??
              'No se pudo registrar el equipo de protección.',
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

  /// Comprueba si existe información sin guardar.
  bool _tieneCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _tipoEquipoProteccionId != null;
  }

  /// Solicita confirmación antes de salir cuando
  /// existen cambios sin guardar.
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
        appBar: AppBar(title: const Text('Nuevo equipo de protección')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                const _TituloSeccion(
                  icono: Icons.engineering_outlined,
                  titulo: 'Información del equipo',
                  descripcion:
                      'Registra el EPP que será utilizado '
                      'para proteger al personal frente '
                      'a los peligros identificados.',
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
                                _codigoController.text = _generarCodigoEpp();
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
                    labelText: 'Nombre del equipo',
                    hintText: 'Ejemplo: Mandil para laboratorio',
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
                  descripcion: 'Asocia el equipo con su tipo correspondiente.',
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

                        return DropdownButtonFormField<int>(
                          initialValue: _tipoEquipoProteccionId,
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

                const _InformacionRegistroCard(),
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

/// Encabezado visual utilizado para separar
/// las secciones del formulario.
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

/// Muestra información sobre los valores
/// que serán asignados inicialmente.
class _InformacionRegistroCard extends StatelessWidget {
  const _InformacionRegistroCard();

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
              'El código se generará automáticamente. '
              'El equipo será registrado como parte '
              'del catálogo general.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo mostrado mientras se cargan
/// los tipos de EPP.
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

/// Campo mostrado cuando ocurre un error
/// al cargar los tipos.
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

/// Campo mostrado cuando no existen
/// tipos de EPP activos.
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
