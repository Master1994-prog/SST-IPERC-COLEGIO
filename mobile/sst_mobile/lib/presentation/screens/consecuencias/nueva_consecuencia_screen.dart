import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../providers/consecuencia_provider.dart';

/// Pantalla para registrar una nueva consecuencia.
///
/// Permite ingresar:
///
/// - Nombre.
/// - Descripción.
/// - Clasificación.
/// - Incapacidad permanente.
/// - Fatalidad.
/// - Estado activo.
class NuevaConsecuenciaScreen extends StatefulWidget {
  const NuevaConsecuenciaScreen({super.key, required this.usuarioRegistroId});

  /// Identificador del usuario que registra.
  final int usuarioRegistroId;

  @override
  State<NuevaConsecuenciaScreen> createState() {
    return _NuevaConsecuenciaScreenState();
  }
}

class _NuevaConsecuenciaScreenState extends State<NuevaConsecuenciaScreen> {
  /// Clave del formulario.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controladores de los campos.
  final TextEditingController _codigoController = TextEditingController();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  final TextEditingController _clasificacionController =
      TextEditingController();

  /// Estado de las opciones.
  bool _incapacidadPermanente = false;
  bool _fatalidad = false;
  bool _activo = true;

  /// Indica si se está guardando.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final ConsecuenciaProvider provider = context.read<ConsecuenciaProvider>();
    _codigoController.text = _generarCodigoConsecuencia(
      provider.consecuencias,
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _clasificacionController.dispose();
    super.dispose();
  }

  /// Genera un código correlativo con el formato CONS-001.
  String _generarCodigoConsecuencia(List<ConsecuenciaModel> consecuencias) {
    final RegExp expresion = RegExp(r'^CONS-(\d+)$', caseSensitive: false);

    int mayorNumero = 0;

    for (final ConsecuenciaModel consecuencia in consecuencias) {
      final RegExpMatch? coincidencia = expresion.firstMatch(
        consecuencia.codigo.trim(),
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
    final String correlativo = siguienteNumero.toString().padLeft(3, '0');

    return 'CONS-$correlativo';
  }

  /// Registra la consecuencia.
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

    final CrearConsecuenciaRequest request = CrearConsecuenciaRequest(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      clasificacion: _clasificacionController.text,
      incapacidadPermanente: _incapacidadPermanente,
      fatalidad: _fatalidad,
      activo: _activo,
      usuarioRegistroId: widget.usuarioRegistroId,
    );

    final bool creada = await provider.crearConsecuencia(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (creada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consecuencia registrada correctamente.')),
      );

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ?? 'No se pudo registrar la consecuencia.',
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

  /// Comprueba si el usuario modificó el formulario.
  bool _tieneCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _clasificacionController.text.trim().isNotEmpty ||
        _incapacidadPermanente ||
        _fatalidad ||
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
        appBar: AppBar(title: const Text('Nueva consecuencia')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                const _TituloSeccion(
                  icono: Icons.personal_injury_outlined,
                  titulo: 'Información de la consecuencia',
                  descripcion: 'Registra los datos principales.',
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _codigoController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Código generado',
                    helperText: 'El código se genera automáticamente.',
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
                    hintText: 'Ejemplo: Fractura',
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
                    hintText: 'Describe la consecuencia.',
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
                    hintText: 'Ejemplo: Lesión grave',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const _TituloSeccion(
                  icono: Icons.health_and_safety_outlined,
                  titulo: 'Condiciones de gravedad',
                  descripcion: 'Indica el nivel de consecuencia.',
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
                    'Puede ocasionar pérdida permanente '
                    'de una capacidad.',
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

/// Encabezado de cada sección del formulario.
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
