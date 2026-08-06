import 'package:flutter/material.dart';

import '../../../data/models/area_model.dart';
import '../../../data/models/institucion_model.dart';
import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/institucion_repository.dart';

/// Permite consultar, registrar, editar y eliminar áreas.
class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() {
    return _AreasScreenState();
  }
}

class _AreasScreenState extends State<AreasScreen> {
  final AreaRepository _areaRepository = AreaRepository();

  final InstitucionRepository _institucionRepository = InstitucionRepository();

  final TextEditingController _busquedaController = TextEditingController();

  List<AreaModel> _areas = <AreaModel>[];

  List<InstitucionModel> _instituciones = <InstitucionModel>[];

  bool _cargando = true;
  bool _procesando = false;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<AreaModel> get _areasFiltradas {
    return _areaRepository.buscarEnLista(_areas, _busqueda);
  }

  Future<void> _cargarDatos() async {
    if (_procesando) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _areaRepository.obtenerTodas(),
          _institucionRepository.obtenerTodas(),
        ],
      );

      final List<AreaModel> areas = resultados[0] as List<AreaModel>;

      final List<InstitucionModel> instituciones =
          resultados[1] as List<InstitucionModel>;

      areas.sort((AreaModel primero, AreaModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      instituciones.sort((InstitucionModel primero, InstitucionModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _areas = areas;
        _instituciones = instituciones;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _obtenerMensajeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _abrirNuevaArea() async {
    if (_instituciones.isEmpty) {
      _mostrarMensaje('No existen instituciones disponibles.', esError: true);
      return;
    }

    final _AreaFormResult? resultado = await showDialog<_AreaFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _AreaFormDialog(
          titulo: 'Nueva área',
          instituciones: _instituciones,
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _crearArea(resultado);
  }

  Future<void> _abrirEditarArea(AreaModel area) async {
    final _AreaFormResult? resultado = await showDialog<_AreaFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _AreaFormDialog(
          titulo: 'Editar área',
          instituciones: _instituciones,
          area: area,
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _actualizarArea(area, resultado);
  }

  Future<void> _crearArea(_AreaFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _areaRepository.crear(
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        institucionId: datos.institucionId,
        usuarioRegistroId: 1,
        colegioId: null,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Área registrada correctamente.');

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _actualizarArea(AreaModel area, _AreaFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _areaRepository.actualizar(
        id: area.id,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        institucionId: datos.institucionId,
        activo: datos.activo,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Área actualizada correctamente.');

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar(AreaModel area) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar área'),
          content: Text(
            '¿Deseas eliminar el área '
            '"${area.nombre}"?\n\n'
            'No podrá eliminarse si tiene '
            'procesos o puestos relacionados.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _areaRepository.eliminar(
        id: area.id,
        usuarioId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje(mensaje);

      await _cargarDatos();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_obtenerMensajeError(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
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
    final List<AreaModel> areas = _areasFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : _abrirNuevaArea,
        icon: const Icon(Icons.add),
        label: const Text('Nueva área'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: Column(
              children: <Widget>[
                _construirResumen(),
                _construirBuscador(),
                Expanded(child: _construirContenido(areas)),
              ],
            ),
          ),
          if (_procesando)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirResumen() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(child: Icon(Icons.apartment)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Áreas de la institución',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_areas.length} '
                  '${_areas.length == 1 ? 'área registrada' : 'áreas registradas'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _busquedaController,
        onChanged: (String value) {
          setState(() {
            _busqueda = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar área o institución',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _busqueda.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _busquedaController.clear();

                    setState(() {
                      _busqueda = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _construirContenido(List<AreaModel> areas) {
    if (_cargando && _areas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _areas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 50),
          const Icon(Icons.cloud_off_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar las áreas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    if (areas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.apartment_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            _areas.isEmpty
                ? 'No hay áreas registradas'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _areas.isEmpty
                ? 'Presiona "Nueva área" para registrar la primera.'
                : 'Prueba con otro criterio de búsqueda.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: areas.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final AreaModel area = areas[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            leading: CircleAvatar(
              child: Text(area.nombre.substring(0, 1).toUpperCase()),
            ),
            title: Text(
              area.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              <String>[
                if (area.descripcion.isNotEmpty) area.descripcion,
                area.institucionNombre.isNotEmpty
                    ? area.institucionNombre
                    : 'Institución #${area.institucionId}',
              ].join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: area.descripcion.isNotEmpty,
            trailing: PopupMenuButton<String>(
              enabled: !_procesando,
              tooltip: 'Opciones',
              onSelected: (String opcion) {
                if (opcion == 'editar') {
                  _abrirEditarArea(area);
                } else if (opcion == 'eliminar') {
                  _confirmarEliminar(area);
                }
              },
              itemBuilder: (_) {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'editar',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
                    ),
                  ),
                ];
              },
            ),
          ),
        );
      },
    );
  }

  String _obtenerMensajeError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'DioException: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.titulo,
    required this.instituciones,
    this.area,
  });

  final String titulo;
  final List<InstitucionModel> instituciones;
  final AreaModel? area;

  @override
  State<_AreaFormDialog> createState() {
    return _AreaFormDialogState();
  }
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;

  late final TextEditingController _descripcionController;

  int? _institucionId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(text: widget.area?.nombre ?? '');

    _descripcionController = TextEditingController(
      text: widget.area?.descripcion ?? '',
    );

    _activo = widget.area?.activo ?? true;

    final int? areaInstitucionId = widget.area?.institucionId;

    final bool existeInstitucion =
        areaInstitucionId != null &&
        widget.instituciones.any((InstitucionModel institucion) {
          return institucion.id == areaInstitucionId;
        });

    _institucionId = existeInstitucion
        ? areaInstitucionId
        : widget.instituciones.first.id;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? institucionId = _institucionId;

    if (institucionId == null || institucionId <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _AreaFormResult(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        institucionId: institucionId,
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.area != null;

    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<int>(
                  initialValue: _institucionId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Institución',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.instituciones.map((
                    InstitucionModel institucion,
                  ) {
                    return DropdownMenuItem<int>(
                      value: institucion.id,
                      child: Text(
                        institucion.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _institucionId = value;
                    });
                  },
                  validator: (int? value) {
                    if (value == null || value <= 0) {
                      return 'Selecciona una institución.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del área',
                    prefixIcon: Icon(Icons.apartment),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    final String nombre = value?.trim() ?? '';

                    if (nombre.isEmpty) {
                      return 'Ingresa el nombre del área.';
                    }

                    if (nombre.length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 500,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),

                if (editando)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    subtitle: Text(
                      _activo
                          ? 'El área está disponible.'
                          : 'El área está desactivada.',
                    ),
                    value: _activo,
                    onChanged: (bool value) {
                      setState(() {
                        _activo = value;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardar,
          icon: Icon(editando ? Icons.save_outlined : Icons.add),
          label: Text(editando ? 'Guardar' : 'Registrar'),
        ),
      ],
    );
  }
}

class _AreaFormResult {
  const _AreaFormResult({
    required this.nombre,
    required this.descripcion,
    required this.institucionId,
    required this.activo,
  });

  final String nombre;
  final String descripcion;
  final int institucionId;
  final bool activo;
}
