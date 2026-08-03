import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/peligro_model.dart';
import '../../providers/detalle_iperc_catalogos_provider.dart';
import '../../providers/detalle_iperc_offline_provider.dart';

/// Formulario para registrar o editar un detalle IPERC.
///
/// El registro se almacena primero en SQLite. Cuando exista conexión,
/// podrá sincronizarse con el backend.
class DetalleIpercFormScreen extends StatefulWidget {
  const DetalleIpercFormScreen({
    super.key,
    required this.matrizIdLocal,
    this.matrizIdServidor,
    this.siguienteItem,
    this.detalle,
  });

  /// Identificador local de la matriz.
  final String matrizIdLocal;

  /// Identificador de la matriz en el backend.
  final int? matrizIdServidor;

  /// Número sugerido para el nuevo detalle.
  final int? siguienteItem;

  /// Detalle que se editará.
  final DetalleIpercLocalModel? detalle;

  bool get esEdicion => detalle != null;

  @override
  State<DetalleIpercFormScreen> createState() => _DetalleIpercFormScreenState();
}

class _DetalleIpercFormScreenState extends State<DetalleIpercFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _itemController;
  late final TextEditingController _tareaController;
  late final TextEditingController _actividadController;
  late final TextEditingController _controlController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _responsableController;

  int? _peligroIdSeleccionado;
  int? _consecuenciaIdSeleccionada;

  int _severidadInicial = 1;
  int _frecuenciaInicial = 1;

  int? _severidadResidual;
  int? _frecuenciaResidual;

  bool _registrarEvaluacionResidual = false;

  DateTime? _fechaCompromiso;
  DateTime? _fechaImplementacion;

  String _estadoImplementacion = 'PENDIENTE';

  static const List<String> _estadosImplementacion = <String>[
    'PENDIENTE',
    'EN_PROCESO',
    'IMPLEMENTADO',
    'VERIFICADO',
    'CERRADO',
  ];

  @override
  void initState() {
    super.initState();

    final DetalleIpercLocalModel? detalle = widget.detalle;

    _itemController = TextEditingController(
      text: (detalle?.item ?? widget.siguienteItem ?? 1).toString(),
    );

    _tareaController = TextEditingController(
      text: detalle?.tarea ?? detalle?.actividadDescripcion ?? '',
    );

    _actividadController = TextEditingController(
      text: detalle?.actividadDescripcion ?? '',
    );

    _controlController = TextEditingController(
      text: detalle?.controlDescripcion ?? '',
    );

    _observacionesController = TextEditingController(
      text: detalle?.observaciones ?? '',
    );

    _responsableController = TextEditingController(
      text: detalle?.responsableImplementacionId ?? '',
    );

    _peligroIdSeleccionado = int.tryParse(detalle?.peligroId ?? '');

    _consecuenciaIdSeleccionada = int.tryParse(detalle?.consecuenciaId ?? '');

    if (detalle != null) {
      _severidadInicial = detalle.severidadInicial;
      _frecuenciaInicial = detalle.frecuenciaInicial;

      _severidadResidual = detalle.severidadResidual;
      _frecuenciaResidual = detalle.frecuenciaResidual;

      _registrarEvaluacionResidual =
          detalle.severidadResidual != null &&
          detalle.frecuenciaResidual != null;

      _fechaCompromiso = detalle.fechaCompromiso;
      _fechaImplementacion = detalle.fechaImplementacion;

      _estadoImplementacion = detalle.estadoImplementacion ?? 'PENDIENTE';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCatalogos();
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _tareaController.dispose();
    _actividadController.dispose();
    _controlController.dispose();
    _observacionesController.dispose();
    _responsableController.dispose();

    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    await context.read<DetalleIpercCatalogosProvider>().cargar();

    if (mounted) {
      setState(() {});
    }
  }

  int get _valorRiesgoInicial {
    return _severidadInicial * _frecuenciaInicial;
  }

  int? get _valorRiesgoResidual {
    if (!_registrarEvaluacionResidual ||
        _severidadResidual == null ||
        _frecuenciaResidual == null) {
      return null;
    }

    return _severidadResidual! * _frecuenciaResidual!;
  }

  String _obtenerNivelRiesgo(int valor) {
    if (valor <= 4) {
      return 'BAJO';
    }

    if (valor <= 9) {
      return 'MEDIO';
    }

    if (valor <= 16) {
      return 'ALTO';
    }

    return 'CRÍTICO';
  }

  Color _obtenerColorRiesgo(int valor) {
    if (valor <= 4) {
      return Colors.green.shade700;
    }

    if (valor <= 9) {
      return Colors.amber.shade800;
    }

    if (valor <= 16) {
      return Colors.orange.shade800;
    }

    return Colors.red.shade700;
  }

  String _crearIdLocal() {
    return 'DET-${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _validarCampoObligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validarItem(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de ítem es obligatorio.';
    }

    final int? item = int.tryParse(value.trim());

    if (item == null || item <= 0) {
      return 'Ingrese un número de ítem válido.';
    }

    return null;
  }

  String? _validarPeligro(int? value) {
    if (value == null || value <= 0) {
      return 'Seleccione un peligro.';
    }

    return null;
  }

  String? _validarConsecuencia(int? value) {
    if (value == null || value <= 0) {
      return 'Seleccione una consecuencia.';
    }

    return null;
  }

  String? _textoOpcional(String value) {
    final String texto = value.trim();

    return texto.isEmpty ? null : texto;
  }

  Future<void> _seleccionarFechaCompromiso() async {
    final DateTime ahora = DateTime.now();

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompromiso ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de compromiso',
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaCompromiso = fecha;
      });
    }
  }

  Future<void> _seleccionarFechaImplementacion() async {
    final DateTime ahora = DateTime.now();

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaImplementacion ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de implementación',
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaImplementacion = fecha;
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'No seleccionada';
    }

    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_peligroIdSeleccionado == null || _consecuenciaIdSeleccionada == null) {
      _mostrarMensaje(
        'Seleccione el peligro y la consecuencia.',
        esError: true,
      );
      return;
    }

    if (_registrarEvaluacionResidual &&
        (_severidadResidual == null || _frecuenciaResidual == null)) {
      _mostrarMensaje(
        'Complete la severidad y frecuencia residual.',
        esError: true,
      );
      return;
    }

    final DetalleIpercCatalogosProvider catalogos = context
        .read<DetalleIpercCatalogosProvider>();

    final PeligroModel? peligro = catalogos.buscarPeligroPorId(
      _peligroIdSeleccionado,
    );

    final ConsecuenciaModel? consecuencia = catalogos.buscarConsecuenciaPorId(
      _consecuenciaIdSeleccionada,
    );

    if (peligro == null || consecuencia == null) {
      _mostrarMensaje(
        'No se pudo obtener la información del peligro o consecuencia.',
        esError: true,
      );
      return;
    }

    final DetalleIpercOfflineProvider provider = context
        .read<DetalleIpercOfflineProvider>();

    final DateTime ahora = DateTime.now().toUtc();
    final DetalleIpercLocalModel? anterior = widget.detalle;

    final int? valorResidual = _valorRiesgoResidual;

    final DetalleIpercLocalModel detalle = DetalleIpercLocalModel(
      idLocal: anterior?.idLocal ?? _crearIdLocal(),
      idServidor: anterior?.idServidor,

      matrizIdLocal: widget.matrizIdLocal,
      matrizIdServidor: anterior?.matrizIdServidor ?? widget.matrizIdServidor,

      item: int.parse(_itemController.text.trim()),
      tarea: _tareaController.text.trim(),

      actividadId: anterior?.actividadId,

      peligroId: peligro.id.toString(),
      consecuenciaId: consecuencia.id.toString(),

      actividadDescripcion: _actividadController.text.trim(),

      peligroDescripcion: peligro.nombreCompleto,
      consecuenciaDescripcion: consecuencia.nombreCompleto,

      evaluacionInicialId: anterior?.evaluacionInicialId,

      severidadInicial: _severidadInicial,
      frecuenciaInicial: _frecuenciaInicial,
      valorRiesgoInicial: _valorRiesgoInicial,
      nivelRiesgoInicial: _obtenerNivelRiesgo(_valorRiesgoInicial),

      controlIds: anterior?.controlIds ?? const <String>[],

      equipoProteccionIds: anterior?.equipoProteccionIds ?? const <String>[],

      controlDescripcion: _textoOpcional(_controlController.text),

      evaluacionResidualId: anterior?.evaluacionResidualId,

      severidadResidual: _registrarEvaluacionResidual
          ? _severidadResidual
          : null,

      frecuenciaResidual: _registrarEvaluacionResidual
          ? _frecuenciaResidual
          : null,

      valorRiesgoResidual: valorResidual,

      nivelRiesgoResidual: valorResidual == null
          ? null
          : _obtenerNivelRiesgo(valorResidual),

      responsableImplementacionId: _textoOpcional(_responsableController.text),

      fechaCompromiso: _fechaCompromiso,
      fechaImplementacion: _fechaImplementacion,

      estadoImplementacion: _estadoImplementacion,

      observaciones: _textoOpcional(_observacionesController.text),

      sincronizado: false,
      eliminado: false,

      fechaRegistro: anterior?.fechaRegistro ?? ahora,

      fechaActualizacion: widget.esEdicion ? ahora : null,

      fechaSincronizacion: anterior?.fechaSincronizacion,
    );

    final bool guardado;

    if (widget.esEdicion) {
      guardado = await provider.actualizar(detalle);
    } else {
      guardado = await provider.crear(detalle);
    }

    if (!mounted) {
      return;
    }

    if (!guardado) {
      _mostrarMensaje(
        provider.error ?? 'No se pudo guardar el detalle IPERC.',
        esError: true,
      );
      return;
    }

    _mostrarMensaje(
      widget.esEdicion
          ? 'Detalle IPERC actualizado localmente.'
          : 'Detalle IPERC guardado localmente.',
    );

    Navigator.of(context).pop(true);
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool guardando = context.select<DetalleIpercOfflineProvider, bool>(
      (DetalleIpercOfflineProvider provider) => provider.guardando,
    );

    final DetalleIpercCatalogosProvider catalogos = context
        .watch<DetalleIpercCatalogosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esEdicion ? 'Editar detalle IPERC' : 'Nuevo detalle IPERC',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar catálogos',
            onPressed:
                catalogos.cargando || catalogos.actualizandoRemoto || guardando
                ? null
                : catalogos.recargar,
            icon: catalogos.actualizandoRemoto
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: catalogos.cargando && !catalogos.cargado
            ? const Center(child: CircularProgressIndicator())
            : _construirFormulario(catalogos: catalogos, guardando: guardando),
      ),
    );
  }

  Widget _construirFormulario({
    required DetalleIpercCatalogosProvider catalogos,
    required bool guardando,
  }) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _construirAvisoOffline(),

          if (catalogos.tieneError) ...<Widget>[
            const SizedBox(height: 12),
            _construirErrorCatalogos(catalogos),
          ],

          if (catalogos.tieneAdvertencia) ...<Widget>[
            const SizedBox(height: 12),
            _construirAdvertenciaCatalogos(catalogos),
          ],

          const SizedBox(height: 20),

          _construirTituloSeccion(
            'Información de la tarea',
            Icons.assignment_outlined,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _itemController,
            enabled: !guardando && !widget.esEdicion,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ítem *',
              prefixIcon: Icon(Icons.numbers),
              border: OutlineInputBorder(),
            ),
            validator: _validarItem,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _tareaController,
            enabled: !guardando,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tarea *',
              hintText: 'Ejemplo: revisar instalaciones eléctricas',
              prefixIcon: Icon(Icons.task_alt_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validarCampoObligatorio,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _actividadController,
            enabled: !guardando,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Actividad o proceso *',
              hintText: 'Ejemplo: mantenimiento preventivo',
              prefixIcon: Icon(Icons.work_outline),
              border: OutlineInputBorder(),
            ),
            validator: _validarCampoObligatorio,
          ),

          const SizedBox(height: 24),

          _construirTituloSeccion(
            'Identificación del peligro',
            Icons.warning_amber_rounded,
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            initialValue: _valorPeligroValido(catalogos),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Peligro identificado *',
              prefixIcon: Icon(Icons.warning_outlined),
              border: OutlineInputBorder(),
            ),
            items: catalogos.peligros.map((PeligroModel peligro) {
              return DropdownMenuItem<int>(
                value: peligro.id,
                child: Text(
                  peligro.nombreCompleto,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: guardando
                ? null
                : (int? value) {
                    setState(() {
                      _peligroIdSeleccionado = value;
                    });
                  },
            validator: _validarPeligro,
          ),

          if (_peligroIdSeleccionado != null) ...<Widget>[
            const SizedBox(height: 8),
            _construirDescripcionPeligro(catalogos),
          ],

          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            initialValue: _valorConsecuenciaValido(catalogos),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Consecuencia posible *',
              prefixIcon: Icon(Icons.report_problem_outlined),
              border: OutlineInputBorder(),
            ),
            items: catalogos.consecuencias.map((
              ConsecuenciaModel consecuencia,
            ) {
              return DropdownMenuItem<int>(
                value: consecuencia.id,
                child: Text(
                  consecuencia.nombreCompleto,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: guardando
                ? null
                : (int? value) {
                    setState(() {
                      _consecuenciaIdSeleccionada = value;
                    });
                  },
            validator: _validarConsecuencia,
          ),

          if (_consecuenciaIdSeleccionada != null) ...<Widget>[
            const SizedBox(height: 8),
            _construirDescripcionConsecuencia(catalogos),
          ],

          const SizedBox(height: 24),

          _construirTituloSeccion(
            'Evaluación inicial 5 × 5',
            Icons.grid_view_rounded,
          ),

          const SizedBox(height: 12),

          _construirSelectorValor(
            titulo: 'Severidad',
            valor: _severidadInicial,
            habilitado: !guardando,
            onChanged: (int valor) {
              setState(() {
                _severidadInicial = valor;
              });
            },
          ),

          const SizedBox(height: 12),

          _construirSelectorValor(
            titulo: 'Frecuencia o probabilidad',
            valor: _frecuenciaInicial,
            habilitado: !guardando,
            onChanged: (int valor) {
              setState(() {
                _frecuenciaInicial = valor;
              });
            },
          ),

          const SizedBox(height: 12),

          _construirResultadoRiesgo(
            titulo: 'Riesgo inicial',
            valor: _valorRiesgoInicial,
          ),

          const SizedBox(height: 24),

          _construirTituloSeccion(
            'Medidas de control',
            Icons.health_and_safety_outlined,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _controlController,
            enabled: !guardando,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Controles por implementar',
              hintText: 'Describa los controles necesarios',
              prefixIcon: Icon(Icons.security_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Registrar riesgo residual'),
            subtitle: const Text(
              'Evaluar el riesgo después de aplicar los controles.',
            ),
            value: _registrarEvaluacionResidual,
            onChanged: guardando
                ? null
                : (bool value) {
                    setState(() {
                      _registrarEvaluacionResidual = value;

                      if (value) {
                        _severidadResidual ??= 1;
                        _frecuenciaResidual ??= 1;
                      } else {
                        _severidadResidual = null;
                        _frecuenciaResidual = null;
                      }
                    });
                  },
          ),

          if (_registrarEvaluacionResidual) ...<Widget>[
            const SizedBox(height: 12),

            _construirSelectorValor(
              titulo: 'Severidad residual',
              valor: _severidadResidual ?? 1,
              habilitado: !guardando,
              onChanged: (int valor) {
                setState(() {
                  _severidadResidual = valor;
                });
              },
            ),

            const SizedBox(height: 12),

            _construirSelectorValor(
              titulo: 'Frecuencia residual',
              valor: _frecuenciaResidual ?? 1,
              habilitado: !guardando,
              onChanged: (int valor) {
                setState(() {
                  _frecuenciaResidual = valor;
                });
              },
            ),

            const SizedBox(height: 12),

            _construirResultadoRiesgo(
              titulo: 'Riesgo residual',
              valor: _valorRiesgoResidual ?? 1,
            ),
          ],

          const SizedBox(height: 24),

          _construirTituloSeccion('Implementación', Icons.engineering_outlined),

          const SizedBox(height: 12),

          TextFormField(
            controller: _responsableController,
            enabled: !guardando,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID del responsable',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _estadoImplementacion,
            decoration: const InputDecoration(
              labelText: 'Estado de implementación',
              prefixIcon: Icon(Icons.check_circle_outline),
              border: OutlineInputBorder(),
            ),
            items: _estadosImplementacion.map((String estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(estado.replaceAll('_', ' ')),
              );
            }).toList(),
            onChanged: guardando
                ? null
                : (String? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _estadoImplementacion = value;
                    });
                  },
          ),

          const SizedBox(height: 12),

          _construirSelectorFecha(
            titulo: 'Fecha de compromiso',
            fecha: _fechaCompromiso,
            icono: Icons.event_outlined,
            habilitado: !guardando,
            onPressed: _seleccionarFechaCompromiso,
            onLimpiar: () {
              setState(() {
                _fechaCompromiso = null;
              });
            },
          ),

          const SizedBox(height: 12),

          _construirSelectorFecha(
            titulo: 'Fecha de implementación',
            fecha: _fechaImplementacion,
            icono: Icons.event_available,
            habilitado: !guardando,
            onPressed: _seleccionarFechaImplementacion,
            onLimpiar: () {
              setState(() {
                _fechaImplementacion = null;
              });
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _observacionesController,
            enabled: !guardando,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: guardando || !catalogos.tieneCatalogos ? null : _guardar,
            icon: guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              guardando
                  ? 'Guardando...'
                  : widget.esEdicion
                  ? 'Actualizar detalle'
                  : 'Guardar detalle',
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  int? _valorPeligroValido(DetalleIpercCatalogosProvider catalogos) {
    final bool existe = catalogos.peligros.any(
      (PeligroModel peligro) => peligro.id == _peligroIdSeleccionado,
    );

    return existe ? _peligroIdSeleccionado : null;
  }

  int? _valorConsecuenciaValido(DetalleIpercCatalogosProvider catalogos) {
    final bool existe = catalogos.consecuencias.any(
      (ConsecuenciaModel consecuencia) =>
          consecuencia.id == _consecuenciaIdSeleccionada,
    );

    return existe ? _consecuenciaIdSeleccionada : null;
  }

  Widget _construirDescripcionPeligro(DetalleIpercCatalogosProvider catalogos) {
    final PeligroModel? peligro = catalogos.buscarPeligroPorId(
      _peligroIdSeleccionado,
    );

    if (peligro == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${peligro.tipoVisible} · ${peligro.categoriaVisible}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _construirDescripcionConsecuencia(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    final ConsecuenciaModel? consecuencia = catalogos.buscarConsecuenciaPorId(
      _consecuenciaIdSeleccionada,
    );

    if (consecuencia == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${consecuencia.clasificacionVisible} · '
      '${consecuencia.gravedadVisible}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _construirErrorCatalogos(DetalleIpercCatalogosProvider catalogos) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              catalogos.error ?? 'No se pudieron cargar los catálogos.',
            ),
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: catalogos.recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _construirAvisoOffline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'El detalle se guardará localmente y se sincronizará cuando exista conexión con el servidor.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTituloSeccion(String titulo, IconData icono) {
    return Row(
      children: <Widget>[
        Icon(icono, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _construirSelectorValor({
    required String titulo,
    required int valor,
    required bool habilitado,
    required ValueChanged<int> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List<Widget>.generate(5, (int index) {
          final int opcion = index + 1;

          return ChoiceChip(
            label: Text(opcion.toString()),
            selected: valor == opcion,
            onSelected: habilitado
                ? (bool selected) {
                    if (selected) {
                      onChanged(opcion);
                    }
                  }
                : null,
          );
        }),
      ),
    );
  }

  Widget _construirResultadoRiesgo({
    required String titulo,
    required int valor,
  }) {
    final String nivel = _obtenerNivelRiesgo(valor);
    final Color color = _obtenerColorRiesgo(valor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.shield_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$titulo: $valor - $nivel',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorFecha({
    required String titulo,
    required DateTime? fecha,
    required IconData icono,
    required bool habilitado,
    required VoidCallback onPressed,
    required VoidCallback onLimpiar,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(_formatearFecha(fecha))),
          if (fecha != null)
            IconButton(
              tooltip: 'Limpiar fecha',
              onPressed: habilitado ? onLimpiar : null,
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            tooltip: 'Seleccionar fecha',
            onPressed: habilitado ? onPressed : null,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
    );
  }

  Widget _construirAdvertenciaCatalogos(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.storage_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              catalogos.advertencia ?? 'Se están utilizando catálogos locales.',
            ),
          ),
        ],
      ),
    );
  }
}
