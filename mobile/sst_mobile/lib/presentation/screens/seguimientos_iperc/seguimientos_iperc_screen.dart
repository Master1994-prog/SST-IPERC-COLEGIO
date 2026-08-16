import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/seguimiento_iperc_local_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../providers/seguimiento_iperc_provider.dart';
import 'seguimiento_iperc_form_screen.dart';

/// ===============================================================
/// PANTALLA - SEGUIMIENTOS IPERC
/// ===============================================================
///
/// Administra seguimientos provenientes de:
///
/// - Backend.
/// - SQLite.
///
/// Cuando existe conexión se muestran primero los datos remotos.
/// Los registros locales que ya tienen el mismo `idServidor` que un
/// registro remoto se ocultan para evitar duplicados.
///
/// Los seguimientos todavía pendientes de sincronización se muestran
/// con una etiqueta "Pendiente de sincronizar".
/// ===============================================================
class SeguimientosIpercScreen extends StatelessWidget {
  const SeguimientosIpercScreen({
    this.detalleIpercId,
    this.detalleIpercIdLocal,
    this.titulo = 'Seguimientos IPERC',
    super.key,
  });

  /// ID del Detalle IPERC en el backend.
  final int? detalleIpercId;

  /// UUID local del Detalle IPERC.
  final String? detalleIpercIdLocal;

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SeguimientoIpercProvider>(
      create: (_) {
        final SeguimientoIpercProvider provider = SeguimientoIpercProvider();

        Future<void>.microtask(() async {
          final String localId = detalleIpercIdLocal?.trim() ?? '';

          if (localId.isNotEmpty) {
            await provider.cargarPorDetalleLocal(localId);
            return;
          }

          final int? servidorId = detalleIpercId;

          if (servidorId != null && servidorId > 0) {
            await provider.cargarPorDetalle(servidorId);
            return;
          }

          await provider.cargarTodos();
        });

        return provider;
      },
      child: _SeguimientosIpercView(
        detalleIpercId: detalleIpercId,
        detalleIpercIdLocal: detalleIpercIdLocal,
        titulo: titulo,
      ),
    );
  }
}

class _SeguimientosIpercView extends StatefulWidget {
  const _SeguimientosIpercView({
    required this.titulo,
    this.detalleIpercId,
    this.detalleIpercIdLocal,
  });

  final int? detalleIpercId;
  final String? detalleIpercIdLocal;
  final String titulo;

  @override
  State<_SeguimientosIpercView> createState() => _SeguimientosIpercViewState();
}

class _SeguimientosIpercViewState extends State<_SeguimientosIpercView> {
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _actualizar() {
    return context.read<SeguimientoIpercProvider>().refrescar();
  }

  // =============================================================
  // NUEVO
  // =============================================================

  Future<void> _abrirNuevo() async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool? registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<SeguimientoIpercProvider>.value(
          value: provider,
          child: SeguimientoIpercFormScreen(
            detalleIpercIdInicial: widget.detalleIpercId,
            detalleIpercIdLocalInicial: widget.detalleIpercIdLocal,
          ),
        ),
      ),
    );

    if (!mounted || registrado != true) {
      return;
    }

    await _actualizar();
  }

  // =============================================================
  // EDITAR REMOTO
  // =============================================================

  Future<void> _abrirEditarRemoto(SeguimientoIpercModel seguimiento) async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<SeguimientoIpercProvider>.value(
          value: provider,
          child: SeguimientoIpercFormScreen(seguimiento: seguimiento),
        ),
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await _actualizar();
  }

  // =============================================================
  // EDITAR LOCAL
  // =============================================================

  Future<void> _abrirEditarLocal(SeguimientoIpercLocalModel seguimiento) async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<SeguimientoIpercProvider>.value(
          value: provider,
          child: SeguimientoIpercFormScreen(seguimientoLocal: seguimiento),
        ),
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await _actualizar();
  }

  // =============================================================
  // ELIMINAR REMOTO
  // =============================================================

  Future<void> _confirmarEliminarRemoto(
    SeguimientoIpercModel seguimiento,
  ) async {
    final bool confirmado = await _preguntarEliminar(
      seguimiento.detalleVisible,
    );

    if (!mounted || !confirmado) {
      return;
    }

    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool eliminado = await provider.eliminar(seguimiento.id);

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      eliminado
          ? 'Seguimiento eliminado correctamente.'
          : provider.error ?? 'No se pudo eliminar el seguimiento.',
      esError: !eliminado,
    );
  }

  // =============================================================
  // ELIMINAR LOCAL
  // =============================================================

  Future<void> _confirmarEliminarLocal(
    SeguimientoIpercLocalModel seguimiento,
  ) async {
    final bool confirmado = await _preguntarEliminar(
      seguimiento.detalleVisible,
    );

    if (!mounted || !confirmado) {
      return;
    }

    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool eliminado = await provider.eliminarOffline(
      idLocal: seguimiento.idLocal,
    );

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      eliminado
          ? 'Seguimiento eliminado localmente.'
          : provider.error ?? 'No se pudo eliminar el seguimiento.',
      esError: !eliminado,
    );
  }

  Future<bool> _preguntarEliminar(String detalleVisible) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar seguimiento'),
          content: Text(
            '¿Deseas eliminar el seguimiento de '
            '"$detalleVisible"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    return confirmado == true;
  }

  // =============================================================
  // VERIFICAR REMOTO
  // =============================================================

  Future<void> _verificarRemoto(SeguimientoIpercModel seguimiento) async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool verificado = await provider.verificar(seguimiento.id);

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      verificado
          ? 'Seguimiento verificado correctamente.'
          : provider.error ?? 'No se pudo verificar el seguimiento.',
      esError: !verificado,
    );
  }

  // =============================================================
  // VERIFICAR LOCAL
  // =============================================================

  Future<void> _verificarLocal(SeguimientoIpercLocalModel seguimiento) async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool verificado = await provider.verificarOffline(
      idLocal: seguimiento.idLocal,
    );

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      verificado
          ? 'Seguimiento verificado localmente.'
          : provider.error ?? 'No se pudo verificar el seguimiento.',
      esError: !verificado,
    );
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
          content: Text(mensaje),
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
        title: Text(widget.titulo),
        actions: <Widget>[
          Consumer<SeguimientoIpercProvider>(
            builder:
                (
                  BuildContext context,
                  SeguimientoIpercProvider provider,
                  Widget? child,
                ) {
                  return IconButton(
                    tooltip: 'Actualizar',
                    onPressed: provider.cargando ? null : _actualizar,
                    icon: provider.cargando
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  );
                },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Consumer<SeguimientoIpercProvider>(
        builder:
            (
              BuildContext context,
              SeguimientoIpercProvider provider,
              Widget? child,
            ) {
              if (provider.cargando && !provider.tieneSeguimientos) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<SeguimientoIpercModel> remotos =
                  provider.seguimientosFiltrados;

              // IDs remotos ya mostrados por el backend.
              final Set<int> idsRemotos = remotos
                  .where((SeguimientoIpercModel item) => item.id > 0)
                  .map((SeguimientoIpercModel item) => item.id)
                  .toSet();

              // Un local sincronizado se oculta si su equivalente remoto
              // ya está presente, evitando tarjetas duplicadas.
              final List<SeguimientoIpercLocalModel> locales = provider
                  .seguimientosLocalesFiltrados
                  .where(
                    (SeguimientoIpercLocalModel item) =>
                        item.idServidor == null ||
                        !idsRemotos.contains(item.idServidor),
                  )
                  .toList(growable: false);

              final int totalVisible = remotos.length + locales.length;

              return RefreshIndicator(
                onRefresh: _actualizar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: <Widget>[
                    _EstadoConexionCard(
                      conectado: provider.isConnected,
                      pendientes: provider.pendientesSincronizacion,
                    ),
                    const SizedBox(height: 12),
                    _ResumenSeguimientos(
                      total: totalVisible,
                      pendientes: _contarPendientes(remotos, locales),
                      verificados: _contarVerificados(remotos, locales),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _busquedaController,
                      onChanged: provider.buscar,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: 'Buscar seguimiento',
                        border: const OutlineInputBorder(),
                        suffixIcon: provider.terminoBusqueda.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  _busquedaController.clear();
                                  provider.limpiarBusqueda();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    if (provider.tieneError) ...<Widget>[
                      const SizedBox(height: 12),
                      _ErrorCard(mensaje: provider.error!),
                    ],
                    const SizedBox(height: 12),
                    if (totalVisible == 0)
                      _VacioCard(buscando: provider.terminoBusqueda.isNotEmpty)
                    else ...<Widget>[
                      // Registros locales pendientes o no presentes en
                      // el resultado remoto.
                      ...locales.map(
                        (SeguimientoIpercLocalModel seguimiento) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SeguimientoLocalCard(
                            seguimiento: seguimiento,
                            onEditar: () => _abrirEditarLocal(seguimiento),
                            onEliminar: () =>
                                _confirmarEliminarLocal(seguimiento),
                            onVerificar: seguimiento.verificado
                                ? null
                                : () => _verificarLocal(seguimiento),
                          ),
                        ),
                      ),

                      // Registros confirmados por backend.
                      ...remotos.map(
                        (SeguimientoIpercModel seguimiento) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SeguimientoRemotoCard(
                            seguimiento: seguimiento,
                            onEditar: () => _abrirEditarRemoto(seguimiento),
                            onEliminar: () =>
                                _confirmarEliminarRemoto(seguimiento),
                            onVerificar: seguimiento.verificado
                                ? null
                                : () => _verificarRemoto(seguimiento),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
      ),
    );
  }

  int _contarPendientes(
    List<SeguimientoIpercModel> remotos,
    List<SeguimientoIpercLocalModel> locales,
  ) {
    return remotos
            .where((SeguimientoIpercModel item) => !item.verificado)
            .length +
        locales
            .where((SeguimientoIpercLocalModel item) => !item.verificado)
            .length;
  }

  int _contarVerificados(
    List<SeguimientoIpercModel> remotos,
    List<SeguimientoIpercLocalModel> locales,
  ) {
    return remotos
            .where((SeguimientoIpercModel item) => item.verificado)
            .length +
        locales
            .where((SeguimientoIpercLocalModel item) => item.verificado)
            .length;
  }
}

// ===============================================================
// ESTADO DE CONEXIÓN
// ===============================================================

class _EstadoConexionCard extends StatelessWidget {
  const _EstadoConexionCard({
    required this.conectado,
    required this.pendientes,
  });

  final bool conectado;
  final int pendientes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          conectado ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        ),
        title: Text(conectado ? 'Modo online' : 'Modo offline'),
        subtitle: Text(
          pendientes > 0
              ? '$pendientes seguimiento(s) '
                    'pendiente(s) de sincronizar.'
              : conectado
              ? 'Conexión disponible.'
              : 'Los cambios se guardarán '
                    'en el dispositivo.',
        ),
      ),
    );
  }
}

// ===============================================================
// RESUMEN
// ===============================================================

class _ResumenSeguimientos extends StatelessWidget {
  const _ResumenSeguimientos({
    required this.total,
    required this.pendientes,
    required this.verificados,
  });

  final int total;
  final int pendientes;
  final int verificados;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _ResumenDato(etiqueta: 'Total', valor: total.toString()),
            ),
            Expanded(
              child: _ResumenDato(
                etiqueta: 'Pendientes',
                valor: pendientes.toString(),
              ),
            ),
            Expanded(
              child: _ResumenDato(
                etiqueta: 'Verificados',
                valor: verificados.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenDato extends StatelessWidget {
  const _ResumenDato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          valor,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(etiqueta, textAlign: TextAlign.center),
      ],
    );
  }
}

// ===============================================================
// TARJETA LOCAL
// ===============================================================

class _SeguimientoLocalCard extends StatelessWidget {
  const _SeguimientoLocalCard({
    required this.seguimiento,
    required this.onEditar,
    required this.onEliminar,
    this.onVerificar,
  });

  final SeguimientoIpercLocalModel seguimiento;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onVerificar;

  @override
  Widget build(BuildContext context) {
    return _SeguimientoBaseCard(
      detalleVisible: seguimiento.detalleVisible,
      fechaSeguimiento: seguimiento.fechaSeguimiento,
      descripcion: seguimiento.descripcion,
      observaciones: seguimiento.observaciones,
      porcentajeAvance: seguimiento.porcentajeAvance,
      verificado: seguimiento.verificado,
      sincronizado: seguimiento.sincronizado,
      esLocal: true,
      onEditar: onEditar,
      onEliminar: onEliminar,
      onVerificar: onVerificar,
    );
  }
}

// ===============================================================
// TARJETA REMOTA
// ===============================================================

class _SeguimientoRemotoCard extends StatelessWidget {
  const _SeguimientoRemotoCard({
    required this.seguimiento,
    required this.onEditar,
    required this.onEliminar,
    this.onVerificar,
  });

  final SeguimientoIpercModel seguimiento;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onVerificar;

  @override
  Widget build(BuildContext context) {
    return _SeguimientoBaseCard(
      detalleVisible: seguimiento.detalleVisible,
      fechaSeguimiento: seguimiento.fechaSeguimiento,
      descripcion: seguimiento.descripcion,
      observaciones: seguimiento.observaciones,
      porcentajeAvance: seguimiento.porcentajeAvance,
      verificado: seguimiento.verificado,
      sincronizado: true,
      esLocal: false,
      onEditar: onEditar,
      onEliminar: onEliminar,
      onVerificar: onVerificar,
    );
  }
}

// ===============================================================
// TARJETA COMÚN
// ===============================================================

class _SeguimientoBaseCard extends StatelessWidget {
  const _SeguimientoBaseCard({
    required this.detalleVisible,
    required this.fechaSeguimiento,
    required this.descripcion,
    required this.porcentajeAvance,
    required this.verificado,
    required this.sincronizado,
    required this.esLocal,
    required this.onEditar,
    required this.onEliminar,
    this.observaciones,
    this.onVerificar,
  });

  final String detalleVisible;
  final DateTime fechaSeguimiento;
  final String descripcion;
  final String? observaciones;
  final double porcentajeAvance;
  final bool verificado;
  final bool sincronizado;
  final bool esLocal;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onVerificar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: verificado
                      ? colors.primaryContainer
                      : colors.errorContainer,
                  child: Icon(
                    verificado
                        ? Icons.verified_outlined
                        : Icons.pending_actions_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        detalleVisible,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatearFecha(fechaSeguimiento)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'editar':
                        onEditar();
                        break;
                      case 'verificar':
                        onVerificar?.call();
                        break;
                      case 'eliminar':
                        onEliminar();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      if (onVerificar != null)
                        const PopupMenuItem<String>(
                          value: 'verificar',
                          child: Text('Verificar'),
                        ),
                      const PopupMenuItem<String>(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(descripcion),
            if ((observaciones ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('Obs.: ${observaciones!.trim()}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.percent, size: 18),
                  label: Text('${porcentajeAvance.toStringAsFixed(0)}%'),
                ),
                Chip(
                  avatar: Icon(
                    verificado
                        ? Icons.check_circle_outline
                        : Icons.schedule_outlined,
                    size: 18,
                  ),
                  label: Text(verificado ? 'Verificado' : 'Pendiente'),
                ),
                if (esLocal)
                  Chip(
                    avatar: Icon(
                      sincronizado
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      size: 18,
                    ),
                    label: Text(
                      sincronizado
                          ? 'Sincronizado'
                          : 'Pendiente de sincronizar',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// ERROR / VACÍO
// ===============================================================

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
  }
}

class _VacioCard extends StatelessWidget {
  const _VacioCard({required this.buscando});

  final bool buscando;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(Icons.fact_check_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              buscando
                  ? 'No se encontraron seguimientos.'
                  : 'Todavía no hay seguimientos registrados.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatearFecha(DateTime fecha) {
  final String dia = fecha.day.toString().padLeft(2, '0');

  final String mes = fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes/${fecha.year}';
}
