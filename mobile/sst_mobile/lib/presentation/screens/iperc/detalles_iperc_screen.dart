import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../providers/detalle_iperc_provider.dart';
import 'editar_detalle_iperc_screen.dart';
import 'nuevo_detalle_iperc_screen.dart';

/// Lista los peligros y riesgos registrados en una matriz IPERC.
class DetallesIpercScreen extends StatelessWidget {
  const DetallesIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DetalleIpercProvider>(
      create: (_) {
        final DetalleIpercProvider provider = DetalleIpercProvider();
        Future<void>.microtask(() => provider.cargarPorMatriz(matriz.id));
        return provider;
      },
      child: _DetallesIpercView(matriz: matriz),
    );
  }
}

class _DetallesIpercView extends StatefulWidget {
  const _DetallesIpercView({required this.matriz});

  final MatrizIpercModel matriz;

  @override
  State<_DetallesIpercView> createState() {
    return _DetallesIpercViewState();
  }
}

class _DetallesIpercViewState extends State<_DetallesIpercView> {
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _actualizar() {
    return context.read<DetalleIpercProvider>().cargarPorMatriz(
      widget.matriz.id,
    );
  }

  Future<void> _abrirNuevoDetalle() async {
    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    final bool? registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<DetalleIpercProvider>.value(
          value: provider,
          child: NuevoDetalleIpercScreen(matriz: widget.matriz),
        ),
      ),
    );

    if (!mounted || registrado != true) {
      return;
    }

    await _actualizar();
  }

  Future<void> _abrirEditarDetalle(DetalleIpercModel detalle) async {
    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<DetalleIpercProvider>.value(
          value: provider,
          child: EditarDetalleIpercScreen(
            matriz: widget.matriz,
            detalle: detalle,
          ),
        ),
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await _actualizar();
  }

  Future<void> _confirmarEliminar(DetalleIpercModel detalle) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar peligro evaluado'),
          content: Text(
            '¿Deseas eliminar el ítem ${detalle.item}: '
            '"${detalle.peligroVisible}"?',
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

    final DetalleIpercProvider provider = context
        .read<DetalleIpercProvider>();
    final bool eliminado = await provider.eliminar(detalle.id);

    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: eliminado
              ? null
              : Theme.of(context).colorScheme.error,
          content: Text(
            eliminado
                ? 'Peligro evaluado eliminado correctamente.'
                : provider.error ?? 'No se pudo eliminar el detalle IPERC.',
          ),
        ),
      );
  }

  void _mostrarDetalle(DetalleIpercModel detalle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EncabezadoDetalle(detalle: detalle),
                const SizedBox(height: 20),
                _DatoDetalle(
                  icono: Icons.work_outline,
                  etiqueta: 'Tarea',
                  valor: detalle.tarea,
                ),
                _DatoDetalle(
                  icono: Icons.warning_amber_outlined,
                  etiqueta: 'Peligro',
                  valor: detalle.peligroVisible,
                ),
                _DatoDetalle(
                  icono: Icons.report_problem_outlined,
                  etiqueta: 'Consecuencia',
                  valor: detalle.consecuenciaVisible,
                ),
                _DatoDetalle(
                  icono: Icons.description_outlined,
                  etiqueta: 'Descripción específica',
                  valor: detalle.descripcionVisible,
                ),
                _DatoDetalle(
                  icono: Icons.calculate_outlined,
                  etiqueta: 'Evaluación inicial',
                  valor: 'ID ${detalle.evaluacionInicialId}',
                ),
                _DatoDetalle(
                  icono: Icons.verified_user_outlined,
                  etiqueta: 'Evaluación residual',
                  valor: detalle.tieneEvaluacionResidual
                      ? 'ID ${detalle.evaluacionResidualId}'
                      : 'Pendiente',
                ),
                _DatoDetalle(
                  icono: Icons.security_outlined,
                  etiqueta: 'Controles',
                  valor: detalle.tieneControles
                      ? '${detalle.controlIds.length} seleccionado(s)'
                      : 'Sin controles asignados',
                ),
                _DatoDetalle(
                  icono: Icons.health_and_safety_outlined,
                  etiqueta: 'EPP',
                  valor: detalle.tieneEquiposProteccion
                      ? '${detalle.equipoProteccionIds.length} seleccionado(s)'
                      : 'Sin EPP asignados',
                ),
                _DatoDetalle(
                  icono: Icons.task_alt_outlined,
                  etiqueta: 'Implementación',
                  valor: detalle.estadoImplementacionNombre,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop();
                          _abrirEditarDetalle(detalle);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop();
                          _confirmarEliminar(detalle);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peligros y riesgos'),
        actions: <Widget>[
          Consumer<DetalleIpercProvider>(
            builder:
                (
                  BuildContext context,
                  DetalleIpercProvider provider,
                  Widget? child,
                ) {
                  return IconButton(
                    tooltip: 'Actualizar',
                    onPressed: provider.cargando ? null : _actualizar,
                    icon: provider.cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  );
                },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevoDetalle,
        icon: const Icon(Icons.add),
        label: const Text('Agregar peligro'),
      ),
      body: Consumer<DetalleIpercProvider>(
        builder:
            (
              BuildContext context,
              DetalleIpercProvider provider,
              Widget? child,
            ) {
              return Column(
                children: <Widget>[
                  _MatrizResumen(
                    matriz: widget.matriz,
                    total: provider.cantidadDetalles,
                    conResidual: provider.cantidadConRiesgoResidual,
                  ),
                  _construirBuscador(provider),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _actualizar,
                      child: _construirContenido(provider),
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _construirBuscador(DetalleIpercProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar tarea, peligro o consecuencia',
          prefixIcon: const Icon(Icons.search),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _construirContenido(DetalleIpercProvider provider) {
    if (provider.cargando && !provider.tieneDetalles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneDetalles) {
      return _EstadoLista(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudieron cargar los peligros',
        mensaje: provider.error ?? 'Ocurrió un error inesperado.',
        accion: FilledButton.icon(
          onPressed: _actualizar,
          icon: const Icon(Icons.refresh),
          label: const Text('Volver a intentar'),
        ),
      );
    }

    final List<DetalleIpercModel> detalles = provider.detallesFiltrados;

    if (detalles.isEmpty) {
      final bool buscando = provider.terminoBusqueda.isNotEmpty;

      return _EstadoLista(
        icono: buscando
            ? Icons.search_off_outlined
            : Icons.assignment_outlined,
        titulo: buscando
            ? 'No se encontraron resultados'
            : 'La matriz todavía no tiene peligros',
        mensaje: buscando
            ? 'Prueba con otro criterio de búsqueda.'
            : 'Agrega el primer peligro y registra su evaluación de riesgo.',
        accion: buscando
            ? OutlinedButton.icon(
                onPressed: () {
                  _busquedaController.clear();
                  provider.limpiarBusqueda();
                },
                icon: const Icon(Icons.close),
                label: const Text('Limpiar búsqueda'),
              )
            : FilledButton.icon(
                onPressed: _abrirNuevoDetalle,
                icon: const Icon(Icons.add),
                label: const Text('Agregar peligro'),
              ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: detalles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final DetalleIpercModel detalle = detalles[index];

        return _DetalleCard(
          detalle: detalle,
          procesando: provider.procesando,
          onTap: () => _mostrarDetalle(detalle),
          onEditar: () => _abrirEditarDetalle(detalle),
          onEliminar: () => _confirmarEliminar(detalle),
        );
      },
    );
  }
}

class _MatrizResumen extends StatelessWidget {
  const _MatrizResumen({
    required this.matriz,
    required this.total,
    required this.conResidual,
  });

  final MatrizIpercModel matriz;
  final int total;
  final int conResidual;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: colors.primaryContainer,
            child: const Icon(Icons.assignment_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  matriz.codigo,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  matriz.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$total ítems',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$conResidual con residual',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetalleCard extends StatelessWidget {
  const _DetalleCard({
    required this.detalle,
    required this.procesando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final DetalleIpercModel detalle;
  final bool procesando;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                child: Text(
                  detalle.item > 0 ? detalle.item.toString() : '–',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      detalle.peligroVisible,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle.tarea,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _Etiqueta(
                          icono: Icons.report_problem_outlined,
                          texto: detalle.consecuenciaVisible,
                        ),
                        _Etiqueta(
                          icono: detalle.tieneEvaluacionResidual
                              ? Icons.verified_user_outlined
                              : Icons.pending_actions_outlined,
                          texto: detalle.tieneEvaluacionResidual
                              ? 'Con riesgo residual'
                              : 'Residual pendiente',
                        ),
                        _Etiqueta(
                          icono: Icons.security_outlined,
                          texto: detalle.tieneControles
                              ? '${detalle.controlIds.length} control(es)'
                              : 'Sin controles',
                        ),
                        _Etiqueta(
                          icono: Icons.health_and_safety_outlined,
                          texto: detalle.tieneEquiposProteccion
                              ? '${detalle.equipoProteccionIds.length} EPP'
                              : 'Sin EPP',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !procesando,
                tooltip: 'Opciones',
                onSelected: (String opcion) {
                  if (opcion == 'editar') {
                    onEditar();
                  } else if (opcion == 'eliminar') {
                    onEliminar();
                  }
                },
                itemBuilder: (_) {
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
                        leading: Icon(Icons.delete_outline),
                        title: Text('Eliminar'),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncabezadoDetalle extends StatelessWidget {
  const _EncabezadoDetalle({required this.detalle});

  final DetalleIpercModel detalle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 28,
          child: Text(
            detalle.item > 0 ? detalle.item.toString() : '–',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                detalle.peligroVisible,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(detalle.estadoImplementacionNombre),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icono, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  etiqueta,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(valor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 15),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoLista extends StatelessWidget {
  const _EstadoLista({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget accion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 50),
        Icon(icono, size: 76, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center),
        const SizedBox(height: 22),
        accion,
      ],
    );
  }
}
