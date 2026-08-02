import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_local_model.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import 'detalle_iperc_form_screen.dart';

/// Muestra los detalles IPERC almacenados localmente para una matriz.
class DetallesIpercOfflineScreen extends StatefulWidget {
  const DetallesIpercOfflineScreen({
    super.key,
    required this.matrizIdLocal,
    this.nombreMatriz,
  });

  /// Identificador local de la matriz seleccionada.
  final String matrizIdLocal;

  /// Nombre opcional que se mostrará en el encabezado.
  final String? nombreMatriz;

  @override
  State<DetallesIpercOfflineScreen> createState() =>
      _DetallesIpercOfflineScreenState();
}

class _DetallesIpercOfflineScreenState
    extends State<DetallesIpercOfflineScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDetalles();
    });
  }

  Future<void> _cargarDetalles({bool mostrarCarga = true}) async {
    await context.read<DetalleIpercOfflineProvider>().cargarPorMatriz(
      widget.matrizIdLocal,
      mostrarCarga: mostrarCarga,
    );
  }

  Future<void> _abrirFormulario({DetalleIpercLocalModel? detalle}) async {
    final bool? resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return DetalleIpercFormScreen(
            matrizIdLocal: widget.matrizIdLocal,
            detalle: detalle,
          );
        },
      ),
    );

    if (resultado == true && mounted) {
      await _cargarDetalles(mostrarCarga: false);
    }
  }

  Future<void> _confirmarEliminacion(DetalleIpercLocalModel detalle) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar detalle'),
          content: Text(
            '¿Desea eliminar el peligro '
            '"${detalle.peligroDescripcion}"?\n\n'
            'La eliminación quedará pendiente de sincronización.',
          ),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final DetalleIpercOfflineProvider provider = context
        .read<DetalleIpercOfflineProvider>();

    final bool eliminado = await provider.eliminar(detalle.idLocal);

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      eliminado
          ? 'Detalle eliminado localmente.'
          : provider.error ?? 'No se pudo eliminar el detalle.',
      esError: !eliminado,
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles IPERC'),
        actions: <Widget>[
          Consumer<DetalleIpercOfflineProvider>(
            builder:
                (
                  BuildContext context,
                  DetalleIpercOfflineProvider provider,
                  Widget? child,
                ) {
                  if (!provider.tienePendientes) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Tooltip(
                        message: 'Registros pendientes de sincronización',
                        child: Badge(
                          label: Text('${provider.cantidadPendientes}'),
                          child: const Icon(Icons.cloud_upload_outlined),
                        ),
                      ),
                    ),
                  );
                },
          ),
        ],
      ),
      body: Consumer<DetalleIpercOfflineProvider>(
        builder:
            (
              BuildContext context,
              DetalleIpercOfflineProvider provider,
              Widget? child,
            ) {
              if (provider.cargando && provider.detalles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.tieneError && provider.detalles.isEmpty) {
                return _construirError(provider);
              }

              if (provider.detalles.isEmpty) {
                return _construirEstadoVacio();
              }

              return Column(
                children: <Widget>[
                  _construirEncabezado(provider),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _cargarDetalles(mostrarCarga: false),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: provider.detalles.length,
                        separatorBuilder: (BuildContext context, int index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (BuildContext context, int index) {
                          return _construirDetalle(provider.detalles[index]);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
      ),
      floatingActionButton: Consumer<DetalleIpercOfflineProvider>(
        builder:
            (
              BuildContext context,
              DetalleIpercOfflineProvider provider,
              Widget? child,
            ) {
              return FloatingActionButton.extended(
                onPressed: provider.procesando
                    ? null
                    : () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo detalle'),
              );
            },
      ),
    );
  }

  Widget _construirEncabezado(DetalleIpercOfflineProvider provider) {
    final String titulo = widget.nombreMatriz?.trim().isNotEmpty == true
        ? widget.nombreMatriz!.trim()
        : 'Matriz IPERC';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.detalles.length} '
            '${provider.detalles.length == 1 ? 'detalle' : 'detalles'}',
          ),
          if (provider.tienePendientes) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_off_outlined,
                  size: 18,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${provider.cantidadPendientes} '
                    '${provider.cantidadPendientes == 1 ? 'registro pendiente' : 'registros pendientes'} '
                    'de sincronización',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirDetalle(DetalleIpercLocalModel detalle) {
    final Color colorInicial = _obtenerColorRiesgo(detalle.valorRiesgoInicial);

    final int? valorResidual = detalle.valorRiesgoResidual;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirFormulario(detalle: detalle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: colorInicial,
                    foregroundColor: Colors.white,
                    child: Text(
                      '${detalle.valorRiesgoInicial}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          detalle.peligroDescripcion ??
                              'Peligro no especificado',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detalle.actividadDescripcion ??
                              'Actividad no especificada',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    onSelected: (String opcion) {
                      switch (opcion) {
                        case 'editar':
                          _abrirFormulario(detalle: detalle);
                          break;
                        case 'eliminar':
                          _confirmarEliminacion(detalle);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'editar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'eliminar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _construirInformacion(
                icono: Icons.report_problem_outlined,
                titulo: 'Consecuencia',
                contenido:
                    detalle.consecuenciaDescripcion ??
                    'Consecuencia no especificada',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _construirIndicadorRiesgo(
                    texto: 'Inicial: ${detalle.nivelRiesgoInicial}',
                    valor: detalle.valorRiesgoInicial,
                  ),
                  if (valorResidual != null)
                    _construirIndicadorRiesgo(
                      texto: 'Residual: ${detalle.nivelRiesgoResidual ?? ''}',
                      valor: valorResidual,
                    ),
                  Chip(
                    avatar: Icon(
                      detalle.sincronizado
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      size: 18,
                    ),
                    label: Text(
                      detalle.sincronizado ? 'Sincronizado' : 'Pendiente',
                    ),
                  ),
                ],
              ),
              if (detalle.controlDescripcion?.trim().isNotEmpty ==
                  true) ...<Widget>[
                const SizedBox(height: 12),
                _construirInformacion(
                  icono: Icons.health_and_safety_outlined,
                  titulo: 'Controles',
                  contenido: detalle.controlDescripcion!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirIndicadorRiesgo({
    required String texto,
    required int valor,
  }) {
    final Color color = _obtenerColorRiesgo(valor);

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text(
          '$valor',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
      label: Text(texto),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.10),
    );
  }

  Widget _construirInformacion({
    required IconData icono,
    required String titulo,
    required String contenido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icono, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: contenido),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirEstadoVacio() {
    return RefreshIndicator(
      onRefresh: () => _cargarDetalles(mostrarCarga: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.assignment_outlined,
            size: 90,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No hay detalles IPERC',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre el primer peligro y su evaluación de riesgo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Registrar detalle'),
          ),
        ],
      ),
    );
  }

  Widget _construirError(DetalleIpercOfflineProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los detalles',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Ocurrió un error inesperado.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _cargarDetalles,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Color _obtenerColorRiesgo(int valor) {
    if (valor <= 4) {
      return Colors.green.shade700;
    }

    if (valor <= 12) {
      return Colors.amber.shade800;
    }

    return Colors.red.shade700;
  }
}
