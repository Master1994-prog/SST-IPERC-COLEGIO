import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/network_info.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/local/catalogos_organizacion_local_datasource.dart';
import '../../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../../data/models/catalogo_item_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';
import '../../providers/sync_provider.dart';

/// ===============================================================
/// NUEVA MATRIZ IPERC - SST EDURISK
/// ===============================================================
///
/// Mantiene la lógica online/offline existente:
///
/// ONLINE:
/// - Obtiene catálogos desde el backend.
/// - Guarda copia de catálogos en SQLite.
/// - Registra la matriz directamente en el backend.
///
/// OFFLINE:
/// - Obtiene catálogos desde SQLite.
/// - Guarda la matriz en SQLite.
/// - Registra una operación pendiente.
/// - SyncService la enviará cuando vuelva la conexión.
///
/// Identidad visual:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class NuevaMatrizIpercScreen extends StatefulWidget {
  const NuevaMatrizIpercScreen({
    super.key,
    this.matricesRegistradas = const <MatrizIpercModel>[],
  });

  final List<MatrizIpercModel> matricesRegistradas;

  @override
  State<NuevaMatrizIpercScreen> createState() {
    return _NuevaMatrizIpercScreenState();
  }
}

class _NuevaMatrizIpercScreenState extends State<NuevaMatrizIpercScreen> {
  // =============================================================
  // FORMULARIO
  // =============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController = TextEditingController();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _objetivoController = TextEditingController();

  // =============================================================
  // DATASOURCES / REPOSITORIES
  // =============================================================

  final CatalogosRemoteDatasource _catalogosRemote =
      CatalogosRemoteDatasource();

  final CatalogosOrganizacionLocalDatasource _catalogosLocal =
      CatalogosOrganizacionLocalDatasource();

  final MatrizIpercRemoteDatasource _matrizRemote =
      MatrizIpercRemoteDatasource();

  final MatrizIpercOfflineRepository _matrizOfflineRepository =
      MatrizIpercOfflineRepository();

  final NetworkInfo _networkInfo = NetworkInfo.instance;

  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // =============================================================
  // CATÁLOGOS
  // =============================================================

  List<CatalogoItemModel> _instituciones = <CatalogoItemModel>[];
  List<CatalogoItemModel> _sedes = <CatalogoItemModel>[];
  List<CatalogoItemModel> _areas = <CatalogoItemModel>[];
  List<CatalogoItemModel> _procesos = <CatalogoItemModel>[];
  List<CatalogoItemModel> _actividades = <CatalogoItemModel>[];
  List<CatalogoItemModel> _puestosTrabajo = <CatalogoItemModel>[];

  // =============================================================
  // SELECCIONES
  // =============================================================

  CatalogoItemModel? _institucionSeleccionada;
  CatalogoItemModel? _sedeSeleccionada;
  CatalogoItemModel? _areaSeleccionada;
  CatalogoItemModel? _procesoSeleccionado;
  CatalogoItemModel? _actividadSeleccionada;
  CatalogoItemModel? _puestoTrabajoSeleccionado;

  // =============================================================
  // ESTADOS
  // =============================================================

  bool _cargandoInstituciones = true;
  bool _cargandoSedes = false;
  bool _cargandoAreas = false;
  bool _cargandoProcesos = false;
  bool _cargandoActividades = false;
  bool _cargandoPuestosTrabajo = false;
  bool _guardando = false;

  /// Indica que la pantalla está utilizando catálogos SQLite.
  bool _usandoCatalogosLocales = false;

  String? _mensajeErrorCarga;

  // =============================================================
  // INIT / DISPOSE
  // =============================================================

  @override
  void initState() {
    super.initState();

    _codigoController.text = _generarCodigoMatriz();

    _cargarInstituciones();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _objetivoController.dispose();

    super.dispose();
  }

  // =============================================================
  // GENERAR CÓDIGO
  // =============================================================

  String _generarCodigoMatriz() {
    final int anio = DateTime.now().year;

    int mayorCorrelativo = 0;

    for (final MatrizIpercModel matriz in widget.matricesRegistradas) {
      final String codigo = matriz.codigo.trim().toUpperCase();

      if (!codigo.startsWith('IPERC-$anio-')) {
        continue;
      }

      final int? correlativo = int.tryParse(codigo.split('-').last);

      if (correlativo != null && correlativo > mayorCorrelativo) {
        mayorCorrelativo = correlativo;
      }
    }

    final int siguiente = mayorCorrelativo + 1;

    return 'IPERC-$anio-${siguiente.toString().padLeft(4, '0')}';
  }

  // =============================================================
  // CARGAR INSTITUCIONES
  // =============================================================

  Future<void> _cargarInstituciones() async {
    if (mounted) {
      setState(() {
        _cargandoInstituciones = true;
        _mensajeErrorCarga = null;

        _instituciones = <CatalogoItemModel>[];
        _sedes = <CatalogoItemModel>[];
        _areas = <CatalogoItemModel>[];
        _puestosTrabajo = <CatalogoItemModel>[];
        _procesos = <CatalogoItemModel>[];
        _actividades = <CatalogoItemModel>[];

        _institucionSeleccionada = null;
        _sedeSeleccionada = null;
        _areaSeleccionada = null;
        _puestoTrabajoSeleccionado = null;
        _procesoSeleccionado = null;
        _actividadSeleccionada = null;
      });
    }

    try {
      final bool conectado = await _networkInfo.isConnected;

      // ---------------------------------------------------------
      // ONLINE
      // ---------------------------------------------------------

      if (conectado) {
        try {
          final List<CatalogoItemModel> remotas = await _catalogosRemote
              .obtenerInstituciones();

          await _catalogosLocal.guardarInstituciones(remotas);

          if (!mounted) {
            return;
          }

          setState(() {
            _instituciones = remotas;
            _usandoCatalogosLocales = false;
          });

          return;
        } on DioException {
          // Intentamos SQLite.
        } catch (_) {
          // Intentamos SQLite.
        }
      }

      // ---------------------------------------------------------
      // OFFLINE
      // ---------------------------------------------------------

      final List<CatalogoItemModel> locales = await _catalogosLocal
          .obtenerInstituciones();

      if (!mounted) {
        return;
      }

      if (locales.isEmpty) {
        setState(() {
          _mensajeErrorCarga =
              'No hay conexión con el servidor y todavía no existen '
              'instituciones almacenadas en el dispositivo.\n\n'
              'Conéctese una vez a internet para descargar los '
              'catálogos necesarios.';
        });

        return;
      }

      setState(() {
        _instituciones = locales;
        _usandoCatalogosLocales = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeErrorCarga =
            'No se pudieron cargar las instituciones locales: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoInstituciones = false;
        });
      }
    }
  }

  // =============================================================
  // SELECCIONAR INSTITUCIÓN
  // =============================================================

  Future<void> _seleccionarInstitucion(CatalogoItemModel? institucion) async {
    setState(() {
      _institucionSeleccionada = institucion;

      _sedeSeleccionada = null;
      _areaSeleccionada = null;
      _puestoTrabajoSeleccionado = null;
      _procesoSeleccionado = null;
      _actividadSeleccionada = null;

      _sedes = <CatalogoItemModel>[];
      _areas = <CatalogoItemModel>[];
      _puestosTrabajo = <CatalogoItemModel>[];
      _procesos = <CatalogoItemModel>[];
      _actividades = <CatalogoItemModel>[];
    });

    if (institucion == null) {
      return;
    }

    setState(() {
      _cargandoSedes = true;
      _cargandoAreas = true;
    });

    try {
      final bool conectado = await _networkInfo.isConnected;

      if (conectado) {
        try {
          final List<List<CatalogoItemModel>> resultados =
              await Future.wait<List<CatalogoItemModel>>(
                <Future<List<CatalogoItemModel>>>[
                  _catalogosRemote.obtenerSedes(institucionId: institucion.id),
                  _catalogosRemote.obtenerAreas(institucionId: institucion.id),
                ],
              );

          final List<CatalogoItemModel> sedes = resultados[0];
          final List<CatalogoItemModel> areas = resultados[1];

          await Future.wait<void>(<Future<void>>[
            _catalogosLocal.guardarSedes(sedes, institucionId: institucion.id),
            _catalogosLocal.guardarAreas(areas, institucionId: institucion.id),
          ]);

          if (!mounted) {
            return;
          }

          setState(() {
            _sedes = sedes;
            _areas = areas;
            _usandoCatalogosLocales = false;
          });

          return;
        } on DioException {
          // Pasar a SQLite.
        } catch (_) {
          // Pasar a SQLite.
        }
      }

      final List<List<CatalogoItemModel>> locales =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosLocal.obtenerSedes(institucionId: institucion.id),
              _catalogosLocal.obtenerAreas(institucionId: institucion.id),
            ],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _sedes = locales[0];
        _areas = locales[1];
        _usandoCatalogosLocales = true;
      });

      if (_sedes.isEmpty) {
        _mostrarMensaje(
          'No existen sedes almacenadas para esta institución.',
          esError: true,
        );
      }

      if (_areas.isEmpty) {
        _mostrarMensaje(
          'No existen áreas almacenadas para esta institución.',
          esError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoSedes = false;
          _cargandoAreas = false;
        });
      }
    }
  }

  // =============================================================
  // SELECCIONAR ÁREA
  // =============================================================

  Future<void> _seleccionarArea(CatalogoItemModel? area) async {
    setState(() {
      _areaSeleccionada = area;

      _puestoTrabajoSeleccionado = null;
      _procesoSeleccionado = null;
      _actividadSeleccionada = null;

      _puestosTrabajo = <CatalogoItemModel>[];
      _procesos = <CatalogoItemModel>[];
      _actividades = <CatalogoItemModel>[];
    });

    if (area == null) {
      return;
    }

    setState(() {
      _cargandoPuestosTrabajo = true;
      _cargandoProcesos = true;
    });

    try {
      final bool conectado = await _networkInfo.isConnected;

      if (conectado) {
        try {
          final List<List<CatalogoItemModel>> resultados =
              await Future.wait<List<CatalogoItemModel>>(
                <Future<List<CatalogoItemModel>>>[
                  _catalogosRemote.obtenerPuestosTrabajo(areaId: area.id),
                  _catalogosRemote.obtenerProcesos(areaId: area.id),
                ],
              );

          final List<CatalogoItemModel> puestos = resultados[0];
          final List<CatalogoItemModel> procesos = resultados[1];

          await Future.wait<void>(<Future<void>>[
            _catalogosLocal.guardarPuestosTrabajo(puestos, areaId: area.id),
            _catalogosLocal.guardarProcesos(procesos, areaId: area.id),
          ]);

          if (!mounted) {
            return;
          }

          setState(() {
            _puestosTrabajo = puestos;
            _procesos = procesos;
            _usandoCatalogosLocales = false;
          });

          return;
        } on DioException {
          // Pasar a SQLite.
        } catch (_) {
          // Pasar a SQLite.
        }
      }

      final List<List<CatalogoItemModel>> locales =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosLocal.obtenerPuestosTrabajo(areaId: area.id),
              _catalogosLocal.obtenerProcesos(areaId: area.id),
            ],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _puestosTrabajo = locales[0];
        _procesos = locales[1];
        _usandoCatalogosLocales = true;
      });

      if (_puestosTrabajo.isEmpty) {
        _mostrarMensaje(
          'No existen puestos de trabajo almacenados para esta área.',
          esError: true,
        );
      }

      if (_procesos.isEmpty) {
        _mostrarMensaje(
          'No existen procesos almacenados para esta área.',
          esError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoPuestosTrabajo = false;
          _cargandoProcesos = false;
        });
      }
    }
  }

  // =============================================================
  // SELECCIONAR PROCESO
  // =============================================================

  Future<void> _seleccionarProceso(CatalogoItemModel? proceso) async {
    setState(() {
      _procesoSeleccionado = proceso;

      _actividadSeleccionada = null;
      _actividades = <CatalogoItemModel>[];
    });

    if (proceso == null) {
      return;
    }

    setState(() {
      _cargandoActividades = true;
    });

    try {
      final bool conectado = await _networkInfo.isConnected;

      if (conectado) {
        try {
          final List<CatalogoItemModel> actividades = await _catalogosRemote
              .obtenerActividades(procesoId: proceso.id);

          await _catalogosLocal.guardarActividades(
            actividades,
            procesoId: proceso.id,
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _actividades = actividades;
            _usandoCatalogosLocales = false;
          });

          return;
        } on DioException {
          // Usar SQLite.
        } catch (_) {
          // Usar SQLite.
        }
      }

      final List<CatalogoItemModel> locales = await _catalogosLocal
          .obtenerActividades(procesoId: proceso.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _actividades = locales;
        _usandoCatalogosLocales = true;
      });

      if (_actividades.isEmpty) {
        _mostrarMensaje(
          'No existen actividades almacenadas para este proceso.',
          esError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoActividades = false;
        });
      }
    }
  }

  // =============================================================
  // OBTENER USUARIO AUTENTICADO
  // =============================================================

  // USUARIO_OFFLINE_FALLBACK_V1
  Future<int> _obtenerUsuarioAutenticadoId() async {
    String usuarioTexto = (await _secureStorage.getUsuarioId())?.trim() ?? '';

    if (usuarioTexto.isEmpty) {
      usuarioTexto = (await _secureStorage.getOfflineUsuarioId())?.trim() ?? '';
    }

    if (usuarioTexto.isEmpty) {
      throw StateError(
        'No se encontró un usuario autorizado para trabajar offline. '
        'Conéctese una vez e inicie sesión nuevamente.',
      );
    }

    final int? usuarioId = int.tryParse(usuarioTexto);

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError('El identificador del usuario autorizado no es válido.');
    }

    return usuarioId;
  }

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido || _guardando) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _obtenerUsuarioAutenticadoId();

      final bool conectado = await _networkInfo.isConnected;

      // ---------------------------------------------------------
      // ONLINE
      // ---------------------------------------------------------

      if (conectado) {
        try {
          await _guardarOnline();

          return;
        } on DioException catch (error) {
          if (!_esErrorConexion(error)) {
            rethrow;
          }

          debugPrint(
            'Servidor no disponible. '
            'Se guardará la matriz en SQLite.',
          );
        }
      }

      // ---------------------------------------------------------
      // OFFLINE
      // ---------------------------------------------------------

      await _guardarOffline();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _obtenerMensajeDio(
          error,
          mensajePredeterminado: 'No se pudo registrar la matriz IPERC.',
        ),
        esError: true,
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.message, esError: true);
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'No se pudo guardar la matriz IPERC: $error',
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // =============================================================
  // GUARDAR ONLINE
  // =============================================================

  Future<void> _guardarOnline() async {
    final int usuarioRegistroId = await _obtenerUsuarioAutenticadoId();

    final Map<String, dynamic> datos = <String, dynamic>{
      'codigo': _codigoController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'objetivo': _objetivoController.text.trim(),
      'institucionId': _institucionSeleccionada!.id,
      'sedeId': _sedeSeleccionada!.id,
      'areaId': _areaSeleccionada!.id,
      'puestoTrabajoId': _puestoTrabajoSeleccionado!.id,
      'procesoId': _procesoSeleccionado!.id,
      'actividadId': _actividadSeleccionada!.id,
      'usuarioRegistroId': usuarioRegistroId,
    };

    debugPrint('DATOS MATRIZ IPERC ONLINE: $datos');

    final String idServidor = await _matrizRemote.create(datos);

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      'Matriz registrada correctamente. '
      'ID: $idServidor',
    );

    Navigator.of(context).pop(true);
  }

  // =============================================================
  // GUARDAR OFFLINE
  // =============================================================

  Future<void> _guardarOffline() async {
    final CatalogoItemModel institucion = _institucionSeleccionada!;

    final CatalogoItemModel sede = _sedeSeleccionada!;

    final CatalogoItemModel area = _areaSeleccionada!;

    final CatalogoItemModel puesto = _puestoTrabajoSeleccionado!;

    final CatalogoItemModel proceso = _procesoSeleccionado!;

    final CatalogoItemModel actividad = _actividadSeleccionada!;

    final matriz = await _matrizOfflineRepository.createOffline(
      institucionId: institucion.id.toString(),
      sedeId: sede.id.toString(),
      areaId: area.id.toString(),
      puestoTrabajoId: puesto.id.toString(),
      procesoId: proceso.id.toString(),
      actividadId: actividad.id.toString(),
      codigo: _codigoController.text.trim(),
      nombre: _nombreController.text.trim(),
      descripcion: _objetivoController.text.trim(),
      fechaEvaluacion: DateTime.now().toUtc(),
    );

    debugPrint('MATRIZ IPERC OFFLINE: ${matriz.idLocal}');

    if (mounted) {
      try {
        await context.read<SyncProvider>().notifyLocalChange();
      } catch (_) {
        // La matriz ya quedó correctamente almacenada.
      }
    }

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      'Matriz guardada en el dispositivo. '
      'Se sincronizará automáticamente cuando vuelva la conexión.',
    );

    Navigator.of(context).pop(true);
  }

  // =============================================================
  // ERROR DE CONEXIÓN
  // =============================================================

  bool _esErrorConexion(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  // =============================================================
  // MENSAJE DIO
  // =============================================================

  String _obtenerMensajeDio(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    if (_esErrorConexion(error)) {
      return 'No se pudo conectar con el servidor.';
    }

    final int? codigoEstado = error.response?.statusCode;

    final dynamic contenido = error.response?.data;

    String mensaje = mensajePredeterminado;

    if (contenido is Map) {
      final Map<String, dynamic> respuesta = Map<String, dynamic>.from(
        contenido,
      );

      final dynamic mensajeServidor =
          respuesta['mensaje'] ??
          respuesta['message'] ??
          respuesta['title'] ??
          respuesta['detail'];

      if (mensajeServidor != null &&
          mensajeServidor.toString().trim().isNotEmpty) {
        mensaje = mensajeServidor.toString();
      }

      final dynamic errores = respuesta['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> detalles = <String>[];

        for (final dynamic valor in errores.values) {
          if (valor is List) {
            detalles.addAll(valor.map((dynamic item) => item.toString()));
          } else if (valor != null) {
            detalles.add(valor.toString());
          }
        }

        if (detalles.isNotEmpty) {
          mensaje = detalles.join('\n');
        }
      }
    } else if (contenido != null && contenido.toString().trim().isNotEmpty) {
      mensaje = contenido.toString();
    }

    if (codigoEstado != null) {
      return 'Error $codigoEstado: $mensaje';
    }

    return mensaje;
  }

  // =============================================================
  // MENSAJES
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
          duration: Duration(seconds: esError ? 7 : 4),
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
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Nueva matriz IPERC'),
      ),
      body: _construirContenido(),
    );
  }

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido() {
    if (_cargandoInstituciones) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_mensajeErrorCarga != null) {
      return _construirErrorCarga();
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: <Widget>[
            // ---------------------------------------------------
            // CABECERA
            // ---------------------------------------------------
            _construirCabecera(),

            const SizedBox(height: 18),

            // ---------------------------------------------------
            // INDICADOR OFFLINE
            // ---------------------------------------------------
            if (_usandoCatalogosLocales) ...<Widget>[
              _construirAvisoOffline(),
              const SizedBox(height: 18),
            ],

            // ---------------------------------------------------
            // INFORMACIÓN GENERAL
            // ---------------------------------------------------
            _SeccionFormulario(
              icono: Icons.assignment_outlined,
              titulo: 'Información general',
              descripcion:
                  'Registre los datos principales de la matriz. '
                  'El código se genera automáticamente.',
              color: AppColors.primaryBright,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _codigoController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Código generado',
                      helperText: 'El código se genera automáticamente.',
                      prefixIcon: const Icon(
                        Icons.qr_code_outlined,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Generar código',
                        onPressed: _guardando
                            ? null
                            : () {
                                setState(() {
                                  _codigoController.text =
                                      _generarCodigoMatriz();
                                });
                              },
                        icon: const Icon(
                          Icons.autorenew,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _nombreController,
                    enabled: !_guardando,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la matriz',
                      hintText: 'Ej. Matriz IPERC - Área Administrativa',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: AppColors.primaryBright,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese el nombre de la matriz.';
                      }

                      if (value.trim().length < 5) {
                        return 'Ingrese al menos 5 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _objetivoController,
                    enabled: !_guardando,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo',
                      hintText: 'Describa el objetivo de la evaluación IPERC.',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: AppColors.green,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese el objetivo.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---------------------------------------------------
            // ORGANIZACIÓN
            // ---------------------------------------------------
            _SeccionFormulario(
              icono: Icons.apartment_outlined,
              titulo: 'Organización',
              descripcion:
                  'Seleccione la institución, sede, área, puesto, '
                  'proceso y actividad que serán evaluados.',
              color: AppColors.green,
              child: Column(
                children: <Widget>[
                  _construirDropdown(
                    etiqueta: 'Institución',
                    icono: Icons.apartment_outlined,
                    valor: _institucionSeleccionada,
                    elementos: _instituciones,
                    cargando: false,
                    onChanged: _seleccionarInstitucion,
                    mensajeValidacion: 'Seleccione una institución.',
                  ),

                  const SizedBox(height: 16),

                  _construirDropdown(
                    etiqueta: 'Sede',
                    icono: Icons.location_city_outlined,
                    valor: _sedeSeleccionada,
                    elementos: _sedes,
                    cargando: _cargandoSedes,
                    onChanged: (CatalogoItemModel? value) {
                      setState(() {
                        _sedeSeleccionada = value;
                      });
                    },
                    mensajeValidacion: 'Seleccione una sede.',
                  ),

                  const SizedBox(height: 16),

                  _construirDropdown(
                    etiqueta: 'Área',
                    icono: Icons.domain_outlined,
                    valor: _areaSeleccionada,
                    elementos: _areas,
                    cargando: _cargandoAreas,
                    onChanged: _seleccionarArea,
                    mensajeValidacion: 'Seleccione un área.',
                  ),

                  const SizedBox(height: 16),

                  _construirDropdown(
                    etiqueta: 'Puesto de trabajo',
                    icono: Icons.badge_outlined,
                    valor: _puestoTrabajoSeleccionado,
                    elementos: _puestosTrabajo,
                    cargando: _cargandoPuestosTrabajo,
                    onChanged: (CatalogoItemModel? value) {
                      setState(() {
                        _puestoTrabajoSeleccionado = value;
                      });
                    },
                    mensajeValidacion: 'Seleccione un puesto de trabajo.',
                  ),

                  const SizedBox(height: 16),

                  _construirDropdown(
                    etiqueta: 'Proceso',
                    icono: Icons.account_tree_outlined,
                    valor: _procesoSeleccionado,
                    elementos: _procesos,
                    cargando: _cargandoProcesos,
                    onChanged: _seleccionarProceso,
                    mensajeValidacion: 'Seleccione un proceso.',
                  ),

                  const SizedBox(height: 16),

                  _construirDropdown(
                    etiqueta: 'Actividad',
                    icono: Icons.task_alt_outlined,
                    valor: _actividadSeleccionada,
                    elementos: _actividades,
                    cargando: _cargandoActividades,
                    onChanged: (CatalogoItemModel? value) {
                      setState(() {
                        _actividadSeleccionada = value;
                      });
                    },
                    mensajeValidacion: 'Seleccione una actividad.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------
            // RESUMEN DEL MODO DE GUARDADO
            // ---------------------------------------------------
            _ModoGuardadoCard(offline: _usandoCatalogosLocales),

            const SizedBox(height: 22),

            // ---------------------------------------------------
            // GUARDAR
            // ---------------------------------------------------
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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando ? 'Guardando...' : 'Guardar matriz',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Los datos quedarán protegidos en el dispositivo '
              'si no existe conexión con el servidor.',
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
    );
  }

  // =============================================================
  // CABECERA
  // =============================================================

  Widget _construirCabecera() {
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
      child: const Row(
        children: <Widget>[
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Registro de matriz IPERC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Complete la información para iniciar '
                  'la identificación de peligros y evaluación de riesgos.',
                  style: TextStyle(
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
  // ERROR DE CARGA
  // =============================================================

  Widget _construirErrorCarga() {
    return SafeArea(
      child: Center(
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
                  _mensajeErrorCarga!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.40,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _cargarInstituciones,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // AVISO OFFLINE
  // =============================================================

  Widget _construirAvisoOffline() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.55)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OfflineIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Modo offline',
                  style: TextStyle(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Se están utilizando los catálogos almacenados '
                  'en el dispositivo. La matriz quedará pendiente '
                  'de sincronización.',
                  style: TextStyle(
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
  // DROPDOWN GENÉRICO
  // =============================================================

  Widget _construirDropdown({
    required String etiqueta,
    required IconData icono,
    required CatalogoItemModel? valor,
    required List<CatalogoItemModel> elementos,
    required bool cargando,
    required ValueChanged<CatalogoItemModel?> onChanged,
    required String mensajeValidacion,
  }) {
    final CatalogoItemModel? valorValido =
        valor != null &&
            elementos.any((CatalogoItemModel item) => item.id == valor.id)
        ? elementos.firstWhere((CatalogoItemModel item) => item.id == valor.id)
        : null;

    return DropdownButtonFormField<CatalogoItemModel>(
      initialValue: valorValido,
      isExpanded: true,
      iconEnabledColor: AppColors.primary,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: AppColors.primary),
        suffixIcon: cargando
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      items: elementos
          .map(
            (CatalogoItemModel item) => DropdownMenuItem<CatalogoItemModel>(
              value: item,
              child: Text(
                item.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: cargando || _guardando ? null : onChanged,
      validator: (CatalogoItemModel? item) {
        if (item == null) {
          return mensajeValidacion;
        }

        return null;
      },
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
/// INDICADOR DEL MODO DE GUARDADO
/// ===============================================================

class _ModoGuardadoCard extends StatelessWidget {
  const _ModoGuardadoCard({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final Color color = offline ? AppColors.yellow : AppColors.green;

    final Color foreground = offline ? AppColors.navyDark : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: offline ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            offline ? Icons.phone_android_outlined : Icons.cloud_done_outlined,
            color: foreground,
            size: 27,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  offline
                      ? 'Guardado local habilitado'
                      : 'Guardado online disponible',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  offline
                      ? 'La matriz se almacenará en SQLite y se enviará cuando vuelva internet.'
                      : 'La matriz se enviará al servidor. Si la conexión falla, se guardará en el dispositivo.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
}

/// ===============================================================
/// ICONO DE CABECERA
/// ===============================================================

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.assignment_add,
        color: AppColors.primary,
        size: 31,
      ),
    );
  }
}

/// ===============================================================
/// ICONO OFFLINE
/// ===============================================================

class _OfflineIcon extends StatelessWidget {
  const _OfflineIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.offline_bolt_outlined, color: AppColors.navyDark),
    );
  }
}
