import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import '../matriz_iperc/detalles_iperc_offline_screen.dart';
import 'matriz_iperc_detail_screen.dart';
import 'nueva_matriz_iperc_screen.dart';

/// ===============================================================
/// MATRICES IPERC
/// ===============================================================
///
/// Lista las matrices disponibles tanto en:
///
/// - Backend.
/// - SQLite.
///
/// Esto permite continuar trabajando cuando no existe conexión.
///
/// Las matrices creadas localmente se abren utilizando su idLocal.
/// Las matrices provenientes del backend utilizan su idServidor.
/// ===============================================================
class MatricesIpercScreen extends StatefulWidget {
  const MatricesIpercScreen({required this.rol, super.key});

  final String rol;

  @override
  State<MatricesIpercScreen> createState() => _MatricesIpercScreenState();
}

class _MatricesIpercScreenState extends State<MatricesIpercScreen> {
  bool get _puedeGestionarMatrices =>
      RolePermissions.puedeGestionarMatrices(widget.rol);
  // =============================================================
  // REPOSITORIES
  // =============================================================

  final MatrizIpercRepository _repository = MatrizIpercRepository();

  final MatrizIpercOfflineRepository _offlineRepository =
      MatrizIpercOfflineRepository();

  // =============================================================
  // ESTADO
  // =============================================================

  bool _cargando = true;

  String? _mensajeErrorServidor;

  List<MatrizIpercModel> _matricesServidor = <MatrizIpercModel>[];

  List<MatrizIpercLocalModel> _matricesLocales = <MatrizIpercLocalModel>[];

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _cargarMatrices();
  }

  // =============================================================
  // CARGAR TODOS
  // =============================================================

  Future<void> _cargarMatrices() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _mensajeErrorServidor = null;
      });
    }

    // -----------------------------------------------------------
    // 1. SIEMPRE CARGAMOS SQLITE
    // -----------------------------------------------------------

    try {
      final List<MatrizIpercLocalModel> locales = await _offlineRepository
          .getAll();

      if (mounted) {
        setState(() {
          _matricesLocales = locales;
        });
      }
    } catch (error) {
      debugPrint('Error cargando matrices locales: $error');
    }

    // -----------------------------------------------------------
    // 2. INTENTAMOS CARGAR EL BACKEND
    // -----------------------------------------------------------

    try {
      final List<MatrizIpercModel> remotas = await _repository
          .obtenerMatrices();

      if (!mounted) {
        return;
      }

      setState(() {
        _matricesServidor = remotas;
        _mensajeErrorServidor = null;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      String mensaje =
          'No se pudieron actualizar las matrices desde el servidor.';

      if (error.response?.statusCode == 401) {
        mensaje = 'La sesión venció. Inicie sesión nuevamente.';
      } else if (error.response?.statusCode == 403) {
        mensaje = 'No tiene permisos para consultar matrices.';
      } else if (error.response?.statusCode == 404) {
        mensaje = 'No se encontró el endpoint de matrices IPERC.';
      } else if (_esErrorConexion(error)) {
        mensaje =
            'Modo offline: se muestran las matrices '
            'guardadas en este dispositivo.';
      }

      setState(() {
        _mensajeErrorServidor = mensaje;

        // -------------------------------------------------------
        // IMPORTANTE
        // -------------------------------------------------------
        //
        // No borramos _matricesServidor.
        //
        // Si ya existían datos cargados anteriormente durante
        // esta sesión, los conservamos.
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeErrorServidor = 'No se pudo actualizar desde el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
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
  // NUEVA MATRIZ
  // =============================================================

  Future<void> _abrirNuevaMatriz() async {
    final bool? creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return NuevaMatrizIpercScreen(matricesRegistradas: _matricesServidor);
        },
      ),
    );

    if (!mounted || creada != true) {
      return;
    }

    await _cargarMatrices();
  }

  // =============================================================
  // ABRIR MATRIZ SERVIDOR
  // =============================================================

  Future<void> _abrirMatrizServidor(MatrizIpercModel matriz) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return MatrizIpercDetailScreen(matriz: matriz, rol: widget.rol);
        },
      ),
    );

    if (mounted) {
      await _cargarMatrices();
    }
  }

  // =============================================================
  // ABRIR MATRIZ LOCAL
  // =============================================================

  Future<void> _abrirMatrizLocal(MatrizIpercLocalModel matriz) async {
    final int? matrizIdServidor = _convertirIdServidor(matriz.idServidor);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          // -----------------------------------------------------
          // Creamos el provider específicamente para la pantalla
          // offline.
          // -----------------------------------------------------

          return ChangeNotifierProvider<DetalleIpercOfflineProvider>(
            create: (_) => DetalleIpercOfflineProvider(),
            child: DetallesIpercOfflineScreen(
              matrizIdLocal: matriz.idLocal,

              matrizIdServidor: matrizIdServidor,

              nombreMatriz: matriz.nombre,
            ),
          );
        },
      ),
    );

    if (mounted) {
      await _cargarMatrices();
    }
  }

  // =============================================================
  // CONVERTIR ID SERVIDOR
  // =============================================================

  int? _convertirIdServidor(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return null;
    }

    final int? resultado = int.tryParse(texto);

    if (resultado == null || resultado <= 0) {
      return null;
    }

    return resultado;
  }

  // =============================================================
  // EVITAR DUPLICADOS
  // =============================================================

  /// Una matriz local sincronizada puede existir también en
  /// la respuesta del backend.
  ///
  /// En ese caso no debemos mostrar dos tarjetas iguales.
  bool _existeEnServidor(MatrizIpercLocalModel matrizLocal) {
    final int? idServidor = _convertirIdServidor(matrizLocal.idServidor);

    if (idServidor == null) {
      return false;
    }

    return _matricesServidor.any(
      (MatrizIpercModel matriz) => matriz.id == idServidor,
    );
  }

  // =============================================================
  // MATRICES LOCALES VISIBLES
  // =============================================================

  List<MatrizIpercLocalModel> get _matricesLocalesVisibles {
    return _matricesLocales.where((MatrizIpercLocalModel matriz) {
      // -------------------------------------------------------
      // Si ya está sincronizada Y ya viene desde el backend,
      // usamos solamente la versión del servidor.
      // -------------------------------------------------------

      if (matriz.sincronizado && _existeEnServidor(matriz)) {
        return false;
      }

      return !matriz.eliminado;
    }).toList();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrices IPERC'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarMatrices,
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: _puedeGestionarMatrices
          ? FloatingActionButton.extended(
              onPressed: _cargando ? null : _abrirNuevaMatriz,
              icon: const Icon(Icons.add),
              label: const Text('Nueva matriz'),
            )
          : null,

      body: RefreshIndicator(
        onRefresh: _cargarMatrices,
        child: _construirContenido(),
      ),
    );
  }

  // =============================================================
  // CONTENIDO
  // =============================================================

  Widget _construirContenido() {
    final List<MatrizIpercLocalModel> locales = _matricesLocalesVisibles;

    final bool noHayMatrices = locales.isEmpty && _matricesServidor.isEmpty;

    // -----------------------------------------------------------
    // CARGA INICIAL
    // -----------------------------------------------------------

    if (_cargando && noHayMatrices) {
      return const Center(child: CircularProgressIndicator());
    }

    // -----------------------------------------------------------
    // SIN DATOS
    // -----------------------------------------------------------

    if (noHayMatrices) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 70),

          Icon(
            _mensajeErrorServidor != null
                ? Icons.cloud_off_outlined
                : Icons.assignment_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 18),

          Text(
            _mensajeErrorServidor ?? 'No hay matrices IPERC registradas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 10),

          const Text(
            'Presione “Nueva matriz” para registrar una matriz IPERC.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 22),

          Center(
            child: FilledButton.icon(
              onPressed: _cargando ? null : _cargarMatrices,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ),
        ],
      );
    }

    // -----------------------------------------------------------
    // LISTADO
    // -----------------------------------------------------------

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: <Widget>[
        // =======================================================
        // MENSAJE OFFLINE
        // =======================================================
        if (_mensajeErrorServidor != null) ...<Widget>[
          _construirAvisoServidor(),
          const SizedBox(height: 16),
        ],

        // =======================================================
        // MATRICES LOCALES
        // =======================================================
        if (locales.isNotEmpty) ...<Widget>[
          _TituloSeccion(
            titulo: 'Matrices del dispositivo',
            subtitulo: 'Disponibles para trabajar sin conexión.',
            icono: Icons.phone_android_outlined,
          ),

          const SizedBox(height: 10),

          ...locales.map(
            (MatrizIpercLocalModel matriz) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirMatrizLocal(matriz),
            ),
          ),

          if (_matricesServidor.isNotEmpty) const SizedBox(height: 8),
        ],

        // =======================================================
        // MATRICES DEL SERVIDOR
        // =======================================================
        if (_matricesServidor.isNotEmpty) ...<Widget>[
          _TituloSeccion(
            titulo: 'Matrices del servidor',
            subtitulo: 'Matrices registradas y sincronizadas.',
            icono: Icons.cloud_done_outlined,
          ),

          const SizedBox(height: 10),

          ..._matricesServidor.map(
            (MatrizIpercModel matriz) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirMatrizServidor(matriz),
            ),
          ),
        ],
      ],
    );
  }

  // =============================================================
  // AVISO SERVIDOR
  // =============================================================

  Widget _construirAvisoServidor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: Colors.orange.shade800),

          const SizedBox(width: 12),

          Expanded(child: Text(_mensajeErrorServidor!)),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA MATRIZ LOCAL
  // =============================================================

  Widget _construirMatrizLocal(MatrizIpercLocalModel matriz) {
    final bool pendiente =
        !matriz.sincronizado ||
        matriz.idServidor == null ||
        matriz.idServidor!.trim().isEmpty;

    final String codigo = matriz.codigo?.trim().isNotEmpty == true
        ? matriz.codigo!.trim()
        : 'SIN CÓDIGO';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirMatrizLocal(matriz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                child: Icon(
                  pendiente
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      codigo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      matriz.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (matriz.descripcion?.trim().isNotEmpty ==
                        true) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        matriz.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _EstadoChip(
                          icono: pendiente
                              ? Icons.schedule_outlined
                              : Icons.cloud_done_outlined,
                          texto: pendiente
                              ? 'Pendiente de sincronización'
                              : 'Sincronizada',
                        ),

                        _EstadoChip(
                          icono: Icons.phone_android_outlined,
                          texto: 'Disponible offline',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TARJETA MATRIZ SERVIDOR
  // =============================================================

  Widget _construirMatrizServidor(MatrizIpercModel matriz) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirMatrizServidor(matriz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                child: Icon(
                  matriz.activo ? Icons.assignment : Icons.assignment_outlined,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      matriz.codigo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      matriz.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (matriz.objetivo != null &&
                        matriz.objetivo!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        matriz.objetivo!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _EstadoChip(
                          icono: matriz.activo
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          texto: matriz.activo ? 'Activa' : 'Inactiva',
                        ),

                        const _EstadoChip(
                          icono: Icons.cloud_done_outlined,
                          texto: 'Servidor',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// TÍTULO DE SECCIÓN
/// ===============================================================
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(child: Icon(icono)),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 2),

              Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// CHIP DE ESTADO
/// ===============================================================
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 16),

          const SizedBox(width: 5),

          Text(
            texto,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
