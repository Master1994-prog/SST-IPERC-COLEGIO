import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/tipo_peligro_model.dart';
import '../../providers/tipo_peligro_provider.dart';
import 'nuevo_tipo_peligro_screen.dart';
import 'editar_tipo_peligro_screen.dart';

/// Pantalla principal del catálogo Tipos de Peligro.
///
/// Permite:
///
/// - Listar los tipos de peligro.
/// - Buscar registros.
/// - Consultar detalles.
/// - Crear nuevos tipos.
/// - Editar registros.
/// - Eliminar o desactivar registros.
class TiposPeligroScreen extends StatelessWidget {
  const TiposPeligroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TipoPeligroProvider>(
      create: (_) {
        final TipoPeligroProvider provider = TipoPeligroProvider();

        Future<void>.microtask(provider.cargarTipos);

        return provider;
      },
      child: const _TiposPeligroView(),
    );
  }
}

/// Vista interna del módulo.
class _TiposPeligroView extends StatefulWidget {
  const _TiposPeligroView();

  @override
  State<_TiposPeligroView> createState() {
    return _TiposPeligroViewState();
  }
}

class _TiposPeligroViewState extends State<_TiposPeligroView> {
  /// Controlador del buscador.
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Recarga los datos desde el backend.
  Future<void> _actualizar() async {
    await context.read<TipoPeligroProvider>().cargarTipos();
  }

  /// Temporalmente muestra un mensaje.
  ///
  /// En el siguiente paso se conectará con la
  /// pantalla de creación.
  Future<void> _abrirNuevoTipo() async {
    final TipoPeligroProvider provider = context.read<TipoPeligroProvider>();

    final bool? creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ChangeNotifierProvider<TipoPeligroProvider>.value(
            value: provider,
            child: const NuevoTipoPeligroScreen(),
          );
        },
      ),
    );

    if (!mounted || creado != true) {
      return;
    }

    await provider.cargarTipos();
  }

  /// Temporalmente muestra un mensaje.
  ///
  /// Después se conectará con la pantalla de edición.
  Future<void> _abrirEditarTipo(TipoPeligroModel tipo) async {
    final TipoPeligroProvider provider = context.read<TipoPeligroProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ChangeNotifierProvider<TipoPeligroProvider>.value(
            value: provider,
            child: EditarTipoPeligroScreen(tipo: tipo),
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await provider.cargarTipos();
  }

  /// Solicita confirmación antes de eliminar
  /// o desactivar un tipo de peligro.
  Future<void> _confirmarEliminar(TipoPeligroModel tipo) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar tipo de peligro'),
          content: Text(
            '¿Deseas eliminar o desactivar '
            '"${tipo.nombre}"?',
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

    final TipoPeligroProvider provider = context.read<TipoPeligroProvider>();

    final bool eliminado = await provider.eliminarTipo(tipo.id);

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
              'Tipo de peligro eliminado '
              'o desactivado correctamente.',
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
            provider.mensajeError ??
                'No se pudo eliminar '
                    'el tipo de peligro.',
          ),
        ),
      );
  }

  /// Muestra los datos completos del registro.
  void _mostrarDetalle(TipoPeligroModel tipo) {
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
                          Icons.warning_amber_outlined,
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
                              tipo.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipo.codigo,
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
                    valor: tipo.descripcionVisible,
                  ),

                  const SizedBox(height: 16),

                  _DetalleCampo(
                    icono: tipo.estaDisponible
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    titulo: 'Estado',
                    valor: tipo.estaDisponible ? 'Activo' : 'Inactivo',
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop();

                            _abrirEditarTipo(tipo);
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

                            _confirmarEliminar(tipo);
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
        title: const Text('Tipos de peligro'),
        actions: <Widget>[
          Consumer<TipoPeligroProvider>(
            builder:
                (
                  BuildContext context,
                  TipoPeligroProvider provider,
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
        onPressed: _abrirNuevoTipo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo'),
      ),
      body: Consumer<TipoPeligroProvider>(
        builder:
            (
              BuildContext context,
              TipoPeligroProvider provider,
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

  /// Construye las tarjetas superiores.
  Widget _construirResumen(TipoPeligroProvider provider) {
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
  Widget _construirBuscador(TipoPeligroProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre o descripción',
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
  Widget _construirContenido(TipoPeligroProvider provider) {
    if (provider.cargando && !provider.tieneTipos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneTipos) {
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
            'No se pudieron cargar los tipos de peligro',
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
                ? 'No hay tipos de peligro registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra el primer tipo de peligro.'
                : 'Prueba con otro criterio '
                      'de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevoTipo,
              icon: const Icon(Icons.add),
              label: const Text('Registrar tipo'),
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
      itemCount: provider.tiposFiltrados.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final TipoPeligroModel tipo = provider.tiposFiltrados[index];

        return _TipoPeligroCard(
          tipo: tipo,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(tipo);
          },
          onEditar: () {
            _abrirEditarTipo(tipo);
          },
          onEliminar: () {
            _confirmarEliminar(tipo);
          },
        );
      },
    );
  }
}

/// Tarjeta de un tipo de peligro.
class _TipoPeligroCard extends StatelessWidget {
  const _TipoPeligroCard({
    required this.tipo,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final TipoPeligroModel tipo;
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
                  color: tipo.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  color: tipo.estaDisponible
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
                      tipo.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tipo.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tipo.descripcionVisible,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EstadoChip(activo: tipo.estaDisponible),
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

/// Tarjeta de resumen.
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

/// Campo del detalle inferior.
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

/// Indicador de estado.
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
