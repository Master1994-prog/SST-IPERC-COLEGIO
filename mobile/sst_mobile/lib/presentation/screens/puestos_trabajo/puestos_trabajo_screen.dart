import 'package:flutter/material.dart';

import '../../../data/models/area_model.dart';
import '../../../data/models/puesto_trabajo_model.dart';
import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/puesto_trabajo_repository.dart';

/// Pantalla para consultar y administrar puestos de trabajo.
class PuestosTrabajoScreen extends StatefulWidget {
  const PuestosTrabajoScreen({super.key});

  @override
  State<PuestosTrabajoScreen> createState() {
    return _PuestosTrabajoScreenState();
  }
}

class _PuestosTrabajoScreenState extends State<PuestosTrabajoScreen> {
  final PuestoTrabajoRepository _puestoRepository = PuestoTrabajoRepository();

  final AreaRepository _areaRepository = AreaRepository();

  final TextEditingController _busquedaController = TextEditingController();

  List<PuestoTrabajoModel> _puestos = <PuestoTrabajoModel>[];
  List<AreaModel> _areas = <AreaModel>[];

  bool _cargando = true;
  bool _procesando = false;

  String? _error;
  String _busqueda = '';
  int? _areaFiltroId;

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

  List<PuestoTrabajoModel> get _puestosFiltrados {
    List<PuestoTrabajoModel> resultado = _puestoRepository.buscarEnLista(
      _puestos,
      _busqueda,
    );

    resultado = _puestoRepository.filtrarPorArea(
      resultado,
      areaId: _areaFiltroId,
    );

    return _puestoRepository.ordenarPorNombre(resultado);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _puestoRepository.obtenerTodos(),
          _areaRepository.obtenerTodas(),
        ],
      );

      final List<PuestoTrabajoModel> puestos =
          resultados[0] as List<PuestoTrabajoModel>;

      final List<AreaModel> areas = resultados[1] as List<AreaModel>;

      puestos.sort((PuestoTrabajoModel primero, PuestoTrabajoModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      areas.sort((AreaModel primero, AreaModel segundo) {
        return primero.nombre.toLowerCase().compareTo(
          segundo.nombre.toLowerCase(),
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _puestos = puestos;
        _areas = areas;

        if (_areaFiltroId != null &&
            !_areas.any((AreaModel area) => area.id == _areaFiltroId)) {
          _areaFiltroId = null;
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

  Future<void> _abrirNuevoPuesto() async {
    if (_areas.isEmpty) {
      _mostrarMensaje(
        'No existen áreas disponibles. Registra primero un área.',
        esError: true,
      );
      return;
    }

    final _PuestoFormResult? resultado = await showDialog<_PuestoFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _PuestoFormDialog(
          titulo: 'Nuevo puesto de trabajo',
          areas: _areas,
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _crearPuesto(resultado);
  }

  Future<void> _abrirEditarPuesto(PuestoTrabajoModel puesto) async {
    if (_areas.isEmpty) {
      _mostrarMensaje('No existen áreas disponibles.', esError: true);
      return;
    }

    final _PuestoFormResult? resultado = await showDialog<_PuestoFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _PuestoFormDialog(
          titulo: 'Editar puesto de trabajo',
          areas: _areas,
          puesto: puesto,
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    await _actualizarPuesto(puesto, resultado);
  }

  Future<void> _crearPuesto(_PuestoFormResult datos) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _puestoRepository.crear(
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        areaId: datos.areaId,
        usuarioRegistroId: 1,
        colegioId: null,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Puesto de trabajo registrado correctamente.');

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

  Future<void> _actualizarPuesto(
    PuestoTrabajoModel puesto,
    _PuestoFormResult datos,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _puestoRepository.actualizar(
        id: puesto.id,
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        areaId: datos.areaId,
        activo: datos.activo,
        usuarioActualizacionId: 1,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Puesto de trabajo actualizado correctamente.');

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

  Future<void> _confirmarEliminar(PuestoTrabajoModel puesto) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar puesto de trabajo'),
          content: Text('¿Deseas eliminar el puesto "${puesto.nombre}"?'),
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
      final String mensaje = await _puestoRepository.eliminar(
        id: puesto.id,
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
    final List<PuestoTrabajoModel> puestos = _puestosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puestos de trabajo'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando || _procesando ? null : _cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : _abrirNuevoPuesto,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo puesto'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: Column(
              children: <Widget>[
                _construirResumen(),
                _construirFiltros(),
                Expanded(child: _construirContenido(puestos)),
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
          const CircleAvatar(child: Icon(Icons.badge_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Puestos registrados',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_puestos.length} '
                  '${_puestos.length == 1 ? 'puesto' : 'puestos'}',
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
              hintText: 'Buscar puesto, descripción o área',
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
            key: ValueKey<int?>(_areaFiltroId),
            initialValue: _areaFiltroId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filtrar por área',
              prefixIcon: Icon(Icons.apartment_outlined),
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas las áreas'),
              ),
              ..._areas.map((AreaModel area) {
                return DropdownMenuItem<int?>(
                  value: area.id,
                  child: Text(
                    area.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (int? value) {
              setState(() {
                _areaFiltroId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(List<PuestoTrabajoModel> puestos) {
    if (_cargando && _puestos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _puestos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 50),
          const Icon(Icons.cloud_off_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los puestos de trabajo',
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

    if (puestos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.badge_outlined, size: 70),
          const SizedBox(height: 16),
          Text(
            _puestos.isEmpty
                ? 'No hay puestos de trabajo registrados'
                : 'No se encontraron resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _puestos.isEmpty
                ? 'Presiona "Nuevo puesto" para registrar el primero.'
                : 'Prueba con otra búsqueda o área.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: puestos.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (BuildContext context, int index) {
        final PuestoTrabajoModel puesto = puestos[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            leading: CircleAvatar(
              child: Text(puesto.nombre.substring(0, 1).toUpperCase()),
            ),
            title: Text(
              puesto.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              <String>[
                if (puesto.descripcion.isNotEmpty) puesto.descripcion,
                puesto.areaNombre.isNotEmpty
                    ? 'Área: ${puesto.areaNombre}'
                    : 'Área #${puesto.areaId}',
                puesto.activo ? 'Estado: Activo' : 'Estado: Inactivo',
              ].join('\n'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              enabled: !_procesando,
              tooltip: 'Opciones',
              onSelected: (String opcion) {
                if (opcion == 'editar') {
                  _abrirEditarPuesto(puesto);
                } else if (opcion == 'eliminar') {
                  _confirmarEliminar(puesto);
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

/// Formulario para registrar o editar un puesto de trabajo.
class _PuestoFormDialog extends StatefulWidget {
  const _PuestoFormDialog({
    required this.titulo,
    required this.areas,
    this.puesto,
  });

  final String titulo;
  final List<AreaModel> areas;
  final PuestoTrabajoModel? puesto;

  @override
  State<_PuestoFormDialog> createState() {
    return _PuestoFormDialogState();
  }
}

class _PuestoFormDialogState extends State<_PuestoFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;

  late final TextEditingController _descripcionController;

  int? _areaId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.puesto?.nombre ?? '',
    );

    _descripcionController = TextEditingController(
      text: widget.puesto?.descripcion ?? '',
    );

    _activo = widget.puesto?.activo ?? true;

    final int? puestoAreaId = widget.puesto?.areaId;

    final bool areaExiste =
        puestoAreaId != null &&
        widget.areas.any((AreaModel area) => area.id == puestoAreaId);

    _areaId = areaExiste ? puestoAreaId : widget.areas.first.id;
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

    final int? areaId = _areaId;

    if (areaId == null || areaId <= 0) {
      return;
    }

    Navigator.of(context).pop(
      _PuestoFormResult(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        areaId: areaId,
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editando = widget.puesto != null;

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
                  initialValue: _areaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    prefixIcon: Icon(Icons.apartment_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.areas.map((AreaModel area) {
                    return DropdownMenuItem<int>(
                      value: area.id,
                      child: Text(
                        area.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _areaId = value;
                    });
                  },
                  validator: (int? value) {
                    if (value == null || value <= 0) {
                      return 'Selecciona un área.';
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
                    labelText: 'Nombre del puesto',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    final String nombre = value?.trim() ?? '';

                    if (nombre.isEmpty) {
                      return 'Ingresa el nombre del puesto.';
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
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
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
                          ? 'El puesto está disponible.'
                          : 'El puesto está desactivado.',
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

class _PuestoFormResult {
  const _PuestoFormResult({
    required this.nombre,
    required this.descripcion,
    required this.areaId,
    required this.activo,
  });

  final String nombre;
  final String descripcion;
  final int areaId;
  final bool activo;
}
