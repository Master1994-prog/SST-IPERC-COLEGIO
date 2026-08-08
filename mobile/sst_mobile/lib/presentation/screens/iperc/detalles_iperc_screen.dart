import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../providers/detalle_iperc_provider.dart';
import '../../providers/usuario_provider.dart';
import '../seguimientos/seguimientos_screen.dart';
import 'editar_detalle_iperc_screen.dart';
import 'nuevo_detalle_iperc_screen.dart';

/// Lista los peligros y riesgos registrados en una matriz IPERC.
class DetallesIpercScreen extends StatelessWidget {
  const DetallesIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DetalleIpercProvider>(
          create: (_) {
            final DetalleIpercProvider provider = DetalleIpercProvider();
            Future<void>.microtask(() => provider.cargarPorMatriz(matriz.id));
            return provider;
          },
        ),
        ChangeNotifierProvider<UsuarioProvider>(
          create: (_) {
            final UsuarioProvider provider = UsuarioProvider();
            Future<void>.microtask(provider.cargarUsuarios);
            return provider;
          },
        ),
      ],
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

  Future<void> _actualizar() async {
    await Future.wait<void>(<Future<void>>[
      context.read<DetalleIpercProvider>().cargarPorMatriz(widget.matriz.id),
      context.read<UsuarioProvider>().cargarUsuarios(),
    ]);
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
    final DetalleIpercProvider detalleProvider = context
        .read<DetalleIpercProvider>();
    final UsuarioProvider usuarioProvider = context.read<UsuarioProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<DetalleIpercProvider>.value(
              value: detalleProvider,
            ),
            ChangeNotifierProvider<UsuarioProvider>.value(
              value: usuarioProvider,
            ),
          ],
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

  Future<void> _abrirSeguimientos(DetalleIpercModel detalle) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return SeguimientosScreen(detalleIpercId: detalle.id);
        },
      ),
    );
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

    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();
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
    final String responsable = _nombreResponsable(
      context.read<UsuarioProvider>(),
      detalle.responsableImplementacionId,
    );

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
                const SizedBox(height: 8),
                _EvaluacionCard(
                  titulo: 'Evaluación inicial',
                  icono: Icons.calculate_outlined,
                  evaluacion: detalle.evaluacionInicial,
                  evaluacionId: detalle.evaluacionInicialId,
                ),
                const SizedBox(height: 12),
                _EvaluacionCard(
                  titulo: 'Evaluación residual',
                  icono: Icons.verified_user_outlined,
                  evaluacion: detalle.evaluacionResidual,
                  evaluacionId: detalle.evaluacionResidualId,
                  pendienteCuandoFalta: true,
                ),
                const SizedBox(height: 8),
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
                _DatoDetalle(
                  icono: Icons.person_outline,
                  etiqueta: 'Responsable',
                  valor: responsable,
                ),
                _DatoDetalle(
                  icono: Icons.event_outlined,
                  etiqueta: 'Fecha de compromiso',
                  valor: _formatearFecha(detalle.fechaCompromiso),
                ),
                _DatoDetalle(
                  icono: Icons.event_available_outlined,
                  etiqueta: 'Fecha de implementación',
                  valor: _formatearFecha(detalle.fechaImplementacion),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      _abrirSeguimientos(detalle);
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ver seguimientos'),
                  ),
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
    final UsuarioProvider usuarioProvider = context.watch<UsuarioProvider>();

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
                      child: _construirContenido(provider, usuarioProvider),
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

  Widget _construirContenido(
    DetalleIpercProvider provider,
    UsuarioProvider usuarioProvider,
  ) {
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
        icono: buscando ? Icons.search_off_outlined : Icons.assignment_outlined,
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
          responsableNombre: _nombreResponsable(
            usuarioProvider,
            detalle.responsableImplementacionId,
          ),
          procesando: provider.procesando,
          onTap: () => _mostrarDetalle(detalle),
          onSeguimientos: () => _abrirSeguimientos(detalle),
          onEditar: () => _abrirEditarDetalle(detalle),
          onEliminar: () => _confirmarEliminar(detalle),
        );
      },
    );
  }

  String _nombreResponsable(UsuarioProvider provider, int? responsableId) {
    if (responsableId == null || responsableId <= 0) {
      return 'Sin responsable asignado';
    }

    for (final UsuarioModel usuario in provider.usuarios) {
      if (usuario.id == responsableId) {
        return usuario.nombreVisible;
      }
    }

    if (provider.cargando) {
      return 'Cargando responsable...';
    }

    return 'Responsable no disponible';
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha registrada';
    }

    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
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
    required this.responsableNombre,
    required this.procesando,
    required this.onTap,
    required this.onSeguimientos,
    required this.onEditar,
    required this.onEliminar,
  });

  final DetalleIpercModel detalle;
  final String responsableNombre;
  final bool procesando;
  final VoidCallback onTap;
  final VoidCallback onSeguimientos;
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
                        // La evaluación inicial siempre existe
                        // en el modelo DetalleIpercModel actual.
                        _NivelRiesgoEtiqueta(
                          evaluacion: detalle.evaluacionInicial,
                        ),

                        // Consecuencia asociada al peligro.
                        _Etiqueta(
                          icono: Icons.report_problem_outlined,
                          texto: detalle.consecuenciaVisible,
                        ),

                        // Estado de la evaluación residual.
                        _Etiqueta(
                          icono: detalle.tieneEvaluacionResidual
                              ? Icons.verified_user_outlined
                              : Icons.pending_actions_outlined,
                          texto: detalle.tieneEvaluacionResidual
                              ? 'Con riesgo residual'
                              : 'Residual pendiente',
                        ),

                        // Controles asociados al detalle IPERC.
                        _Etiqueta(
                          icono: Icons.security_outlined,
                          texto: detalle.tieneControles
                              ? '${detalle.controlIds.length} control(es)'
                              : 'Sin controles',
                        ),

                        // Equipos de protección personal asociados.
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
                  if (opcion == 'seguimientos') {
                    onSeguimientos();
                  } else if (opcion == 'editar') {
                    onEditar();
                  } else if (opcion == 'eliminar') {
                    onEliminar();
                  }
                },
                itemBuilder: (_) {
                  return const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'seguimientos',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.fact_check_outlined),
                        title: Text('Seguimientos'),
                      ),
                    ),
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

/// Presenta los datos que forman una evaluación de riesgo.
class _EvaluacionCard extends StatelessWidget {
  const _EvaluacionCard({
    required this.titulo,
    required this.icono,
    required this.evaluacion,
    required this.evaluacionId,
    this.pendienteCuandoFalta = false,
  });

  final String titulo;
  final IconData icono;
  final EvaluacionDetalleIpercModel? evaluacion;
  final int? evaluacionId;
  final bool pendienteCuandoFalta;

  @override
  Widget build(BuildContext context) {
    final EvaluacionDetalleIpercModel? datos = evaluacion;
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (datos == null) {
      final bool tieneId = evaluacionId != null && evaluacionId! > 0;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icono, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pendienteCuandoFalta && !tieneId
                        ? 'Pendiente de evaluación'
                        : tieneId
                        ? 'La evaluación #$evaluacionId no incluye todavía '
                              'el detalle del cálculo.'
                        : 'Sin evaluación registrada',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final Color colorNivel = _colorDesdeHex(datos.color);
    final Color textoNivel = _colorDeTexto(colorNivel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorNivel.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorNivel.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icono, color: colorNivel),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorNivel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${datos.nivelRiesgoNombre} · ${datos.valorRiesgo}',
                  style: TextStyle(
                    color: textoNivel,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _EvaluacionFila(
            etiqueta: 'Probabilidad',
            valor: '${datos.probabilidadNombre} (${datos.valorProbabilidad})',
          ),
          _EvaluacionFila(
            etiqueta: 'Severidad',
            valor: '${datos.severidadNombre} (${datos.valorSeveridad})',
          ),
          _EvaluacionFila(etiqueta: 'Cálculo', valor: datos.calculo),
          _EvaluacionFila(
            etiqueta: 'Aceptación',
            valor: datos.esAceptable ? 'Riesgo aceptable' : 'No aceptable',
          ),
          _EvaluacionFila(
            etiqueta: 'Acción',
            valor: datos.requiereAccion
                ? 'Requiere medidas de control'
                : 'No requiere acción adicional',
          ),
          if (datos.observaciones?.trim().isNotEmpty == true)
            _EvaluacionFila(
              etiqueta: 'Observaciones',
              valor: datos.observaciones!.trim(),
            ),
        ],
      ),
    );
  }
}

class _EvaluacionFila extends StatelessWidget {
  const _EvaluacionFila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _NivelRiesgoEtiqueta extends StatelessWidget {
  const _NivelRiesgoEtiqueta({required this.evaluacion});

  final EvaluacionDetalleIpercModel evaluacion;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(evaluacion.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.assessment_outlined,
            size: 15,
            color: _colorDeTexto(color),
          ),
          const SizedBox(width: 5),
          Text(
            '${evaluacion.nivelRiesgoNombre} (${evaluacion.valorRiesgo})',
            style: TextStyle(
              color: _colorDeTexto(color),
              fontSize: 12,
              fontWeight: FontWeight.bold,
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

Color _colorDesdeHex(String valor) {
  String hexadecimal = valor.trim().replaceFirst('#', '');

  if (hexadecimal.length == 6) {
    hexadecimal = 'FF$hexadecimal';
  }

  final int? numero = int.tryParse(hexadecimal, radix: 16);
  return numero == null ? const Color(0xFF9E9E9E) : Color(numero);
}

Color _colorDeTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black;
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
