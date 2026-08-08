import 'package:flutter/material.dart';

import '../../../data/models/rol_model.dart';
import '../../../data/repositories/rol_repository.dart';

/// Pantalla para consultar y administrar roles.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() {
    return _RolesScreenState();
  }
}

class _RolesScreenState extends State<RolesScreen> {
  final RolRepository _rolRepository = RolRepository();

  final TextEditingController _busquedaController = TextEditingController();

  List<RolModel> _roles = <RolModel>[];

  bool _cargando = true;
  bool _procesando = false;

  String? _error;
  String _busqueda = '';

  bool? _filtroGlobal;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<RolModel> get _rolesFiltrados {
    List<RolModel> resultado = _rolRepository.buscarEnLista(_roles, _busqueda);

    if (_filtroGlobal != null) {
      resultado = resultado
          .where((RolModel rol) => rol.esGlobal == _filtroGlobal)
          .toList();
    }

    return _rolRepository.ordenarPorNombre(resultado);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<RolModel> roles = await _rolRepository.obtenerTodos();

      if (!mounted) {
        return;
      }

      setState(() {
        _roles = roles;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _abrirNuevoRol() async {
    final _RolFormResult? resultado = await showDialog<_RolFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _RolFormDialog(titulo: 'Nuevo rol');
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _crearRol(resultado);
  }

  Future<void> _abrirEditarRol(RolModel rol) async {
    final _RolFormResult? resultado = await showDialog<_RolFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _RolFormDialog(titulo: 'Editar rol', rol: rol);
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _actualizarRol(rol, resultado);
  }

  Future<void> _crearRol(_RolFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _rolRepository.crear(
        codigo: datos.codigo,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        esGlobal: datos.esGlobal,
        usuarioRegistroId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Rol registrado correctamente.');

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _actualizarRol(RolModel rol, _RolFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _rolRepository.actualizar(
        id: rol.id,
        codigo: datos.codigo,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        activo: datos.activo,
        esGlobal: datos.esGlobal,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Rol actualizado correctamente.');

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _cambiarEstado(RolModel rol) async {
    final bool nuevoEstado = !rol.activo;

    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(nuevoEstado ? 'Activar rol' : 'Desactivar rol'),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar el rol "${rol.nombre}"?'
                : '¿Deseas desactivar el rol "${rol.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(nuevoEstado ? 'Activar' : 'Desactivar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      await _rolRepository.cambiarEstado(
        id: rol.id,
        activo: nuevoEstado,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        nuevoEstado
            ? 'Rol activado correctamente.'
            : 'Rol desactivado correctamente.',
      );

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar(RolModel rol) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar rol'),
          content: Text('¿Deseas eliminar el rol "${rol.nombre}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _rolRepository.eliminar(
        id: rol.id,
        usuarioId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(mensaje);

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
          content: Text(mensaje),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<RolModel> roles = _rolesFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : _abrirNuevoRol,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo rol'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: Column(
              children: <Widget>[
                _construirResumen(),
                _construirFiltros(),
                Expanded(child: _construirContenido(roles)),
              ],
            ),
          ),
          if (_procesando)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirResumen() {
    final int globales = _roles.where((RolModel rol) => rol.esGlobal).length;

    final int locales = _roles.length - globales;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(child: Icon(Icons.admin_panel_settings_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Roles del sistema',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_roles.length} roles '
                  '• $globales globales '
                  '• $locales locales',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _busquedaController,
            onChanged: (String value) {
              setState(() {
                _busqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar código, nombre o descripción',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _busquedaController.clear();

                        setState(() {
                          _busqueda = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool?>(
            key: ValueKey<bool?>(_filtroGlobal),
            initialValue: _filtroGlobal,
            decoration: const InputDecoration(
              labelText: 'Filtrar por alcance',
              prefixIcon: Icon(Icons.public_outlined),
              border: OutlineInputBorder(),
            ),
            items: const <DropdownMenuItem<bool?>>[
              DropdownMenuItem<bool?>(
                value: null,
                child: Text('Todos los roles'),
              ),
              DropdownMenuItem<bool?>(
                value: true,
                child: Text('Roles globales'),
              ),
              DropdownMenuItem<bool?>(
                value: false,
                child: Text('Roles de institución'),
              ),
            ],
            onChanged: (bool? value) {
              setState(() {
                _filtroGlobal = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(List<RolModel> roles) {
    if (_cargando && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _roles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 50),
          const Icon(Icons.cloud_off_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los roles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    if (roles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.admin_panel_settings_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            _roles.isEmpty
                ? 'No hay roles registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: roles.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final RolModel rol = roles[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            leading: CircleAvatar(
              child: Icon(rol.esGlobal ? Icons.public : Icons.apartment),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    rol.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!rol.activo)
                  const Chip(
                    label: Text('Inactivo'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            subtitle: Text(
              <String>[
                'Código: ${rol.codigo}',
                if (rol.descripcion.isNotEmpty) rol.descripcion,
                rol.esGlobal ? 'Alcance: Global' : 'Alcance: Institución',
              ].join('\n'),
            ),
            trailing: PopupMenuButton<String>(
              enabled: !_procesando,
              tooltip: 'Opciones',
              onSelected: (String opcion) {
                switch (opcion) {
                  case 'editar':
                    _abrirEditarRol(rol);
                    break;

                  case 'estado':
                    _cambiarEstado(rol);
                    break;

                  case 'eliminar':
                    _confirmarEliminar(rol);
                    break;
                }
              },
              itemBuilder: (_) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'estado',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        rol.activo
                            ? Icons.toggle_off_outlined
                            : Icons.toggle_on_outlined,
                      ),
                      title: Text(rol.activo ? 'Desactivar' : 'Activar'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'eliminar',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
                    ),
                  ),
                ];
              },
            ),
          ),
        );
      },
    );
  }

  String _obtenerMensajeError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'DioException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}

class _RolFormDialog extends StatefulWidget {
  const _RolFormDialog({required this.titulo, this.rol});

  final String titulo;
  final RolModel? rol;

  @override
  State<_RolFormDialog> createState() {
    return _RolFormDialogState();
  }
}

class _RolFormDialogState extends State<_RolFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoController;

  late final TextEditingController _nombreController;

  late final TextEditingController _descripcionController;

  bool _activo = true;
  bool _esGlobal = false;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(text: widget.rol?.codigo ?? '');

    _nombreController = TextEditingController(text: widget.rol?.nombre ?? '');

    _descripcionController = TextEditingController(
      text: widget.rol?.descripcion ?? '',
    );

    _activo = widget.rol?.activo ?? true;
    _esGlobal = widget.rol?.esGlobal ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _RolFormResult(
        codigo: _codigoController.text.trim().toUpperCase(),
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        activo: _activo,
        esGlobal: _esGlobal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.rol != null;

    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _codigoController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Código del rol',
                    hintText: 'Ej.: SUP_TITULAR',
                    prefixIcon: Icon(Icons.key_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    final String codigo = value?.trim() ?? '';

                    if (codigo.isEmpty) {
                      return 'Ingresa el código del rol.';
                    }

                    if (codigo.length < 2) {
                      return 'El código debe tener al menos 2 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del rol',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    final String nombre = value?.trim() ?? '';

                    if (nombre.isEmpty) {
                      return 'Ingresa el nombre del rol.';
                    }

                    if (nombre.length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcionController,
                  maxLength: 300,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rol global'),
                  subtitle: Text(
                    _esGlobal
                        ? 'El rol tiene alcance sobre toda la plataforma.'
                        : 'El rol pertenece al ámbito de una institución.',
                  ),
                  value: _esGlobal,
                  onChanged: (bool value) {
                    setState(() {
                      _esGlobal = value;
                    });
                  },
                ),
                if (editando)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    subtitle: Text(
                      _activo
                          ? 'El rol está disponible.'
                          : 'El rol está desactivado.',
                    ),
                    value: _activo,
                    onChanged: (bool value) {
                      setState(() {
                        _activo = value;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardar,
          icon: Icon(editando ? Icons.save_outlined : Icons.add),
          label: Text(editando ? 'Guardar' : 'Registrar'),
        ),
      ],
    );
  }
}

class _RolFormResult {
  const _RolFormResult({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.esGlobal,
  });

  final String codigo;
  final String nombre;
  final String descripcion;
  final bool activo;
  final bool esGlobal;
}
