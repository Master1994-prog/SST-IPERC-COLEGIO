import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_model.dart';

class MatrizIpercDetailScreen extends StatelessWidget {
  const MatrizIpercDetailScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(matriz.codigo),
        actions: <Widget>[
          IconButton(
            tooltip: 'Editar matriz',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La edición se implementará en el siguiente paso.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _EncabezadoMatriz(matriz: matriz),
          const SizedBox(height: 16),

          _SeccionCard(
            titulo: 'Información general',
            icono: Icons.info_outline,
            children: <Widget>[
              _DatoFila(etiqueta: 'Código', valor: matriz.codigo),
              _DatoFila(etiqueta: 'Nombre', valor: matriz.nombre),
              _DatoFila(
                etiqueta: 'Objetivo',
                valor: _textoOpcional(matriz.objetivo),
              ),
              _DatoFila(
                etiqueta: 'Estado',
                valor: matriz.activo ? 'Activa' : 'Inactiva',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SeccionCard(
            titulo: 'Organización',
            icono: Icons.apartment_outlined,
            children: <Widget>[
              _DatoFila(
                etiqueta: 'Institución',
                valor: matriz.institucionId?.toString() ?? 'No asignada',
              ),
              _DatoFila(
                etiqueta: 'Área',
                valor: matriz.areaId?.toString() ?? 'No asignada',
              ),
              _DatoFila(
                etiqueta: 'Actividad',
                valor: matriz.actividadId?.toString() ?? 'No asignada',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SeccionCard(
            titulo: 'Evaluación IPERC',
            icono: Icons.grid_view_outlined,
            children: <Widget>[
              _AccionMatriz(
                icono: Icons.list_alt,
                titulo: 'Peligros y riesgos',
                descripcion:
                    'Consultar los peligros, consecuencias y evaluaciones registradas.',
                onTap: () {
                  _mostrarPendiente(context, 'Detalle de peligros y riesgos');
                },
              ),
              const Divider(),
              _AccionMatriz(
                icono: Icons.grid_on,
                titulo: 'Matriz de riesgo 5×5',
                descripcion:
                    'Visualizar probabilidad, severidad y nivel de riesgo.',
                onTap: () {
                  _mostrarPendiente(context, 'Matriz de riesgo 5×5');
                },
              ),
              const Divider(),
              _AccionMatriz(
                icono: Icons.shield_outlined,
                titulo: 'Controles',
                descripcion: 'Consultar las medidas de control asociadas.',
                onTap: () {
                  _mostrarPendiente(context, 'Controles de la matriz');
                },
              ),
              const Divider(),
              _AccionMatriz(
                icono: Icons.fact_check_outlined,
                titulo: 'Seguimientos',
                descripcion: 'Revisar avances, evidencias y observaciones.',
                onTap: () {
                  _mostrarPendiente(context, 'Seguimientos de la matriz');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _textoOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'No registrado';
    }

    return valor;
  }

  static void _mostrarPendiente(BuildContext context, String modulo) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$modulo en construcción.')));
  }
}

class _EncabezadoMatriz extends StatelessWidget {
  const _EncabezadoMatriz({required this.matriz});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              child: Icon(
                matriz.activo ? Icons.assignment : Icons.assignment_outlined,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    matriz.codigo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    matriz.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    avatar: Icon(
                      matriz.activo
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 18,
                    ),
                    label: Text(matriz.activo ? 'Activa' : 'Inactiva'),
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
                Icon(icono, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  const _DatoFila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _AccionMatriz extends StatelessWidget {
  const _AccionMatriz({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icono)),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(descripcion),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
