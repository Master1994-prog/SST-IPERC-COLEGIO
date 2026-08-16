import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_local_model.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import '../../providers/sync_provider.dart';
import 'detalle_iperc_form_screen.dart';

/// ===============================================================
/// PANTALLA OFFLINE - DETALLES IPERC
/// ===============================================================
///
/// Muestra los detalles IPERC almacenados localmente para una matriz.
///
/// IMPORTANTE:
///
/// La sincronización manual se realiza exclusivamente mediante
/// SyncProvider, que utiliza SyncService general.
///
/// De esta forma se respeta siempre:
///
/// MATRIZ_IPERC
///      ↓
/// DETALLE_IPERC
///
/// y nunca se intenta sincronizar un detalle antes de que su matriz
/// tenga un ID válido en el servidor.
/// ===============================================================
class DetallesIpercOfflineScreen extends StatefulWidget {
  const DetallesIpercOfflineScreen({
    super.key,
    required this.matrizIdLocal,
    this.matrizIdServidor,
    this.nombreMatriz,
  });

  final String matrizIdLocal;

  final int? matrizIdServidor;

  final String? nombreMatriz;

  @override
  State<DetallesIpercOfflineScreen> createState() =>
      _DetallesIpercOfflineScreenState();
}

class _DetallesIpercOfflineScreenState
    extends State<DetallesIpercOfflineScreen> {
  // =============================================================
  // INICIALIZAR
  // =============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _cargarDetalles();

      if (!mounted) {
        return;
      }

      await context.read<SyncProvider>().refreshStatus();
    });
  }

  // =============================================================
  // CARGAR DETALLES
  // =============================================================

  Future<void> _cargarDetalles({bool mostrarCarga = true}) async {
    await context.read<DetalleIpercOfflineProvider>().cargarPorMatriz(
      widget.matrizIdLocal,
      mostrarCarga: mostrarCarga,
    );
  }

  // =============================================================
  // SIGUIENTE ÍTEM
  // =============================================================

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

  // =============================================================
  // ABRIR FORMULARIO
  // =============================================================

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

      if (!mounted) {
        return;
      }

      await context.read<SyncProvider>().refreshStatus();
    }
  }

  // =============================================================
  // SINCRONIZACIÓN GLOBAL
  // =============================================================

  Future<void> _sincronizar() async {
    final SyncProvider syncProvider = context.read<SyncProvider>();

    final DetalleIpercOfflineProvider detalleProvider = context
        .read<DetalleIpercOfflineProvider>();

    if (syncProvider.isSynchronizing) {
      return;
    }

    await syncProvider.refreshStatus();

    if (!mounted) {
      return;
    }

    if (syncProvider.pendingCount <= 0 && !detalleProvider.tienePendientes) {
      _mostrarMensaje('No existen registros pendientes de sincronización.');
      return;
    }

    await syncProvider.synchronize();

    if (!mounted) {
      return;
    }

    // Recargar los detalles después del ciclo global.
    await detalleProvider.cargarPorMatriz(
      widget.matrizIdLocal,
      mostrarCarga: false,
    );

    if (!mounted) {
      return;
    }

    await syncProvider.refreshStatus();

    if (!mounted) {
      return;
    }

    switch (syncProvider.status) {
      case SyncStatus.completed:
        _mostrarMensaje(
          syncProvider.message ?? 'Sincronización completada correctamente.',
        );
        break;

      case SyncStatus.offline:
        _mostrarMensaje(
          syncProvider.message ?? 'No hay conexión con el servidor.',
          esError: true,
        );
        break;

      case SyncStatus.error:
        _mostrarMensaje(
          syncProvider.message ??
              syncProvider.lastError ??
              'Ocurrió un error durante la sincronización.',
          esError: true,
        );
        break;

      case SyncStatus.idle:
        _mostrarMensaje(
          syncProvider.message ?? 'Estado de sincronización actualizado.',
        );
        break;

      case SyncStatus.synchronizing:
        // No debería quedar en este estado porque synchronize()
        // se espera con await.
        break;
    }
  }

  // =============================================================
  // ELIMINAR DETALLE
  // =============================================================

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

    await context.read<SyncProvider>().refreshStatus();

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

  // =============================================================
  // MENSAJE
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) {
      return;
    }

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

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles IPERC'),
        actions: <Widget>[
          Consumer2<DetalleIpercOfflineProvider, SyncProvider>(
            builder:
                (
                  BuildContext context,
                  DetalleIpercOfflineProvider detalleProvider,
                  SyncProvider syncProvider,
                  Widget? child,
                ) {
                  final bool hayPendientes =
                      syncProvider.pendingCount > 0 ||
                      detalleProvider.tienePendientes;

                  final bool bloqueado =
                      syncProvider.isSynchronizing ||
                      detalleProvider.cargando ||
                      detalleProvider.guardando ||
                      !hayPendientes;

                  return IconButton(
                    tooltip: hayPendientes
                        ? 'Sincronizar ahora'
                        : 'Sin registros pendientes',
                    onPressed: bloqueado ? null : _sincronizar,
                    icon: syncProvider.isSynchronizing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Badge(
                            isLabelVisible: syncProvider.pendingCount > 0,
                            label: Text('${syncProvider.pendingCount}'),
                            child: const Icon(Icons.sync),
                          ),
                  );
                },
          ),
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: () async {
              await _cargarDetalles(mostrarCarga: false);

              if (!context.mounted) {
                return;
              }

              await context.read<SyncProvider>().refreshStatus();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer2<DetalleIpercOfflineProvider, SyncProvider>(
        builder:
            (
              BuildContext context,
              DetalleIpercOfflineProvider detalleProvider,
              SyncProvider syncProvider,
              Widget? child,
            ) {
              if (detalleProvider.cargando &&
                  detalleProvider.detalles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (detalleProvider.tieneError &&
                  detalleProvider.detalles.isEmpty) {
                return _construirError(detalleProvider);
              }

              return Column(
                children: <Widget>[
                  _construirEncabezado(detalleProvider, syncProvider),

                  if (syncProvider.isSynchronizing)
                    const LinearProgressIndicator(),

                  if (syncProvider.hasError)
                    _construirErrorSincronizacion(syncProvider),

                  Expanded(
                    child: detalleProvider.detalles.isEmpty
                        ? _construirEstadoVacio()
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _cargarDetalles(mostrarCarga: false);

                              if (!context.mounted) {
                                return;
                              }

                              await context
                                  .read<SyncProvider>()
                                  .refreshStatus();
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                100,
                              ),
                              itemCount: detalleProvider.detalles.length,
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                    return const SizedBox(height: 12);
                                  },
                              itemBuilder: (BuildContext context, int index) {
                                return _construirDetalle(
                                  detalleProvider.detalles[index],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
      ),
      floatingActionButton:
          Consumer2<DetalleIpercOfflineProvider, SyncProvider>(
            builder:
                (
                  BuildContext context,
                  DetalleIpercOfflineProvider detalleProvider,
                  SyncProvider syncProvider,
                  Widget? child,
                ) {
                  final bool bloqueado =
                      detalleProvider.cargando ||
                      detalleProvider.guardando ||
                      syncProvider.isSynchronizing;

                  return FloatingActionButton.extended(
                    onPressed: bloqueado ? null : () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo detalle'),
                  );
                },
          ),
    );
  }

  // =============================================================
  // ENCABEZADO
  // =============================================================

  Widget _construirEncabezado(
    DetalleIpercOfflineProvider detalleProvider,
    SyncProvider syncProvider,
  ) {
    final String titulo = widget.nombreMatriz?.trim().isNotEmpty == true
        ? widget.nombreMatriz!.trim()
        : 'Matriz IPERC';

    final bool hayPendientes =
        syncProvider.pendingCount > 0 || detalleProvider.tienePendientes;

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
            '${detalleProvider.detalles.length} '
            '${detalleProvider.detalles.length == 1 ? 'detalle' : 'detalles'}',
          ),

          if (widget.matrizIdServidor == null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'La matriz todavía no tiene identificador '
                    'del servidor. La sincronización global '
                    'creará primero la matriz y después '
                    'sus detalles.',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          if (hayPendientes)
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
                    syncProvider.pendingCount > 0
                        ? '${syncProvider.pendingCount} '
                              '${syncProvider.pendingCount == 1 ? 'operación pendiente' : 'operaciones pendientes'} '
                              'en la cola global.'
                        : '${detalleProvider.cantidadPendientes} '
                              '${detalleProvider.cantidadPendientes == 1 ? 'detalle pendiente' : 'detalles pendientes'} '
                              'de sincronización.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed:
                      syncProvider.isSynchronizing ||
                          detalleProvider.guardando ||
                          detalleProvider.cargando
                      ? null
                      : _sincronizar,
                  icon: syncProvider.isSynchronizing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(
                    syncProvider.isSynchronizing
                        ? 'Sincronizando'
                        : 'Sincronizar ahora',
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_done_outlined,
                  size: 19,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    syncProvider.message ??
                        'Todos los registros están sincronizados.',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // =============================================================
  // ERROR DE SINCRONIZACIÓN
  // =============================================================

  Widget _construirErrorSincronizacion(SyncProvider syncProvider) {
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
              syncProvider.message ??
                  syncProvider.lastError ??
                  'Ocurrió un error durante la sincronización.',
            ),
          ),
          IconButton(
            tooltip: 'Cerrar mensaje',
            onPressed: syncProvider.clearError,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA DETALLE
  // =============================================================

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

  // =============================================================
  // INDICADOR DE RIESGO
  // =============================================================

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

  // =============================================================
  // INFORMACIÓN
  // =============================================================

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

  // =============================================================
  // ESTADO VACÍO
  // =============================================================

  Widget _construirEstadoVacio() {
    return RefreshIndicator(
      onRefresh: () async {
        await _cargarDetalles(mostrarCarga: false);

        if (!mounted) {
          return;
        }

        await context.read<SyncProvider>().refreshStatus();
      },
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

  // =============================================================
  // ERROR DE CARGA
  // =============================================================

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
              onPressed: () async {
                await _cargarDetalles();

                if (!mounted) {
                  return;
                }

                await context.read<SyncProvider>().refreshStatus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // COLOR DE RIESGO
  // =============================================================

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
