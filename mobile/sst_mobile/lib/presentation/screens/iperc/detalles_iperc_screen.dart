import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../providers/detalle_iperc_provider.dart';
import '../../providers/usuario_provider.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';
import 'editar_detalle_iperc_screen.dart';
import 'nuevo_detalle_iperc_screen.dart';

/// ===============================================================
/// DETALLES IPERC - SST EDURISK
/// ===============================================================
///
/// Lista los peligros y riesgos registrados en una matriz IPERC.
///
/// Mantiene:
/// - búsqueda;
/// - creación;
/// - edición;
/// - eliminación;
/// - evaluación inicial y residual;
/// - controles;
/// - EPP;
/// - responsables;
/// - seguimientos;
/// - permisos por rol.
///
/// Colores oficiales:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class DetallesIpercScreen extends StatelessWidget {
  const DetallesIpercScreen({
    required this.matriz,
    required this.rol,
    super.key,
  });

  final MatrizIpercModel matriz;
  final String rol;

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
      child: _DetallesIpercView(matriz: matriz, rol: rol),
    );
  }
}

class _DetallesIpercView extends StatefulWidget {
  const _DetallesIpercView({required this.matriz, required this.rol});

  final MatrizIpercModel matriz;
  final String rol;

  @override
  State<_DetallesIpercView> createState() {
    return _DetallesIpercViewState();
  }
}

class _DetallesIpercViewState extends State<_DetallesIpercView> {
  bool get _puedeGestionarDetalles {
    return RolePermissions.puedeGestionarMatrices(widget.rol);
  }

  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();

    super.dispose();
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> _actualizar() async {
    await Future.wait<void>(<Future<void>>[
      context.read<DetalleIpercProvider>().cargarPorMatriz(widget.matriz.id),
      context.read<UsuarioProvider>().cargarUsuarios(),
    ]);
  }

  // =============================================================
  // NUEVO DETALLE
  // =============================================================

  Future<void> _abrirNuevoDetalle() async {
    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    final bool? registrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return ChangeNotifierProvider<DetalleIpercProvider>.value(
            value: provider,
            child: NuevoDetalleIpercScreen(matriz: widget.matriz),
          );
        },
      ),
    );

    if (!mounted || registrado != true) {
      return;
    }

    await _actualizar();
  }

  // =============================================================
  // EDITAR DETALLE
  // =============================================================

  Future<void> _abrirEditarDetalle(DetalleIpercModel detalle) async {
    final DetalleIpercProvider detalleProvider = context
        .read<DetalleIpercProvider>();

    final UsuarioProvider usuarioProvider = context.read<UsuarioProvider>();

    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiProvider(
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
          );
        },
      ),
    );

    if (!mounted || actualizado != true) {
      return;
    }

    await _actualizar();
  }

  // =============================================================
  // SEGUIMIENTOS
  // =============================================================

  Future<void> _abrirSeguimientos(DetalleIpercModel detalle) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return SeguimientosIpercScreen(
            detalleIpercId: detalle.id,
            rol: widget.rol,
          );
        },
      ),
    );
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> _confirmarEliminar(DetalleIpercModel detalle) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.riskOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.riskOrange,
              size: 32,
            ),
          ),
          title: const Text(
            'Eliminar peligro evaluado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '¿Deseas eliminar este peligro evaluado?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Ítem ${detalle.item}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle.peligroVisible,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.riskOrange,
                foregroundColor: Colors.white,
              ),
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: eliminado ? AppColors.green : AppColors.riskOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                eliminado ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  eliminado
                      ? 'Peligro evaluado eliminado correctamente.'
                      : provider.error ??
                            'No se pudo eliminar el detalle IPERC.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // =============================================================
  // MOSTRAR DETALLE
  // =============================================================

  void _mostrarDetalle(DetalleIpercModel detalle) {
    final String responsable = _nombreResponsable(
      context.read<UsuarioProvider>(),
      detalle.responsableImplementacionId,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EncabezadoDetalle(detalle: detalle),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      _DatoDetalle(
                        icono: Icons.work_outline,
                        etiqueta: 'Tarea',
                        valor: detalle.tarea,
                        color: AppColors.primary,
                      ),
                      _DatoDetalle(
                        icono: Icons.warning_amber_outlined,
                        etiqueta: 'Peligro',
                        valor: detalle.peligroVisible,
                        color: AppColors.riskOrange,
                      ),
                      _DatoDetalle(
                        icono: Icons.report_problem_outlined,
                        etiqueta: 'Consecuencia',
                        valor: detalle.consecuenciaVisible,
                        color: AppColors.yellow,
                        colorTexto: AppColors.navyDark,
                      ),
                      _DatoDetalle(
                        icono: Icons.description_outlined,
                        etiqueta: 'Descripción específica',
                        valor: detalle.descripcionVisible,
                        color: AppColors.primaryBright,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

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

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      _DatoDetalle(
                        icono: Icons.security_outlined,
                        etiqueta: 'Controles',
                        valor: detalle.tieneControles
                            ? '${detalle.controlIds.length} seleccionado(s)'
                            : 'Sin controles asignados',
                        color: AppColors.green,
                      ),
                      _DatoDetalle(
                        icono: Icons.health_and_safety_outlined,
                        etiqueta: 'EPP',
                        valor: detalle.tieneEquiposProteccion
                            ? '${detalle.equipoProteccionIds.length} seleccionado(s)'
                            : 'Sin EPP asignados',
                        color: AppColors.green,
                      ),
                      _DatoDetalle(
                        icono: Icons.task_alt_outlined,
                        etiqueta: 'Implementación',
                        valor: detalle.estadoImplementacionNombre,
                        color: AppColors.primaryBright,
                      ),
                      _DatoDetalle(
                        icono: Icons.person_outline,
                        etiqueta: 'Responsable',
                        valor: responsable,
                        color: AppColors.primary,
                      ),
                      _DatoDetalle(
                        icono: Icons.event_outlined,
                        etiqueta: 'Fecha de compromiso',
                        valor: _formatearFecha(detalle.fechaCompromiso),
                        color: AppColors.yellow,
                        colorTexto: AppColors.navyDark,
                      ),
                      _DatoDetalle(
                        icono: Icons.event_available_outlined,
                        etiqueta: 'Fecha de implementación',
                        valor: _formatearFecha(detalle.fechaImplementacion),
                        color: AppColors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();

                      _abrirSeguimientos(detalle);
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ver seguimientos'),
                  ),
                ),

                if (_puedeGestionarDetalles) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
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
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.riskOrange,
                            foregroundColor: Colors.white,
                          ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final UsuarioProvider usuarioProvider = context.watch<UsuarioProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                  );
                },
          ),
        ],
      ),

      floatingActionButton: _puedeGestionarDetalles
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _abrirNuevoDetalle,
              icon: const Icon(Icons.add),
              label: const Text(
                'Agregar peligro',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,

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
                      color: AppColors.primary,
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

  // =============================================================
  // BUSCADOR
  // =============================================================

  Widget _construirBuscador(DetalleIpercProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: provider.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar tarea, peligro o consecuencia',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: provider.terminoBusqueda.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _busquedaController.clear();

                    provider.limpiarBusqueda();
                  },
                  icon: const Icon(Icons.close, color: AppColors.primary),
                ),
        ),
      ),
    );
  }

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido(
    DetalleIpercProvider provider,
    UsuarioProvider usuarioProvider,
  ) {
    if (provider.cargando && !provider.tieneDetalles) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.tieneError && !provider.tieneDetalles) {
      return _EstadoLista(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudieron cargar los peligros',
        mensaje: provider.error ?? 'Ocurrió un error inesperado.',
        color: AppColors.riskOrange,
        accion: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
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
        color: buscando ? AppColors.primaryBright : AppColors.yellow,
        colorTexto: buscando ? null : AppColors.navyDark,
        accion: buscando
            ? OutlinedButton.icon(
                onPressed: () {
                  _busquedaController.clear();

                  provider.limpiarBusqueda();
                },
                icon: const Icon(Icons.close),
                label: const Text('Limpiar búsqueda'),
              )
            : _puedeGestionarDetalles
            ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _abrirNuevoDetalle,
                icon: const Icon(Icons.add),
                label: const Text('Agregar peligro'),
              )
            : const SizedBox.shrink(),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: detalles.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (BuildContext context, int index) {
        final DetalleIpercModel detalle = detalles[index];

        return _DetalleCard(
          detalle: detalle,
          responsableNombre: _nombreResponsable(
            usuarioProvider,
            detalle.responsableImplementacionId,
          ),
          procesando: provider.procesando,
          puedeGestionar: _puedeGestionarDetalles,
          onTap: () {
            _mostrarDetalle(detalle);
          },
          onSeguimientos: () {
            _abrirSeguimientos(detalle);
          },
          onEditar: () {
            if (_puedeGestionarDetalles) {
              _abrirEditarDetalle(detalle);
            }
          },
          onEliminar: () {
            if (_puedeGestionarDetalles) {
              _confirmarEliminar(detalle);
            }
          },
        );
      },
    );
  }

  // =============================================================
  // RESPONSABLE
  // =============================================================

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

  // =============================================================
  // FECHA
  // =============================================================

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha registrada';
    }

    final String dia = fecha.day.toString().padLeft(2, '0');

    final String mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }
}

/// ===============================================================
/// RESUMEN MATRIZ
/// ===============================================================

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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primaryBright,
            AppColors.primary,
            AppColors.navyDark,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
              size: 29,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  matriz.codigo,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  matriz.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total ítems',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '$conResidual con residual',
                style: const TextStyle(color: Color(0xFFDCEAFF), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// TARJETA DETALLE
/// ===============================================================

class _DetalleCard extends StatelessWidget {
  const _DetalleCard({
    required this.detalle,
    required this.responsableNombre,
    required this.procesando,
    required this.puedeGestionar,
    required this.onTap,
    required this.onSeguimientos,
    required this.onEditar,
    required this.onEliminar,
  });

  final DetalleIpercModel detalle;
  final String responsableNombre;
  final bool procesando;
  final bool puedeGestionar;
  final VoidCallback onTap;
  final VoidCallback onSeguimientos;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final Color nivelColor = _colorDesdeHex(detalle.evaluacionInicial.color);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 5, color: nivelColor),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: nivelColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            detalle.item > 0 ? detalle.item.toString() : '–',
                            style: TextStyle(
                              color: nivelColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
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
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                detalle.tarea,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 9),

                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: <Widget>[
                                  _NivelRiesgoEtiqueta(
                                    evaluacion: detalle.evaluacionInicial,
                                  ),

                                  _Etiqueta(
                                    icono: Icons.report_problem_outlined,
                                    texto: detalle.consecuenciaVisible,
                                    color: AppColors.yellow,
                                    colorTexto: AppColors.navyDark,
                                  ),

                                  _Etiqueta(
                                    icono: detalle.tieneEvaluacionResidual
                                        ? Icons.verified_user_outlined
                                        : Icons.pending_actions_outlined,
                                    texto: detalle.tieneEvaluacionResidual
                                        ? 'Con riesgo residual'
                                        : 'Residual pendiente',
                                    color: detalle.tieneEvaluacionResidual
                                        ? AppColors.green
                                        : AppColors.yellow,
                                    colorTexto: detalle.tieneEvaluacionResidual
                                        ? null
                                        : AppColors.navyDark,
                                  ),

                                  _Etiqueta(
                                    icono: Icons.security_outlined,
                                    texto: detalle.tieneControles
                                        ? '${detalle.controlIds.length} control(es)'
                                        : 'Sin controles',
                                    color: AppColors.green,
                                  ),

                                  _Etiqueta(
                                    icono: Icons.health_and_safety_outlined,
                                    texto: detalle.tieneEquiposProteccion
                                        ? '${detalle.equipoProteccionIds.length} EPP'
                                        : 'Sin EPP',
                                    color: AppColors.primaryBright,
                                  ),
                                ],
                              ),

                              if (responsableNombre
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.person_outline,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        responsableNombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        PopupMenuButton<String>(
                          enabled: !procesando,
                          color: AppColors.surface,
                          tooltip: 'Opciones',
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.primary,
                          ),
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
                            return <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'seguimientos',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.fact_check_outlined,
                                    color: AppColors.primaryBright,
                                  ),
                                  title: Text('Seguimientos'),
                                ),
                              ),
                              if (puedeGestionar)
                                const PopupMenuItem<String>(
                                  value: 'editar',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primary,
                                    ),
                                    title: Text('Editar'),
                                  ),
                                ),
                              if (puedeGestionar)
                                const PopupMenuItem<String>(
                                  value: 'eliminar',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: AppColors.riskOrange,
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// ENCABEZADO DETALLE
/// ===============================================================

class _EncabezadoDetalle extends StatelessWidget {
  const _EncabezadoDetalle({required this.detalle});

  final DetalleIpercModel detalle;

  @override
  Widget build(BuildContext context) {
    final Color nivelColor = _colorDesdeHex(detalle.evaluacionInicial.color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primaryBright,
            AppColors.primary,
            AppColors.navyDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              detalle.item > 0 ? detalle.item.toString() : '–',
              style: TextStyle(
                color: nivelColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  detalle.peligroVisible,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  detalle.estadoImplementacionNombre,
                  style: const TextStyle(
                    color: Color(0xFFDCEAFF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// DATO DETALLE
/// ===============================================================

class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
    this.colorTexto,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icono, color: foreground, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  etiqueta,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  valor,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// EVALUACIÓN
/// ===============================================================

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

    if (datos == null) {
      final bool tieneId = evaluacionId != null && evaluacionId! > 0;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.42)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: AppColors.navyDark),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    pendienteCuandoFalta && !tieneId
                        ? 'Pendiente de evaluación'
                        : tieneId
                        ? 'La evaluación #$evaluacionId no incluye todavía el detalle del cálculo.'
                        : 'Sin evaluación registrada',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
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
        color: colorNivel.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorNivel.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorNivel.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: colorNivel),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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
            valorColor: datos.esAceptable
                ? AppColors.green
                : AppColors.riskOrange,
          ),

          _EvaluacionFila(
            etiqueta: 'Acción',
            valor: datos.requiereAccion
                ? 'Requiere medidas de control'
                : 'No requiere acción adicional',
            valorColor: datos.requiereAccion
                ? AppColors.riskOrange
                : AppColors.green,
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

/// ===============================================================
/// FILA EVALUACIÓN
/// ===============================================================

class _EvaluacionFila extends StatelessWidget {
  const _EvaluacionFila({
    required this.etiqueta,
    required this.valor,
    this.valorColor,
  });

  final String etiqueta;
  final String valor;
  final Color? valorColor;

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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: valorColor ?? AppColors.textPrimary,
                fontWeight: valorColor != null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// ETIQUETA NIVEL DE RIESGO
/// ===============================================================

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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// ETIQUETA AUXILIAR
/// ===============================================================

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icono,
    required this.texto,
    required this.color,
    this.colorTexto,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 15, color: foreground),

          const SizedBox(width: 5),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// COLOR DESDE HEX
/// ===============================================================

Color _colorDesdeHex(String valor) {
  String hexadecimal = valor.trim().replaceFirst('#', '');

  if (hexadecimal.length == 6) {
    hexadecimal = 'FF$hexadecimal';
  }

  final int? numero = int.tryParse(hexadecimal, radix: 16);

  return numero == null ? AppColors.textSecondary : Color(numero);
}

/// ===============================================================
/// CONTRASTE
/// ===============================================================

Color _colorDeTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

/// ===============================================================
/// ESTADO DE LISTA
/// ===============================================================

class _EstadoLista extends StatelessWidget {
  const _EstadoLista({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.accion,
    required this.color,
    this.colorTexto,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget accion;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 46),

        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 46, color: foreground),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),

        const SizedBox(height: 22),

        accion,
      ],
    );
  }
}
