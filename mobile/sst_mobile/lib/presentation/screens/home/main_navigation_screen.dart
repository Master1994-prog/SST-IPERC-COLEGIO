import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
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
        title: Text(_titulos[_indiceActual]),
        automaticallyImplyLeading: false,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Bienvenido, $nombreUsuario',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rol: $rol',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar resumen',
                    onPressed: provider.cargando
                        ? null
                        : provider.cargarResumen,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
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
                icono: Icons.assignment,
                titulo: 'Matrices IPERC',
                descripcion:
                    'Matrices registradas para identificar peligros y evaluar riesgos.',
                resumen:
                    '${provider.cantidadMatrices} '
                    '${provider.cantidadMatrices == 1 ? 'matriz registrada' : 'matrices registradas'}',
              ),
              ResumenCard(
                icono: Icons.warning_amber,
                titulo: 'Riesgos críticos',
                descripcion:
                    'Riesgos altos que requieren controles y atención prioritaria.',
                resumen:
                    '${provider.cantidadRiesgosCriticos} '
                    '${provider.cantidadRiesgosCriticos == 1 ? 'riesgo crítico' : 'riesgos críticos'}',
              ),
              ResumenCard(
                icono: Icons.fact_check,
                titulo: 'Seguimientos',
                descripcion:
                    'Controles y medidas correctivas pendientes de verificación.',
                resumen:
                    '${provider.cantidadSeguimientosPendientes} '
                    '${provider.cantidadSeguimientosPendientes == 1 ? 'seguimiento pendiente' : 'seguimientos pendientes'}',
              ),
              ResumenCard(
                icono: Icons.verified_outlined,
                titulo: 'Seguimientos verificados',
                descripcion:
                    'Seguimientos que ya fueron revisados y aprobados.',
                resumen:
                    '${provider.cantidadSeguimientosVerificados} '
                    '${provider.cantidadSeguimientosVerificados == 1 ? 'seguimiento verificado' : 'seguimientos verificados'}',
              ),
              const ResumenCard(
                icono: Icons.sync,
                titulo: 'Sincronización',
                descripcion:
                    'Estado de los registros guardados en modo online y offline.',
                resumen: 'Sincronización automática activa',
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
            MaterialPageRoute<void>(builder: (_) => const ControlesScreen()),
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

/// Vista de opciones adicionales.
class MasView extends StatelessWidget {
  const MasView({required this.nombreUsuario, required this.rol, super.key});

  final String nombreUsuario;
  final String rol;

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        // Módulos organizacionales:
        // SUPER_ADMIN, ADMIN y COORDINADOR.
        if (RolePermissions.puedeAdministrarCatalogos(rol))
          ModuloItem(
            icono: Icons.apartment,
            titulo: 'Áreas',
            descripcion:
                'Consultar las áreas y ambientes activos de la institución.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AreasScreen()),
            ),
          ),
        if (RolePermissions.puedeAdministrarCatalogos(rol))
          ModuloItem(
            icono: Icons.account_tree_outlined,
            titulo: 'Procesos',
            descripcion: 'Gestionar los procesos pertenecientes a cada área.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProcesosScreen()),
            ),
          ),
        if (RolePermissions.puedeAdministrarCatalogos(rol))
          ModuloItem(
            icono: Icons.task_alt,
            titulo: 'Actividades',
            descripcion: 'Registrar actividades y tareas que serán evaluadas.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ActividadesScreen(),
              ),
            ),
          ),
        if (RolePermissions.puedeAdministrarCatalogos(rol))
          ModuloItem(
            icono: Icons.badge_outlined,
            titulo: 'Puestos de trabajo',
            descripcion: 'Administrar los puestos pertenecientes a cada área.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PuestosTrabajoScreen(),
              ),
            ),
          ),

        // Solo SUPER_ADMIN según role_permissions.dart actualizado.
        if (RolePermissions.puedeAdministrarUsuarios(rol))
          ModuloItem(
            icono: Icons.manage_accounts_outlined,
            titulo: 'Usuarios',
            descripcion: 'Crear, editar, activar, desactivar y asignar roles.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const UsuariosScreen()),
            ),
          ),
        if (RolePermissions.puedeAdministrarRoles(rol))
          ModuloItem(
            icono: Icons.admin_panel_settings_outlined,
            titulo: 'Roles',
            descripcion: 'Administrar roles y permisos generales del sistema.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RolesScreen()),
            ),
          ),
        if (RolePermissions.puedeVerReportes(rol))
          ModuloItem(
            icono: Icons.bar_chart,
            titulo: 'Reportes',
            descripcion:
                'Consultar reportes de riesgos, controles y seguimientos.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ReportesScreen(rol: rol)),
            ),
          ),

        ModuloItem(
          icono: Icons.person,
          titulo: 'Perfil',
          descripcion: 'Consultar la información de la cuenta y cerrar sesión.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PerfilScreen(nombreUsuario: nombreUsuario, rol: rol),
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
            trailing: const Icon(Icons.chevron_right),
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

/// Tarjeta del dashboard.
class ResumenCard extends StatelessWidget {
  const ResumenCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.resumen,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final String resumen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(radius: 24, child: Icon(icono)),
            const SizedBox(width: 14),
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
                  Text(descripcion),
                  const SizedBox(height: 10),
                  Text(
                    resumen,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
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
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? onTap;
}
