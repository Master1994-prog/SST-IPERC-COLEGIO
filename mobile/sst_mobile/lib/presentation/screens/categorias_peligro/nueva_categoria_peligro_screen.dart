import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/categoria_peligro_model.dart';
import '../../providers/categoria_peligro_provider.dart';

/// Pantalla para registrar una nueva categoría de peligro.
class NuevaCategoriaPeligroScreen extends StatefulWidget {
  const NuevaCategoriaPeligroScreen({super.key});

  @override
  State<NuevaCategoriaPeligroScreen> createState() {
    return _NuevaCategoriaPeligroScreenState();
  }
}

class _NuevaCategoriaPeligroScreenState
    extends State<NuevaCategoriaPeligroScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  int _ordenSeleccionado = 1;
  int _ordenInicial = 1;
  String _colorSeleccionado = '#FF9800';
  String _iconoSeleccionado = 'warning';

  bool _activo = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final CategoriaPeligroProvider provider = context
        .read<CategoriaPeligroProvider>();

    final int siguienteOrden = _generarSiguienteOrden(provider.categorias);

    _ordenSeleccionado = siguienteOrden;
    _ordenInicial = siguienteOrden;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  /// Valida y registra la nueva categoría.
  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    FocusScope.of(context).unfocus();

    final CategoriaPeligroProvider provider = context
        .read<CategoriaPeligroProvider>();

    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _guardando = true;
    });

    final CrearCategoriaPeligroRequest request = CrearCategoriaPeligroRequest(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      color: _colorSeleccionado,
      icono: _iconoSeleccionado,
      orden: _ordenSeleccionado,
      activo: _activo,
    );

    final bool creada = await provider.crearCategoria(request);

    if (!mounted) {
      return;
    }

    setState(() {
      _guardando = false;
    });

    if (creada) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Categoría de peligro registrada correctamente.'),
          ),
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
            provider.mensajeError ??
                'No se pudo registrar la categoría de peligro.',
          ),
        ),
      );
  }

  /// Valida el nombre.
  String? _validarNombre(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Ingresa el nombre de la categoría.';
    }

    if (texto.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
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

  /// Verifica si el formulario tiene información modificada.
  bool _hayCambios() {
    return _nombreController.text.trim().isNotEmpty ||
        _descripcionController.text.trim().isNotEmpty ||
        _ordenSeleccionado != _ordenInicial ||
        _colorSeleccionado != '#FF9800' ||
        _iconoSeleccionado != 'warning' ||
        !_activo;
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
        appBar: AppBar(title: const Text('Nueva categoría de peligro')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _EncabezadoFormulario(
                  color: _colorSeleccionado,
                  icono: _iconoSeleccionado,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: _validarNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    hintText: 'Ejemplo: Peligros físicos',
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
                        'Describe los peligros que pertenecen a esta categoría.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _ordenSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Orden de presentación',
                    helperText:
                        'Selecciona la posición de la categoría en los listados.',
                    prefixIcon: Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(),
                  ),
                  items: _opcionesOrden.map((int orden) {
                    return DropdownMenuItem<int>(
                      value: orden,
                      child: Text('Orden $orden'),
                    );
                  }).toList(),
                  onChanged: _guardando
                      ? null
                      : (int? valor) {
                          if (valor == null) {
                            return;
                          }

                          setState(() {
                            _ordenSeleccionado = valor;
                          });
                        },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _colorSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    helperText: 'Selecciona un color para identificarla.',
                    prefixIcon: Icon(Icons.palette_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _opcionesColor.map((_OpcionColor opcion) {
                    return DropdownMenuItem<String>(
                      value: opcion.valor,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: opcion.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(opcion.nombre)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _guardando
                      ? null
                      : (String? valor) {
                          if (valor == null) {
                            return;
                          }

                          setState(() {
                            _colorSeleccionado = valor;
                          });
                        },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _iconoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Icono',
                    helperText: 'Selecciona un icono para la categoría.',
                    prefixIcon: Icon(Icons.insert_emoticon_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _opcionesIcono.map((_OpcionIcono opcion) {
                    return DropdownMenuItem<String>(
                      value: opcion.valor,
                      child: Row(
                        children: <Widget>[
                          Icon(opcion.icono),
                          const SizedBox(width: 10),
                          Expanded(child: Text(opcion.nombre)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _guardando
                      ? null
                      : (String? valor) {
                          if (valor == null) {
                            return;
                          }

                          setState(() {
                            _iconoSeleccionado = valor;
                          });
                        },
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
                  title: const Text('Categoría activa'),
                  subtitle: Text(
                    _activo
                        ? 'Disponible para asociar tipos de peligro.'
                        : 'No estará disponible para nuevos registros.',
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

/// Encabezado visual del formulario.
class _EncabezadoFormulario extends StatelessWidget {
  const _EncabezadoFormulario({required this.color, required this.icono});

  final String color;
  final String icono;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _buscarColor(color).color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _buscarIcono(icono).icono,
            color: colorScheme.onPrimaryContainer,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Información de la categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Las categorías permiten organizar '
                'los diferentes tipos de peligro SST.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta informativa del formulario.
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
              'Ejemplos de categorías: peligros de seguridad, '
              'peligros ambientales, peligros ocupacionales '
              'y peligros relacionados con emergencias.',
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionColor {
  const _OpcionColor({
    required this.nombre,
    required this.valor,
    required this.color,
  });

  final String nombre;
  final String valor;
  final Color color;
}

class _OpcionIcono {
  const _OpcionIcono({
    required this.nombre,
    required this.valor,
    required this.icono,
  });

  final String nombre;
  final String valor;
  final IconData icono;
}

final List<int> _opcionesOrden = List<int>.generate(20, (int index) {
  return index + 1;
});

int _generarSiguienteOrden(List<CategoriaPeligroModel> categorias) {
  if (categorias.isEmpty) {
    return 1;
  }

  final int mayorOrden = categorias
      .map((CategoriaPeligroModel categoria) {
        return categoria.orden;
      })
      .where((int orden) {
        return orden > 0;
      })
      .fold<int>(0, (int mayor, int orden) {
        return orden > mayor ? orden : mayor;
      });

  final int siguienteOrden = mayorOrden + 1;

  if (_opcionesOrden.contains(siguienteOrden)) {
    return siguienteOrden;
  }

  return _opcionesOrden.last;
}

const List<_OpcionColor> _opcionesColor = <_OpcionColor>[
  _OpcionColor(nombre: 'Naranja', valor: '#FF9800', color: Colors.orange),
  _OpcionColor(nombre: 'Rojo', valor: '#F44336', color: Colors.red),
  _OpcionColor(nombre: 'Amarillo', valor: '#FFC107', color: Colors.amber),
  _OpcionColor(nombre: 'Verde', valor: '#4CAF50', color: Colors.green),
  _OpcionColor(nombre: 'Azul', valor: '#2196F3', color: Colors.blue),
  _OpcionColor(nombre: 'Morado', valor: '#9C27B0', color: Colors.purple),
  _OpcionColor(nombre: 'Gris', valor: '#607D8B', color: Colors.blueGrey),
  _OpcionColor(nombre: 'Negro', valor: '#212121', color: Colors.black87),
];

const List<_OpcionIcono> _opcionesIcono = <_OpcionIcono>[
  _OpcionIcono(
    nombre: 'Advertencia',
    valor: 'warning',
    icono: Icons.warning_amber_outlined,
  ),
  _OpcionIcono(
    nombre: 'Categoría',
    valor: 'category',
    icono: Icons.category_outlined,
  ),
  _OpcionIcono(
    nombre: 'Seguridad',
    valor: 'security',
    icono: Icons.security_outlined,
  ),
  _OpcionIcono(
    nombre: 'Salud',
    valor: 'health_and_safety',
    icono: Icons.health_and_safety_outlined,
  ),
  _OpcionIcono(
    nombre: 'Fuego',
    valor: 'local_fire_department',
    icono: Icons.local_fire_department_outlined,
  ),
  _OpcionIcono(
    nombre: 'Electricidad',
    valor: 'bolt',
    icono: Icons.bolt_outlined,
  ),
  _OpcionIcono(
    nombre: 'Químico',
    valor: 'science',
    icono: Icons.science_outlined,
  ),
  _OpcionIcono(nombre: 'Ambiente', valor: 'eco', icono: Icons.eco_outlined),
  _OpcionIcono(nombre: 'Persona', valor: 'person', icono: Icons.person_outline),
  _OpcionIcono(
    nombre: 'Construcción',
    valor: 'construction',
    icono: Icons.construction_outlined,
  ),
];

_OpcionColor _buscarColor(String valor) {
  return _opcionesColor.firstWhere(
    (_OpcionColor opcion) {
      return opcion.valor == valor;
    },
    orElse: () {
      return _opcionesColor.first;
    },
  );
}

_OpcionIcono _buscarIcono(String valor) {
  return _opcionesIcono.firstWhere(
    (_OpcionIcono opcion) {
      return opcion.valor == valor;
    },
    orElse: () {
      return _opcionesIcono.first;
    },
  );
}
