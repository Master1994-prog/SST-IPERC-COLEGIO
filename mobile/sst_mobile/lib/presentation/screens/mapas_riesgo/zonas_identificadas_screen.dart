import 'package:flutter/material.dart';

import '../../../core/network/network_info.dart';
import '../../../data/datasources/local/detalle_iperc_local_datasource.dart';
import '../../../data/datasources/local/matriz_iperc_local_datasource.dart';
import '../../../data/models/detalle_iperc_local_model.dart';
import '../../../data/models/detalle_iperc_model.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/detalle_iperc_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';

/// ===============================================================
/// ZONAS IDENTIFICADAS - VERSIÓN INTERACTIVA
/// ===============================================================
///
/// Complementa al Mapa de Riesgos.
///
/// Funciones:
///
/// - Lee matrices y detalles desde SQLite.
/// - Si existe Internet, completa/actualiza con datos del backend.
/// - Agrupa las matrices por zona o área.
/// - Permite buscar por zona, matriz, peligro o tarea.
/// - Permite filtrar por criticidad.
/// - Muestra resumen de zonas.
/// - Muestra ranking de zonas por nivel máximo de riesgo.
/// - Permite abrir una zona y revisar todos sus riesgos.
/// - Muestra riesgo inicial y residual.
/// ===============================================================
class ZonasIdentificadasScreen extends StatefulWidget {
  const ZonasIdentificadasScreen({super.key});

  @override
  State<ZonasIdentificadasScreen> createState() =>
      _ZonasIdentificadasScreenState();
}

class _ZonasIdentificadasScreenState extends State<ZonasIdentificadasScreen> {
  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final NetworkInfo _networkInfo = NetworkInfo.instance;

  final MatrizIpercRepository _matrizRepository = MatrizIpercRepository();

  final DetalleIpercRepository _detalleRepository = DetalleIpercRepository();

  final MatrizIpercLocalDatasource _matrizLocalDatasource =
      MatrizIpercLocalDatasource();

  final DetalleIpercLocalDatasource _detalleLocalDatasource =
      DetalleIpercLocalDatasource();

  // =============================================================
  // ESTADO
  // =============================================================

  final TextEditingController _busquedaController = TextEditingController();

  final List<_ZonaItem> _zonas = <_ZonaItem>[];

  bool _cargando = true;
  bool _conectado = false;

  String? _error;
  String? _advertencia;

  String _busqueda = '';
  String _filtro = 'TODAS';

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // =============================================================
  // CARGAR
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

    final List<_ZonaItem> zonasLocales = <_ZonaItem>[];

    // -----------------------------------------------------------
    // 1. CARGA LOCAL
    // -----------------------------------------------------------

    try {
      final List<MatrizIpercLocalModel> matrices = await _matrizLocalDatasource
          .getAll();

      final List<DetalleIpercLocalModel> detalles =
          await _detalleLocalDatasource.listarTodos();

      zonasLocales.addAll(
        _crearZonasLocales(matrices: matrices, detalles: detalles),
      );
    } catch (error) {
      _advertencia = _limpiarError(error);
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
    // 3. CARGA REMOTA
    // -----------------------------------------------------------

    if (conectado) {
      try {
        final List<MatrizIpercModel> matrices = await _matrizRepository
            .obtenerMatrices();

        final List<List<DetalleIpercModel>> resultados =
            await Future.wait<List<DetalleIpercModel>>(
              matrices.where((MatrizIpercModel matriz) => matriz.id > 0).map((
                MatrizIpercModel matriz,
              ) {
                return _detalleRepository.obtenerPorMatriz(matriz.id);
              }),
            );

        final List<DetalleIpercModel> detalles = resultados
            .expand((List<DetalleIpercModel> lista) => lista)
            .toList(growable: false);

        final List<_ZonaItem> zonasRemotas = _crearZonasRemotas(
          matrices: matrices,
          detalles: detalles,
        );

        _fusionarZonas(locales: zonasLocales, remotas: zonasRemotas);
      } catch (error) {
        _advertencia =
            'Se muestran los datos guardados localmente. '
            'No se pudo actualizar desde el servidor: '
            '${_limpiarError(error)}';
      }
    }

    zonasLocales.sort((_ZonaItem a, _ZonaItem b) {
      final int comparacion = b.valorMayor.compareTo(a.valorMayor);

      if (comparacion != 0) {
        return comparacion;
      }

      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _conectado = conectado;

      _zonas
        ..clear()
        ..addAll(zonasLocales);

      if (_zonas.isEmpty && _advertencia != null) {
        _error = _advertencia;
      }

      _cargando = false;
    });
  }

  // =============================================================
  // ZONAS LOCALES
  // =============================================================

  List<_ZonaItem> _crearZonasLocales({
    required List<MatrizIpercLocalModel> matrices,
    required List<DetalleIpercLocalModel> detalles,
  }) {
    final Map<String, _ZonaBuilder> agrupadas = <String, _ZonaBuilder>{};

    for (final MatrizIpercLocalModel matriz in matrices) {
      final String zona = _zonaLocal(matriz);

      final _ZonaBuilder builder = agrupadas.putIfAbsent(
        zona,
        () => _ZonaBuilder(nombre: zona),
      );

      builder.matrices.add(
        _MatrizZonaItem(
          clave: _claveMatrizLocal(matriz),
          idServidor: int.tryParse(matriz.idServidor?.trim() ?? ''),
          idLocal: matriz.idLocal,
          codigo: _texto(matriz.codigo) ?? 'LOCAL',
          nombre: _texto(matriz.nombre) ?? 'Matriz IPERC',
          sincronizada: matriz.sincronizado,
        ),
      );
    }

    final Map<String, MatrizIpercLocalModel> matricesPorId =
        <String, MatrizIpercLocalModel>{
          for (final MatrizIpercLocalModel matriz in matrices)
            matriz.idLocal: matriz,
        };

    for (final DetalleIpercLocalModel detalle in detalles) {
      final MatrizIpercLocalModel? matriz =
          matricesPorId[detalle.matrizIdLocal];

      final String zona = matriz == null
          ? 'Zona no identificada'
          : _zonaLocal(matriz);

      final _ZonaBuilder builder = agrupadas.putIfAbsent(
        zona,
        () => _ZonaBuilder(nombre: zona),
      );

      final int? idServidor = int.tryParse(detalle.idServidor?.trim() ?? '');

      builder.riesgos.add(
        _RiesgoZonaItem(
          clave: idServidor != null && idServidor > 0
              ? 'S:$idServidor'
              : 'L:${detalle.idLocal}',
          idServidor: idServidor,
          idLocal: detalle.idLocal,
          matrizClave: matriz != null
              ? _claveMatrizLocal(matriz)
              : detalle.matrizIdLocal,
          tarea: _texto(detalle.tarea) ?? 'Tarea no especificada',
          peligro:
              _texto(detalle.peligroDescripcion) ?? 'Peligro no especificado',
          consecuencia:
              _texto(detalle.consecuenciaDescripcion) ??
              'Consecuencia no especificada',
          valorInicial: detalle.valorRiesgoInicial,
          nivelInicial:
              _texto(detalle.nivelRiesgoInicial) ??
              _nivelPorValor(detalle.valorRiesgoInicial),
          valorResidual: detalle.valorRiesgoResidual,
          nivelResidual: _texto(detalle.nivelRiesgoResidual),
          estado: _texto(detalle.estadoImplementacion) ?? 'Pendiente',
          sincronizado: detalle.sincronizado,
        ),
      );
    }

    return agrupadas.values
        .map((_ZonaBuilder builder) => builder.construir())
        .toList(growable: false);
  }

  String _zonaLocal(MatrizIpercLocalModel matriz) {
    final String? area = _texto(matriz.areaId);

    if (area != null) {
      return 'Área $area';
    }

    return _texto(matriz.nombre) ?? 'Zona no identificada';
  }

  String _claveMatrizLocal(MatrizIpercLocalModel matriz) {
    final int? servidor = int.tryParse(matriz.idServidor?.trim() ?? '');

    if (servidor != null && servidor > 0) {
      return 'S:$servidor';
    }

    return 'L:${matriz.idLocal}';
  }

  // =============================================================
  // ZONAS REMOTAS
  // =============================================================

  List<_ZonaItem> _crearZonasRemotas({
    required List<MatrizIpercModel> matrices,
    required List<DetalleIpercModel> detalles,
  }) {
    final Map<String, _ZonaBuilder> agrupadas = <String, _ZonaBuilder>{};

    final Map<int, MatrizIpercModel> matricesPorId = <int, MatrizIpercModel>{};

    for (final MatrizIpercModel matriz in matrices) {
      if (matriz.id <= 0) {
        continue;
      }

      matricesPorId[matriz.id] = matriz;

      final String zona = _texto(matriz.areaNombre) ?? matriz.areaVisible;

      final _ZonaBuilder builder = agrupadas.putIfAbsent(
        zona,
        () => _ZonaBuilder(nombre: zona),
      );

      builder.matrices.add(
        _MatrizZonaItem(
          clave: 'S:${matriz.id}',
          idServidor: matriz.id,
          idLocal: null,
          codigo: matriz.codigo,
          nombre: matriz.nombre,
          sincronizada: true,
        ),
      );
    }

    for (final DetalleIpercModel detalle in detalles) {
      final MatrizIpercModel? matriz = matricesPorId[detalle.matrizIpercId];

      final String zona =
          _texto(matriz?.areaNombre) ??
          matriz?.areaVisible ??
          'Zona no identificada';

      final _ZonaBuilder builder = agrupadas.putIfAbsent(
        zona,
        () => _ZonaBuilder(nombre: zona),
      );

      builder.riesgos.add(
        _RiesgoZonaItem(
          clave: 'S:${detalle.id}',
          idServidor: detalle.id,
          idLocal: null,
          matrizClave: 'S:${detalle.matrizIpercId}',
          tarea: _texto(detalle.tarea) ?? 'Tarea no especificada',
          peligro: detalle.peligroVisible,
          consecuencia: detalle.consecuenciaVisible,
          valorInicial: detalle.evaluacionInicial.valorRiesgo,
          nivelInicial:
              _texto(detalle.evaluacionInicial.nivelRiesgoNombre) ??
              _nivelPorValor(detalle.evaluacionInicial.valorRiesgo),
          valorResidual: detalle.evaluacionResidual?.valorRiesgo,
          nivelResidual: _texto(detalle.evaluacionResidual?.nivelRiesgoNombre),
          estado: _texto(detalle.estadoImplementacionNombre) ?? 'Pendiente',
          sincronizado: true,
        ),
      );
    }

    return agrupadas.values
        .map((_ZonaBuilder builder) => builder.construir())
        .toList(growable: false);
  }

  // =============================================================
  // FUSIÓN
  // =============================================================

  void _fusionarZonas({
    required List<_ZonaItem> locales,
    required List<_ZonaItem> remotas,
  }) {
    final Map<String, _ZonaItem> porNombre = <String, _ZonaItem>{
      for (final _ZonaItem zona in locales) zona.nombre.toLowerCase(): zona,
    };

    for (final _ZonaItem remota in remotas) {
      final String clave = remota.nombre.toLowerCase();

      final _ZonaItem? local = porNombre[clave];

      if (local == null) {
        locales.add(remota);
        porNombre[clave] = remota;
        continue;
      }

      final Map<String, _MatrizZonaItem> matrices = <String, _MatrizZonaItem>{
        for (final _MatrizZonaItem matriz in local.matrices)
          matriz.clave: matriz,
      };

      for (final _MatrizZonaItem matriz in remota.matrices) {
        final _MatrizZonaItem? anterior = matrices[matriz.clave];

        matrices[matriz.clave] = anterior == null
            ? matriz
            : matriz.copyWith(idLocal: anterior.idLocal);
      }

      final Map<String, _RiesgoZonaItem> riesgos = <String, _RiesgoZonaItem>{
        for (final _RiesgoZonaItem riesgo in local.riesgos)
          riesgo.clave: riesgo,
      };

      for (final _RiesgoZonaItem riesgo in remota.riesgos) {
        final _RiesgoZonaItem? anterior = riesgos[riesgo.clave];

        riesgos[riesgo.clave] = anterior == null
            ? riesgo
            : riesgo.copyWith(idLocal: anterior.idLocal);
      }

      final int index = locales.indexOf(local);

      locales[index] = _ZonaItem(
        nombre: remota.nombre,
        matrices: matrices.values.toList(),
        riesgos: riesgos.values.toList(),
      );

      porNombre[clave] = locales[index];
    }
  }

  // =============================================================
  // FILTROS
  // =============================================================

  List<_ZonaItem> get _zonasFiltradas {
    final String criterio = _normalizar(_busqueda);

    return _zonas
        .where((_ZonaItem zona) {
          if (!_cumpleFiltro(zona)) {
            return false;
          }

          if (criterio.isEmpty) {
            return true;
          }

          final String contenido = _normalizar(
            '${zona.nombre} '
            '${zona.nivelMayor} '
            '${zona.matrices.map((e) => '${e.codigo} ${e.nombre}').join(' ')} '
            '${zona.riesgos.map((e) => '${e.tarea} ${e.peligro} ${e.consecuencia}').join(' ')}',
          );

          return contenido.contains(criterio);
        })
        .toList(growable: false);
  }

  bool _cumpleFiltro(_ZonaItem zona) {
    switch (_filtro) {
      case 'CRITICAS':
        return zona.valorMayor >= 17;

      case 'ALTAS':
        return zona.valorMayor >= 10 && zona.valorMayor <= 16;

      case 'SIN_EVALUAR':
        return zona.riesgos.isEmpty || zona.valorMayor <= 0;

      case 'TODAS':
      default:
        return true;
    }
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  int get _totalZonas => _zonas.length;

  int get _totalMatrices {
    return _zonas.fold<int>(
      0,
      (int total, _ZonaItem zona) => total + zona.matrices.length,
    );
  }

  int get _totalRiesgos {
    return _zonas.fold<int>(
      0,
      (int total, _ZonaItem zona) => total + zona.riesgos.length,
    );
  }

  int get _zonasCriticas {
    return _zonas.where((_ZonaItem zona) => zona.valorMayor >= 17).length;
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas identificadas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _cargar, child: _contenido()),
    );
  }

  Widget _contenido() {
    if (_cargando && _zonas.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _zonas.isEmpty) {
      return _errorVista();
    }

    final List<_ZonaItem> zonas = _zonasFiltradas;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _estadoConexion(),
        const SizedBox(height: 12),

        if (_advertencia != null) ...<Widget>[
          _aviso(),
          const SizedBox(height: 12),
        ],

        _resumen(),
        const SizedBox(height: 16),

        _buscador(),
        const SizedBox(height: 12),

        _filtros(),
        const SizedBox(height: 16),

        _leyenda(),
        const SizedBox(height: 18),

        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${zonas.length} '
                '${zonas.length == 1 ? 'zona encontrada' : 'zonas encontradas'}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (_busqueda.isNotEmpty || _filtro != 'TODAS')
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpiar'),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (zonas.isEmpty)
          _sinResultados()
        else
          ...zonas.asMap().entries.map((MapEntry<int, _ZonaItem> entry) {
            return _tarjetaZona(posicion: entry.key + 1, zona: entry.value);
          }),
      ],
    );
  }

  // =============================================================
  // CONEXIÓN
  // =============================================================

  Widget _estadoConexion() {
    final Color color = _conectado
        ? Colors.green.shade700
        : Colors.orange.shade800;

    return Row(
      children: <Widget>[
        Icon(
          _conectado ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: color,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _conectado
                ? 'Online · SQLite + servidor'
                : 'Offline · datos guardados en el dispositivo',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _aviso() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(child: Text(_advertencia!)),
        ],
      ),
    );
  }

  // =============================================================
  // RESUMEN
  // =============================================================

  Widget _resumen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Resumen de zonas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _resumenItem(
              titulo: 'Zonas',
              valor: _totalZonas,
              icono: Icons.location_city_outlined,
              onTap: () => _aplicarFiltro('TODAS'),
            ),
            _resumenItem(
              titulo: 'Críticas',
              valor: _zonasCriticas,
              icono: Icons.warning_amber_rounded,
              color: Colors.red.shade800,
              onTap: () => _aplicarFiltro('CRITICAS'),
            ),
            _resumenItem(
              titulo: 'Matrices',
              valor: _totalMatrices,
              icono: Icons.assignment_outlined,
              onTap: () => _aplicarFiltro('TODAS'),
            ),
            _resumenItem(
              titulo: 'Riesgos',
              valor: _totalRiesgos,
              icono: Icons.health_and_safety_outlined,
              color: Colors.orange.shade800,
              onTap: () => _aplicarFiltro('TODAS'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resumenItem({
    required String titulo,
    required int valor,
    required IconData icono,
    required VoidCallback onTap,
    Color? color,
  }) {
    final Color principal = color ?? Theme.of(context).colorScheme.primary;

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
  // BÚSQUEDA
  // =============================================================

  Widget _buscador() {
    return TextField(
      controller: _busquedaController,
      onChanged: (String value) {
        setState(() {
          _busqueda = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Buscar zona o riesgo',
        hintText: 'Área, matriz, peligro o tarea',
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
        border: const OutlineInputBorder(),
      ),
    );
  }

  // =============================================================
  // FILTROS
  // =============================================================

  Widget _filtros() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _chip(valor: 'TODAS', texto: 'Todas'),
        _chip(valor: 'CRITICAS', texto: 'Críticas'),
        _chip(valor: 'ALTAS', texto: 'Altas'),
        _chip(valor: 'SIN_EVALUAR', texto: 'Sin evaluar'),
      ],
    );
  }

  Widget _chip({required String valor, required String texto}) {
    return FilterChip(
      selected: _filtro == valor,
      label: Text(texto),
      onSelected: (_) => _aplicarFiltro(valor),
    );
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtro = filtro;
    });
  }

  void _limpiarFiltros() {
    _busquedaController.clear();

    setState(() {
      _busqueda = '';
      _filtro = 'TODAS';
    });
  }

  // =============================================================
  // LEYENDA
  // =============================================================

  Widget _leyenda() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        _leyendaItem(color: Colors.green.shade700, texto: 'Bajo 1–4'),
        _leyendaItem(color: Colors.amber.shade800, texto: 'Medio 5–9'),
        _leyendaItem(color: Colors.orange.shade800, texto: 'Alto 10–16'),
        _leyendaItem(color: Colors.red.shade800, texto: 'Crítico 17–25'),
      ],
    );
  }

  Widget _leyendaItem({required Color color, required String texto}) {
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
  // TARJETA ZONA
  // =============================================================

  Widget _tarjetaZona({required int posicion, required _ZonaItem zona}) {
    final Color color = _colorRiesgo(zona.valorMayor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirZona(zona),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.13),
                    foregroundColor: color,
                    child: Text(
                      '$posicion',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          zona.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${zona.matrices.length} '
                          '${zona.matrices.length == 1 ? 'matriz' : 'matrices'} · '
                          '${zona.riesgos.length} '
                          '${zona.riesgos.length == 1 ? 'riesgo' : 'riesgos'}',
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        zona.valorMayor > 0 ? '${zona.valorMayor}' : '—',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                      Text(
                        zona.nivelMayor,
                        style: TextStyle(color: color, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (zona.valorMayor.clamp(0, 25) / 25).toDouble(),
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      zona.sincronizada
                          ? 'Datos sincronizados'
                          : 'Contiene información pendiente',
                      style: TextStyle(
                        color: zona.sincronizada
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MODAL DE ZONA
  // =============================================================

  Future<void> _abrirZona(_ZonaItem zona) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              children: <Widget>[
                Text(
                  zona.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${zona.matrices.length} matrices · '
                  '${zona.riesgos.length} riesgos',
                ),
                const SizedBox(height: 18),

                Text(
                  'Matrices IPERC',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...zona.matrices.map(
                  (_MatrizZonaItem matriz) => Card(
                    child: ListTile(
                      leading: Icon(
                        matriz.sincronizada
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                      ),
                      title: Text(matriz.nombre),
                      subtitle: Text(matriz.codigo),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Riesgos identificados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (zona.riesgos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Esta zona todavía no tiene riesgos evaluados.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...zona.riesgos.map(_tarjetaRiesgo),
              ],
            );
          },
        );
      },
    );
  }

  // =============================================================
  // RIESGO
  // =============================================================

  Widget _tarjetaRiesgo(_RiesgoZonaItem riesgo) {
    final Color color = _colorRiesgo(riesgo.valorActual);

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(
            '${riesgo.valorActual}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          riesgo.peligro,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          riesgo.tarea,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _dato('Consecuencia', riesgo.consecuencia),
          _dato('Estado', riesgo.estado),
          _dato(
            'Riesgo inicial',
            '${riesgo.valorInicial} · '
                '${riesgo.nivelInicial}',
          ),
          _dato(
            'Riesgo residual',
            riesgo.valorResidual == null
                ? 'Sin evaluación residual'
                : '${riesgo.valorResidual} · '
                      '${riesgo.nivelResidual ?? _nivelPorValor(riesgo.valorResidual!)}',
          ),
          _dato(
            'Sincronización',
            riesgo.sincronizado ? 'Sincronizado' : 'Pendiente',
          ),
        ],
      ),
    );
  }

  Widget _dato(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(
              '$titulo:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  // =============================================================
  // VACÍO / ERROR
  // =============================================================

  Widget _sinResultados() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.location_off_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No existen zonas que coincidan con los filtros.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _limpiarFiltros,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _errorVista() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 90),
        Icon(Icons.cloud_off_outlined, size: 76, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(
          'No se pudieron cargar las zonas',
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

  static String? _texto(String? value) {
    final String texto = value?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }

  static String _normalizar(String value) {
    return value
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

  static String _nivelPorValor(int valor) {
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

  String _limpiarError(Object error) {
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

// ===============================================================
// BUILDER TEMPORAL
// ===============================================================

class _ZonaBuilder {
  _ZonaBuilder({required this.nombre});

  final String nombre;

  final List<_MatrizZonaItem> matrices = <_MatrizZonaItem>[];

  final List<_RiesgoZonaItem> riesgos = <_RiesgoZonaItem>[];

  _ZonaItem construir() {
    return _ZonaItem(
      nombre: nombre,
      matrices: List<_MatrizZonaItem>.from(matrices),
      riesgos: List<_RiesgoZonaItem>.from(riesgos),
    );
  }
}

// ===============================================================
// ZONA
// ===============================================================

class _ZonaItem {
  const _ZonaItem({
    required this.nombre,
    required this.matrices,
    required this.riesgos,
  });

  final String nombre;

  final List<_MatrizZonaItem> matrices;

  final List<_RiesgoZonaItem> riesgos;

  int get valorMayor {
    int mayor = 0;

    for (final _RiesgoZonaItem riesgo in riesgos) {
      if (riesgo.valorActual > mayor) {
        mayor = riesgo.valorActual;
      }
    }

    return mayor;
  }

  String get nivelMayor =>
      _ZonasIdentificadasScreenState._nivelPorValor(valorMayor);

  bool get sincronizada {
    return matrices.every((_MatrizZonaItem matriz) => matriz.sincronizada) &&
        riesgos.every((_RiesgoZonaItem riesgo) => riesgo.sincronizado);
  }
}

// ===============================================================
// MATRIZ DENTRO DE ZONA
// ===============================================================

class _MatrizZonaItem {
  const _MatrizZonaItem({
    required this.clave,
    required this.idServidor,
    required this.idLocal,
    required this.codigo,
    required this.nombre,
    required this.sincronizada,
  });

  final String clave;

  final int? idServidor;

  final String? idLocal;

  final String codigo;

  final String nombre;

  final bool sincronizada;

  _MatrizZonaItem copyWith({String? idLocal}) {
    return _MatrizZonaItem(
      clave: clave,
      idServidor: idServidor,
      idLocal: idLocal ?? this.idLocal,
      codigo: codigo,
      nombre: nombre,
      sincronizada: sincronizada,
    );
  }
}

// ===============================================================
// RIESGO DENTRO DE ZONA
// ===============================================================

class _RiesgoZonaItem {
  const _RiesgoZonaItem({
    required this.clave,
    required this.idServidor,
    required this.idLocal,
    required this.matrizClave,
    required this.tarea,
    required this.peligro,
    required this.consecuencia,
    required this.valorInicial,
    required this.nivelInicial,
    required this.valorResidual,
    required this.nivelResidual,
    required this.estado,
    required this.sincronizado,
  });

  final String clave;

  final int? idServidor;

  final String? idLocal;

  final String matrizClave;

  final String tarea;

  final String peligro;

  final String consecuencia;

  final int valorInicial;

  final String nivelInicial;

  final int? valorResidual;

  final String? nivelResidual;

  final String estado;

  final bool sincronizado;

  int get valorActual => valorResidual ?? valorInicial;

  _RiesgoZonaItem copyWith({String? idLocal}) {
    return _RiesgoZonaItem(
      clave: clave,
      idServidor: idServidor,
      idLocal: idLocal ?? this.idLocal,
      matrizClave: matrizClave,
      tarea: tarea,
      peligro: peligro,
      consecuencia: consecuencia,
      valorInicial: valorInicial,
      nivelInicial: nivelInicial,
      valorResidual: valorResidual,
      nivelResidual: nivelResidual,
      estado: estado,
      sincronizado: sincronizado,
    );
  }
}
