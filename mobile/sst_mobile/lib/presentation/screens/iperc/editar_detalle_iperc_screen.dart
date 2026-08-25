import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/consecuencia_model.dart';
import '../../../data/models/control_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/equipo_proteccion_model.dart';
import '../../../data/models/evaluacion_riesgo_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/peligro_model.dart';
import '../../../data/models/probabilidad_model.dart';
import '../../../data/models/severidad_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/repositories/consecuencia_repository.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/equipo_proteccion_repository.dart';
import '../../../data/repositories/peligro_repository.dart';
import '../../../data/repositories/probabilidad_repository.dart';
import '../../../data/repositories/severidad_repository.dart';
import '../../providers/detalle_iperc_provider.dart';
import '../../providers/usuario_provider.dart';

/// ===============================================================
/// EDITAR DETALLE IPERC - SST EDURISK
/// ===============================================================
///
/// Permite modificar:
/// - Ítem.
/// - Tarea.
/// - Peligro.
/// - Consecuencia.
/// - Evaluación inicial.
/// - Controles.
/// - EPP.
/// - Evaluación residual.
/// - Responsable.
/// - Fechas.
/// - Estado de implementación.
///
/// La pantalla calcula visualmente:
/// Riesgo = Probabilidad × Severidad
///
/// El backend vuelve a realizar el cálculo definitivo al guardar.
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
class EditarDetalleIpercScreen extends StatefulWidget {
  const EditarDetalleIpercScreen({
    required this.matriz,
    required this.detalle,
    super.key,
  });

  final MatrizIpercModel matriz;
  final DetalleIpercModel detalle;

  @override
  State<EditarDetalleIpercScreen> createState() {
    return _EditarDetalleIpercScreenState();
  }
}

class _EditarDetalleIpercScreenState extends State<EditarDetalleIpercScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _itemController = TextEditingController();

  final TextEditingController _tareaController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  // =============================================================
  // REPOSITORIOS
  // =============================================================

  final PeligroRepository _peligroRepository = PeligroRepository();

  final ConsecuenciaRepository _consecuenciaRepository =
      ConsecuenciaRepository();

  final ControlRepository _controlRepository = ControlRepository();

  final EquipoProteccionRepository _equipoProteccionRepository =
      EquipoProteccionRepository();

  final ProbabilidadRepository _probabilidadRepository =
      ProbabilidadRepository();

  final SeveridadRepository _severidadRepository = SeveridadRepository();

  // =============================================================
  // CATÁLOGOS
  // =============================================================

  List<PeligroModel> _peligros = <PeligroModel>[];

  List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];

  List<ControlModel> _controles = <ControlModel>[];

  List<EquipoProteccionModel> _equiposProteccion = <EquipoProteccionModel>[];

  List<ProbabilidadModel> _probabilidades = <ProbabilidadModel>[];

  List<SeveridadModel> _severidades = <SeveridadModel>[];

  // =============================================================
  // SELECCIONES
  // =============================================================

  PeligroModel? _peligroSeleccionado;

  ConsecuenciaModel? _consecuenciaSeleccionada;

  ProbabilidadModel? _probabilidadSeleccionada;

  SeveridadModel? _severidadSeleccionada;

  ProbabilidadModel? _probabilidadResidualSeleccionada;

  SeveridadModel? _severidadResidualSeleccionada;

  bool _registrarEvaluacionResidual = false;

  final Set<int> _controlIdsSeleccionados = <int>{};

  final Set<int> _equipoProteccionIdsSeleccionados = <int>{};

  // =============================================================
  // IMPLEMENTACIÓN
  // =============================================================

  int _estadoImplementacion = EstadoImplementacionIperc.pendiente;

  int? _responsableImplementacionId;

  DateTime? _fechaCompromiso;

  DateTime? _fechaImplementacion;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _mostrarErroresGestion = false;

  bool _cargandoCatalogos = true;

  bool _guardando = false;

  bool _mostrarErroresResidual = false;

  String? _errorCarga;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _itemController.text = widget.detalle.item.toString();

    _tareaController.text = widget.detalle.tarea;

    _descripcionController.text = widget.detalle.descripcionPeligro ?? '';

    _controlIdsSeleccionados.addAll(widget.detalle.controlIds);

    _equipoProteccionIdsSeleccionados.addAll(
      widget.detalle.equipoProteccionIds,
    );

    _estadoImplementacion =
        EstadoImplementacionIperc.valores.contains(
          widget.detalle.estadoImplementacionId,
        )
        ? widget.detalle.estadoImplementacionId
        : EstadoImplementacionIperc.pendiente;

    _registrarEvaluacionResidual = widget.detalle.tieneEvaluacionResidual;

    _responsableImplementacionId = widget.detalle.responsableImplementacionId;

    _fechaCompromiso = _soloFecha(widget.detalle.fechaCompromiso);

    _fechaImplementacion = _soloFecha(widget.detalle.fechaImplementacion);

    _cargarCatalogos();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _tareaController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  // =============================================================
  // CARGAR CATÁLOGOS
  // =============================================================

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCarga = null;
    });

    try {
      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _peligroRepository.obtenerActivos(),
            _consecuenciaRepository.obtenerActivos(),
            _controlRepository.obtenerActivos(),
            _equipoProteccionRepository.obtenerActivos(),
            _probabilidadRepository.obtenerTodas(),
            _severidadRepository.obtenerTodas(),
          ]);

      if (!mounted) {
        return;
      }

      final List<PeligroModel> peligros = (resultados[0] as List<dynamic>)
          .whereType<PeligroModel>()
          .toList();

      final List<ConsecuenciaModel> consecuencias =
          (resultados[1] as List<dynamic>)
              .whereType<ConsecuenciaModel>()
              .toList();

      final List<ControlModel> controles = (resultados[2] as List<dynamic>)
          .whereType<ControlModel>()
          .toList();

      final List<EquipoProteccionModel> equipos =
          (resultados[3] as List<dynamic>)
              .whereType<EquipoProteccionModel>()
              .toList();

      final List<ProbabilidadModel> probabilidades =
          (resultados[4] as List<dynamic>)
              .whereType<ProbabilidadModel>()
              .toList();

      final List<SeveridadModel> severidades = (resultados[5] as List<dynamic>)
          .whereType<SeveridadModel>()
          .toList();

      probabilidades.sort(
        (ProbabilidadModel a, ProbabilidadModel b) =>
            a.valor.compareTo(b.valor),
      );

      severidades.sort(
        (SeveridadModel a, SeveridadModel b) => a.valor.compareTo(b.valor),
      );

      setState(() {
        _peligros = peligros;
        _consecuencias = consecuencias;
        _controles = controles;
        _equiposProteccion = equipos;
        _probabilidades = probabilidades;
        _severidades = severidades;

        _peligroSeleccionado = _buscarPeligro(widget.detalle.peligroId);

        _consecuenciaSeleccionada = _buscarConsecuencia(
          widget.detalle.consecuenciaId,
        );

        // Primero buscamos por ID REAL de MySQL.
        // Si el registro es antiguo, se usa el valor 1..5
        // como mecanismo de compatibilidad.
        _probabilidadSeleccionada = _buscarProbabilidad(
          widget.detalle.evaluacionInicial.probabilidadId,
          valor: widget.detalle.evaluacionInicial.valorProbabilidad,
        );

        _severidadSeleccionada = _buscarSeveridad(
          widget.detalle.evaluacionInicial.severidadId,
          valor: widget.detalle.evaluacionInicial.valorSeveridad,
        );

        final EvaluacionDetalleIpercModel? residual =
            widget.detalle.evaluacionResidual;

        if (residual == null) {
          _probabilidadResidualSeleccionada = null;
          _severidadResidualSeleccionada = null;
        } else {
          _probabilidadResidualSeleccionada = _buscarProbabilidad(
            residual.probabilidadId,
            valor: residual.valorProbabilidad,
          );

          _severidadResidualSeleccionada = _buscarSeveridad(
            residual.severidadId,
            valor: residual.valorSeveridad,
          );
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorCarga = _limpiarMensaje(error);
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
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    setState(() {
      _mostrarErroresResidual = true;
      _mostrarErroresGestion = true;
    });

    final bool residualValida =
        !_registrarEvaluacionResidual ||
        (_probabilidadResidualSeleccionada != null &&
            _severidadResidualSeleccionada != null);

    final bool responsableValido = _responsableImplementacionId != null;

    final bool compromisoValido = _fechaCompromiso != null;

    final bool requiereFechaImplementacion =
        _estadoImplementacion >= EstadoImplementacionIperc.implementado;

    final bool implementacionCompleta =
        !requiereFechaImplementacion || _fechaImplementacion != null;

    final bool ordenFechasValido =
        _fechaCompromiso == null ||
        _fechaImplementacion == null ||
        !_fechaImplementacion!.isBefore(_fechaCompromiso!);

    if (!formularioValido ||
        !residualValida ||
        !responsableValido ||
        !compromisoValido ||
        !implementacionCompleta ||
        !ordenFechasValido) {
      return;
    }

    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    setState(() {
      _guardando = true;
    });

    try {
      final ActualizarDetalleIpercRequest request =
          ActualizarDetalleIpercRequest(
            id: widget.detalle.id,
            matrizIpercId: widget.matriz.id,
            item: int.parse(_itemController.text.trim()),
            tarea: _tareaController.text,
            peligroId: _peligroSeleccionado!.id,
            consecuenciaId: _consecuenciaSeleccionada!.id,
            descripcionPeligro: _descripcionController.text,

            // EVALUACIÓN INICIAL
            probabilidadInicialId: _probabilidadSeleccionada!.id,
            severidadInicialId: _severidadSeleccionada!.id,
            observacionesEvaluacionInicial:
                widget.detalle.evaluacionInicial.observaciones,

            // EVALUACIÓN RESIDUAL
            probabilidadResidualId: _registrarEvaluacionResidual
                ? _probabilidadResidualSeleccionada!.id
                : null,
            severidadResidualId: _registrarEvaluacionResidual
                ? _severidadResidualSeleccionada!.id
                : null,
            observacionesEvaluacionResidual: _registrarEvaluacionResidual
                ? widget.detalle.evaluacionResidual?.observaciones
                : null,

            // CONTROLES
            controlIds: _controlIdsSeleccionados.toList(growable: false),

            // EPP
            equipoProteccionIds: _equipoProteccionIdsSeleccionados.toList(
              growable: false,
            ),

            // IMPLEMENTACIÓN
            responsableImplementacionId: _responsableImplementacionId,
            fechaCompromiso: _fechaCompromiso,
            fechaImplementacion: _fechaImplementacion,
            estadoImplementacion: _estadoImplementacion,
          );

      final bool actualizado = await provider.actualizar(
        widget.detalle.id,
        request,
      );

      if (!mounted) {
        return;
      }

      if (actualizado) {
        _mostrarMensaje(
          'Detalle y evaluaciones actualizados correctamente.',
          esError: false,
        );

        Navigator.of(context).pop(true);

        return;
      }

      _mostrarMensaje(
        provider.error ?? 'No se pudo actualizar el detalle IPERC.',
        esError: true,
      );
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(_limpiarMensaje(error), esError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final DetalleIpercProvider provider = context.watch<DetalleIpercProvider>();

    final UsuarioProvider usuarioProvider = context.watch<UsuarioProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Editar peligro evaluado'),
      ),
      body: SafeArea(
        child: _cargandoCatalogos
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _construirContenido(provider, usuarioProvider),
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
    if (_errorCarga != null && _peligros.isEmpty) {
      return _EstadoCarga(
        mensaje: _errorCarga!,
        onReintentar: _cargarCatalogos,
      );
    }

    final bool bloqueado = provider.procesando || _guardando;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: <Widget>[
          // =====================================================
          // RESUMEN
          // =====================================================
          _ResumenMatriz(matriz: widget.matriz, detalle: widget.detalle),

          const SizedBox(height: 18),

          // =====================================================
          // IDENTIFICACIÓN
          // =====================================================
          _SeccionFormulario(
            icono: Icons.warning_amber_outlined,
            titulo: 'Identificación del peligro',
            descripcion:
                'Actualice la tarea, el peligro, la consecuencia '
                'y su descripción específica.',
            color: AppColors.riskOrange,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _itemController,
                  enabled: !bloqueado,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Ítem *',
                    prefixIcon: Icon(
                      Icons.tag_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  validator: _validarEnteroObligatorio,
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _tareaController,
                  enabled: !bloqueado,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: 'Tarea *',
                    prefixIcon: Icon(
                      Icons.work_outline,
                      color: AppColors.primaryBright,
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la tarea que será evaluada.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<PeligroModel>(
                  initialValue: _peligroSeleccionado,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Peligro *',
                    prefixIcon: Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.riskOrange,
                    ),
                  ),
                  items: _peligros.map((PeligroModel peligro) {
                    return DropdownMenuItem<PeligroModel>(
                      value: peligro,
                      child: Text(
                        peligro.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: bloqueado
                      ? null
                      : (PeligroModel? value) {
                          setState(() {
                            _peligroSeleccionado = value;
                          });
                        },
                  validator: (PeligroModel? value) {
                    return value == null ? 'Selecciona un peligro.' : null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<ConsecuenciaModel>(
                  initialValue: _consecuenciaSeleccionada,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Consecuencia *',
                    prefixIcon: Icon(
                      Icons.report_problem_outlined,
                      color: AppColors.yellow,
                    ),
                  ),
                  items: _consecuencias.map((ConsecuenciaModel consecuencia) {
                    return DropdownMenuItem<ConsecuenciaModel>(
                      value: consecuencia,
                      child: Text(
                        consecuencia.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: bloqueado
                      ? null
                      : (ConsecuenciaModel? value) {
                          setState(() {
                            _consecuenciaSeleccionada = value;
                          });
                        },
                  validator: (ConsecuenciaModel? value) {
                    return value == null
                        ? 'Selecciona una consecuencia.'
                        : null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _descripcionController,
                  enabled: !bloqueado,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Descripción específica',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // EVALUACIÓN INICIAL
          // =====================================================
          _SeccionFormulario(
            icono: Icons.calculate_outlined,
            titulo: 'Evaluación inicial del riesgo',
            descripcion:
                'Modifique probabilidad y severidad. '
                'El riesgo se recalcula automáticamente.',
            color: AppColors.yellow,
            colorTexto: AppColors.navyDark,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<ProbabilidadModel>(
                  initialValue: _probabilidadSeleccionada,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Probabilidad *',
                    prefixIcon: Icon(
                      Icons.trending_up_outlined,
                      color: AppColors.primaryBright,
                    ),
                  ),
                  items: _probabilidades.map((ProbabilidadModel opcion) {
                    return DropdownMenuItem<ProbabilidadModel>(
                      value: opcion,
                      child: Text(opcion.textoSeleccion),
                    );
                  }).toList(),
                  onChanged: bloqueado
                      ? null
                      : (ProbabilidadModel? value) {
                          setState(() {
                            _probabilidadSeleccionada = value;
                          });
                        },
                  validator: (ProbabilidadModel? value) {
                    if (value == null) {
                      return 'Selecciona la probabilidad.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<SeveridadModel>(
                  initialValue: _severidadSeleccionada,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Severidad *',
                    prefixIcon: Icon(
                      Icons.priority_high_outlined,
                      color: AppColors.riskOrange,
                    ),
                  ),
                  items: _severidades.map((SeveridadModel opcion) {
                    return DropdownMenuItem<SeveridadModel>(
                      value: opcion,
                      child: Text(opcion.textoSeleccion),
                    );
                  }).toList(),
                  onChanged: bloqueado
                      ? null
                      : (SeveridadModel? value) {
                          setState(() {
                            _severidadSeleccionada = value;
                          });
                        },
                  validator: (SeveridadModel? value) {
                    if (value == null) {
                      return 'Selecciona la severidad.';
                    }

                    return null;
                  },
                ),

                if (_probabilidadSeleccionada != null &&
                    _severidadSeleccionada != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _ResumenEvaluacionRiesgo(
                    probabilidad: _probabilidadSeleccionada!,
                    severidad: _severidadSeleccionada!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // CONTROLES
          // =====================================================
          _SeccionFormulario(
            icono: Icons.security_outlined,
            titulo: 'Controles aplicables',
            descripcion:
                'Actualice las medidas de control utilizadas para reducir el riesgo.',
            color: AppColors.green,
            child: _SelectorControles(
              controles: _controles,
              seleccionados: _controlIdsSeleccionados,
              habilitado: !bloqueado,
              onChanged: _alternarControl,
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // EPP
          // =====================================================
          _SeccionFormulario(
            icono: Icons.health_and_safety_outlined,
            titulo: 'Equipos de protección personal',
            descripcion: 'Actualice los EPP requeridos para esta tarea.',
            color: AppColors.primaryBright,
            child: _SelectorEquiposProteccion(
              equipos: _equiposProteccion,
              seleccionados: _equipoProteccionIdsSeleccionados,
              habilitado: !bloqueado,
              onChanged: _alternarEquipoProteccion,
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // EVALUACIÓN RESIDUAL
          // =====================================================
          _SeccionEvaluacionResidual(
            activa: _registrarEvaluacionResidual,
            bloqueada: bloqueado,
            probabilidades: _probabilidades,
            severidades: _severidades,
            probabilidad: _probabilidadResidualSeleccionada,
            severidad: _severidadResidualSeleccionada,
            mostrarErrores: _mostrarErroresResidual,
            onActivar: (bool value) {
              setState(() {
                _registrarEvaluacionResidual = value;

                _mostrarErroresResidual = false;

                if (!value) {
                  _probabilidadResidualSeleccionada = null;

                  _severidadResidualSeleccionada = null;
                }
              });
            },
            onProbabilidadChanged: (ProbabilidadModel? value) {
              setState(() {
                _probabilidadResidualSeleccionada = value;
              });
            },
            onSeveridadChanged: (SeveridadModel? value) {
              setState(() {
                _severidadResidualSeleccionada = value;
              });
            },
          ),

          if (_registrarEvaluacionResidual &&
              _probabilidadSeleccionada != null &&
              _severidadSeleccionada != null &&
              _probabilidadResidualSeleccionada != null &&
              _severidadResidualSeleccionada != null) ...<Widget>[
            const SizedBox(height: 16),
            _ComparacionEvaluaciones(
              probabilidadInicial: _probabilidadSeleccionada!,
              severidadInicial: _severidadSeleccionada!,
              probabilidadResidual: _probabilidadResidualSeleccionada!,
              severidadResidual: _severidadResidualSeleccionada!,
            ),
          ],

          const SizedBox(height: 18),

          // =====================================================
          // IMPLEMENTACIÓN
          // =====================================================
          _SeccionFormulario(
            icono: Icons.task_alt_outlined,
            titulo: 'Implementación de medidas',
            descripcion:
                'Asigne responsable, fechas y estado de implementación.',
            color: AppColors.primary,
            child: Column(
              children: <Widget>[
                if (usuarioProvider.cargando) ...<Widget>[
                  const LinearProgressIndicator(
                    color: AppColors.primaryBright,
                    backgroundColor: AppColors.border,
                  ),
                  const SizedBox(height: 14),
                ],

                if (usuarioProvider.error != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.riskOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.riskOrange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.riskOrange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            usuarioProvider.error!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reintentar',
                          onPressed: bloqueado
                              ? null
                              : usuarioProvider.cargarUsuarios,
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                DropdownButtonFormField<int>(
                  key: ValueKey<String>(
                    'responsable-'
                    '${_responsableImplementacionId ?? 0}-'
                    '${usuarioProvider.usuarios.length}',
                  ),
                  initialValue:
                      usuarioProvider.usuarios.any(
                        (UsuarioModel usuario) =>
                            usuario.id == _responsableImplementacionId,
                      )
                      ? _responsableImplementacionId
                      : null,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Responsable de implementación *',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  items: usuarioProvider.usuarios.map((UsuarioModel usuario) {
                    return DropdownMenuItem<int>(
                      value: usuario.id,
                      child: Text(
                        usuario.nombreVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: bloqueado || usuarioProvider.cargando
                      ? null
                      : (int? value) {
                          setState(() {
                            _responsableImplementacionId = value;
                          });
                        },
                  validator: (int? value) {
                    if (value == null) {
                      return 'Selecciona al responsable.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _CampoFecha(
                  etiqueta: 'Fecha de compromiso *',
                  fecha: _fechaCompromiso,
                  habilitado: !bloqueado,
                  icono: Icons.event_outlined,
                  color: AppColors.yellow,
                  colorTexto: AppColors.navyDark,
                  errorTexto: _mostrarErroresGestion && _fechaCompromiso == null
                      ? 'Selecciona la fecha de compromiso.'
                      : null,
                  onSeleccionar: () =>
                      _seleccionarFecha(tipo: _TipoFecha.compromiso),
                  onLimpiar: null,
                ),

                const SizedBox(height: 14),

                _CampoFecha(
                  etiqueta:
                      _estadoImplementacion >=
                          EstadoImplementacionIperc.implementado
                      ? 'Fecha de implementación *'
                      : 'Fecha de implementación',
                  fecha: _fechaImplementacion,
                  habilitado: !bloqueado,
                  icono: Icons.event_available_outlined,
                  color: AppColors.green,
                  errorTexto: _errorFechaImplementacion,
                  onSeleccionar: () =>
                      _seleccionarFecha(tipo: _TipoFecha.implementacion),
                  onLimpiar: _fechaImplementacion == null
                      ? null
                      : () {
                          setState(() {
                            _fechaImplementacion = null;
                          });
                        },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<int>(
                  initialValue: _estadoImplementacion,
                  isExpanded: true,
                  iconEnabledColor: AppColors.primary,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Estado de implementación',
                    prefixIcon: Icon(
                      Icons.task_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  items: EstadoImplementacionIperc.valores.map((int estado) {
                    return DropdownMenuItem<int>(
                      value: estado,
                      child: Text(
                        EstadoImplementacionIperc.obtenerNombre(estado),
                      ),
                    );
                  }).toList(),
                  onChanged: bloqueado
                      ? null
                      : (int? value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _estadoImplementacion = value;

                            if (value <
                                EstadoImplementacionIperc.implementado) {
                              _fechaImplementacion = null;
                            }
                          });
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =====================================================
          // GUARDAR
          // =====================================================
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.45,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: bloqueado ? null : _guardar,
              icon: bloqueado
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                bloqueado ? 'Guardando...' : 'Guardar cambios',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: bloqueado
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // BUSCADORES
  // =============================================================

  PeligroModel? _buscarPeligro(int id) {
    for (final PeligroModel peligro in _peligros) {
      if (peligro.id == id) {
        return peligro;
      }
    }

    return null;
  }

  ConsecuenciaModel? _buscarConsecuencia(int id) {
    for (final ConsecuenciaModel consecuencia in _consecuencias) {
      if (consecuencia.id == id) {
        return consecuencia;
      }
    }

    return null;
  }

  ProbabilidadModel? _buscarProbabilidad(int id, {int? valor}) {
    for (final ProbabilidadModel opcion in _probabilidades) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    if (valor != null && valor > 0) {
      return _probabilidadRepository.obtenerPorValor(_probabilidades, valor);
    }

    return null;
  }

  SeveridadModel? _buscarSeveridad(int id, {int? valor}) {
    for (final SeveridadModel opcion in _severidades) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    if (valor != null && valor > 0) {
      return _severidadRepository.obtenerPorValor(_severidades, valor);
    }

    return null;
  }

  // =============================================================
  // VALIDACIÓN FECHAS
  // =============================================================

  String? get _errorFechaImplementacion {
    if (!_mostrarErroresGestion) {
      return null;
    }

    if (_estadoImplementacion >= EstadoImplementacionIperc.implementado &&
        _fechaImplementacion == null) {
      return 'Selecciona la fecha de implementación.';
    }

    if (_fechaCompromiso != null &&
        _fechaImplementacion != null &&
        _fechaImplementacion!.isBefore(_fechaCompromiso!)) {
      return 'No puede ser anterior a la fecha de compromiso.';
    }

    return null;
  }

  // =============================================================
  // DATE PICKER
  // =============================================================

  Future<void> _seleccionarFecha({required _TipoFecha tipo}) async {
    final DateTime hoy = _soloFecha(DateTime.now())!;

    final DateTime? actual = tipo == _TipoFecha.compromiso
        ? _fechaCompromiso
        : _fechaImplementacion;

    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? _fechaCompromiso ?? hoy,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year + 10, 12, 31),
      helpText: tipo == _TipoFecha.compromiso
          ? 'Seleccionar fecha de compromiso'
          : 'Seleccionar fecha de implementación',
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

    if (!mounted || seleccionada == null) {
      return;
    }

    setState(() {
      _mostrarErroresGestion = false;

      if (tipo == _TipoFecha.compromiso) {
        _fechaCompromiso = _soloFecha(seleccionada);
      } else {
        _fechaImplementacion = _soloFecha(seleccionada);
      }
    });
  }

  static DateTime? _soloFecha(DateTime? fecha) {
    if (fecha == null) {
      return null;
    }

    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  // =============================================================
  // VALIDACIÓN ITEM
  // =============================================================

  String? _validarEnteroObligatorio(String? value) {
    final int? id = int.tryParse(value?.trim() ?? '');

    if (id == null || id <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

  // =============================================================
  // CONTROLES / EPP
  // =============================================================

  void _alternarControl(int id) {
    setState(() {
      if (_controlIdsSeleccionados.contains(id)) {
        _controlIdsSeleccionados.remove(id);
      } else {
        _controlIdsSeleccionados.add(id);
      }
    });
  }

  void _alternarEquipoProteccion(int id) {
    setState(() {
      if (_equipoProteccionIdsSeleccionados.contains(id)) {
        _equipoProteccionIdsSeleccionados.remove(id);
      } else {
        _equipoProteccionIdsSeleccionados.add(id);
      }
    });
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {required bool esError}) {
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

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

// ===============================================================
// TIPO DE FECHA
// ===============================================================

enum _TipoFecha { compromiso, implementacion }

// ===============================================================
// CAMPO FECHA
// ===============================================================

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.etiqueta,
    required this.fecha,
    required this.habilitado,
    required this.icono,
    required this.color,
    required this.errorTexto,
    required this.onSeleccionar,
    required this.onLimpiar,
    this.colorTexto,
  });

  final String etiqueta;
  final DateTime? fecha;
  final bool habilitado;
  final IconData icono;
  final Color color;
  final Color? colorTexto;
  final String? errorTexto;
  final VoidCallback onSeleccionar;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return InkWell(
      onTap: habilitado ? onSeleccionar : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono, color: foreground),
          suffixIcon: onLimpiar == null
              ? Icon(Icons.calendar_month_outlined, color: foreground)
              : IconButton(
                  tooltip: 'Limpiar fecha',
                  onPressed: habilitado ? onLimpiar : null,
                  icon: const Icon(Icons.clear),
                ),
          errorText: errorTexto,
          enabled: habilitado,
        ),
        child: Text(
          fecha == null
              ? 'Seleccionar fecha'
              : '${fecha!.day.toString().padLeft(2, '0')}/'
                    '${fecha!.month.toString().padLeft(2, '0')}/'
                    '${fecha!.year}',
          style: TextStyle(
            color: fecha == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontWeight: fecha == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// RESUMEN MATRIZ
// ===============================================================

class _ResumenMatriz extends StatelessWidget {
  const _ResumenMatriz({required this.matriz, required this.detalle});

  final MatrizIpercModel matriz;
  final DetalleIpercModel detalle;

  @override
  Widget build(BuildContext context) {
    final Color riesgo = _colorDesdeHex(detalle.evaluacionInicial.color);

    return Container(
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              detalle.item > 0 ? detalle.item.toString() : '-',
              style: TextStyle(
                color: riesgo,
                fontSize: 19,
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
                  matriz.codigo,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  matriz.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle.peligroVisible,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCEAFF),
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
// SECCIÓN FORMULARIO
// ===============================================================

class _SeccionFormulario extends StatelessWidget {
  const _SeccionFormulario({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.child,
    this.colorTexto,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color? colorTexto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: foreground, size: 26),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ===============================================================
// RESUMEN DE RIESGO
// ===============================================================

class _ResumenEvaluacionRiesgo extends StatelessWidget {
  const _ResumenEvaluacionRiesgo({
    required this.probabilidad,
    required this.severidad,
  });

  final ProbabilidadModel probabilidad;
  final SeveridadModel severidad;

  @override
  Widget build(BuildContext context) {
    final int valor = probabilidad.valor * severidad.valor;

    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    final Color color = _colorDesdeHex(nivel.colorHex);

    final Color texto = _colorDeTexto(color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.60)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  valor.toString(),
                  style: TextStyle(
                    color: texto,
                    fontSize: 19,
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
                      'Nivel ${nivel.nombre}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nivel.aceptable
                          ? 'Riesgo aceptable con seguimiento.'
                          : 'Requiere controles y seguimiento.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FilaCalculo(
            etiqueta: 'Cálculo',
            valor: '${probabilidad.valor} × ${severidad.valor} = $valor',
          ),
          _FilaCalculo(
            etiqueta: 'Probabilidad',
            valor: probabilidad.textoSeleccion,
          ),
          _FilaCalculo(etiqueta: 'Severidad', valor: severidad.textoSeleccion),
        ],
      ),
    );
  }
}

class _FilaCalculo extends StatelessWidget {
  const _FilaCalculo({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
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
// EVALUACIÓN RESIDUAL
// ===============================================================

class _SeccionEvaluacionResidual extends StatelessWidget {
  const _SeccionEvaluacionResidual({
    required this.activa,
    required this.bloqueada,
    required this.probabilidades,
    required this.severidades,
    required this.probabilidad,
    required this.severidad,
    required this.mostrarErrores,
    required this.onActivar,
    required this.onProbabilidadChanged,
    required this.onSeveridadChanged,
  });

  final bool activa;
  final bool bloqueada;
  final List<ProbabilidadModel> probabilidades;
  final List<SeveridadModel> severidades;
  final ProbabilidadModel? probabilidad;
  final SeveridadModel? severidad;
  final bool mostrarErrores;
  final ValueChanged<bool> onActivar;
  final ValueChanged<ProbabilidadModel?> onProbabilidadChanged;
  final ValueChanged<SeveridadModel?> onSeveridadChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColors.green,
            activeThumbColor: Colors.white,
            secondary: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.trending_down_outlined,
                color: AppColors.green,
              ),
            ),
            title: const Text(
              'Evaluación residual',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            subtitle: const Text(
              'Actívala después de seleccionar los controles y EPP aplicados.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            value: activa,
            onChanged: bloqueada ? null : onActivar,
          ),

          if (activa) ...<Widget>[
            const SizedBox(height: 14),

            DropdownButtonFormField<ProbabilidadModel>(
              initialValue: probabilidad,
              isExpanded: true,
              iconEnabledColor: AppColors.primary,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: 'Probabilidad residual *',
                prefixIcon: const Icon(
                  Icons.trending_up_outlined,
                  color: AppColors.primaryBright,
                ),
                errorText: mostrarErrores && probabilidad == null
                    ? 'Selecciona la probabilidad residual.'
                    : null,
              ),
              items: probabilidades.map((ProbabilidadModel opcion) {
                return DropdownMenuItem<ProbabilidadModel>(
                  value: opcion,
                  child: Text(opcion.textoSeleccion),
                );
              }).toList(),
              onChanged: bloqueada ? null : onProbabilidadChanged,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<SeveridadModel>(
              initialValue: severidad,
              isExpanded: true,
              iconEnabledColor: AppColors.primary,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: 'Severidad residual *',
                prefixIcon: const Icon(
                  Icons.priority_high_outlined,
                  color: AppColors.riskOrange,
                ),
                errorText: mostrarErrores && severidad == null
                    ? 'Selecciona la severidad residual.'
                    : null,
              ),
              items: severidades.map((SeveridadModel opcion) {
                return DropdownMenuItem<SeveridadModel>(
                  value: opcion,
                  child: Text(opcion.textoSeleccion),
                );
              }).toList(),
              onChanged: bloqueada ? null : onSeveridadChanged,
            ),

            if (probabilidad != null && severidad != null) ...<Widget>[
              const SizedBox(height: 14),
              _ResumenEvaluacionRiesgo(
                probabilidad: probabilidad!,
                severidad: severidad!,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ===============================================================
// COMPARACIÓN
// ===============================================================

class _ComparacionEvaluaciones extends StatelessWidget {
  const _ComparacionEvaluaciones({
    required this.probabilidadInicial,
    required this.severidadInicial,
    required this.probabilidadResidual,
    required this.severidadResidual,
  });

  final ProbabilidadModel probabilidadInicial;

  final SeveridadModel severidadInicial;

  final ProbabilidadModel probabilidadResidual;

  final SeveridadModel severidadResidual;

  @override
  Widget build(BuildContext context) {
    final int valorInicial = probabilidadInicial.valor * severidadInicial.valor;

    final int valorResidual =
        probabilidadResidual.valor * severidadResidual.valor;

    final int reduccion = valorInicial - valorResidual;

    final bool mejoro = reduccion > 0;

    final bool seMantuvo = reduccion == 0;

    final Color color = mejoro
        ? AppColors.green
        : seMantuvo
        ? AppColors.yellow
        : AppColors.riskOrange;

    final Color foreground = seMantuvo ? AppColors.navyDark : color;

    final String mensaje = mejoro
        ? 'Los controles reducen el riesgo en $reduccion punto(s).'
        : seMantuvo
        ? 'El riesgo no cambió después de los controles.'
        : 'El riesgo residual es mayor. Revisa los controles aplicados.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: seMantuvo ? 0.14 : 0.09),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.compare_arrows_outlined, color: foreground),
              const SizedBox(width: 8),
              const Text(
                'Comparación del riesgo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _ValorComparacion(
                  etiqueta: 'Inicial',
                  valor: valorInicial,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: AppColors.primary),
              ),
              Expanded(
                child: _ValorComparacion(
                  etiqueta: 'Residual',
                  valor: valorResidual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                mejoro
                    ? Icons.check_circle_outline
                    : seMantuvo
                    ? Icons.info_outline
                    : Icons.warning_amber_outlined,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValorComparacion extends StatelessWidget {
  const _ValorComparacion({required this.etiqueta, required this.valor});

  final String etiqueta;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    final Color color = _colorDesdeHex(nivel.colorHex);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            valor.toString(),
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nivel.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// SELECTORES MÚLTIPLES
// ===============================================================

class _SelectorControles extends StatelessWidget {
  const _SelectorControles({
    required this.controles,
    required this.seleccionados,
    required this.habilitado,
    required this.onChanged,
  });

  final List<ControlModel> controles;

  final Set<int> seleccionados;

  final bool habilitado;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SelectorMultipleCatalogo(
      subtitulo: controles.isEmpty
          ? 'No hay controles activos registrados.'
          : 'Seleccionados: ${seleccionados.length}',
      color: AppColors.green,
      chips: controles.map((ControlModel control) {
        final bool selected = seleccionados.contains(control.id);

        return FilterChip(
          selected: selected,
          selectedColor: AppColors.green.withValues(alpha: 0.16),
          checkmarkColor: AppColors.green,
          label: Text(control.nombreCompleto),
          onSelected: habilitado ? (_) => onChanged(control.id) : null,
        );
      }).toList(),
    );
  }
}

class _SelectorEquiposProteccion extends StatelessWidget {
  const _SelectorEquiposProteccion({
    required this.equipos,
    required this.seleccionados,
    required this.habilitado,
    required this.onChanged,
  });

  final List<EquipoProteccionModel> equipos;

  final Set<int> seleccionados;

  final bool habilitado;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SelectorMultipleCatalogo(
      subtitulo: equipos.isEmpty
          ? 'No hay EPP activos registrados.'
          : 'Seleccionados: ${seleccionados.length}',
      color: AppColors.primaryBright,
      chips: equipos.map((EquipoProteccionModel equipo) {
        final bool selected = seleccionados.contains(equipo.id);

        return FilterChip(
          selected: selected,
          selectedColor: AppColors.primaryBright.withValues(alpha: 0.16),
          checkmarkColor: AppColors.primary,
          label: Text(equipo.nombreCompleto),
          onSelected: habilitado ? (_) => onChanged(equipo.id) : null,
        );
      }).toList(),
    );
  }
}

class _SelectorMultipleCatalogo extends StatelessWidget {
  const _SelectorMultipleCatalogo({
    required this.subtitulo,
    required this.color,
    required this.chips,
  });

  final String subtitulo;
  final Color color;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            subtitulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 18, color: color),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'No hay elementos disponibles para seleccionar.',
                    style: TextStyle(
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
    );
  }
}

// ===============================================================
// ESTADO DE CARGA
// ===============================================================

class _EstadoCarga extends StatelessWidget {
  const _EstadoCarga({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.riskOrange.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: AppColors.riskOrange,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No se pudieron cargar los catálogos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.40,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Volver a intentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// COLOR RIESGO
// ===============================================================

Color _colorDesdeHex(String hex) {
  final String limpio = hex.replaceAll('#', '').trim();

  final String completo = limpio.length == 6 ? 'FF$limpio' : limpio;

  final int? valor = int.tryParse(completo, radix: 16);

  return valor == null ? AppColors.textSecondary : Color(valor);
}

Color _colorDeTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
