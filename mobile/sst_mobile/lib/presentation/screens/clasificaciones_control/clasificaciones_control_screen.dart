import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/clasificacion_control_model.dart';
import '../../providers/clasificacion_control_provider.dart';
import 'nueva_clasificacion_control_screen.dart';
import 'editar_clasificacion_control_screen.dart';

/// Pantalla principal del catálogo
/// Clasificaciones de Control.
class ClasificacionesControlScreen extends StatelessWidget {
  const ClasificacionesControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClasificacionControlProvider>(
      create: (_) {
        final ClasificacionControlProvider provider =
            ClasificacionControlProvider();

        Future<void>.microtask(provider.cargarClasificaciones);

        return provider;
      },
      child: const _ClasificacionesControlView(),
    );
  }
}

/// Vista interna del módulo.
class _ClasificacionesControlView extends StatefulWidget {
  const _ClasificacionesControlView();

  @override
  State<_ClasificacionesControlView> createState() {
    return _ClasificacionesControlViewState();
  }
}

class _ClasificacionesControlViewState
    extends State<_ClasificacionesControlView> {
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Actualiza el catálogo.
  Future<void> _actualizar() async {
    await context.read<ClasificacionControlProvider>().cargarClasificaciones();
  }

  /// Se conectará con el formulario de registro
  /// en el siguiente paso.
  Future<void> _abrirNuevaClasificacion() async {
    final ClasificacionControlProvider provider = context
        .read<ClasificacionControlProvider>();

    final bool? creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ChangeNotifierProvider<ClasificacionControlProvider>.value(
            value: provider,
            child: const NuevaClasificacionControlScreen(),
          );
        },
      ),
    );

    if (!mounted || creado != true) {
      return;
    }

    await provider.cargarClasificaciones();
  }

  /// Se conectará con el formulario de edición
  /// en un siguiente paso.
  Future<void> _abrirEditarClasificacion(
    ClasificacionControlModel clasificacion,
  ) async {
    final ClasificacionControlProvider provider = context
        .read<ClasificacionControlProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ChangeNotifierProvider<ClasificacionControlProvider>.value(
            value: provider,
            child: EditarClasificacionControlScreen(
              clasificacion: clasificacion,
            ),
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await provider.cargarClasificaciones();
  }

  /// Solicita confirmación antes de eliminar
  /// o desactivar una clasificación.
  Future<void> _confirmarEliminar(
    ClasificacionControlModel clasificacion,
  ) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar clasificación'),
          content: Text(
            '¿Deseas eliminar o desactivar '
            '"${clasificacion.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) {
      return;
    }

    final ClasificacionControlProvider provider = context
        .read<ClasificacionControlProvider>();

    final bool eliminado = await provider.eliminarClasificacion(
      clasificacion.id,
    );

    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (eliminado) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Clasificación eliminada o desactivada correctamente.',
            ),
          ),
        );

      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            provider.mensajeError ?? 'No se pudo eliminar la clasificación.',
          ),
        ),
      );
  }

  /// Muestra el detalle de una clasificación.
  void _mostrarDetalle(ClasificacionControlModel clasificacion) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        final ColorScheme colorScheme = Theme.of(
          bottomSheetContext,
        ).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.tune_outlined,
                        size: 30,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            clasificacion.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clasificacion.codigo,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _DetalleCampo(
                  icono: Icons.description_outlined,
                  titulo: 'Descripción',
                  valor: clasificacion.descripcionVisible,
                ),

                const SizedBox(height: 16),

                _DetalleCampo(
                  icono: Icons.low_priority_outlined,
                  titulo: 'Prioridad',
                  valor: clasificacion.prioridad.toString(),
                ),

                const SizedBox(height: 16),

                _DetalleCampo(
                  icono: clasificacion.estaDisponible
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  titulo: 'Estado',
                  valor: clasificacion.estaDisponible ? 'Activa' : 'Inactiva',
                ),

                const SizedBox(height: 24),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop();

                          _abrirEditarClasificacion(clasificacion);
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

                          _confirmarEliminar(clasificacion);
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
        title: const Text('Clasificaciones de control'),
        actions: <Widget>[
          Consumer<ClasificacionControlProvider>(
            builder:
                (
                  BuildContext context,
                  ClasificacionControlProvider provider,
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
        onPressed: _abrirNuevaClasificacion,
        icon: const Icon(Icons.add),
        label: const Text('Nueva clasificación'),
      ),
      body: Consumer<ClasificacionControlProvider>(
        builder:
            (
              BuildContext context,
              ClasificacionControlProvider provider,
              Widget? child,
            ) {
              return Column(
                children: <Widget>[
                  _construirResumen(provider),
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

  /// Construye las tarjetas resumen.
  Widget _construirResumen(ClasificacionControlProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ResumenCard(
              titulo: 'Total',
              valor: provider.cantidadTotal,
              icono: Icons.tune_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumenCard(
              titulo: 'Activas',
              valor: provider.cantidadActivas,
              icono: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumenCard(
              titulo: 'Inactivas',
              valor: provider.cantidadInactivas,
              icono: Icons.cancel_outlined,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el buscador.
  Widget _construirBuscador(ClasificacionControlProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre o prioridad',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: provider.textoBusqueda.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _busquedaController.clear();
                    provider.limpiarBusqueda();
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  /// Construye el contenido principal.
  Widget _construirContenido(ClasificacionControlProvider provider) {
    if (provider.cargando && !provider.tieneClasificaciones) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneClasificaciones) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          Icon(
            Icons.cloud_off_outlined,
            size: 76,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 18),
          const Text(
            'No se pudieron cargar las clasificaciones',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.mensajeError ?? 'Ocurrió un error inesperado.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _actualizar,
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    if (!provider.tieneResultados) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.tune_outlined, size: 78, color: Colors.grey),
          const SizedBox(height: 18),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'No hay clasificaciones registradas'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra la primera clasificación '
                      'de control.'
                : 'Prueba con otro criterio '
                      'de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevaClasificacion,
              icon: const Icon(Icons.add),
              label: const Text('Registrar clasificación'),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                _busquedaController.clear();
                provider.limpiarBusqueda();
              },
              icon: const Icon(Icons.close),
              label: const Text('Limpiar búsqueda'),
            ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: provider.clasificacionesFiltradas.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final ClasificacionControlModel clasificacion =
            provider.clasificacionesFiltradas[index];

        return _ClasificacionCard(
          clasificacion: clasificacion,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(clasificacion);
          },
          onEditar: () {
            _abrirEditarClasificacion(clasificacion);
          },
          onEliminar: () {
            _confirmarEliminar(clasificacion);
          },
        );
      },
    );
  }
}

/// Tarjeta de una clasificación.
class _ClasificacionCard extends StatelessWidget {
  const _ClasificacionCard({
    required this.clasificacion,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final ClasificacionControlModel clasificacion;
  final bool eliminando;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: clasificacion.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.tune_outlined,
                  color: clasificacion.estaDisponible
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      clasificacion.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clasificacion.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      clasificacion.descripcionVisible,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _PrioridadChip(prioridad: clasificacion.prioridad),
                        _EstadoChip(activo: clasificacion.estaDisponible),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !eliminando,
                tooltip: 'Opciones',
                onSelected: (String opcion) {
                  if (opcion == 'editar') {
                    onEditar();
                  } else if (opcion == 'eliminar') {
                    onEliminar();
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

/// Tarjeta resumen.
class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final int valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icono, color: colorScheme.primary),
          const SizedBox(height: 5),
          Text(
            valor.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Campo de detalle.
class _DetalleCampo extends StatelessWidget {
  const _DetalleCampo({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icono, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(valor, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Indicador de prioridad.
class _PrioridadChip extends StatelessWidget {
  const _PrioridadChip({required this.prioridad});

  final int prioridad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Prioridad $prioridad',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Indicador de estado.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: activo
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        activo ? 'Activa' : 'Inactiva',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: activo ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
