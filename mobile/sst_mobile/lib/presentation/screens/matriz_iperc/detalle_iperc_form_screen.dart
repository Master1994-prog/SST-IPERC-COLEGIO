import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/peligro_model.dart';
import '../../../data/models/probabilidad_model.dart';
import '../../../data/models/severidad_model.dart';
import '../../providers/detalle_iperc_catalogos_provider.dart';
import '../../providers/detalle_iperc_offline_provider.dart';

/// ===============================================================
/// FORMULARIO OFFLINE - DETALLE IPERC
/// ===============================================================
///
/// Permite registrar o editar un detalle IPERC.
///
/// El registro se almacena primero en SQLite.
///
/// Para la evaluación de riesgos guarda por separado:
///
/// - ID real de Probabilidad.
/// - Valor de Probabilidad 1..5.
/// - ID real de Severidad.
/// - Valor de Severidad 1..5.
///
/// Esto permite sincronizar correctamente aunque el ID del catálogo
/// sea distinto del valor utilizado en la matriz 5x5.
/// ===============================================================
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

  /// Número sugerido para un nuevo detalle.
  final int? siguienteItem;

  /// Detalle que se editará.
  final DetalleIpercLocalModel? detalle;

  bool get esEdicion => detalle != null;

  @override
  State<DetalleIpercFormScreen> createState() {
    return _DetalleIpercFormScreenState();
  }
}

class _DetalleIpercFormScreenState extends State<DetalleIpercFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // =============================================================
  // CONTROLADORES
  // =============================================================

  late final TextEditingController _itemController;
  late final TextEditingController _tareaController;
  late final TextEditingController _actividadController;
  late final TextEditingController _controlController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _responsableController;

  // =============================================================
  // PELIGRO / CONSECUENCIA
  // =============================================================

  int? _peligroIdSeleccionado;
  int? _consecuenciaIdSeleccionada;

  // =============================================================
  // EVALUACIÓN INICIAL
  // =============================================================

  /// ID real del catálogo Probabilidades.
  int? _probabilidadInicialId;

  /// ID real del catálogo Severidades.
  int? _severidadInicialId;

  /// Valor 1..5.
  int _frecuenciaInicial = 1;

  /// Valor 1..5.
  int _severidadInicial = 1;

  // =============================================================
  // EVALUACIÓN RESIDUAL
  // =============================================================

  int? _probabilidadResidualId;
  int? _severidadResidualId;

  int? _frecuenciaResidual;
  int? _severidadResidual;

  bool _registrarEvaluacionResidual = false;

  // =============================================================
  // IMPLEMENTACIÓN
  // =============================================================

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

  // =============================================================
  // INIT
  // =============================================================

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
      // ---------------------------------------------------------
      // EVALUACIÓN INICIAL
      // ---------------------------------------------------------

      _probabilidadInicialId = detalle.probabilidadInicialId;

      _severidadInicialId = detalle.severidadInicialId;

      _frecuenciaInicial = detalle.frecuenciaInicial;

      _severidadInicial = detalle.severidadInicial;

      // ---------------------------------------------------------
      // EVALUACIÓN RESIDUAL
      // ---------------------------------------------------------

      _probabilidadResidualId = detalle.probabilidadResidualId;

      _severidadResidualId = detalle.severidadResidualId;

      _frecuenciaResidual = detalle.frecuenciaResidual;

      _severidadResidual = detalle.severidadResidual;

      _registrarEvaluacionResidual =
          detalle.frecuenciaResidual != null &&
          detalle.severidadResidual != null;

      // ---------------------------------------------------------
      // IMPLEMENTACIÓN
      // ---------------------------------------------------------

      _fechaCompromiso = detalle.fechaCompromiso;

      _fechaImplementacion = detalle.fechaImplementacion;

      _estadoImplementacion = detalle.estadoImplementacion ?? 'PENDIENTE';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCatalogos();
    });
  }

  // =============================================================
  // DISPOSE
  // =============================================================

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

  // =============================================================
  // CARGAR CATÁLOGOS
  // =============================================================

  Future<void> _cargarCatalogos() async {
    final DetalleIpercCatalogosProvider catalogos = context
        .read<DetalleIpercCatalogosProvider>();

    await catalogos.cargar();

    if (!mounted) {
      return;
    }

    // -----------------------------------------------------------
    // COMPATIBILIDAD CON REGISTROS ANTIGUOS
    // -----------------------------------------------------------
    //
    // Si el registro antiguo todavía no tiene un ID real válido,
    // buscamos el catálogo mediante su valor 1..5.

    _resolverEvaluacionesDesdeCatalogos(catalogos);

    setState(() {});
  }

  // =============================================================
  // RESOLVER IDS DE CATÁLOGOS
  // =============================================================

  void _resolverEvaluacionesDesdeCatalogos(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    // -----------------------------------------------------------
    // PROBABILIDAD INICIAL
    // -----------------------------------------------------------

    final ProbabilidadModel? probabilidadInicialPorId = catalogos
        .buscarProbabilidadPorId(_probabilidadInicialId);

    if (probabilidadInicialPorId != null) {
      _probabilidadInicialId = probabilidadInicialPorId.id;

      _frecuenciaInicial = probabilidadInicialPorId.valor;
    } else {
      final ProbabilidadModel? porValor = catalogos.buscarProbabilidadPorValor(
        _frecuenciaInicial,
      );

      if (porValor != null) {
        _probabilidadInicialId = porValor.id;

        _frecuenciaInicial = porValor.valor;
      }
    }

    // -----------------------------------------------------------
    // SEVERIDAD INICIAL
    // -----------------------------------------------------------

    final SeveridadModel? severidadInicialPorId = catalogos
        .buscarSeveridadPorId(_severidadInicialId);

    if (severidadInicialPorId != null) {
      _severidadInicialId = severidadInicialPorId.id;

      _severidadInicial = severidadInicialPorId.valor;
    } else {
      final SeveridadModel? porValor = catalogos.buscarSeveridadPorValor(
        _severidadInicial,
      );

      if (porValor != null) {
        _severidadInicialId = porValor.id;

        _severidadInicial = porValor.valor;
      }
    }

    // -----------------------------------------------------------
    // RESIDUAL
    // -----------------------------------------------------------

    if (!_registrarEvaluacionResidual) {
      return;
    }

    if (_frecuenciaResidual != null) {
      final ProbabilidadModel? porId = catalogos.buscarProbabilidadPorId(
        _probabilidadResidualId,
      );

      if (porId != null) {
        _probabilidadResidualId = porId.id;

        _frecuenciaResidual = porId.valor;
      } else {
        final ProbabilidadModel? porValor = catalogos
            .buscarProbabilidadPorValor(_frecuenciaResidual!);

        if (porValor != null) {
          _probabilidadResidualId = porValor.id;

          _frecuenciaResidual = porValor.valor;
        }
      }
    }

    if (_severidadResidual != null) {
      final SeveridadModel? porId = catalogos.buscarSeveridadPorId(
        _severidadResidualId,
      );

      if (porId != null) {
        _severidadResidualId = porId.id;

        _severidadResidual = porId.valor;
      } else {
        final SeveridadModel? porValor = catalogos.buscarSeveridadPorValor(
          _severidadResidual!,
        );

        if (porValor != null) {
          _severidadResidualId = porValor.id;

          _severidadResidual = porValor.valor;
        }
      }
    }
  }

  // =============================================================
  // CÁLCULO INICIAL
  // =============================================================

  int get _valorRiesgoInicial {
    return _severidadInicial * _frecuenciaInicial;
  }

  // =============================================================
  // CÁLCULO RESIDUAL
  // =============================================================

  int? get _valorRiesgoResidual {
    if (!_registrarEvaluacionResidual ||
        _severidadResidual == null ||
        _frecuenciaResidual == null) {
      return null;
    }

    return _severidadResidual! * _frecuenciaResidual!;
  }

  // =============================================================
  // NIVEL DE RIESGO
  // =============================================================

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

  // =============================================================
  // COLOR DE RIESGO
  // =============================================================

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

  // =============================================================
  // ID LOCAL
  // =============================================================

  String _crearIdLocal() {
    return 'DET-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }

  // =============================================================
  // VALIDACIONES
  // =============================================================

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

  String? _validarProbabilidad(int? value) {
    if (value == null || value <= 0) {
      return 'Seleccione la probabilidad.';
    }

    return null;
  }

  String? _validarSeveridad(int? value) {
    if (value == null || value <= 0) {
      return 'Seleccione la severidad.';
    }

    return null;
  }

  String? _textoOpcional(String value) {
    final String texto = value.trim();

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // FECHA COMPROMISO
  // =============================================================

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

  // =============================================================
  // FECHA IMPLEMENTACIÓN
  // =============================================================

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

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final DetalleIpercCatalogosProvider catalogos = context
        .read<DetalleIpercCatalogosProvider>();

    // -----------------------------------------------------------
    // VALIDAR PELIGRO Y CONSECUENCIA
    // -----------------------------------------------------------

    if (_peligroIdSeleccionado == null || _consecuenciaIdSeleccionada == null) {
      _mostrarMensaje(
        'Seleccione el peligro y la consecuencia.',
        esError: true,
      );

      return;
    }

    // -----------------------------------------------------------
    // VALIDAR EVALUACIÓN INICIAL
    // -----------------------------------------------------------

    if (_probabilidadInicialId == null || _severidadInicialId == null) {
      _mostrarMensaje(
        'Seleccione la probabilidad y la severidad inicial.',
        esError: true,
      );

      return;
    }

    // -----------------------------------------------------------
    // VALIDAR RESIDUAL
    // -----------------------------------------------------------

    if (_registrarEvaluacionResidual &&
        (_probabilidadResidualId == null ||
            _severidadResidualId == null ||
            _frecuenciaResidual == null ||
            _severidadResidual == null)) {
      _mostrarMensaje(
        'Complete la probabilidad y la severidad residual.',
        esError: true,
      );

      return;
    }

    // -----------------------------------------------------------
    // OBTENER OBJETOS DE CATÁLOGO
    // -----------------------------------------------------------

    final PeligroModel? peligro = catalogos.buscarPeligroPorId(
      _peligroIdSeleccionado,
    );

    final ConsecuenciaModel? consecuencia = catalogos.buscarConsecuenciaPorId(
      _consecuenciaIdSeleccionada,
    );

    final ProbabilidadModel? probabilidadInicial = catalogos
        .buscarProbabilidadPorId(_probabilidadInicialId);

    final SeveridadModel? severidadInicial = catalogos.buscarSeveridadPorId(
      _severidadInicialId,
    );

    if (peligro == null ||
        consecuencia == null ||
        probabilidadInicial == null ||
        severidadInicial == null) {
      _mostrarMensaje(
        'No se pudo obtener toda la información de los catálogos IPERC.',
        esError: true,
      );

      return;
    }

    ProbabilidadModel? probabilidadResidual;
    SeveridadModel? severidadResidual;

    if (_registrarEvaluacionResidual) {
      probabilidadResidual = catalogos.buscarProbabilidadPorId(
        _probabilidadResidualId,
      );

      severidadResidual = catalogos.buscarSeveridadPorId(_severidadResidualId);

      if (probabilidadResidual == null || severidadResidual == null) {
        _mostrarMensaje(
          'No se pudo obtener la evaluación residual seleccionada.',
          esError: true,
        );

        return;
      }
    }

    // -----------------------------------------------------------
    // ACTUALIZAR VALORES DESDE LOS CATÁLOGOS
    // -----------------------------------------------------------

    _frecuenciaInicial = probabilidadInicial.valor;

    _severidadInicial = severidadInicial.valor;

    if (_registrarEvaluacionResidual) {
      _frecuenciaResidual = probabilidadResidual!.valor;

      _severidadResidual = severidadResidual!.valor;
    }

    final DetalleIpercOfflineProvider provider = context
        .read<DetalleIpercOfflineProvider>();

    final DateTime ahora = DateTime.now().toUtc();

    final DetalleIpercLocalModel? anterior = widget.detalle;

    final int? valorResidual = _valorRiesgoResidual;

    // ===========================================================
    // CREAR MODELO LOCAL
    // ===========================================================

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

      // =========================================================
      // EVALUACIÓN INICIAL
      // =========================================================
      evaluacionInicialId: anterior?.evaluacionInicialId,

      /// ID REAL DEL CATÁLOGO.
      probabilidadInicialId: probabilidadInicial.id,

      /// ID REAL DEL CATÁLOGO.
      severidadInicialId: severidadInicial.id,

      /// VALORES 1..5.
      frecuenciaInicial: probabilidadInicial.valor,

      severidadInicial: severidadInicial.valor,

      valorRiesgoInicial: probabilidadInicial.valor * severidadInicial.valor,

      nivelRiesgoInicial: _obtenerNivelRiesgo(
        probabilidadInicial.valor * severidadInicial.valor,
      ),

      // =========================================================
      // CONTROLES / EPP
      // =========================================================
      controlIds: anterior?.controlIds ?? const <String>[],

      equipoProteccionIds: anterior?.equipoProteccionIds ?? const <String>[],

      controlDescripcion: _textoOpcional(_controlController.text),

      // =========================================================
      // EVALUACIÓN RESIDUAL
      // =========================================================
      evaluacionResidualId: anterior?.evaluacionResidualId,

      probabilidadResidualId: _registrarEvaluacionResidual
          ? probabilidadResidual!.id
          : null,

      severidadResidualId: _registrarEvaluacionResidual
          ? severidadResidual!.id
          : null,

      frecuenciaResidual: _registrarEvaluacionResidual
          ? probabilidadResidual!.valor
          : null,

      severidadResidual: _registrarEvaluacionResidual
          ? severidadResidual!.valor
          : null,

      valorRiesgoResidual: valorResidual,

      nivelRiesgoResidual: valorResidual == null
          ? null
          : _obtenerNivelRiesgo(valorResidual),

      // =========================================================
      // IMPLEMENTACIÓN
      // =========================================================
      responsableImplementacionId: _textoOpcional(_responsableController.text),

      fechaCompromiso: _fechaCompromiso,

      fechaImplementacion: _fechaImplementacion,

      estadoImplementacion: _estadoImplementacion,

      observaciones: _textoOpcional(_observacionesController.text),

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      sincronizado: false,

      eliminado: false,

      fechaRegistro: anterior?.fechaRegistro ?? ahora,

      fechaActualizacion: widget.esEdicion ? ahora : null,

      fechaSincronizacion: anterior?.fechaSincronizacion,
    );

    // ===========================================================
    // GUARDAR SQLITE
    // ===========================================================

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

  // =============================================================
  // MENSAJE
  // =============================================================

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

  // =============================================================
  // BUILD
  // =============================================================

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
                : () async {
                    await catalogos.recargar();

                    if (!mounted) {
                      return;
                    }

                    _resolverEvaluacionesDesdeCatalogos(catalogos);

                    setState(() {});
                  },

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

  // =============================================================
  // FORMULARIO
  // =============================================================

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

          // =====================================================
          // INFORMACIÓN DE LA TAREA
          // =====================================================
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

          // =====================================================
          // PELIGRO
          // =====================================================
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

          // =====================================================
          // CONSECUENCIA
          // =====================================================
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

          // =====================================================
          // EVALUACIÓN INICIAL
          // =====================================================
          _construirTituloSeccion(
            'Evaluación inicial 5 × 5',
            Icons.grid_view_rounded,
          ),

          const SizedBox(height: 12),

          // -----------------------------------------------------
          // PROBABILIDAD INICIAL
          // -----------------------------------------------------
          DropdownButtonFormField<int>(
            initialValue: _valorProbabilidadInicialValido(catalogos),

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Probabilidad *',
              prefixIcon: Icon(Icons.trending_up),
              border: OutlineInputBorder(),
            ),

            items: catalogos.probabilidades.map((ProbabilidadModel item) {
              return DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.textoSeleccion),
              );
            }).toList(),

            onChanged: guardando
                ? null
                : (int? id) {
                    if (id == null) {
                      return;
                    }

                    final ProbabilidadModel? item = catalogos
                        .buscarProbabilidadPorId(id);

                    if (item == null) {
                      return;
                    }

                    setState(() {
                      _probabilidadInicialId = item.id;

                      _frecuenciaInicial = item.valor;
                    });
                  },

            validator: _validarProbabilidad,
          ),

          const SizedBox(height: 12),

          // -----------------------------------------------------
          // SEVERIDAD INICIAL
          // -----------------------------------------------------
          DropdownButtonFormField<int>(
            initialValue: _valorSeveridadInicialValido(catalogos),

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Severidad *',
              prefixIcon: Icon(Icons.priority_high),
              border: OutlineInputBorder(),
            ),

            items: catalogos.severidades.map((SeveridadModel item) {
              return DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.textoSeleccion),
              );
            }).toList(),

            onChanged: guardando
                ? null
                : (int? id) {
                    if (id == null) {
                      return;
                    }

                    final SeveridadModel? item = catalogos.buscarSeveridadPorId(
                      id,
                    );

                    if (item == null) {
                      return;
                    }

                    setState(() {
                      _severidadInicialId = item.id;

                      _severidadInicial = item.valor;
                    });
                  },

            validator: _validarSeveridad,
          ),

          if (_probabilidadInicialId != null &&
              _severidadInicialId != null) ...<Widget>[
            const SizedBox(height: 12),

            _construirResultadoRiesgo(
              titulo: 'Riesgo inicial',
              valor: _valorRiesgoInicial,
            ),
          ],

          const SizedBox(height: 24),

          // =====================================================
          // CONTROLES
          // =====================================================
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

          // =====================================================
          // ACTIVAR RESIDUAL
          // =====================================================
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
                        final ProbabilidadModel? primeraProbabilidad =
                            catalogos.probabilidades.isNotEmpty
                            ? catalogos.probabilidades.first
                            : null;

                        final SeveridadModel? primeraSeveridad =
                            catalogos.severidades.isNotEmpty
                            ? catalogos.severidades.first
                            : null;

                        if (_probabilidadResidualId == null &&
                            primeraProbabilidad != null) {
                          _probabilidadResidualId = primeraProbabilidad.id;

                          _frecuenciaResidual = primeraProbabilidad.valor;
                        }

                        if (_severidadResidualId == null &&
                            primeraSeveridad != null) {
                          _severidadResidualId = primeraSeveridad.id;

                          _severidadResidual = primeraSeveridad.valor;
                        }
                      } else {
                        _probabilidadResidualId = null;

                        _severidadResidualId = null;

                        _frecuenciaResidual = null;

                        _severidadResidual = null;
                      }
                    });
                  },
          ),

          // =====================================================
          // RESIDUAL
          // =====================================================
          if (_registrarEvaluacionResidual) ...<Widget>[
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: _valorProbabilidadResidualValido(catalogos),

              isExpanded: true,

              decoration: const InputDecoration(
                labelText: 'Probabilidad residual *',
                prefixIcon: Icon(Icons.trending_down),
                border: OutlineInputBorder(),
              ),

              items: catalogos.probabilidades.map((ProbabilidadModel item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.textoSeleccion),
                );
              }).toList(),

              onChanged: guardando
                  ? null
                  : (int? id) {
                      if (id == null) {
                        return;
                      }

                      final ProbabilidadModel? item = catalogos
                          .buscarProbabilidadPorId(id);

                      if (item == null) {
                        return;
                      }

                      setState(() {
                        _probabilidadResidualId = item.id;

                        _frecuenciaResidual = item.valor;
                      });
                    },

              validator: _registrarEvaluacionResidual
                  ? _validarProbabilidad
                  : null,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: _valorSeveridadResidualValido(catalogos),

              isExpanded: true,

              decoration: const InputDecoration(
                labelText: 'Severidad residual *',
                prefixIcon: Icon(Icons.priority_high),
                border: OutlineInputBorder(),
              ),

              items: catalogos.severidades.map((SeveridadModel item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.textoSeleccion),
                );
              }).toList(),

              onChanged: guardando
                  ? null
                  : (int? id) {
                      if (id == null) {
                        return;
                      }

                      final SeveridadModel? item = catalogos
                          .buscarSeveridadPorId(id);

                      if (item == null) {
                        return;
                      }

                      setState(() {
                        _severidadResidualId = item.id;

                        _severidadResidual = item.valor;
                      });
                    },

              validator: _registrarEvaluacionResidual
                  ? _validarSeveridad
                  : null,
            ),

            if (_valorRiesgoResidual != null) ...<Widget>[
              const SizedBox(height: 12),

              _construirResultadoRiesgo(
                titulo: 'Riesgo residual',
                valor: _valorRiesgoResidual!,
              ),
            ],
          ],

          const SizedBox(height: 24),

          // =====================================================
          // IMPLEMENTACIÓN
          // =====================================================
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

          // =====================================================
          // GUARDAR
          // =====================================================
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

  // =============================================================
  // VALORES VÁLIDOS PARA DROPDOWN
  // =============================================================

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

  int? _valorProbabilidadInicialValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    final bool existe = catalogos.probabilidades.any(
      (ProbabilidadModel item) => item.id == _probabilidadInicialId,
    );

    return existe ? _probabilidadInicialId : null;
  }

  int? _valorSeveridadInicialValido(DetalleIpercCatalogosProvider catalogos) {
    final bool existe = catalogos.severidades.any(
      (SeveridadModel item) => item.id == _severidadInicialId,
    );

    return existe ? _severidadInicialId : null;
  }

  int? _valorProbabilidadResidualValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    final bool existe = catalogos.probabilidades.any(
      (ProbabilidadModel item) => item.id == _probabilidadResidualId,
    );

    return existe ? _probabilidadResidualId : null;
  }

  int? _valorSeveridadResidualValido(DetalleIpercCatalogosProvider catalogos) {
    final bool existe = catalogos.severidades.any(
      (SeveridadModel item) => item.id == _severidadResidualId,
    );

    return existe ? _severidadResidualId : null;
  }

  // =============================================================
  // DESCRIPCIÓN PELIGRO
  // =============================================================

  Widget _construirDescripcionPeligro(DetalleIpercCatalogosProvider catalogos) {
    final PeligroModel? peligro = catalogos.buscarPeligroPorId(
      _peligroIdSeleccionado,
    );

    if (peligro == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${peligro.tipoVisible} · '
      '${peligro.categoriaVisible}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  // =============================================================
  // DESCRIPCIÓN CONSECUENCIA
  // =============================================================

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

  // =============================================================
  // ERROR CATÁLOGOS
  // =============================================================

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
            onPressed: () async {
              await catalogos.recargar();

              if (!mounted) {
                return;
              }

              _resolverEvaluacionesDesdeCatalogos(catalogos);

              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // AVISO OFFLINE
  // =============================================================

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
              'El detalle se guardará localmente y se sincronizará '
              'cuando exista conexión con el servidor.',
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TÍTULO SECCIÓN
  // =============================================================

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

  // =============================================================
  // RESULTADO RIESGO
  // =============================================================

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

  // =============================================================
  // SELECTOR FECHA
  // =============================================================

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

  // =============================================================
  // ADVERTENCIA CATÁLOGOS
  // =============================================================

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
