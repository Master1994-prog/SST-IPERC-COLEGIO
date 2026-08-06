import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../controles/controles_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import 'detalles_iperc_screen.dart';

/// Pantalla que muestra la información completa de una matriz IPERC.
class MatrizIpercDetailScreen extends StatefulWidget {
  const MatrizIpercDetailScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<MatrizIpercDetailScreen> createState() {
    return _MatrizIpercDetailScreenState();
  }
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

  /// Consulta nuevamente la matriz por su ID para mostrar
  /// la información más reciente del backend.
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
      /*
       * Si la recarga falla, se conserva la información
       * recibida desde el listado de matrices.
       */
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDetalle = false;
        });
      }
    }
  }

  /// Abre la pantalla de detalles pertenecientes exclusivamente
  /// a la matriz seleccionada.
  void _abrirDetalles() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return DetallesIpercScreen(matriz: matriz);
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
            tooltip: 'Actualizar',
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
                      'La edición de la matriz se implementará en el siguiente paso.',
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
                      'Consultar los peligros, consecuencias y evaluaciones registradas únicamente en esta matriz.',
                  onTap: _abrirDetalles,
                ),

                const Divider(),

                _AccionMatriz(
                  icono: Icons.grid_on,
                  titulo: 'Matriz de riesgo 5×5',
                  descripcion:
                      'Visualizar la relación entre probabilidad, severidad y nivel de riesgo.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) {
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
                  descripcion:
                      'Consultar las medidas de control registradas en el sistema.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) {
                          return const ControlesScreen();
                        },
                      ),
                    );
                  },
                ),

                const Divider(),

                /*
                 * Los seguimientos pertenecen a un detalle IPERC,
                 * no directamente a la matriz.
                 *
                 * Por eso se abre primero la lista de detalles
                 * correspondientes a esta matriz.
                 */
                _AccionMatriz(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Seguimientos',
                  descripcion:
                      'Seleccionar un detalle IPERC de esta matriz para revisar sus avances, evidencias y observaciones.',
                  onTap: _abrirDetalles,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _textoOpcional(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'No registrado';
    }

    return texto;
  }
}

/// Encabezado con el código, nombre y estado de la matriz.
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

/// Tarjeta reutilizable para agrupar secciones.
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

/// Fila utilizada para mostrar una etiqueta y su valor.
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

/// Acción disponible dentro del detalle de una matriz.
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
