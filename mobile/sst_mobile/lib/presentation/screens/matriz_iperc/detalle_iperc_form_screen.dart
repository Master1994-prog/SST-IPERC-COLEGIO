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
/// Permite crear y editar un Detalle IPERC en SQLite.
///
/// Mantiene separados:
///
/// - ID real de Probabilidad en MySQL.
/// - Valor de Probabilidad 1..5.
/// - ID real de Severidad en MySQL.
/// - Valor de Severidad 1..5.
///
/// Esto permite que la matriz 5x5 se calcule con los valores 1..5
/// sin confundirlos con los identificadores reales del backend.
/// ===============================================================
class DetalleIpercFormScreen extends StatefulWidget {
  const DetalleIpercFormScreen({
    super.key,
    required this.matrizIdLocal,
    this.matrizIdServidor,
    this.siguienteItem,
    this.detalle,
  });

  final String matrizIdLocal;
  final int? matrizIdServidor;
  final int? siguienteItem;
  final DetalleIpercLocalModel? detalle;

  bool get esEdicion => detalle != null;

  @override
  State<DetalleIpercFormScreen> createState() =>
      _DetalleIpercFormScreenState();
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

  int? _probabilidadInicialId;
  int? _severidadInicialId;

  int _probabilidadInicialValor = 1;
  int _severidadInicialValor = 1;

  bool _registrarEvaluacionResidual = false;

  int? _probabilidadResidualId;
  int? _severidadResidualId;

  int? _probabilidadResidualValor;
  int? _severidadResidualValor;

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

    _peligroIdSeleccionado =
        int.tryParse(detalle?.peligroId?.trim() ?? '');

    _consecuenciaIdSeleccionada =
        int.tryParse(detalle?.consecuenciaId?.trim() ?? '');

    if (detalle != null) {
      _probabilidadInicialId = detalle.probabilidadInicialId;
      _severidadInicialId = detalle.severidadInicialId;

      _probabilidadInicialValor = detalle.frecuenciaInicial;
      _severidadInicialValor = detalle.severidadInicial;

      _probabilidadResidualId = detalle.probabilidadResidualId;
      _severidadResidualId = detalle.severidadResidualId;

      _probabilidadResidualValor = detalle.frecuenciaResidual;
      _severidadResidualValor = detalle.severidadResidual;

      _registrarEvaluacionResidual =
          detalle.frecuenciaResidual != null &&
          detalle.severidadResidual != null;

      _fechaCompromiso = detalle.fechaCompromiso;
      _fechaImplementacion = detalle.fechaImplementacion;

      final String estado = detalle.estadoImplementacion?.trim() ?? '';

      if (_estadosImplementacion.contains(estado)) {
        _estadoImplementacion = estado;
      }
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
    final DetalleIpercCatalogosProvider catalogos =
        context.read<DetalleIpercCatalogosProvider>();

    await catalogos.cargar();

    if (!mounted) {
      return;
    }

    _resolverIdsCatalogo(catalogos);

    setState(() {});
  }

  void _resolverIdsCatalogo(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    // ===========================================================
    // PROBABILIDAD INICIAL
    // ===========================================================
    //
    // Compatibilidad con registros antiguos:
    // un valor IPERC 1..5 pudo quedar guardado por error dentro
    // del campo destinado al ID real del catálogo.
    //
    // Por eso un ID solo se considera confiable si el catálogo
    // encontrado por ese ID tiene también el mismo valor 1..5
    // que estaba almacenado localmente.

    final ProbabilidadModel? probabilidadPorId =
        catalogos.buscarProbabilidadPorId(_probabilidadInicialId);

    final bool probabilidadIdConfiable =
        probabilidadPorId != null &&
        probabilidadPorId.valor == _probabilidadInicialValor;

    if (probabilidadIdConfiable) {
      _probabilidadInicialId = probabilidadPorId.id;
      _probabilidadInicialValor = probabilidadPorId.valor;
    } else {
      final ProbabilidadModel? porValor =
          catalogos.buscarProbabilidadPorValor(_probabilidadInicialValor);

      if (porValor != null) {
        _probabilidadInicialId = porValor.id;
        _probabilidadInicialValor = porValor.valor;
      } else {
        _probabilidadInicialId = null;
      }
    }

    // ===========================================================
    // SEVERIDAD INICIAL
    // ===========================================================

    final SeveridadModel? severidadPorId =
        catalogos.buscarSeveridadPorId(_severidadInicialId);

    final bool severidadIdConfiable =
        severidadPorId != null &&
        severidadPorId.valor == _severidadInicialValor;

    if (severidadIdConfiable) {
      _severidadInicialId = severidadPorId.id;
      _severidadInicialValor = severidadPorId.valor;
    } else {
      final SeveridadModel? porValor =
          catalogos.buscarSeveridadPorValor(_severidadInicialValor);

      if (porValor != null) {
        _severidadInicialId = porValor.id;
        _severidadInicialValor = porValor.valor;
      } else {
        _severidadInicialId = null;
      }
    }

    // ===========================================================
    // SIN EVALUACIÓN RESIDUAL
    // ===========================================================

    if (!_registrarEvaluacionResidual) {
      _probabilidadResidualId = null;
      _severidadResidualId = null;
      return;
    }

    // ===========================================================
    // PROBABILIDAD RESIDUAL
    // ===========================================================

    if (_probabilidadResidualValor != null) {
      final ProbabilidadModel? residualPorId =
          catalogos.buscarProbabilidadPorId(_probabilidadResidualId);

      final bool residualIdConfiable =
          residualPorId != null &&
          residualPorId.valor == _probabilidadResidualValor;

      if (residualIdConfiable) {
        _probabilidadResidualId = residualPorId.id;
        _probabilidadResidualValor = residualPorId.valor;
      } else {
        final ProbabilidadModel? porValor =
            catalogos.buscarProbabilidadPorValor(
          _probabilidadResidualValor!,
        );

        if (porValor != null) {
          _probabilidadResidualId = porValor.id;
          _probabilidadResidualValor = porValor.valor;
        } else {
          _probabilidadResidualId = null;
        }
      }
    } else {
      _probabilidadResidualId = null;
    }

    // ===========================================================
    // SEVERIDAD RESIDUAL
    // ===========================================================

    if (_severidadResidualValor != null) {
      final SeveridadModel? residualPorId =
          catalogos.buscarSeveridadPorId(_severidadResidualId);

      final bool residualIdConfiable =
          residualPorId != null &&
          residualPorId.valor == _severidadResidualValor;

      if (residualIdConfiable) {
        _severidadResidualId = residualPorId.id;
        _severidadResidualValor = residualPorId.valor;
      } else {
        final SeveridadModel? porValor =
            catalogos.buscarSeveridadPorValor(_severidadResidualValor!);

        if (porValor != null) {
          _severidadResidualId = porValor.id;
          _severidadResidualValor = porValor.valor;
        } else {
          _severidadResidualId = null;
        }
      }
    } else {
      _severidadResidualId = null;
    }
  }

  int get _valorRiesgoInicial =>
      _probabilidadInicialValor * _severidadInicialValor;

  int? get _valorRiesgoResidual {
    if (!_registrarEvaluacionResidual ||
        _probabilidadResidualValor == null ||
        _severidadResidualValor == null) {
      return null;
    }

    return _probabilidadResidualValor! * _severidadResidualValor!;
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

  String? _validarTextoObligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validarItem(String? value) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El número de ítem es obligatorio.';
    }

    final int? item = int.tryParse(texto);

    if (item == null || item <= 0) {
      return 'Ingrese un número de ítem válido.';
    }

    return null;
  }

  String? _validarIdSeleccionado(int? value, String nombre) {
    if (value == null || value <= 0) {
      return 'Seleccione $nombre.';
    }

    return null;
  }

  String? _validarResponsable(String? value) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      return 'Ingrese un ID de responsable válido.';
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

    final String matrizIdLocal = widget.matrizIdLocal.trim();

    if (matrizIdLocal.isEmpty) {
      _mostrarMensaje(
        'No se encontró el identificador local de la matriz.',
        esError: true,
      );
      return;
    }

    if (widget.matrizIdServidor != null && widget.matrizIdServidor! <= 0) {
      _mostrarMensaje(
        'El identificador de la matriz en el servidor no es válido.',
        esError: true,
      );
      return;
    }

    final DetalleIpercCatalogosProvider catalogos =
        context.read<DetalleIpercCatalogosProvider>();

    if (!catalogos.tieneCatalogos) {
      _mostrarMensaje(
        'Los catálogos IPERC no están disponibles.',
        esError: true,
      );
      return;
    }

    if (_peligroIdSeleccionado == null ||
        _consecuenciaIdSeleccionada == null ||
        _probabilidadInicialId == null ||
        _severidadInicialId == null) {
      _mostrarMensaje(
        'Complete peligro, consecuencia, probabilidad y severidad.',
        esError: true,
      );
      return;
    }

    if (_registrarEvaluacionResidual &&
        (_probabilidadResidualId == null ||
            _severidadResidualId == null ||
            _probabilidadResidualValor == null ||
            _severidadResidualValor == null)) {
      _mostrarMensaje(
        'Complete la evaluación de riesgo residual.',
        esError: true,
      );
      return;
    }

    final PeligroModel? peligro =
        catalogos.buscarPeligroPorId(_peligroIdSeleccionado);

    final ConsecuenciaModel? consecuencia =
        catalogos.buscarConsecuenciaPorId(_consecuenciaIdSeleccionada);

    final ProbabilidadModel? probabilidadInicial =
        catalogos.buscarProbabilidadPorId(_probabilidadInicialId);

    final SeveridadModel? severidadInicial =
        catalogos.buscarSeveridadPorId(_severidadInicialId);

    if (peligro == null ||
        consecuencia == null ||
        probabilidadInicial == null ||
        severidadInicial == null) {
      _mostrarMensaje(
        'No se pudo resolver la selección con los catálogos IPERC.',
        esError: true,
      );
      return;
    }

    ProbabilidadModel? probabilidadResidual;
    SeveridadModel? severidadResidual;

    if (_registrarEvaluacionResidual) {
      probabilidadResidual =
          catalogos.buscarProbabilidadPorId(_probabilidadResidualId);

      severidadResidual =
          catalogos.buscarSeveridadPorId(_severidadResidualId);

      if (probabilidadResidual == null || severidadResidual == null) {
        _mostrarMensaje(
          'No se pudo resolver la evaluación residual seleccionada.',
          esError: true,
        );
        return;
      }
    }

    final DetalleIpercOfflineProvider provider =
        context.read<DetalleIpercOfflineProvider>();

    final DetalleIpercLocalModel? anterior = widget.detalle;
    final DateTime ahora = DateTime.now().toUtc();

    final int riesgoInicial =
        probabilidadInicial.valor * severidadInicial.valor;

    final int? riesgoResidual = _registrarEvaluacionResidual
        ? probabilidadResidual!.valor * severidadResidual!.valor
        : null;

    final DetalleIpercLocalModel detalle = DetalleIpercLocalModel(
      idLocal: anterior?.idLocal ?? _crearIdLocal(),
      idServidor: anterior?.idServidor,
      matrizIdLocal: matrizIdLocal,
      matrizIdServidor:
          anterior?.matrizIdServidor ?? widget.matrizIdServidor,

      item: int.parse(_itemController.text.trim()),
      tarea: _tareaController.text.trim(),

      // La actividad continúa siendo descriptiva en esta pantalla.
      // Si el registro ya tenía una relación real, se conserva.
      actividadId: anterior?.actividadId,

      peligroId: peligro.id.toString(),
      consecuenciaId: consecuencia.id.toString(),

      actividadDescripcion: _actividadController.text.trim(),
      peligroDescripcion: peligro.nombreCompleto,
      consecuenciaDescripcion: consecuencia.nombreCompleto,

      evaluacionInicialId: anterior?.evaluacionInicialId,

      // IDs REALES de MySQL.
      probabilidadInicialId: probabilidadInicial.id,
      severidadInicialId: severidadInicial.id,

      // Valores 1..5 para matriz 5x5.
      frecuenciaInicial: probabilidadInicial.valor,
      severidadInicial: severidadInicial.valor,

      valorRiesgoInicial: riesgoInicial,
      nivelRiesgoInicial: _obtenerNivelRiesgo(riesgoInicial),

      // Se conservan las relaciones previamente seleccionadas.
      controlIds: anterior?.controlIds ?? const <String>[],
      equipoProteccionIds:
          anterior?.equipoProteccionIds ?? const <String>[],

      controlDescripcion: _textoOpcional(_controlController.text),

      // Si se desactiva el residual, se limpia también su evaluación.
      evaluacionResidualId: _registrarEvaluacionResidual
          ? anterior?.evaluacionResidualId
          : null,

      probabilidadResidualId:
          _registrarEvaluacionResidual ? probabilidadResidual!.id : null,

      severidadResidualId:
          _registrarEvaluacionResidual ? severidadResidual!.id : null,

      frecuenciaResidual:
          _registrarEvaluacionResidual ? probabilidadResidual!.valor : null,

      severidadResidual:
          _registrarEvaluacionResidual ? severidadResidual!.valor : null,

      valorRiesgoResidual: riesgoResidual,

      nivelRiesgoResidual: riesgoResidual == null
          ? null
          : _obtenerNivelRiesgo(riesgoResidual),

      responsableImplementacionId:
          _textoOpcional(_responsableController.text),

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

    final bool guardado = widget.esEdicion
        ? await provider.actualizar(detalle)
        : await provider.crear(detalle);

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

  void _mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool guardando =
        context.select<DetalleIpercOfflineProvider, bool>(
      (DetalleIpercOfflineProvider provider) => provider.guardando,
    );

    final DetalleIpercCatalogosProvider catalogos =
        context.watch<DetalleIpercCatalogosProvider>();

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

                        _resolverIdsCatalogo(catalogos);

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
            : _construirFormulario(
                catalogos: catalogos,
                guardando: guardando,
              ),
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
            validator: _validarTextoObligatorio,
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
            validator: _validarTextoObligatorio,
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
            validator: (int? value) =>
                _validarIdSeleccionado(value, 'un peligro'),
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
            items: catalogos.consecuencias.map(
              (ConsecuenciaModel consecuencia) {
                return DropdownMenuItem<int>(
                  value: consecuencia.id,
                  child: Text(
                    consecuencia.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: guardando
                ? null
                : (int? value) {
                    setState(() {
                      _consecuenciaIdSeleccionada = value;
                    });
                  },
            validator: (int? value) =>
                _validarIdSeleccionado(value, 'una consecuencia'),
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

          DropdownButtonFormField<int>(
            initialValue: _valorProbabilidadInicialValido(catalogos),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Probabilidad *',
              prefixIcon: Icon(Icons.trending_up),
              border: OutlineInputBorder(),
            ),
            items: catalogos.probabilidades.map(
              (ProbabilidadModel item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.textoSeleccion),
                );
              },
            ).toList(),
            onChanged: guardando
                ? null
                : (int? id) {
                    final ProbabilidadModel? item =
                        catalogos.buscarProbabilidadPorId(id);

                    if (item == null) {
                      return;
                    }

                    setState(() {
                      _probabilidadInicialId = item.id;
                      _probabilidadInicialValor = item.valor;
                    });
                  },
            validator: (int? value) =>
                _validarIdSeleccionado(value, 'la probabilidad'),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            initialValue: _valorSeveridadInicialValido(catalogos),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Severidad *',
              prefixIcon: Icon(Icons.priority_high),
              border: OutlineInputBorder(),
            ),
            items: catalogos.severidades.map(
              (SeveridadModel item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.textoSeleccion),
                );
              },
            ).toList(),
            onChanged: guardando
                ? null
                : (int? id) {
                    final SeveridadModel? item =
                        catalogos.buscarSeveridadPorId(id);

                    if (item == null) {
                      return;
                    }

                    setState(() {
                      _severidadInicialId = item.id;
                      _severidadInicialValor = item.valor;
                    });
                  },
            validator: (int? value) =>
                _validarIdSeleccionado(value, 'la severidad'),
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
                        final ProbabilidadModel? primeraProbabilidad =
                            catalogos.probabilidades.isEmpty
                                ? null
                                : catalogos.probabilidades.first;

                        final SeveridadModel? primeraSeveridad =
                            catalogos.severidades.isEmpty
                                ? null
                                : catalogos.severidades.first;

                        if (_probabilidadResidualId == null &&
                            primeraProbabilidad != null) {
                          _probabilidadResidualId = primeraProbabilidad.id;
                          _probabilidadResidualValor =
                              primeraProbabilidad.valor;
                        }

                        if (_severidadResidualId == null &&
                            primeraSeveridad != null) {
                          _severidadResidualId = primeraSeveridad.id;
                          _severidadResidualValor = primeraSeveridad.valor;
                        }
                      } else {
                        _probabilidadResidualId = null;
                        _severidadResidualId = null;
                        _probabilidadResidualValor = null;
                        _severidadResidualValor = null;
                      }
                    });
                  },
          ),

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
              items: catalogos.probabilidades.map(
                (ProbabilidadModel item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.textoSeleccion),
                  );
                },
              ).toList(),
              onChanged: guardando
                  ? null
                  : (int? id) {
                      final ProbabilidadModel? item =
                          catalogos.buscarProbabilidadPorId(id);

                      if (item == null) {
                        return;
                      }

                      setState(() {
                        _probabilidadResidualId = item.id;
                        _probabilidadResidualValor = item.valor;
                      });
                    },
              validator: (int? value) =>
                  _validarIdSeleccionado(value, 'la probabilidad residual'),
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
              items: catalogos.severidades.map(
                (SeveridadModel item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.textoSeleccion),
                  );
                },
              ).toList(),
              onChanged: guardando
                  ? null
                  : (int? id) {
                      final SeveridadModel? item =
                          catalogos.buscarSeveridadPorId(id);

                      if (item == null) {
                        return;
                      }

                      setState(() {
                        _severidadResidualId = item.id;
                        _severidadResidualValor = item.valor;
                      });
                    },
              validator: (int? value) =>
                  _validarIdSeleccionado(value, 'la severidad residual'),
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

          _construirTituloSeccion(
            'Implementación',
            Icons.engineering_outlined,
          ),

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
            validator: _validarResponsable,
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
            onPressed:
                guardando || !catalogos.tieneCatalogos ? null : _guardar,
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

  int? _valorPeligroValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.peligros.any(
      (PeligroModel item) => item.id == _peligroIdSeleccionado,
    )
        ? _peligroIdSeleccionado
        : null;
  }

  int? _valorConsecuenciaValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.consecuencias.any(
      (ConsecuenciaModel item) => item.id == _consecuenciaIdSeleccionada,
    )
        ? _consecuenciaIdSeleccionada
        : null;
  }

  int? _valorProbabilidadInicialValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.probabilidades.any(
      (ProbabilidadModel item) => item.id == _probabilidadInicialId,
    )
        ? _probabilidadInicialId
        : null;
  }

  int? _valorSeveridadInicialValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.severidades.any(
      (SeveridadModel item) => item.id == _severidadInicialId,
    )
        ? _severidadInicialId
        : null;
  }

  int? _valorProbabilidadResidualValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.probabilidades.any(
      (ProbabilidadModel item) => item.id == _probabilidadResidualId,
    )
        ? _probabilidadResidualId
        : null;
  }

  int? _valorSeveridadResidualValido(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    return catalogos.severidades.any(
      (SeveridadModel item) => item.id == _severidadResidualId,
    )
        ? _severidadResidualId
        : null;
  }

  Widget _construirDescripcionPeligro(
    DetalleIpercCatalogosProvider catalogos,
  ) {
    final PeligroModel? peligro =
        catalogos.buscarPeligroPorId(_peligroIdSeleccionado);

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
    final ConsecuenciaModel? consecuencia =
        catalogos.buscarConsecuenciaPorId(_consecuenciaIdSeleccionada);

    if (consecuencia == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${consecuencia.clasificacionVisible} · '
      '${consecuencia.gravedadVisible}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _construirErrorCatalogos(
    DetalleIpercCatalogosProvider catalogos,
  ) {
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

              _resolverIdsCatalogo(catalogos);

              setState(() {});
            },
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
              'El detalle se guardará localmente y se sincronizará '
              'cuando exista conexión con el servidor.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTituloSeccion(
    String titulo,
    IconData icono,
  ) {
    return Row(
      children: <Widget>[
        Icon(icono, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
          Expanded(
            child: Text(_formatearFecha(fecha)),
          ),
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
              catalogos.advertencia ??
                  'Se están utilizando catálogos locales.',
            ),
          ),
        ],
      ),
    );
  }
}
