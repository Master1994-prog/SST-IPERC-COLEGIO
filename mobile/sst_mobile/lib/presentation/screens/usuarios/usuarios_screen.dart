import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';

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

/// ===============================================================
/// USUARIOS SCREEN - SST EDURISK
/// ===============================================================
///
/// Gestión de usuarios para SUPER_ADMIN.
///
/// Incluye:
/// - listado de usuarios;
/// - búsqueda y filtro por rol;
/// - registro;
/// - edición;
/// - cambio de contraseña;
/// - activación / desactivación;
/// - eliminación lógica;
/// - auditoría usando el usuario autenticado;
/// - identidad visual oficial SST EduRisk.
/// ===============================================================
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuarioRepository _usuarioRepository = UsuarioRepository();
  final RolRepository _rolRepository = RolRepository();
  final InstitucionRepository _institucionRepository = InstitucionRepository();
  final SedeRepository _sedeRepository = SedeRepository();
  final AreaRepository _areaRepository = AreaRepository();

  final SecureStorageService _secureStorage = SecureStorageService.instance;

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

  // =============================================================
  // USUARIO AUTENTICADO
  // =============================================================

  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String? usuarioIdTexto = await _secureStorage.getUsuarioId();

    final int? usuarioId = int.tryParse(usuarioIdTexto ?? '');

    if (usuarioId == null || usuarioId <= 0) {
      throw Exception(
        'No se pudo identificar al usuario autenticado. '
        'Cierra sesión y vuelve a ingresar.',
      );
    }

    return usuarioId;
  }

  // =============================================================
  // CARGAR DATOS
  // =============================================================

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

  // =============================================================
  // NUEVO USUARIO
  // =============================================================

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

  Future<void> _crearUsuario(_UsuarioFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

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
        usuarioRegistroId: usuarioAutenticadoId,
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

  // =============================================================
  // EDITAR USUARIO
  // =============================================================

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

  Future<void> _actualizarUsuario(
    UsuarioModel usuario,
    _UsuarioFormResult datos,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

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
        usuarioActualizacionId: usuarioAutenticadoId,
      );

      await _usuarioRepository.actualizarRoles(
        id: usuario.id,
        rolIds: datos.rolIds,
        usuarioActualizacionId: usuarioAutenticadoId,
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

  // =============================================================
  // CAMBIAR CONTRASEÑA
  // =============================================================

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
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

      final String mensaje = await _usuarioRepository.cambiarPassword(
        id: usuario.id,
        nuevaPassword: resultado.password,
        debeCambiarPassword: resultado.debeCambiarPassword,
        usuarioActualizacionId: usuarioAutenticadoId,
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

  // =============================================================
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<void> _cambiarEstado(UsuarioModel usuario) async {
    final bool nuevoEstado = !usuario.activo;

    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            nuevoEstado ? Icons.person_add_alt_1 : Icons.person_off_outlined,
            color: nuevoEstado ? AppColors.green : AppColors.riskOrange,
            size: 42,
          ),
          title: Text(nuevoEstado ? 'Activar usuario' : 'Desactivar usuario'),
          content: Text(
            nuevoEstado
                ? '¿Deseas activar a '
                      '"${usuario.nombreVisible}"?'
                : '¿Deseas desactivar a '
                      '"${usuario.nombreVisible}"?',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: nuevoEstado
                    ? AppColors.green
                    : AppColors.riskOrange,
              ),
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
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

      final String mensaje = await _usuarioRepository.cambiarEstado(
        id: usuario.id,
        activo: nuevoEstado,
        usuarioActualizacionId: usuarioAutenticadoId,
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

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> _confirmarEliminar(UsuarioModel usuario) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: AppColors.riskOrange,
            size: 42,
          ),
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Deseas eliminar al usuario '
            '"${usuario.nombreVisible}"?\n\n'
            'Esta operación realizará una '
            'eliminación lógica.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.riskOrange,
              ),
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
      final int usuarioAutenticadoId = await _obtenerUsuarioAutenticadoId();

      final String mensaje = await _usuarioRepository.eliminar(
        id: usuario.id,
        usuarioId: usuarioAutenticadoId,
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

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? AppColors.riskOrange : AppColors.navyDark,
          content: Row(
            children: <Widget>[
              Icon(
                esError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(mensaje)),
            ],
          ),
        ),
      );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final List<UsuarioModel> usuarios = _usuariosFiltrados;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBright,
        foregroundColor: Colors.white,
        onPressed: _procesando ? null : _abrirNuevoUsuario,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Nuevo usuario',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            color: AppColors.primaryBright,
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
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.navyDark.withValues(alpha: 0.20),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  Widget _construirResumen() {
    final int activos = _usuarios
        .where((UsuarioModel usuario) => usuario.activo)
        .length;

    final int inactivos = _usuarios.length - activos;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.navyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Usuarios del sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_usuarios.length} registrados',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _ResumenBadge(
                      icon: Icons.check_circle_outline,
                      text: '$activos activos',
                      color: AppColors.green,
                    ),
                    _ResumenBadge(
                      icon: Icons.person_off_outlined,
                      text: '$inactivos inactivos',
                      color: AppColors.yellow,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FILTROS
  // =============================================================

  Widget _construirFiltros() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
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
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey<int?>(_rolFiltroId),
            initialValue: _rolFiltroId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filtrar por rol',
              prefixIcon: Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
              ),
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

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido(List<UsuarioModel> usuarios) {
    if (_cargando && _usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _usuarios.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 44),
          const Icon(
            Icons.cloud_off_outlined,
            size: 72,
            color: AppColors.riskOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los usuarios',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
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
          const Icon(Icons.people_outline, size: 72, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            _usuarios.isEmpty
                ? 'No hay usuarios registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Utiliza el botón "Nuevo usuario" para registrar una cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: usuarios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final UsuarioModel usuario = usuarios[index];

        return _UsuarioCard(
          usuario: usuario,
          procesando: _procesando,
          inicial: _inicialUsuario(usuario),
          onEditar: () => _abrirEditarUsuario(usuario),
          onPassword: () => _abrirCambiarPassword(usuario),
          onEstado: () => _cambiarEstado(usuario),
          onEliminar: () => _confirmarEliminar(usuario),
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

/// ===============================================================
/// TARJETA DE USUARIO
/// ===============================================================
class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({
    required this.usuario,
    required this.procesando,
    required this.inicial,
    required this.onEditar,
    required this.onPassword,
    required this.onEstado,
    required this.onEliminar,
  });

  final UsuarioModel usuario;
  final bool procesando;
  final String inicial;

  final VoidCallback onEditar;
  final VoidCallback onPassword;
  final VoidCallback onEstado;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final Color estadoColor = usuario.activo
        ? AppColors.green
        : AppColors.riskOrange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          usuario.nombreVisible,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          usuario.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@${usuario.nombreUsuario}',
                    style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoLinea(
                    icon: Icons.badge_outlined,
                    texto: usuario.rolesTexto,
                  ),
                  if (usuario.numeroDocumento.isNotEmpty)
                    _InfoLinea(
                      icon: Icons.assignment_ind_outlined,
                      texto:
                          '${usuario.tipoDocumento.isEmpty ? 'Documento' : usuario.tipoDocumento}: '
                          '${usuario.numeroDocumento}',
                    ),
                  if (usuario.correo.isNotEmpty)
                    _InfoLinea(
                      icon: Icons.email_outlined,
                      texto: usuario.correo,
                    ),
                  if (usuario.telefono.isNotEmpty)
                    _InfoLinea(
                      icon: Icons.phone_outlined,
                      texto: usuario.telefono,
                    ),
                  if (usuario.debeCambiarPassword)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.lock_reset_outlined,
                            size: 17,
                            color: AppColors.navyDark,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Cambio de contraseña pendiente',
                              style: TextStyle(
                                color: AppColors.navyDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              enabled: !procesando,
              color: AppColors.surface,
              onSelected: (String opcion) {
                switch (opcion) {
                  case 'editar':
                    onEditar();
                    break;
                  case 'password':
                    onPassword();
                    break;
                  case 'estado':
                    onEstado();
                    break;
                  case 'eliminar':
                    onEliminar();
                    break;
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'editar',
                  child: _MenuOpcion(
                    icon: Icons.edit_outlined,
                    texto: 'Editar',
                    color: AppColors.primary,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'password',
                  child: _MenuOpcion(
                    icon: Icons.password_outlined,
                    texto: 'Cambiar contraseña',
                    color: AppColors.primaryBright,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'estado',
                  child: _MenuOpcion(
                    icon: usuario.activo
                        ? Icons.person_off_outlined
                        : Icons.person_outline,
                    texto: usuario.activo ? 'Desactivar' : 'Activar',
                    color: usuario.activo ? AppColors.yellow : AppColors.green,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: _MenuOpcion(
                    icon: Icons.delete_outline,
                    texto: 'Eliminar',
                    color: AppColors.riskOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLinea extends StatelessWidget {
  const _InfoLinea({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuOpcion extends StatelessWidget {
  const _MenuOpcion({
    required this.icon,
    required this.texto,
    required this.color,
  });

  final IconData icon;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(texto),
      ],
    );
  }
}

class _ResumenBadge extends StatelessWidget {
  const _ResumenBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// FORMULARIO DE USUARIO
/// ===============================================================
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
  State<_UsuarioFormScreen> createState() => _UsuarioFormScreenState();
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

  List<AreaModel> get _areasDisponibles {
    if (_institucionId == null) {
      return <AreaModel>[];
    }

    return widget.areas
        .where((AreaModel area) => area.institucionId == _institucionId)
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

  // =============================================================
  // GUARDAR
  // =============================================================

  void _guardar() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
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
      ..showSnackBar(
        SnackBar(backgroundColor: AppColors.riskOrange, content: Text(mensaje)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<SedeModel> sedes = _sedesDisponibles;

    final List<AreaModel> areas = _areasDisponibles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.titulo)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _FormularioCabecera(editando: _editando),
              const SizedBox(height: 18),

              _SeccionCard(
                titulo: 'Datos personales',
                icono: Icons.person_outline,
                children: <Widget>[
                  TextFormField(
                    controller: _nombresController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombres',
                      prefixIcon: Icon(Icons.person_outline),
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
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'DNI',
                        child: Text('DNI'),
                      ),
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
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SeccionCard(
                titulo: 'Organización',
                icono: Icons.apartment_outlined,
                children: <Widget>[
                  DropdownButtonFormField<int>(
                    initialValue: _institucionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Institución',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: widget.instituciones.map((
                      InstitucionModel institucion,
                    ) {
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
                                  sede.id == _sedeId &&
                                  sede.institucionId == value,
                            )) {
                          _sedeId = null;
                        }

                        if (_areaId != null &&
                            !widget.areas.any(
                              (AreaModel area) =>
                                  area.id == _areaId &&
                                  area.institucionId == value,
                            )) {
                          _areaId = null;
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
                    initialValue:
                        sedes.any((SedeModel sede) => sede.id == _sedeId)
                        ? _sedeId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sede (opcional)',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin sede'),
                      ),
                      ...sedes.map((SedeModel sede) {
                        return DropdownMenuItem<int?>(
                          value: sede.id,
                          child: Text(
                            sede.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    key: ValueKey<String>('$_institucionId-$_areaId'),
                    initialValue:
                        areas.any((AreaModel area) => area.id == _areaId)
                        ? _areaId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Área (opcional)',
                      prefixIcon: Icon(Icons.business_center_outlined),
                    ),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin área'),
                      ),
                      ...areas.map((AreaModel area) {
                        return DropdownMenuItem<int?>(
                          value: area.id,
                          child: Text(
                            area.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (int? value) {
                      setState(() {
                        _areaId = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SeccionCard(
                titulo: 'Rol del usuario',
                icono: Icons.admin_panel_settings_outlined,
                children: <Widget>[
                  const Text(
                    'Selecciona uno o más roles.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...widget.roles.map((RolModel rol) {
                    final bool seleccionado = _rolIds.contains(rol.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? AppColors.primary.withValues(alpha: 0.07)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado
                              ? AppColors.primaryBright
                              : AppColors.border,
                        ),
                      ),
                      child: CheckboxListTile(
                        activeColor: AppColors.primary,
                        value: seleccionado,
                        title: Text(
                          rol.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 16),

              _SeccionCard(
                titulo: 'Acceso al sistema',
                icono: Icons.lock_outline,
                children: <Widget>[
                  TextFormField(
                    controller: _nombreUsuarioController,
                    autocorrect: false,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: Icon(Icons.account_circle_outlined),
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
                          tooltip: _ocultarPassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
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
                      ),
                      validator: (String? value) {
                        if ((value ?? '').length < 8) {
                          return 'La contraseña debe tener al menos 8 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.green,
                        title: const Text(
                          'Cambiar contraseña al ingresar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Recomendado para contraseñas temporales.',
                        ),
                        value: _debeCambiarPassword,
                        onChanged: (bool value) {
                          setState(() {
                            _debeCambiarPassword = value;
                          });
                        },
                      ),
                    ),
                  ],

                  if (_editando)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: _activo
                            ? AppColors.green.withValues(alpha: 0.09)
                            : AppColors.riskOrange.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activo
                              ? AppColors.green
                              : AppColors.riskOrange,
                        ),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: AppColors.green,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text(
                          'Usuario activo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                    ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _guardar,
                  icon: Icon(
                    _editando ? Icons.save_outlined : Icons.person_add_alt_1,
                  ),
                  label: Text(
                    _editando ? 'Guardar cambios' : 'Registrar usuario',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
}

/// ===============================================================
/// CABECERA DE FORMULARIO
/// ===============================================================
class _FormularioCabecera extends StatelessWidget {
  const _FormularioCabecera({required this.editando});

  final bool editando;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryBright],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              editando
                  ? Icons.manage_accounts_outlined
                  : Icons.person_add_alt_1,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  editando ? 'Actualizar cuenta' : 'Registrar nueva cuenta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  editando
                      ? 'Modifica los datos del usuario seleccionado.'
                      : 'Completa los datos y asigna su rol en SST EduRisk.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// SECCIÓN DEL FORMULARIO
/// ===============================================================
class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  final String titulo;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icono, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// DIÁLOGO CAMBIAR CONTRASEÑA
/// ===============================================================
class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog({required this.usuario});

  final UsuarioModel usuario;

  @override
  State<_CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmarController = TextEditingController();

  bool _debeCambiar = true;
  bool _ocultar = true;
  bool _ocultarConfirmacion = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
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
      icon: const Icon(
        Icons.lock_reset_outlined,
        color: AppColors.primaryBright,
        size: 44,
      ),
      title: const Text('Cambiar contraseña', textAlign: TextAlign.center),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.usuario.nombreVisible,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${widget.usuario.nombreUsuario}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
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
                  obscureText: _ocultarConfirmacion,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _ocultarConfirmacion = !_ocultarConfirmacion;
                        });
                      },
                      icon: Icon(
                        _ocultarConfirmacion
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: AppColors.green,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    value: _debeCambiar,
                    title: const Text(
                      'Solicitar cambio al ingresar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Actívalo cuando la contraseña sea temporal.',
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        _debeCambiar = value;
                      });
                    },
                  ),
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// ===============================================================
/// RESULTADO FORMULARIO USUARIO
/// ===============================================================
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

/// ===============================================================
/// RESULTADO CONTRASEÑA
/// ===============================================================
class _PasswordResult {
  const _PasswordResult({
    required this.password,
    required this.debeCambiarPassword,
  });

  final String password;
  final bool debeCambiarPassword;
}
