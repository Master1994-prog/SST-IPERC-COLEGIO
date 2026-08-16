import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import '../../providers/sync_provider.dart';
import '../matriz_iperc/detalles_iperc_offline_screen.dart';
import 'editar_matriz_iperc_offline_screen.dart';
import 'editar_matriz_iperc_screen.dart';
import 'matriz_iperc_detail_screen.dart';
import 'nueva_matriz_iperc_screen.dart';

/// ===============================================================
/// MATRICES IPERC
/// ===============================================================
///
/// Pantalla principal del módulo de matrices IPERC.
///
/// Permite trabajar con:
///
/// - Matrices almacenadas en el servidor.
/// - Matrices almacenadas en SQLite.
/// - Creación online/offline.
/// - Edición online.
/// - Eliminación online.
/// - Edición offline.
/// - Eliminación offline.
/// - Sincronización automática.
///
/// PERMISOS:
///
/// Gestionar matrices:
/// - SUPER_ADMIN
/// - ADMIN
/// - COORDINADOR
/// - SUP_TITULAR
/// - SUP_SUPLENTE
///
/// Eliminar matrices:
/// - SOLO SUPER_ADMIN
/// ===============================================================
class MatricesIpercScreen extends StatefulWidget {
  const MatricesIpercScreen({required this.rol, super.key});

  final String rol;

  @override
  State<MatricesIpercScreen> createState() {
    return _MatricesIpercScreenState();
  }
}

class _MatricesIpercScreenState extends State<MatricesIpercScreen> {
  // =============================================================
  // PERMISOS
  // =============================================================

  bool get _puedeGestionarMatrices {
    return RolePermissions.puedeGestionarMatrices(widget.rol);
  }

  bool get _puedeEliminarMatrices {
    return RolePermissions.puedeEliminarRegistros(widget.rol);
  }

  // =============================================================
  // REPOSITORIOS
  // =============================================================

  final MatrizIpercRepository _repository = MatrizIpercRepository();

  final MatrizIpercOfflineRepository _offlineRepository =
      MatrizIpercOfflineRepository();

  final SecureStorageService _secureStorage = SecureStorageService.instance;

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
  // CARGAR MATRICES
  // =============================================================

  Future<void> _cargarMatrices() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _mensajeErrorServidor = null;
      });
    }

    // ===========================================================
    // 1. SQLITE
    // ===========================================================

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

    // ===========================================================
    // 2. BACKEND
    // ===========================================================

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
          'No se pudieron actualizar las matrices '
          'desde el servidor.';

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
    if (!_puedeGestionarMatrices) {
      return;
    }

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

    await _notificarCambioLocal();

    if (!mounted) {
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

    if (!mounted) {
      return;
    }

    await _cargarMatrices();
  }

  // =============================================================
  // EDITAR MATRIZ SERVIDOR
  // =============================================================

  Future<void> _editarMatrizServidor(MatrizIpercModel matriz) async {
    if (!_puedeGestionarMatrices) {
      _mostrarMensaje(
        'No tiene permisos para editar matrices IPERC.',
        esError: true,
      );

      return;
    }

    final bool? actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return EditarMatrizIpercScreen(matriz: matriz);
        },
      ),
    );

    if (!mounted || actualizada != true) {
      return;
    }

    await _cargarMatrices();
  }

  // =============================================================
  // ELIMINAR MATRIZ SERVIDOR
  // =============================================================

  Future<void> _eliminarMatrizServidor(MatrizIpercModel matriz) async {
    if (!_puedeEliminarMatrices) {
      _mostrarMensaje(
        'Solo el Super Administrador '
        'puede eliminar matrices IPERC.',
        esError: true,
      );

      return;
    }

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar matriz IPERC'),
          content: Text(
            '¿Deseas eliminar esta matriz?\n\n'
            '${matriz.codigo}\n'
            '${matriz.nombre}\n\n'
            'La eliminación será lógica y '
            'la matriz quedará inactiva.',
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

    if (!mounted || confirmar != true) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      // ---------------------------------------------------------
      // OBTENER USUARIO AUTENTICADO
      // ---------------------------------------------------------

      final int usuarioEliminacionId = await _obtenerUsuarioAutenticadoId();

      // ---------------------------------------------------------
      // ELIMINAR EN BACKEND
      // ---------------------------------------------------------

      await _repository.eliminar(
        matriz.id,
        usuarioEliminacionId: usuarioEliminacionId,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensaje('Matriz IPERC eliminada correctamente.');

      await _cargarMatrices();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _obtenerMensajeDio(
          error,
          predeterminado: 'No se pudo eliminar la matriz IPERC.',
        ),
        esError: true,
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.message, esError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarMensaje(error), esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
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
          return ChangeNotifierProvider<DetalleIpercOfflineProvider>(
            create: (_) {
              return DetalleIpercOfflineProvider();
            },
            child: DetallesIpercOfflineScreen(
              matrizIdLocal: matriz.idLocal,
              matrizIdServidor: matrizIdServidor,
              nombreMatriz: matriz.nombre,
            ),
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _cargarMatrices();
  }

  // =============================================================
  // EDITAR MATRIZ LOCAL
  // =============================================================

  Future<void> _editarMatrizLocal(MatrizIpercLocalModel matriz) async {
    if (!_puedeGestionarMatrices) {
      _mostrarMensaje(
        'No tiene permisos para editar matrices IPERC.',
        esError: true,
      );

      return;
    }

    final bool? actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return EditarMatrizIpercOfflineScreen(matriz: matriz);
        },
      ),
    );

    if (!mounted || actualizada != true) {
      return;
    }

    await _notificarCambioLocal();

    if (!mounted) {
      return;
    }

    await _cargarMatrices();
  }

  // =============================================================
  // ELIMINAR MATRIZ LOCAL
  // =============================================================

  Future<void> _eliminarMatrizLocal(MatrizIpercLocalModel matriz) async {
    if (!_puedeEliminarMatrices) {
      _mostrarMensaje(
        'Solo el Super Administrador '
        'puede eliminar matrices IPERC.',
        esError: true,
      );

      return;
    }

    final String codigo = matriz.codigo?.trim().isNotEmpty == true
        ? matriz.codigo!.trim()
        : 'SIN CÓDIGO';

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar matriz offline'),
          content: Text(
            '¿Deseas eliminar esta matriz '
            'del dispositivo?\n\n'
            '$codigo\n'
            '${matriz.nombre}\n\n'
            'La operación quedará pendiente '
            'de sincronización.',
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

    if (!mounted || confirmar != true) {
      return;
    }

    try {
      // ---------------------------------------------------------
      // ELIMINAR LOCALMENTE
      // ---------------------------------------------------------
      //
      // El repositorio obtiene internamente el ID real
      // del usuario autenticado.
      // ---------------------------------------------------------

      await _offlineRepository.deleteOffline(idLocal: matriz.idLocal);

      if (!mounted) {
        return;
      }

      // ---------------------------------------------------------
      // ACTUALIZAR ESTADO GLOBAL DE SINCRONIZACIÓN
      // ---------------------------------------------------------

      await _notificarCambioLocal();

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'Matriz eliminada del dispositivo. '
        'Se sincronizará cuando exista conexión.',
      );

      await _cargarMatrices();
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        error.message?.toString() ?? error.toString(),
        esError: true,
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.message, esError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarMensaje(error), esError: true);
    }
  }

  // =============================================================
  // OBTENER USUARIO AUTENTICADO
  // =============================================================

  Future<int> _obtenerUsuarioAutenticadoId() async {
    final String usuarioTexto =
        (await _secureStorage.getUsuarioId())?.trim() ?? '';

    if (usuarioTexto.isEmpty) {
      throw StateError(
        'No se encontró el usuario autenticado. '
        'Inicie sesión nuevamente.',
      );
    }

    final int? usuarioId = int.tryParse(usuarioTexto);

    if (usuarioId == null || usuarioId <= 0) {
      throw StateError(
        'El identificador del usuario autenticado '
        'no es válido: $usuarioTexto.',
      );
    }

    return usuarioId;
  }

  // =============================================================
  // NOTIFICAR CAMBIO LOCAL
  // =============================================================

  Future<void> _notificarCambioLocal() async {
    if (!mounted) {
      return;
    }

    try {
      await context.read<SyncProvider>().notifyLocalChange();
    } catch (error) {
      debugPrint(
        'No se pudo actualizar el estado '
        'de sincronización: $error',
      );
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

  bool _existeEnServidor(MatrizIpercLocalModel matrizLocal) {
    final int? idServidor = _convertirIdServidor(matrizLocal.idServidor);

    if (idServidor == null) {
      return false;
    }

    return _matricesServidor.any((MatrizIpercModel matriz) {
      return matriz.id == idServidor;
    });
  }

  // =============================================================
  // MATRICES LOCALES VISIBLES
  // =============================================================

  List<MatrizIpercLocalModel> get _matricesLocalesVisibles {
    return _matricesLocales.where((MatrizIpercLocalModel matriz) {
      if (matriz.eliminado) {
        return false;
      }

      // -------------------------------------------------------
      // Si una matriz local ya está sincronizada y también
      // aparece en el servidor, mostramos solamente
      // la versión del servidor.
      // -------------------------------------------------------

      if (matriz.sincronizado && _existeEnServidor(matriz)) {
        return false;
      }

      return true;
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

    // ===========================================================
    // CARGA INICIAL
    // ===========================================================

    if (_cargando && noHayMatrices) {
      return const Center(child: CircularProgressIndicator());
    }

    // ===========================================================
    // SIN DATOS
    // ===========================================================

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
            'Presione “Nueva matriz” para '
            'registrar una matriz IPERC.',
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

    // ===========================================================
    // LISTADO
    // ===========================================================

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: <Widget>[
        // =======================================================
        // MENSAJE OFFLINE / SERVIDOR
        // =======================================================
        if (_mensajeErrorServidor != null) ...<Widget>[
          _construirAvisoServidor(),

          const SizedBox(height: 16),
        ],

        // =======================================================
        // MATRICES LOCALES
        // =======================================================
        if (locales.isNotEmpty) ...<Widget>[
          const _TituloSeccion(
            titulo: 'Matrices del dispositivo',
            subtitulo:
                'Disponibles para trabajar '
                'sin conexión.',
            icono: Icons.phone_android_outlined,
          ),

          const SizedBox(height: 10),

          ...locales.map((MatrizIpercLocalModel matriz) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirMatrizLocal(matriz),
            );
          }),

          if (_matricesServidor.isNotEmpty) const SizedBox(height: 8),
        ],

        // =======================================================
        // MATRICES SERVIDOR
        // =======================================================
        if (_matricesServidor.isNotEmpty) ...<Widget>[
          const _TituloSeccion(
            titulo: 'Matrices del servidor',
            subtitulo:
                'Matrices registradas '
                'y sincronizadas.',
            icono: Icons.cloud_done_outlined,
          ),

          const SizedBox(height: 10),

          ..._matricesServidor.map((MatrizIpercModel matriz) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirMatrizServidor(matriz),
            );
          }),
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
        onTap: () {
          _abrirMatrizLocal(matriz);
        },
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

                        const _EstadoChip(
                          icono: Icons.phone_android_outlined,
                          texto: 'Disponible offline',
                        ),

                        if (matriz.idServidor?.trim().isNotEmpty == true)
                          _EstadoChip(
                            icono: Icons.link_outlined,
                            texto: 'Servidor #${matriz.idServidor}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // MENÚ LOCAL
              // =================================================
              if (_puedeGestionarMatrices || _puedeEliminarMatrices)
                PopupMenuButton<String>(
                  tooltip: 'Opciones de matriz',
                  onSelected: (String opcion) {
                    switch (opcion) {
                      case 'editar':
                        _editarMatrizLocal(matriz);
                        break;

                      case 'eliminar':
                        _eliminarMatrizLocal(matriz);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      if (_puedeGestionarMatrices)
                        const PopupMenuItem<String>(
                          value: 'editar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar offline'),
                          ),
                        ),

                      if (_puedeEliminarMatrices)
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Eliminar offline'),
                          ),
                        ),
                    ];
                  },
                )
              else
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
        onTap: () {
          _abrirMatrizServidor(matriz);
        },
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

              // =================================================
              // MENÚ SERVIDOR
              // =================================================
              if (_puedeGestionarMatrices || _puedeEliminarMatrices)
                PopupMenuButton<String>(
                  tooltip: 'Opciones de matriz',
                  onSelected: (String opcion) {
                    switch (opcion) {
                      case 'editar':
                        _editarMatrizServidor(matriz);
                        break;

                      case 'eliminar':
                        _eliminarMatrizServidor(matriz);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      if (_puedeGestionarMatrices)
                        const PopupMenuItem<String>(
                          value: 'editar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),

                      if (_puedeEliminarMatrices)
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Eliminar'),
                          ),
                        ),
                    ];
                  },
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MENSAJE DIO
  // =============================================================

  String _obtenerMensajeDio(
    DioException error, {
    required String predeterminado,
  }) {
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

      final dynamic errores = respuesta['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final dynamic valor in errores.values) {
          if (valor is List) {
            mensajes.addAll(
              valor.map((dynamic item) {
                return item.toString();
              }),
            );
          } else if (valor != null) {
            mensajes.add(valor.toString());
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }
    }

    if (_esErrorConexion(error)) {
      return 'No se pudo conectar con el servidor.';
    }

    return error.message ?? predeterminado;
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  String _limpiarMensaje(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'Bad state: ',
      'ArgumentError: ',
      'Unsupported operation: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }

  // =============================================================
  // MOSTRAR MENSAJE
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
