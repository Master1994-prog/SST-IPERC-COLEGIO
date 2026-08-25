import 'package:flutter/material.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';
import '../../../data/repositories/usuario_repository.dart';

/// ===============================================================
/// SEGUIMIENTOS IPERC - SST EDURISK
/// ===============================================================
///
/// Permite:
/// - consultar seguimientos;
/// - buscar;
/// - filtrar por estado;
/// - crear;
/// - editar;
/// - verificar;
/// - eliminar.
///
/// Mantiene la lógica existente del proyecto y aplica la identidad
/// visual oficial SST EduRisk.
///
/// Colores:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class SeguimientosScreen extends StatefulWidget {
  const SeguimientosScreen({required this.rol, this.detalleIpercId, super.key});

  final String rol;

  /// Si se proporciona un detalle IPERC, solamente se muestran
  /// sus seguimientos.
  final int? detalleIpercId;

  @override
  State<SeguimientosScreen> createState() {
    return _SeguimientosScreenState();
  }
}

class _SeguimientosScreenState extends State<SeguimientosScreen> {
  bool get _puedeGestionarSeguimientos =>
      RolePermissions.puedeGestionarSeguimientos(widget.rol);

  bool get _puedeEliminar => RolePermissions.puedeEliminarRegistros(widget.rol);

  final SeguimientoIpercRepository _repository = SeguimientoIpercRepository();

  final TextEditingController _buscarController = TextEditingController();

  List<SeguimientoIpercModel> _seguimientos = <SeguimientoIpercModel>[];

  bool _cargando = false;

  String? _error;

  String _busqueda = '';

  bool? _filtroVerificado;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _cargarSeguimientos();
  }

  @override
  void dispose() {
    _buscarController.dispose();

    super.dispose();
  }

  // =============================================================
  // FILTROS
  // =============================================================

  List<SeguimientoIpercModel> get _seguimientosFiltrados {
    final String texto = _busqueda.toLowerCase().trim();

    return _seguimientos.where((SeguimientoIpercModel seguimiento) {
      final bool coincideEstado =
          _filtroVerificado == null ||
          seguimiento.verificado == _filtroVerificado;

      if (!coincideEstado) {
        return false;
      }

      if (texto.isEmpty) {
        return true;
      }

      return seguimiento.descripcion.toLowerCase().contains(texto) ||
          seguimiento.detalleVisible.toLowerCase().contains(texto) ||
          seguimiento.estadoVisible.toLowerCase().contains(texto) ||
          (seguimiento.usuarioNombre ?? '').toLowerCase().contains(texto);
    }).toList();
  }

  // =============================================================
  // CARGAR
  // =============================================================

  Future<void> _cargarSeguimientos() async {
    if (_cargando) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final int? detalleId = widget.detalleIpercId;

      final List<SeguimientoIpercModel> resultados =
          detalleId != null && detalleId > 0
          ? await _repository.obtenerPorDetalle(detalleId)
          : await _repository.obtenerTodos();

      resultados.sort((
        SeguimientoIpercModel primero,
        SeguimientoIpercModel segundo,
      ) {
        return segundo.fechaSeguimiento.compareTo(primero.fechaSeguimiento);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _seguimientos = resultados;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // =============================================================
  // FORMULARIO
  // =============================================================

  Future<void> _abrirFormulario({SeguimientoIpercModel? seguimiento}) async {
    final bool? guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SeguimientoFormDialog(
          seguimiento: seguimiento,
          detalleIpercIdInicial: widget.detalleIpercId,
          repository: _repository,
        );
      },
    );

    if (guardado == true) {
      await _cargarSeguimientos();
    }
  }

  // =============================================================
  // VERIFICAR
  // =============================================================

  Future<void> _verificar(SeguimientoIpercModel seguimiento) async {
    if (seguimiento.verificado) {
      _mostrarMensaje('El seguimiento ya se encuentra verificado.');

      return;
    }

    final bool confirmar =
        await _confirmarAccion(
          titulo: 'Verificar seguimiento',
          mensaje: '¿Deseas marcar este seguimiento como verificado?',
          textoConfirmar: 'Verificar',
          icono: Icons.verified_outlined,
          color: AppColors.green,
        ) ??
        false;

    if (!confirmar) {
      return;
    }

    try {
      await _repository.verificar(seguimiento.id);

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Seguimiento verificado correctamente.');

      await _cargarSeguimientos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    }
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<void> _eliminar(SeguimientoIpercModel seguimiento) async {
    final bool confirmar =
        await _confirmarAccion(
          titulo: 'Eliminar seguimiento',
          mensaje: '¿Deseas eliminar el seguimiento seleccionado?',
          textoConfirmar: 'Eliminar',
          icono: Icons.delete_outline,
          color: AppColors.riskOrange,
        ) ??
        false;

    if (!confirmar) {
      return;
    }

    try {
      await _repository.eliminar(seguimiento.id);

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Seguimiento eliminado correctamente.');

      await _cargarSeguimientos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    }
  }

  // =============================================================
  // CONFIRMACIÓN
  // =============================================================

  Future<bool?> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required String textoConfirmar,
    required IconData icono,
    required Color color,
  }) {
    return showDialog<bool>(
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
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 32),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: color == AppColors.yellow
                    ? AppColors.navyDark
                    : Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: esError ? AppColors.riskOrange : AppColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                esError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
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
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final List<SeguimientoIpercModel> filtrados = _seguimientosFiltrados;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Seguimientos IPERC'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarSeguimientos,
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _puedeGestionarSeguimientos
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _cargando
                  ? null
                  : () {
                      _abrirFormulario();
                    },
              icon: const Icon(Icons.add),
              label: const Text(
                'Nuevo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarSeguimientos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _construirResumen()),
            SliverToBoxAdapter(child: _construirFiltros()),
            if (_cargando && _seguimientos.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null && _seguimientos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EstadoVacio(
                  icono: Icons.cloud_off_outlined,
                  titulo: 'No se pudieron cargar los seguimientos',
                  descripcion: _error!,
                  textoBoton: 'Reintentar',
                  onPressed: _cargarSeguimientos,
                  color: AppColors.riskOrange,
                ),
              )
            else if (filtrados.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EstadoVacio(
                  icono: Icons.fact_check_outlined,
                  titulo: _seguimientos.isEmpty
                      ? 'No hay seguimientos registrados'
                      : 'No se encontraron resultados',
                  descripcion: _seguimientos.isEmpty
                      ? 'Registra el primer seguimiento para controlar el avance de las medidas.'
                      : 'Modifica la búsqueda o los filtros seleccionados.',
                  textoBoton:
                      _seguimientos.isEmpty && _puedeGestionarSeguimientos
                      ? 'Registrar seguimiento'
                      : null,
                  onPressed:
                      _seguimientos.isEmpty && _puedeGestionarSeguimientos
                      ? () {
                          _abrirFormulario();
                        }
                      : null,
                  color: _seguimientos.isEmpty
                      ? AppColors.yellow
                      : AppColors.primaryBright,
                  colorTexto: _seguimientos.isEmpty ? AppColors.navyDark : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final SeguimientoIpercModel seguimiento = filtrados[index];

                    return _SeguimientoCard(
                      seguimiento: seguimiento,
                      puedeGestionar: _puedeGestionarSeguimientos,
                      puedeEliminar: _puedeEliminar,
                      onEditar: () {
                        _abrirFormulario(seguimiento: seguimiento);
                      },
                      onVerificar: () {
                        _verificar(seguimiento);
                      },
                      onEliminar: () {
                        _eliminar(seguimiento);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  Widget _construirResumen() {
    final int total = _seguimientos.length;

    final int verificados = _seguimientos.where((SeguimientoIpercModel item) {
      return item.verificado;
    }).length;

    final int pendientes = total - verificados;

    final double avancePromedio = total == 0
        ? 0
        : _seguimientos.fold<double>(0, (
                double acumulado,
                SeguimientoIpercModel item,
              ) {
                return acumulado + item.porcentajeAvance;
              }) /
              total;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          if (widget.detalleIpercId != null) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Detalle IPERC ${widget.detalleIpercId}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Mostrando únicamente los seguimientos del detalle seleccionado.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: <Widget>[
              _ResumenItem(
                icono: Icons.fact_check_outlined,
                titulo: 'Total',
                valor: total.toString(),
                color: AppColors.primary,
              ),
              _ResumenItem(
                icono: Icons.pending_actions,
                titulo: 'Pendientes',
                valor: pendientes.toString(),
                color: AppColors.yellow,
                colorTexto: AppColors.navyDark,
              ),
              _ResumenItem(
                icono: Icons.verified_outlined,
                titulo: 'Verificados',
                valor: verificados.toString(),
                color: AppColors.green,
              ),
              _ResumenItem(
                icono: Icons.percent,
                titulo: 'Avance promedio',
                valor: '${avancePromedio.toStringAsFixed(0)} %',
                color: AppColors.primaryBright,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FILTROS
  // =============================================================

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _buscarController,
            onChanged: (String value) {
              setState(() {
                _busqueda = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Buscar seguimiento',
              hintText: 'Descripción, tarea o usuario',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      onPressed: () {
                        _buscarController.clear();

                        setState(() {
                          _busqueda = '';
                        });
                      },
                      icon: const Icon(Icons.clear, color: AppColors.primary),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool?>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }

                  return AppColors.textSecondary;
                }),
              ),
              segments: const <ButtonSegment<bool?>>[
                ButtonSegment<bool?>(
                  value: null,
                  label: Text('Todos'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment<bool?>(
                  value: false,
                  label: Text('Pendientes'),
                  icon: Icon(Icons.pending_actions),
                ),
                ButtonSegment<bool?>(
                  value: true,
                  label: Text('Verificados'),
                  icon: Icon(Icons.verified_outlined),
                ),
              ],
              selected: <bool?>{_filtroVerificado},
              onSelectionChanged: (Set<bool?> seleccion) {
                setState(() {
                  _filtroVerificado = seleccion.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ERROR
  // =============================================================

  String _obtenerMensajeError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'DioException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}

// ===============================================================
// TARJETA DE SEGUIMIENTO
// ===============================================================

class _SeguimientoCard extends StatelessWidget {
  const _SeguimientoCard({
    required this.seguimiento,
    required this.onEditar,
    required this.onVerificar,
    required this.onEliminar,
    required this.puedeGestionar,
    required this.puedeEliminar,
  });

  final SeguimientoIpercModel seguimiento;

  final VoidCallback onEditar;

  final VoidCallback onVerificar;

  final VoidCallback onEliminar;

  final bool puedeGestionar;

  final bool puedeEliminar;

  @override
  Widget build(BuildContext context) {
    final double porcentaje = seguimiento.porcentajeAvance
        .clamp(0, 100)
        .toDouble();

    final Color estadoColor = seguimiento.verificado
        ? AppColors.green
        : AppColors.yellow;

    final Color estadoTexto = seguimiento.verificado
        ? AppColors.green
        : AppColors.navyDark;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 5, color: estadoColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 7, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              seguimiento.verificado
                                  ? Icons.verified
                                  : Icons.pending_actions,
                              color: estadoTexto,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  seguimiento.detalleVisible,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatearFecha(
                                        seguimiento.fechaSeguimiento,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (puedeGestionar || puedeEliminar)
                            PopupMenuButton<String>(
                              color: AppColors.surface,
                              tooltip: 'Opciones',
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.primary,
                              ),
                              onSelected: (String opcion) {
                                switch (opcion) {
                                  case 'editar':
                                    onEditar();
                                    break;
                                  case 'verificar':
                                    onVerificar();
                                    break;
                                  case 'eliminar':
                                    onEliminar();
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return <PopupMenuEntry<String>>[
                                  if (puedeGestionar)
                                    const PopupMenuItem<String>(
                                      value: 'editar',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.primary,
                                        ),
                                        title: Text('Editar'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  if (puedeGestionar && !seguimiento.verificado)
                                    const PopupMenuItem<String>(
                                      value: 'verificar',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.verified_outlined,
                                          color: AppColors.green,
                                        ),
                                        title: Text('Verificar'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  if (puedeEliminar)
                                    const PopupMenuItem<String>(
                                      value: 'eliminar',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.riskOrange,
                                        ),
                                        title: Text('Eliminar'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                ];
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        seguimiento.descripcion,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                      if ((seguimiento.observaciones ?? '')
                          .trim()
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            'Observaciones: '
                            '${seguimiento.observaciones}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Row(
                        children: <Widget>[
                          Expanded(
                            child: LinearProgressIndicator(
                              value: porcentaje / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              color: seguimiento.verificado
                                  ? AppColors.green
                                  : AppColors.primaryBright,
                              backgroundColor: AppColors.border,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${porcentaje.toStringAsFixed(0)} %',
                            style: TextStyle(
                              color: porcentaje >= 100
                                  ? AppColors.green
                                  : AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _SeguimientoChip(
                            icono: seguimiento.verificado
                                ? Icons.check_circle
                                : Icons.schedule,
                            texto: seguimiento.estadoVisible,
                            color: estadoColor,
                            colorTexto: estadoTexto,
                          ),
                          if ((seguimiento.usuarioNombre ?? '')
                              .trim()
                              .isNotEmpty)
                            _SeguimientoChip(
                              icono: Icons.person_outline,
                              texto: seguimiento.usuarioNombre!,
                              color: AppColors.primary,
                            ),
                          if ((seguimiento.nombreArchivo ?? '')
                              .trim()
                              .isNotEmpty)
                            _SeguimientoChip(
                              icono: Icons.attach_file,
                              texto: seguimiento.nombreArchivo!,
                              color: AppColors.primaryBright,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatearFecha(DateTime fecha) {
    final String dia = fecha.day.toString().padLeft(2, '0');

    final String mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }
}

// ===============================================================
// CHIP DE SEGUIMIENTO
// ===============================================================

class _SeguimientoChip extends StatelessWidget {
  const _SeguimientoChip({
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

// ===============================================================
// RESUMEN
// ===============================================================

class _ResumenItem extends StatelessWidget {
  const _ResumenItem({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    this.colorTexto,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  valor,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

// ===============================================================
// ESTADO VACÍO
// ===============================================================

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    this.colorTexto,
    this.textoBoton,
    this.onPressed,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color? colorTexto;
  final String? textoBoton;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 48, color: foreground),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (textoBoton != null && onPressed != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(textoBoton!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// FORMULARIO SEGUIMIENTO
// ===============================================================

class _SeguimientoFormDialog extends StatefulWidget {
  const _SeguimientoFormDialog({
    required this.repository,
    this.seguimiento,
    this.detalleIpercIdInicial,
  });

  final SeguimientoIpercRepository repository;

  final SeguimientoIpercModel? seguimiento;

  final int? detalleIpercIdInicial;

  @override
  State<_SeguimientoFormDialog> createState() {
    return _SeguimientoFormDialogState();
  }
}

// ===============================================================
// ESTADO DEL FORMULARIO
// ===============================================================

class _SeguimientoFormDialogState extends State<_SeguimientoFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  late final TextEditingController _descripcionController;

  late final TextEditingController _observacionesController;

  late final TextEditingController _archivoController;

  late final TextEditingController _nombreArchivoController;

  late final TextEditingController _tipoArchivoController;

  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];

  List<UsuarioModel> _usuarios = <UsuarioModel>[];

  int? _detalleSeleccionadoId;

  int? _usuarioSeleccionadoId;

  late DateTime _fechaSeguimiento;

  late double _porcentajeAvance;

  late bool _verificado;

  bool _cargandoCatalogos = true;

  bool _guardando = false;

  String? _errorCatalogos;

  String? _error;

  bool get _esEdicion {
    return widget.seguimiento != null;
  }

  bool get _detalleBloqueado {
    return widget.detalleIpercIdInicial != null &&
        widget.detalleIpercIdInicial! > 0;
  }

  // =============================================================
  // INICIALIZAR
  // =============================================================

  @override
  void initState() {
    super.initState();

    final SeguimientoIpercModel? actual = widget.seguimiento;

    _detalleSeleccionadoId =
        actual?.detalleIpercId ?? widget.detalleIpercIdInicial;

    _usuarioSeleccionadoId = actual?.usuarioId;

    _descripcionController = TextEditingController(
      text: actual?.descripcion ?? '',
    );

    _observacionesController = TextEditingController(
      text: actual?.observaciones ?? '',
    );

    _archivoController = TextEditingController(text: actual?.archivo ?? '');

    _nombreArchivoController = TextEditingController(
      text: actual?.nombreArchivo ?? '',
    );

    _tipoArchivoController = TextEditingController(
      text: actual?.tipoArchivo ?? '',
    );

    _fechaSeguimiento = actual?.fechaSeguimiento ?? DateTime.now();

    _porcentajeAvance = (actual?.porcentajeAvance ?? 0)
        .clamp(0, 100)
        .toDouble();

    _verificado = actual?.verificado ?? false;

    _cargarCatalogos();
  }

  // =============================================================
  // LIBERAR CONTROLADORES
  // =============================================================

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    _archivoController.dispose();
    _nombreArchivoController.dispose();
    _tipoArchivoController.dispose();

    super.dispose();
  }

  // =============================================================
  // CARGAR CATÁLOGOS
  // =============================================================

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _detalleRepository.obtenerTodos(),
          _usuarioRepository.obtenerTodos(),
        ],
      );

      final List<DetalleIpercModel> detalles =
          resultados[0] as List<DetalleIpercModel>;

      final List<UsuarioModel> usuarios = resultados[1] as List<UsuarioModel>;

      detalles.sort((DetalleIpercModel primero, DetalleIpercModel segundo) {
        final int comparacionMatriz = primero.matrizIpercCodigo.compareTo(
          segundo.matrizIpercCodigo,
        );

        if (comparacionMatriz != 0) {
          return comparacionMatriz;
        }

        return primero.item.compareTo(segundo.item);
      });

      usuarios.sort((UsuarioModel primero, UsuarioModel segundo) {
        return primero.nombreVisible.toLowerCase().compareTo(
          segundo.nombreVisible.toLowerCase(),
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _detalles = detalles;
        _usuarios = usuarios;

        if (_usuarioSeleccionadoId == null && usuarios.length == 1) {
          _usuarioSeleccionadoId = usuarios.first.id;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorCatalogos = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoCatalogos = false;
        });
      }
    }
  }

  // =============================================================
  // SELECCIONAR FECHA
  // =============================================================

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeguimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de seguimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaSeguimiento = fecha;
    });
  }

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final int? detalleId = _detalleSeleccionadoId;

    final int? usuarioId = _usuarioSeleccionadoId;

    if (detalleId == null || detalleId <= 0) {
      setState(() {
        _error = 'Selecciona un detalle IPERC.';
      });

      return;
    }

    if (usuarioId == null || usuarioId <= 0) {
      setState(() {
        _error = 'Selecciona un usuario responsable.';
      });

      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      if (_esEdicion) {
        final SeguimientoIpercModel actual = widget.seguimiento!;

        await widget.repository.actualizar(
          actual.id,
          ActualizarSeguimientoIpercRequest(
            detalleIpercId: detalleId,
            fechaSeguimiento: _fechaSeguimiento,
            usuarioId: usuarioId,
            descripcion: _descripcionController.text,
            porcentajeAvance: _porcentajeAvance,
            verificado: _verificado,
            fechaVerificacion: _verificado
                ? actual.fechaVerificacion ?? DateTime.now()
                : null,
            observaciones: _observacionesController.text,
            archivo: _archivoController.text,
            nombreArchivo: _nombreArchivoController.text,
            tipoArchivo: _tipoArchivoController.text,
          ),
        );
      } else {
        await widget.repository.crear(
          CrearSeguimientoIpercRequest(
            detalleIpercId: detalleId,
            fechaSeguimiento: _fechaSeguimiento,
            usuarioId: usuarioId,
            descripcion: _descripcionController.text,
            porcentajeAvance: _porcentajeAvance,
            verificado: _verificado,
            fechaVerificacion: _verificado ? DateTime.now() : null,
            observaciones: _observacionesController.text,
            archivo: _archivoController.text,
            nombreArchivo: _nombreArchivoController.text,
            tipoArchivo: _tipoArchivoController.text,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // =============================================================
  // INTERFAZ FORMULARIO
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final String fechaTexto =
        '${_fechaSeguimiento.day.toString().padLeft(2, '0')}/'
        '${_fechaSeguimiento.month.toString().padLeft(2, '0')}/'
        '${_fechaSeguimiento.year}';

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _esEdicion ? Icons.edit_note_outlined : Icons.add_task_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _esEdicion ? 'Editar seguimiento' : 'Nuevo seguimiento',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: _cargandoCatalogos
            ? const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _errorCatalogos != null
            ? _construirErrorCatalogos()
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _FormularioSeccion(
                        titulo: 'Seguimiento',
                        icono: Icons.fact_check_outlined,
                        color: AppColors.primaryBright,
                        child: Column(
                          children: <Widget>[
                            _construirSelectorDetalle(),
                            const SizedBox(height: 12),
                            _construirSelectorUsuario(),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _seleccionarFecha,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de seguimiento',
                                  prefixIcon: Icon(
                                    Icons.calendar_month,
                                    color: AppColors.primary,
                                  ),
                                ),
                                child: Text(
                                  fechaTexto,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                hintText: 'Describe el avance realizado',
                                prefixIcon: Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primaryBright,
                                ),
                                alignLabelWithHint: true,
                              ),
                              validator: (String? value) {
                                final String texto = value?.trim() ?? '';

                                if (texto.isEmpty) {
                                  return 'La descripción es obligatoria.';
                                }

                                if (texto.length < 5) {
                                  return 'Ingresa al menos 5 caracteres.';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _FormularioSeccion(
                        titulo: 'Avance y verificación',
                        icono: Icons.trending_up_outlined,
                        color: AppColors.green,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text(
                                    'Porcentaje de avance',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.09,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_porcentajeAvance.toStringAsFixed(0)} %',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              activeColor: AppColors.primaryBright,
                              inactiveColor: AppColors.border,
                              value: _porcentajeAvance,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              label:
                                  '${_porcentajeAvance.toStringAsFixed(0)} %',
                              onChanged: (double value) {
                                setState(() {
                                  _porcentajeAvance = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeTrackColor: AppColors.green,
                              activeThumbColor: Colors.white,
                              title: const Text(
                                'Seguimiento verificado',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Indica que el avance fue revisado y aprobado.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              value: _verificado,
                              onChanged: (bool value) {
                                setState(() {
                                  _verificado = value;
                                });
                              },
                              secondary: Icon(
                                _verificado
                                    ? Icons.verified_outlined
                                    : Icons.pending_actions,
                                color: _verificado
                                    ? AppColors.green
                                    : AppColors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _FormularioSeccion(
                        titulo: 'Observaciones',
                        icono: Icons.notes_outlined,
                        color: AppColors.yellow,
                        colorTexto: AppColors.navyDark,
                        child: TextFormField(
                          controller: _observacionesController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            prefixIcon: Icon(
                              Icons.notes,
                              color: AppColors.navyDark,
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _FormularioSeccion(
                        titulo: 'Información de evidencia',
                        icono: Icons.attach_file,
                        color: AppColors.primary,
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          iconColor: AppColors.primary,
                          collapsedIconColor: AppColors.primary,
                          title: const Text(
                            'Adjunto / evidencia',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Datos del archivo relacionado al seguimiento.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          children: <Widget>[
                            TextFormField(
                              controller: _nombreArchivoController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del archivo',
                                prefixIcon: Icon(
                                  Icons.drive_file_rename_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _tipoArchivoController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de archivo',
                                hintText: 'image/jpeg, application/pdf',
                                prefixIcon: Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primaryBright,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _archivoController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Ruta o contenido del archivo',
                                prefixIcon: Icon(
                                  Icons.link_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 14),
                        _construirMensajeError(_error!),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      actions: <Widget>[
        TextButton(
          onPressed: _guardando
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardando || _cargandoCatalogos || _errorCatalogos != null
              ? null
              : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }

  // =============================================================
  // SELECTOR DETALLE
  // =============================================================

  Widget _construirSelectorDetalle() {
    final bool valorExiste =
        _detalleSeleccionadoId == null ||
        _detalles.any((DetalleIpercModel detalle) {
          return detalle.id == _detalleSeleccionadoId;
        });

    final int? valorSeleccionado = valorExiste ? _detalleSeleccionadoId : null;

    return DropdownButtonFormField<int>(
      initialValue: valorSeleccionado,
      isExpanded: true,
      iconEnabledColor: AppColors.primary,
      dropdownColor: AppColors.surface,
      decoration: const InputDecoration(
        labelText: 'Detalle IPERC',
        prefixIcon: Icon(Icons.assignment_outlined, color: AppColors.primary),
      ),
      items: _detalles.map((DetalleIpercModel detalle) {
        return DropdownMenuItem<int>(
          value: detalle.id,
          child: Text(
            _nombreDetalle(detalle),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _detalleBloqueado
          ? null
          : (int? value) {
              setState(() {
                _detalleSeleccionadoId = value;
              });
            },
      validator: (int? value) {
        if (value == null || value <= 0) {
          return 'Selecciona un detalle IPERC.';
        }

        return null;
      },
    );
  }

  // =============================================================
  // SELECTOR USUARIO
  // =============================================================

  Widget _construirSelectorUsuario() {
    final bool valorExiste =
        _usuarioSeleccionadoId == null ||
        _usuarios.any((UsuarioModel usuario) {
          return usuario.id == _usuarioSeleccionadoId;
        });

    final int? valorSeleccionado = valorExiste ? _usuarioSeleccionadoId : null;

    return DropdownButtonFormField<int>(
      initialValue: valorSeleccionado,
      isExpanded: true,
      iconEnabledColor: AppColors.primary,
      dropdownColor: AppColors.surface,
      decoration: const InputDecoration(
        labelText: 'Usuario responsable',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
      ),
      items: _usuarios.map((UsuarioModel usuario) {
        return DropdownMenuItem<int>(
          value: usuario.id,
          child: Text(
            usuario.nombreVisible,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (int? value) {
        setState(() {
          _usuarioSeleccionadoId = value;
        });
      },
      validator: (int? value) {
        if (value == null || value <= 0) {
          return 'Selecciona un usuario.';
        }

        return null;
      },
    );
  }

  // =============================================================
  // ERROR CATÁLOGOS
  // =============================================================

  Widget _construirErrorCatalogos() {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.riskOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.riskOrange,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No se pudieron cargar los datos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorCatalogos!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _cargarCatalogos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MENSAJE ERROR
  // =============================================================

  Widget _construirMensajeError(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.riskOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.riskOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            color: AppColors.riskOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // NOMBRE DEL DETALLE
  // =============================================================

  String _nombreDetalle(DetalleIpercModel detalle) {
    final String codigo = detalle.matrizIpercCodigo.trim();

    final String tarea = detalle.tarea.trim().isEmpty
        ? 'Sin tarea'
        : detalle.tarea.trim();

    final String itemTarea = 'Item ${detalle.item} - $tarea';

    if (codigo.isEmpty) {
      return itemTarea;
    }

    return '$codigo | $itemTarea';
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  String _obtenerMensajeError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'DioException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}

// ===============================================================
// SECCIÓN FORMULARIO
// ===============================================================

class _FormularioSeccion extends StatelessWidget {
  const _FormularioSeccion({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.child,
    this.colorTexto,
  });

  final String titulo;
  final IconData icono;
  final Color color;
  final Color? colorTexto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icono, color: foreground, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
