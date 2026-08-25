import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/network_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/local/detalle_iperc_local_datasource.dart';
import '../../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../../data/repositories/mapa_riesgo_repository.dart';
import '../../../data/models/mapa_riesgo_local_model.dart';
import '../../providers/sync_provider.dart';
import '../seguimientos_iperc/seguimientos_iperc_screen.dart';

/// ===============================================================
/// MAPA DE RIESGOS INTERACTIVO
/// ===============================================================
///
/// Esta pantalla:
///
/// - Trabaja con información local de SQLite.
/// - Cuando existe Internet, actualiza la vista con el backend.
/// - Agrupa riesgos por zona/área.
/// - Permite buscar por área, tarea, peligro o consecuencia.
/// - Permite filtrar por nivel de riesgo.
/// - Tiene vista "Mapa", "Lista" y "Críticas".
/// - Muestra riesgo inicial y residual.
/// - Permite abrir Seguimientos IPERC desde cada riesgo.
///
/// No utiliza un plano físico todavía. La vista "Mapa" representa
/// cada zona como un bloque interactivo, preparada para evolucionar
/// después a un plano real del colegio.
/// ===============================================================
class MapasRiesgoScreen extends StatefulWidget {
  const MapasRiesgoScreen({super.key});

  @override
  State<MapasRiesgoScreen> createState() => _MapasRiesgoScreenState();
}

class _MapasRiesgoScreenState extends State<MapasRiesgoScreen> {
  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final NetworkInfo _networkInfo = NetworkInfo.instance;

  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  /// Repositorio híbrido de Mapas de Riesgo.
  ///
  /// Permite:
  /// - leer el mapa desde SQLite;
  /// - descargarlo desde el backend;
  /// - subir el plano;
  /// - guardar MarcadoresJson;
  /// - actualizar el mapa existente.
  final MapaRiesgoRepository _mapaRiesgoRepository = MapaRiesgoRepository();

  final MatrizIpercLocalDatasource _matrizLocalDatasource =
      MatrizIpercLocalDatasource();

  final DetalleIpercLocalDatasource _detalleLocalDatasource =
      DetalleIpercLocalDatasource();

  // =============================================================
  // CONTROLADORES
  // =============================================================

  final TextEditingController _busquedaController = TextEditingController();

  /// Selector de imágenes para cargar el plano real.
  final ImagePicker _imagePicker = ImagePicker();

  /// Ruta persistente de la imagen del plano.
  String? _rutaPlano;

  /// Posiciones normalizadas de los marcadores por nombre de zona.
  ///
  /// x/y se guardan entre 0.0 y 1.0 para que el plano siga
  /// adaptándose correctamente a distintos tamaños de pantalla.
  final Map<String, Offset> _posicionesMarcadores = <String, Offset>{};

  bool _editandoPlano = false;

  /// Matriz IPERC seleccionada para asociar el plano.
  int? _matrizMapaSeleccionada;

  /// Mapa persistido actualmente para esa matriz.
  MapaRiesgoLocalModel? _mapaPersistido;

  /// Evita guardar dos veces mientras existe una petición en curso.
  bool _guardandoMapa = false;

  /// Indica si se está recuperando el plano desde SQLite/backend.
  bool _cargandoMapaPersistido = false;

  /// Indica que el backend respondió, pero la imagen física del plano
  /// no pudo recuperarse. Este estado NO se muestra como error general,
  /// porque los riesgos IPERC pueden seguir utilizándose normalmente.
  bool _planoServidorNoDisponible = false;

  static const String _prefRutaPlano = 'mapa_riesgo_ruta_plano';
  static const String _prefMarcadores = 'mapa_riesgo_marcadores';

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = true;
  bool _conectado = false;
  String? _error;
  String? _advertencia;

  String _busqueda = '';
  String _nivelSeleccionado = 'TODOS';
  String _zonaSeleccionada = 'TODAS';
  _VistaMapaRiesgo _vista = _VistaMapaRiesgo.mapa;

  final List<_RiesgoMapaItem> _riesgos = <_RiesgoMapaItem>[];

  // =============================================================
  // MATRICES DISPONIBLES PARA EL PLANO
  // =============================================================

  List<_MatrizMapaOption> get _matricesDisponiblesMapa {
    final Map<int, _MatrizMapaOption> resultado = <int, _MatrizMapaOption>{};

    for (final _RiesgoMapaItem riesgo in _riesgos) {
      final int? id = riesgo.matrizIdServidor;

      if (id == null || id <= 0) {
        continue;
      }

      resultado[id] = _MatrizMapaOption(
        id: id,
        codigo: riesgo.matrizCodigo,
        nombre: riesgo.matrizNombre,
      );
    }

    final List<_MatrizMapaOption> lista = resultado.values.toList();

    lista.sort(
      (_MatrizMapaOption a, _MatrizMapaOption b) =>
          a.codigo.toLowerCase().compareTo(b.codigo.toLowerCase()),
    );

    return lista;
  }

  List<_RiesgoMapaItem> get _riesgosMatrizPlano {
    final int? matrizId = _matrizMapaSeleccionada;

    if (matrizId == null) {
      return _riesgosFiltrados;
    }

    return _riesgosFiltrados
        .where((_RiesgoMapaItem item) => item.matrizIdServidor == matrizId)
        .toList(growable: false);
  }

  List<_ZonaRiesgoInteractiva> get _zonasPlanoSeleccionado {
    final Map<String, List<_RiesgoMapaItem>> agrupados =
        <String, List<_RiesgoMapaItem>>{};

    for (final _RiesgoMapaItem item in _riesgosMatrizPlano) {
      agrupados.putIfAbsent(item.zona, () => <_RiesgoMapaItem>[]).add(item);
    }

    final List<_ZonaRiesgoInteractiva> zonas = agrupados.entries.map((
      MapEntry<String, List<_RiesgoMapaItem>> entry,
    ) {
      return _ZonaRiesgoInteractiva(nombre: entry.key, riesgos: entry.value);
    }).toList();

    zonas.sort(
      (_ZonaRiesgoInteractiva a, _ZonaRiesgoInteractiva b) =>
          b.valorMayor.compareTo(a.valorMayor),
    );

    return zonas;
  }

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    await _cargarConfiguracionPlano();
    await _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // =============================================================
  // MAPA PERSISTIDO: SQLITE + BACKEND
  // =============================================================

  Future<void> _cargarMapaPersistido({bool refrescarServidor = true}) async {
    final int? matrizId = _matrizMapaSeleccionada;

    if (matrizId == null || matrizId <= 0) {
      return;
    }

    if (mounted) {
      setState(() {
        _cargandoMapaPersistido = true;
        _planoServidorNoDisponible = false;
      });
    }

    try {
      List<MapaRiesgoLocalModel> mapas = await _mapaRiesgoRepository
          .obtenerLocalesPorMatriz(matrizId);

      if (refrescarServidor && _conectado) {
        try {
          mapas = await _mapaRiesgoRepository.refrescarDesdeServidor(matrizId);
        } catch (_) {
          // Si únicamente falla la imagen del plano remoto, no mostramos
          // un error general. Las matrices, riesgos y zonas continúan
          // disponibles y el usuario puede cargar un plano nuevo.
          if (mounted) {
            setState(() {
              _planoServidorNoDisponible = true;
            });
          }
        }
      }

      MapaRiesgoLocalModel? mapa;

      if (mapas.isNotEmpty) {
        mapa = mapas.first;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _mapaPersistido = mapa;

        if (mapa != null) {
          _planoServidorNoDisponible = false;
          if (mapa.archivoLocal != null &&
              mapa.archivoLocal!.trim().isNotEmpty) {
            _rutaPlano = mapa.archivoLocal;
          }

          _aplicarMarcadoresJson(mapa.marcadoresJson);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _advertencia =
              'No se pudo recuperar el mapa guardado: '
              '${_mensajeError(error)}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoMapaPersistido = false;
        });
      }
    }
  }

  void _aplicarMarcadoresJson(String? json) {
    final String contenido = json?.trim() ?? '';

    if (contenido.isEmpty) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(contenido);

      if (decoded is! Map) {
        return;
      }

      _posicionesMarcadores.clear();

      for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
        final dynamic value = entry.value;

        if (value is! Map) {
          continue;
        }

        final double? x = double.tryParse(value['x']?.toString() ?? '');

        final double? y = double.tryParse(value['y']?.toString() ?? '');

        if (x == null || y == null) {
          continue;
        }

        _posicionesMarcadores[entry.key.toString()] = Offset(
          x.clamp(0.0, 1.0),
          y.clamp(0.0, 1.0),
        );
      }
    } catch (_) {
      // Un JSON inválido no debe bloquear la pantalla.
    }
  }

  String _marcadoresComoJson() {
    final Map<String, Map<String, double>> json = <String, Map<String, double>>{
      for (final MapEntry<String, Offset> entry
          in _posicionesMarcadores.entries)
        entry.key: <String, double>{'x': entry.value.dx, 'y': entry.value.dy},
    };

    return jsonEncode(json);
  }

  Future<void> _guardarMapaServidor() async {
    final int? matrizId = _matrizMapaSeleccionada;

    if (matrizId == null || matrizId <= 0) {
      _mostrarMensaje(
        'Selecciona una matriz IPERC sincronizada.',
        esError: true,
      );
      return;
    }

    if (_rutaPlano == null || _rutaPlano!.trim().isEmpty) {
      _mostrarMensaje('Primero carga una imagen del plano.', esError: true);
      return;
    }

    if (!_conectado) {
      _MatrizMapaOption? matriz;

      for (final _MatrizMapaOption item in _matricesDisponiblesMapa) {
        if (item.id == matrizId) {
          matriz = item;
          break;
        }
      }

      try {
        final MapaRiesgoLocalModel pendiente = await _mapaRiesgoRepository
            .guardarPendienteOffline(
              matrizIpercId: matrizId,
              nombre: 'Mapa de riesgos ${matriz?.codigo ?? matrizId}',
              descripcion:
                  'Plano interactivo de riesgos asociado a la Matriz IPERC.',
              ubicacion: matriz?.nombre ?? 'Área evaluada',
              marcadoresJson: _marcadoresComoJson(),
              archivoLocal: _rutaPlano!,
              existente: _mapaPersistido,
              version: _mapaPersistido?.version ?? 1,
              estadoMapa: 'Vigente',
            );

        await _guardarMarcadores();

        if (!mounted) {
          return;
        }

        setState(() {
          _mapaPersistido = pendiente;
          _editandoPlano = false;
        });

        await _notificarCambioLocal();

        if (!mounted) {
          return;
        }

        _mostrarMensaje('Mapa guardado offline. Pendiente de sincronizar.');
      } catch (error) {
        _mostrarMensaje(
          'No se pudo guardar el mapa offline: '
          '${_mensajeError(error)}',
          esError: true,
        );
      }

      return;
    }

    if (_guardandoMapa) {
      return;
    }

    _MatrizMapaOption? matriz;

    for (final _MatrizMapaOption item in _matricesDisponiblesMapa) {
      if (item.id == matrizId) {
        matriz = item;
        break;
      }
    }

    setState(() {
      _guardandoMapa = true;
    });

    try {
      final MapaRiesgoLocalModel guardado = await _mapaRiesgoRepository
          .guardarEnServidor(
            matrizIpercId: matrizId,
            nombre: 'Mapa de riesgos ${matriz?.codigo ?? matrizId}',
            descripcion:
                'Plano interactivo de riesgos asociado a la Matriz IPERC.',
            ubicacion: matriz?.nombre ?? 'Área evaluada',
            marcadoresJson: _marcadoresComoJson(),
            archivoLocal: _rutaPlano,
            mapaIdServidor: _mapaPersistido?.idServidor,
            codigo: _mapaPersistido?.codigo,
            archivoUrlServidor: _mapaPersistido?.archivoUrlServidor,
            tipoArchivo: _mapaPersistido?.tipoArchivo,
            version: _mapaPersistido?.version ?? 1,
            estadoMapa: 'Vigente',
          );

      await _guardarMarcadores();

      if (!mounted) {
        return;
      }

      setState(() {
        _mapaPersistido = guardado;
        _rutaPlano = guardado.archivoLocal ?? _rutaPlano;
        _editandoPlano = false;
      });

      _mostrarMensaje('Plano y marcadores sincronizados con el servidor.');
    } catch (error) {
      _mostrarMensaje(
        'No se pudo guardar el mapa en el servidor: '
        '${_mensajeError(error)}',
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardandoMapa = false;
        });
      }
    }
  }

  // =============================================================
  // CONFIGURACIÓN DEL PLANO REAL
  // =============================================================

  Future<void> _notificarCambioLocal() async {
    if (!mounted) {
      return;
    }

    try {
      await context.read<SyncProvider>().notifyLocalChange();
    } catch (_) {
      // Local data and queue are already persisted.
      // A later refresh or connectivity change will retry.
    }
  }

  Future<void> _cargarConfiguracionPlano() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? ruta = prefs.getString(_prefRutaPlano);
      final String? posicionesJson = prefs.getString(_prefMarcadores);

      if (ruta != null && ruta.trim().isNotEmpty) {
        final File archivo = File(ruta);

        if (await archivo.exists()) {
          _rutaPlano = ruta;
        } else {
          await prefs.remove(_prefRutaPlano);
        }
      }

      if (posicionesJson != null && posicionesJson.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(posicionesJson);

        if (decoded is Map) {
          for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
            final dynamic value = entry.value;

            if (value is Map) {
              final double? x = double.tryParse(value['x']?.toString() ?? '');
              final double? y = double.tryParse(value['y']?.toString() ?? '');

              if (x != null && y != null) {
                _posicionesMarcadores[entry.key.toString()] = Offset(
                  x.clamp(0.0, 1.0),
                  y.clamp(0.0, 1.0),
                );
              }
            }
          }
        }
      }
    } catch (_) {
      // La falta de preferencias no debe impedir abrir el mapa.
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _guardarMarcadores() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final Map<String, Map<String, double>> json = <String, Map<String, double>>{
      for (final MapEntry<String, Offset> entry
          in _posicionesMarcadores.entries)
        entry.key: <String, double>{'x': entry.value.dx, 'y': entry.value.dy},
    };

    await prefs.setString(_prefMarcadores, jsonEncode(json));
  }

  Future<void> _seleccionarPlano() async {
    try {
      final XFile? seleccionada = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (seleccionada == null) {
        return;
      }

      final Directory directory = await getApplicationDocumentsDirectory();

      final Directory planosDir = Directory(
        p.join(directory.path, 'mapas_riesgo'),
      );

      if (!await planosDir.exists()) {
        await planosDir.create(recursive: true);
      }

      final String extension = p.extension(seleccionada.path).isEmpty
          ? '.jpg'
          : p.extension(seleccionada.path);

      final String destino = p.join(planosDir.path, 'plano_colegio$extension');

      final File origen = File(seleccionada.path);
      final File archivoDestino = File(destino);

      if (await archivoDestino.exists()) {
        await archivoDestino.delete();
      }

      await origen.copy(destino);

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString(_prefRutaPlano, destino);

      if (!mounted) {
        return;
      }

      setState(() {
        _rutaPlano = destino;
        _editandoPlano = true;
        _planoServidorNoDisponible = false;
      });

      _mostrarMensaje('Plano cargado. Arrastra los marcadores para ubicarlos.');
    } catch (error) {
      _mostrarMensaje(
        'No se pudo cargar el plano: ${_mensajeError(error)}',
        esError: true,
      );
    }
  }

  Future<void> _eliminarPlano() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.riskOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.riskOrange,
              size: 32,
            ),
          ),
          title: const Text(
            'Quitar plano',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Se quitara la imagen del plano y las posiciones de los '
            'marcadores. Si el mapa ya existe en el servidor, el cambio '
            'tambien se aplicara al sincronizar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.riskOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Quitar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final String? ruta = _rutaPlano;

      final MapaRiesgoLocalModel? actual = _mapaPersistido;

      MapaRiesgoLocalModel? limpio;

      if (actual != null) {
        limpio = await _mapaRiesgoRepository.quitarPlano(
          existente: actual,
          conectado: _conectado,
        );
      }

      // El archivo local se elimina solamente despues de que SQLite /
      // backend / cola hayan quedado en un estado coherente.
      if (ruta != null && ruta.trim().isNotEmpty) {
        final File archivo = File(ruta);

        if (await archivo.exists()) {
          await archivo.delete();
        }
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove(_prefRutaPlano);
      await prefs.remove(_prefMarcadores);

      if (!mounted) {
        return;
      }

      setState(() {
        _mapaPersistido = limpio ?? _mapaPersistido;
        _rutaPlano = null;
        _posicionesMarcadores.clear();
        _editandoPlano = false;
        _planoServidorNoDisponible = false;
      });

      if (actual != null) {
        await _notificarCambioLocal();

        if (!mounted) {
          return;
        }
      }

      final bool pendienteServidor =
          actual?.idServidor != null && actual!.idServidor! > 0 && !_conectado;

      if (pendienteServidor) {
        _mostrarMensaje(
          'Plano quitado del dispositivo. '
          'La eliminacion visual se sincronizara al recuperar Internet.',
        );
      } else if (actual?.idServidor != null && actual!.idServidor! > 0) {
        _mostrarMensaje('Plano y marcadores retirados correctamente.');
      } else {
        _mostrarMensaje('Plano local retirado correctamente.');
      }
    } catch (error) {
      _mostrarMensaje(
        'No se pudo quitar el plano: ${_mensajeError(error)}',
        esError: true,
      );
    }
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: esError ? AppColors.riskOrange : AppColors.green,
        ),
      );
  }

  Offset _posicionInicialMarcador(int index, int total) {
    if (total <= 0) {
      return const Offset(0.5, 0.5);
    }

    const int columnas = 3;
    final int fila = index ~/ columnas;
    final int columna = index % columnas;

    final int filas = ((total + columnas - 1) ~/ columnas).clamp(1, 100);

    final double x = ((columna + 1) / (columnas + 1)).clamp(0.08, 0.92);

    final double y = ((fila + 1) / (filas + 1)).clamp(0.08, 0.92);

    return Offset(x, y);
  }

  // =============================================================
  // CARGAR INFORMACIÓN
  // =============================================================

  Future<void> _cargar() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _advertencia = null;
    });

    final List<_RiesgoMapaItem> acumulados = <_RiesgoMapaItem>[];

    // -----------------------------------------------------------
    // 1. SQLITE
    // -----------------------------------------------------------

    try {
      final List<MatrizIpercLocalModel> matricesLocales =
          await _matrizLocalDatasource.getAll();

      final List<DetalleIpercLocalModel> detallesLocales =
          await _detalleLocalDatasource.listarTodos();

      acumulados.addAll(
        _convertirLocales(matrices: matricesLocales, detalles: detallesLocales),
      );
    } catch (error) {
      _advertencia = _mensajeError(error);
    }

    // -----------------------------------------------------------
    // 2. CONEXIÓN
    // -----------------------------------------------------------

    bool conectado = false;

    try {
      conectado = await _networkInfo.isConnected;
    } catch (_) {
      conectado = false;
    }

    // -----------------------------------------------------------
    // 3. BACKEND
    // -----------------------------------------------------------

    if (conectado) {
      try {
        final List<MatrizIpercModel> matricesRemotas = await _matrizRepository
            .obtenerMatrices();

        final List<List<DetalleIpercModel>> grupos =
            await Future.wait<List<DetalleIpercModel>>(
              matricesRemotas
                  .where((MatrizIpercModel matriz) => matriz.id > 0)
                  .map((MatrizIpercModel matriz) {
                    return _detalleRepository.obtenerPorMatriz(matriz.id);
                  }),
            );

        final List<DetalleIpercModel> detallesRemotos = grupos
            .expand((List<DetalleIpercModel> grupo) => grupo)
            .toList(growable: false);

        final List<_RiesgoMapaItem> remotos = _convertirRemotos(
          matrices: matricesRemotas,
          detalles: detallesRemotos,
        );

        _fusionarPreferiendoServidor(destino: acumulados, remotos: remotos);
      } catch (error) {
        _advertencia =
            'Se muestran los datos guardados en el dispositivo. '
            'No se pudo actualizar desde el servidor: ${_mensajeError(error)}';
      }
    }

    if (!mounted) {
      return;
    }

    acumulados.sort((_RiesgoMapaItem a, _RiesgoMapaItem b) {
      final int porRiesgo = b.valorRiesgoActual.compareTo(a.valorRiesgoActual);

      if (porRiesgo != 0) {
        return porRiesgo;
      }

      return a.zona.toLowerCase().compareTo(b.zona.toLowerCase());
    });

    setState(() {
      _conectado = conectado;

      _riesgos
        ..clear()
        ..addAll(acumulados);

      _cargando = false;

      if (_riesgos.isEmpty && _advertencia != null) {
        _error = _advertencia;
      }

      if (_zonaSeleccionada != 'TODAS' &&
          !_zonasDisponibles.contains(_zonaSeleccionada)) {
        _zonaSeleccionada = 'TODAS';
      }

      final List<_MatrizMapaOption> matrices = _matricesDisponiblesMapa;

      if (matrices.isNotEmpty &&
          (_matrizMapaSeleccionada == null ||
              !matrices.any(
                (_MatrizMapaOption item) => item.id == _matrizMapaSeleccionada,
              ))) {
        _matrizMapaSeleccionada = matrices.first.id;
      }
    });

    if (_matrizMapaSeleccionada != null) {
      await _cargarMapaPersistido(refrescarServidor: conectado);
    }
  }

  // =============================================================
  // CONVERTIR SQLITE
  // =============================================================

  List<_RiesgoMapaItem> _convertirLocales({
    required List<MatrizIpercLocalModel> matrices,
    required List<DetalleIpercLocalModel> detalles,
  }) {
    final Map<String, MatrizIpercLocalModel> matricesPorLocal =
        <String, MatrizIpercLocalModel>{
          for (final MatrizIpercLocalModel matriz in matrices)
            matriz.idLocal: matriz,
        };

    return detalles
        .map((DetalleIpercLocalModel detalle) {
          final MatrizIpercLocalModel? matriz =
              matricesPorLocal[detalle.matrizIdLocal];

          final String zona = _zonaLocal(matriz);

          final int? idServidor = int.tryParse(
            detalle.idServidor?.trim() ?? '',
          );

          return _RiesgoMapaItem(
            clave: idServidor != null && idServidor > 0
                ? 'S:$idServidor'
                : 'L:${detalle.idLocal}',
            detalleIdServidor: idServidor,
            detalleIdLocal: detalle.idLocal,
            matrizIdServidor: detalle.matrizIdServidor,
            matrizIdLocal: detalle.matrizIdLocal,
            matrizCodigo: _textoNoVacio(matriz?.codigo) ?? 'Matriz local',
            matrizNombre: _textoNoVacio(matriz?.nombre) ?? 'Matriz IPERC',
            zona: zona,
            item: detalle.item,
            tarea: _textoNoVacio(detalle.tarea) ?? 'Tarea no especificada',
            peligro:
                _textoNoVacio(detalle.peligroDescripcion) ??
                'Peligro no especificado',
            consecuencia:
                _textoNoVacio(detalle.consecuenciaDescripcion) ??
                'Consecuencia no especificada',
            valorInicial: detalle.valorRiesgoInicial,
            nivelInicial:
                _textoNoVacio(detalle.nivelRiesgoInicial) ??
                _nombreNivel(detalle.valorRiesgoInicial),
            valorResidual: detalle.valorRiesgoResidual,
            nivelResidual: _textoNoVacio(detalle.nivelRiesgoResidual),
            estadoImplementacion:
                _textoNoVacio(detalle.estadoImplementacion) ?? 'Pendiente',
            sincronizado: detalle.sincronizado,
            origenLocal: true,
          );
        })
        .toList(growable: false);
  }

  String _zonaLocal(MatrizIpercLocalModel? matriz) {
    if (matriz == null) {
      return 'Zona no identificada';
    }

    final String? area = _textoNoVacio(matriz.areaId);

    if (area != null) {
      return 'Área $area';
    }

    return _textoNoVacio(matriz.nombre) ?? 'Zona no identificada';
  }

  // =============================================================
  // CONVERTIR BACKEND
  // =============================================================

  List<_RiesgoMapaItem> _convertirRemotos({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
  }) {
    final Map<int, MatrizIpercModel> matricesPorId = <int, MatrizIpercModel>{
      for (final MatrizIpercModel matriz in matrices)
        if (matriz.id > 0) matriz.id: matriz,
    };

    return detalles
        .map((DetalleIpercModel detalle) {
          final MatrizIpercModel? matriz = matricesPorId[detalle.matrizIpercId];

          final EvaluacionDetalleIpercModel actual =
              detalle.evaluacionResidual ?? detalle.evaluacionInicial;

          return _RiesgoMapaItem(
            clave: 'S:${detalle.id}',
            detalleIdServidor: detalle.id,
            detalleIdLocal: null,
            matrizIdServidor: detalle.matrizIpercId,
            matrizIdLocal: null,
            matrizCodigo:
                _textoNoVacio(matriz?.codigo) ?? detalle.matrizIpercCodigo,
            matrizNombre: _textoNoVacio(matriz?.nombre) ?? 'Matriz IPERC',
            zona:
                _textoNoVacio(matriz?.areaNombre) ??
                matriz?.areaVisible ??
                'Zona no identificada',
            item: detalle.item,
            tarea: _textoNoVacio(detalle.tarea) ?? 'Tarea no especificada',
            peligro: detalle.peligroVisible,
            consecuencia: detalle.consecuenciaVisible,
            valorInicial: detalle.evaluacionInicial.valorRiesgo,
            nivelInicial:
                _textoNoVacio(detalle.evaluacionInicial.nivelRiesgoNombre) ??
                _nombreNivel(detalle.evaluacionInicial.valorRiesgo),
            valorResidual: detalle.evaluacionResidual?.valorRiesgo,
            nivelResidual: _textoNoVacio(
              detalle.evaluacionResidual?.nivelRiesgoNombre,
            ),
            estadoImplementacion:
                _textoNoVacio(detalle.estadoImplementacionNombre) ??
                'Pendiente',
            sincronizado: true,
            origenLocal: false,
            colorBackend: _textoNoVacio(actual.color),
          );
        })
        .toList(growable: false);
  }

  // =============================================================
  // FUSIONAR LOCAL + REMOTO
  // =============================================================

  void _fusionarPreferiendoServidor({
    required List<_RiesgoMapaItem> destino,
    required List<_RiesgoMapaItem> remotos,
  }) {
    final Map<String, int> indices = <String, int>{};

    for (int index = 0; index < destino.length; index++) {
      indices[destino[index].clave] = index;
    }

    for (final _RiesgoMapaItem remoto in remotos) {
      final int? index = indices[remoto.clave];

      if (index == null) {
        destino.add(remoto);
        indices[remoto.clave] = destino.length - 1;
        continue;
      }

      final _RiesgoMapaItem local = destino[index];

      // Conservamos el idLocal para que el módulo de Seguimientos
      // pueda seguir trabajando con SQLite, pero usamos los datos
      // del servidor como fuente visual principal.
      destino[index] = remoto.copyWith(
        detalleIdLocal: local.detalleIdLocal,
        matrizIdLocal: local.matrizIdLocal,
      );
    }
  }

  // =============================================================
  // FILTROS
  // =============================================================

  List<String> get _zonasDisponibles {
    final Set<String> zonas = _riesgos
        .map((_RiesgoMapaItem item) => item.zona)
        .where((String zona) => zona.trim().isNotEmpty)
        .toSet();

    final List<String> resultado = zonas.toList()..sort();

    return resultado;
  }

  List<_RiesgoMapaItem> get _riesgosFiltrados {
    final String termino = _normalizar(_busqueda);

    return _riesgos
        .where((_RiesgoMapaItem item) {
          if (_zonaSeleccionada != 'TODAS' && item.zona != _zonaSeleccionada) {
            return false;
          }

          if (_nivelSeleccionado != 'TODOS' &&
              _nivelFiltro(item.valorRiesgoActual) != _nivelSeleccionado) {
            return false;
          }

          if (termino.isEmpty) {
            return true;
          }

          final String contenido = _normalizar(
            '${item.zona} '
            '${item.matrizCodigo} '
            '${item.matrizNombre} '
            '${item.tarea} '
            '${item.peligro} '
            '${item.consecuencia} '
            '${item.estadoImplementacion}',
          );

          return contenido.contains(termino);
        })
        .toList(growable: false);
  }

  List<_ZonaRiesgoInteractiva> get _zonasFiltradas {
    final Map<String, List<_RiesgoMapaItem>> agrupados =
        <String, List<_RiesgoMapaItem>>{};

    for (final _RiesgoMapaItem item in _riesgosFiltrados) {
      agrupados.putIfAbsent(item.zona, () => <_RiesgoMapaItem>[]).add(item);
    }

    final List<_ZonaRiesgoInteractiva> zonas = agrupados.entries.map((
      MapEntry<String, List<_RiesgoMapaItem>> entry,
    ) {
      return _ZonaRiesgoInteractiva(nombre: entry.key, riesgos: entry.value);
    }).toList();

    zonas.sort((_ZonaRiesgoInteractiva a, _ZonaRiesgoInteractiva b) {
      return b.valorMayor.compareTo(a.valorMayor);
    });

    return zonas;
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  int get _totalRiesgos => _riesgos.length;

  int get _totalCriticos => _riesgos
      .where((_RiesgoMapaItem item) => item.valorRiesgoActual >= 17)
      .length;

  int get _totalAltos => _riesgos
      .where(
        (_RiesgoMapaItem item) =>
            item.valorRiesgoActual >= 10 && item.valorRiesgoActual <= 16,
      )
      .length;

  int get _totalMedios => _riesgos
      .where(
        (_RiesgoMapaItem item) =>
            item.valorRiesgoActual >= 5 && item.valorRiesgoActual <= 9,
      )
      .length;

  int get _totalBajos => _riesgos
      .where(
        (_RiesgoMapaItem item) =>
            item.valorRiesgoActual > 0 && item.valorRiesgoActual <= 4,
      )
      .length;

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
        title: const Text('Mapa de riesgos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargar,
        child: _contenido(),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _riesgos.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _riesgos.isEmpty) {
      return _construirError();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _construirEstadoConexion(),
        const SizedBox(height: 12),

        if (_advertencia != null) ...<Widget>[
          _construirAdvertencia(),
          const SizedBox(height: 12),
        ],

        _construirResumen(),
        const SizedBox(height: 16),

        _construirBuscador(),
        const SizedBox(height: 12),

        _construirFiltros(),
        const SizedBox(height: 16),

        _construirSelectorVista(),
        const SizedBox(height: 16),

        if (_riesgosFiltrados.isEmpty)
          _construirSinResultados()
        else
          switch (_vista) {
            _VistaMapaRiesgo.mapa => _construirVistaMapa(),
            _VistaMapaRiesgo.lista => _construirVistaLista(),
            _VistaMapaRiesgo.criticas => _construirVistaCriticas(),
          },
      ],
    );
  }

  // =============================================================
  // ESTADO CONEXIÓN
  // =============================================================

  Widget _construirEstadoConexion() {
    final bool online = _conectado;

    final Color baseColor = online ? AppColors.green : AppColors.yellow;

    final Color foreground = online ? AppColors.green : AppColors.navyDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: online ? 0.08 : 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: foreground,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  online
                      ? 'Datos locales + servidor'
                      : 'Mostrando datos guardados en el dispositivo',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAdvertencia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.50)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, color: AppColors.navyDark),
          const SizedBox(width: 10),
          Expanded(child: Text(_advertencia!)),
        ],
      ),
    );
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  Widget _construirResumen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Resumen',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _tarjetaResumen(
              titulo: 'Riesgos',
              valor: _totalRiesgos,
              icono: Icons.warning_amber_rounded,
              color: AppColors.primary,
              onTap: () => _aplicarNivel('TODOS'),
            ),
            _tarjetaResumen(
              titulo: 'Críticos',
              valor: _totalCriticos,
              icono: Icons.error_outline,
              color: Colors.red.shade800,
              onTap: () => _aplicarNivel('CRITICO'),
            ),
            _tarjetaResumen(
              titulo: 'Altos',
              valor: _totalAltos,
              icono: Icons.trending_up,
              color: Colors.orange.shade800,
              onTap: () => _aplicarNivel('ALTO'),
            ),
            _tarjetaResumen(
              titulo: 'Medios / Bajos',
              valor: _totalMedios + _totalBajos,
              icono: Icons.shield_outlined,
              color: Colors.green.shade700,
              onTap: () => _aplicarNivel('TODOS'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaResumen({
    required String titulo,
    required int valor,
    required IconData icono,
    required VoidCallback onTap,
    Color? color,
  }) {
    final Color principal = color ?? AppColors.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: principal.withValues(alpha: 0.12),
                foregroundColor: principal,
                child: Icon(icono),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$valor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // BUSCADOR Y FILTROS
  // =============================================================

  Widget _construirBuscador() {
    return TextField(
      controller: _busquedaController,
      onChanged: (String valor) {
        setState(() {
          _busqueda = valor;
        });
      },
      decoration: InputDecoration(
        labelText: 'Buscar peligro, tarea o zona',
        hintText: 'Ej.: electricidad, caída, almacén',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
                icon: const Icon(Icons.close, color: AppColors.primary),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _construirFiltros() {
    final List<String> zonas = _zonasDisponibles;

    return Column(
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _zonaSeleccionada,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Zona / área',
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: 'TODAS',
              child: Text('Todas las zonas'),
            ),
            ...zonas.map(
              (String zona) => DropdownMenuItem<String>(
                value: zona,
                child: Text(zona, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (String? valor) {
            setState(() {
              _zonaSeleccionada = valor ?? 'TODAS';
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _chipNivel('TODOS', 'Todos'),
            _chipNivel('CRITICO', 'Crítico'),
            _chipNivel('ALTO', 'Alto'),
            _chipNivel('MEDIO', 'Medio'),
            _chipNivel('BAJO', 'Bajo'),
          ],
        ),
      ],
    );
  }

  Widget _chipNivel(String valor, String texto) {
    final bool seleccionado = _nivelSeleccionado == valor;

    return FilterChip(
      selected: seleccionado,
      label: Text(texto),
      onSelected: (_) => _aplicarNivel(valor),
    );
  }

  void _aplicarNivel(String nivel) {
    setState(() {
      _nivelSeleccionado = nivel;
    });
  }

  // =============================================================
  // SELECTOR VISTA
  // =============================================================

  Widget _construirSelectorVista() {
    return SegmentedButton<_VistaMapaRiesgo>(
      segments: const <ButtonSegment<_VistaMapaRiesgo>>[
        ButtonSegment<_VistaMapaRiesgo>(
          value: _VistaMapaRiesgo.mapa,
          icon: Icon(Icons.grid_view_outlined),
          label: Text('Mapa'),
        ),
        ButtonSegment<_VistaMapaRiesgo>(
          value: _VistaMapaRiesgo.lista,
          icon: Icon(Icons.view_list_outlined),
          label: Text('Lista'),
        ),
        ButtonSegment<_VistaMapaRiesgo>(
          value: _VistaMapaRiesgo.criticas,
          icon: Icon(Icons.priority_high),
          label: Text('Críticas'),
        ),
      ],
      selected: <_VistaMapaRiesgo>{_vista},
      onSelectionChanged: (Set<_VistaMapaRiesgo> valores) {
        if (valores.isEmpty) {
          return;
        }

        setState(() {
          _vista = valores.first;
        });
      },
    );
  }

  // =============================================================
  // VISTA MAPA POR ZONAS
  // =============================================================

  Widget _construirVistaMapa() {
    final List<_ZonaRiesgoInteractiva> zonas = _zonasPlanoSeleccionado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _rutaPlano == null
                        ? 'Plano interactivo'
                        : 'Plano real del colegio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _rutaPlano == null
                        ? 'Puedes usar el plano automático o cargar una imagen real.'
                        : _editandoPlano
                        ? 'Arrastra cada marcador hasta su ambiente.'
                        : 'Toca un marcador para revisar los riesgos de esa zona.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _rutaPlano == null
                  ? Icons.touch_app_outlined
                  : Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_matricesDisponiblesMapa.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _matrizMapaSeleccionada,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Matriz IPERC del plano',
              prefixIcon: const Icon(Icons.assignment_outlined),
              suffixIcon: _cargandoMapaPersistido
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            items: _matricesDisponiblesMapa
                .map(
                  (_MatrizMapaOption matriz) => DropdownMenuItem<int>(
                    value: matriz.id,
                    child: Text(
                      '${matriz.codigo} · ${matriz.nombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _cargandoMapaPersistido
                ? null
                : (int? value) async {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _matrizMapaSeleccionada = value;
                      _mapaPersistido = null;
                      _rutaPlano = null;
                      _posicionesMarcadores.clear();
                      _editandoPlano = false;
                      _planoServidorNoDisponible = false;
                    });

                    await _cargarMapaPersistido(refrescarServidor: _conectado);
                  },
          ),

        if (_matricesDisponiblesMapa.isNotEmpty) const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _seleccionarPlano,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _rutaPlano == null ? 'Cargar plano' : 'Cambiar plano',
              ),
            ),

            if (_rutaPlano != null)
              OutlinedButton.icon(
                onPressed: () => _verPlanoPantallaCompleta(zonas),
                icon: const Icon(Icons.fullscreen_outlined),
                label: const Text('Ver plano'),
              ),

            if (_rutaPlano != null)
              OutlinedButton.icon(
                onPressed: _guardandoMapa
                    ? null
                    : () async {
                        if (!_editandoPlano) {
                          setState(() {
                            _editandoPlano = true;
                          });
                          return;
                        }

                        await _guardarMapaServidor();
                      },
                icon: _guardandoMapa
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _editandoPlano
                            ? Icons.cloud_upload_outlined
                            : Icons.edit_location_alt_outlined,
                      ),
                label: Text(
                  _guardandoMapa
                      ? 'Guardando...'
                      : _editandoPlano
                      ? 'Guardar y sincronizar'
                      : 'Editar marcadores',
                ),
              ),
            if (_rutaPlano != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.riskOrange,
                ),
                onPressed: _eliminarPlano,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar plano'),
              ),
          ],
        ),

        const SizedBox(height: 14),

        if (_rutaPlano == null && _planoServidorNoDisponible)
          _planoServidorNoDisponibleCard()
        else if (_rutaPlano == null)
          _planoAutomatico(zonas)
        else ...<Widget>[
          _planoImagenReal(zonas),
          const SizedBox(height: 18),

          // -------------------------------------------------------
          // LOS CUADROS DE RIESGO NO DESAPARECEN AL CARGAR EL PLANO
          // -------------------------------------------------------
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Riesgos por zona',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${zonas.length} zonas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Los cuadros permanecen visibles aunque exista un plano cargado.',
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: zonas.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 170,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _tarjetaZona(zonas[index]);
            },
          ),
        ],

        const SizedBox(height: 16),
        _construirLeyenda(),
        const SizedBox(height: 10),

        Text(
          _rutaPlano == null
              ? 'Toca cualquier ambiente para revisar sus riesgos.'
              : _editandoPlano
              ? 'Mantén y arrastra cada marcador para posicionarlo. '
                    'Los cuadros de riesgos permanecen visibles debajo.'
              : 'Toca un marcador o un cuadro de zona para revisar sus riesgos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _verPlanoPantallaCompleta(
    List<_ZonaRiesgoInteractiva> zonas,
  ) async {
    final String? ruta = _rutaPlano;

    if (ruta == null || ruta.trim().isEmpty) {
      _mostrarMensaje(
        'No hay un plano disponible para visualizar.',
        esError: true,
      );
      return;
    }

    final File archivo = File(ruta);

    if (!await archivo.exists()) {
      if (!mounted) {
        return;
      }

      setState(() {
        _planoServidorNoDisponible = true;
        _rutaPlano = null;
      });

      _mostrarMensaje(
        'El archivo del plano ya no está disponible. '
        'Puedes cargar uno nuevo.',
        esError: true,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _PlanoRiesgoViewerScreen(
          rutaPlano: ruta,
          zonas: zonas,
          posicionesMarcadores: Map<String, Offset>.from(_posicionesMarcadores),
          colorResolver: _colorRiesgo,
          onAbrirZona: _abrirZona,
        ),
      ),
    );
  }

  Widget _planoServidorNoDisponibleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'Plano no disponible',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los riesgos siguen disponibles. Puedes cargar un nuevo plano '
            'para volver a ubicar los marcadores.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _seleccionarPlano,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Cargar nuevo plano'),
          ),
        ],
      ),
    );
  }

  Widget _planoAutomatico(List<_ZonaRiesgoInteractiva> zonas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          _encabezadoPlano(),
          const SizedBox(height: 10),
          _planoDinamico(zonas),
          const SizedBox(height: 10),
          _pasilloPlano(),
        ],
      ),
    );
  }

  Widget _planoImagenReal(List<_ZonaRiesgoInteractiva> zonas) {
    final String ruta = _rutaPlano!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ancho = constraints.maxWidth;
        final double alto = (ancho * 0.72).clamp(300.0, 620.0);

        return Container(
          width: ancho,
          height: alto,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              InteractiveViewer(
                minScale: 1,
                maxScale: _editandoPlano ? 1 : 4,
                panEnabled: !_editandoPlano,
                scaleEnabled: !_editandoPlano,
                child: Image.file(
                  File(ruta),
                  fit: BoxFit.contain,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Text(
                            'No se pudo mostrar la imagen del plano.',
                          ),
                        );
                      },
                ),
              ),

              for (int index = 0; index < zonas.length; index++)
                _marcadorSobrePlano(
                  zona: zonas[index],
                  index: index,
                  total: zonas.length,
                  ancho: ancho,
                  alto: alto,
                ),

              Positioned(
                left: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: Text(
                      _editandoPlano ? 'MODO EDICIÓN' : 'PLANO INTERACTIVO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _marcadorSobrePlano({
    required _ZonaRiesgoInteractiva zona,
    required int index,
    required int total,
    required double ancho,
    required double alto,
  }) {
    final Color color = _colorRiesgo(zona.valorMayor);

    final Offset normalizada =
        _posicionesMarcadores[zona.nombre] ??
        _posicionInicialMarcador(index, total);

    const double markerWidth = 72;
    const double markerHeight = 62;

    final double left = (normalizada.dx * ancho - markerWidth / 2).clamp(
      0.0,
      (ancho - markerWidth).clamp(0.0, ancho),
    );

    final double top = (normalizada.dy * alto - markerHeight / 2).clamp(
      0.0,
      (alto - markerHeight).clamp(0.0, alto),
    );

    return Positioned(
      left: left,
      top: top,
      width: markerWidth,
      height: markerHeight,
      child: GestureDetector(
        onTap: _editandoPlano ? null : () => _abrirZona(zona),
        onPanUpdate: !_editandoPlano
            ? null
            : (DragUpdateDetails details) {
                final double nuevoX =
                    (normalizada.dx + details.delta.dx / ancho).clamp(
                      0.04,
                      0.96,
                    );

                final double nuevoY = (normalizada.dy + details.delta.dy / alto)
                    .clamp(0.04, 0.96);

                setState(() {
                  _posicionesMarcadores[zona.nombre] = Offset(nuevoX, nuevoY);
                });
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    blurRadius: 5,
                    offset: Offset(0, 2),
                    color: Colors.black38,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                zona.valorMayor > 0 ? '${zona.valorMayor}' : '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: markerWidth),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                zona.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encabezado superior del plano.
  Widget _encabezadoPlano() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.apartment_outlined, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'PLANO DE RIESGOS SST',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${_zonasFiltradas.length} zonas',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Genera automáticamente la distribución visual de las áreas.
  ///
  /// No pretende reemplazar el plano arquitectónico oficial:
  /// organiza las áreas IPERC disponibles como ambientes pulsables.
  Widget _planoDinamico(List<_ZonaRiesgoInteractiva> zonas) {
    if (zonas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay zonas disponibles para construir el plano.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 520;

        final int columnas = compacto
            ? 2
            : constraints.maxWidth < 820
            ? 3
            : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: zonas.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: compacto ? 1.15 : 1.35,
          ),
          itemBuilder: (BuildContext context, int index) {
            final _ZonaRiesgoInteractiva zona = zonas[index];

            return _ambientePlano(zona: zona, numero: index + 1);
          },
        );
      },
    );
  }

  /// Ambiente o zona dentro del plano.
  Widget _ambientePlano({
    required _ZonaRiesgoInteractiva zona,
    required int numero,
  }) {
    final Color color = _colorRiesgo(zona.valorMayor);

    final bool critica = zona.valorMayor >= 17;

    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirZona(zona),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: critica ? 3 : 2),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    zona.valorMayor > 0 ? '${zona.valorMayor}' : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(_iconoZona(zona.nombre), color: color, size: 27),
                    const Spacer(),
                    Text(
                      zona.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${zona.riesgos.length} '
                      '${zona.riesgos.length == 1 ? 'riesgo' : 'riesgos'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nombreNivel(zona.valorMayor),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Número visual del ambiente.
              Positioned(
                left: 7,
                top: 6,
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

              if (critica)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(Icons.priority_high, color: color, size: 19),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Representación visual de un pasillo central.
  Widget _pasilloPlano() {
    return Container(
      width: double.infinity,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.directions_walk,
              size: 17,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              'PASILLO / CIRCULACIÓN',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona un ícono aproximado según el nombre de la zona.
  IconData _iconoZona(String nombre) {
    final String texto = _normalizar(nombre);

    if (texto.contains('laboratorio')) {
      return Icons.science_outlined;
    }

    if (texto.contains('almacen')) {
      return Icons.inventory_2_outlined;
    }

    if (texto.contains('administr')) {
      return Icons.business_center_outlined;
    }

    if (texto.contains('direccion')) {
      return Icons.account_balance_outlined;
    }

    if (texto.contains('secret')) {
      return Icons.description_outlined;
    }

    if (texto.contains('aula') || texto.contains('innovacion')) {
      return Icons.computer_outlined;
    }

    if (texto.contains('patio')) {
      return Icons.park_outlined;
    }

    if (texto.contains('biblioteca')) {
      return Icons.local_library_outlined;
    }

    if (texto.contains('cocina') || texto.contains('comedor')) {
      return Icons.restaurant_outlined;
    }

    if (texto.contains('servicio') || texto.contains('bano')) {
      return Icons.wc_outlined;
    }

    if (texto.contains('taller')) {
      return Icons.handyman_outlined;
    }

    return Icons.meeting_room_outlined;
  }

  // =============================================================
  // TARJETA DE ZONA
  // =============================================================

  Widget _tarjetaZona(_ZonaRiesgoInteractiva zona) {
    final Color color = _colorRiesgo(zona.valorMayor);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirZona(zona),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color, width: 6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                    child: Icon(_iconoZona(zona.nombre), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      zona.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${zona.riesgos.length} '
                '${zona.riesgos.length == 1 ? 'riesgo' : 'riesgos'}',
              ),
              const SizedBox(height: 4),
              Text(
                zona.valorMayor > 0
                    ? 'Máximo: ${zona.valorMayor} · ${_nombreNivel(zona.valorMayor)}'
                    : 'Sin evaluar',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (zona.valorMayor.clamp(0, 25) / 25).toDouble(),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // VISTA LISTA
  // =============================================================

  Widget _construirVistaLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${_riesgosFiltrados.length} riesgos identificados',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._riesgosFiltrados.map(_tarjetaRiesgo),
      ],
    );
  }

  // =============================================================
  // VISTA CRÍTICAS
  // =============================================================

  Widget _construirVistaCriticas() {
    final List<_ZonaRiesgoInteractiva> zonas = _zonasFiltradas
        .where((_ZonaRiesgoInteractiva zona) => zona.valorMayor >= 10)
        .toList(growable: false);

    if (zonas.isEmpty) {
      return _construirSinResultados(
        mensaje:
            'No hay zonas con riesgos altos o críticos para los filtros actuales.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ranking de zonas críticas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (int index = 0; index < zonas.length; index++)
          _tarjetaRanking(posicion: index + 1, zona: zonas[index]),
      ],
    );
  }

  Widget _tarjetaRanking({
    required int posicion,
    required _ZonaRiesgoInteractiva zona,
  }) {
    final Color color = _colorRiesgo(zona.valorMayor);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _abrirZona(zona),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(
            '$posicion',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          zona.nombre,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${zona.riesgos.length} riesgos identificados'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${zona.valorMayor}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _nombreNivel(zona.valorMayor),
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // DETALLE DE ZONA
  // =============================================================

  Future<void> _abrirZona(_ZonaRiesgoInteractiva zona) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: <Widget>[
                Text(
                  zona.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${zona.riesgos.length} riesgos · '
                  'máximo ${zona.valorMayor}',
                ),
                const SizedBox(height: 16),
                ...zona.riesgos.map(_tarjetaRiesgo),
              ],
            );
          },
        );
      },
    );
  }

  // =============================================================
  // TARJETA DE RIESGO
  // =============================================================

  Widget _tarjetaRiesgo(_RiesgoMapaItem item) {
    final Color color = _colorRiesgo(item.valorRiesgoActual);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _mostrarDetalleRiesgo(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    child: Text(
                      '${item.valorRiesgoActual}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.peligro,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.tarea,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  Chip(
                    label: Text(
                      '${item.valorRiesgoActual} · ${item.nivelActual}',
                    ),
                    side: BorderSide(color: color),
                  ),
                  Chip(
                    avatar: Icon(
                      item.sincronizado
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      size: 17,
                    ),
                    label: Text(
                      item.sincronizado ? 'Sincronizado' : 'Pendiente',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.zona,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FICHA DE RIESGO
  // =============================================================

  Future<void> _mostrarDetalleRiesgo(_RiesgoMapaItem item) async {
    final Color color = _colorRiesgo(item.valorRiesgoActual);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      child: Text(
                        '${item.valorRiesgoActual}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.peligro,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.zona,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _filaDetalle(
                  icono: Icons.assignment_outlined,
                  titulo: 'Matriz',
                  valor: '${item.matrizCodigo} · ${item.matrizNombre}',
                ),
                _filaDetalle(
                  icono: Icons.work_outline,
                  titulo: 'Tarea',
                  valor: item.tarea,
                ),
                _filaDetalle(
                  icono: Icons.report_problem_outlined,
                  titulo: 'Consecuencia',
                  valor: item.consecuencia,
                ),
                _filaDetalle(
                  icono: Icons.construction_outlined,
                  titulo: 'Estado',
                  valor: item.estadoImplementacion,
                ),
                const Divider(height: 28),
                Text(
                  'Evaluación del riesgo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _tarjetaEvaluacion(
                        titulo: 'Inicial',
                        valor: item.valorInicial,
                        nivel: item.nivelInicial,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tarjetaEvaluacion(
                        titulo: 'Residual',
                        valor: item.valorResidual ?? item.valorInicial,
                        nivel: item.nivelResidual ?? 'Sin evaluación residual',
                        sinResidual: item.valorResidual == null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(modalContext).pop();
                      _abrirSeguimientos(item);
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ver seguimientos'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filaDetalle({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaEvaluacion({
    required String titulo,
    required int valor,
    required String nivel,
    bool sinResidual = false,
  }) {
    final Color color = sinResidual ? Colors.grey : _colorRiesgo(valor);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            sinResidual ? '—' : '$valor',
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            nivel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SEGUIMIENTOS
  // =============================================================

  Future<void> _abrirSeguimientos(_RiesgoMapaItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientosIpercScreen(
          detalleIpercId: item.detalleIdServidor,
          detalleIpercIdLocal: item.detalleIdLocal,
          titulo: 'Seguimientos · ${item.peligro}',
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargar();
  }

  // =============================================================
  // LEYENDA
  // =============================================================

  Widget _construirLeyenda() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        _leyenda(color: Colors.green.shade700, texto: 'Bajo 1–4'),
        _leyenda(color: Colors.amber.shade800, texto: 'Medio 5–9'),
        _leyenda(color: Colors.orange.shade800, texto: 'Alto 10–16'),
        _leyenda(color: Colors.red.shade800, texto: 'Crítico 17–25'),
      ],
    );
  }

  Widget _leyenda({required Color color, required String texto}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(texto),
      ],
    );
  }

  // =============================================================
  // SIN RESULTADOS
  // =============================================================

  Widget _construirSinResultados({String? mensaje}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.map_outlined,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            mensaje ??
                'No se encontraron riesgos con los filtros seleccionados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _limpiarFiltros,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  void _limpiarFiltros() {
    _busquedaController.clear();

    setState(() {
      _busqueda = '';
      _nivelSeleccionado = 'TODOS';
      _zonaSeleccionada = 'TODAS';
    });
  }

  // =============================================================
  // ERROR
  // =============================================================

  Widget _construirError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 80, color: AppColors.riskOrange),
        const SizedBox(height: 16),
        Text(
          'No se pudo cargar el mapa de riesgos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Ocurrió un error inesperado.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _cargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }

  // =============================================================
  // UTILIDADES
  // =============================================================

  Color _colorRiesgo(int valor) {
    if (valor <= 0) {
      return Colors.grey.shade600;
    }

    if (valor <= 4) {
      return Colors.green.shade700;
    }

    if (valor <= 9) {
      return Colors.amber.shade800;
    }

    if (valor <= 16) {
      return Colors.orange.shade800;
    }

    return Colors.red.shade800;
  }

  static String _nombreNivel(int valor) {
    if (valor <= 0) {
      return 'Sin evaluar';
    }

    if (valor <= 4) {
      return 'Bajo';
    }

    if (valor <= 9) {
      return 'Medio';
    }

    if (valor <= 16) {
      return 'Alto';
    }

    return 'Crítico';
  }

  static String _nivelFiltro(int valor) {
    if (valor <= 4) {
      return 'BAJO';
    }

    if (valor <= 9) {
      return 'MEDIO';
    }

    if (valor <= 16) {
      return 'ALTO';
    }

    return 'CRITICO';
  }

  static String? _textoNoVacio(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  static String _normalizar(String valor) {
    return valor
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  static String _mensajeError(Object error) {
    return error.toString().replaceFirst('Exception:', '').trim();
  }
}

// ===============================================================
// VISOR DE PLANO EN PANTALLA COMPLETA
// ===============================================================

class _PlanoRiesgoViewerScreen extends StatelessWidget {
  const _PlanoRiesgoViewerScreen({
    required this.rutaPlano,
    required this.zonas,
    required this.posicionesMarcadores,
    required this.colorResolver,
    required this.onAbrirZona,
  });

  final String rutaPlano;
  final List<_ZonaRiesgoInteractiva> zonas;
  final Map<String, Offset> posicionesMarcadores;
  final Color Function(int valor) colorResolver;
  final Future<void> Function(_ZonaRiesgoInteractiva zona) onAbrirZona;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Plano de riesgos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double ancho = constraints.maxWidth;
            final double alto = constraints.maxHeight;

            return InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: ancho,
                height: alto,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Center(
                      child: Image.file(
                        File(rutaPlano),
                        fit: BoxFit.contain,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return const Center(
                                child: Text(
                                  'No se pudo mostrar el plano.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                      ),
                    ),

                    for (int index = 0; index < zonas.length; index++)
                      _marcador(
                        context: context,
                        zona: zonas[index],
                        index: index,
                        ancho: ancho,
                        alto: alto,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _marcador({
    required BuildContext context,
    required _ZonaRiesgoInteractiva zona,
    required int index,
    required double ancho,
    required double alto,
  }) {
    final Color color = colorResolver(zona.valorMayor);

    final Offset normalizada =
        posicionesMarcadores[zona.nombre] ??
        _posicionInicial(index, zonas.length);

    const double markerWidth = 78;
    const double markerHeight = 66;

    final double left = (normalizada.dx * ancho - markerWidth / 2).clamp(
      0.0,
      (ancho - markerWidth).clamp(0.0, ancho),
    );

    final double top = (normalizada.dy * alto - markerHeight / 2).clamp(
      0.0,
      (alto - markerHeight).clamp(0.0, alto),
    );

    return Positioned(
      left: left,
      top: top,
      width: markerWidth,
      height: markerHeight,
      child: GestureDetector(
        onTap: () async {
          await onAbrirZona(zona);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 2),
                    color: Colors.black54,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                zona.valorMayor > 0 ? '${zona.valorMayor}' : '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: markerWidth),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                zona.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Offset _posicionInicial(int index, int total) {
    if (total <= 0) {
      return const Offset(0.5, 0.5);
    }

    const int columnas = 3;

    final int fila = index ~/ columnas;
    final int columna = index % columnas;

    final int filas = ((total + columnas - 1) ~/ columnas).clamp(1, 100);

    final double x = ((columna + 1) / (columnas + 1)).clamp(0.08, 0.92);

    final double y = ((fila + 1) / (filas + 1)).clamp(0.08, 0.92);

    return Offset(x, y);
  }
}

// ===============================================================
// VISTA
// ===============================================================

enum _VistaMapaRiesgo { mapa, lista, criticas }

// ===============================================================
// OPCIÓN DE MATRIZ PARA EL PLANO
// ===============================================================

class _MatrizMapaOption {
  const _MatrizMapaOption({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  final int id;
  final String codigo;
  final String nombre;
}

// ===============================================================
// MODELO UNIFICADO PARA LA PANTALLA
// ===============================================================

class _RiesgoMapaItem {
  const _RiesgoMapaItem({
    required this.clave,
    required this.detalleIdServidor,
    required this.detalleIdLocal,
    required this.matrizIdServidor,
    required this.matrizIdLocal,
    required this.matrizCodigo,
    required this.matrizNombre,
    required this.zona,
    required this.item,
    required this.tarea,
    required this.peligro,
    required this.consecuencia,
    required this.valorInicial,
    required this.nivelInicial,
    required this.valorResidual,
    required this.nivelResidual,
    required this.estadoImplementacion,
    required this.sincronizado,
    required this.origenLocal,
    this.colorBackend,
  });

  final String clave;

  final int? detalleIdServidor;
  final String? detalleIdLocal;

  final int? matrizIdServidor;
  final String? matrizIdLocal;

  final String matrizCodigo;
  final String matrizNombre;
  final String zona;

  final int item;
  final String tarea;
  final String peligro;
  final String consecuencia;

  final int valorInicial;
  final String nivelInicial;

  final int? valorResidual;
  final String? nivelResidual;

  final String estadoImplementacion;

  final bool sincronizado;
  final bool origenLocal;

  final String? colorBackend;

  int get valorRiesgoActual => valorResidual ?? valorInicial;

  String get nivelActual {
    final String residual = nivelResidual?.trim() ?? '';

    if (valorResidual != null && residual.isNotEmpty) {
      return residual;
    }

    final String inicial = nivelInicial.trim();

    if (inicial.isNotEmpty) {
      return inicial;
    }

    return _MapasRiesgoScreenState._nombreNivel(valorRiesgoActual);
  }

  _RiesgoMapaItem copyWith({String? detalleIdLocal, String? matrizIdLocal}) {
    return _RiesgoMapaItem(
      clave: clave,
      detalleIdServidor: detalleIdServidor,
      detalleIdLocal: detalleIdLocal ?? this.detalleIdLocal,
      matrizIdServidor: matrizIdServidor,
      matrizIdLocal: matrizIdLocal ?? this.matrizIdLocal,
      matrizCodigo: matrizCodigo,
      matrizNombre: matrizNombre,
      zona: zona,
      item: item,
      tarea: tarea,
      peligro: peligro,
      consecuencia: consecuencia,
      valorInicial: valorInicial,
      nivelInicial: nivelInicial,
      valorResidual: valorResidual,
      nivelResidual: nivelResidual,
      estadoImplementacion: estadoImplementacion,
      sincronizado: sincronizado,
      origenLocal: origenLocal,
      colorBackend: colorBackend,
    );
  }
}

// ===============================================================
// ZONA AGRUPADA
// ===============================================================

class _ZonaRiesgoInteractiva {
  const _ZonaRiesgoInteractiva({required this.nombre, required this.riesgos});

  final String nombre;
  final List<_RiesgoMapaItem> riesgos;

  int get valorMayor {
    if (riesgos.isEmpty) {
      return 0;
    }

    int mayor = 0;

    for (final _RiesgoMapaItem riesgo in riesgos) {
      if (riesgo.valorRiesgoActual > mayor) {
        mayor = riesgo.valorRiesgoActual;
      }
    }

    return mayor;
  }
}
