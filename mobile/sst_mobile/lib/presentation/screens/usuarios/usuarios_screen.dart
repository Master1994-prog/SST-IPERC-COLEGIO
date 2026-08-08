import 'package:flutter/material.dart';

import '../../../data/models/area_model.dart';
import '../../../data/models/institucion_model.dart';
import '../../../data/models/rol_model.dart';
import '../../../data/models/sede_model.dart';
import '../../../data/models/usuario_model.dart';

import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/institucion_repository.dart';
import '../../../data/repositories/rol_repository.dart';
import '../../../data/repositories/sede_repository.dart';
import '../../../data/repositories/usuario_repository.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() {
    return _UsuariosScreenState();
  }
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final RolRepository _rolRepository = RolRepository();

  final InstitucionRepository _institucionRepository = InstitucionRepository();

  final SedeRepository _sedeRepository = SedeRepository();

  final AreaRepository _areaRepository = AreaRepository();

  final TextEditingController _busquedaController = TextEditingController();

  List<UsuarioModel> _usuarios = <UsuarioModel>[];
  List<RolModel> _roles = <RolModel>[];
  List<InstitucionModel> _instituciones = <InstitucionModel>[];
  List<SedeModel> _sedes = <SedeModel>[];
  List<AreaModel> _areas = <AreaModel>[];

  bool _cargando = true;
  bool _procesando = false;

  String? _error;
  String _busqueda = '';

  int? _rolFiltroId;

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

  List<UsuarioModel> get _usuariosFiltrados {
    List<UsuarioModel> resultado = _usuarioRepository.buscarEnLista(
      _usuarios,
      _busqueda,
    );

    resultado = _usuarioRepository.filtrarPorRol(
      resultado,
      rolId: _rolFiltroId,
    );

    return _usuarioRepository.ordenarPorNombre(resultado);
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
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _usuarioRepository.obtenerTodos(),
            _rolRepository.obtenerTodos(),
            _institucionRepository.obtenerTodas(),
            _sedeRepository.obtenerTodas(),
            _areaRepository.obtenerTodas(),
          ]);

      final List<UsuarioModel> usuarios = resultados[0] as List<UsuarioModel>;

      final List<RolModel> roles = resultados[1] as List<RolModel>;

      final List<InstitucionModel> instituciones =
          resultados[2] as List<InstitucionModel>;

      final List<SedeModel> sedes = resultados[3] as List<SedeModel>;

      final List<AreaModel> areas = resultados[4] as List<AreaModel>;

      roles.sort(
        (RolModel a, RolModel b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      instituciones.sort(
        (InstitucionModel a, InstitucionModel b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      sedes.sort(
        (SedeModel a, SedeModel b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      areas.sort(
        (AreaModel a, AreaModel b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = usuarios;
        _roles = roles;
        _instituciones = instituciones;
        _sedes = sedes;
        _areas = areas;

        if (_rolFiltroId != null &&
            !_roles.any((RolModel rol) => rol.id == _rolFiltroId)) {
          _rolFiltroId = null;
        }
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

  Future<void> _abrirNuevoUsuario() async {
    if (_instituciones.isEmpty) {
      _mostrarMensaje('No existen instituciones disponibles.', esError: true);
      return;
    }

    if (_roles.isEmpty) {
      _mostrarMensaje('No existen roles disponibles.', esError: true);
      return;
    }

    final _UsuarioFormResult? resultado = await Navigator.of(context)
        .push<_UsuarioFormResult>(
          MaterialPageRoute<_UsuarioFormResult>(
            builder: (_) {
              return _UsuarioFormScreen(
                titulo: 'Nuevo usuario',
                instituciones: _instituciones,
                sedes: _sedes,
                areas: _areas,
                roles: _roles,
              );
            },
          ),
        );

    if (resultado == null || !mounted) {
      return;
    }

    await _crearUsuario(resultado);
  }

  Future<void> _abrirEditarUsuario(UsuarioModel usuario) async {
    final _UsuarioFormResult? resultado = await Navigator.of(context)
        .push<_UsuarioFormResult>(
          MaterialPageRoute<_UsuarioFormResult>(
            builder: (_) {
              return _UsuarioFormScreen(
                titulo: 'Editar usuario',
                instituciones: _instituciones,
                sedes: _sedes,
                areas: _areas,
                roles: _roles,
                usuario: usuario,
              );
            },
          ),
        );

    if (resultado == null || !mounted) {
      return;
    }

    await _actualizarUsuario(usuario, resultado);
  }

  Future<void> _crearUsuario(_UsuarioFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _usuarioRepository.crear(
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        numeroDocumento: datos.numeroDocumento,
        tipoDocumento: datos.tipoDocumento,
        correo: datos.correo,
        telefono: datos.telefono,
        nombreUsuario: datos.nombreUsuario,
        password: datos.password,
        institucionId: datos.institucionId,
        sedeId: datos.sedeId,
        areaId: datos.areaId,
        rolIds: datos.rolIds,
        debeCambiarPassword: datos.debeCambiarPassword,
        usuarioRegistroId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Usuario registrado correctamente.');

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

  Future<void> _actualizarUsuario(
    UsuarioModel usuario,
    _UsuarioFormResult datos,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _usuarioRepository.actualizar(
        id: usuario.id,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        numeroDocumento: datos.numeroDocumento,
        tipoDocumento: datos.tipoDocumento,
        correo: datos.correo,
        telefono: datos.telefono,
        nombreUsuario: datos.nombreUsuario,
        institucionId: datos.institucionId,
        sedeId: datos.sedeId,
        areaId: datos.areaId,
        activo: datos.activo,
        usuarioActualizacionId: 1,
      );

      await _usuarioRepository.actualizarRoles(
        id: usuario.id,
        rolIds: datos.rolIds,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Usuario actualizado correctamente.');

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

  Future<void> _abrirCambiarPassword(UsuarioModel usuario) async {
    final _PasswordResult? resultado = await showDialog<_PasswordResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CambiarPasswordDialog(usuario: usuario);
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _usuarioRepository.cambiarPassword(
        id: usuario.id,
        nuevaPassword: resultado.password,
        debeCambiarPassword: resultado.debeCambiarPassword,
        usuarioActualizacionId: 1,
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

  Future<void> _cambiarEstado(UsuarioModel usuario) async {
    final bool nuevoEstado = !usuario.activo;

    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(nuevoEstado ? 'Activar usuario' : 'Desactivar usuario'),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar a "${usuario.nombreVisible}"?'
                : '¿Deseas desactivar a "${usuario.nombreVisible}"?',
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
      final String mensaje = await _usuarioRepository.cambiarEstado(
        id: usuario.id,
        activo: nuevoEstado,
        usuarioActualizacionId: 1,
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

  Future<void> _confirmarEliminar(UsuarioModel usuario) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Deseas eliminar al usuario '
            '"${usuario.nombreVisible}"?\n\n'
            'Esta operación realizará una '
            'eliminación lógica.',
          ),
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
      final String mensaje = await _usuarioRepository.eliminar(
        id: usuario.id,
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
    final List<UsuarioModel> usuarios = _usuariosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : _abrirNuevoUsuario,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo usuario'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: Column(
              children: <Widget>[
                _construirResumen(),
                _construirFiltros(),
                Expanded(child: _construirContenido(usuarios)),
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
    final int activos = _usuarios
        .where((UsuarioModel usuario) => usuario.activo)
        .length;

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
          const CircleAvatar(child: Icon(Icons.people_alt_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Usuarios del sistema',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_usuarios.length} registrados '
                  '• $activos activos',
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
              hintText: 'Buscar nombre, usuario, DNI, correo o rol',
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
          DropdownButtonFormField<int?>(
            key: ValueKey<int?>(_rolFiltroId),
            initialValue: _rolFiltroId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filtrar por rol',
              prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los roles'),
              ),
              ..._roles.map((RolModel rol) {
                return DropdownMenuItem<int?>(
                  value: rol.id,
                  child: Text(rol.nombre),
                );
              }),
            ],
            onChanged: (int? value) {
              setState(() {
                _rolFiltroId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(List<UsuarioModel> usuarios) {
    if (_cargando && _usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _usuarios.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 50),
          const Icon(Icons.cloud_off_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los usuarios',
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

    if (usuarios.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.people_outline, size: 70),
          const SizedBox(height: 16),
          Text(
            _usuarios.isEmpty
                ? 'No hay usuarios registrados'
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
      itemCount: usuarios.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final UsuarioModel usuario = usuarios[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            leading: CircleAvatar(child: Text(_inicialUsuario(usuario))),
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    usuario.nombreVisible,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!usuario.activo)
                  const Chip(
                    label: Text('Inactivo'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            subtitle: Text(
              <String>[
                'Usuario: ${usuario.nombreUsuario}',
                'Rol: ${usuario.rolesTexto}',
                if (usuario.numeroDocumento.isNotEmpty)
                  '${usuario.tipoDocumento.isEmpty ? 'Documento' : usuario.tipoDocumento}: '
                      '${usuario.numeroDocumento}',
                if (usuario.correo.isNotEmpty) usuario.correo,
              ].join('\n'),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              enabled: !_procesando,
              onSelected: (String opcion) {
                switch (opcion) {
                  case 'editar':
                    _abrirEditarUsuario(usuario);
                    break;

                  case 'password':
                    _abrirCambiarPassword(usuario);
                    break;

                  case 'estado':
                    _cambiarEstado(usuario);
                    break;

                  case 'eliminar':
                    _confirmarEliminar(usuario);
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
                  const PopupMenuItem<String>(
                    value: 'password',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.password_outlined),
                      title: Text('Cambiar contraseña'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'estado',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        usuario.activo
                            ? Icons.person_off_outlined
                            : Icons.person_outline,
                      ),
                      title: Text(usuario.activo ? 'Desactivar' : 'Activar'),
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

  String _inicialUsuario(UsuarioModel usuario) {
    final String texto = usuario.nombreVisible.trim();

    if (texto.isEmpty) {
      return '?';
    }

    return texto.substring(0, 1).toUpperCase();
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

class _UsuarioFormScreen extends StatefulWidget {
  const _UsuarioFormScreen({
    required this.titulo,
    required this.instituciones,
    required this.sedes,
    required this.areas,
    required this.roles,
    this.usuario,
  });

  final String titulo;

  final List<InstitucionModel> instituciones;

  final List<SedeModel> sedes;
  final List<AreaModel> areas;
  final List<RolModel> roles;

  final UsuarioModel? usuario;

  @override
  State<_UsuarioFormScreen> createState() {
    return _UsuarioFormScreenState();
  }
}

class _UsuarioFormScreenState extends State<_UsuarioFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombresController;

  late final TextEditingController _apellidosController;

  late final TextEditingController _numeroDocumentoController;

  late final TextEditingController _correoController;

  late final TextEditingController _telefonoController;

  late final TextEditingController _nombreUsuarioController;

  late final TextEditingController _passwordController;

  int? _institucionId;
  int? _sedeId;
  int? _areaId;

  String _tipoDocumento = 'DNI';

  final Set<int> _rolIds = <int>{};

  bool _activo = true;

  bool _debeCambiarPassword = true;

  bool _ocultarPassword = true;

  bool get _editando => widget.usuario != null;

  List<SedeModel> get _sedesDisponibles {
    if (_institucionId == null) {
      return <SedeModel>[];
    }

    return widget.sedes
        .where((SedeModel sede) => sede.institucionId == _institucionId)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    final UsuarioModel? usuario = widget.usuario;

    _nombresController = TextEditingController(text: usuario?.nombres ?? '');

    _apellidosController = TextEditingController(
      text: usuario?.apellidos ?? '',
    );

    _numeroDocumentoController = TextEditingController(
      text: usuario?.numeroDocumento ?? '',
    );

    _correoController = TextEditingController(text: usuario?.correo ?? '');

    _telefonoController = TextEditingController(text: usuario?.telefono ?? '');

    _nombreUsuarioController = TextEditingController(
      text: usuario?.nombreUsuario ?? '',
    );

    _passwordController = TextEditingController();

    if (usuario != null) {
      _institucionId = usuario.institucionId;

      _sedeId = usuario.sedeId;
      _areaId = usuario.areaId;

      _activo = usuario.activo;

      _tipoDocumento = usuario.tipoDocumento.trim().isEmpty
          ? 'DNI'
          : usuario.tipoDocumento;

      _rolIds.addAll(usuario.rolIds);
    } else {
      _institucionId = widget.instituciones.isEmpty
          ? null
          : widget.instituciones.first.id;
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _nombreUsuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_institucionId == null || _institucionId! <= 0) {
      _mostrarError('Selecciona una institución.');
      return;
    }

    if (_rolIds.isEmpty) {
      _mostrarError('Selecciona al menos un rol.');
      return;
    }

    Navigator.of(context).pop(
      _UsuarioFormResult(
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        numeroDocumento: _numeroDocumentoController.text.trim(),
        tipoDocumento: _tipoDocumento,
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        nombreUsuario: _nombreUsuarioController.text.trim(),
        password: _passwordController.text,
        institucionId: _institucionId!,
        sedeId: _sedeId,
        areaId: _areaId,
        rolIds: _rolIds.toList(),
        activo: _activo,
        debeCambiarPassword: _debeCambiarPassword,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final List<SedeModel> sedes = _sedesDisponibles;

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _tituloSeccion('Datos personales', Icons.person_outline),

              TextFormField(
                controller: _nombresController,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Ingresa los nombres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _apellidosController,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Ingresa los apellidos.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _tipoDocumento,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'DNI', child: Text('DNI')),
                  DropdownMenuItem<String>(
                    value: 'CE',
                    child: Text('Carné de extranjería'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'PASAPORTE',
                    child: Text('Pasaporte'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _tipoDocumento = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _numeroDocumentoController,
                keyboardType: TextInputType.number,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  final String texto = value?.trim() ?? '';

                  if (texto.isEmpty) {
                    return null;
                  }

                  if (!texto.contains('@')) {
                    return 'Ingresa un correo válido.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              _tituloSeccion('Organización', Icons.apartment_outlined),

              DropdownButtonFormField<int>(
                initialValue: _institucionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Institución',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.instituciones.map((InstitucionModel institucion) {
                  return DropdownMenuItem<int>(
                    value: institucion.id,
                    child: Text(
                      institucion.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _institucionId = value;

                    if (_sedeId != null &&
                        !widget.sedes.any(
                          (SedeModel sede) =>
                              sede.id == _sedeId && sede.institucionId == value,
                        )) {
                      _sedeId = null;
                    }
                  });
                },
                validator: (int? value) {
                  if (value == null || value <= 0) {
                    return 'Selecciona una institución.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int?>(
                key: ValueKey<String>('$_institucionId-$_sedeId'),
                initialValue: sedes.any((SedeModel sede) => sede.id == _sedeId)
                    ? _sedeId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sede (opcional)',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin sede'),
                  ),
                  ...sedes.map((SedeModel sede) {
                    return DropdownMenuItem<int?>(
                      value: sede.id,
                      child: Text(sede.nombre, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _sedeId = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int?>(
                initialValue:
                    widget.areas.any((AreaModel area) => area.id == _areaId)
                    ? _areaId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Área (opcional)',
                  prefixIcon: Icon(Icons.business_center_outlined),
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin área'),
                  ),
                  ...widget.areas.map((AreaModel area) {
                    return DropdownMenuItem<int?>(
                      value: area.id,
                      child: Text(area.nombre, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _areaId = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              _tituloSeccion(
                'Rol del usuario',
                Icons.admin_panel_settings_outlined,
              ),

              ...widget.roles.map((RolModel rol) {
                return CheckboxListTile(
                  value: _rolIds.contains(rol.id),
                  title: Text(rol.nombre),
                  subtitle: Text(
                    '${rol.codigo}'
                    '${rol.esGlobal ? ' • Global' : ''}',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _rolIds.add(rol.id);
                      } else {
                        _rolIds.remove(rol.id);
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 24),

              _tituloSeccion('Acceso al sistema', Icons.lock_outline),

              TextFormField(
                controller: _nombreUsuarioController,
                autocorrect: false,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().length < 4) {
                    return 'Debe tener al menos 4 caracteres.';
                  }

                  return null;
                },
              ),

              if (!_editando) ...<Widget>[
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Contraseña temporal',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _ocultarPassword = !_ocultarPassword;
                        });
                      },
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if ((value ?? '').length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres.';
                    }

                    return null;
                  },
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cambiar contraseña al ingresar'),
                  subtitle: const Text(
                    'El usuario deberá cambiar la contraseña temporal.',
                  ),
                  value: _debeCambiarPassword,
                  onChanged: (bool value) {
                    setState(() {
                      _debeCambiarPassword = value;
                    });
                  },
                ),
              ],

              if (_editando)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usuario activo'),
                  subtitle: Text(
                    _activo
                        ? 'El usuario puede acceder al sistema.'
                        : 'El acceso del usuario está deshabilitado.',
                  ),
                  value: _activo,
                  onChanged: (bool value) {
                    setState(() {
                      _activo = value;
                    });
                  },
                ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _guardar,
                icon: Icon(
                  _editando ? Icons.save_outlined : Icons.person_add_alt_1,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _editando ? 'Guardar cambios' : 'Registrar usuario',
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: <Widget>[
          Icon(icono),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog({required this.usuario});

  final UsuarioModel usuario;

  @override
  State<_CambiarPasswordDialog> createState() {
    return _CambiarPasswordDialogState();
  }
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmarController = TextEditingController();

  bool _debeCambiar = true;
  bool _ocultar = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _PasswordResult(
        password: _passwordController.text,
        debeCambiarPassword: _debeCambiar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(widget.usuario.nombreVisible),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _ocultar,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _ocultar = !_ocultar;
                      });
                    },
                    icon: Icon(
                      _ocultar
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if ((value ?? '').length < 8) {
                    return 'Debe tener al menos 8 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _confirmarController,
                obscureText: _ocultar,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_reset),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden.';
                  }

                  return null;
                },
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _debeCambiar,
                title: const Text('Solicitar cambio al ingresar'),
                onChanged: (bool value) {
                  setState(() {
                    _debeCambiar = value;
                  });
                },
              ),
            ],
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
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _UsuarioFormResult {
  const _UsuarioFormResult({
    required this.nombres,
    required this.apellidos,
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.correo,
    required this.telefono,
    required this.nombreUsuario,
    required this.password,
    required this.institucionId,
    required this.sedeId,
    required this.areaId,
    required this.rolIds,
    required this.activo,
    required this.debeCambiarPassword,
  });

  final String nombres;
  final String apellidos;

  final String numeroDocumento;
  final String tipoDocumento;

  final String correo;
  final String telefono;

  final String nombreUsuario;
  final String password;

  final int institucionId;
  final int? sedeId;
  final int? areaId;

  final List<int> rolIds;

  final bool activo;
  final bool debeCambiarPassword;
}

class _PasswordResult {
  const _PasswordResult({
    required this.password,
    required this.debeCambiarPassword,
  });

  final String password;
  final bool debeCambiarPassword;
}
