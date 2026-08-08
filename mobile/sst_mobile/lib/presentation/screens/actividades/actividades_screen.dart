import 'package:flutter/material.dart';

import '../../../data/models/actividad_model.dart';
import '../../../data/models/proceso_model.dart';
import '../../../data/repositories/actividad_repository.dart';
import '../../../data/repositories/proceso_repository.dart';

/// Pantalla para consultar y administrar actividades.
class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() {
    return _ActividadesScreenState();
  }
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  final ActividadRepository _actividadRepository = ActividadRepository();

  final ProcesoRepository _procesoRepository = ProcesoRepository();

  final TextEditingController _busquedaController = TextEditingController();

  List<ActividadModel> _actividades = <ActividadModel>[];

  List<ProcesoModel> _procesos = <ProcesoModel>[];

  bool _cargando = true;
  bool _procesando = false;
  String? _error;
  String _busqueda = '';
  int? _procesoFiltroId;

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

  List<ActividadModel> get _actividadesFiltradas {
    List<ActividadModel> resultados = _actividadRepository.buscarEnLista(
      _actividades,
      _busqueda,
    );

    if (_procesoFiltroId != null && _procesoFiltroId! > 0) {
      resultados = resultados.where((ActividadModel actividad) {
        return actividad.procesoId == _procesoFiltroId;
      }).toList();
    }

    return resultados;
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
          _actividadRepository.obtenerTodas(),
          _procesoRepository.obtenerTodos(),
        ],
      );

      final List<ActividadModel> actividades =
          resultados[0] as List<ActividadModel>;

      final List<ProcesoModel> procesos = resultados[1] as List<ProcesoModel>;

      actividades.sort((ActividadModel primero, ActividadModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      procesos.sort((ProcesoModel primero, ProcesoModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _actividades = actividades;
        _procesos = procesos;

        if (_procesoFiltroId != null &&
            !_procesos.any((ProcesoModel proceso) {
              return proceso.id == _procesoFiltroId;
            })) {
          _procesoFiltroId = null;
        }
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

  Future<void> _abrirNuevaActividad() async {
    if (_procesos.isEmpty) {
      _mostrarMensaje(
        'No existen procesos disponibles. '
        'Registra primero un proceso.',
        esError: true,
      );
      return;
    }

    final _ActividadFormResult? resultado =
        await showDialog<_ActividadFormResult>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return _ActividadFormDialog(
              titulo: 'Nueva actividad',
              procesos: _procesos,
            );
          },
        );

    if (resultado == null || !mounted) {
      return;
    }

    await _crearActividad(resultado);
  }

  Future<void> _abrirEditarActividad(ActividadModel actividad) async {
    final _ActividadFormResult? resultado =
        await showDialog<_ActividadFormResult>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return _ActividadFormDialog(
              titulo: 'Editar actividad',
              procesos: _procesos,
              actividad: actividad,
            );
          },
        );

    if (resultado == null || !mounted) {
      return;
    }

    await _actualizarActividad(actividad, resultado);
  }

  Future<void> _crearActividad(_ActividadFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _actividadRepository.crear(
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        procesoId: datos.procesoId,
        usuarioRegistroId: 1,
        colegioId: null,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Actividad registrada correctamente.');

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

  Future<void> _actualizarActividad(
    ActividadModel actividad,
    _ActividadFormResult datos,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _actividadRepository.actualizar(
        id: actividad.id,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        procesoId: datos.procesoId,
        activo: datos.activo,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Actividad actualizada correctamente.');

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

  Future<void> _confirmarEliminar(ActividadModel actividad) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar actividad'),
          content: Text(
            '¿Deseas eliminar la actividad '
            '"${actividad.nombre}"?',
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
      final String mensaje = await _actividadRepository.eliminar(
        id: actividad.id,
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
    final List<ActividadModel> actividades = _actividadesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : _abrirNuevaActividad,
        icon: const Icon(Icons.add),
        label: const Text('Nueva actividad'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: Column(
              children: <Widget>[
                _construirResumen(),
                _construirFiltros(),
                Expanded(child: _construirContenido(actividades)),
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
          const CircleAvatar(child: Icon(Icons.task_alt)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Actividades registradas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_actividades.length} '
                  '${_actividades.length == 1 ? 'actividad' : 'actividades'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _busquedaController,
            onChanged: (String value) {
              setState(() {
                _busqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar actividad, proceso o área',
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey<int?>(_procesoFiltroId),
            initialValue: _procesoFiltroId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filtrar por proceso',
              prefixIcon: Icon(Icons.account_tree_outlined),
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los procesos'),
              ),
              ..._procesos.map((ProcesoModel proceso) {
                return DropdownMenuItem<int?>(
                  value: proceso.id,
                  child: Text(
                    proceso.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (int? value) {
              setState(() {
                _procesoFiltroId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(List<ActividadModel> actividades) {
    if (_cargando && _actividades.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _actividades.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 50),
          const Icon(Icons.cloud_off_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar las actividades',
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

    if (actividades.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.task_alt_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            _actividades.isEmpty
                ? 'No hay actividades registradas'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _actividades.isEmpty
                ? 'Presiona "Nueva actividad" para registrar la primera.'
                : 'Prueba con otra búsqueda o proceso.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: actividades.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final ActividadModel actividad = actividades[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            leading: CircleAvatar(
              child: Text(actividad.nombre.substring(0, 1).toUpperCase()),
            ),
            title: Text(
              actividad.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              <String>[
                if (actividad.descripcion.isNotEmpty) actividad.descripcion,
                actividad.procesoNombre.isNotEmpty
                    ? actividad.procesoNombre
                    : 'Proceso #${actividad.procesoId}',
                if (actividad.areaNombre.isNotEmpty) actividad.areaNombre,
              ].join('\n'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              enabled: !_procesando,
              tooltip: 'Opciones',
              onSelected: (String opcion) {
                if (opcion == 'editar') {
                  _abrirEditarActividad(actividad);
                } else if (opcion == 'eliminar') {
                  _confirmarEliminar(actividad);
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

class _ActividadFormDialog extends StatefulWidget {
  const _ActividadFormDialog({
    required this.titulo,
    required this.procesos,
    this.actividad,
  });

  final String titulo;
  final List<ProcesoModel> procesos;
  final ActividadModel? actividad;

  @override
  State<_ActividadFormDialog> createState() {
    return _ActividadFormDialogState();
  }
}

class _ActividadFormDialogState extends State<_ActividadFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;

  late final TextEditingController _descripcionController;

  int? _procesoId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.actividad?.nombre ?? '',
    );

    _descripcionController = TextEditingController(
      text: widget.actividad?.descripcion ?? '',
    );

    _activo = widget.actividad?.activo ?? true;

    final int? actividadProcesoId = widget.actividad?.procesoId;

    final bool existeProceso =
        actividadProcesoId != null &&
        widget.procesos.any((ProcesoModel proceso) {
          return proceso.id == actividadProcesoId;
        });

    _procesoId = existeProceso ? actividadProcesoId : widget.procesos.first.id;
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

    final int? procesoId = _procesoId;

    if (procesoId == null || procesoId <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _ActividadFormResult(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        procesoId: procesoId,
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.actividad != null;

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
                  initialValue: _procesoId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proceso',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.procesos.map((ProcesoModel proceso) {
                    return DropdownMenuItem<int>(
                      value: proceso.id,
                      child: Text(
                        proceso.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _procesoId = value;
                    });
                  },
                  validator: (int? value) {
                    if (value == null || value <= 0) {
                      return 'Selecciona un proceso.';
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
                    labelText: 'Nombre de la actividad',
                    prefixIcon: Icon(Icons.task_alt),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    final String nombre = value?.trim() ?? '';

                    if (nombre.isEmpty) {
                      return 'Ingresa el nombre de la actividad.';
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
                          ? 'La actividad está disponible.'
                          : 'La actividad está desactivada.',
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

class _ActividadFormResult {
  const _ActividadFormResult({
    required this.nombre,
    required this.descripcion,
    required this.procesoId,
    required this.activo,
  });

  final String nombre;
  final String descripcion;
  final int procesoId;
  final bool activo;
}
