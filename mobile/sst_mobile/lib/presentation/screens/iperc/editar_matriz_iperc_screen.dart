import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// ===============================================================
/// EDITAR MATRIZ IPERC
/// ===============================================================
///
/// Edita una matriz registrada en el servidor.
///
/// El backend actual permite modificar:
///
/// - Nombre.
/// - Objetivo.
/// - Institución.
/// - Sede.
/// - Área.
/// - Puesto de trabajo.
/// - Proceso.
/// - Actividad.
/// - Estado.
///
/// En esta pantalla se editan los datos generales y se conservan
/// las relaciones organizacionales actuales.
///
/// IMPORTANTE:
/// El código IPERC se genera automáticamente y NO se modifica.
/// ===============================================================
class EditarMatrizIpercScreen extends StatefulWidget {
  const EditarMatrizIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<EditarMatrizIpercScreen> createState() {
    return _EditarMatrizIpercScreenState();
  }
}

class _EditarMatrizIpercScreenState extends State<EditarMatrizIpercScreen> {
  // =============================================================
  // FORMULARIO
  // =============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;

  late final TextEditingController _objetivoController;

  // =============================================================
  // REPOSITORIO
  // =============================================================

  final MatrizIpercRepository _repository = MatrizIpercRepository();

  // =============================================================
  // ESTADO
  // =============================================================

  bool _guardando = false;

  late bool _activa;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    final MatrizIpercModel matriz = widget.matriz;

    _nombreController = TextEditingController(text: matriz.nombre);

    _objetivoController = TextEditingController(text: matriz.objetivo ?? '');

    _activa = matriz.activo;
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _nombreController.dispose();
    _objetivoController.dispose();

    super.dispose();
  }

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (_guardando) {
      return;
    }

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final MatrizIpercModel matriz = widget.matriz;

    // -----------------------------------------------------------
    // Los siguientes campos son nullable en MatrizIpercModel.
    // Los convertimos a 0 para poder validarlos correctamente.
    // -----------------------------------------------------------

    final int institucionId = matriz.institucionId ?? 0;

    final int sedeId = matriz.sedeId ?? 0;

    final int areaId = matriz.areaId ?? 0;

    final int puestoTrabajoId = matriz.puestoTrabajoId ?? 0;

    final int procesoId = matriz.procesoId ?? 0;

    final int actividadId = matriz.actividadId ?? 0;

    // -----------------------------------------------------------
    // VALIDAR RELACIONES
    // -----------------------------------------------------------

    if (institucionId <= 0 ||
        sedeId <= 0 ||
        areaId <= 0 ||
        puestoTrabajoId <= 0 ||
        procesoId <= 0 ||
        actividadId <= 0) {
      _mostrarMensaje(
        'La matriz tiene información organizacional incompleta. '
        'Actualiza los datos de la matriz desde el servidor '
        'antes de editarla.',
        esError: true,
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      // =========================================================
      // PAYLOAD EXACTO DEL BACKEND ACTUAL
      // =========================================================
      //
      // MatricesIPERCController espera:
      //
      // nombre
      // objetivo
      // institucionId
      // sedeId
      // areaId
      // puestoTrabajoId
      // procesoId
      // actividadId
      // estado
      // usuarioActualizacionId
      //
      // En el proyecto actual la creación de matrices utiliza
      // usuarioRegistroId = 1.
      // Se mantiene temporalmente el mismo usuario técnico.
      // =========================================================

      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': _nombreController.text.trim(),

        'objetivo': _textoOpcional(_objetivoController.text),

        'institucionId': institucionId,

        'sedeId': sedeId,

        'areaId': areaId,

        'puestoTrabajoId': puestoTrabajoId,

        'procesoId': procesoId,

        'actividadId': actividadId,

        'estado': _activa,

        'usuarioActualizacionId': 1,
      };

      debugPrint('ACTUALIZAR MATRIZ ${matriz.id}: $datos');

      await _repository.actualizar(matriz.id, datos);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Matriz IPERC actualizada correctamente.'),
          ),
        );

      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeDio(error), esError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarMensaje(error), esError: true);
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
    final MatrizIpercModel matriz = widget.matriz;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar matriz IPERC')),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

            children: <Widget>[
              // =================================================
              // CÓDIGO
              // =================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const CircleAvatar(
                        child: Icon(Icons.assignment_outlined),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              matriz.codigo,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'El código es automático '
                              'y no puede modificarse.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // DATOS GENERALES
              // =================================================
              Text(
                'Datos generales',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _nombreController,

                enabled: !_guardando,

                textCapitalization: TextCapitalization.sentences,

                maxLength: 250,

                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),

                validator: (String? value) {
                  final String texto = value?.trim() ?? '';

                  if (texto.isEmpty) {
                    return 'El nombre es obligatorio.';
                  }

                  if (texto.length < 5) {
                    return 'El nombre debe tener '
                        'al menos 5 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _objetivoController,

                enabled: !_guardando,

                textCapitalization: TextCapitalization.sentences,

                maxLines: 4,

                maxLength: 1000,

                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                  prefixIcon: Icon(Icons.flag_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // ESTADO
              // =================================================
              Text(
                'Estado',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Card(
                child: SwitchListTile(
                  value: _activa,

                  onChanged: _guardando
                      ? null
                      : (bool value) {
                          setState(() {
                            _activa = value;
                          });
                        },

                  title: Text(_activa ? 'Matriz activa' : 'Matriz inactiva'),

                  subtitle: Text(
                    _activa
                        ? 'La matriz está disponible '
                              'para continuar trabajando.'
                        : 'La matriz quedará desactivada.',
                  ),

                  secondary: Icon(
                    _activa
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // ORGANIZACIÓN
              // =================================================
              Text(
                'Información organizacional',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              _DatoSoloLectura(
                icono: Icons.school_outlined,
                titulo: 'Institución',
                valor: matriz.institucionVisible,
              ),

              _DatoSoloLectura(
                icono: Icons.apartment_outlined,
                titulo: 'Área',
                valor: matriz.areaVisible,
              ),

              _DatoSoloLectura(
                icono: Icons.local_activity_outlined,
                titulo: 'Actividad',
                valor: matriz.actividadVisible,
              ),

              _DatoSoloLectura(
                icono: Icons.badge_outlined,
                titulo: 'ID sede',
                valor: matriz.sedeId?.toString() ?? 'No asignada',
              ),

              _DatoSoloLectura(
                icono: Icons.work_outline,
                titulo: 'ID puesto de trabajo',
                valor: matriz.puestoTrabajoId?.toString() ?? 'No asignado',
              ),

              _DatoSoloLectura(
                icono: Icons.account_tree_outlined,
                titulo: 'ID proceso',
                valor: matriz.procesoId?.toString() ?? 'No asignado',
              ),

              const SizedBox(height: 24),

              // =================================================
              // GUARDAR
              // =================================================
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,

                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),

                label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TEXTO OPCIONAL
  // =============================================================

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // MENSAJE DIO
  // =============================================================

  String _obtenerMensajeDio(DioException error) {
    final dynamic contenido = error.response?.data;

    if (contenido is Map) {
      final Map<String, dynamic> respuesta = Map<String, dynamic>.from(
        contenido,
      );

      final dynamic mensaje =
          respuesta['mensaje'] ??
          respuesta['message'] ??
          respuesta['title'] ??
          respuesta['detail'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      final dynamic errores = respuesta['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final dynamic valor in errores.values) {
          if (valor is List) {
            mensajes.addAll(valor.map((dynamic item) => item.toString()));
          } else if (valor != null) {
            mensajes.add(valor.toString());
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }
    }

    if (contenido != null && contenido.toString().trim().isNotEmpty) {
      return contenido.toString().trim();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar con el servidor.';
    }

    return error.message ?? 'No se pudo actualizar la matriz IPERC.';
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  String _limpiarMensaje(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'Bad state: ',
      'ArgumentError: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty
        ? 'No se pudo actualizar '
              'la matriz IPERC.'
        : mensaje;
  }

  // =============================================================
  // MOSTRAR MENSAJE
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}

/// ===============================================================
/// DATO SOLO LECTURA
/// ===============================================================

class _DatoSoloLectura extends StatelessWidget {
  const _DatoSoloLectura({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(child: Icon(icono)),

      title: Text(titulo),

      subtitle: Text(valor.trim().isEmpty ? 'No asignado' : valor),
    );
  }
}
