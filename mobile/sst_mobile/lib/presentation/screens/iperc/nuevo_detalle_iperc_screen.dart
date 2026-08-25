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
import '../../../data/repositories/consecuencia_repository.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/equipo_proteccion_repository.dart';
import '../../../data/repositories/peligro_repository.dart';
import '../../../data/repositories/probabilidad_repository.dart';
import '../../../data/repositories/severidad_repository.dart';
import '../../providers/detalle_iperc_provider.dart';

/// ===============================================================
/// NUEVO DETALLE IPERC - SST EDURISK
/// ===============================================================
///
/// Permite agregar un peligro evaluado a una Matriz IPERC.
///
/// IMPORTANTE:
/// - Probabilidad y severidad se cargan desde el backend.
/// - Para el cálculo visual se utilizan los valores 1..5.
/// - Para guardar se utilizan los IDs reales de MySQL.
///
/// Colores oficiales SST EduRisk:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class NuevoDetalleIpercScreen extends StatefulWidget {
  const NuevoDetalleIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<NuevoDetalleIpercScreen> createState() {
    return _NuevoDetalleIpercScreenState();
  }
}

class _NuevoDetalleIpercScreenState extends State<NuevoDetalleIpercScreen> {
  // =============================================================
  // FORMULARIO
  // =============================================================

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

  final Set<int> _controlIdsSeleccionados = <int>{};

  final Set<int> _equipoProteccionIdsSeleccionados = <int>{};

  // =============================================================
  // IMPLEMENTACIÓN
  // =============================================================

  int _estadoImplementacion = EstadoImplementacionIperc.pendiente;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargandoCatalogos = true;

  bool _guardando = false;

  bool _mostrarErroresEvaluacion = false;

  String? _errorCarga;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _itemController.text = context
        .read<DetalleIpercProvider>()
        .siguienteItem
        .toString();

    _cargarCatalogos();
  }

  // =============================================================
  // DISPOSE
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

      probabilidades.sort((ProbabilidadModel a, ProbabilidadModel b) {
        return a.valor.compareTo(b.valor);
      });

      severidades.sort((SeveridadModel a, SeveridadModel b) {
        return a.valor.compareTo(b.valor);
      });

      setState(() {
        _peligros = peligros;
        _consecuencias = consecuencias;
        _controles = controles;
        _equiposProteccion = equipos;
        _probabilidades = probabilidades;
        _severidades = severidades;
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
      _mostrarErroresEvaluacion = true;
    });

    if (!formularioValido ||
        _probabilidadSeleccionada == null ||
        _severidadSeleccionada == null) {
      return;
    }

    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    setState(() {
      _guardando = true;
    });

    try {
      final CrearDetalleIpercRequest request = CrearDetalleIpercRequest(
        matrizIpercId: widget.matriz.id,
        item: int.parse(_itemController.text.trim()),
        tarea: _tareaController.text,
        peligroId: _peligroSeleccionado!.id,
        consecuenciaId: _consecuenciaSeleccionada!.id,
        descripcionPeligro: _descripcionController.text,

        // IDs REALES de MySQL.
        probabilidadInicialId: _probabilidadSeleccionada!.id,
        severidadInicialId: _severidadSeleccionada!.id,

        observacionesEvaluacionInicial:
            'Evaluación inicial registrada desde Detalle IPERC.',

        controlIds: _controlIdsSeleccionados.toList(growable: false),

        equipoProteccionIds: _equipoProteccionIdsSeleccionados.toList(
          growable: false,
        ),

        estadoImplementacion: _estadoImplementacion,
      );

      final bool registrado = await provider.crear(request);

      if (!mounted) {
        return;
      }

      if (registrado) {
        _mostrarMensaje(
          'Peligro evaluado registrado correctamente.',
          esError: false,
        );

        Navigator.of(context).pop(true);

        return;
      }

      _mostrarMensaje(
        provider.error ?? 'No se pudo registrar el detalle IPERC.',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Agregar peligro evaluado'),
      ),
      body: SafeArea(
        child: _cargandoCatalogos
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _construirContenido(provider),
      ),
    );
  }

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido(DetalleIpercProvider provider) {
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
          // MATRIZ
          // =====================================================
          _ResumenMatriz(matriz: widget.matriz),

          const SizedBox(height: 18),

          // =====================================================
          // IDENTIFICACIÓN
          // =====================================================
          _SeccionFormulario(
            icono: Icons.warning_amber_outlined,
            titulo: 'Identificación del peligro',
            descripcion:
                'Registre la tarea, peligro, consecuencia '
                'y descripción específica.',
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
                    helperText:
                        'Se propone automáticamente el siguiente número.',
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
                    hintText: 'Ejemplo: Limpiar el aula de innovación',
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

                if (_peligros.isEmpty)
                  const _AdvertenciaCatalogo(
                    mensaje:
                        'No existen peligros activos. '
                        'Registra uno antes de continuar.',
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

                if (_consecuencias.isEmpty)
                  const _AdvertenciaCatalogo(
                    mensaje:
                        'No existen consecuencias activas. '
                        'Registra una antes de continuar.',
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
                    hintText:
                        'Describe cómo se presenta el peligro en esta tarea.',
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
                'Seleccione probabilidad y severidad. '
                'El sistema calculará automáticamente el nivel de riesgo.',
            color: AppColors.yellow,
            colorTexto: AppColors.navyDark,
            child: Column(
              children: <Widget>[
                _SelectorProbabilidad(
                  probabilidades: _probabilidades,
                  seleccionada: _probabilidadSeleccionada,
                  habilitado: !bloqueado,
                  mostrarError:
                      _mostrarErroresEvaluacion &&
                      _probabilidadSeleccionada == null,
                  onChanged: (ProbabilidadModel value) {
                    setState(() {
                      _probabilidadSeleccionada = value;
                    });
                  },
                ),

                if (_probabilidades.isEmpty)
                  const _AdvertenciaCatalogo(
                    mensaje:
                        'No existen probabilidades disponibles. '
                        'Verifica el catálogo del servidor.',
                  ),

                const SizedBox(height: 14),

                _SelectorSeveridad(
                  severidades: _severidades,
                  seleccionada: _severidadSeleccionada,
                  habilitado: !bloqueado,
                  mostrarError:
                      _mostrarErroresEvaluacion &&
                      _severidadSeleccionada == null,
                  onChanged: (SeveridadModel value) {
                    setState(() {
                      _severidadSeleccionada = value;
                    });
                  },
                ),

                if (_severidades.isEmpty)
                  const _AdvertenciaCatalogo(
                    mensaje:
                        'No existen severidades disponibles. '
                        'Verifica el catálogo del servidor.',
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
                'Seleccione las medidas de control necesarias para reducir el riesgo.',
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
            descripcion:
                'Seleccione los EPP requeridos para ejecutar la tarea de forma segura.',
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
          // IMPLEMENTACIÓN
          // =====================================================
          _SeccionFormulario(
            icono: Icons.task_alt_outlined,
            titulo: 'Estado de implementación',
            descripcion:
                'Indique el estado inicial de las medidas asociadas a este peligro.',
            color: AppColors.primary,
            child: DropdownButtonFormField<int>(
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
                      });
                    },
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
              onPressed:
                  bloqueado ||
                      _peligros.isEmpty ||
                      _consecuencias.isEmpty ||
                      _probabilidades.isEmpty ||
                      _severidades.isEmpty
                  ? null
                  : _guardar,
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
                bloqueado ? 'Guardando...' : 'Guardar peligro',
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
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

/// ===============================================================
/// RESUMEN MATRIZ
/// ===============================================================

class _ResumenMatriz extends StatelessWidget {
  const _ResumenMatriz({required this.matriz});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
              size: 31,
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
                const Text(
                  'Registro de peligro y evaluación inicial',
                  style: TextStyle(color: Color(0xFFDCEAFF), fontSize: 12),
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
/// SECCIÓN DEL FORMULARIO
/// ===============================================================

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

/// ===============================================================
/// ADVERTENCIA CATÁLOGO
/// ===============================================================

class _AdvertenciaCatalogo extends StatelessWidget {
  const _AdvertenciaCatalogo({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.riskOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.riskOrange.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.warning_amber_outlined,
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
      ),
    );
  }
}

/// ===============================================================
/// SELECTOR DE PROBABILIDAD
/// ===============================================================

class _SelectorProbabilidad extends StatelessWidget {
  const _SelectorProbabilidad({
    required this.probabilidades,
    required this.seleccionada,
    required this.habilitado,
    required this.mostrarError,
    required this.onChanged,
  });

  final List<ProbabilidadModel> probabilidades;

  final ProbabilidadModel? seleccionada;

  final bool habilitado;

  final bool mostrarError;

  final ValueChanged<ProbabilidadModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TarjetaSelectorEscala(
      titulo: 'Probabilidad *',
      descripcion: 'Marca una opción del 1 al 5.',
      icono: Icons.trending_up_outlined,
      color: AppColors.primaryBright,
      mostrarError: mostrarError,
      mensajeError: 'Selecciona la probabilidad.',
      opciones: probabilidades
          .map((ProbabilidadModel opcion) {
            final bool seleccionada = this.seleccionada?.id == opcion.id;

            return ChoiceChip(
              selected: seleccionada,
              showCheckmark: true,
              selectedColor: AppColors.primaryBright.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primary,
              avatar: CircleAvatar(
                backgroundColor: seleccionada
                    ? AppColors.primary
                    : AppColors.background,
                foregroundColor: seleccionada
                    ? Colors.white
                    : AppColors.primary,
                child: Text(
                  opcion.valor.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              label: Text(opcion.nombre),
              onSelected: habilitado ? (_) => onChanged(opcion) : null,
            );
          })
          .toList(growable: false),
      detalleSeleccionado: seleccionada?.descripcion,
    );
  }
}

/// ===============================================================
/// SELECTOR DE SEVERIDAD
/// ===============================================================

class _SelectorSeveridad extends StatelessWidget {
  const _SelectorSeveridad({
    required this.severidades,
    required this.seleccionada,
    required this.habilitado,
    required this.mostrarError,
    required this.onChanged,
  });

  final List<SeveridadModel> severidades;

  final SeveridadModel? seleccionada;

  final bool habilitado;

  final bool mostrarError;

  final ValueChanged<SeveridadModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TarjetaSelectorEscala(
      titulo: 'Severidad *',
      descripcion: 'Marca una opción del 1 al 5.',
      icono: Icons.priority_high_outlined,
      color: AppColors.riskOrange,
      mostrarError: mostrarError,
      mensajeError: 'Selecciona la severidad.',
      opciones: severidades
          .map((SeveridadModel opcion) {
            final bool seleccionada = this.seleccionada?.id == opcion.id;

            return ChoiceChip(
              selected: seleccionada,
              showCheckmark: true,
              selectedColor: AppColors.riskOrange.withValues(alpha: 0.15),
              checkmarkColor: AppColors.riskOrange,
              avatar: CircleAvatar(
                backgroundColor: seleccionada
                    ? AppColors.riskOrange
                    : AppColors.background,
                foregroundColor: seleccionada
                    ? Colors.white
                    : AppColors.riskOrange,
                child: Text(
                  opcion.valor.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              label: Text(opcion.nombre),
              onSelected: habilitado ? (_) => onChanged(opcion) : null,
            );
          })
          .toList(growable: false),
      detalleSeleccionado: seleccionada?.descripcion,
    );
  }
}

/// ===============================================================
/// TARJETA SELECTOR ESCALA
/// ===============================================================

class _TarjetaSelectorEscala extends StatelessWidget {
  const _TarjetaSelectorEscala({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.mostrarError,
    required this.mensajeError,
    required this.opciones,
    required this.detalleSeleccionado,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final bool mostrarError;
  final String mensajeError;
  final List<Widget> opciones;
  final String? detalleSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(
          color: mostrarError ? AppColors.riskOrange : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
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
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: opciones),
          if (detalleSeleccionado != null &&
              detalleSeleccionado!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                detalleSeleccionado!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (mostrarError) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              mensajeError,
              style: const TextStyle(
                color: AppColors.riskOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ===============================================================
/// RESUMEN EVALUACIÓN DE RIESGO
/// ===============================================================

class _ResumenEvaluacionRiesgo extends StatelessWidget {
  const _ResumenEvaluacionRiesgo({
    required this.probabilidad,
    required this.severidad,
  });

  final ProbabilidadModel probabilidad;
  final SeveridadModel severidad;

  @override
  Widget build(BuildContext context) {
    // Se usan los VALORES 1..5,
    // NO los IDs de MySQL.
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

/// ===============================================================
/// FILA DEL CÁLCULO
/// ===============================================================

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

/// ===============================================================
/// SELECTOR DE CONTROLES
/// ===============================================================

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

/// ===============================================================
/// SELECTOR DE EPP
/// ===============================================================

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

/// ===============================================================
/// SELECTOR MÚLTIPLE
/// ===============================================================

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

/// ===============================================================
/// ESTADO DE CARGA
/// ===============================================================

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
                  height: 1.4,
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

/// ===============================================================
/// COLOR DESDE HEX
/// ===============================================================

Color _colorDesdeHex(String hex) {
  final String limpio = hex.replaceAll('#', '').trim();

  final String completo = limpio.length == 6 ? 'FF$limpio' : limpio;

  final int? valor = int.tryParse(completo, radix: 16);

  if (valor == null) {
    return AppColors.textSecondary;
  }

  return Color(valor);
}

/// ===============================================================
/// CONTRASTE DE TEXTO
/// ===============================================================

Color _colorDeTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
