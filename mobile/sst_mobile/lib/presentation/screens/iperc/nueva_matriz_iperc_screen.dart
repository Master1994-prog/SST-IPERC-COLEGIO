import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../../data/datasources/remote/matriz_iperc_remote_datasource.dart';
import '../../../data/models/catalogo_item_model.dart';

class NuevaMatrizIpercScreen extends StatefulWidget {
  const NuevaMatrizIpercScreen({super.key});

  @override
  State<NuevaMatrizIpercScreen> createState() => _NuevaMatrizIpercScreenState();
}

class _NuevaMatrizIpercScreenState extends State<NuevaMatrizIpercScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _objetivoController = TextEditingController();

  final CatalogosRemoteDatasource _catalogosDatasource =
      CatalogosRemoteDatasource();

  final MatrizIpercRemoteDatasource _matrizDatasource =
      MatrizIpercRemoteDatasource();

  List<CatalogoItemModel> _instituciones = <CatalogoItemModel>[];

  List<CatalogoItemModel> _sedes = <CatalogoItemModel>[];

  List<CatalogoItemModel> _areas = <CatalogoItemModel>[];

  List<CatalogoItemModel> _procesos = <CatalogoItemModel>[];

  List<CatalogoItemModel> _actividades = <CatalogoItemModel>[];

  List<CatalogoItemModel> _puestosTrabajo = <CatalogoItemModel>[];

  CatalogoItemModel? _institucionSeleccionada;
  CatalogoItemModel? _sedeSeleccionada;
  CatalogoItemModel? _areaSeleccionada;
  CatalogoItemModel? _procesoSeleccionado;
  CatalogoItemModel? _actividadSeleccionada;
  CatalogoItemModel? _puestoTrabajoSeleccionado;

  bool _cargandoInstituciones = true;
  bool _cargandoSedes = false;
  bool _cargandoAreas = false;
  bool _cargandoProcesos = false;
  bool _cargandoActividades = false;
  bool _cargandoPuestosTrabajo = false;
  bool _guardando = false;

  String? _mensajeErrorCarga;

  @override
  void initState() {
    super.initState();
    _cargarInstituciones();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarInstituciones() async {
    setState(() {
      _cargandoInstituciones = true;
      _mensajeErrorCarga = null;

      _instituciones = <CatalogoItemModel>[];
      _areas = <CatalogoItemModel>[];
      _procesos = <CatalogoItemModel>[];
      _actividades = <CatalogoItemModel>[];

      _institucionSeleccionada = null;
      _areaSeleccionada = null;
      _procesoSeleccionado = null;
      _actividadSeleccionada = null;
    });

    try {
      final List<CatalogoItemModel> instituciones = await _catalogosDatasource
          .obtenerInstituciones();

      if (!mounted) {
        return;
      }

      setState(() {
        _instituciones = instituciones;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeErrorCarga = _obtenerMensajeDio(
          error,
          mensajePredeterminado: 'No se pudieron cargar las instituciones.',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeErrorCarga = 'Error al cargar instituciones: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargandoInstituciones = false;
        });
      }
    }
  }

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
      final List<List<CatalogoItemModel>> resultados =
          await Future.wait(<Future<List<CatalogoItemModel>>>[
            _catalogosDatasource.obtenerSedes(institucionId: institucion.id),
            _catalogosDatasource.obtenerAreas(institucionId: institucion.id),
          ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _sedes = resultados[0];
        _areas = resultados[1];
      });

      if (_sedes.isEmpty) {
        _mostrarMensaje(
          'La institución no tiene sedes registradas.',
          esError: true,
        );
      }

      if (_areas.isEmpty) {
        _mostrarMensaje(
          'La institución no tiene áreas registradas.',
          esError: true,
        );
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _obtenerMensajeDio(
          error,
          mensajePredeterminado: 'No se pudieron cargar sedes y áreas.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoSedes = false;
          _cargandoAreas = false;
        });
      }
    }
  }

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
      final List<List<CatalogoItemModel>> resultados =
          await Future.wait(<Future<List<CatalogoItemModel>>>[
            _catalogosDatasource.obtenerPuestosTrabajo(areaId: area.id),
            _catalogosDatasource.obtenerProcesos(areaId: area.id),
          ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _puestosTrabajo = resultados[0];
        _procesos = resultados[1];
      });

      if (_puestosTrabajo.isEmpty) {
        _mostrarMensaje(
          'No existen puestos de trabajo para el área.',
          esError: true,
        );
      }

      if (_procesos.isEmpty) {
        _mostrarMensaje('No existen procesos para el área.', esError: true);
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _obtenerMensajeDio(
          error,
          mensajePredeterminado: 'No se pudieron cargar los datos del área.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoPuestosTrabajo = false;
          _cargandoProcesos = false;
        });
      }
    }
  }

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
      final List<CatalogoItemModel> actividades = await _catalogosDatasource
          .obtenerActividades();

      if (!mounted) {
        return;
      }

      setState(() {
        _actividades = actividades;
      });

      if (actividades.isEmpty) {
        _mostrarMensaje('No existen actividades registradas.', esError: true);
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _obtenerMensajeDio(
          error,
          mensajePredeterminado: 'No se pudieron cargar las actividades.',
        ),
        esError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje('Error al cargar actividades: $error', esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _cargandoActividades = false;
        });
      }
    }
  }

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
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'objetivo': _objetivoController.text.trim(),
        'institucionId': _institucionSeleccionada!.id,
        'sedeId': _institucionSeleccionada!.id,
        'areaId': _areaSeleccionada!.id,
        'puestoTrabajoId': _puestoTrabajoSeleccionado!.id,
        'procesoId': _procesoSeleccionado!.id,
        'actividadId': _actividadSeleccionada!.id,
        'usuarioRegistroId': 1,
      };

      debugPrint('DATOS MATRIZ IPERC: $datos');

      final String idServidor = await _matrizDatasource.create(datos);

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'Matriz registrada correctamente. '
        'ID: $idServidor',
      );

      Navigator.of(context).pop(true);
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

      _mostrarMensaje(
        'La respuesta del servidor no es válida: '
        '${error.message}',
        esError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje('Error inesperado: $error', esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  String _obtenerMensajeDio(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva matriz IPERC')),
      body: _construirContenido(),
    );
  }

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

  Widget _construirDropdown({
    required String etiqueta,
    required IconData icono,
    required CatalogoItemModel? valor,
    required List<CatalogoItemModel> elementos,
    required bool cargando,
    required ValueChanged<CatalogoItemModel?> onChanged,
    required String mensajeValidacion,
  }) {
    return DropdownButtonFormField<CatalogoItemModel>(
      initialValue: valor,
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
