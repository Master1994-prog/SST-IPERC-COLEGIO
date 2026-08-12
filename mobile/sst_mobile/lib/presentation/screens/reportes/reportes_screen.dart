import 'package:flutter/material.dart';

import '../controles/controles_screen.dart';
import '../iperc/matrices_iperc_screen.dart';
import '../mapas_riesgo/mapas_riesgo_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../seguimientos/seguimientos_screen.dart';

/// Pantalla principal del módulo de reportes.
///
/// Centraliza las consultas disponibles del sistema SST/IPERC.
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({required this.rol, super.key});

  final String rol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _construirEncabezado(context),
          const SizedBox(height: 20),
          Text(
            'Reportes disponibles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _ReporteCard(
            icono: Icons.assignment_outlined,
            titulo: 'Reporte de matrices IPERC',
            descripcion:
                'Consultar las matrices registradas, su institución, área, '
                'actividad y estado actual.',
            etiqueta: 'Ver matrices',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MatricesIpercScreen(rol: rol),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _ReporteCard(
            icono: Icons.grid_view_outlined,
            titulo: 'Reporte de evaluación de riesgos',
            descripcion:
                'Consultar la matriz de riesgo 5×5 según probabilidad, '
                'severidad y nivel de riesgo.',
            etiqueta: 'Ver evaluación',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MatrizRiesgoScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _ReporteCard(
            icono: Icons.health_and_safety_outlined,
            titulo: 'Reporte de controles SST',
            descripcion:
                'Consultar las medidas de control registradas para '
                'eliminar o reducir los riesgos.',
            etiqueta: 'Ver controles',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ControlesScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _ReporteCard(
            icono: Icons.fact_check_outlined,
            titulo: 'Reporte de seguimientos IPERC',
            descripcion:
                'Consultar seguimientos pendientes, verificados, responsables, '
                'porcentaje de avance y observaciones registradas.',
            etiqueta: 'Ver seguimientos',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SeguimientosScreen(rol: rol),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _ReporteCard(
            icono: Icons.map_outlined,
            titulo: 'Reporte de mapas de riesgo',
            descripcion:
                'Consultar la ubicación de peligros y los niveles de '
                'riesgo identificados por área.',
            etiqueta: 'Ver mapas',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapasRiesgoScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _construirAviso(),
        ],
      ),
    );
  }

  Widget _construirEncabezado(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.bar_chart,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Centro de reportes SST/IPERC',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Consulta la información registrada sobre matrices, '
                    'riesgos, controles, seguimientos y mapas de riesgo.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAviso() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'La exportación de reportes a PDF y Excel se agregará '
              'en el siguiente bloque.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta reutilizable para cada tipo de reporte.
class _ReporteCard extends StatelessWidget {
  const _ReporteCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.etiqueta,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(child: Icon(icono)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(descripcion),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Text(
                          etiqueta,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
