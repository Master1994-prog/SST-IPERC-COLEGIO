import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../../data/models/catalogo_item_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// ===============================================================
/// EDITAR MATRIZ IPERC
/// ===============================================================
///
/// Permite modificar:
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
/// El código IPERC no puede modificarse.
/// ===============================================================
class EditarMatrizIpercScreen extends StatefulWidget {
  const EditarMatrizIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<EditarMatrizIpercScreen> createState() =>
      _EditarMatrizIpercScreenState();
}

class _EditarMatrizIpercScreenState extends State<EditarMatrizIpercScreen> {
  // =============================================================
  // FORMULARIO
  // =============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _objetivoController;

  // =============================================================
  // SERVICIOS
  // =============================================================

  final MatrizIpercRepository _repository = MatrizIpercRepository();

  final CatalogosRemoteDatasource _catalogosRemote =
      CatalogosRemoteDatasource();

  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // =============================================================
  // CATÁLOGOS
  // =============================================================

  List<CatalogoItemModel> _instituciones = <CatalogoItemModel>[];
  List<CatalogoItemModel> _sedes = <CatalogoItemModel>[];
  List<CatalogoItemModel> _areas = <CatalogoItemModel>[];
  List<CatalogoItemModel> _puestosTrabajo = <CatalogoItemModel>[];
  List<CatalogoItemModel> _procesos = <CatalogoItemModel>[];
  List<CatalogoItemModel> _actividades = <CatalogoItemModel>[];

  // =============================================================
  // SELECCIONES
  // =============================================================

  CatalogoItemModel? _institucionSeleccionada;
  CatalogoItemModel? _sedeSeleccionada;
  CatalogoItemModel? _areaSeleccionada;
  CatalogoItemModel? _puestoTrabajoSeleccionado;
  CatalogoItemModel? _procesoSeleccionado;
  CatalogoItemModel? _actividadSeleccionada;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _activa = true;

  bool _guardando = false;
  bool _cargandoCatalogos = true;

  bool _cargandoSedes = false;
  bool _cargandoAreas = false;
  bool _cargandoPuestos = false;
  bool _cargandoProcesos = false;
  bool _cargandoActividades = false;

  String? _mensajeErrorCarga;

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

    _cargarCatalogosIniciales();
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
  // CARGA INICIAL
  // =============================================================

  Future<void> _cargarCatalogosIniciales() async {
    final MatrizIpercModel matriz = widget.matriz;

    final int institucionId = matriz.institucionId ?? 0;
    final int sedeId = matriz.sedeId ?? 0;
    final int areaId = matriz.areaId ?? 0;
    final int puestoId = matriz.puestoTrabajoId ?? 0;
    final int procesoId = matriz.procesoId ?? 0;
    final int actividadId = matriz.actividadId ?? 0;

    if (institucionId <= 0 ||
        sedeId <= 0 ||
        areaId <= 0 ||
        puestoId <= 0 ||
        procesoId <= 0 ||
        actividadId <= 0) {
      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga =
            'La matriz tiene información organizacional incompleta.';
      });

      return;
    }

    try {
      // ---------------------------------------------------------
      // INSTITUCIONES
      // ---------------------------------------------------------

      final List<CatalogoItemModel> instituciones = await _catalogosRemote
          .obtenerInstituciones();

      final CatalogoItemModel? institucion = _buscarPorId(
        instituciones,
        institucionId,
      );

      // ---------------------------------------------------------
      // SEDES Y ÁREAS
      // ---------------------------------------------------------

      final List<List<CatalogoItemModel>> organizacion =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosRemote.obtenerSedes(institucionId: institucionId),
              _catalogosRemote.obtenerAreas(institucionId: institucionId),
            ],
          );

      final List<CatalogoItemModel> sedes = organizacion[0];
      final List<CatalogoItemModel> areas = organizacion[1];

      final CatalogoItemModel? sede = _buscarPorId(sedes, sedeId);

      final CatalogoItemModel? area = _buscarPorId(areas, areaId);

      // ---------------------------------------------------------
      // PUESTOS Y PROCESOS
      // ---------------------------------------------------------

      final List<List<CatalogoItemModel>> trabajo =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosRemote.obtenerPuestosTrabajo(areaId: areaId),
              _catalogosRemote.obtenerProcesos(areaId: areaId),
            ],
          );

      final List<CatalogoItemModel> puestos = trabajo[0];
      final List<CatalogoItemModel> procesos = trabajo[1];

      final CatalogoItemModel? puesto = _buscarPorId(puestos, puestoId);

      final CatalogoItemModel? proceso = _buscarPorId(procesos, procesoId);

      // ---------------------------------------------------------
      // ACTIVIDADES
      // ---------------------------------------------------------

      final List<CatalogoItemModel> actividades = await _catalogosRemote
          .obtenerActividades(procesoId: procesoId);

      final CatalogoItemModel? actividad = _buscarPorId(
        actividades,
        actividadId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _instituciones = instituciones;
        _sedes = sedes;
        _areas = areas;
        _puestosTrabajo = puestos;
        _procesos = procesos;
        _actividades = actividades;

        _institucionSeleccionada = institucion;
        _sedeSeleccionada = sede;
        _areaSeleccionada = area;
        _puestoTrabajoSeleccionado = puesto;
        _procesoSeleccionado = proceso;
        _actividadSeleccionada = actividad;

        _cargandoCatalogos = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga = _obtenerMensajeDio(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga = 'No se pudieron cargar los catálogos: $error';
      });
    }
  }

  // =============================================================
  // BUSCAR ITEM
  // =============================================================

  CatalogoItemModel? _buscarPorId(List<CatalogoItemModel> elementos, int id) {
    for (final CatalogoItemModel item in elementos) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // =============================================================
  // INSTITUCIÓN
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
      final List<List<CatalogoItemModel>> resultados =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosRemote.obtenerSedes(institucionId: institucion.id),
              _catalogosRemote.obtenerAreas(institucionId: institucion.id),
            ],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _sedes = resultados[0];
        _areas = resultados[1];
      });
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudieron cargar las sedes y áreas.',
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
  // ÁREA
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
      _cargandoPuestos = true;
      _cargandoProcesos = true;
    });

    try {
      final List<List<CatalogoItemModel>> resultados =
          await Future.wait<List<CatalogoItemModel>>(
            <Future<List<CatalogoItemModel>>>[
              _catalogosRemote.obtenerPuestosTrabajo(areaId: area.id),
              _catalogosRemote.obtenerProcesos(areaId: area.id),
            ],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _puestosTrabajo = resultados[0];
        _procesos = resultados[1];
      });
    } catch (_) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudieron cargar puestos y procesos.',
          esError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoPuestos = false;
          _cargandoProcesos = false;
        });
      }
    }
  }

  // =============================================================
  // PROCESO
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
      final List<CatalogoItemModel> actividades = await _catalogosRemote
          .obtenerActividades(procesoId: proceso.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _actividades = actividades;
      });
    } catch (_) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudieron cargar las actividades.',
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
  // USUARIO AUTENTICADO
  // =============================================================

  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String usuarioTexto =
        (await _secureStorage.getUsuarioId())?.trim() ?? '';

    final int? usuarioId = int.tryParse(usuarioTexto);

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'No se encontró el usuario autenticado. '
        'Inicie sesión nuevamente.',
      );
    }

    return usuarioId;
  }

  // =============================================================
  // GUARDAR
  // =============================================================

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (_guardando) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final int usuarioId = await _obtenerUsuarioAutenticadoId();

      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'objetivo': _textoOpcional(_objetivoController.text),
        'institucionId': _institucionSeleccionada!.id,
        'sedeId': _sedeSeleccionada!.id,
        'areaId': _areaSeleccionada!.id,
        'puestoTrabajoId': _puestoTrabajoSeleccionado!.id,
        'procesoId': _procesoSeleccionado!.id,
        'actividadId': _actividadSeleccionada!.id,
        'estado': _activa,
        'usuarioActualizacionId': usuarioId,
      };

      await _repository.actualizar(widget.matriz.id, datos);

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
      if (mounted) {
        _mostrarMensaje(_obtenerMensajeDio(error), esError: true);
      }
    } on StateError catch (error) {
      if (mounted) {
        _mostrarMensaje(error.message, esError: true);
      }
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudo actualizar la matriz: $error',
          esError: true,
        );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Editar matriz IPERC')),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargandoCatalogos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeErrorCarga != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(_mensajeErrorCarga!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _cargandoCatalogos = true;
                    _mensajeErrorCarga = null;
                  });

                  _cargarCatalogosIniciales();
                },
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            // ===================================================
            // CÓDIGO
            // ===================================================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.assignment_outlined),
                ),
                title: Text(
                  widget.matriz.codigo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'El código es automático '
                  'y no puede modificarse.',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===================================================
            // DATOS GENERALES
            // ===================================================
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

            // ===================================================
            // ORGANIZACIÓN
            // ===================================================
            Text(
              'Organización',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _construirDropdown(
              etiqueta: 'Institución',
              icono: Icons.apartment_outlined,
              valor: _institucionSeleccionada,
              elementos: _instituciones,
              cargando: false,
              onChanged: _seleccionarInstitucion,
              mensajeValidacion: 'Seleccione una institución.',
            ),

            const SizedBox(height: 14),

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

            const SizedBox(height: 14),

            _construirDropdown(
              etiqueta: 'Área',
              icono: Icons.domain_outlined,
              valor: _areaSeleccionada,
              elementos: _areas,
              cargando: _cargandoAreas,
              onChanged: _seleccionarArea,
              mensajeValidacion: 'Seleccione un área.',
            ),

            const SizedBox(height: 14),

            _construirDropdown(
              etiqueta: 'Puesto de trabajo',
              icono: Icons.badge_outlined,
              valor: _puestoTrabajoSeleccionado,
              elementos: _puestosTrabajo,
              cargando: _cargandoPuestos,
              onChanged: (CatalogoItemModel? value) {
                setState(() {
                  _puestoTrabajoSeleccionado = value;
                });
              },
              mensajeValidacion: 'Seleccione un puesto de trabajo.',
            ),

            const SizedBox(height: 14),

            _construirDropdown(
              etiqueta: 'Proceso',
              icono: Icons.account_tree_outlined,
              valor: _procesoSeleccionado,
              elementos: _procesos,
              cargando: _cargandoProcesos,
              onChanged: _seleccionarProceso,
              mensajeValidacion: 'Seleccione un proceso.',
            ),

            const SizedBox(height: 14),

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

            const SizedBox(height: 20),

            // ===================================================
            // ESTADO
            // ===================================================
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
                  _activa ? Icons.check_circle_outline : Icons.cancel_outlined,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===================================================
            // GUARDAR
            // ===================================================
            SizedBox(
              height: 54,
              child: FilledButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // DROPDOWN
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
              child: Text(item.nombre, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: cargando || _guardando ? null : onChanged,
      validator: (CatalogoItemModel? value) {
        if (value == null) {
          return mensajeValidacion;
        }

        return null;
      },
    );
  }

  // =============================================================
  // OBJETIVO OPCIONAL
  // =============================================================

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  // =============================================================
  // ERROR DIO
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
  // MENSAJE
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
