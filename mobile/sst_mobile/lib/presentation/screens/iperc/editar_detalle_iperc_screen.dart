import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
/// EDITAR DETALLE IPERC
/// ===============================================================
///
/// Permite modificar:
///
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
/// IMPORTANTE:
///
/// La pantalla calcula visualmente:
///
/// Riesgo = Probabilidad x Severidad
///
/// tanto para:
///
/// - Riesgo inicial.
/// - Riesgo residual.
///
/// El backend vuelve a realizar el cálculo definitivo
/// cuando se guarda el registro.
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
  // PELIGRO / CONSECUENCIA
  // =============================================================

  PeligroModel? _peligroSeleccionado;

  ConsecuenciaModel? _consecuenciaSeleccionada;

  // =============================================================
  // EVALUACIÓN INICIAL
  // =============================================================

  ProbabilidadModel? _probabilidadSeleccionada;

  SeveridadModel? _severidadSeleccionada;

  // =============================================================
  // EVALUACIÓN RESIDUAL
  // =============================================================

  ProbabilidadModel? _probabilidadResidualSeleccionada;

  SeveridadModel? _severidadResidualSeleccionada;

  bool _registrarEvaluacionResidual = false;

  // =============================================================
  // CONTROLES Y EPP
  // =============================================================

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
  // ESTADO DE PANTALLA
  // =============================================================

  bool _mostrarErroresGestion = false;

  bool _cargandoCatalogos = true;

  bool _guardando = false;

  bool _mostrarErroresResidual = false;

  String? _errorCarga;

  // =============================================================
  // INICIALIZAR
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

  // =============================================================
  // LIBERAR CONTROLADORES
  // =============================================================

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
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _peligroRepository.obtenerActivos(),
          _consecuenciaRepository.obtenerActivos(),
          _controlRepository.obtenerActivos(),
          _equipoProteccionRepository.obtenerActivos(),

          // Catálogos reales de la base de datos.
          _probabilidadRepository.obtenerTodas(),
          _severidadRepository.obtenerTodas(),
        ],
      );

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

        // =========================================================
        // EVALUACIÓN INICIAL
        // =========================================================
        //
        // Primero buscamos por ID REAL.
        //
        // Si por alguna razón el registro fue creado cuando
        // Flutter todavía utilizaba IDs locales 1..5,
        // utilizamos también el valor recibido del backend
        // como mecanismo de compatibilidad.

        _probabilidadSeleccionada = _buscarProbabilidad(
          widget.detalle.evaluacionInicial.probabilidadId,
          valor: widget.detalle.evaluacionInicial.valorProbabilidad,
        );

        _severidadSeleccionada = _buscarSeveridad(
          widget.detalle.evaluacionInicial.severidadId,
          valor: widget.detalle.evaluacionInicial.valorSeveridad,
        );

        // =========================================================
        // EVALUACIÓN RESIDUAL
        // =========================================================

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
      // ---------------------------------------------------------
      // IMPORTANTE
      // ---------------------------------------------------------
      //
      // Ya NO modificamos EvaluacionRiesgo directamente.
      //
      // Flutter envía:
      //
      // - Probabilidad inicial.
      // - Severidad inicial.
      // - Probabilidad residual.
      // - Severidad residual.
      //
      // El backend crea/recalcula las evaluaciones.

      final ActualizarDetalleIpercRequest request =
          ActualizarDetalleIpercRequest(
            id: widget.detalle.id,

            matrizIpercId: widget.matriz.id,

            item: int.parse(_itemController.text.trim()),

            tarea: _tareaController.text,

            peligroId: _peligroSeleccionado!.id,

            consecuenciaId: _consecuenciaSeleccionada!.id,

            descripcionPeligro: _descripcionController.text,

            // -------------------------------------------------------
            // EVALUACIÓN INICIAL
            // -------------------------------------------------------
            probabilidadInicialId: _probabilidadSeleccionada!.id,

            severidadInicialId: _severidadSeleccionada!.id,

            observacionesEvaluacionInicial:
                widget.detalle.evaluacionInicial.observaciones,

            // -------------------------------------------------------
            // EVALUACIÓN RESIDUAL
            // -------------------------------------------------------
            probabilidadResidualId: _registrarEvaluacionResidual
                ? _probabilidadResidualSeleccionada!.id
                : null,

            severidadResidualId: _registrarEvaluacionResidual
                ? _severidadResidualSeleccionada!.id
                : null,

            observacionesEvaluacionResidual: _registrarEvaluacionResidual
                ? widget.detalle.evaluacionResidual?.observaciones
                : null,

            // -------------------------------------------------------
            // CONTROLES
            // -------------------------------------------------------
            controlIds: _controlIdsSeleccionados.toList(growable: false),

            // -------------------------------------------------------
            // EPP
            // -------------------------------------------------------
            equipoProteccionIds: _equipoProteccionIdsSeleccionados.toList(
              growable: false,
            ),

            // -------------------------------------------------------
            // IMPLEMENTACIÓN
            // -------------------------------------------------------
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Detalle y evaluaciones actualizados correctamente.',
              ),
            ),
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
      appBar: AppBar(title: const Text('Editar peligro evaluado')),

      body: SafeArea(
        child: _cargandoCatalogos
            ? const Center(child: CircularProgressIndicator())
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

        children: <Widget>[
          // =====================================================
          // MATRIZ
          // =====================================================
          _ResumenMatriz(matriz: widget.matriz, detalle: widget.detalle),

          const SizedBox(height: 20),

          // =====================================================
          // IDENTIFICACIÓN
          // =====================================================
          Text(
            'Identificación del peligro',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _itemController,

            enabled: !bloqueado,

            keyboardType: TextInputType.number,

            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],

            decoration: const InputDecoration(
              labelText: 'Ítem *',
              prefixIcon: Icon(Icons.tag_outlined),
              border: OutlineInputBorder(),
            ),

            validator: _validarEnteroObligatorio,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _tareaController,

            enabled: !bloqueado,

            textCapitalization: TextCapitalization.sentences,

            maxLength: 250,

            decoration: const InputDecoration(
              labelText: 'Tarea *',
              prefixIcon: Icon(Icons.work_outline),
              border: OutlineInputBorder(),
            ),

            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa la tarea que será evaluada.';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          // =====================================================
          // PELIGRO
          // =====================================================
          DropdownButtonFormField<PeligroModel>(
            initialValue: _peligroSeleccionado,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Peligro *',
              prefixIcon: Icon(Icons.warning_amber_outlined),
              border: OutlineInputBorder(),
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

          const SizedBox(height: 16),

          // =====================================================
          // CONSECUENCIA
          // =====================================================
          DropdownButtonFormField<ConsecuenciaModel>(
            initialValue: _consecuenciaSeleccionada,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Consecuencia *',
              prefixIcon: Icon(Icons.report_problem_outlined),
              border: OutlineInputBorder(),
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
              return value == null ? 'Selecciona una consecuencia.' : null;
            },
          ),

          const SizedBox(height: 16),

          // =====================================================
          // DESCRIPCIÓN
          // =====================================================
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
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          // =====================================================
          // EVALUACIÓN INICIAL
          // =====================================================
          Text(
            'Evaluación inicial del riesgo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<ProbabilidadModel>(
            initialValue: _probabilidadSeleccionada,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Probabilidad *',
              prefixIcon: Icon(Icons.trending_up_outlined),
              border: OutlineInputBorder(),
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

          const SizedBox(height: 12),

          DropdownButtonFormField<SeveridadModel>(
            initialValue: _severidadSeleccionada,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Severidad *',
              prefixIcon: Icon(Icons.priority_high_outlined),
              border: OutlineInputBorder(),
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

          // -----------------------------------------------------
          // RESULTADO INICIAL AUTOMÁTICO
          // -----------------------------------------------------
          if (_probabilidadSeleccionada != null &&
              _severidadSeleccionada != null) ...<Widget>[
            const SizedBox(height: 12),

            _ResumenEvaluacionRiesgo(
              probabilidad: _probabilidadSeleccionada!,
              severidad: _severidadSeleccionada!,
            ),
          ],

          const SizedBox(height: 20),

          // =====================================================
          // CONTROLES
          // =====================================================
          _SelectorControles(
            controles: _controles,
            seleccionados: _controlIdsSeleccionados,
            habilitado: !bloqueado,
            onChanged: _alternarControl,
          ),

          const SizedBox(height: 20),

          // =====================================================
          // EPP
          // =====================================================
          _SelectorEquiposProteccion(
            equipos: _equiposProteccion,
            seleccionados: _equipoProteccionIdsSeleccionados,
            habilitado: !bloqueado,
            onChanged: _alternarEquipoProteccion,
          ),

          const SizedBox(height: 20),

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

          // =====================================================
          // COMPARACIÓN INICIAL / RESIDUAL
          // =====================================================
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

          const SizedBox(height: 20),

          // =====================================================
          // IMPLEMENTACIÓN
          // =====================================================
          Text(
            'Implementación de medidas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (usuarioProvider.cargando)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          if (usuarioProvider.error != null)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(usuarioProvider.error!),
                trailing: IconButton(
                  tooltip: 'Reintentar',
                  onPressed: bloqueado
                      ? null
                      : () => usuarioProvider.cargarUsuarios(),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),

          // =====================================================
          // RESPONSABLE
          // =====================================================
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

            decoration: const InputDecoration(
              labelText: 'Responsable de implementación *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
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

          const SizedBox(height: 12),

          // =====================================================
          // FECHA COMPROMISO
          // =====================================================
          _CampoFecha(
            etiqueta: 'Fecha de compromiso *',

            fecha: _fechaCompromiso,

            habilitado: !bloqueado,

            icono: Icons.event_outlined,

            errorTexto: _mostrarErroresGestion && _fechaCompromiso == null
                ? 'Selecciona la fecha de compromiso.'
                : null,

            onSeleccionar: () => _seleccionarFecha(tipo: _TipoFecha.compromiso),

            onLimpiar: null,
          ),

          const SizedBox(height: 12),

          // =====================================================
          // FECHA IMPLEMENTACIÓN
          // =====================================================
          _CampoFecha(
            etiqueta:
                _estadoImplementacion >= EstadoImplementacionIperc.implementado
                ? 'Fecha de implementación *'
                : 'Fecha de implementación',

            fecha: _fechaImplementacion,

            habilitado: !bloqueado,

            icono: Icons.event_available_outlined,

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

          const SizedBox(height: 12),

          // =====================================================
          // ESTADO
          // =====================================================
          DropdownButtonFormField<int>(
            initialValue: _estadoImplementacion,

            decoration: const InputDecoration(
              labelText: 'Estado de implementación',
              prefixIcon: Icon(Icons.task_alt_outlined),
              border: OutlineInputBorder(),
            ),

            items: EstadoImplementacionIperc.valores.map((int estado) {
              return DropdownMenuItem<int>(
                value: estado,
                child: Text(EstadoImplementacionIperc.obtenerNombre(estado)),
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

                      if (value < EstadoImplementacionIperc.implementado) {
                        _fechaImplementacion = null;
                      }
                    });
                  },
          ),

          const SizedBox(height: 24),

          // =====================================================
          // GUARDAR
          // =====================================================
          FilledButton.icon(
            onPressed: bloqueado ? null : _guardar,

            icon: bloqueado
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),

            label: Text(bloqueado ? 'Guardando...' : 'Guardar cambios'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: bloqueado
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // BUSCAR PELIGRO
  // =============================================================

  PeligroModel? _buscarPeligro(int id) {
    for (final PeligroModel peligro in _peligros) {
      if (peligro.id == id) {
        return peligro;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR CONSECUENCIA
  // =============================================================

  ConsecuenciaModel? _buscarConsecuencia(int id) {
    for (final ConsecuenciaModel consecuencia in _consecuencias) {
      if (consecuencia.id == id) {
        return consecuencia;
      }
    }

    return null;
  }

  // =============================================================
  // BUSCAR PROBABILIDAD
  // =============================================================

  ProbabilidadModel? _buscarProbabilidad(int id, {int? valor}) {
    // Primero busca por ID real de MySQL.
    for (final ProbabilidadModel opcion in _probabilidades) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    // Compatibilidad con registros antiguos.
    if (valor != null && valor > 0) {
      return _probabilidadRepository.obtenerPorValor(_probabilidades, valor);
    }

    return null;
  }

  // =============================================================
  // BUSCAR SEVERIDAD
  // =============================================================

  SeveridadModel? _buscarSeveridad(int id, {int? valor}) {
    // Primero busca por ID real de MySQL.
    for (final SeveridadModel opcion in _severidades) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    // Compatibilidad con registros antiguos.
    if (valor != null && valor > 0) {
      return _severidadRepository.obtenerPorValor(_severidades, valor);
    }

    return null;
  }

  // =============================================================
  // ERROR FECHA IMPLEMENTACIÓN
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
  // SELECCIONAR FECHA
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

  // =============================================================
  // SOLO FECHA
  // =============================================================

  static DateTime? _soloFecha(DateTime? fecha) {
    if (fecha == null) {
      return null;
    }

    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  // =============================================================
  // VALIDAR ENTERO
  // =============================================================

  String? _validarEnteroObligatorio(String? value) {
    final int? id = int.tryParse(value?.trim() ?? '');

    if (id == null || id <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

  // =============================================================
  // CONTROLES
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

  // =============================================================
  // EPP
  // =============================================================

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
  // MENSAJE
  // =============================================================

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,

          content: Text(mensaje),
        ),
      );
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

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
    required this.errorTexto,
    required this.onSeleccionar,
    required this.onLimpiar,
  });

  final String etiqueta;

  final DateTime? fecha;

  final bool habilitado;

  final IconData icono;

  final String? errorTexto;

  final VoidCallback onSeleccionar;

  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: habilitado ? onSeleccionar : null,

      borderRadius: BorderRadius.circular(4),

      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,

          prefixIcon: Icon(icono),

          suffixIcon: onLimpiar == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Limpiar fecha',
                  onPressed: habilitado ? onLimpiar : null,
                  icon: const Icon(Icons.clear),
                ),

          border: const OutlineInputBorder(),

          errorText: errorTexto,

          enabled: habilitado,
        ),

        child: Text(
          fecha == null
              ? 'Seleccionar fecha'
              : '${fecha!.day.toString().padLeft(2, '0')}/'
                    '${fecha!.month.toString().padLeft(2, '0')}/'
                    '${fecha!.year}',
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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: colors.primaryContainer,

            child: Text(
              detalle.item > 0 ? detalle.item.toString() : '-',

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: <Widget>[
                Text(
                  matriz.codigo,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  matriz.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
// RESUMEN AUTOMÁTICO DE RIESGO
// ===============================================================

/// Calcula y muestra el riesgo automáticamente.
///
/// Se utiliza tanto para:
///
/// - Evaluación inicial.
/// - Evaluación residual.
///
/// Fórmula:
///
/// Riesgo = Probabilidad x Severidad
class _ResumenEvaluacionRiesgo extends StatelessWidget {
  const _ResumenEvaluacionRiesgo({
    required this.probabilidad,
    required this.severidad,
  });

  final ProbabilidadModel probabilidad;

  final SeveridadModel severidad;

  @override
  Widget build(BuildContext context) {
    // ===========================================================
    // CÁLCULO DEL RIESGO
    // ===========================================================
    //
    // IMPORTANTE:
    //
    // Para calcular utilizamos VALOR.
    //
    // Ejemplo:
    //
    // Probabilidad:
    // id real = 24
    // valor = 4
    //
    // Severidad:
    // id real = 35
    // valor = 5
    //
    // Cálculo:
    //
    // 4 × 5 = 20
    //
    // Al guardar, en cambio, Flutter enviará
    // los IDs reales 24 y 35.

    final int valor = probabilidad.valor * severidad.valor;

    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    final Color color = _colorDesdeHex(nivel.colorHex);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),

        border: Border.all(color: color),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: color,

                foregroundColor: Colors.white,

                child: Text(
                  valor.toString(),

                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: <Widget>[
                    Text(
                      'Nivel ${nivel.nombre}',

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      nivel.aceptable
                          ? 'Riesgo aceptable con seguimiento.'
                          : 'Requiere controles y seguimiento.',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Cálculo: '
            '${probabilidad.valor} × '
            '${severidad.valor} = '
            '$valor',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            'Probabilidad: '
            '${probabilidad.textoSeleccion}',
          ),

          Text(
            'Severidad: '
            '${severidad.textoSeleccion}',
          ),
        ],
      ),
    );
  }

  Color _colorDesdeHex(String hex) {
    final String limpio = hex.replaceAll('#', '').trim();

    final String completo = limpio.length == 6 ? 'FF$limpio' : limpio;

    final int? valor = int.tryParse(completo, radix: 16);

    return valor == null ? Colors.grey : Color(valor);
  }
}

// ===============================================================
// EVALUACIÓN RESIDUAL
// ===============================================================

/// Sección para registrar el riesgo que queda
/// después de aplicar controles y EPP.
///
/// Al seleccionar:
///
/// - Probabilidad residual.
/// - Severidad residual.
///
/// el riesgo residual aparece AUTOMÁTICAMENTE.
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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.35),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: colors.outlineVariant),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,

            secondary: const Icon(Icons.trending_down_outlined),

            title: const Text(
              'Evaluación residual',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            subtitle: const Text(
              'Actívala después de seleccionar '
              'los controles y EPP aplicados.',
            ),

            value: activa,

            onChanged: bloqueada ? null : onActivar,
          ),

          if (activa) ...<Widget>[
            const SizedBox(height: 12),

            // ================================================
            // PROBABILIDAD RESIDUAL
            // ================================================
            DropdownButtonFormField<ProbabilidadModel>(
              initialValue: probabilidad,

              isExpanded: true,

              decoration: InputDecoration(
                labelText: 'Probabilidad residual *',

                prefixIcon: const Icon(Icons.trending_up_outlined),

                border: const OutlineInputBorder(),

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

            const SizedBox(height: 12),

            // ================================================
            // SEVERIDAD RESIDUAL
            // ================================================
            DropdownButtonFormField<SeveridadModel>(
              initialValue: severidad,

              isExpanded: true,

              decoration: InputDecoration(
                labelText: 'Severidad residual *',

                prefixIcon: const Icon(Icons.priority_high_outlined),

                border: const OutlineInputBorder(),

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

            // ================================================
            // RESULTADO
            // ================================================
            if (probabilidad != null && severidad != null) ...<Widget>[
              const SizedBox(height: 12),

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
// COMPARACIÓN DE EVALUACIONES
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
        ? Colors.green
        : seMantuvo
        ? Colors.orange
        : Theme.of(context).colorScheme.error;

    final String mensaje = mejoro
        ? 'Los controles reducen el riesgo en '
              '$reduccion punto(s).'
        : seMantuvo
        ? 'El riesgo no cambió después de los controles.'
        : 'El riesgo residual es mayor. '
              'Revisa los controles aplicados.';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),

        border: Border.all(color: color),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          const Text(
            'Comparación del riesgo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

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
                child: Icon(Icons.arrow_forward),
              ),

              Expanded(
                child: _ValorComparacion(
                  etiqueta: 'Residual',
                  valor: valorResidual,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: <Widget>[
              Icon(
                mejoro ? Icons.check_circle_outline : Icons.info_outline,

                color: color,
              ),

              const SizedBox(width: 8),

              Expanded(child: Text(mensaje)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// VALOR COMPARACIÓN
// ===============================================================

class _ValorComparacion extends StatelessWidget {
  const _ValorComparacion({required this.etiqueta, required this.valor});

  final String etiqueta;

  final int valor;

  @override
  Widget build(BuildContext context) {
    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);

    return Column(
      children: <Widget>[
        Text(etiqueta),

        const SizedBox(height: 4),

        Text(
          valor.toString(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        Text(nivel.nombre),
      ],
    );
  }
}

// ===============================================================
// SELECTOR CONTROLES
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
      titulo: 'Controles aplicables',

      subtitulo: controles.isEmpty
          ? 'No hay controles activos registrados.'
          : 'Selecciona uno o más controles para reducir el riesgo.',

      icono: Icons.security_outlined,

      chips: controles.map((ControlModel control) {
        return FilterChip(
          selected: seleccionados.contains(control.id),

          label: Text(control.nombreCompleto),

          onSelected: habilitado ? (_) => onChanged(control.id) : null,
        );
      }).toList(),
    );
  }
}

// ===============================================================
// SELECTOR EPP
// ===============================================================

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
      titulo: 'Equipos de protección',

      subtitulo: equipos.isEmpty
          ? 'No hay EPP activos registrados.'
          : 'Selecciona los EPP requeridos para esta tarea.',

      icono: Icons.health_and_safety_outlined,

      chips: equipos.map((EquipoProteccionModel equipo) {
        return FilterChip(
          selected: seleccionados.contains(equipo.id),

          label: Text(equipo.nombreCompleto),

          onSelected: habilitado ? (_) => onChanged(equipo.id) : null,
        );
      }).toList(),
    );
  }
}

// ===============================================================
// SELECTOR MÚLTIPLE
// ===============================================================

class _SelectorMultipleCatalogo extends StatelessWidget {
  const _SelectorMultipleCatalogo({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.chips,
  });

  final String titulo;

  final String subtitulo;

  final IconData icono;

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: <Widget>[
            Icon(icono, color: Theme.of(context).colorScheme.primary),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: <Widget>[
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 2),

                  Text(subtitulo),
                ],
              ),
            ),
          ],
        ),

        if (chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),

          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,

              size: 64,

              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(height: 16),

            Text(
              'No se pudieron cargar los catálogos',

              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),

              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(mensaje, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onReintentar,

              icon: const Icon(Icons.refresh),

              label: const Text('Volver a intentar'),
            ),
          ],
        ),
      ),
    );
  }
}
