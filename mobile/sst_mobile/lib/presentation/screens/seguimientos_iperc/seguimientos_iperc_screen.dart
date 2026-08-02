import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/seguimiento_iperc_model.dart';
import '../../providers/seguimiento_iperc_provider.dart';
import 'seguimiento_iperc_form_screen.dart';

/// Lista y administra los seguimientos IPERC registrados.
class SeguimientosIpercScreen extends StatelessWidget {
  const SeguimientosIpercScreen({
    this.detalleIpercId,
    this.titulo = 'Seguimientos IPERC',
    super.key,
  });

  final int? detalleIpercId;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SeguimientoIpercProvider>(
      create: (_) {
        final SeguimientoIpercProvider provider = SeguimientoIpercProvider();
        Future<void>.microtask(() {
          final int? detalleId = detalleIpercId;
          if (detalleId != null && detalleId > 0) {
            return provider.cargarPorDetalle(detalleId);
          }

          return provider.cargarTodos();
        });
        return provider;
      },
      child: _SeguimientosIpercView(
        detalleIpercId: detalleIpercId,
        titulo: titulo,
      ),
    );
  }
}

class _SeguimientosIpercView extends StatefulWidget {
  const _SeguimientosIpercView({required this.titulo, this.detalleIpercId});

  final int? detalleIpercId;
  final String titulo;

  @override
  State<_SeguimientosIpercView> createState() {
    return _SeguimientosIpercViewState();
  }
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

  Future<void> _abrirNuevo() async {
    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();

    final bool? registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<SeguimientoIpercProvider>.value(
          value: provider,
          child: SeguimientoIpercFormScreen(
            detalleIpercIdInicial: widget.detalleIpercId,
          ),
        ),
      ),
    );

    if (!mounted || registrado != true) {
      return;
    }

    await _actualizar();
  }

  Future<void> _abrirEditar(SeguimientoIpercModel seguimiento) async {
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

  Future<void> _confirmarEliminar(SeguimientoIpercModel seguimiento) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar seguimiento'),
          content: Text(
            '¿Deseas eliminar el seguimiento de "${seguimiento.detalleVisible}"?',
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

    if (!mounted || confirmado != true) {
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

  Future<void> _verificar(SeguimientoIpercModel seguimiento) async {
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

              return RefreshIndicator(
                onRefresh: _actualizar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: <Widget>[
                    _ResumenSeguimientos(provider: provider),
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
                    if (provider.seguimientosFiltrados.isEmpty)
                      _VacioCard(buscando: provider.terminoBusqueda.isNotEmpty)
                    else
                      ...List<Widget>.generate(
                        provider.seguimientosFiltrados.length,
                        (int index) {
                          final SeguimientoIpercModel seguimiento =
                              provider.seguimientosFiltrados[index];
                          final bool esUltimo =
                              index ==
                              provider.seguimientosFiltrados.length - 1;

                          return Padding(
                            padding: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
                            child: _SeguimientoCard(
                              seguimiento: seguimiento,
                              onEditar: () => _abrirEditar(seguimiento),
                              onEliminar: () => _confirmarEliminar(seguimiento),
                              onVerificar: seguimiento.verificado
                                  ? null
                                  : () => _verificar(seguimiento),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
      ),
    );
  }
}

class _ResumenSeguimientos extends StatelessWidget {
  const _ResumenSeguimientos({required this.provider});

  final SeguimientoIpercProvider provider;

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
              child: _ResumenDato(
                etiqueta: 'Total',
                valor: provider.total.toString(),
              ),
            ),
            Expanded(
              child: _ResumenDato(
                etiqueta: 'Pendientes',
                valor: provider.pendientes.toString(),
              ),
            ),
            Expanded(
              child: _ResumenDato(
                etiqueta: 'Verificados',
                valor: provider.verificados.toString(),
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

class _SeguimientoCard extends StatelessWidget {
  const _SeguimientoCard({
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
                  backgroundColor: seguimiento.verificado
                      ? colors.primaryContainer
                      : colors.errorContainer,
                  child: Icon(
                    seguimiento.verificado
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
                        seguimiento.detalleVisible,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatearFecha(seguimiento.fechaSeguimiento)),
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
            Text(seguimiento.descripcion),
            if ((seguimiento.observaciones ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('Obs.: ${seguimiento.observaciones}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.percent, size: 18),
                  label: Text(
                    '${seguimiento.porcentajeAvance.toStringAsFixed(0)}%',
                  ),
                ),
                Chip(
                  avatar: Icon(
                    seguimiento.verificado
                        ? Icons.check_circle_outline
                        : Icons.schedule_outlined,
                    size: 18,
                  ),
                  label: Text(seguimiento.estadoVisible),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
  final String anio = fecha.year.toString();
  return '$dia/$mes/$anio';
}
