import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/network_info.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/datasources/local/detalle_iperc_local_datasource.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_local_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../providers/seguimiento_iperc_provider.dart';

/// ===============================================================
/// FORMULARIO - SEGUIMIENTO IPERC
/// ===============================================================
///
/// Funciona en:
///
/// - Modo ONLINE.
/// - Modo OFFLINE.
///
/// El usuario nunca escribe IDs manualmente.
///
/// El selector combina:
///
/// - Detalles remotos.
/// - Detalles locales.
///
/// Si el detalle seleccionado tiene ID remoto y existe conexión,
/// se registra directamente en el backend.
///
/// Si el detalle todavía solo existe localmente, el seguimiento se
/// guarda en SQLite aunque exista Internet. Luego la cola respetará:
///
/// MATRIZ → DETALLE → SEGUIMIENTO.
///
/// ===============================================================
class SeguimientoIpercFormScreen
    extends StatefulWidget {
  const SeguimientoIpercFormScreen({
    this.seguimiento,
    this.seguimientoLocal,
    this.detalleIpercIdInicial,
    this.detalleIpercIdLocalInicial,
    super.key,
  });

  /// Registro remoto en edición.
  final SeguimientoIpercModel? seguimiento;

  /// Registro local en edición.
  final SeguimientoIpercLocalModel? seguimientoLocal;

  /// ID remoto preseleccionado.
  final int? detalleIpercIdInicial;

  /// UUID local preseleccionado.
  final String? detalleIpercIdLocalInicial;

  @override
  State<SeguimientoIpercFormScreen>
      createState() =>
          _SeguimientoIpercFormScreenState();
}

class _SeguimientoIpercFormScreenState
    extends State<SeguimientoIpercFormScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  final TextEditingController
      _observacionesController =
      TextEditingController();

  final DetalleIpercRepository
      _detalleRepository =
      DetalleIpercRepository();

  final DetalleIpercLocalDatasource
      _detalleLocalDatasource =
      DetalleIpercLocalDatasource();

  // =============================================================
  // CATÁLOGO UNIFICADO DE DETALLES
  // =============================================================

  List<_DetalleSeleccionable> _detalles =
      <_DetalleSeleccionable>[];

  _DetalleSeleccionable? _detalleSeleccionado;

  bool _cargandoDetalles = true;

  String? _errorDetalles;

  // =============================================================
  // DATOS DEL FORMULARIO
  // =============================================================

  int _usuarioId = 0;

  DateTime _fechaSeguimiento =
      DateTime.now();

  double _porcentajeAvance = 0;

  bool _verificado = false;

  bool _hayConexion = false;

  // =============================================================
  // MODO
  // =============================================================

  bool get _esEdicionRemota =>
      widget.seguimiento != null;

  bool get _esEdicionLocal =>
      widget.seguimientoLocal != null;

  bool get _esEdicion =>
      _esEdicionRemota ||
      _esEdicionLocal;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    final SeguimientoIpercModel? remoto =
        widget.seguimiento;

    final SeguimientoIpercLocalModel? local =
        widget.seguimientoLocal;

    if (remoto != null) {
      _usuarioId = remoto.usuarioId;
      _fechaSeguimiento =
          remoto.fechaSeguimiento;
      _porcentajeAvance =
          remoto.porcentajeAvance
              .clamp(0, 100)
              .toDouble();
      _verificado = remoto.verificado;
      _descripcionController.text =
          remoto.descripcion;
      _observacionesController.text =
          remoto.observaciones ?? '';
    } else if (local != null) {
      _usuarioId = local.usuarioId;
      _fechaSeguimiento =
          local.fechaSeguimiento;
      _porcentajeAvance =
          local.porcentajeAvance
              .clamp(0, 100)
              .toDouble();
      _verificado = local.verificado;
      _descripcionController.text =
          local.descripcion;
      _observacionesController.text =
          local.observaciones ?? '';
    }

    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // =============================================================
  // CARGA INICIAL
  // =============================================================

  Future<void> _cargarDatosIniciales() async {
    await Future.wait(<Future<void>>[
      _cargarUsuario(),
      _comprobarConexion(),
      _cargarDetalles(),
    ]);
  }

  Future<void> _comprobarConexion() async {
    final bool conectado =
        await NetworkInfo.instance.isConnected;

    if (!mounted) {
      return;
    }

    setState(() {
      _hayConexion = conectado;
    });
  }

  Future<void> _cargarUsuario() async {
    if (_usuarioId > 0) {
      return;
    }

    final String? usuarioIdTexto =
        await SecureStorageService.instance
            .getUsuarioId();

    final int usuarioId =
        int.tryParse(
          usuarioIdTexto ?? '',
        ) ??
        0;

    if (!mounted) {
      return;
    }

    setState(() {
      _usuarioId = usuarioId;
    });
  }

  // =============================================================
  // CARGAR DETALLES ONLINE + OFFLINE
  // =============================================================

  Future<void> _cargarDetalles() async {
    if (mounted) {
      setState(() {
        _cargandoDetalles = true;
        _errorDetalles = null;
      });
    }

    try {
      final List<_DetalleSeleccionable>
          combinados =
          <_DetalleSeleccionable>[];

      // ---------------------------------------------------------
      // DETALLES LOCALES
      // ---------------------------------------------------------

      final List<DetalleIpercLocalModel>
          locales =
          await _detalleLocalDatasource
              .listarTodos();

      for (final DetalleIpercLocalModel local
          in locales) {
        final int? servidorId =
            int.tryParse(
          local.idServidor?.trim() ?? '',
        );

        combinados.add(
          _DetalleSeleccionable(
            idLocal: local.idLocal,
            idServidor:
                servidorId != null &&
                        servidorId > 0
                    ? servidorId
                    : null,
            item: local.item,
            tarea: local.tarea.trim().isEmpty
                ? 'Sin tarea'
                : local.tarea.trim(),
            esLocal: true,
          ),
        );
      }

      // ---------------------------------------------------------
      // DETALLES REMOTOS
      // ---------------------------------------------------------

      final bool conectado =
          await NetworkInfo.instance.isConnected;

      if (conectado) {
        try {
          final List<DetalleIpercModel>
              remotos =
              await _detalleRepository
                  .obtenerTodos();

          final Set<int> idsYaIncluidos =
              combinados
                  .where(
                    (
                      _DetalleSeleccionable item,
                    ) =>
                        item.idServidor != null,
                  )
                  .map(
                    (
                      _DetalleSeleccionable item,
                    ) =>
                        item.idServidor!,
                  )
                  .toSet();

          for (final DetalleIpercModel remoto
              in remotos) {
            if (idsYaIncluidos.contains(
              remoto.id,
            )) {
              continue;
            }

            combinados.add(
              _DetalleSeleccionable(
                idLocal: null,
                idServidor: remoto.id,
                item: remoto.item,
                tarea:
                    remoto.tarea.trim().isEmpty
                        ? 'Sin tarea'
                        : remoto.tarea.trim(),
                esLocal: false,
              ),
            );
          }
        } catch (_) {
          // Si falla el backend pero hay detalles locales,
          // el formulario sigue siendo utilizable offline.
        }
      }

      combinados.sort(
        (
          _DetalleSeleccionable a,
          _DetalleSeleccionable b,
        ) {
          final int porItem =
              a.item.compareTo(b.item);

          if (porItem != 0) {
            return porItem;
          }

          return a.tarea.compareTo(b.tarea);
        },
      );

      final _DetalleSeleccionable?
          seleccionado =
          _resolverSeleccionInicial(
        combinados,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hayConexion = conectado;
        _detalles = combinados;
        _detalleSeleccionado =
            seleccionado ??
            (combinados.isNotEmpty
                ? combinados.first
                : null);
        _cargandoDetalles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoDetalles = false;
        _errorDetalles = error
            .toString()
            .replaceFirst(
              'Exception:',
              '',
            )
            .trim();
      });
    }
  }

  _DetalleSeleccionable?
      _resolverSeleccionInicial(
    List<_DetalleSeleccionable> detalles,
  ) {
    // -----------------------------------------------------------
    // EDICIÓN LOCAL
    // -----------------------------------------------------------

    final SeguimientoIpercLocalModel? local =
        widget.seguimientoLocal;

    if (local != null) {
      for (final _DetalleSeleccionable item
          in detalles) {
        if (item.idLocal ==
            local.detalleIpercIdLocal) {
          return item;
        }
      }
    }

    // -----------------------------------------------------------
    // EDICIÓN REMOTA
    // -----------------------------------------------------------

    final SeguimientoIpercModel? remoto =
        widget.seguimiento;

    if (remoto != null) {
      for (final _DetalleSeleccionable item
          in detalles) {
        if (item.idServidor ==
            remoto.detalleIpercId) {
          return item;
        }
      }
    }

    // -----------------------------------------------------------
    // PRESELECCIÓN LOCAL
    // -----------------------------------------------------------

    final String localInicial =
        widget.detalleIpercIdLocalInicial
                ?.trim() ??
            '';

    if (localInicial.isNotEmpty) {
      for (final _DetalleSeleccionable item
          in detalles) {
        if (item.idLocal == localInicial) {
          return item;
        }
      }
    }

    // -----------------------------------------------------------
    // PRESELECCIÓN REMOTA
    // -----------------------------------------------------------

    final int? servidorInicial =
        widget.detalleIpercIdInicial;

    if (servidorInicial != null &&
        servidorInicial > 0) {
      for (final _DetalleSeleccionable item
          in detalles) {
        if (item.idServidor ==
            servidorInicial) {
          return item;
        }
      }
    }

    return null;
  }

  // =============================================================
  // FECHA
  // =============================================================

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha =
        await showDatePicker(
      context: context,
      initialDate: _fechaSeguimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) {
      return;
    }

    setState(() {
      _fechaSeguimiento = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        _fechaSeguimiento.hour,
        _fechaSeguimiento.minute,
      );
    });
  }

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    final FormState? form =
        _formKey.currentState;

    if (form == null ||
        !form.validate()) {
      return;
    }

    final _DetalleSeleccionable? detalle =
        _detalleSeleccionado;

    if (detalle == null) {
      _mostrarMensaje(
        'Selecciona un detalle IPERC válido.',
        esError: true,
      );
      return;
    }

    if (_usuarioId <= 0) {
      _mostrarMensaje(
        'No se pudo identificar el usuario de la sesión.',
        esError: true,
      );
      return;
    }

    final SeguimientoIpercProvider provider =
        context.read<SeguimientoIpercProvider>();

    final bool correcto;

    // ===========================================================
    // EDICIÓN LOCAL
    // ===========================================================

    if (_esEdicionLocal) {
      correcto =
          await provider.actualizarOffline(
        idLocal:
            widget.seguimientoLocal!.idLocal,
        fechaSeguimiento:
            _fechaSeguimiento,
        descripcion:
            _descripcionController.text,
        porcentajeAvance:
            _porcentajeAvance,
        observaciones:
            _observacionesController.text,
        archivo:
            widget.seguimientoLocal!.archivo,
        nombreArchivo:
            widget
                .seguimientoLocal!
                .nombreArchivo,
        tipoArchivo:
            widget
                .seguimientoLocal!
                .tipoArchivo,
      );

      // El cambio del switch se procesa después de guardar.
      if (correcto) {
        final bool estabaVerificado =
            widget
                .seguimientoLocal!
                .verificado;

        if (_verificado &&
            !estabaVerificado) {
          await provider.verificarOffline(
            idLocal:
                widget
                    .seguimientoLocal!
                    .idLocal,
          );
        } else if (!_verificado &&
            estabaVerificado) {
          await provider
              .quitarVerificacionOffline(
            idLocal:
                widget
                    .seguimientoLocal!
                    .idLocal,
          );
        }
      }
    }
    // ===========================================================
    // EDICIÓN REMOTA
    // ===========================================================
    else if (_esEdicionRemota) {
      final int? detalleServidor =
          detalle.idServidor;

      if (detalleServidor == null ||
          detalleServidor <= 0) {
        _mostrarMensaje(
          'El seguimiento remoto necesita un '
          'Detalle IPERC sincronizado.',
          esError: true,
        );
        return;
      }

      final DateTime? fechaVerificacion =
          _verificado
              ? widget
                      .seguimiento!
                      .fechaVerificacion ??
                  DateTime.now()
              : null;

      correcto =
          await provider.actualizar(
        widget.seguimiento!.id,
        ActualizarSeguimientoIpercRequest(
          detalleIpercId:
              detalleServidor,
          fechaSeguimiento:
              _fechaSeguimiento,
          usuarioId: _usuarioId,
          descripcion:
              _descripcionController.text,
          porcentajeAvance:
              _porcentajeAvance,
          verificado: _verificado,
          fechaVerificacion:
              fechaVerificacion,
          observaciones:
              _observacionesController.text,
          archivo:
              widget.seguimiento!.archivo,
          nombreArchivo:
              widget
                  .seguimiento!
                  .nombreArchivo,
          tipoArchivo:
              widget
                  .seguimiento!
                  .tipoArchivo,
        ),
      );
    }
    // ===========================================================
    // NUEVO
    // ===========================================================
    else {
      // ---------------------------------------------------------
      // DETALLE SOLO LOCAL
      // ---------------------------------------------------------
      //
      // Aunque haya Internet, no puede hacerse POST si el detalle
      // todavía no existe en backend.
      // ---------------------------------------------------------

      if (detalle.idServidor == null) {
        final String localId =
            detalle.idLocal ?? '';

        correcto =
            await provider.crearOffline(
          detalleIpercIdLocal: localId,
          fechaSeguimiento:
              _fechaSeguimiento,
          descripcion:
              _descripcionController.text,
          porcentajeAvance:
              _porcentajeAvance,
          observaciones:
              _observacionesController.text,
        );
      } else if (_hayConexion) {
        // -------------------------------------------------------
        // ONLINE
        // -------------------------------------------------------

        correcto = await provider.crear(
          CrearSeguimientoIpercRequest(
            detalleIpercId:
                detalle.idServidor!,
            fechaSeguimiento:
                _fechaSeguimiento,
            usuarioId: _usuarioId,
            descripcion:
                _descripcionController.text,
            porcentajeAvance:
                _porcentajeAvance,
            verificado: _verificado,
            fechaVerificacion:
                _verificado
                    ? DateTime.now()
                    : null,
            observaciones:
                _observacionesController.text,
          ),
        );
      } else {
        // -------------------------------------------------------
        // SIN INTERNET, PERO EL DETALLE TIENE COPIA LOCAL
        // -------------------------------------------------------

        final String localId =
            detalle.idLocal ?? '';

        if (localId.isEmpty) {
          _mostrarMensaje(
            'Este detalle solo está disponible en el '
            'servidor. Conéctate a Internet para '
            'registrar el seguimiento.',
            esError: true,
          );
          return;
        }

        correcto =
            await provider.crearOffline(
          detalleIpercIdLocal: localId,
          fechaSeguimiento:
              _fechaSeguimiento,
          descripcion:
              _descripcionController.text,
          porcentajeAvance:
              _porcentajeAvance,
          observaciones:
              _observacionesController.text,
        );
      }
    }

    if (!mounted) {
      return;
    }

    if (correcto) {
      Navigator.of(context).pop(true);
      return;
    }

    _mostrarMensaje(
      provider.error ??
          'No se pudo guardar el seguimiento IPERC.',
      esError: true,
    );
  }

  // =============================================================
  // MENSAJE
  // =============================================================

  void _mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError
              ? Theme.of(context)
                  .colorScheme
                  .error
              : null,
          content: Text(mensaje),
        ),
      );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion
              ? 'Editar seguimiento'
              : 'Nuevo seguimiento',
        ),
      ),
      body:
          Consumer<SeguimientoIpercProvider>(
        builder: (
          BuildContext context,
          SeguimientoIpercProvider provider,
          Widget? child,
        ) {
          return Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                96,
              ),
              children: <Widget>[
                _ModoCard(
                  conectado: _hayConexion,
                ),
                const SizedBox(height: 12),

                _DetalleSelector(
                  cargando:
                      _cargandoDetalles,
                  error: _errorDetalles,
                  detalles: _detalles,
                  valor:
                      _detalleSeleccionado,
                  onChanged: _esEdicion
                      ? null
                      : (
                          _DetalleSeleccionable?
                              value,
                        ) {
                          setState(() {
                            _detalleSeleccionado =
                                value;
                          });
                        },
                  onRetry: _cargarDetalles,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      _descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Descripción del avance',
                    border:
                        OutlineInputBorder(),
                  ),
                  validator:
                      (String? value) {
                    final String texto =
                        (value ?? '')
                            .trim();

                    if (texto.isEmpty) {
                      return 'Ingresa la descripción '
                          'del seguimiento.';
                    }

                    if (texto.length > 3000) {
                      return 'La descripción no debe '
                          'superar 3000 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      _observacionesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText: 'Observaciones',
                    border:
                        OutlineInputBorder(),
                  ),
                  validator:
                      (String? value) {
                    if ((value ?? '')
                            .trim()
                            .length >
                        3000) {
                      return 'Las observaciones no '
                          'deben superar 3000 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Fecha: '
                                '${_formatearFecha(_fechaSeguimiento)}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _seleccionarFecha,
                              icon: const Icon(
                                Icons
                                    .calendar_month,
                              ),
                              label: const Text(
                                'Cambiar',
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Avance: '
                          '${_porcentajeAvance.toStringAsFixed(0)}%',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        Slider(
                          value:
                              _porcentajeAvance,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label:
                              '${_porcentajeAvance.toStringAsFixed(0)}%',
                          onChanged:
                              (double value) {
                            setState(() {
                              _porcentajeAvance =
                                  value;
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          title: const Text(
                            'Marcar como verificado',
                          ),
                          subtitle:
                              !_esEdicion &&
                                      (_detalleSeleccionado
                                                  ?.idServidor ==
                                              null ||
                                          !_hayConexion)
                                  ? const Text(
                                      'Si se guarda offline, '
                                      'puedes verificarlo '
                                      'después desde la lista.',
                                    )
                                  : null,
                          value: _verificado,
                          onChanged:
                              (!_esEdicion &&
                                      (_detalleSeleccionado
                                                  ?.idServidor ==
                                              null ||
                                          !_hayConexion))
                                  ? null
                                  : (bool value) {
                                      setState(
                                        () {
                                          _verificado =
                                              value;

                                          if (value &&
                                              _porcentajeAvance <
                                                  100) {
                                            _porcentajeAvance =
                                                100;
                                          }
                                        },
                                      );
                                    },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child:
            Consumer<SeguimientoIpercProvider>(
          builder: (
            BuildContext context,
            SeguimientoIpercProvider provider,
            Widget? child,
          ) {
            return FilledButton.icon(
              onPressed: provider.procesando
                  ? null
                  : _guardar,
              icon: provider.procesando
                  ? const SizedBox.square(
                      dimension: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                    ),
              label: Text(
                _esEdicion
                    ? 'Actualizar'
                    : 'Guardar',
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===============================================================
// MODELO INTERNO PARA EL SELECTOR
// ===============================================================

class _DetalleSeleccionable {
  const _DetalleSeleccionable({
    required this.item,
    required this.tarea,
    required this.esLocal,
    this.idLocal,
    this.idServidor,
  });

  final String? idLocal;
  final int? idServidor;
  final int item;
  final String tarea;
  final bool esLocal;

  String get clave {
    if (idLocal != null &&
        idLocal!.trim().isNotEmpty) {
      return 'LOCAL:${idLocal!.trim()}';
    }

    return 'SERVER:${idServidor ?? 0}';
  }

  String get etiqueta {
    final String origen =
        idServidor == null
            ? 'Offline'
            : esLocal
                ? 'Local / sincronizado'
                : 'Servidor';

    return 'Item $item - $tarea · $origen';
  }
}

// ===============================================================
// SELECTOR DE DETALLE
// ===============================================================

class _DetalleSelector extends StatelessWidget {
  const _DetalleSelector({
    required this.cargando,
    required this.detalles,
    required this.valor,
    required this.onChanged,
    required this.onRetry,
    this.error,
  });

  final bool cargando;
  final String? error;
  final List<_DetalleSeleccionable> detalles;
  final _DetalleSeleccionable? valor;
  final ValueChanged<_DetalleSeleccionable?>?
      onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cargando detalles IPERC...',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null &&
        error!.trim().isNotEmpty &&
        detalles.isEmpty) {
      return Card(
        color: Theme.of(context)
            .colorScheme
            .errorContainer,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(error!),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon:
                    const Icon(Icons.refresh),
                label:
                    const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final String? valorClave =
        valor?.clave;

    return DropdownButtonFormField<String>(
      initialValue: detalles.any(
        (_DetalleSeleccionable item) =>
            item.clave == valorClave,
      )
          ? valorClave
          : null,
      isExpanded: true,
      decoration:
          const InputDecoration(
        labelText: 'Detalle IPERC',
        border: OutlineInputBorder(),
      ),
      items: detalles
          .map(
            (_DetalleSeleccionable item) =>
                DropdownMenuItem<String>(
              value: item.clave,
              child: Text(
                item.etiqueta,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged == null
          ? null
          : (String? clave) {
              if (clave == null) {
                onChanged!(null);
                return;
              }

              for (final _DetalleSeleccionable
                  item in detalles) {
                if (item.clave == clave) {
                  onChanged!(item);
                  return;
                }
              }

              onChanged!(null);
            },
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Selecciona el detalle IPERC.';
        }

        return null;
      },
    );
  }
}

// ===============================================================
// INDICADOR ONLINE / OFFLINE
// ===============================================================

class _ModoCard extends StatelessWidget {
  const _ModoCard({
    required this.conectado,
  });

  final bool conectado;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          conectado
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_outlined,
        ),
        title: Text(
          conectado
              ? 'Conexión disponible'
              : 'Modo offline',
        ),
        subtitle: Text(
          conectado
              ? 'Los detalles sincronizados '
                  'pueden guardarse directamente '
                  'en el servidor.'
              : 'El seguimiento se guardará '
                  'en el dispositivo y se '
                  'sincronizará después.',
        ),
      ),
    );
  }
}

String _formatearFecha(
  DateTime fecha,
) {
  final String dia =
      fecha.day.toString().padLeft(2, '0');

  final String mes =
      fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes/${fecha.year}';
}
