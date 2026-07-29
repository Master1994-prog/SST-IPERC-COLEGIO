import 'package:flutter/material.dart';

import '../categorias_peligro/categorias_peligro_screen.dart';
import '../clasificaciones_control/clasificaciones_control_screen.dart';
import '../consecuencias/consecuencias_screen.dart';
import '../controles/controles_screen.dart';
import '../equipos_proteccion/equipos_proteccion_screen.dart';
import '../iperc/matrices_iperc_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../peligros/peligros_screen.dart';
import '../reportes/reportes_screen.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';
import '../tipos_equipo_proteccion/tipos_equipo_proteccion_screen.dart';
import '../tipos_peligro/tipos_peligro_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    required this.nombreUsuario,
    required this.rol,
    super.key,
  });

  final String nombreUsuario;
  final String rol;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceActual = 0;

  late final List<Widget> _pantallas = <Widget>[
    InicioView(nombreUsuario: widget.nombreUsuario, rol: widget.rol),
    const IpercView(),
    const SstView(),
    const MapasView(),
    const MasView(),
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

class InicioView extends StatelessWidget {
  const InicioView({required this.nombreUsuario, required this.rol, super.key});

  final String nombreUsuario;
  final String rol;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Bienvenido, $nombreUsuario',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('Rol: $rol', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        const ResumenCard(
          icono: Icons.assignment,
          titulo: 'Matrices IPERC',
          descripcion:
              'Matrices registradas para identificar peligros y evaluar riesgos.',
          resumen: '0 matrices registradas',
        ),
        const ResumenCard(
          icono: Icons.warning_amber,
          titulo: 'Riesgos críticos',
          descripcion:
              'Riesgos altos que requieren controles y atención prioritaria.',
          resumen: '0 riesgos críticos',
        ),
        const ResumenCard(
          icono: Icons.fact_check,
          titulo: 'Seguimientos',
          descripcion:
              'Controles y medidas correctivas pendientes de verificación.',
          resumen: '0 seguimientos pendientes',
        ),
        const ResumenCard(
          icono: Icons.sync,
          titulo: 'Sincronización',
          descripcion:
              'Estado de los registros guardados en modo online y offline.',
          resumen: 'Datos sincronizados',
        ),
      ],
    );
  }
}

class IpercView extends StatelessWidget {
  const IpercView({super.key});

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
                builder: (_) => const MatricesIpercScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _IpercModuloCard(
          icono: Icons.grid_view,
          titulo: 'Evaluación 5x5',
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
                builder: (_) => const SeguimientosIpercScreen(),
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

class SstView extends StatelessWidget {
  const SstView({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        ModuloItem(
          icono: Icons.category_outlined,
          titulo: 'Categorías de peligro',
          descripcion:
              'Administrar las categorías principales utilizadas para organizar los tipos de peligro.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoriasPeligroScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.account_tree_outlined,
          titulo: 'Tipos de peligro',
          descripcion:
              'Administrar los tipos utilizados para clasificar los peligros SST.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TiposPeligroScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.warning_amber_outlined,
          titulo: 'Peligros',
          descripcion:
              'Registrar fuentes, actos y situaciones que pueden causar daño.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PeligrosScreen()),
            );
          },
        ),
        ModuloItem(
          icono: Icons.personal_injury_outlined,
          titulo: 'Consecuencias',
          descripcion:
              'Registrar los posibles daños o efectos producidos por cada peligro.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConsecuenciasScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.account_tree_outlined,
          titulo: 'Clasificaciones de control',
          descripcion:
              'Administrar la jerarquía utilizada para organizar los controles SST.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ClasificacionesControlScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.health_and_safety_outlined,
          titulo: 'Controles',
          descripcion:
              'Administrar medidas para eliminar o reducir los riesgos.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ControlesScreen()),
            );
          },
        ),
        ModuloItem(
          icono: Icons.category_outlined,
          titulo: 'Tipos de EPP',
          descripcion:
              'Administrar las categorías utilizadas para clasificar los equipos de protección personal.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TiposEquipoProteccionScreen(),
              ),
            );
          },
        ),
        ModuloItem(
          icono: Icons.engineering_outlined,
          titulo: 'Equipos de protección',
          descripcion:
              'Gestionar los equipos de protección personal requeridos.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EquiposProteccionScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class MapasView extends StatelessWidget {
  const MapasView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulosList(
      modulos: <ModuloItem>[
        ModuloItem(
          icono: Icons.map,
          titulo: 'Mapas de riesgo',
          descripcion:
              'Ubicar los peligros y niveles de riesgo por área del colegio.',
        ),
        ModuloItem(
          icono: Icons.location_on,
          titulo: 'Zonas identificadas',
          descripcion: 'Consultar las zonas con riesgos bajos, medios y altos.',
        ),
      ],
    );
  }
}

class MasView extends StatelessWidget {
  const MasView({super.key});

  @override
  Widget build(BuildContext context) {
    return ModulosList(
      modulos: <ModuloItem>[
        const ModuloItem(
          icono: Icons.apartment,
          titulo: 'Áreas',
          descripcion: 'Administrar las áreas y ambientes de la institución.',
        ),
        const ModuloItem(
          icono: Icons.task_alt,
          titulo: 'Actividades',
          descripcion: 'Registrar actividades y tareas que serán evaluadas.',
        ),
        const ModuloItem(
          icono: Icons.people,
          titulo: 'Usuarios',
          descripcion: 'Administrar usuarios, roles e instituciones.',
        ),
        ModuloItem(
          icono: Icons.bar_chart,
          titulo: 'Reportes',
          descripcion:
              'Consultar reportes de riesgos, controles y seguimientos.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReportesScreen()),
            );
          },
        ),
        const ModuloItem(
          icono: Icons.person,
          titulo: 'Perfil',
          descripcion: 'Consultar la información de la cuenta y cerrar sesión.',
        ),
      ],
    );
  }
}

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
