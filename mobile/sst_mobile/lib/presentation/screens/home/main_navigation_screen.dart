import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/solicitud_seguridad_repository.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/sync_status_card.dart';
import '../actividades/actividades_screen.dart';
import '../areas/areas_screen.dart';
import '../categorias_peligro/categorias_peligro_screen.dart';
import '../clasificaciones_control/clasificaciones_control_screen.dart';
import '../consecuencias/consecuencias_screen.dart';
import '../controles/controles_screen.dart';
import '../equipos_proteccion/equipos_proteccion_screen.dart';
import '../iperc/matrices_iperc_screen.dart';
import '../mapas_riesgo/mapas_riesgo_screen.dart';
import '../mapas_riesgo/zonas_identificadas_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../peligros/peligros_screen.dart';
import '../perfil/perfil_screen.dart';
import '../procesos/procesos_screen.dart';
import '../puestos_trabajo/puestos_trabajo_screen.dart';
import '../reportes/reportes_screen.dart';
import '../roles/roles_screen.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';
import '../solicitudes_seguridad/solicitudes_seguridad_screen.dart';
import '../tipos_equipo_proteccion/tipos_equipo_proteccion_screen.dart';
import '../tipos_peligro/tipos_peligro_screen.dart';
import '../usuarios/usuarios_screen.dart';

/// ===============================================================
/// MAIN NAVIGATION SCREEN - SST EDURISK
/// ===============================================================
///
/// Navegación principal con identidad visual oficial.
///
/// Colores:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    required this.nombreUsuario,
    required this.rol,
    super.key,
  });

  final String nombreUsuario;
  final String rol;

  @override
  State<MainNavigationScreen> createState() {
    return _MainNavigationScreenState();
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarPendientesAlEntrar();
    });
  }

  Future<void> _sincronizarPendientesAlEntrar() async {
    if (!mounted) {
      return;
    }

    try {
      await context.read<SyncProvider>().refreshAndSynchronize();
    } catch (_) {
      // La cola permanece en SQLite.
      // SyncStatusCard mostrarÃ¡ el error real si el envÃ­o falla.
    }
  }

  late final List<Widget> _pantallas = <Widget>[
    ChangeNotifierProvider<DashboardProvider>(
      create: (_) {
        final DashboardProvider provider = DashboardProvider();
        Future<void>.microtask(provider.cargarResumen);
        return provider;
      },
      child: InicioView(nombreUsuario: widget.nombreUsuario, rol: widget.rol),
    ),
    IpercView(rol: widget.rol),
    SstView(rol: widget.rol),
    const MapasView(),
    MasView(nombreUsuario: widget.nombreUsuario, rol: widget.rol),
  ];

  final List<String> _titulos = <String>[
    'Inicio',
    'Gestión IPERC',
    'Seguridad y Salud',
    'Mapas de riesgo',
    'Más opciones',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/icons/sst_edurisk_icon_1024.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'SST EduRisk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _titulos[_indiceActual],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDCEAFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceActual = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'IPERC',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(
              Icons.health_and_safety,
              color: AppColors.primary,
            ),
            label: 'SST',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Mapas',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more, color: AppColors.primary),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// INICIO
/// ===============================================================
class InicioView extends StatelessWidget {
  const InicioView({required this.nombreUsuario, required this.rol, super.key});

  final String nombreUsuario;
  final String rol;

  String _rolVisible(String rol) {
    switch (rol.trim().toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'SUPER ADMIN';

      case 'SUP_TITULAR':
        return 'SUPERVISOR TITULAR';

      case 'SUP_SUPLENTE':
        return 'SUPERVISOR SUPLENTE';

      case 'ADMIN':
        return 'ADMINISTRADOR';

      case 'COORDINADOR':
        return 'COORDINADOR';

      default:
        return rol.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (BuildContext context, DashboardProvider provider, Widget? child) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: provider.cargarResumen,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.primaryBright,
                      AppColors.primary,
                      AppColors.navyDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.asset(
                        'assets/icons/sst_edurisk_icon_1024.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Bienvenido, $nombreUsuario',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Rol: ${_rolVisible(rol)}',
                            style: const TextStyle(
                              color: Color(0xFFDCEAFF),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'SST EduRisk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar resumen',
                      onPressed: provider.cargando
                          ? null
                          : provider.cargarResumen,
                      color: Colors.white,
                      disabledColor: Colors.white54,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (provider.cargando) ...<Widget>[
                const LinearProgressIndicator(
                  color: AppColors.primaryBright,
                  backgroundColor: AppColors.border,
                ),
                const SizedBox(height: 16),
              ],

              if (provider.tieneError) ...<Widget>[
                _DashboardError(
                  mensaje: provider.error!,
                  onReintentar: provider.cargarResumen,
                ),
                const SizedBox(height: 16),
              ],

              ResumenCard(
                icono: Icons.assignment_outlined,
                titulo: 'Matrices IPERC',
                descripcion:
                    'Matrices registradas para identificar peligros '
                    'y evaluar riesgos.',
                resumen:
                    '${provider.cantidadMatrices} '
                    '${provider.cantidadMatrices == 1 ? 'matriz registrada' : 'matrices registradas'}',
                color: AppColors.primaryBright,
              ),

              ResumenCard(
                icono: Icons.warning_amber_rounded,
                titulo: 'Riesgos críticos',
                descripcion:
                    'Riesgos altos que requieren controles '
                    'y atención prioritaria.',
                resumen:
                    '${provider.cantidadRiesgosCriticos} '
                    '${provider.cantidadRiesgosCriticos == 1 ? 'riesgo crítico' : 'riesgos críticos'}',
                color: AppColors.riskOrange,
              ),

              ResumenCard(
                icono: Icons.fact_check_outlined,
                titulo: 'Seguimientos',
                descripcion:
                    'Controles y medidas correctivas '
                    'pendientes de verificación.',
                resumen:
                    '${provider.cantidadSeguimientosPendientes} '
                    '${provider.cantidadSeguimientosPendientes == 1 ? 'seguimiento pendiente' : 'seguimientos pendientes'}',
                color: AppColors.yellow,
                colorTexto: const Color(0xFF8A5A00),
              ),

              ResumenCard(
                icono: Icons.verified_outlined,
                titulo: 'Seguimientos verificados',
                descripcion:
                    'Seguimientos que ya fueron revisados '
                    'y aprobados.',
                resumen:
                    '${provider.cantidadSeguimientosVerificados} '
                    '${provider.cantidadSeguimientosVerificados == 1 ? 'seguimiento verificado' : 'seguimientos verificados'}',
                color: AppColors.green,
              ),

              const SizedBox(height: 2),

              // Estado REAL de sincronización online/offline.
              const SyncStatusCard(),

              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// ERROR DEL DASHBOARD
/// ===============================================================
class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.riskOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.riskOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.riskOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// ===============================================================
/// IPERC
/// ===============================================================
class IpercView extends StatelessWidget {
  const IpercView({required this.rol, super.key});

  final String rol;

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        ModuloItem(
          icono: Icons.assignment_outlined,
          titulo: 'Matrices IPERC',
          descripcion:
              'Crear, consultar y actualizar matrices de identificación '
              'de peligros y evaluación de riesgos.',
          color: AppColors.primaryBright,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MatricesIpercScreen(rol: rol),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.grid_view_rounded,
          titulo: 'Evaluación 5×5',
          descripcion:
              'Calcular el nivel de riesgo según probabilidad y severidad.',
          color: AppColors.yellow,
          colorTexto: AppColors.navyDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MatrizRiesgoScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.fact_check_outlined,
          titulo: 'Seguimientos',
          descripcion:
              'Registrar avances, evidencias, responsables y observaciones.',
          color: AppColors.green,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SeguimientosIpercScreen(rol: rol),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// ===============================================================
/// SST
/// ===============================================================
class SstView extends StatelessWidget {
  const SstView({required this.rol, super.key});

  final String rol;

  @override
  Widget build(BuildContext context) {
    final bool puedeAdministrar = RolePermissions.puedeAdministrarCatalogos(
      rol,
    );

    if (!puedeAdministrar) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Acceso restringido',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu usuario no tiene permisos para administrar '
            'los catálogos SST.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.40),
          ),
        ],
      );
    }

    return ModulosList(
      modulos: <ModuloItem>[
        ModuloItem(
          icono: Icons.category_outlined,
          titulo: 'Categorías de peligro',
          descripcion:
              'Administrar las categorías principales utilizadas para '
              'organizar los tipos de peligro.',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CategoriasPeligroScreen(),
            ),
          ),
        ),
        ModuloItem(
          icono: Icons.account_tree_outlined,
          titulo: 'Tipos de peligro',
          descripcion:
              'Administrar los tipos utilizados para clasificar '
              'los peligros SST.',
          color: AppColors.primaryBright,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TiposPeligroScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.warning_amber_rounded,
          titulo: 'Peligros',
          descripcion:
              'Registrar fuentes, actos y situaciones que pueden causar daño.',
          color: AppColors.riskOrange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PeligrosScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.personal_injury_outlined,
          titulo: 'Consecuencias',
          descripcion:
              'Registrar los posibles daños o efectos producidos '
              'por cada peligro.',
          color: AppColors.yellow,
          colorTexto: AppColors.navyDark,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConsecuenciasScreen(),
            ),
          ),
        ),
        ModuloItem(
          icono: Icons.account_tree_outlined,
          titulo: 'Clasificaciones de control',
          descripcion:
              'Administrar la jerarquía utilizada para organizar '
              'los controles SST.',
          color: AppColors.navyDark,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ClasificacionesControlScreen(),
            ),
          ),
        ),
        ModuloItem(
          icono: Icons.health_and_safety_outlined,
          titulo: 'Controles',
          descripcion:
              'Administrar medidas para eliminar o reducir los riesgos.',
          color: AppColors.green,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ControlesScreen(rol: rol)),
          ),
        ),
        ModuloItem(
          icono: Icons.category_outlined,
          titulo: 'Tipos de EPP',
          descripcion:
              'Administrar las categorías utilizadas para clasificar '
              'los equipos de protección personal.',
          color: AppColors.primaryBright,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TiposEquipoProteccionScreen(),
            ),
          ),
        ),
        ModuloItem(
          icono: Icons.engineering_outlined,
          titulo: 'Equipos de protección',
          descripcion:
              'Gestionar los equipos de protección personal requeridos.',
          color: AppColors.green,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EquiposProteccionScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// MAPAS DE RIESGO
/// ===============================================================
class MapasView extends StatelessWidget {
  const MapasView({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        ModuloItem(
          icono: Icons.map_outlined,
          titulo: 'Mapas de riesgo',
          descripcion:
              'Consultar los peligros y niveles de riesgo registrados '
              'por matriz IPERC.',
          color: AppColors.primaryBright,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MapasRiesgoScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.location_on_outlined,
          titulo: 'Zonas identificadas',
          descripcion:
              'Consultar las áreas identificadas, su nivel máximo '
              'y cantidad de riesgos.',
          color: AppColors.riskOrange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ZonasIdentificadasScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// MÁS OPCIONES
/// ===============================================================
class MasView extends StatefulWidget {
  const MasView({required this.nombreUsuario, required this.rol, super.key});

  final String nombreUsuario;
  final String rol;

  @override
  State<MasView> createState() => _MasViewState();
}

class _MasViewState extends State<MasView> {
  final SolicitudSeguridadRepository _solicitudesRepository =
      SolicitudSeguridadRepository();

  int _solicitudesPendientes = 0;

  bool _cargandoSolicitudes = false;

  @override
  void initState() {
    super.initState();

    if (RolePermissions.esSuperAdmin(widget.rol)) {
      _cargarSolicitudesPendientes();
    }
  }

  // =============================================================
  // CONTAR SOLICITUDES PENDIENTES
  // =============================================================

  Future<void> _cargarSolicitudesPendientes() async {
    if (_cargandoSolicitudes) {
      return;
    }

    if (!RolePermissions.esSuperAdmin(widget.rol)) {
      return;
    }

    setState(() {
      _cargandoSolicitudes = true;
    });

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _solicitudesRepository.obtenerSolicitudesAcceso(estado: 'PENDIENTE'),
          _solicitudesRepository.obtenerSolicitudesRecuperacion(
            estado: 'PENDIENTE',
          ),
        ],
      );

      final int accesos = (resultados[0] as List).length;
      final int recuperaciones = (resultados[1] as List).length;

      if (!mounted) {
        return;
      }

      setState(() {
        _solicitudesPendientes = accesos + recuperaciones;
      });
    } catch (_) {
      // El contador no debe bloquear el menú si no hay conexión.
    } finally {
      if (mounted) {
        setState(() {
          _cargandoSolicitudes = false;
        });
      }
    }
  }

  // =============================================================
  // ABRIR SOLICITUDES
  // =============================================================

  Future<void> _abrirSolicitudes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return SolicitudesSeguridadScreen(rol: widget.rol);
        },
      ),
    );

    if (mounted) {
      await _cargarSolicitudesPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.apartment_outlined,
            titulo: 'Áreas',
            descripcion:
                'Consultar las áreas y ambientes activos de la institución.',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AreasScreen()),
              );
            },
          ),

        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.account_tree_outlined,
            titulo: 'Procesos',
            descripcion: 'Gestionar los procesos pertenecientes a cada área.',
            color: AppColors.primaryBright,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProcesosScreen()),
              );
            },
          ),

        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.task_alt_outlined,
            titulo: 'Actividades',
            descripcion: 'Registrar actividades y tareas que serán evaluadas.',
            color: AppColors.green,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ActividadesScreen(),
                ),
              );
            },
          ),

        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.badge_outlined,
            titulo: 'Puestos de trabajo',
            descripcion: 'Administrar los puestos pertenecientes a cada área.',
            color: AppColors.yellow,
            colorTexto: AppColors.navyDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PuestosTrabajoScreen(),
                ),
              );
            },
          ),

        if (RolePermissions.esSuperAdmin(widget.rol))
          ModuloItem(
            icono: Icons.mark_email_unread_outlined,
            titulo: 'Solicitudes de seguridad',
            descripcion:
                'Aprobar accesos y atender recuperaciones de contraseña.',
            color: AppColors.riskOrange,
            cantidad: _solicitudesPendientes,
            cargandoCantidad: _cargandoSolicitudes,
            onTap: _abrirSolicitudes,
          ),

        if (RolePermissions.puedeAdministrarUsuarios(widget.rol))
          ModuloItem(
            icono: Icons.manage_accounts_outlined,
            titulo: 'Usuarios',
            descripcion: 'Crear, editar, activar, desactivar y asignar roles.',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const UsuariosScreen()),
              );
            },
          ),

        if (RolePermissions.puedeAdministrarRoles(widget.rol))
          ModuloItem(
            icono: Icons.admin_panel_settings_outlined,
            titulo: 'Roles',
            descripcion: 'Administrar roles y permisos generales del sistema.',
            color: AppColors.navyDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RolesScreen()),
              );
            },
          ),

        if (RolePermissions.puedeVerReportes(widget.rol))
          ModuloItem(
            icono: Icons.bar_chart_outlined,
            titulo: 'Reportes',
            descripcion:
                'Consultar reportes de riesgos, controles y seguimientos.',
            color: AppColors.green,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportesScreen(rol: widget.rol),
                ),
              );
            },
          ),

        ModuloItem(
          icono: Icons.person_outline,
          titulo: 'Perfil',
          descripcion:
              'Consultar la información de la cuenta, acceso offline '
              'y cerrar sesión.',
          color: AppColors.primaryBright,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PerfilScreen(
                  nombreUsuario: widget.nombreUsuario,
                  rol: widget.rol,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// ===============================================================
/// LISTA REUTILIZABLE DE MÓDULOS
/// ===============================================================
class ModulosList extends StatelessWidget {
  const ModulosList({required this.modulos, super.key});

  final List<ModuloItem> modulos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: modulos.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final ModuloItem modulo = modulos[index];
        final Color colorTexto = modulo.colorTexto ?? modulo.color;

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                modulo.onTap ??
                () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Módulo ${modulo.titulo} en construcción.',
                        ),
                      ),
                    );
                },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(width: 5, color: modulo.color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: modulo.color.withValues(alpha: 0.11),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                modulo.icono,
                                color: colorTexto,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    modulo.titulo,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    modulo.descripcion,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (modulo.cargandoCantidad)
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: modulo.color,
                                    ),
                                  )
                                else if (modulo.cantidad > 0)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.riskOrange,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      modulo.cantidad > 99
                                          ? '99+'
                                          : modulo.cantidad.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (modulo.cargandoCantidad ||
                                    modulo.cantidad > 0)
                                  const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorTexto,
                                  size: 26,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// TARJETA DEL DASHBOARD
/// ===============================================================
class ResumenCard extends StatelessWidget {
  const ResumenCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.resumen,
    required this.color,
    this.colorTexto,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final String resumen;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color textoDestacado = colorTexto ?? color;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icono, color: textoDestacado, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            descripcion,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              resumen,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: textoDestacado,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// INFORMACIÓN VISUAL DE UN MÓDULO
/// ===============================================================
class ModuloItem {
  const ModuloItem({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    this.colorTexto,
    this.onTap,
    this.cantidad = 0,
    this.cargandoCantidad = false,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  /// Color de identidad del módulo.
  final Color color;

  /// Se usa especialmente con amarillo para mejorar contraste.
  final Color? colorTexto;

  final VoidCallback? onTap;

  /// Cantidad pendiente mostrada como badge.
  final int cantidad;

  /// Indica si todavía se consulta el contador.
  final bool cargandoCantidad;
}
