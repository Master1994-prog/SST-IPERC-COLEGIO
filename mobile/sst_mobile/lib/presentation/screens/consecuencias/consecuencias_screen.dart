import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../providers/consecuencia_provider.dart';
import 'nueva_consecuencia_screen.dart';
import 'editar_consecuencia_screen.dart';

/// Pantalla principal del módulo de consecuencias.
///
/// Permite:
///
/// - Consultar consecuencias.
/// - Buscar por código, nombre o clasificación.
/// - Visualizar información detallada.
/// - Actualizar el listado.
/// - Eliminar una consecuencia.
/// - Acceder posteriormente a las pantallas de registro y edición.
class ConsecuenciasScreen extends StatelessWidget {
  const ConsecuenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConsecuenciaProvider>(
      create: (_) {
        final ConsecuenciaProvider provider = ConsecuenciaProvider();

        // Carga los datos después de construir la pantalla.
        Future<void>.microtask(provider.cargarConsecuencias);

        return provider;
      },
      child: const _ConsecuenciasView(),
    );
  }
}

/// Vista interna que contiene el estado visual de la pantalla.
class _ConsecuenciasView extends StatefulWidget {
  const _ConsecuenciasView();

  @override
  State<_ConsecuenciasView> createState() {
    return _ConsecuenciasViewState();
  }
}

class _ConsecuenciasViewState extends State<_ConsecuenciasView> {
  /// Controlador del campo de búsqueda.
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Recarga las consecuencias desde el backend.
  Future<void> _actualizar() async {
    await context.read<ConsecuenciaProvider>().cargarConsecuencias();
  }

  /// Por ahora muestra un aviso.
  ///
  /// En el siguiente paso se conectará con
  /// NuevaConsecuenciaScreen.
  Future<void> _abrirNuevaConsecuencia() async {
    final ConsecuenciaProvider provider = context.read<ConsecuenciaProvider>();

    final bool? creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<ConsecuenciaProvider>.value(
          value: provider,
          child: const NuevaConsecuenciaScreen(usuarioRegistroId: 1),
        ),
      ),
    );

    if (!mounted || creada != true) {
      return;
    }

    await provider.cargarConsecuencias();
  }

  /// Por ahora muestra un aviso.
  ///
  /// Luego se conectará con EditarConsecuenciaScreen.
  Future<void> _abrirEditarConsecuencia(ConsecuenciaModel consecuencia) async {
    final ConsecuenciaProvider provider = context.read<ConsecuenciaProvider>();

    final bool? actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<ConsecuenciaProvider>.value(
          value: provider,
          child: EditarConsecuenciaScreen(
            consecuencia: consecuencia,
            usuarioActualizacionId: 1,
          ),
        ),
      ),
    );

    if (!mounted || actualizada != true) {
      return;
    }

    await provider.cargarConsecuencias();
  }

  /// Solicita confirmación antes de eliminar.
  Future<void> _confirmarEliminar(ConsecuenciaModel consecuencia) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar consecuencia'),
          content: Text(
            '¿Deseas eliminar la consecuencia '
            '"${consecuencia.nombre}"?',
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

    final ConsecuenciaProvider provider = context.read<ConsecuenciaProvider>();

    final bool eliminada = await provider.eliminarConsecuencia(consecuencia.id);

    if (!mounted) {
      return;
    }

    if (eliminada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consecuencia eliminada correctamente.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          provider.mensajeError ?? 'No se pudo eliminar la consecuencia.',
        ),
      ),
    );
  }

  /// Muestra todos los datos de la consecuencia
  /// en una ventana inferior.
  void _mostrarDetalle(ConsecuenciaModel consecuencia) {
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
                          Icons.personal_injury_outlined,
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
                              consecuencia.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              consecuencia.codigo.isEmpty
                                  ? 'Sin código'
                                  : consecuencia.codigo,
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
                    valor: consecuencia.descripcionVisible,
                    icono: Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DetalleCampo(
                    titulo: 'Clasificación',
                    valor: consecuencia.clasificacionVisible,
                    icono: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DetalleCampo(
                    titulo: 'Gravedad',
                    valor: consecuencia.gravedadVisible,
                    icono: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DetalleCampo(
                    titulo: 'Incapacidad permanente',
                    valor: consecuencia.incapacidadPermanente ? 'Sí' : 'No',
                    icono: Icons.accessible_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DetalleCampo(
                    titulo: 'Fatalidad',
                    valor: consecuencia.fatalidad ? 'Sí' : 'No',
                    icono: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 14),
                  _DetalleCampo(
                    titulo: 'Estado',
                    valor: consecuencia.estaDisponible ? 'Activa' : 'Inactiva',
                    icono: consecuencia.estaDisponible
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

                            _abrirEditarConsecuencia(consecuencia);
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

                            _confirmarEliminar(consecuencia);
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
        title: const Text('Consecuencias'),
        actions: <Widget>[
          Consumer<ConsecuenciaProvider>(
            builder:
                (
                  BuildContext context,
                  ConsecuenciaProvider provider,
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
        onPressed: _abrirNuevaConsecuencia,
        icon: const Icon(Icons.add),
        label: const Text('Nueva consecuencia'),
      ),
      body: Consumer<ConsecuenciaProvider>(
        builder:
            (
              BuildContext context,
              ConsecuenciaProvider provider,
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
  Widget _construirResumen(ConsecuenciaProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ResumenCard(
              titulo: 'Total',
              valor: provider.cantidadTotal,
              icono: Icons.personal_injury_outlined,
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
              titulo: 'Fatales',
              valor: provider.cantidadFatalidades,
              icono: Icons.warning_amber_outlined,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el campo de búsqueda.
  Widget _construirBuscador(ConsecuenciaProvider provider) {
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

  /// Construye el contenido según el estado del provider.
  Widget _construirContenido(ConsecuenciaProvider provider) {
    if (provider.cargando && !provider.tieneConsecuencias) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.tieneError && !provider.tieneConsecuencias) {
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
            'No se pudieron cargar las consecuencias',
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
                ? 'No hay consecuencias registradas'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.textoBusqueda.isEmpty
                ? 'Registra la primera consecuencia.'
                : 'Prueba con otro criterio de búsqueda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (provider.textoBusqueda.isEmpty)
            FilledButton.icon(
              onPressed: _abrirNuevaConsecuencia,
              icon: const Icon(Icons.add),
              label: const Text('Registrar consecuencia'),
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
      itemCount: provider.consecuenciasFiltradas.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final ConsecuenciaModel consecuencia =
            provider.consecuenciasFiltradas[index];

        return _ConsecuenciaCard(
          consecuencia: consecuencia,
          eliminando: provider.eliminando,
          onTap: () {
            _mostrarDetalle(consecuencia);
          },
          onEditar: () {
            _abrirEditarConsecuencia(consecuencia);
          },
          onEliminar: () {
            _confirmarEliminar(consecuencia);
          },
        );
      },
    );
  }
}

/// Tarjeta utilizada para mostrar una consecuencia.
class _ConsecuenciaCard extends StatelessWidget {
  const _ConsecuenciaCard({
    required this.consecuencia,
    required this.eliminando,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final ConsecuenciaModel consecuencia;
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
                  color: consecuencia.estaDisponible
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  consecuencia.fatalidad
                      ? Icons.warning_amber_rounded
                      : Icons.personal_injury_outlined,
                  color: consecuencia.estaDisponible
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
                      consecuencia.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consecuencia.codigo.isEmpty
                          ? 'Sin código'
                          : consecuencia.codigo,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _InformacionLinea(
                      icono: Icons.category_outlined,
                      texto: consecuencia.clasificacionVisible,
                    ),
                    const SizedBox(height: 4),
                    _InformacionLinea(
                      icono: Icons.health_and_safety_outlined,
                      texto: consecuencia.gravedadVisible,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _EstadoChip(
                          texto: consecuencia.estaDisponible
                              ? 'Activa'
                              : 'Inactiva',
                          activo: consecuencia.estaDisponible,
                        ),
                        if (consecuencia.incapacidadPermanente)
                          const _IndicadorChip(
                            texto: 'Incapacidad permanente',
                            icono: Icons.accessible_outlined,
                          ),
                        if (consecuencia.fatalidad)
                          const _IndicadorChip(
                            texto: 'Fatalidad',
                            icono: Icons.warning_outlined,
                          ),
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

/// Tarjeta pequeña usada en la sección de resumen.
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

/// Campo utilizado dentro del detalle inferior.
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

/// Etiqueta de estado activa o inactiva.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.texto, required this.activo});

  final String texto;
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
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: activo ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

/// Etiqueta utilizada para mostrar condiciones especiales.
class _IndicadorChip extends StatelessWidget {
  const _IndicadorChip({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 13, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
