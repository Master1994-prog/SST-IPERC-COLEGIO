import 'package:flutter/material.dart';

// Modelo de la matriz IPERC.
import '../../../data/models/matriz_iperc_model.dart';

// Repositorio utilizado para volver a consultar la matriz por su ID.
import '../../../data/repositories/matriz_iperc_repository.dart';

// Pantallas que se abrirán desde el detalle de la matriz.
import '../controles/controles_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';
import 'detalles_iperc_screen.dart';

/// Pantalla que muestra toda la información de una matriz IPERC.
///
/// Desde esta pantalla se puede ingresar a:
/// - Peligros y riesgos.
/// - Matriz de riesgo 5×5.
/// - Controles.
/// - Seguimientos.
class MatrizIpercDetailScreen extends StatefulWidget {
  const MatrizIpercDetailScreen({
    required this.matriz,
    super.key,
  });

  /// Matriz seleccionada desde el listado.
  final MatrizIpercModel matriz;

  @override
  State<MatrizIpercDetailScreen> createState() {
    return _MatrizIpercDetailScreenState();
  }
}

class _MatrizIpercDetailScreenState
    extends State<MatrizIpercDetailScreen> {
  /// Repositorio para consultar la matriz actualizada.
  final MatrizIpercRepository _repository = MatrizIpercRepository();

  /// Matriz que se mostrará en la pantalla.
  late MatrizIpercModel matriz;

  /// Indica si se está consultando nuevamente la matriz.
  bool _cargandoDetalle = false;

  @override
  void initState() {
    super.initState();

    // Primero mostramos la matriz recibida desde el listado.
    matriz = widget.matriz;

    // Después consultamos el detalle actualizado en el backend.
    _cargarDetalleActualizado();
  }

  /// Consulta nuevamente la matriz usando su ID.
  ///
  /// Esto permite obtener los nombres actualizados de:
  /// - Institución.
  /// - Área.
  /// - Actividad.
  Future<void> _cargarDetalleActualizado() async {
    // Si la matriz todavía no tiene un ID válido, no hacemos la consulta.
    if (matriz.id <= 0) {
      return;
    }

    setState(() {
      _cargandoDetalle = true;
    });

    try {
      final MatrizIpercModel matrizActualizada =
          await _repository.obtenerMatrizPorId(matriz.id);

      // Verificamos que la pantalla siga abierta.
      if (!mounted) {
        return;
      }

      setState(() {
        matriz = matrizActualizada;
      });
    } catch (_) {
      // Si falla la consulta, conservamos la matriz recibida
      // desde la pantalla anterior.
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDetalle = false;
        });
      }
    }
  }

  /// Abre la pantalla de peligros y riesgos de esta matriz.
  Future<void> _abrirPeligrosYRiesgos() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return DetallesIpercScreen(
            matriz: matriz,
          );
        },
      ),
    );

    // Cuando regresamos, actualizamos nuevamente los datos.
    if (mounted) {
      await _cargarDetalleActualizado();
    }
  }

  /// Abre la matriz visual de riesgo 5×5.
  void _abrirMatrizRiesgo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const MatrizRiesgoScreen();
        },
      ),
    );
  }

  /// Abre el catálogo de controles.
  void _abrirControles() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const ControlesScreen();
        },
      ),
    );
  }

  /// Abre la pantalla de seguimientos IPERC.
  void _abrirSeguimientos() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const SeguimientosIpercScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          matriz.codigo.isEmpty
              ? 'Detalle de matriz'
              : matriz.codigo,
        ),
        actions: <Widget>[
          // Botón para volver a consultar la matriz.
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargandoDetalle
                ? null
                : _cargarDetalleActualizado,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // Permite actualizar deslizando hacia abajo.
      body: RefreshIndicator(
        onRefresh: _cargarDetalleActualizado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Barra de progreso durante la recarga.
            if (_cargandoDetalle) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],

            // Encabezado con código, nombre y estado.
            _EncabezadoMatriz(matriz: matriz),

            const SizedBox(height: 16),

            // Información principal de la matriz.
            _SeccionCard(
              titulo: 'Información general',
              icono: Icons.info_outline,
              children: <Widget>[
                _DatoFila(
                  etiqueta: 'Código',
                  valor: _textoObligatorio(matriz.codigo),
                ),
                _DatoFila(
                  etiqueta: 'Nombre',
                  valor: _textoObligatorio(matriz.nombre),
                ),
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

            // Información de la institución, área y actividad.
            _SeccionCard(
              titulo: 'Organización',
              icono: Icons.apartment_outlined,
              children: <Widget>[
                _DatoFila(
                  etiqueta: 'Institución',
                  valor: matriz.institucionVisible,
                ),
                _DatoFila(
                  etiqueta: 'Área',
                  valor: matriz.areaVisible,
                ),
                _DatoFila(
                  etiqueta: 'Actividad',
                  valor: matriz.actividadVisible,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Opciones funcionales de la matriz.
            _SeccionCard(
              titulo: 'Evaluación IPERC',
              icono: Icons.grid_view_outlined,
              children: <Widget>[
                // Esta opción ya no muestra "en construcción".
                _AccionMatriz(
                  icono: Icons.list_alt,
                  titulo: 'Peligros y riesgos',
                  descripcion:
                      'Registrar y consultar peligros, consecuencias y evaluaciones.',
                  onTap: _abrirPeligrosYRiesgos,
                ),

                const Divider(),

                // Abre la matriz visual de evaluación 5×5.
                _AccionMatriz(
                  icono: Icons.grid_on,
                  titulo: 'Matriz de riesgo 5×5',
                  descripcion:
                      'Visualizar probabilidad, severidad y nivel de riesgo.',
                  onTap: _abrirMatrizRiesgo,
                ),

                const Divider(),

                // Abre la pantalla real de controles.
                _AccionMatriz(
                  icono: Icons.shield_outlined,
                  titulo: 'Controles',
                  descripcion:
                      'Consultar y administrar las medidas de control.',
                  onTap: _abrirControles,
                ),

                const Divider(),

                // Abre la pantalla real de seguimientos.
                _AccionMatriz(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Seguimientos',
                  descripcion:
                      'Revisar avances, evidencias y observaciones.',
                  onTap: _abrirSeguimientos,
                ),
              ],
            ),

            // Espacio inferior para que la última tarjeta
            // no quede pegada al borde de la pantalla.
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Devuelve un texto alternativo cuando un campo opcional está vacío.
  static String _textoOpcional(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'No registrado';
    }

    return valor.trim();
  }

  /// Devuelve un texto alternativo para campos obligatorios vacíos.
  static String _textoObligatorio(String valor) {
    if (valor.trim().isEmpty) {
      return 'No disponible';
    }

    return valor.trim();
  }
}

/// Encabezado principal de la matriz.
///
/// Muestra:
/// - Icono.
/// - Código.
/// - Nombre.
/// - Estado.
class _EncabezadoMatriz extends StatelessWidget {
  const _EncabezadoMatriz({
    required this.matriz,
  });

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: matriz.activo
                  ? colores.primaryContainer
                  : colores.surfaceContainerHighest,
              child: Icon(
                matriz.activo
                    ? Icons.assignment
                    : Icons.assignment_outlined,
                size: 30,
                color: matriz.activo
                    ? colores.onPrimaryContainer
                    : colores.onSurfaceVariant,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    matriz.codigo.isEmpty
                        ? 'Sin código'
                        : matriz.codigo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colores.primary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    matriz.nombre.isEmpty
                        ? 'Matriz IPERC'
                        : matriz.nombre,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    label: Text(
                      matriz.activo ? 'Activa' : 'Inactiva',
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

/// Tarjeta reutilizable para agrupar información.
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
                Icon(
                  icono,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
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
  const _DatoFila({
    required this.etiqueta,
    required this.valor,
  });

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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              valor.trim().isEmpty ? 'No registrado' : valor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opción de navegación dentro de la matriz IPERC.
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
      leading: CircleAvatar(
        child: Icon(icono),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(descripcion),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
