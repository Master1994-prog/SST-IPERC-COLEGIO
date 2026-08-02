import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/detalle_iperc_local_model.dart';
import '../../providers/detalle_iperc_offline_provider.dart';

/// Formulario para registrar o editar un detalle IPERC sin conexión.
class DetalleIpercFormScreen extends StatefulWidget {
  const DetalleIpercFormScreen({
    super.key,
    required this.matrizIdLocal,
    this.detalle,
  });

  /// Identificador local de la matriz IPERC.
  final String matrizIdLocal;

  /// Si contiene un detalle, el formulario funcionará en modo edición.
  final DetalleIpercLocalModel? detalle;

  bool get esEdicion => detalle != null;

  @override
  State<DetalleIpercFormScreen> createState() => _DetalleIpercFormScreenState();
}

class _DetalleIpercFormScreenState extends State<DetalleIpercFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _actividadController;
  late final TextEditingController _peligroController;
  late final TextEditingController _consecuenciaController;
  late final TextEditingController _controlController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _responsableController;

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
  ];

  @override
  void initState() {
    super.initState();

    final DetalleIpercLocalModel? detalle = widget.detalle;

    _actividadController = TextEditingController(
      text: detalle?.actividadDescripcion ?? '',
    );

    _peligroController = TextEditingController(
      text: detalle?.peligroDescripcion ?? '',
    );

    _consecuenciaController = TextEditingController(
      text: detalle?.consecuenciaDescripcion ?? '',
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
  }

  @override
  void dispose() {
    _actividadController.dispose();
    _peligroController.dispose();
    _consecuenciaController.dispose();
    _controlController.dispose();
    _observacionesController.dispose();
    _responsableController.dispose();

    super.dispose();
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

    if (valor <= 12) {
      return 'MEDIO';
    }

    return 'ALTO';
  }

  Color _obtenerColorRiesgo(int valor) {
    if (valor <= 4) {
      return Colors.green;
    }

    if (valor <= 12) {
      return Colors.amber.shade700;
    }

    return Colors.red;
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

    if (_registrarEvaluacionResidual &&
        (_severidadResidual == null || _frecuenciaResidual == null)) {
      _mostrarMensaje(
        'Complete la severidad y frecuencia residual.',
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
      actividadId: anterior?.actividadId,
      peligroId: anterior?.peligroId,
      consecuenciaId: anterior?.consecuenciaId,
      actividadDescripcion: _actividadController.text.trim(),
      peligroDescripcion: _peligroController.text.trim(),
      consecuenciaDescripcion: _consecuenciaController.text.trim(),
      severidadInicial: _severidadInicial,
      frecuenciaInicial: _frecuenciaInicial,
      valorRiesgoInicial: _valorRiesgoInicial,
      nivelRiesgoInicial: _obtenerNivelRiesgo(_valorRiesgoInicial),
      controlIds: anterior?.controlIds ?? const <String>[],
      equipoProteccionIds: anterior?.equipoProteccionIds ?? const <String>[],
      controlDescripcion: _textoOpcional(_controlController.text),
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

  String? _textoOpcional(String value) {
    final String texto = value.trim();
    return texto.isEmpty ? null : texto;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esEdicion ? 'Editar detalle IPERC' : 'Nuevo detalle IPERC',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _construirAvisoOffline(),
              const SizedBox(height: 20),
              _construirTituloSeccion(
                'Identificación del peligro',
                Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actividadController,
                enabled: !guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Actividad o tarea *',
                  hintText: 'Ejemplo: mantenimiento de computadoras',
                  prefixIcon: Icon(Icons.assignment_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validarCampoObligatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _peligroController,
                enabled: !guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Peligro identificado *',
                  hintText: 'Ejemplo: cables eléctricos expuestos',
                  prefixIcon: Icon(Icons.warning_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validarCampoObligatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _consecuenciaController,
                enabled: !guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Consecuencia posible *',
                  hintText: 'Ejemplo: descarga eléctrica',
                  prefixIcon: Icon(Icons.report_problem_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validarCampoObligatorio,
              ),
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
                  hintText: 'Describa los controles y equipos de protección',
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
              _construirTituloSeccion(
                'Implementación',
                Icons.task_alt_outlined,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsableController,
                enabled: !guardando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Responsable de implementación',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _estadoImplementacion,
                decoration: const InputDecoration(
                  labelText: 'Estado de implementación',
                  prefixIcon: Icon(Icons.pending_actions_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _estadosImplementacion
                    .map(
                      (String estado) => DropdownMenuItem<String>(
                        value: estado,
                        child: Text(_nombreEstado(estado)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: guardando
                    ? null
                    : (String? value) {
                        if (value != null) {
                          setState(() {
                            _estadoImplementacion = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              _construirSelectorFecha(
                titulo: 'Fecha de compromiso',
                fecha: _fechaCompromiso,
                onPressed: guardando ? null : _seleccionarFechaCompromiso,
                onClear: guardando
                    ? null
                    : () {
                        setState(() {
                          _fechaCompromiso = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              _construirSelectorFecha(
                titulo: 'Fecha de implementación',
                fecha: _fechaImplementacion,
                onPressed: guardando ? null : _seleccionarFechaImplementacion,
                onClear: guardando
                    ? null
                    : () {
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
                onPressed: guardando ? null : _guardar,
                icon: guardando
                    ? const SizedBox.square(
                        dimension: 20,
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
        ),
      ),
    );
  }

  Widget _construirAvisoOffline() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'El registro se guardará en el dispositivo y quedará '
                'pendiente de sincronización.',
              ),
            ),
          ],
        ),
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
    return DropdownButtonFormField<int>(
      initialValue: valor,
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
      ),
      items: List<DropdownMenuItem<int>>.generate(5, (int index) {
        final int numero = index + 1;

        return DropdownMenuItem<int>(
          value: numero,
          child: Text('$numero - ${_descripcionValor(numero)}'),
        );
      }),
      onChanged: habilitado
          ? (int? nuevoValor) {
              if (nuevoValor != null) {
                onChanged(nuevoValor);
              }
            }
          : null,
    );
  }

  Widget _construirResultadoRiesgo({
    required String titulo,
    required int valor,
  }) {
    final Color color = _obtenerColorRiesgo(valor);
    final String nivel = _obtenerNivelRiesgo(valor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Text(
              '$valor',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$titulo: $nivel',
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
    required VoidCallback? onPressed,
    required VoidCallback? onClear,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(_formatearFecha(fecha))),
          if (fecha != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Quitar fecha',
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            onPressed: onPressed,
            tooltip: 'Seleccionar fecha',
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
        ],
      ),
    );
  }

  String _descripcionValor(int valor) {
    switch (valor) {
      case 1:
        return 'Muy bajo';
      case 2:
        return 'Bajo';
      case 3:
        return 'Moderado';
      case 4:
        return 'Alto';
      case 5:
        return 'Muy alto';
      default:
        return '';
    }
  }

  String _nombreEstado(String estado) {
    switch (estado) {
      case 'EN_PROCESO':
        return 'En proceso';
      case 'IMPLEMENTADO':
        return 'Implementado';
      case 'VERIFICADO':
        return 'Verificado';
      case 'PENDIENTE':
      default:
        return 'Pendiente';
    }
  }
}
