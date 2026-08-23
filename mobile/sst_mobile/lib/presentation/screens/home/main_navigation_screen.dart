import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/security/role_permissions.dart';
import '../../../data/repositories/solicitud_seguridad_repository.dart';
import '../../providers/dashboard_provider.dart';
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
import '../seguimientos/seguimientos_screen.dart';
import '../solicitudes_seguridad/solicitudes_seguridad_screen.dart';
import '../tipos_equipo_proteccion/tipos_equipo_proteccion_screen.dart';
import '../tipos_peligro/tipos_peligro_screen.dart';
import '../usuarios/usuarios_screen.dart';

/// Pantalla principal de navegación de la aplicación.
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,

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
                      fontWeight: FontWeight.bold,
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
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceActual = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'IPERC',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'SST',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapas',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

/// Vista inicial.
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
                      Color(0xFF0D60D6),
                      Color(0xFF083F85),
                      Color(0xFF05295E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF083F85).withValues(alpha: 0.20),
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
                              fontWeight: FontWeight.bold,
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
                const LinearProgressIndicator(),
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

              const ResumenCard(
                icono: Icons.sync,
                titulo: 'Sincronización',
                descripcion:
                    'Estado de los registros guardados '
                    'en modo online y offline.',
                resumen: 'Sincronización automática activa',
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Vista principal del módulo IPERC.
class IpercView extends StatelessWidget {
  const IpercView({required this.rol, super.key});

  final String rol;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _IpercModuloCard(
          icono: Icons.assignment,
          titulo: 'Matrices IPERC',
          descripcion:
              'Crear, consultar y actualizar matrices de identificación de peligros y evaluación de riesgos.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MatricesIpercScreen(rol: rol),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _IpercModuloCard(
          icono: Icons.grid_view,
          titulo: 'Evaluación 5×5',
          descripcion:
              'Calcular el nivel de riesgo según probabilidad y severidad.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MatrizRiesgoScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _IpercModuloCard(
          icono: Icons.fact_check,
          titulo: 'Seguimientos',
          descripcion:
              'Registrar avances, evidencias, responsables y observaciones.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SeguimientosScreen(rol: rol),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _IpercModuloCard extends StatelessWidget {
  const _IpercModuloCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Icon(icono)),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(descripcion),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Catálogos SST.
///
/// Solo SUPER_ADMIN, ADMIN y COORDINADOR pueden administrar
/// los catálogos SST.
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
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Acceso restringido',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu usuario no tiene permisos para administrar los catálogos SST.',
            textAlign: TextAlign.center,
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
              'Administrar las categorías principales utilizadas para organizar los tipos de peligro.',
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
              'Administrar los tipos utilizados para clasificar los peligros SST.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TiposPeligroScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.warning_amber_outlined,
          titulo: 'Peligros',
          descripcion:
              'Registrar fuentes, actos y situaciones que pueden causar daño.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PeligrosScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.personal_injury_outlined,
          titulo: 'Consecuencias',
          descripcion:
              'Registrar los posibles daños o efectos producidos por cada peligro.',
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
              'Administrar la jerarquía utilizada para organizar los controles SST.',
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ControlesScreen(rol: rol)),
          ),
        ),
        ModuloItem(
          icono: Icons.category_outlined,
          titulo: 'Tipos de EPP',
          descripcion:
              'Administrar las categorías utilizadas para clasificar los equipos de protección personal.',
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

/// Mapas de riesgo.
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
              'Consultar los peligros y niveles de riesgo registrados por matriz IPERC.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MapasRiesgoScreen()),
          ),
        ),
        ModuloItem(
          icono: Icons.location_on_outlined,
          titulo: 'Zonas identificadas',
          descripcion:
              'Consultar las áreas identificadas, su nivel máximo y cantidad de riesgos.',
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
///
/// Contiene opciones administrativas y adicionales.
///
/// Para SUPER_ADMIN también consulta la cantidad de solicitudes
/// de acceso y recuperación pendientes.
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
      // El contador no debe bloquear el menú
      // si temporalmente no hay conexión.
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

    // Cuando el SUPER_ADMIN regresa del módulo,
    // actualizamos el contador.
    if (mounted) {
      await _cargarSolicitudesPendientes();
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        // =======================================================
        // ORGANIZACIÓN
        // =======================================================
        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.apartment,
            titulo: 'Áreas',
            descripcion:
                'Consultar las áreas y ambientes activos '
                'de la institución.',
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
            descripcion:
                'Gestionar los procesos pertenecientes '
                'a cada área.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProcesosScreen()),
              );
            },
          ),

        if (RolePermissions.puedeAdministrarCatalogos(widget.rol))
          ModuloItem(
            icono: Icons.task_alt,
            titulo: 'Actividades',
            descripcion:
                'Registrar actividades y tareas '
                'que serán evaluadas.',
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
            descripcion:
                'Administrar los puestos pertenecientes '
                'a cada área.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PuestosTrabajoScreen(),
                ),
              );
            },
          ),

        // =======================================================
        // SOLO SUPER_ADMIN
        // =======================================================
        if (RolePermissions.esSuperAdmin(widget.rol))
          ModuloItem(
            icono: Icons.mark_email_unread_outlined,
            titulo: 'Solicitudes de seguridad',
            descripcion:
                'Aprobar accesos y atender recuperaciones '
                'de contraseña.',
            cantidad: _solicitudesPendientes,
            cargandoCantidad: _cargandoSolicitudes,
            onTap: _abrirSolicitudes,
          ),

        if (RolePermissions.puedeAdministrarUsuarios(widget.rol))
          ModuloItem(
            icono: Icons.manage_accounts_outlined,
            titulo: 'Usuarios',
            descripcion:
                'Crear, editar, activar, desactivar '
                'y asignar roles.',
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
            descripcion:
                'Administrar roles y permisos '
                'generales del sistema.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RolesScreen()),
              );
            },
          ),

        // =======================================================
        // REPORTES
        // =======================================================
        if (RolePermissions.puedeVerReportes(widget.rol))
          ModuloItem(
            icono: Icons.bar_chart,
            titulo: 'Reportes',
            descripcion:
                'Consultar reportes de riesgos, '
                'controles y seguimientos.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportesScreen(rol: widget.rol),
                ),
              );
            },
          ),

        // =======================================================
        // PERFIL
        // =======================================================
        ModuloItem(
          icono: Icons.person,
          titulo: 'Perfil',
          descripcion:
              'Consultar la información de la cuenta '
              'y cerrar sesión.',
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

/// Lista reutilizable de módulos.
class ModulosList extends StatelessWidget {
  const ModulosList({required this.modulos, super.key});

  final List<ModuloItem> modulos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: modulos.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        final ModuloItem modulo = modulos[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(child: Icon(modulo.icono)),
            title: Text(
              modulo.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(modulo.descripcion),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (modulo.cargandoCantidad)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (modulo.cantidad > 0)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      modulo.cantidad > 99 ? '99+' : modulo.cantidad.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                if (modulo.cargandoCantidad || modulo.cantidad > 0)
                  const SizedBox(width: 8),

                const Icon(Icons.chevron_right),
              ],
            ),
            onTap:
                modulo.onTap ??
                () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Módulo ${modulo.titulo} en construcción.',
                        ),
                      ),
                    );
                },
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// TARJETA DEL DASHBOARD SST EDURISK
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

  /// Color asociado al módulo según la identidad SST EduRisk.
  final Color color;

  /// Permite usar un tono más oscuro cuando sea necesario,
  /// especialmente con el amarillo.
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
            // ===================================================
            // BARRA DE COLOR
            // ===================================================
            Container(width: 5, color: color),

            // ===================================================
            // CONTENIDO
            // ===================================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ===========================================
                    // ICONO
                    // ===========================================
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

                    // ===========================================
                    // INFORMACIÓN
                    // ===========================================
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

                          const SizedBox(height: 5),

                          Text(
                            descripcion,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.35),
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

/// Información visual de un módulo.
class ModuloItem {
  const ModuloItem({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.onTap,
    this.cantidad = 0,
    this.cargandoCantidad = false,
  });

  final IconData icono;

  final String titulo;

  final String descripcion;

  final VoidCallback? onTap;

  /// Cantidad pendiente que se mostrará como badge.
  final int cantidad;

  /// Indica si el contador todavía se está consultando.
  final bool cargandoCantidad;
}
