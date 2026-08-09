import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/network_info.dart';
import '../../../data/datasources/local/catalogos_organizacion_local_datasource.dart';
import '../../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../../data/models/catalogo_item_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';
import '../../providers/sync_provider.dart';

/// ===============================================================
/// NUEVA MATRIZ IPERC
/// ===============================================================
///
/// La pantalla trabaja de dos maneras:
///
/// ONLINE:
/// - Obtiene catálogos desde el backend.
/// - Guarda una copia de los catálogos en SQLite.
/// - Intenta registrar la matriz directamente en el backend.
///
/// OFFLINE:
/// - Obtiene los catálogos almacenados en SQLite.
/// - Guarda la matriz en SQLite.
/// - Agrega la matriz a la cola de sincronización.
/// - Cuando vuelva internet, SyncProvider/SyncService la enviará
///   al backend.
/// ===============================================================
class NuevaMatrizIpercScreen extends StatefulWidget {
  const NuevaMatrizIpercScreen({
    super.key,
    this.matricesRegistradas = const <MatrizIpercModel>[],
  });

  final List<MatrizIpercModel> matricesRegistradas;

  @override
  State<NuevaMatrizIpercScreen> createState() => _NuevaMatrizIpercScreenState();
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

  /// Indica que la pantalla está utilizando la copia SQLite.
  bool _usandoCatalogosLocales = false;

  String? _mensajeErrorCarga;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _codigoController.text = _generarCodigoMatriz();

    _cargarInstituciones();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

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

    return 'IPERC-$anio-'
        '${siguiente.toString().padLeft(4, '0')}';
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

          // Guardamos copia para uso offline.
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
          // Si la API no responde, intentaremos SQLite.
        } catch (_) {
          // También intentamos SQLite.
        }
      }

      // ---------------------------------------------------------
      // OFFLINE / FALLBACK
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
              await Future.wait(<Future<List<CatalogoItemModel>>>[
                _catalogosRemote.obtenerSedes(institucionId: institucion.id),
                _catalogosRemote.obtenerAreas(institucionId: institucion.id),
              ]);

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

      // ---------------------------------------------------------
      // SQLITE
      // ---------------------------------------------------------

      final List<List<CatalogoItemModel>> locales =
          await Future.wait(<Future<List<CatalogoItemModel>>>[
            _catalogosLocal.obtenerSedes(institucionId: institucion.id),
            _catalogosLocal.obtenerAreas(institucionId: institucion.id),
          ]);

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
              await Future.wait(<Future<List<CatalogoItemModel>>>[
                _catalogosRemote.obtenerPuestosTrabajo(areaId: area.id),
                _catalogosRemote.obtenerProcesos(areaId: area.id),
              ]);

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
          // Pasamos a SQLite.
        } catch (_) {
          // Pasamos a SQLite.
        }
      }

      final List<List<CatalogoItemModel>> locales =
          await Future.wait(<Future<List<CatalogoItemModel>>>[
            _catalogosLocal.obtenerPuestosTrabajo(areaId: area.id),
            _catalogosLocal.obtenerProcesos(areaId: area.id),
          ]);

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
              .obtenerActividades();

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
      final bool conectado = await _networkInfo.isConnected;

      // =========================================================
      // INTENTAR ONLINE
      // =========================================================

      if (conectado) {
        try {
          await _guardarOnline();

          return;
        } on DioException catch (error) {
          // -----------------------------------------------------
          // Si es un error real de conexión, se guarda offline.
          // Si el backend respondió 400/404/500, no debemos
          // esconder el error almacenando silenciosamente.
          // -----------------------------------------------------

          if (!_esErrorConexion(error)) {
            rethrow;
          }

          debugPrint(
            'Servidor no disponible. '
            'Se guardará la matriz en SQLite.',
          );
        }
      }

      // =========================================================
      // OFFLINE
      // =========================================================

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
      'usuarioRegistroId': 1,
    };

    debugPrint('DATOS MATRIZ IPERC ONLINE: $datos');

    final String idServidor = await _matrizRemote.create(datos);

    if (!mounted) {
      return;
    }

    _mostrarMensaje('Matriz registrada correctamente. ID: $idServidor');

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

      // En el modelo local se mantiene como descripción.
      // SyncService lo transforma posteriormente a "objetivo".
      descripcion: _objetivoController.text.trim(),

      fechaEvaluacion: DateTime.now().toUtc(),
    );

    debugPrint('MATRIZ IPERC OFFLINE: ${matriz.idLocal}');

    // -----------------------------------------------------------
    // ACTUALIZAR CONTADOR GLOBAL DE PENDIENTES
    // -----------------------------------------------------------

    if (mounted) {
      try {
        await context.read<SyncProvider>().notifyLocalChange();
      } catch (_) {
        // La matriz ya fue guardada correctamente.
        // Si SyncProvider no estuviera disponible en este contexto,
        // no se debe cancelar el guardado local.
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
  // IDENTIFICAR ERROR DE CONEXIÓN
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
          content: Text(mensaje),
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
          duration: Duration(seconds: esError ? 7 : 4),
        ),
      );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva matriz IPERC')),
      body: _construirContenido(),
    );
  }

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido() {
    if (_cargandoInstituciones) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeErrorCarga != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_off,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 18),
              Text(_mensajeErrorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _cargarInstituciones,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: <Widget>[
            // ===================================================
            // INDICADOR OFFLINE
            // ===================================================
            if (_usandoCatalogosLocales) ...<Widget>[
              _construirAvisoOffline(),
              const SizedBox(height: 20),
            ],

            Text(
              'Información general',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'Registre los datos principales. '
              'El código se generará automáticamente.',
            ),

            const SizedBox(height: 26),

            // ===================================================
            // CÓDIGO
            // ===================================================
            TextFormField(
              controller: _codigoController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Código generado',
                helperText: 'El código se genera automáticamente.',
                prefixIcon: const Icon(Icons.qr_code_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Generar código',
                  onPressed: _guardando
                      ? null
                      : () {
                          setState(() {
                            _codigoController.text = _generarCodigoMatriz();
                          });
                        },
                  icon: const Icon(Icons.autorenew),
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            // ===================================================
            // NOMBRE
            // ===================================================
            TextFormField(
              controller: _nombreController,
              enabled: !_guardando,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la matriz',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
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

            // ===================================================
            // OBJETIVO
            // ===================================================
            TextFormField(
              controller: _objetivoController,
              enabled: !_guardando,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Objetivo',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese el objetivo.';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            Text(
              'Organización',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18),

            // ===================================================
            // INSTITUCIÓN
            // ===================================================
            _construirDropdown(
              etiqueta: 'Institución',
              icono: Icons.apartment_outlined,
              valor: _institucionSeleccionada,
              elementos: _instituciones,
              cargando: false,
              onChanged: _seleccionarInstitucion,
              mensajeValidacion: 'Seleccione una institución.',
            ),

            const SizedBox(height: 18),

            // ===================================================
            // SEDE
            // ===================================================
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

            const SizedBox(height: 18),

            // ===================================================
            // ÁREA
            // ===================================================
            _construirDropdown(
              etiqueta: 'Área',
              icono: Icons.domain_outlined,
              valor: _areaSeleccionada,
              elementos: _areas,
              cargando: _cargandoAreas,
              onChanged: _seleccionarArea,
              mensajeValidacion: 'Seleccione un área.',
            ),

            const SizedBox(height: 18),

            // ===================================================
            // PUESTO
            // ===================================================
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

            const SizedBox(height: 18),

            // ===================================================
            // PROCESO
            // ===================================================
            _construirDropdown(
              etiqueta: 'Proceso',
              icono: Icons.account_tree_outlined,
              valor: _procesoSeleccionado,
              elementos: _procesos,
              cargando: _cargandoProcesos,
              onChanged: _seleccionarProceso,
              mensajeValidacion: 'Seleccione un proceso.',
            ),

            const SizedBox(height: 18),

            // ===================================================
            // ACTIVIDAD
            // ===================================================
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

            const SizedBox(height: 34),

            // ===================================================
            // GUARDAR
            // ===================================================
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando ? 'Guardando...' : 'Guardar matriz',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.offline_bolt_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Modo offline: se están utilizando los '
              'catálogos almacenados en el dispositivo. '
              'La matriz quedará pendiente de sincronización.',
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
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
        suffixIcon: cargando
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2),
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
