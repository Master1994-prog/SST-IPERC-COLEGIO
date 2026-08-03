import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../controles/controles_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';
import 'detalles_iperc_offline_screen.dart';

class MatrizIpercDetailScreen extends StatefulWidget {
  const MatrizIpercDetailScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<MatrizIpercDetailScreen> createState() =>
      _MatrizIpercDetailScreenState();
}

class _MatrizIpercDetailScreenState extends State<MatrizIpercDetailScreen> {
  final MatrizIpercRepository _repository = MatrizIpercRepository();

  late MatrizIpercModel matriz;

  bool _cargandoDetalle = false;

  @override
  void initState() {
    super.initState();

    matriz = widget.matriz;

    _cargarDetalleActualizado();
  }

  /// Recarga la matriz desde el backend para trabajar con
  /// la información más reciente.
  Future<void> _cargarDetalleActualizado() async {
    if (matriz.id <= 0) {
      return;
    }

    setState(() {
      _cargandoDetalle = true;
    });

    try {
      final MatrizIpercModel matrizActualizada = await _repository
          .obtenerMatrizPorId(matriz.id);

      if (!mounted) {
        return;
      }

      setState(() {
        matriz = matrizActualizada;
      });
    } catch (_) {
      // Si no se puede actualizar, se mantienen los datos
      // recibidos desde la pantalla anterior.
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDetalle = false;
        });
      }
    }
  }

  /// Genera un identificador local estable para una matriz
  /// que ya existe en el backend.
  String get _matrizIdLocal {
    return 'MATRIZ-SERVIDOR-${matriz.id}';
  }

  /// Abre los detalles IPERC locales de la matriz.
  void _abrirDetallesIperc() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return DetallesIpercOfflineScreen(
            matrizIdLocal: _matrizIdLocal,

            // Identificador numérico requerido por la API.
            matrizIdServidor: matriz.id,

            nombreMatriz: matriz.nombre,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(matriz.codigo),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar información',
            onPressed: _cargandoDetalle ? null : _cargarDetalleActualizado,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Editar matriz',
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La edición de la matriz se implementará posteriormente.',
                    ),
                  ),
                );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDetalleActualizado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_cargandoDetalle) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],

            _EncabezadoMatriz(matriz: matriz),

            const SizedBox(height: 16),

            _SeccionCard(
              titulo: 'Información general',
              icono: Icons.info_outline,
              children: <Widget>[
                _DatoFila(etiqueta: 'ID', valor: matriz.id.toString()),
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
                  valor: matriz.institucionVisible,
                ),
                _DatoFila(etiqueta: 'Área', valor: matriz.areaVisible),
                _DatoFila(
                  etiqueta: 'Actividad',
                  valor: matriz.actividadVisible,
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
                      'Registrar y consultar peligros, consecuencias y evaluaciones de riesgo.',
                  onTap: _abrirDetallesIperc,
                ),

                const Divider(),

                _AccionMatriz(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'Detalles IPERC offline',
                  descripcion:
                      'Trabajar con evaluaciones almacenadas localmente y pendientes de sincronización.',
                  onTap: _abrirDetallesIperc,
                ),

                const Divider(),

                _AccionMatriz(
                  icono: Icons.grid_on,
                  titulo: 'Matriz de riesgo 5×5',
                  descripcion:
                      'Visualizar probabilidad, severidad y nivel de riesgo.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return const MatrizRiesgoScreen();
                        },
                      ),
                    );
                  },
                ),

                const Divider(),

                _AccionMatriz(
                  icono: Icons.shield_outlined,
                  titulo: 'Controles',
                  descripcion: 'Consultar las medidas de control disponibles.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return const ControlesScreen();
                        },
                      ),
                    );
                  },
                ),

                const Divider(),

                _AccionMatriz(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Seguimientos',
                  descripcion: 'Revisar avances, evidencias y observaciones.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return const SeguimientosIpercScreen();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _textoOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'No registrado';
    }

    return valor.trim();
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(
                        avatar: Icon(
                          matriz.activo
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 18,
                        ),
                        label: Text(matriz.activo ? 'Activa' : 'Inactiva'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.cloud_done_outlined, size: 18),
                        label: Text('Servidor: ${matriz.id}'),
                      ),
                    ],
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
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
