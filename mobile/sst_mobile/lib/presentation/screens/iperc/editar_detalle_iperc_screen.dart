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
import '../../../data/models/usuario_model.dart';
import '../../../data/repositories/consecuencia_repository.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/equipo_proteccion_repository.dart';
import '../../../data/repositories/evaluacion_riesgo_repository.dart';
import '../../../data/repositories/peligro_repository.dart';
import '../../providers/detalle_iperc_provider.dart';
import '../../providers/usuario_provider.dart';

/// Formulario completo para editar una fila registrada en la Matriz IPERC.
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

  final PeligroRepository _peligroRepository = PeligroRepository();
  final ConsecuenciaRepository _consecuenciaRepository =
      ConsecuenciaRepository();
  final ControlRepository _controlRepository = ControlRepository();
  final EquipoProteccionRepository _equipoProteccionRepository =
      EquipoProteccionRepository();
  final EvaluacionRiesgoRepository _evaluacionRiesgoRepository =
      EvaluacionRiesgoRepository();

  List<PeligroModel> _peligros = <PeligroModel>[];
  List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];
  List<ControlModel> _controles = <ControlModel>[];
  List<EquipoProteccionModel> _equiposProteccion = <EquipoProteccionModel>[];

  PeligroModel? _peligroSeleccionado;
  ConsecuenciaModel? _consecuenciaSeleccionada;

  // Valores de la evaluación antes de aplicar controles.
  ProbabilidadIpercOption? _probabilidadSeleccionada;
  SeveridadIpercOption? _severidadSeleccionada;

  // Valores de la evaluación después de aplicar controles.
  ProbabilidadIpercOption? _probabilidadResidualSeleccionada;
  SeveridadIpercOption? _severidadResidualSeleccionada;
  bool _registrarEvaluacionResidual = false;

  final Set<int> _controlIdsSeleccionados = <int>{};
  final Set<int> _equipoProteccionIdsSeleccionados = <int>{};
  int _estadoImplementacion = EstadoImplementacionIperc.pendiente;
  int? _responsableImplementacionId;
  DateTime? _fechaCompromiso;
  DateTime? _fechaImplementacion;

  bool _mostrarErroresGestion = false;
  bool _cargandoCatalogos = true;
  bool _guardando = false;
  bool _mostrarErroresResidual = false;
  String? _errorCarga;

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

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCarga = null;
    });

    try {
      final Future<EvaluacionRiesgoModel?> evaluacionResidualFuture =
          widget.detalle.tieneEvaluacionResidual
          ? _evaluacionRiesgoRepository
                .obtenerPorId(widget.detalle.evaluacionResidualId!)
                .then<EvaluacionRiesgoModel?>(
                  (EvaluacionRiesgoModel evaluacion) => evaluacion,
                )
          : Future<EvaluacionRiesgoModel?>.value(null);

      final List<dynamic> resultados =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _peligroRepository.obtenerActivos(),
            _consecuenciaRepository.obtenerActivos(),
            _controlRepository.obtenerActivos(),
            _equipoProteccionRepository.obtenerActivos(),
            _evaluacionRiesgoRepository.obtenerPorId(
              widget.detalle.evaluacionInicialId,
            ),
            evaluacionResidualFuture,
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
      final List<EquipoProteccionModel> equiposProteccion =
          (resultados[3] as List<dynamic>)
              .whereType<EquipoProteccionModel>()
              .toList();
      final EvaluacionRiesgoModel evaluacion =
          resultados[4] as EvaluacionRiesgoModel;
      final EvaluacionRiesgoModel? evaluacionResidual =
          resultados[5] as EvaluacionRiesgoModel?;

      setState(() {
        _peligros = peligros;
        _consecuencias = consecuencias;
        _controles = controles;
        _equiposProteccion = equiposProteccion;
        _peligroSeleccionado = _buscarPeligro(widget.detalle.peligroId);
        _consecuenciaSeleccionada = _buscarConsecuencia(
          widget.detalle.consecuenciaId,
        );
        _probabilidadSeleccionada = _buscarProbabilidad(
          evaluacion.probabilidadId,
        );
        _severidadSeleccionada = _buscarSeveridad(evaluacion.severidadId);
        _probabilidadResidualSeleccionada = evaluacionResidual == null
            ? null
            : _buscarProbabilidad(evaluacionResidual.probabilidadId);
        _severidadResidualSeleccionada = evaluacionResidual == null
            ? null
            : _buscarSeveridad(evaluacionResidual.severidadId);
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
      // 1. Actualizamos la evaluación inicial existente.
      final int valorRiesgo =
          _probabilidadSeleccionada!.valor * _severidadSeleccionada!.valor;
      final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valorRiesgo);

      await _evaluacionRiesgoRepository.actualizar(
        widget.detalle.evaluacionInicialId,
        ActualizarEvaluacionRiesgoRequest(
          probabilidadId: _probabilidadSeleccionada!.id,
          severidadId: _severidadSeleccionada!.id,
          nivelRiesgoId: nivel.id,
          observaciones:
              'Evaluacion inicial actualizada desde el detalle IPERC.',
        ),
      );

      // 2. Si se activó la evaluación residual, la actualizamos o la creamos.
      int? evaluacionResidualId;

      if (_registrarEvaluacionResidual) {
        final int valorResidual =
            _probabilidadResidualSeleccionada!.valor *
            _severidadResidualSeleccionada!.valor;
        final NivelRiesgoIpercOption nivelResidual = obtenerNivelRiesgoIperc(
          valorResidual,
        );

        if (widget.detalle.tieneEvaluacionResidual) {
          evaluacionResidualId = widget.detalle.evaluacionResidualId;

          await _evaluacionRiesgoRepository.actualizar(
            evaluacionResidualId!,
            ActualizarEvaluacionRiesgoRequest(
              probabilidadId: _probabilidadResidualSeleccionada!.id,
              severidadId: _severidadResidualSeleccionada!.id,
              nivelRiesgoId: nivelResidual.id,
              observaciones:
                  'Evaluacion residual actualizada desde el detalle IPERC.',
            ),
          );
        } else {
          final EvaluacionRiesgoModel evaluacionResidual =
              await _evaluacionRiesgoRepository.crear(
                CrearEvaluacionRiesgoRequest(
                  probabilidadId: _probabilidadResidualSeleccionada!.id,
                  severidadId: _severidadResidualSeleccionada!.id,
                  nivelRiesgoId: nivelResidual.id,
                  observaciones:
                      'Evaluacion residual generada desde el detalle IPERC.',
                ),
              );

          evaluacionResidualId = evaluacionResidual.id;
        }
      }

      // 3. Guardamos el detalle usando los IDs de evaluación internamente.
      final ActualizarDetalleIpercRequest request =
          ActualizarDetalleIpercRequest(
            matrizIpercId: widget.matriz.id,
            item: int.parse(_itemController.text.trim()),
            tarea: _tareaController.text,
            peligroId: _peligroSeleccionado!.id,
            consecuenciaId: _consecuenciaSeleccionada!.id,
            descripcionPeligro: _descripcionController.text,
            evaluacionInicialId: widget.detalle.evaluacionInicialId,
            evaluacionResidualId: evaluacionResidualId,
            controlIds: _controlIdsSeleccionados.toList(growable: false),
            equipoProteccionIds: _equipoProteccionIdsSeleccionados.toList(
              growable: false,
            ),
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
          _ResumenMatriz(matriz: widget.matriz, detalle: widget.detalle),
          const SizedBox(height: 20),
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
          Text(
            'Evaluación inicial del riesgo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProbabilidadIpercOption>(
            initialValue: _probabilidadSeleccionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Probabilidad *',
              prefixIcon: Icon(Icons.trending_up_outlined),
              border: OutlineInputBorder(),
            ),
            items: probabilidadesIperc.map((ProbabilidadIpercOption opcion) {
              return DropdownMenuItem<ProbabilidadIpercOption>(
                value: opcion,
                child: Text(opcion.etiqueta),
              );
            }).toList(),
            onChanged: bloqueado
                ? null
                : (ProbabilidadIpercOption? value) {
                    setState(() {
                      _probabilidadSeleccionada = value;
                    });
                  },
            validator: (ProbabilidadIpercOption? value) {
              return value == null ? 'Selecciona la probabilidad.' : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SeveridadIpercOption>(
            initialValue: _severidadSeleccionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Severidad *',
              prefixIcon: Icon(Icons.priority_high_outlined),
              border: OutlineInputBorder(),
            ),
            items: severidadesIperc.map((SeveridadIpercOption opcion) {
              return DropdownMenuItem<SeveridadIpercOption>(
                value: opcion,
                child: Text(opcion.etiqueta),
              );
            }).toList(),
            onChanged: bloqueado
                ? null
                : (SeveridadIpercOption? value) {
                    setState(() {
                      _severidadSeleccionada = value;
                    });
                  },
            validator: (SeveridadIpercOption? value) {
              return value == null ? 'Selecciona la severidad.' : null;
            },
          ),
          if (_probabilidadSeleccionada != null &&
              _severidadSeleccionada != null) ...<Widget>[
            const SizedBox(height: 12),
            _ResumenEvaluacionRiesgo(
              probabilidad: _probabilidadSeleccionada!,
              severidad: _severidadSeleccionada!,
            ),
          ],
          const SizedBox(height: 20),
          _SelectorControles(
            controles: _controles,
            seleccionados: _controlIdsSeleccionados,
            habilitado: !bloqueado,
            onChanged: _alternarControl,
          ),
          const SizedBox(height: 20),
          _SelectorEquiposProteccion(
            equipos: _equiposProteccion,
            seleccionados: _equipoProteccionIdsSeleccionados,
            habilitado: !bloqueado,
            onChanged: _alternarEquipoProteccion,
          ),
          const SizedBox(height: 20),

          // La evaluación residual representa el riesgo después de aplicar
          // los controles y EPP seleccionados.
          _SeccionEvaluacionResidual(
            activa: _registrarEvaluacionResidual,
            bloqueada: bloqueado,
            probabilidad: _probabilidadResidualSeleccionada,
            severidad: _severidadResidualSeleccionada,
            mostrarErrores: _mostrarErroresResidual,
            onActivar: (bool value) {
              setState(() {
                _registrarEvaluacionResidual = value;
                _mostrarErroresResidual = false;
              });
            },
            onProbabilidadChanged: (ProbabilidadIpercOption? value) {
              setState(() {
                _probabilidadResidualSeleccionada = value;
              });
            },
            onSeveridadChanged: (SeveridadIpercOption? value) {
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
          const SizedBox(height: 20),
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
          DropdownButtonFormField<int>(
            key: ValueKey<String>(
              'responsable-${_responsableImplementacionId ?? 0}-'
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

  ProbabilidadIpercOption? _buscarProbabilidad(int id) {
    for (final ProbabilidadIpercOption opcion in probabilidadesIperc) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    return null;
  }

  SeveridadIpercOption? _buscarSeveridad(int id) {
    for (final SeveridadIpercOption opcion in severidadesIperc) {
      if (opcion.id == id) {
        return opcion;
      }
    }

    return null;
  }

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

  static DateTime? _soloFecha(DateTime? fecha) {
    if (fecha == null) {
      return null;
    }

    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  String? _validarEnteroObligatorio(String? value) {
    final int? id = int.tryParse(value?.trim() ?? '');

    if (id == null || id <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

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

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

enum _TipoFecha { compromiso, implementacion }

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

class _ResumenEvaluacionRiesgo extends StatelessWidget {
  const _ResumenEvaluacionRiesgo({
    required this.probabilidad,
    required this.severidad,
  });

  final ProbabilidadIpercOption probabilidad;
  final SeveridadIpercOption severidad;

  @override
  Widget build(BuildContext context) {
    final int valor = probabilidad.valor * severidad.valor;
    final NivelRiesgoIpercOption nivel = obtenerNivelRiesgoIperc(valor);
    final Color color = _colorDesdeHex(nivel.colorHex);

    return Container(
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
          Text('Probabilidad: ${probabilidad.etiqueta}'),
          Text('Severidad: ${severidad.etiqueta}'),
        ],
      ),
    );
  }

  Color _colorDesdeHex(String hex) {
    final String limpio = hex.replaceAll('#', '').trim();
    final int? valor = int.tryParse('FF$limpio', radix: 16);
    return valor == null ? Colors.grey : Color(valor);
  }
}

/// Sección que permite registrar el riesgo que queda después de los controles.
class _SeccionEvaluacionResidual extends StatelessWidget {
  const _SeccionEvaluacionResidual({
    required this.activa,
    required this.bloqueada,
    required this.probabilidad,
    required this.severidad,
    required this.mostrarErrores,
    required this.onActivar,
    required this.onProbabilidadChanged,
    required this.onSeveridadChanged,
  });

  final bool activa;
  final bool bloqueada;
  final ProbabilidadIpercOption? probabilidad;
  final SeveridadIpercOption? severidad;
  final bool mostrarErrores;
  final ValueChanged<bool> onActivar;
  final ValueChanged<ProbabilidadIpercOption?> onProbabilidadChanged;
  final ValueChanged<SeveridadIpercOption?> onSeveridadChanged;

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
              'Actívala después de seleccionar los controles y EPP aplicados.',
            ),
            value: activa,
            onChanged: bloqueada ? null : onActivar,
          ),
          if (activa) ...<Widget>[
            const SizedBox(height: 12),
            DropdownButtonFormField<ProbabilidadIpercOption>(
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
              items: probabilidadesIperc.map((ProbabilidadIpercOption opcion) {
                return DropdownMenuItem<ProbabilidadIpercOption>(
                  value: opcion,
                  child: Text(opcion.etiqueta),
                );
              }).toList(),
              onChanged: bloqueada ? null : onProbabilidadChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SeveridadIpercOption>(
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
              items: severidadesIperc.map((SeveridadIpercOption opcion) {
                return DropdownMenuItem<SeveridadIpercOption>(
                  value: opcion,
                  child: Text(opcion.etiqueta),
                );
              }).toList(),
              onChanged: bloqueada ? null : onSeveridadChanged,
            ),
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

/// Compara el riesgo original con el riesgo posterior a los controles.
class _ComparacionEvaluaciones extends StatelessWidget {
  const _ComparacionEvaluaciones({
    required this.probabilidadInicial,
    required this.severidadInicial,
    required this.probabilidadResidual,
    required this.severidadResidual,
  });

  final ProbabilidadIpercOption probabilidadInicial;
  final SeveridadIpercOption severidadInicial;
  final ProbabilidadIpercOption probabilidadResidual;
  final SeveridadIpercOption severidadResidual;

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
        ? 'Los controles reducen el riesgo en $reduccion punto(s).'
        : seMantuvo
        ? 'El riesgo no cambió después de los controles.'
        : 'El riesgo residual es mayor. Revisa los controles aplicados.';

    return Container(
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
