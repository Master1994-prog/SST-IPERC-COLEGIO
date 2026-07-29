import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/control_model.dart';
import '../../providers/control_provider.dart';
import 'nuevo_control_screen.dart';
import 'editar_control_screen.dart';
import '../../providers/clasificacion_control_provider.dart';

/// Pantalla principal del módulo de medidas de control.
///
/// Permite:
///
/// - Consultar controles.
/// - Buscar por código, nombre o clasificación.
/// - Visualizar información detallada.
/// - Actualizar el listado.
/// - Eliminar controles.
/// - Acceder a las pantallas de registro y edición.
class ControlesScreen extends StatelessWidget {
  const ControlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ControlProvider>(
      create: (_) {
        final ControlProvider provider = ControlProvider();

        // Carga los controles después de construir
        // la primera vista.
        Future<void>.microtask(provider.cargarControles);

        return provider;
      },
      child: const _ControlesView(),
    );
  }
}

/// Vista interna que administra los elementos visuales
/// y el controlador del campo de búsqueda.
class _ControlesView extends StatefulWidget {
  const _ControlesView();

  @override
  State<_ControlesView> createState() {
    return _ControlesViewState();
  }
}

class _ControlesViewState extends State<_ControlesView> {
  /// Controlador del buscador.
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Recarga los controles desde el backend.
  Future<void> _actualizar() async {
    await context.read<ControlProvider>().cargarControles();
  }

  /// Abre la pantalla para registrar un nuevo control.
  ///
  /// Comparte el provider de controles y crea un provider
  /// independiente para cargar las clasificaciones activas.
  Future<void> _abrirNuevoControl() async {
    final ControlProvider controlProvider = context.read<ControlProvider>();

    final bool? creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ControlProvider>.value(
                value: controlProvider,
              ),
              ChangeNotifierProvider<ClasificacionControlProvider>(
                create: (_) => ClasificacionControlProvider(),
              ),
            ],
            child: const NuevoControlScreen(usuarioRegistroId: 1),
          );
        },
      ),
    );

    if (!mounted || creado != true) {
      return;
    }

    await controlProvider.cargarControles();
  }

  /// Abre la pantalla para editar un control.
  ///
  /// Comparte el provider de controles y crea un provider
  /// para cargar las clasificaciones disponibles.
  Future<void> _abrirEditarControl(ControlModel control) async {
    final ControlProvider controlProvider = context.read<ControlProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ControlProvider>.value(
                value: controlProvider,
              ),
              ChangeNotifierProvider<ClasificacionControlProvider>(
                create: (_) => ClasificacionControlProvider(),
              ),
            ],
            child: EditarControlScreen(
              control: control,
              usuarioActualizacionId: 1,
            ),
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await controlProvider.cargarControles();
  }

  /// Solicita confirmación antes de eliminar
  /// una medida de control.
  Future<void> _confirmarEliminar(ControlModel control) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar control'),
          content: Text(
            '¿Deseas eliminar la medida de control '
            '"${control.nombre}"?',
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

    final ControlProvider provider = context.read<ControlProvider>();

    final bool eliminado = await provider.eliminarControl(control.id);

    if (!mounted) {
      return;
    }

    if (eliminado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Control eliminado correctamente.')),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ?? 'No se pudo eliminar el control.',
        ),
      ),
    );
  }

  /// Muestra la información completa del control
  /// en una ventana inferior.
  void _mostrarDetalle(ControlModel control) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          size: 30,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              control.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              control.codigo.isEmpty
                                  ? 'Sin código'
                                  : control.codigo,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _DetalleCampo(
                    titulo: 'Descripción',
                    valor: control.descripcionVisible,
                    icono: Icons.description_outlined,
                  ),

                  const SizedBox(height: 14),

                  _DetalleCampo(
                    titulo: 'Clasificación',
                    valor: control.clasificacionVisible,
                    icono: Icons.category_outlined,
                  ),

                  const SizedBox(height: 14),

                  _DetalleCampo(
                    titulo: 'Estado',
                    valor: control.estaDisponible ? 'Activo' : 'Inactivo',
                    icono: control.estaDisponible
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

                            _abrirEditarControl(control);
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

                            _confirmarEliminar(control);
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
        title: const Text('Medidas de control'),
        actions: <Widget>[
          Consumer<ControlProvider>(
            builder:
                (
                  BuildContext context,
                  ControlProvider provider,
                  Widget? child,
                ) {
                  return IconButton(
                    tooltip: 'Actualizar',
                    onPressed: provider.cargando ? null : _actualizar,
                    icon: const Icon(Icons.refresh),
                  );
                },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevoControl,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo control'),
      ),
      body: Consumer<ControlProvider>(
        builder:
            (BuildContext context, ControlProvider provider, Widget? child) {
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

  /// Construye las tarjetas superiores
  /// con información resumida.
  Widget _construirResumen(ControlProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ResumenCard(
              titulo: 'Total',
              valor: provider.cantidadTotal,
              icono: Icons.health_and_safety_outlined,
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
              titulo: 'Clasificados',
              valor: provider.cantidadClasificados,
              icono: Icons.category_outlined,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el campo utilizado para
  /// buscar controles.
  Widget _construirBuscador(ControlProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar por código, nombre o clasificación',
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

  /// Construye el contenido principal según
  /// el estado del provider.
  Widget _construirContenido(ControlProvider provider) {
    if (provider.cargando && !provider.tieneControles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneControles) {
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
            'No se pudieron cargar los controles',
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
          const Icon(Icons.search_off_outlined, size: 78, color: Colors.grey),
          const SizedBox(height: 18),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'No hay controles registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra la primera medida '
                      'de control.'
                : 'Prueba con otro criterio '
                      'de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevoControl,
              icon: const Icon(Icons.add),
              label: const Text('Registrar control'),
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
      itemCount: provider.controlesFiltrados.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final ControlModel control = provider.controlesFiltrados[index];

        return _ControlCard(
          control: control,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(control);
          },
          onEditar: () {
            _abrirEditarControl(control);
          },
          onEliminar: () {
            _confirmarEliminar(control);
          },
        );
      },
    );
  }
}

/// Tarjeta utilizada para mostrar una medida
/// de control en el listado.
class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.control,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final ControlModel control;
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
                  color: control.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: control.estaDisponible
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
                      control.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      control.codigo.isEmpty ? 'Sin código' : control.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    _InformacionLinea(
                      icono: Icons.category_outlined,
                      texto: control.clasificacionVisible,
                    ),

                    const SizedBox(height: 4),

                    _InformacionLinea(
                      icono: Icons.description_outlined,
                      texto: control.descripcionVisible,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 8),

                    _EstadoChip(
                      texto: control.estaDisponible ? 'Activo' : 'Inactivo',
                      activo: control.estaDisponible,
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

/// Tarjeta pequeña utilizada en la sección
/// superior de resumen.
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

/// Línea informativa con icono y texto.
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

/// Campo utilizado para mostrar información
/// dentro del detalle inferior.
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

/// Etiqueta que muestra si el control
/// está activo o inactivo.
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
