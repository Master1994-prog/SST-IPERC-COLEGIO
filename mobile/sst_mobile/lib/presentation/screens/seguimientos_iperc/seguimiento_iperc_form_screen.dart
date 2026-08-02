import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/seguimiento_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../providers/seguimiento_iperc_provider.dart';

/// Formulario para registrar o actualizar un seguimiento IPERC.
class SeguimientoIpercFormScreen extends StatefulWidget {
  const SeguimientoIpercFormScreen({
    this.seguimiento,
    this.detalleIpercIdInicial,
    super.key,
  });

  final SeguimientoIpercModel? seguimiento;
  final int? detalleIpercIdInicial;

  @override
  State<SeguimientoIpercFormScreen> createState() {
    return _SeguimientoIpercFormScreenState();
  }
}

class _SeguimientoIpercFormScreenState
    extends State<SeguimientoIpercFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  List<DetalleIpercModel> _detalles = <DetalleIpercModel>[];
  bool _cargandoDetalles = true;
  String? _errorDetalles;

  int? _detalleIpercId;
  int _usuarioId = 0;
  DateTime _fechaSeguimiento = DateTime.now();
  double _porcentajeAvance = 0;
  bool _verificado = false;

  bool get _esEdicion => widget.seguimiento != null;

  @override
  void initState() {
    super.initState();

    final SeguimientoIpercModel? seguimiento = widget.seguimiento;

    if (seguimiento != null) {
      _detalleIpercId = seguimiento.detalleIpercId;
      _usuarioId = seguimiento.usuarioId;
      _fechaSeguimiento = seguimiento.fechaSeguimiento;
      _porcentajeAvance = seguimiento.porcentajeAvance.clamp(0, 100).toDouble();
      _verificado = seguimiento.verificado;
      _descripcionController.text = seguimiento.descripcion;
      _observacionesController.text = seguimiento.observaciones ?? '';
    } else {
      _detalleIpercId = widget.detalleIpercIdInicial;
    }

    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    await Future.wait(<Future<void>>[_cargarUsuario(), _cargarDetalles()]);
  }

  Future<void> _cargarUsuario() async {
    if (_usuarioId > 0) {
      return;
    }

    final String? usuarioIdTexto = await SecureStorageService.instance
        .getUsuarioId();
    final int usuarioId = int.tryParse(usuarioIdTexto ?? '') ?? 0;

    if (!mounted) {
      return;
    }

    setState(() {
      _usuarioId = usuarioId;
    });
  }

  Future<void> _cargarDetalles() async {
    setState(() {
      _cargandoDetalles = true;
      _errorDetalles = null;
    });

    try {
      final List<DetalleIpercModel> detalles = await _detalleRepository
          .obtenerTodos();

      if (!mounted) {
        return;
      }

      setState(() {
        _detalles = detalles;
        _cargandoDetalles = false;
        if (_detalleIpercId == null && detalles.isNotEmpty) {
          _detalleIpercId = detalles.first.id;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoDetalles = false;
        _errorDetalles = error.toString().replaceFirst('Exception:', '').trim();
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
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

  Future<void> _guardar() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_detalleIpercId == null || _detalleIpercId! <= 0) {
      _mostrarMensaje('Selecciona un detalle IPERC válido.', esError: true);
      return;
    }

    if (_usuarioId <= 0) {
      _mostrarMensaje(
        'No se pudo identificar el usuario de la sesión.',
        esError: true,
      );
      return;
    }

    final SeguimientoIpercProvider provider = context
        .read<SeguimientoIpercProvider>();
    final DateTime? fechaVerificacion = _verificado ? DateTime.now() : null;

    final bool correcto;

    if (_esEdicion) {
      correcto = await provider.actualizar(
        widget.seguimiento!.id,
        ActualizarSeguimientoIpercRequest(
          detalleIpercId: _detalleIpercId!,
          fechaSeguimiento: _fechaSeguimiento,
          usuarioId: _usuarioId,
          descripcion: _descripcionController.text,
          porcentajeAvance: _porcentajeAvance,
          verificado: _verificado,
          fechaVerificacion: fechaVerificacion,
          observaciones: _observacionesController.text,
        ),
      );
    } else {
      correcto = await provider.crear(
        CrearSeguimientoIpercRequest(
          detalleIpercId: _detalleIpercId!,
          fechaSeguimiento: _fechaSeguimiento,
          usuarioId: _usuarioId,
          descripcion: _descripcionController.text,
          porcentajeAvance: _porcentajeAvance,
          verificado: _verificado,
          fechaVerificacion: fechaVerificacion,
          observaciones: _observacionesController.text,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    if (correcto) {
      Navigator.of(context).pop(true);
      return;
    }

    _mostrarMensaje(
      provider.error ?? 'No se pudo guardar el seguimiento IPERC.',
      esError: true,
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
          content: Text(mensaje),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar seguimiento' : 'Nuevo seguimiento'),
      ),
      body: Consumer<SeguimientoIpercProvider>(
        builder: (BuildContext context, SeguimientoIpercProvider provider, Widget? child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: <Widget>[
                _DetalleSelector(
                  cargando: _cargandoDetalles,
                  error: _errorDetalles,
                  detalles: _detalles,
                  valor: _detalleIpercId,
                  onChanged: _esEdicion
                      ? null
                      : (int? value) {
                          setState(() {
                            _detalleIpercId = value;
                          });
                        },
                  onRetry: _cargarDetalles,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del avance',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ingresa la descripción del seguimiento.';
                    }

                    if ((value ?? '').trim().length > 3000) {
                      return 'La descripción no debe superar 3000 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().length > 3000) {
                      return 'Las observaciones no deben superar 3000 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Fecha: ${_formatearFecha(_fechaSeguimiento)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _seleccionarFecha,
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Cambiar'),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Avance: ${_porcentajeAvance.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Slider(
                          value: _porcentajeAvance,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_porcentajeAvance.toStringAsFixed(0)}%',
                          onChanged: (double value) {
                            setState(() {
                              _porcentajeAvance = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Marcar como verificado'),
                          value: _verificado,
                          onChanged: (bool value) {
                            setState(() {
                              _verificado = value;
                              if (value && _porcentajeAvance < 100) {
                                _porcentajeAvance = 100;
                              }
                            });
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
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Consumer<SeguimientoIpercProvider>(
          builder:
              (
                BuildContext context,
                SeguimientoIpercProvider provider,
                Widget? child,
              ) {
                return FilledButton.icon(
                  onPressed: provider.procesando ? null : _guardar,
                  icon: provider.procesando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_esEdicion ? 'Actualizar' : 'Guardar'),
                );
              },
        ),
      ),
    );
  }
}

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
  final List<DetalleIpercModel> detalles;
  final int? valor;
  final ValueChanged<int?>? onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final int? valorSeguro =
        detalles.any((DetalleIpercModel detalle) => detalle.id == valor)
        ? valor
        : null;

    if (cargando) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Cargando detalles IPERC...')),
            ],
          ),
        ),
      );
    }

    if (error != null && error!.trim().isNotEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(error!),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: valorSeguro,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Detalle IPERC',
        border: OutlineInputBorder(),
      ),
      items: detalles.map((DetalleIpercModel detalle) {
        return DropdownMenuItem<int>(
          value: detalle.id,
          child: Text(
            'Item ${detalle.item} - ${detalle.tarea}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (int? value) {
        if (value == null || value <= 0) {
          return 'Selecciona el detalle IPERC.';
        }

        return null;
      },
    );
  }
}

String _formatearFecha(DateTime fecha) {
  final String dia = fecha.day.toString().padLeft(2, '0');
  final String mes = fecha.month.toString().padLeft(2, '0');
  final String anio = fecha.year.toString();
  return '$dia/$mes/$anio';
}
