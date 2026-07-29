import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../data/models/equipo_proteccion_model.dart';
import '../../providers/equipo_proteccion_provider.dart';
import '../../providers/tipo_equipo_proteccion_provider.dart';
import 'nuevo_equipo_proteccion_screen.dart';
import 'editar_equipo_proteccion_screen.dart';

/// Pantalla principal del módulo Equipos de Protección Personal.
///
/// Esta pantalla permite:
///
/// - Consultar los EPP registrados.
/// - Buscar por código, nombre, descripción o tipo.
/// - Visualizar el detalle de cada equipo.
/// - Actualizar el listado.
/// - Eliminar equipos.
/// - Acceder posteriormente al registro y edición.
class EquiposProteccionScreen extends StatelessWidget {
  const EquiposProteccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EquipoProteccionProvider>(
      create: (_) {
        final EquipoProteccionProvider provider = EquipoProteccionProvider();

        // Se ejecuta después de construir la primera vista.
        Future<void>.microtask(provider.cargarEquipos);

        return provider;
      },
      child: const _EquiposProteccionView(),
    );
  }
}

/// Vista interna de la pantalla.
///
/// Se utiliza un StatefulWidget porque contiene:
///
/// - El controlador del buscador.
/// - Métodos de navegación.
/// - Diálogos.
/// - Operaciones asíncronas.
class _EquiposProteccionView extends StatefulWidget {
  const _EquiposProteccionView();

  @override
  State<_EquiposProteccionView> createState() {
    return _EquiposProteccionViewState();
  }
}

class _EquiposProteccionViewState extends State<_EquiposProteccionView> {
  /// Controlador del campo de búsqueda.
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Actualiza el listado desde el backend.
  Future<void> _actualizar() async {
    await context.read<EquipoProteccionProvider>().cargarEquipos();
  }

  /// Abre el formulario para registrar un nuevo EPP.
  ///
  /// Se comparte el provider principal de equipos y se crea
  /// un provider independiente para cargar los tipos de EPP.
  Future<void> _abrirNuevoEquipo() async {
    final EquipoProteccionProvider equipoProvider = context
        .read<EquipoProteccionProvider>();

    final bool? creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<EquipoProteccionProvider>.value(
                value: equipoProvider,
              ),
              ChangeNotifierProvider<TipoEquipoProteccionProvider>(
                create: (_) => TipoEquipoProteccionProvider(),
              ),
            ],
            child: const NuevoEquipoProteccionScreen(usuarioRegistroId: 1),
          );
        },
      ),
    );

    if (!mounted || creado != true) {
      return;
    }

    await equipoProvider.cargarEquipos();
  }

  /// Abre el formulario para editar un EPP.
  ///
  /// La pantalla recibe:
  ///
  /// - El equipo seleccionado.
  /// - El provider de equipos existente.
  /// - Un provider para cargar los tipos de EPP.
  Future<void> _abrirEditarEquipo(EquipoProteccionModel equipo) async {
    final EquipoProteccionProvider equipoProvider = context
        .read<EquipoProteccionProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<EquipoProteccionProvider>.value(
                value: equipoProvider,
              ),
              ChangeNotifierProvider<TipoEquipoProteccionProvider>(
                create: (_) => TipoEquipoProteccionProvider(),
              ),
            ],
            child: EditarEquipoProteccionScreen(
              equipo: equipo,
              usuarioActualizacionId: 1,
            ),
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await equipoProvider.cargarEquipos();
  }

  /// Solicita confirmación antes de eliminar un EPP.
  Future<void> _confirmarEliminar(EquipoProteccionModel equipo) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar equipo de protección'),
          content: Text(
            '¿Deseas eliminar el equipo '
            '"${equipo.nombre}"?',
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

    final EquipoProteccionProvider provider = context
        .read<EquipoProteccionProvider>();

    final bool eliminado = await provider.eliminarEquipo(equipo.id);

    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (eliminado) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Equipo de protección eliminado correctamente.'),
        ),
      );

      return;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ??
              'No se pudo eliminar el equipo de protección.',
        ),
      ),
    );
  }

  /// Muestra el detalle completo del EPP
  /// mediante una ventana inferior.
  void _mostrarDetalle(EquipoProteccionModel equipo) {
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
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
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
                          Icons.engineering_outlined,
                          size: 31,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              equipo.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              equipo.codigo.trim().isEmpty
                                  ? 'Sin código'
                                  : equipo.codigo,
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
                    valor: equipo.descripcionVisible,
                    icono: Icons.description_outlined,
                  ),
                  const SizedBox(height: 16),
                  _DetalleCampo(
                    titulo: 'Tipo de equipo de protección',
                    valor: equipo.tipoVisible,
                    icono: Icons.category_outlined,
                  ),
                  const SizedBox(height: 16),
                  _DetalleCampo(
                    titulo: 'Estado',
                    valor: equipo.estaDisponible ? 'Activo' : 'Inactivo',
                    icono: equipo.estaDisponible
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop();

                            _abrirEditarEquipo(equipo);
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

                            _confirmarEliminar(equipo);
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
        title: const Text('Equipos de protección'),
        actions: <Widget>[
          Consumer<EquipoProteccionProvider>(
            builder:
                (
                  BuildContext context,
                  EquipoProteccionProvider provider,
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
        onPressed: _abrirNuevoEquipo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo EPP'),
      ),
      body: Consumer<EquipoProteccionProvider>(
        builder:
            (
              BuildContext context,
              EquipoProteccionProvider provider,
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

  /// Construye las tarjetas superiores de resumen.
  Widget _construirResumen(EquipoProteccionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ResumenCard(
              titulo: 'Total',
              valor: provider.cantidadTotal,
              icono: Icons.engineering_outlined,
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
              titulo: 'Con tipo',
              valor: provider.cantidadConTipo,
              icono: Icons.category_outlined,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el buscador.
  Widget _construirBuscador(EquipoProteccionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre o tipo',
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

  /// Construye el contenido según el estado
  /// actual del provider.
  Widget _construirContenido(EquipoProteccionProvider provider) {
    if (provider.cargando && !provider.tieneEquipos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneEquipos) {
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
            'No se pudieron cargar los equipos',
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
            Icons.personal_injury_outlined,
            size: 78,
            color: Colors.grey,
          ),
          const SizedBox(height: 18),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'No hay equipos registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra el primer equipo '
                      'de protección personal.'
                : 'Prueba con otro criterio '
                      'de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevoEquipo,
              icon: const Icon(Icons.add),
              label: const Text('Registrar EPP'),
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
      itemCount: provider.equiposFiltrados.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final EquipoProteccionModel equipo = provider.equiposFiltrados[index];

        return _EquipoProteccionCard(
          equipo: equipo,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(equipo);
          },
          onEditar: () {
            _abrirEditarEquipo(equipo);
          },
          onEliminar: () {
            _confirmarEliminar(equipo);
          },
        );
      },
    );
  }
}

/// Tarjeta que representa un equipo de protección.
class _EquipoProteccionCard extends StatelessWidget {
  const _EquipoProteccionCard({
    required this.equipo,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final EquipoProteccionModel equipo;
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
                  color: equipo.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.engineering_outlined,
                  color: equipo.estaDisponible
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
                      equipo.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equipo.codigo.trim().isEmpty
                          ? 'Sin código'
                          : equipo.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _InformacionLinea(
                      icono: Icons.category_outlined,
                      texto: equipo.tipoVisible,
                    ),
                    const SizedBox(height: 4),
                    _InformacionLinea(
                      icono: Icons.description_outlined,
                      texto: equipo.descripcionVisible,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    _EstadoChip(
                      texto: equipo.estaDisponible ? 'Activo' : 'Inactivo',
                      activo: equipo.estaDisponible,
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

/// Tarjeta pequeña usada en el resumen superior.
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

/// Línea con icono y texto.
class _InformacionLinea extends StatelessWidget {
  const _InformacionLinea({
    required this.icono,
    required this.texto,
    this.maxLines,
  });

  final IconData icono;
  final String texto;
  final int? maxLines;

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
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

/// Campo usado en el detalle del equipo.
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

/// Etiqueta visual para activo o inactivo.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.texto, required this.activo});

  final String texto;
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
          texto,
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
