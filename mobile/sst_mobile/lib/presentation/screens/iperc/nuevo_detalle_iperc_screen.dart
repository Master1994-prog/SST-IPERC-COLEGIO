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

import '../../../data/repositories/consecuencia_repository.dart';
import '../../../data/repositories/control_repository.dart';
import '../../../data/repositories/equipo_proteccion_repository.dart';
import '../../../data/repositories/peligro_repository.dart';
import '../../../data/repositories/probabilidad_repository.dart';
import '../../../data/repositories/severidad_repository.dart';

import '../../providers/detalle_iperc_provider.dart';

/// ===============================================================
/// NUEVO DETALLE IPERC
/// ===============================================================
///
/// Permite agregar un peligro evaluado a una Matriz IPERC.
///
/// IMPORTANTE:
///
/// Probabilidad y Severidad se cargan desde el backend.
///
/// Cada registro contiene:
///
/// - id   -> identificador REAL de MySQL.
/// - valor -> valor 1..5 usado para calcular el riesgo.
///
/// Ejemplo:
///
/// Probabilidad:
/// id = 24
/// valor = 4
///
/// Severidad:
/// id = 35
/// valor = 5
///
/// Cálculo:
///
/// 4 × 5 = 20
///
/// Al guardar:
///
/// probabilidadInicialId = 24
/// severidadInicialId = 35
///
/// De esta manera evitamos confundir el valor de la escala
/// con el identificador real de la base de datos.
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
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _peligroRepository.obtenerActivos(),
          _consecuenciaRepository.obtenerActivos(),
          _controlRepository.obtenerActivos(),
          _equipoProteccionRepository.obtenerActivos(),

          // =====================================================
          // PROBABILIDADES Y SEVERIDADES REALES
          // =====================================================
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
      // =========================================================
      // IMPORTANTE
      // =========================================================
      //
      // Para calcular visualmente usamos:
      //
      // probabilidad.valor
      // severidad.valor
      //
      // Pero para guardar enviamos:
      //
      // probabilidad.id
      // severidad.id
      //
      // Esos IDs vienen directamente de MySQL.

      final CrearDetalleIpercRequest request = CrearDetalleIpercRequest(
        matrizIpercId: widget.matriz.id,

        item: int.parse(_itemController.text.trim()),

        tarea: _tareaController.text,

        peligroId: _peligroSeleccionado!.id,

        consecuenciaId: _consecuenciaSeleccionada!.id,

        descripcionPeligro: _descripcionController.text,

        // =======================================================
        // EVALUACIÓN INICIAL
        // =======================================================
        probabilidadInicialId: _probabilidadSeleccionada!.id,

        severidadInicialId: _severidadSeleccionada!.id,

        observacionesEvaluacionInicial:
            'Evaluación inicial registrada desde Detalle IPERC.',

        // =======================================================
        // CONTROLES
        // =======================================================
        controlIds: _controlIdsSeleccionados.toList(growable: false),

        // =======================================================
        // EPP
        // =======================================================
        equipoProteccionIds: _equipoProteccionIdsSeleccionados.toList(
          growable: false,
        ),

        // =======================================================
        // IMPLEMENTACIÓN
        // =======================================================
        estadoImplementacion: _estadoImplementacion,
      );

      final bool registrado = await provider.crear(request);

      if (!mounted) {
        return;
      }

      if (registrado) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Peligro evaluado registrado correctamente.'),
            ),
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
      appBar: AppBar(title: const Text('Agregar peligro evaluado')),

      body: SafeArea(
        child: _cargandoCatalogos
            ? const Center(child: CircularProgressIndicator())
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

        children: <Widget>[
          // =====================================================
          // MATRIZ
          // =====================================================
          _ResumenMatriz(matriz: widget.matriz),

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

          // =====================================================
          // ITEM
          // =====================================================
          TextFormField(
            controller: _itemController,

            enabled: !bloqueado,

            keyboardType: TextInputType.number,

            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],

            decoration: const InputDecoration(
              labelText: 'Ítem *',

              helperText: 'Se propone automáticamente el siguiente número.',

              prefixIcon: Icon(Icons.tag_outlined),

              border: OutlineInputBorder(),
            ),

            validator: _validarEnteroObligatorio,
          ),

          const SizedBox(height: 12),

          // =====================================================
          // TAREA
          // =====================================================
          TextFormField(
            controller: _tareaController,

            enabled: !bloqueado,

            textCapitalization: TextCapitalization.sentences,

            maxLength: 250,

            decoration: const InputDecoration(
              labelText: 'Tarea *',

              hintText: 'Ejemplo: Limpiar el aula de innovación',

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

          if (_peligros.isEmpty)
            const _AdvertenciaCatalogo(
              mensaje:
                  'No existen peligros activos. '
                  'Registra uno antes de continuar.',
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

          if (_consecuencias.isEmpty)
            const _AdvertenciaCatalogo(
              mensaje:
                  'No existen consecuencias activas. '
                  'Registra una antes de continuar.',
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

              hintText: 'Describe cómo se presenta el peligro en esta tarea.',

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

          // =====================================================
          // PROBABILIDAD
          // =====================================================
          _SelectorProbabilidad(
            probabilidades: _probabilidades,

            seleccionada: _probabilidadSeleccionada,

            habilitado: !bloqueado,

            mostrarError:
                _mostrarErroresEvaluacion && _probabilidadSeleccionada == null,

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

          const SizedBox(height: 12),

          // =====================================================
          // SEVERIDAD
          // =====================================================
          _SelectorSeveridad(
            severidades: _severidades,

            seleccionada: _severidadSeleccionada,

            habilitado: !bloqueado,

            mostrarError:
                _mostrarErroresEvaluacion && _severidadSeleccionada == null,

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

          // =====================================================
          // RESULTADO DEL RIESGO
          // =====================================================
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

          const SizedBox(height: 12),

          // =====================================================
          // ESTADO IMPLEMENTACIÓN
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
                    });
                  },
          ),

          const SizedBox(height: 24),

          // =====================================================
          // GUARDAR
          // =====================================================
          FilledButton.icon(
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),

            label: Text(bloqueado ? 'Guardando...' : 'Guardar peligro'),
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
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

// ===============================================================
// RESUMEN MATRIZ
// ===============================================================

class _ResumenMatriz extends StatelessWidget {
  const _ResumenMatriz({required this.matriz});

  final MatrizIpercModel matriz;

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

            child: const Icon(Icons.assignment_outlined),
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
// ADVERTENCIA CATÁLOGO
// ===============================================================

class _AdvertenciaCatalogo extends StatelessWidget {
  const _AdvertenciaCatalogo({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),

      child: Text(
        mensaje,

        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

// ===============================================================
// SELECTOR DE PROBABILIDAD
// ===============================================================

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

      mostrarError: mostrarError,

      mensajeError: 'Selecciona la probabilidad.',

      opciones: probabilidades
          .map((ProbabilidadModel opcion) {
            return ChoiceChip(
              // Se compara por ID REAL.
              selected: seleccionada?.id == opcion.id,

              showCheckmark: true,

              avatar: CircleAvatar(child: Text(opcion.valor.toString())),

              label: Text(opcion.nombre),

              onSelected: habilitado ? (_) => onChanged(opcion) : null,
            );
          })
          .toList(growable: false),

      detalleSeleccionado: seleccionada?.descripcion,
    );
  }
}

// ===============================================================
// SELECTOR DE SEVERIDAD
// ===============================================================

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

      mostrarError: mostrarError,

      mensajeError: 'Selecciona la severidad.',

      opciones: severidades
          .map((SeveridadModel opcion) {
            return ChoiceChip(
              // Se compara por ID REAL.
              selected: seleccionada?.id == opcion.id,

              showCheckmark: true,

              avatar: CircleAvatar(child: Text(opcion.valor.toString())),

              label: Text(opcion.nombre),

              onSelected: habilitado ? (_) => onChanged(opcion) : null,
            );
          })
          .toList(growable: false),

      detalleSeleccionado: seleccionada?.descripcion,
    );
  }
}

// ===============================================================
// TARJETA SELECTOR ESCALA
// ===============================================================

class _TarjetaSelectorEscala extends StatelessWidget {
  const _TarjetaSelectorEscala({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.mostrarError,
    required this.mensajeError,
    required this.opciones,
    required this.detalleSeleccionado,
  });

  final String titulo;

  final String descripcion;

  final IconData icono;

  final bool mostrarError;

  final String mensajeError;

  final List<Widget> opciones;

  final String? detalleSeleccionado;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        border: Border.all(
          color: mostrarError ? colors.error : colors.outlineVariant,
        ),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icono, color: colors.primary),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: <Widget>[
                    Text(
                      titulo,

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Text(
                      descripcion,

                      style: Theme.of(context).textTheme.bodySmall,
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

            Text(
              detalleSeleccionado!,

              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          if (mostrarError) ...<Widget>[
            const SizedBox(height: 8),

            Text(
              mensajeError,

              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ===============================================================
// RESUMEN EVALUACIÓN DE RIESGO
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
    // ===========================================================
    // CÁLCULO
    // ===========================================================
    //
    // Aquí usamos los VALORES 1..5.
    //
    // NO usamos los IDs de MySQL.

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

    if (valor == null) {
      return Colors.grey;
    }

    return Color(valor);
  }
}

// ===============================================================
// SELECTOR DE CONTROLES
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
// SELECTOR DE EPP
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
