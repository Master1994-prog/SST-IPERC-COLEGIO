import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/consecuencia_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/models/peligro_model.dart';
import '../../../data/repositories/consecuencia_repository.dart';
import '../../../data/repositories/peligro_repository.dart';
import '../../providers/detalle_iperc_provider.dart';

/// Formulario para editar una fila registrada en la Matriz IPERC.
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
  final TextEditingController _evaluacionInicialController =
      TextEditingController();
  final TextEditingController _evaluacionResidualController =
      TextEditingController();

  final PeligroRepository _peligroRepository = PeligroRepository();
  final ConsecuenciaRepository _consecuenciaRepository =
      ConsecuenciaRepository();

  List<PeligroModel> _peligros = <PeligroModel>[];
  List<ConsecuenciaModel> _consecuencias = <ConsecuenciaModel>[];

  PeligroModel? _peligroSeleccionado;
  ConsecuenciaModel? _consecuenciaSeleccionada;
  int _estadoImplementacion = EstadoImplementacionIperc.pendiente;

  bool _cargandoCatalogos = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _itemController.text = widget.detalle.item.toString();
    _tareaController.text = widget.detalle.tarea;
    _descripcionController.text = widget.detalle.descripcionPeligro ?? '';
    _evaluacionInicialController.text =
        widget.detalle.evaluacionInicialId.toString();
    _evaluacionResidualController.text =
        widget.detalle.evaluacionResidualId?.toString() ?? '';
    _estadoImplementacion = EstadoImplementacionIperc.valores.contains(
      widget.detalle.estadoImplementacionId,
    )
        ? widget.detalle.estadoImplementacionId
        : EstadoImplementacionIperc.pendiente;
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _tareaController.dispose();
    _descripcionController.dispose();
    _evaluacionInicialController.dispose();
    _evaluacionResidualController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCarga = null;
    });

    try {
      final List<List<Object>> resultados = await Future.wait<List<Object>>(
        <Future<List<Object>>>[
          _peligroRepository.obtenerActivos(),
          _consecuenciaRepository.obtenerActivos(),
        ],
      );

      if (!mounted) {
        return;
      }

      final List<PeligroModel> peligros = resultados[0]
          .whereType<PeligroModel>()
          .toList();
      final List<ConsecuenciaModel> consecuencias = resultados[1]
          .whereType<ConsecuenciaModel>()
          .toList();

      setState(() {
        _peligros = peligros;
        _consecuencias = consecuencias;
        _peligroSeleccionado = _buscarPeligro(widget.detalle.peligroId);
        _consecuenciaSeleccionada = _buscarConsecuencia(
          widget.detalle.consecuenciaId,
        );
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
    if (!formularioValido) {
      return;
    }

    final DetalleIpercProvider provider = context.read<DetalleIpercProvider>();

    final ActualizarDetalleIpercRequest request =
        ActualizarDetalleIpercRequest(
      matrizIpercId: widget.matriz.id,
      item: int.parse(_itemController.text.trim()),
      tarea: _tareaController.text,
      peligroId: _peligroSeleccionado!.id,
      consecuenciaId: _consecuenciaSeleccionada!.id,
      descripcionPeligro: _descripcionController.text,
      evaluacionInicialId: int.parse(_evaluacionInicialController.text.trim()),
      evaluacionResidualId: _leerEnteroOpcional(
        _evaluacionResidualController.text,
      ),
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
            content: Text('Detalle IPERC actualizado correctamente.'),
          ),
        );

      Navigator.of(context).pop(true);
      return;
    }

    _mostrarMensaje(
      provider.error ?? 'No se pudo actualizar el detalle IPERC.',
      esError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DetalleIpercProvider provider = context.watch<DetalleIpercProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar peligro evaluado')),
      body: SafeArea(
        child: _cargandoCatalogos
            ? const Center(child: CircularProgressIndicator())
            : _construirContenido(provider),
      ),
    );
  }

  Widget _construirContenido(DetalleIpercProvider provider) {
    if (_errorCarga != null && _peligros.isEmpty) {
      return _EstadoCarga(
        mensaje: _errorCarga!,
        onReintentar: _cargarCatalogos,
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _ResumenMatriz(matriz: widget.matriz, detalle: widget.detalle),
          const SizedBox(height: 20),
          Text(
            'Identificación del peligro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _itemController,
            enabled: !provider.procesando,
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
            enabled: !provider.procesando,
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
            onChanged: provider.procesando
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
            onChanged: provider.procesando
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
            enabled: !provider.procesando,
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
            'Evaluación del riesgo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _evaluacionInicialController,
            enabled: !provider.procesando,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'ID de evaluación inicial *',
              prefixIcon: Icon(Icons.calculate_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validarEnteroObligatorio,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _evaluacionResidualController,
            enabled: !provider.procesando,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'ID de evaluación residual',
              helperText: 'Opcional. Se completa cuando ya existe control.',
              prefixIcon: Icon(Icons.verified_user_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validarEnteroOpcional,
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
            onChanged: provider.procesando
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
          FilledButton.icon(
            onPressed: provider.procesando ? null : _guardar,
            icon: provider.procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              provider.procesando ? 'Guardando...' : 'Guardar cambios',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: provider.procesando
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

  String? _validarEnteroObligatorio(String? value) {
    final int? id = int.tryParse(value?.trim() ?? '');

    if (id == null || id <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

  String? _validarEnteroOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? id = int.tryParse(texto);

    if (id == null || id <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

  int? _leerEnteroOpcional(String value) {
    final String texto = value.trim();
    return texto.isEmpty ? null : int.parse(texto);
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: esError
              ? Theme.of(context).colorScheme.error
              : null,
          content: Text(mensaje),
        ),
      );
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
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

class _EstadoCarga extends StatelessWidget {
  const _EstadoCarga({
    required this.mensaje,
    required this.onReintentar,
  });

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
