import 'package:flutter/material.dart';

import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/seguimiento_iperc_repository.dart';
import '../../../data/repositories/usuario_repository.dart';

/// ===============================================================
/// PANTALLA - SEGUIMIENTOS IPERC
/// ===============================================================
///
/// Permite:
///
/// - Consultar seguimientos.
/// - Buscar.
/// - Filtrar por estado.
/// - Crear.
/// - Editar.
/// - Verificar.
/// - Eliminar.
/// ===============================================================
class SeguimientosScreen extends StatefulWidget {
  const SeguimientosScreen({this.detalleIpercId, super.key});

  /// Si se proporciona un detalle IPERC,
  /// solamente se muestran sus seguimientos.
  final int? detalleIpercId;

  @override
  State<SeguimientosScreen> createState() {
    return _SeguimientosScreenState();
  }
}

class _SeguimientosScreenState extends State<SeguimientosScreen> {
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
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titulo),

          content: Text(mensaje),

          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
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
      appBar: AppBar(
        title: const Text('Seguimientos IPERC'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarSeguimientos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando
            ? null
            : () {
                _abrirFormulario();
              },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),

      body: RefreshIndicator(
        onRefresh: _cargarSeguimientos,

        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          slivers: <Widget>[
            SliverToBoxAdapter(child: _construirResumen()),

            SliverToBoxAdapter(child: _construirFiltros()),

            if (_cargando && _seguimientos.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _seguimientos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EstadoVacio(
                  icono: Icons.cloud_off,
                  titulo: 'No se pudieron cargar los seguimientos',
                  descripcion: _error!,
                  textoBoton: 'Reintentar',
                  onPressed: _cargarSeguimientos,
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

                  textoBoton: _seguimientos.isEmpty
                      ? 'Registrar seguimiento'
                      : null,

                  onPressed: _seguimientos.isEmpty
                      ? () {
                          _abrirFormulario();
                        }
                      : null,
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
          if (widget.detalleIpercId != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.assignment)),
                title: Text(
                  'Detalle IPERC '
                  '${widget.detalleIpercId}',
                ),
                subtitle: const Text(
                  'Mostrando seguimientos '
                  'del detalle seleccionado.',
                ),
              ),
            ),

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
              ),

              _ResumenItem(
                icono: Icons.pending_actions,
                titulo: 'Pendientes',
                valor: pendientes.toString(),
              ),

              _ResumenItem(
                icono: Icons.verified_outlined,
                titulo: 'Verificados',
                valor: verificados.toString(),
              ),

              _ResumenItem(
                icono: Icons.percent,
                titulo: 'Avance promedio',
                valor: '${avancePromedio.toStringAsFixed(0)} %',
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
              prefixIcon: const Icon(Icons.search),

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
                      icon: const Icon(Icons.clear),
                    ),

              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          SegmentedButton<bool?>(
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
  });

  final SeguimientoIpercModel seguimiento;

  final VoidCallback onEditar;

  final VoidCallback onVerificar;

  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final double porcentaje = seguimiento.porcentajeAvance
        .clamp(0, 100)
        .toDouble();

    final Color estadoColor = seguimiento.verificado
        ? Colors.green
        : Colors.orange;

    return Card(
      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: <Widget>[
                CircleAvatar(
                  backgroundColor: estadoColor.withValues(alpha: 0.15),

                  child: Icon(
                    seguimiento.verificado
                        ? Icons.verified
                        : Icons.pending_actions,

                    color: estadoColor,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(_formatearFecha(seguimiento.fechaSeguimiento)),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
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
                      const PopupMenuItem<String>(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      if (!seguimiento.verificado)
                        const PopupMenuItem<String>(
                          value: 'verificar',
                          child: ListTile(
                            leading: Icon(Icons.verified),
                            title: Text('Verificar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                      const PopupMenuItem<String>(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
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

            Text(seguimiento.descripcion),

            if ((seguimiento.observaciones ?? '')
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),

              Text(
                'Observaciones: '
                '${seguimiento.observaciones}',
                style: Theme.of(context).textTheme.bodySmall,
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
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  '${porcentaje.toStringAsFixed(0)} %',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: <Widget>[
                Chip(
                  avatar: Icon(
                    seguimiento.verificado
                        ? Icons.check_circle
                        : Icons.schedule,
                    size: 18,
                  ),
                  label: Text(seguimiento.estadoVisible),
                ),

                if ((seguimiento.usuarioNombre ?? '').trim().isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: Text(seguimiento.usuarioNombre!),
                  ),

                if ((seguimiento.nombreArchivo ?? '').trim().isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.attach_file, size: 18),
                    label: Text(seguimiento.nombreArchivo!),
                  ),
              ],
            ),
          ],
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
// RESUMEN
// ===============================================================

class _ResumenItem extends StatelessWidget {
  const _ResumenItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;

  final String titulo;

  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          children: <Widget>[
            CircleAvatar(child: Icon(icono)),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: <Widget>[
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
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
    this.textoBoton,
    this.onPressed,
  });

  final IconData icono;

  final String titulo;

  final String descripcion;

  final String? textoBoton;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: <Widget>[
            Icon(icono, size: 68, color: Theme.of(context).colorScheme.outline),

            const SizedBox(height: 16),

            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(descripcion, textAlign: TextAlign.center),

            if (textoBoton != null && onPressed != null) ...<Widget>[
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh),
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

      // ---------------------------------------------------------
      // ORDENAR DETALLES
      // ---------------------------------------------------------
      //
      // CORRECCIÓN:
      // matrizIpercCodigo ya NO es nullable.
      // Por eso eliminamos los operadores ?? ''.

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
      title: Text(_esEdicion ? 'Editar seguimiento' : 'Nuevo seguimiento'),

      content: SizedBox(
        width: 520,

        child: _cargandoCatalogos
            ? const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            : _errorCatalogos != null
            ? _construirErrorCatalogos()
            : Form(
                key: _formKey,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: <Widget>[
                      _construirSelectorDetalle(),

                      const SizedBox(height: 12),

                      _construirSelectorUsuario(),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: _seleccionarFecha,

                        borderRadius: BorderRadius.circular(8),

                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de seguimiento',
                            prefixIcon: Icon(Icons.calendar_month),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(fechaTexto),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descripcionController,

                        maxLines: 3,

                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe el avance realizado',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
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

                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerLeft,

                        child: Text(
                          'Porcentaje de avance: '
                          '${_porcentajeAvance.toStringAsFixed(0)} %',

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Slider(
                        value: _porcentajeAvance,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_porcentajeAvance.toStringAsFixed(0)} %',
                        onChanged: (double value) {
                          setState(() {
                            _porcentajeAvance = value;
                          });
                        },
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,

                        title: const Text('Seguimiento verificado'),

                        subtitle: const Text(
                          'Indica que el avance fue revisado y aprobado.',
                        ),

                        value: _verificado,

                        onChanged: (bool value) {
                          setState(() {
                            _verificado = value;
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Información de evidencia'),
                        leading: const Icon(Icons.attach_file),
                        children: <Widget>[
                          TextFormField(
                            controller: _nombreArchivoController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del archivo',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _tipoArchivoController,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de archivo',
                              hintText: 'image/jpeg, application/pdf',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _archivoController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Ruta o contenido del archivo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
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
          onPressed: _guardando || _cargandoCatalogos || _errorCatalogos != null
              ? null
              : _guardar,

          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
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

      decoration: const InputDecoration(
        labelText: 'Detalle IPERC',
        prefixIcon: Icon(Icons.assignment_outlined),
        border: OutlineInputBorder(),
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

      decoration: const InputDecoration(
        labelText: 'Usuario responsable',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
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
      height: 240,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: <Widget>[
          Icon(
            Icons.cloud_off,
            size: 54,
            color: Theme.of(context).colorScheme.error,
          ),

          const SizedBox(height: 14),

          const Text(
            'No se pudieron cargar los datos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(_errorCatalogos!, textAlign: TextAlign.center),

          const SizedBox(height: 16),

          FilledButton.icon(
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
        color: Theme.of(context).colorScheme.errorContainer,

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        mensaje,

        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }

  // =============================================================
  // NOMBRE DEL DETALLE
  // =============================================================

  String _nombreDetalle(DetalleIpercModel detalle) {
    /// CORRECCIÓN:
    ///
    /// matrizIpercCodigo ya es String no nullable.
    /// Por eso eliminamos ?.
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
