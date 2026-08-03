import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/services/detalle_iperc_sync_service.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import 'detalle_iperc_form_screen.dart';

/// Muestra los detalles IPERC almacenados localmente para una matriz.
class DetallesIpercOfflineScreen extends StatefulWidget {
  const DetallesIpercOfflineScreen({
    super.key,
    required this.matrizIdLocal,
    this.matrizIdServidor,
    this.nombreMatriz,
  });

  /// Identificador local de la matriz seleccionada.
  final String matrizIdLocal;

  /// Identificador asignado por el backend.
  ///
  /// Puede ser nulo cuando la matriz todavía no fue sincronizada.
  final int? matrizIdServidor;

  /// Nombre mostrado en el encabezado.
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

  /// Carga los detalles almacenados para la matriz.
  Future<void> _cargarDetalles({bool mostrarCarga = true}) async {
    await context.read<DetalleIpercOfflineProvider>().cargarPorMatriz(
      widget.matrizIdLocal,
      mostrarCarga: mostrarCarga,
    );
  }

  /// Calcula el siguiente número de ítem disponible.
  int _calcularSiguienteItem(List<DetalleIpercLocalModel> detalles) {
    if (detalles.isEmpty) {
      return 1;
    }

    int mayorItem = 0;

    for (final DetalleIpercLocalModel detalle in detalles) {
      if (detalle.item > mayorItem) {
        mayorItem = detalle.item;
      }
    }

    return mayorItem + 1;
  }

  /// Abre el formulario para crear o editar un detalle.
  Future<void> _abrirFormulario({DetalleIpercLocalModel? detalle}) async {
    final DetalleIpercOfflineProvider provider = context
        .read<DetalleIpercOfflineProvider>();

    final int siguienteItem = _calcularSiguienteItem(provider.detalles);

    final bool? resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return DetalleIpercFormScreen(
            matrizIdLocal: widget.matrizIdLocal,
            matrizIdServidor:
                detalle?.matrizIdServidor ?? widget.matrizIdServidor,
            siguienteItem: siguienteItem,
            detalle: detalle,
          );
        },
      ),
    );

    if (resultado == true && mounted) {
      await _cargarDetalles(mostrarCarga: false);
    }
  }

  /// Ejecuta la sincronización manual.
  Future<void> _sincronizar() async {
    final DetalleIpercOfflineProvider provider = context
        .read<DetalleIpercOfflineProvider>();

    if (!provider.tienePendientes) {
      _mostrarMensaje('No existen registros pendientes de sincronización.');
      return;
    }

    final DetalleIpercSyncResult? resultado = await provider
        .sincronizarPendientes();

    if (!mounted) {
      return;
    }

    if (resultado == null) {
      _mostrarMensaje(
        provider.errorSincronizacion ?? 'No se pudo iniciar la sincronización.',
        esError: true,
      );
      return;
    }

    if (resultado.sinPendientes) {
      _mostrarMensaje('No existen registros pendientes.');
      return;
    }

    if (resultado.exitoso) {
      _mostrarMensaje(
        '${resultado.sincronizados} '
        '${resultado.sincronizados == 1 ? 'registro sincronizado' : 'registros sincronizados'} correctamente.',
      );
      return;
    }

    if (resultado.parcialmenteExitoso) {
      _mostrarMensaje(
        'Se sincronizaron ${resultado.sincronizados} registros. '
        '${resultado.fallidos} presentaron errores.',
        esError: true,
      );
      return;
    }

    _mostrarMensaje(
      provider.errorSincronizacion ?? 'No se pudo sincronizar ningún registro.',
      esError: true,
    );
  }

  /// Solicita confirmación antes de eliminar un detalle.
  Future<void> _confirmarEliminacion(DetalleIpercLocalModel detalle) async {
    final String descripcion =
        detalle.peligroDescripcion?.trim().isNotEmpty == true
        ? detalle.peligroDescripcion!.trim()
        : detalle.tarea;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar detalle'),
          content: Text(
            '¿Desea eliminar el detalle "$descripcion"?\n\n'
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
                  return IconButton(
                    tooltip: provider.tienePendientes
                        ? 'Sincronizar ahora'
                        : 'Sin registros pendientes',
                    onPressed:
                        provider.sincronizando ||
                            provider.cargando ||
                            provider.guardando ||
                            !provider.tienePendientes
                        ? null
                        : _sincronizar,
                    icon: provider.sincronizando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Badge(
                            isLabelVisible: provider.tienePendientes,
                            label: Text('${provider.cantidadPendientes}'),
                            child: const Icon(Icons.sync),
                          ),
                  );
                },
          ),
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: () {
              _cargarDetalles(mostrarCarga: false);
            },
            icon: const Icon(Icons.refresh),
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

              return Column(
                children: <Widget>[
                  _construirEncabezado(provider),

                  if (provider.sincronizando) const LinearProgressIndicator(),

                  if (provider.tieneErrorSincronizacion)
                    _construirErrorSincronizacion(provider),

                  Expanded(
                    child: provider.detalles.isEmpty
                        ? _construirEstadoVacio()
                        : RefreshIndicator(
                            onRefresh: () =>
                                _cargarDetalles(mostrarCarga: false),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                100,
                              ),
                              itemCount: provider.detalles.length,
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                    return const SizedBox(height: 12);
                                  },
                              itemBuilder: (BuildContext context, int index) {
                                return _construirDetalle(
                                  provider.detalles[index],
                                );
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

          if (widget.matrizIdServidor == null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'La matriz todavía no tiene identificador del servidor.',
                  ),
                ),
              ],
            ),
          ],

          if (provider.tienePendientes) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 19,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${provider.cantidadPendientes} '
                    '${provider.cantidadPendientes == 1 ? 'registro pendiente' : 'registros pendientes'} '
                    'de sincronización.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: provider.procesando ? null : _sincronizar,
                  icon: provider.sincronizando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(
                    provider.sincronizando
                        ? 'Sincronizando'
                        : 'Sincronizar ahora',
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_done_outlined,
                  size: 19,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Todos los registros están sincronizados.',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirErrorSincronizacion(DetalleIpercOfflineProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.sync_problem_outlined, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.errorSincronizacion ??
                  'Ocurrió un error durante la sincronización.',
            ),
          ),
          IconButton(
            tooltip: 'Cerrar mensaje',
            onPressed: provider.limpiarErrorSincronizacion,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _construirDetalle(DetalleIpercLocalModel detalle) {
    final Color colorInicial = _obtenerColorRiesgo(detalle.valorRiesgoInicial);

    final int? valorResidual = detalle.valorRiesgoResidual;

    final String tarea = detalle.tarea.trim().isNotEmpty
        ? detalle.tarea.trim()
        : detalle.actividadDescripcion ?? 'Tarea no especificada';

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
                          'Ítem ${detalle.item}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tarea,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detalle.peligroDescripcion ??
                              'Peligro no especificado',
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
                icono: Icons.work_outline,
                titulo: 'Actividad',
                contenido:
                    detalle.actividadDescripcion ?? 'Actividad no especificada',
              ),

              const SizedBox(height: 10),

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

                  if (detalle.idServidor != null &&
                      detalle.idServidor!.trim().isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.tag, size: 18),
                      label: Text('Servidor: ${detalle.idServidor}'),
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
          const SizedBox(height: 70),
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

    if (valor <= 9) {
      return Colors.amber.shade800;
    }

    if (valor <= 16) {
      return Colors.orange.shade800;
    }

    return Colors.red.shade700;
  }
}
