import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/peligro_model.dart';
import '../../providers/peligro_provider.dart';
import '../../providers/tipo_peligro_provider.dart';
import 'editar_peligro_screen.dart';
import 'nuevo_peligro_screen.dart';

/// Pantalla principal del módulo Peligros.
class PeligrosScreen extends StatelessWidget {
  const PeligrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PeligroProvider>(
          create: (_) {
            final PeligroProvider provider = PeligroProvider();

            Future<void>.microtask(provider.cargarPeligros);

            return provider;
          },
        ),
        ChangeNotifierProvider<TipoPeligroProvider>(
          create: (_) {
            return TipoPeligroProvider();
          },
        ),
      ],
      child: const _PeligrosView(),
    );
  }
}

/// Vista interna del módulo.
class _PeligrosView extends StatefulWidget {
  const _PeligrosView();

  @override
  State<_PeligrosView> createState() {
    return _PeligrosViewState();
  }
}

class _PeligrosViewState extends State<_PeligrosView> {
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Recarga los peligros desde el backend.
  Future<void> _actualizar() async {
    await context.read<PeligroProvider>().cargarPeligros();
  }

  /// Abre el formulario para registrar un peligro.
  Future<void> _abrirNuevoPeligro() async {
    final PeligroProvider peligroProvider = context.read<PeligroProvider>();

    final TipoPeligroProvider tipoProvider = context
        .read<TipoPeligroProvider>();

    final bool? creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<PeligroProvider>.value(
                value: peligroProvider,
              ),
              ChangeNotifierProvider<TipoPeligroProvider>.value(
                value: tipoProvider,
              ),
            ],
            child: const NuevoPeligroScreen(usuarioRegistroId: 1),
          );
        },
      ),
    );

    if (!mounted || creado != true) {
      return;
    }

    await peligroProvider.cargarPeligros();
  }

  /// Abre el formulario de edición.
  Future<void> _abrirEditarPeligro(PeligroModel peligro) async {
    final PeligroProvider peligroProvider = context.read<PeligroProvider>();

    final TipoPeligroProvider tipoProvider = context
        .read<TipoPeligroProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<PeligroProvider>.value(
                value: peligroProvider,
              ),
              ChangeNotifierProvider<TipoPeligroProvider>.value(
                value: tipoProvider,
              ),
            ],
            child: EditarPeligroScreen(
              peligro: peligro,
              usuarioActualizacionId: 1,
            ),
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await peligroProvider.cargarPeligros();
  }

  /// Solicita confirmación antes de eliminar
  /// o desactivar un peligro.
  Future<void> _confirmarEliminar(PeligroModel peligro) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar peligro'),
          content: Text(
            '¿Deseas eliminar o desactivar '
            '"${peligro.nombre}"?',
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

    final PeligroProvider provider = context.read<PeligroProvider>();

    final bool eliminado = await provider.eliminarPeligro(peligro.id);

    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (eliminado) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Peligro eliminado o desactivado correctamente.'),
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
            provider.mensajeError ?? 'No se pudo eliminar el peligro.',
          ),
        ),
      );
  }

  /// Muestra los datos completos de un peligro.
  void _mostrarDetalle(PeligroModel peligro) {
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
            child: SingleChildScrollView(
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
                          Icons.warning_amber_rounded,
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
                              peligro.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              peligro.codigo.trim().isEmpty
                                  ? 'Sin código'
                                  : peligro.codigo,
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
                    titulo: 'Descripción',
                    valor: peligro.descripcionVisible,
                    icono: Icons.description_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Categoría',
                    valor: peligro.categoriaVisible,
                    icono: Icons.category_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Tipo de peligro',
                    valor: peligro.tipoVisible,
                    icono: Icons.account_tree_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Fuente',
                    valor: peligro.fuenteVisible,
                    icono: Icons.electric_bolt_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Medio',
                    valor: peligro.medioVisible,
                    icono: Icons.route_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Receptor',
                    valor: peligro.receptorVisible,
                    icono: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Requisito legal',
                    valor: peligro.requisitoLegalVisible,
                    icono: Icons.policy_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Recomendaciones',
                    valor: peligro.recomendacionesVisible,
                    icono: Icons.fact_check_outlined,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    titulo: 'Estado',
                    valor: peligro.estaDisponible ? 'Activo' : 'Inactivo',
                    icono: peligro.estaDisponible
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop();

                            _abrirEditarPeligro(peligro);
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

                            _confirmarEliminar(peligro);
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peligros'),
        actions: <Widget>[
          Consumer<PeligroProvider>(
            builder:
                (
                  BuildContext context,
                  PeligroProvider provider,
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
        onPressed: _abrirNuevoPeligro,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo peligro'),
      ),
      body: Consumer<PeligroProvider>(
        builder:
            (BuildContext context, PeligroProvider provider, Widget? child) {
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

  /// Construye las tarjetas de resumen.
  Widget _construirResumen(PeligroProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ResumenCard(
              titulo: 'Total',
              valor: provider.cantidadTotal,
              icono: Icons.warning_amber_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumenCard(
              titulo: 'Activos',
              valor: provider.cantidadActivos,
              icono: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumenCard(
              titulo: 'Inactivos',
              valor: provider.cantidadInactivos,
              icono: Icons.cancel_outlined,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el campo de búsqueda.
  Widget _construirBuscador(PeligroProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre, categoría o tipo',
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

  /// Construye el contenido según el estado.
  Widget _construirContenido(PeligroProvider provider) {
    if (provider.cargando && !provider.tienePeligros) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tienePeligros) {
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
            'No se pudieron cargar los peligros',
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
          const Icon(
            Icons.warning_amber_outlined,
            size: 78,
            color: Colors.grey,
          ),
          const SizedBox(height: 18),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'No hay peligros registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra el primer peligro para comenzar.'
                : 'Prueba con otro criterio de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevoPeligro,
              icon: const Icon(Icons.add),
              label: const Text('Registrar peligro'),
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
      itemCount: provider.peligrosFiltrados.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final PeligroModel peligro = provider.peligrosFiltrados[index];

        return _PeligroCard(
          peligro: peligro,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(peligro);
          },
          onEditar: () {
            _abrirEditarPeligro(peligro);
          },
          onEliminar: () {
            _confirmarEliminar(peligro);
          },
        );
      },
    );
  }
}

/// Tarjeta utilizada en el listado.
class _PeligroCard extends StatelessWidget {
  const _PeligroCard({
    required this.peligro,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final PeligroModel peligro;
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
                  color: peligro.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: peligro.estaDisponible
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
                      peligro.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      peligro.codigo.trim().isEmpty
                          ? 'Sin código'
                          : peligro.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _InformacionLinea(
                      icono: Icons.category_outlined,
                      texto: peligro.categoriaVisible,
                    ),
                    const SizedBox(height: 4),
                    _InformacionLinea(
                      icono: Icons.account_tree_outlined,
                      texto: peligro.tipoVisible,
                    ),
                    const SizedBox(height: 8),
                    _EstadoChip(activo: peligro.estaDisponible),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !eliminando,
                tooltip: 'Opciones',
                onSelected: (String opcion) {
                  if (opcion == 'editar') {
                    onEditar();
                    return;
                  }

                  if (opcion == 'eliminar') {
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

/// Tarjeta superior de resumen.
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

/// Línea de información secundaria.
class _InformacionLinea extends StatelessWidget {
  const _InformacionLinea({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icono, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

/// Campo utilizado en el detalle inferior.
class _DetalleCampo extends StatelessWidget {
  const _DetalleCampo({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

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

/// Etiqueta del estado.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: activo
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          activo ? 'Activo' : 'Inactivo',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: activo ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
