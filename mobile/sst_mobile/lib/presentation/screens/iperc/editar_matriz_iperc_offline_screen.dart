import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';

/// ===============================================================
/// EDITAR MATRIZ IPERC OFFLINE - SST EDURISK
/// ===============================================================
///
/// Permite modificar una matriz almacenada en SQLite.
///
/// La actualización:
/// 1. modifica la matriz local;
/// 2. la marca como pendiente;
/// 3. agrega ACTUALIZAR a la cola;
/// 4. SyncService realizará PUT cuando vuelva Internet.
///
/// El usuario responsable de la modificación se obtiene
/// automáticamente desde SecureStorageService dentro del
/// repositorio offline.
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
class EditarMatrizIpercOfflineScreen extends StatefulWidget {
  const EditarMatrizIpercOfflineScreen({required this.matriz, super.key});

  final MatrizIpercLocalModel matriz;

  @override
  State<EditarMatrizIpercOfflineScreen> createState() {
    return _EditarMatrizIpercOfflineScreenState();
  }
}

class _EditarMatrizIpercOfflineScreenState
    extends State<EditarMatrizIpercOfflineScreen> {
  // =============================================================
  // FORMULARIO
  // =============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // =============================================================
  // REPOSITORIO
  // =============================================================

  final MatrizIpercOfflineRepository _repository =
      MatrizIpercOfflineRepository();

  // =============================================================
  // CONTROLADORES
  // =============================================================

  late final TextEditingController _nombreController;

  late final TextEditingController _objetivoController;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _guardando = false;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.matriz.nombre);

    _objetivoController = TextEditingController(
      text: widget.matriz.descripcion ?? '',
    );
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

    final bool valido = _formKey.currentState?.validate() ?? false;

    if (!valido) {
      return;
    }

    final MatrizIpercLocalModel matriz = widget.matriz;

    // -----------------------------------------------------------
    // OBTENER RELACIONES ORGANIZACIONALES
    // -----------------------------------------------------------

    final String institucionId = matriz.institucionId.trim();

    final String sedeId = matriz.sedeId?.trim() ?? '';

    final String areaId = matriz.areaId?.trim() ?? '';

    final String puestoTrabajoId = matriz.puestoTrabajoId?.trim() ?? '';

    final String procesoId = matriz.procesoId?.trim() ?? '';

    final String actividadId = matriz.actividadId?.trim() ?? '';

    // -----------------------------------------------------------
    // VALIDAR RELACIONES
    // -----------------------------------------------------------

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
      // ---------------------------------------------------------
      // ACTUALIZAR SQLITE
      // ---------------------------------------------------------
      //
      // El repositorio obtiene automáticamente el usuario
      // autenticado desde SecureStorageService.
      // ---------------------------------------------------------

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
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'Matriz actualizada en el dispositivo. '
        'Se sincronizará cuando vuelva Internet.',
      );

      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        error.message?.toString() ?? error.toString(),
        esError: true,
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.message, esError: true);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.message, esError: true);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Editar matriz offline'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: <Widget>[
              // -------------------------------------------------
              // CABECERA
              // -------------------------------------------------
              _construirCabecera(codigo: codigo, tieneServidor: tieneServidor),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // ESTADO LOCAL
              // -------------------------------------------------
              _EstadoLocalCard(
                sincronizado: matriz.sincronizado,
                tieneServidor: tieneServidor,
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // DATOS GENERALES
              // -------------------------------------------------
              _SeccionOffline(
                icono: Icons.edit_note_outlined,
                titulo: 'Datos generales',
                descripcion:
                    'Modifique la información principal '
                    'de la matriz almacenada en este dispositivo.',
                color: AppColors.primaryBright,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nombreController,
                      enabled: !_guardando,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 250,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        hintText: 'Nombre descriptivo de la matriz',
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryBright,
                        ),
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

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _objetivoController,
                      enabled: !_guardando,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Objetivo',
                        hintText: 'Objetivo de la evaluación IPERC',
                        prefixIcon: Icon(
                          Icons.flag_outlined,
                          color: AppColors.green,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // INFORMACIÓN ORGANIZACIONAL
              // -------------------------------------------------
              _SeccionOffline(
                icono: Icons.apartment_outlined,
                titulo: 'Información organizacional',
                descripcion:
                    'Relaciones organizacionales almacenadas '
                    'con la matriz local.',
                color: AppColors.green,
                child: Column(
                  children: <Widget>[
                    _DatoLocal(
                      titulo: 'Institución',
                      valor: matriz.institucionId,
                      icono: Icons.apartment_outlined,
                    ),
                    const Divider(height: 1),
                    _DatoLocal(
                      titulo: 'Sede',
                      valor: matriz.sedeId,
                      icono: Icons.location_city_outlined,
                    ),
                    const Divider(height: 1),
                    _DatoLocal(
                      titulo: 'Área',
                      valor: matriz.areaId,
                      icono: Icons.domain_outlined,
                    ),
                    const Divider(height: 1),
                    _DatoLocal(
                      titulo: 'Puesto de trabajo',
                      valor: matriz.puestoTrabajoId,
                      icono: Icons.badge_outlined,
                    ),
                    const Divider(height: 1),
                    _DatoLocal(
                      titulo: 'Proceso',
                      valor: matriz.procesoId,
                      icono: Icons.account_tree_outlined,
                    ),
                    const Divider(height: 1),
                    _DatoLocal(
                      titulo: 'Actividad',
                      valor: matriz.actividadId,
                      icono: Icons.task_alt_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------
              // AVISO DE SINCRONIZACIÓN
              // -------------------------------------------------
              _construirAvisoSincronizacion(sincronizado: matriz.sincronizado),

              const SizedBox(height: 22),

              // -------------------------------------------------
              // GUARDAR
              // -------------------------------------------------
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
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
                    _guardando ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'La actualización se guarda primero en SQLite. '
                'Cuando vuelva la conexión, SST EduRisk '
                'sincronizará los cambios automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // CABECERA
  // =============================================================

  Widget _construirCabecera({
    required String codigo,
    required bool tieneServidor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.phone_android_outlined,
              color: AppColors.primary,
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Edición local IPERC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  codigo,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  tieneServidor
                      ? 'La matriz está guardada localmente '
                            'y vinculada al servidor.'
                      : 'La matriz fue creada en este dispositivo '
                            'y aún no tiene registro en el servidor.',
                  style: const TextStyle(
                    color: Color(0xFFDCEAFF),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // AVISO SINCRONIZACIÓN
  // =============================================================

  Widget _construirAvisoSincronizacion({required bool sincronizado}) {
    final Color color = sincronizado ? AppColors.green : AppColors.yellow;

    final Color foreground = sincronizado
        ? AppColors.green
        : AppColors.navyDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: sincronizado ? 0.08 : 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sincronizado
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_upload_outlined,
              color: foreground,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sincronizado ? 'Matriz sincronizada' : 'Cambios pendientes',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  sincronizado
                      ? 'La matriz ya tiene información registrada '
                            'en el servidor.'
                      : 'Los cambios realizados quedarán en el '
                            'dispositivo y se enviarán al recuperar Internet.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  // LIMPIAR ERROR
  // =============================================================

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

  // =============================================================
  // MENSAJE
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
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
}

/// ===============================================================
/// ESTADO LOCAL
/// ===============================================================

class _EstadoLocalCard extends StatelessWidget {
  const _EstadoLocalCard({
    required this.sincronizado,
    required this.tieneServidor,
  });

  final bool sincronizado;
  final bool tieneServidor;

  @override
  Widget build(BuildContext context) {
    final Color color = sincronizado ? AppColors.green : AppColors.yellow;

    final Color foreground = sincronizado
        ? AppColors.green
        : AppColors.navyDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              sincronizado
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_upload_outlined,
              color: foreground,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sincronizado ? 'Sincronizada' : 'Pendiente de sincronización',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  tieneServidor
                      ? 'Vinculada a un registro existente en el servidor.'
                      : 'Registro creado únicamente en este dispositivo.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
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

/// ===============================================================
/// SECCIÓN OFFLINE
/// ===============================================================

class _SeccionOffline extends StatelessWidget {
  const _SeccionOffline({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 26),
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
/// DATO LOCAL
/// ===============================================================

class _DatoLocal extends StatelessWidget {
  const _DatoLocal({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String? valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final String texto = valor?.trim() ?? '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icono, color: AppColors.primary, size: 21),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        texto.isEmpty ? 'No asignado' : texto,
        style: TextStyle(
          color: texto.isEmpty ? AppColors.riskOrange : AppColors.textSecondary,
        ),
      ),
    );
  }
}
