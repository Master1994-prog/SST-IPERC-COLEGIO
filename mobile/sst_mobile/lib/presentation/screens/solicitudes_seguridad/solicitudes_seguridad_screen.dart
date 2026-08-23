import 'package:flutter/material.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/area_model.dart';
import '../../../data/models/institucion_model.dart';
import '../../../data/models/rol_model.dart';
import '../../../data/models/sede_model.dart';
import '../../../data/models/solicitud_seguridad_model.dart';
import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/institucion_repository.dart';
import '../../../data/repositories/rol_repository.dart';
import '../../../data/repositories/sede_repository.dart';
import '../../../data/repositories/solicitud_seguridad_repository.dart';
import '../../../data/repositories/usuario_repository.dart';

/// ===============================================================
/// SOLICITUDES DE SEGURIDAD
/// ===============================================================
///
/// Exclusiva para SUPER_ADMIN.
///
/// Permite:
///
/// - Consultar solicitudes de acceso.
/// - Aprobar y crear cuentas.
/// - Rechazar solicitudes.
/// - Atender recuperación de contraseña.
/// - Asignar contraseña temporal.
/// ===============================================================
class SolicitudesSeguridadScreen extends StatefulWidget {
  const SolicitudesSeguridadScreen({required this.rol, super.key});

  final String rol;

  @override
  State<SolicitudesSeguridadScreen> createState() =>
      _SolicitudesSeguridadScreenState();
}

class _SolicitudesSeguridadScreenState extends State<SolicitudesSeguridadScreen>
    with SingleTickerProviderStateMixin {
  final SolicitudSeguridadRepository _solicitudesRepository =
      SolicitudSeguridadRepository();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final SecureStorageService _secureStorage = SecureStorageService.instance;

  late final TabController _tabController;

  List<SolicitudAccesoModel> _accesos = <SolicitudAccesoModel>[];

  List<SolicitudRecuperacionModel> _recuperaciones =
      <SolicitudRecuperacionModel>[];

  bool _cargando = true;
  bool _procesando = false;

  String? _error;

  String _filtroAcceso = 'PENDIENTE';
  String _filtroRecuperacion = 'PENDIENTE';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  // =============================================================
  // CARGAR
  // =============================================================

  Future<void> _cargarTodo() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _solicitudesRepository.obtenerSolicitudesAcceso(
            estado: _filtroAcceso == 'TODAS' ? null : _filtroAcceso,
          ),
          _solicitudesRepository.obtenerSolicitudesRecuperacion(
            estado: _filtroRecuperacion == 'TODAS' ? null : _filtroRecuperacion,
          ),
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accesos = resultados[0] as List<SolicitudAccesoModel>;

        _recuperaciones = resultados[1] as List<SolicitudRecuperacionModel>;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _limpiarError(error);
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
  // ID DEL SUPER ADMIN
  // =============================================================

  Future<int> _usuarioActualId() async {
    final String texto = (await _secureStorage.getUsuarioId())?.trim() ?? '';

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      throw StateError('No se encontró el usuario autenticado.');
    }

    return id;
  }

  // =============================================================
  // APROBAR ACCESO
  // =============================================================

  Future<void> _aprobarAcceso(SolicitudAccesoModel solicitud) async {
    final AprobacionAccesoResult? datos = await Navigator.of(context)
        .push<AprobacionAccesoResult>(
          MaterialPageRoute<AprobacionAccesoResult>(
            builder: (_) {
              return AprobarSolicitudAccesoScreen(solicitud: solicitud);
            },
          ),
        );

    if (datos == null || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final int usuarioAdminId = await _usuarioActualId();

      // ---------------------------------------------------------
      // CREAR USUARIO
      // ---------------------------------------------------------

      await _usuarioRepository.crear(
        nombres: solicitud.nombres,
        apellidos: solicitud.apellidos,
        numeroDocumento: datos.numeroDocumento,
        tipoDocumento: datos.tipoDocumento,
        correo: solicitud.correo,
        telefono: datos.telefono,
        nombreUsuario: datos.nombreUsuario,
        password: datos.password,
        institucionId: datos.institucionId,
        sedeId: datos.sedeId,
        areaId: datos.areaId,
        rolIds: <int>[datos.rolId],
        debeCambiarPassword: true,
        usuarioRegistroId: usuarioAdminId,
      );

      // ---------------------------------------------------------
      // MARCAR SOLICITUD APROBADA
      // ---------------------------------------------------------

      await _solicitudesRepository.aprobarAcceso(solicitud.id);

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Cuenta creada y solicitud aprobada correctamente.');

      await _cargarTodo();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // RECHAZAR ACCESO
  // =============================================================

  Future<void> _rechazarAcceso(SolicitudAccesoModel solicitud) async {
    final bool confirmado = await _confirmar(
      titulo: 'Rechazar solicitud',
      mensaje:
          '¿Deseas rechazar la solicitud de '
          '${solicitud.nombreCompleto}?',
      textoAceptar: 'Rechazar',
    );

    if (!confirmado || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _solicitudesRepository.rechazarAcceso(
        solicitud.id,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(mensaje);

      await _cargarTodo();
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(_limpiarError(error), esError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // ATENDER RECUPERACIÓN
  // =============================================================

  Future<void> _atenderRecuperacion(
    SolicitudRecuperacionModel solicitud,
  ) async {
    if (solicitud.usuarioId == null) {
      _mostrarMensaje(
        'La solicitud no tiene un usuario asociado.',
        esError: true,
      );

      return;
    }

    final PasswordTemporalResult? resultado =
        await showDialog<PasswordTemporalResult>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return const PasswordTemporalDialog();
          },
        );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final int usuarioAdminId = await _usuarioActualId();

      // ---------------------------------------------------------
      // CAMBIAR PASSWORD
      // ---------------------------------------------------------

      await _usuarioRepository.cambiarPassword(
        id: solicitud.usuarioId!,
        nuevaPassword: resultado.password,
        debeCambiarPassword: true,
        usuarioActualizacionId: usuarioAdminId,
      );

      // ---------------------------------------------------------
      // MARCAR COMO ATENDIDA
      // ---------------------------------------------------------

      await _solicitudesRepository.atenderRecuperacion(solicitud.id);

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Contraseña temporal asignada correctamente.');

      await _cargarTodo();
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(_limpiarError(error), esError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // RECHAZAR RECUPERACIÓN
  // =============================================================

  Future<void> _rechazarRecuperacion(
    SolicitudRecuperacionModel solicitud,
  ) async {
    final bool confirmado = await _confirmar(
      titulo: 'Rechazar recuperación',
      mensaje: '¿Deseas rechazar esta solicitud de recuperación?',
      textoAceptar: 'Rechazar',
    );

    if (!confirmado || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _solicitudesRepository.rechazarRecuperacion(
        solicitud.id,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(mensaje);

      await _cargarTodo();
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(_limpiarError(error), esError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    if (!RolePermissions.esSuperAdmin(widget.rol)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solicitudes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 72),
                SizedBox(height: 16),
                Text(
                  'Acceso restringido',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Solo el SUPER_ADMIN puede '
                  'administrar estas solicitudes.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de seguridad'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarTodo,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,

          // ===========================================================
          // COLORES DEL TABBAR
          // ===========================================================
          labelColor: Colors.white,

          unselectedLabelColor: Colors.white70,

          indicatorColor: Colors.white,

          indicatorWeight: 3,

          dividerColor: Colors.transparent,

          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),

          unselectedLabelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),

          tabs: <Widget>[
            Tab(
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              text: 'Acceso (${_accesos.length})',
            ),

            Tab(
              icon: const Icon(Icons.lock_reset, color: Colors.white),
              text: 'Recuperación (${_recuperaciones.length})',
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _construirError()
          else
            TabBarView(
              controller: _tabController,
              children: <Widget>[
                _construirAccesos(),
                _construirRecuperaciones(),
              ],
            ),

          if (_procesando)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // ACCESOS
  // =============================================================

  Widget _construirAccesos() {
    return Column(
      children: <Widget>[
        _FiltroSolicitudes(
          valor: _filtroAcceso,
          opciones: const <String>[
            'PENDIENTE',
            'APROBADA',
            'RECHAZADA',
            'TODAS',
          ],
          onChanged: (String value) {
            setState(() {
              _filtroAcceso = value;
            });

            _cargarTodo();
          },
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarTodo,
            child: _accesos.isEmpty
                ? _listaVacia(
                    'No hay solicitudes de acceso.',
                    Icons.person_add_disabled,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _accesos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final SolicitudAccesoModel solicitud = _accesos[index];

                      return _AccesoCard(
                        solicitud: solicitud,
                        onAprobar: solicitud.pendiente
                            ? () => _aprobarAcceso(solicitud)
                            : null,
                        onRechazar: solicitud.pendiente
                            ? () => _rechazarAcceso(solicitud)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // RECUPERACIONES
  // =============================================================

  Widget _construirRecuperaciones() {
    return Column(
      children: <Widget>[
        _FiltroSolicitudes(
          valor: _filtroRecuperacion,
          opciones: const <String>[
            'PENDIENTE',
            'ATENDIDA',
            'RECHAZADA',
            'TODAS',
          ],
          onChanged: (String value) {
            setState(() {
              _filtroRecuperacion = value;
            });

            _cargarTodo();
          },
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarTodo,
            child: _recuperaciones.isEmpty
                ? _listaVacia(
                    'No hay solicitudes de recuperación.',
                    Icons.lock_outline,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _recuperaciones.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final SolicitudRecuperacionModel solicitud =
                          _recuperaciones[index];

                      return _RecuperacionCard(
                        solicitud: solicitud,
                        onAtender: solicitud.pendiente
                            ? () => _atenderRecuperacion(solicitud)
                            : null,
                        onRechazar: solicitud.pendiente
                            ? () => _rechazarRecuperacion(solicitud)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _listaVacia(String texto, IconData icono) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: <Widget>[
        const SizedBox(height: 50),
        Icon(icono, size: 70, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 70,
              color: AppColors.riskOrange,
            ),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _cargarTodo,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String textoAceptar,
  }) async {
    final bool? resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
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
              child: Text(textoAceptar),
            ),
          ],
        );
      },
    );

    return resultado == true;
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? AppColors.riskOrange : null,
          content: Text(mensaje),
        ),
      );
  }

  String _limpiarError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}

// ===============================================================
// FILTRO
// ===============================================================

class _FiltroSolicitudes extends StatelessWidget {
  const _FiltroSolicitudes({
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  final String valor;
  final List<String> opciones;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        decoration: const InputDecoration(
          labelText: 'Filtrar por estado',
          prefixIcon: Icon(Icons.filter_list),
        ),
        items: opciones
            .map(
              (String item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: (String? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

// ===============================================================
// CARD ACCESO
// ===============================================================

class _AccesoCard extends StatelessWidget {
  const _AccesoCard({required this.solicitud, this.onAprobar, this.onRechazar});

  final SolicitudAccesoModel solicitud;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

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
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    solicitud.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _EstadoChip(estado: solicitud.estadoSolicitud),
              ],
            ),

            const SizedBox(height: 14),

            _Dato(icono: Icons.email_outlined, texto: solicitud.correo),

            _Dato(
              icono: Icons.apartment_outlined,
              texto: solicitud.institucion,
            ),

            if (solicitud.cargo.isNotEmpty)
              _Dato(icono: Icons.badge_outlined, texto: solicitud.cargo),

            if (solicitud.motivo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Motivo:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(solicitud.motivo),
            ],

            const SizedBox(height: 10),

            Text(
              _formatearFecha(solicitud.fechaSolicitud),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            if (solicitud.pendiente) ...[
              const Divider(height: 28),

              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRechazar,
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAprobar,
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// CARD RECUPERACIÓN
// ===============================================================

class _RecuperacionCard extends StatelessWidget {
  const _RecuperacionCard({
    required this.solicitud,
    this.onAtender,
    this.onRechazar,
  });

  final SolicitudRecuperacionModel solicitud;

  final VoidCallback? onAtender;

  final VoidCallback? onRechazar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ===================================================
            // CABECERA
            // ===================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const CircleAvatar(child: Icon(Icons.lock_reset)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        solicitud.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (solicitud.nombreUsuario.isNotEmpty) ...[
                        const SizedBox(height: 3),

                        Text(
                          '@${solicitud.nombreUsuario}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _EstadoChip(estado: solicitud.estadoSolicitud),
              ],
            ),

            const SizedBox(height: 16),

            // ===================================================
            // INFORMACIÓN
            // ===================================================
            if (solicitud.correo.isNotEmpty)
              _Dato(icono: Icons.email_outlined, texto: solicitud.correo),

            _Dato(
              icono: Icons.person_outline,
              texto: solicitud.nombreUsuario.isEmpty
                  ? solicitud.identificador
                  : solicitud.nombreUsuario,
            ),

            if (solicitud.usuarioId != null)
              _Dato(
                icono: Icons.tag_outlined,
                texto: 'Usuario ID: ${solicitud.usuarioId}',
              ),

            const SizedBox(height: 8),

            Text(
              'Solicitado: '
              '${_formatearFecha(solicitud.fechaSolicitud)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // ===================================================
            // ACCIONES
            // ===================================================
            if (solicitud.pendiente) ...[
              const Divider(height: 28),

              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRechazar,
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAtender,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Atender'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final String valor = estado.toUpperCase();

    Color color;

    switch (valor) {
      case 'APROBADA':
      case 'ATENDIDA':
        color = AppColors.green;
        break;

      case 'RECHAZADA':
        color = AppColors.riskOrange;
        break;

      default:
        color = AppColors.yellow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        valor,
        style: TextStyle(
          color: valor == 'PENDIENTE' ? const Color(0xFF835900) : color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

String _formatearFecha(DateTime? fecha) {
  if (fecha == null) {
    return 'Fecha no disponible';
  }

  final DateTime local = fecha.toLocal();

  String dos(int value) => value.toString().padLeft(2, '0');

  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}

// ===============================================================
// RESULTADO APROBACIÓN
// ===============================================================

class AprobacionAccesoResult {
  const AprobacionAccesoResult({
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.telefono,
    required this.nombreUsuario,
    required this.password,
    required this.institucionId,
    required this.sedeId,
    required this.areaId,
    required this.rolId,
  });

  final String numeroDocumento;
  final String tipoDocumento;
  final String telefono;
  final String nombreUsuario;
  final String password;

  final int institucionId;
  final int? sedeId;
  final int? areaId;
  final int rolId;
}

// ===============================================================
// APROBAR SOLICITUD
// ===============================================================

class AprobarSolicitudAccesoScreen extends StatefulWidget {
  const AprobarSolicitudAccesoScreen({required this.solicitud, super.key});

  final SolicitudAccesoModel solicitud;

  @override
  State<AprobarSolicitudAccesoScreen> createState() =>
      _AprobarSolicitudAccesoScreenState();
}

class _AprobarSolicitudAccesoScreenState
    extends State<AprobarSolicitudAccesoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final InstitucionRepository _institucionRepository = InstitucionRepository();

  final SedeRepository _sedeRepository = SedeRepository();

  final AreaRepository _areaRepository = AreaRepository();

  final RolRepository _rolRepository = RolRepository();

  final TextEditingController _documentoController = TextEditingController();

  final TextEditingController _telefonoController = TextEditingController();

  final TextEditingController _usuarioController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmarController = TextEditingController();

  List<InstitucionModel> _instituciones = <InstitucionModel>[];

  List<SedeModel> _sedes = <SedeModel>[];

  List<AreaModel> _areas = <AreaModel>[];

  List<RolModel> _roles = <RolModel>[];

  InstitucionModel? _institucion;
  SedeModel? _sede;
  AreaModel? _area;
  RolModel? _rol;

  String _tipoDocumento = 'DNI';

  bool _cargando = true;
  bool _ocultarPassword = true;

  @override
  void initState() {
    super.initState();

    _usuarioController.text = _generarUsuario();

    _cargarCatalogos();
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _telefonoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();

    super.dispose();
  }

  String _generarUsuario() {
    String limpiar(String value) {
      return value
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-záéíóúñ0-9 ]'), '')
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ñ', 'n');
    }

    final List<String> nombres = limpiar(
      widget.solicitud.nombres,
    ).split(RegExp(r'\s+'));

    final List<String> apellidos = limpiar(
      widget.solicitud.apellidos,
    ).split(RegExp(r'\s+'));

    final String nombre = nombres.isEmpty ? 'usuario' : nombres.first;

    final String apellido = apellidos.isEmpty ? '' : apellidos.first;

    return '$nombre.$apellido'.replaceAll(RegExp(r'\.+$'), '');
  }

  Future<void> _cargarCatalogos() async {
    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _institucionRepository.obtenerTodas(),
          _rolRepository.obtenerTodos(),
        ],
      );

      final List<InstitucionModel> instituciones =
          (resultados[0] as List<InstitucionModel>)
              .where((InstitucionModel item) => item.activo)
              .toList();

      final List<RolModel> roles = (resultados[1] as List<RolModel>)
          .where(
            (RolModel item) =>
                item.activo &&
                RolePermissions.normalizar(item.codigo) !=
                    RolePermissions.superAdmin,
          )
          .toList();

      InstitucionModel? institucionEncontrada;

      final String buscada = widget.solicitud.institucion.trim().toLowerCase();

      for (final InstitucionModel item in instituciones) {
        if (item.nombre.trim().toLowerCase() == buscada) {
          institucionEncontrada = item;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _instituciones = instituciones;
        _roles = roles;
        _institucion = institucionEncontrada;
        _cargando = false;
      });

      if (institucionEncontrada != null) {
        await _cargarDependencias(institucionEncontrada.id);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    }
  }

  Future<void> _cargarDependencias(int institucionId) async {
    setState(() {
      _sede = null;
      _area = null;
      _sedes = <SedeModel>[];
      _areas = <AreaModel>[];
    });

    final List<dynamic> resultados =
        await Future.wait<dynamic>(<Future<dynamic>>[
          _sedeRepository.obtenerTodas(institucionId: institucionId),
          _areaRepository.obtenerTodas(institucionId: institucionId),
        ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _sedes = resultados[0] as List<SedeModel>;
      _areas = resultados[1] as List<AreaModel>;
    });
  }

  void _aceptar() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      AprobacionAccesoResult(
        numeroDocumento: _documentoController.text.trim(),
        tipoDocumento: _tipoDocumento,
        telefono: _telefonoController.text.trim(),
        nombreUsuario: _usuarioController.text.trim(),
        password: _passwordController.text,
        institucionId: _institucion!.id,
        sedeId: _sede?.id,
        areaId: _area?.id,
        rolId: _rol!.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprobar acceso')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(
                        widget.solicitud.nombreCompleto,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${widget.solicitud.correo}\n'
                        'Institución solicitada: '
                        '${widget.solicitud.institucion}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<InstitucionModel>(
                    initialValue: _institucion,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Institución *',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    items: _instituciones
                        .map(
                          (InstitucionModel item) =>
                              DropdownMenuItem<InstitucionModel>(
                                value: item,
                                child: Text(
                                  item.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        )
                        .toList(),
                    onChanged: (InstitucionModel? value) {
                      setState(() {
                        _institucion = value;
                      });

                      if (value != null) {
                        _cargarDependencias(value.id);
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione una institución.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<SedeModel?>(
                    initialValue: _sede,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sede',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: <DropdownMenuItem<SedeModel?>>[
                      const DropdownMenuItem<SedeModel?>(
                        value: null,
                        child: Text('Sin sede específica'),
                      ),
                      ..._sedes.map(
                        (SedeModel item) => DropdownMenuItem<SedeModel?>(
                          value: item,
                          child: Text(item.nombre),
                        ),
                      ),
                    ],
                    onChanged: (SedeModel? value) {
                      setState(() {
                        _sede = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<AreaModel?>(
                    initialValue: _area,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Área',
                      prefixIcon: Icon(Icons.domain_outlined),
                    ),
                    items: <DropdownMenuItem<AreaModel?>>[
                      const DropdownMenuItem<AreaModel?>(
                        value: null,
                        child: Text('Sin área específica'),
                      ),
                      ..._areas.map(
                        (AreaModel item) => DropdownMenuItem<AreaModel?>(
                          value: item,
                          child: Text(item.nombre),
                        ),
                      ),
                    ],
                    onChanged: (AreaModel? value) {
                      setState(() {
                        _area = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<RolModel>(
                    initialValue: _rol,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Rol *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: _roles
                        .map(
                          (RolModel item) => DropdownMenuItem<RolModel>(
                            value: item,
                            child: Text(item.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (RolModel? value) {
                      setState(() {
                        _rol = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione un rol.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _tipoDocumento,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de documento',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                      DropdownMenuItem(
                        value: 'CE',
                        child: Text('Carné de extranjería'),
                      ),
                      DropdownMenuItem(
                        value: 'PASAPORTE',
                        child: Text('Pasaporte'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _tipoDocumento = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _documentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de documento',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _usuarioController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().length < 4) {
                        return 'Debe tener al menos 4 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña temporal *',
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
                    ),
                    validator: (String? value) {
                      if (value == null || value.length < 8) {
                        return 'Debe tener al menos 8 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _confirmarController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña *',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (String? value) {
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _aceptar,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear usuario y aprobar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class PasswordTemporalResult {
  const PasswordTemporalResult({required this.password});

  final String password;
}

class PasswordTemporalDialog extends StatefulWidget {
  const PasswordTemporalDialog({super.key});

  @override
  State<PasswordTemporalDialog> createState() => _PasswordTemporalDialogState();
}

class _PasswordTemporalDialogState extends State<PasswordTemporalDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmarController = TextEditingController();

  bool _ocultar = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_reset, color: AppColors.primary, size: 42),
      title: const Text('Contraseña temporal'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'El usuario deberá cambiar esta '
                'contraseña después de recuperar '
                'el acceso.',
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
                  if (value == null || value.length < 8) {
                    return 'Mínimo 8 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _confirmarController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (String? value) {
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden.';
                  }

                  return null;
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

        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }

            Navigator.of(
              context,
            ).pop(PasswordTemporalResult(password: _passwordController.text));
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
