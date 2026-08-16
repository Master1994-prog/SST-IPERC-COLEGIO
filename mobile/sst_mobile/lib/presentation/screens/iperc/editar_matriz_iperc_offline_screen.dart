import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';

/// ===============================================================
/// EDITAR MATRIZ IPERC OFFLINE
/// ===============================================================
///
/// Permite modificar una matriz almacenada en SQLite.
///
/// La actualización:
///
/// 1. modifica la matriz local;
/// 2. la marca como pendiente;
/// 3. agrega ACTUALIZAR a la cola;
/// 4. SyncService hará PUT cuando vuelva Internet.
/// ===============================================================
class EditarMatrizIpercOfflineScreen extends StatefulWidget {
  const EditarMatrizIpercOfflineScreen({required this.matriz, super.key});

  final MatrizIpercLocalModel matriz;

  @override
  State<EditarMatrizIpercOfflineScreen> createState() =>
      _EditarMatrizIpercOfflineScreenState();
}

class _EditarMatrizIpercOfflineScreenState
    extends State<EditarMatrizIpercOfflineScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final MatrizIpercOfflineRepository _repository =
      MatrizIpercOfflineRepository();

  late final TextEditingController _nombreController;

  late final TextEditingController _objetivoController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.matriz.nombre);

    _objetivoController = TextEditingController(
      text: widget.matriz.descripcion ?? '',
    );
  }

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

    final bool valido = _formKey.currentState?.validate() ?? false;

    if (!valido) {
      return;
    }

    final MatrizIpercLocalModel matriz = widget.matriz;

    final String institucionId = matriz.institucionId.trim();

    final String sedeId = matriz.sedeId?.trim() ?? '';

    final String areaId = matriz.areaId?.trim() ?? '';

    final String puestoTrabajoId = matriz.puestoTrabajoId?.trim() ?? '';

    final String procesoId = matriz.procesoId?.trim() ?? '';

    final String actividadId = matriz.actividadId?.trim() ?? '';

    if (institucionId.isEmpty ||
        sedeId.isEmpty ||
        areaId.isEmpty ||
        puestoTrabajoId.isEmpty ||
        procesoId.isEmpty ||
        actividadId.isEmpty) {
      _mostrarMensaje(
        'La matriz tiene información organizacional incompleta.',
        esError: true,
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _repository.updateOffline(
        idLocal: matriz.idLocal,

        institucionId: institucionId,

        sedeId: sedeId,

        areaId: areaId,

        puestoTrabajoId: puestoTrabajoId,

        procesoId: procesoId,

        actividadId: actividadId,

        nombre: _nombreController.text.trim(),

        descripcion: _textoOpcional(_objetivoController.text),

        codigo: matriz.codigo,

        fechaEvaluacion: matriz.fechaEvaluacion,

        estadoMatriz: matriz.estadoMatriz,

        // Temporal hasta conectar el ID real del usuario logueado.
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Matriz actualizada en el dispositivo. '
              'Se sincronizará cuando vuelva Internet.',
            ),
          ),
        );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarError(error), esError: true);
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
    final MatrizIpercLocalModel matriz = widget.matriz;

    final String codigo = matriz.codigo?.trim().isNotEmpty == true
        ? matriz.codigo!.trim()
        : 'SIN CÓDIGO';

    final bool tieneServidor = matriz.idServidor?.trim().isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar matriz offline')),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              // =================================================
              // INFORMACIÓN
              // =================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const CircleAvatar(
                        child: Icon(Icons.phone_android_outlined),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              codigo,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              tieneServidor
                                  ? 'Matriz almacenada localmente '
                                        'y vinculada al servidor.'
                                  : 'Matriz creada en este dispositivo '
                                        'y pendiente de sincronización.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Datos generales',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // =================================================
              // NOMBRE
              // =================================================
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

              // =================================================
              // OBJETIVO
              // =================================================
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
              // ESTADO SINCRONIZACIÓN
              // =================================================
              Text(
                'Sincronización',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: Icon(
                    matriz.sincronizado
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                  ),

                  title: Text(
                    matriz.sincronizado ? 'Sincronizada' : 'Pendiente',
                  ),

                  subtitle: Text(
                    matriz.sincronizado
                        ? 'La matriz ya tiene información '
                              'en el servidor.'
                        : 'Los cambios se enviarán '
                              'automáticamente al recuperar Internet.',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // RELACIONES
              // =================================================
              Text(
                'Información organizacional',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              _DatoLocal(titulo: 'Institución', valor: matriz.institucionId),

              _DatoLocal(titulo: 'Sede', valor: matriz.sedeId),

              _DatoLocal(titulo: 'Área', valor: matriz.areaId),

              _DatoLocal(
                titulo: 'Puesto de trabajo',
                valor: matriz.puestoTrabajoId,
              ),

              _DatoLocal(titulo: 'Proceso', valor: matriz.procesoId),

              _DatoLocal(titulo: 'Actividad', valor: matriz.actividadId),

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

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  String _limpiarError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'ArgumentError: ',
      'StateError: ',
      'Bad state: ',
      'FormatException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'No se pudo actualizar la matriz local.' : mensaje;
  }

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
/// DATO LOCAL
/// ===============================================================

class _DatoLocal extends StatelessWidget {
  const _DatoLocal({required this.titulo, required this.valor});

  final String titulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final String texto = valor?.trim() ?? '';

    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: const Icon(Icons.chevron_right),

      title: Text(titulo),

      subtitle: Text(texto.isEmpty ? 'No asignado' : texto),
    );
  }
}
