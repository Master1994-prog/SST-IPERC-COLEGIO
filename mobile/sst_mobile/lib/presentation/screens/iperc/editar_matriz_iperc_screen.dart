import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../../data/models/catalogo_item_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// ===============================================================
/// EDITAR MATRIZ IPERC - SST EDURISK
/// ===============================================================
/// Mantiene la lógica online existente y aplica la identidad visual
/// oficial de SST EduRisk.
/// ===============================================================
class EditarMatrizIpercScreen extends StatefulWidget {
  const EditarMatrizIpercScreen({required this.matriz, super.key});

  final MatrizIpercModel matriz;

  @override
  State<EditarMatrizIpercScreen> createState() =>
      _EditarMatrizIpercScreenState();
}

class _EditarMatrizIpercScreenState extends State<EditarMatrizIpercScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _objetivoController;

  final MatrizIpercRepository _repository = MatrizIpercRepository();
  final CatalogosRemoteDatasource _catalogosRemote =
      CatalogosRemoteDatasource();
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  List<CatalogoItemModel> _instituciones = <CatalogoItemModel>[];
  List<CatalogoItemModel> _sedes = <CatalogoItemModel>[];
  List<CatalogoItemModel> _areas = <CatalogoItemModel>[];
  List<CatalogoItemModel> _puestosTrabajo = <CatalogoItemModel>[];
  List<CatalogoItemModel> _procesos = <CatalogoItemModel>[];
  List<CatalogoItemModel> _actividades = <CatalogoItemModel>[];

  CatalogoItemModel? _institucionSeleccionada;
  CatalogoItemModel? _sedeSeleccionada;
  CatalogoItemModel? _areaSeleccionada;
  CatalogoItemModel? _puestoTrabajoSeleccionado;
  CatalogoItemModel? _procesoSeleccionado;
  CatalogoItemModel? _actividadSeleccionada;

  bool _activa = true;
  bool _guardando = false;
  bool _cargandoCatalogos = true;
  bool _cargandoSedes = false;
  bool _cargandoAreas = false;
  bool _cargandoPuestos = false;
  bool _cargandoProcesos = false;
  bool _cargandoActividades = false;

  String? _mensajeErrorCarga;

  @override
  void initState() {
    super.initState();

    final MatrizIpercModel matriz = widget.matriz;

    _nombreController = TextEditingController(text: matriz.nombre);
    _objetivoController = TextEditingController(text: matriz.objetivo ?? '');
    _activa = matriz.activo;

    _cargarCatalogosIniciales();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

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
      if (!mounted) return;

      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga =
            'La matriz tiene información organizacional incompleta.';
      });
      return;
    }

    try {
      final List<CatalogoItemModel> instituciones = await _catalogosRemote
          .obtenerInstituciones();

      final CatalogoItemModel? institucion = _buscarPorId(
        instituciones,
        institucionId,
      );

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

      final List<CatalogoItemModel> actividades = await _catalogosRemote
          .obtenerActividades(procesoId: procesoId);

      final CatalogoItemModel? actividad = _buscarPorId(
        actividades,
        actividadId,
      );

      if (!mounted) return;

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
        _mensajeErrorCarga = null;
      });
    } on DioException catch (error) {
      if (!mounted) return;

      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga = _obtenerMensajeDio(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargandoCatalogos = false;
        _mensajeErrorCarga = 'No se pudieron cargar los catálogos: $error';
      });
    }
  }

  CatalogoItemModel? _buscarPorId(List<CatalogoItemModel> elementos, int id) {
    for (final CatalogoItemModel item in elementos) {
      if (item.id == id) return item;
    }

    return null;
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

    if (institucion == null) return;

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

      if (!mounted) return;

      setState(() {
        _sedes = resultados[0];
        _areas = resultados[1];
      });
    } catch (_) {
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

    if (area == null) return;

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

      if (!mounted) return;

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

  Future<void> _seleccionarProceso(CatalogoItemModel? proceso) async {
    setState(() {
      _procesoSeleccionado = proceso;
      _actividadSeleccionada = null;
      _actividades = <CatalogoItemModel>[];
    });

    if (proceso == null) return;

    setState(() {
      _cargandoActividades = true;
    });

    try {
      final List<CatalogoItemModel> actividades = await _catalogosRemote
          .obtenerActividades(procesoId: proceso.id);

      if (!mounted) return;

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

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (_guardando) return;

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

      if (!mounted) return;

      _mostrarMensaje('Matriz IPERC actualizada correctamente.');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Editar matriz IPERC'),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargandoCatalogos) {
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
            _construirCabecera(),
            const SizedBox(height: 18),

            _CodigoMatrizCard(codigo: widget.matriz.codigo),
            const SizedBox(height: 18),

            _SeccionEdicion(
              icono: Icons.edit_note_outlined,
              titulo: 'Datos generales',
              descripcion: 'Actualice el nombre y el objetivo de la matriz.',
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
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
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

            _SeccionEdicion(
              icono: Icons.apartment_outlined,
              titulo: 'Organización',
              descripcion:
                  'Modifique la ubicación organizacional '
                  'y la actividad asociada a la matriz.',
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
                ],
              ),
            ),

            const SizedBox(height: 18),

            _construirEstado(),

            const SizedBox(height: 24),

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
              'Los cambios de esta pantalla se guardan '
              'directamente en el servidor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

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
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Actualizar matriz IPERC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Revise la información antes de guardar los cambios.',
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

  Widget _construirEstado() {
    final Color color = _activa ? AppColors.green : AppColors.riskOrange;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        value: _activa,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.green,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.riskOrange.withValues(alpha: 0.65),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onChanged: _guardando
            ? null
            : (bool value) {
                setState(() {
                  _activa = value;
                });
              },
        title: Text(
          _activa ? 'Matriz activa' : 'Matriz inactiva',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          _activa
              ? 'La matriz está disponible para continuar trabajando.'
              : 'La matriz quedará desactivada.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _activa ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
          ),
        ),
      ),
    );
  }

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
                    Icons.error_outline,
                    size: 44,
                    color: AppColors.riskOrange,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No se pudieron cargar los datos',
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
      validator: (CatalogoItemModel? value) {
        if (value == null) {
          return mensajeValidacion;
        }

        return null;
      },
    );
  }

  String? _textoOpcional(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

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

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;

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

class _CodigoMatrizCard extends StatelessWidget {
  const _CodigoMatrizCard({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.qr_code_2_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Código IPERC',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  codigo,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'El código es automático y no puede modificarse.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: AppColors.navyDark, size: 22),
        ],
      ),
    );
  }
}

class _SeccionEdicion extends StatelessWidget {
  const _SeccionEdicion({
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
