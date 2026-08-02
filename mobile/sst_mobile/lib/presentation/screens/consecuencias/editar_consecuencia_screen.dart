import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../providers/consecuencia_provider.dart';

/// Pantalla para editar una consecuencia existente.
///
/// Permite modificar:
///
/// - Nombre.
/// - Descripción.
/// - Clasificación.
/// - Incapacidad permanente.
/// - Fatalidad.
/// - Estado activo.
class EditarConsecuenciaScreen extends StatefulWidget {
  const EditarConsecuenciaScreen({
    super.key,
    required this.consecuencia,
    required this.usuarioActualizacionId,
  });

  /// Consecuencia que será editada.
  final ConsecuenciaModel consecuencia;

  /// Identificador del usuario que realiza la actualización.
  final int usuarioActualizacionId;

  @override
  State<EditarConsecuenciaScreen> createState() {
    return _EditarConsecuenciaScreenState();
  }
}

class _EditarConsecuenciaScreenState extends State<EditarConsecuenciaScreen> {
  /// Clave del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controladores de los campos.
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _clasificacionController;

  /// Valores actuales de las opciones.
  late bool _incapacidadPermanente;
  late bool _fatalidad;
  late bool _activo;

  /// Indica si la información se está guardando.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    // Carga en el formulario los datos actuales.
    _codigoController = TextEditingController(text: widget.consecuencia.codigo);

    _nombreController = TextEditingController(text: widget.consecuencia.nombre);

    _descripcionController = TextEditingController(
      text: widget.consecuencia.descripcion ?? '',
    );

    _clasificacionController = TextEditingController(
      text: widget.consecuencia.clasificacion ?? '',
    );

    _incapacidadPermanente = widget.consecuencia.incapacidadPermanente;

    _fatalidad = widget.consecuencia.fatalidad;
    _activo = widget.consecuencia.activo;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _clasificacionController.dispose();
    super.dispose();
  }

  /// Guarda los cambios en el backend.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    FocusScope.of(context).unfocus();

    final ConsecuenciaProvider provider = context.read<ConsecuenciaProvider>();

    setState(() {
      _guardando = true;
    });

    final ActualizarConsecuenciaRequest request = ActualizarConsecuenciaRequest(
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      clasificacion: _clasificacionController.text,
      incapacidadPermanente: _incapacidadPermanente,
      fatalidad: _fatalidad,
      activo: _activo,
      usuarioActualizacionId: widget.usuarioActualizacionId,
    );

    final bool actualizada = await provider.actualizarConsecuencia(
      widget.consecuencia.id,
      request,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (actualizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consecuencia actualizada correctamente.'),
        ),
      );

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ?? 'No se pudo actualizar la consecuencia.',
        ),
      ),
    );
  }

  /// Valida el nombre.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre de la consecuencia.';
    }

    if (texto.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
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

  /// Valida la clasificación.
  String? _validarClasificacion(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.length > 150) {
      return 'La clasificación no puede superar los 150 caracteres.';
    }

    return null;
  }

  /// Comprueba si el formulario fue modificado.
  bool _hayCambios() {
    final String nombreActual = _nombreController.text.trim();

    final String descripcionActual = _descripcionController.text.trim();

    final String clasificacionActual = _clasificacionController.text.trim();

    final String nombreOriginal = widget.consecuencia.nombre.trim();

    final String descripcionOriginal =
        widget.consecuencia.descripcion?.trim() ?? '';

    final String clasificacionOriginal =
        widget.consecuencia.clasificacion?.trim() ?? '';

    return nombreActual != nombreOriginal ||
        descripcionActual != descripcionOriginal ||
        clasificacionActual != clasificacionOriginal ||
        _incapacidadPermanente != widget.consecuencia.incapacidadPermanente ||
        _fatalidad != widget.consecuencia.fatalidad ||
        _activo != widget.consecuencia.activo;
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
        appBar: AppBar(title: const Text('Editar consecuencia')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoConsecuencia(
                  codigo: widget.consecuencia.codigo,
                  nombre: widget.consecuencia.nombre,
                ),

                const SizedBox(height: 22),

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
                  maxLength: 200,
                  validator: _validarNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la consecuencia',
                    prefixIcon: Icon(Icons.personal_injury_outlined),
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
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _clasificacionController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 150,
                  validator: _validarClasificacion,
                  decoration: const InputDecoration(
                    labelText: 'Clasificación',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const _TituloSeccion(
                  icono: Icons.health_and_safety_outlined,
                  titulo: 'Condiciones de gravedad',
                  descripcion: 'Actualiza las condiciones asociadas.',
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  value: _incapacidadPermanente,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _incapacidadPermanente = valor;
                          });
                        },
                  title: const Text('Incapacidad permanente'),
                  subtitle: const Text(
                    'Puede ocasionar una pérdida '
                    'permanente de capacidad.',
                  ),
                  secondary: const Icon(Icons.accessible_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                SwitchListTile(
                  value: _fatalidad,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _fatalidad = valor;
                          });
                        },
                  title: const Text('Fatalidad'),
                  subtitle: const Text('Puede ocasionar la muerte.'),
                  secondary: const Icon(Icons.warning_amber_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  value: _activo,
                  onChanged: _guardando
                      ? null
                      : (bool valor) {
                          setState(() {
                            _activo = valor;
                          });
                        },
                  title: const Text('Consecuencia activa'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible para usar en matrices IPERC.'
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
}

/// Encabezado que muestra el código y nombre actual.
class _EncabezadoConsecuencia extends StatelessWidget {
  const _EncabezadoConsecuencia({required this.codigo, required this.nombre});

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
              Icons.personal_injury_outlined,
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

/// Encabezado de una sección del formulario.
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
