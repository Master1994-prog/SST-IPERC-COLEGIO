import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/matriz_iperc_local_model.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_offline_repository.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../../providers/detalle_iperc_offline_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/sync_status_card.dart';
import '../matriz_iperc/detalles_iperc_offline_screen.dart';
import 'editar_matriz_iperc_offline_screen.dart';
import 'editar_matriz_iperc_screen.dart';
import 'matriz_iperc_detail_screen.dart';
import 'nueva_matriz_iperc_screen.dart';

/// ===============================================================
/// MATRICES IPERC - SST EDURISK
/// ===============================================================
///
/// Pantalla principal del módulo IPERC.
///
/// Mantiene la lógica online/offline existente y aplica la identidad
/// visual oficial SST EduRisk.
///
/// Colores:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
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

    // -----------------------------------------------------------
    // 1. SQLITE
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
    // 2. BACKEND
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

    final bool? confirmar = await _confirmarEliminacion(
      titulo: 'Eliminar matriz IPERC',
      codigo: matriz.codigo,
      nombre: matriz.nombre,
      mensaje: 'La eliminación será lógica y la matriz quedará inactiva.',
    );

    if (!mounted || confirmar != true) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final int usuarioEliminacionId = await _obtenerUsuarioAutenticadoId();

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

    final bool? confirmar = await _confirmarEliminacion(
      titulo: 'Eliminar matriz offline',
      codigo: codigo,
      nombre: matriz.nombre,
      mensaje: 'La operación quedará pendiente de sincronización.',
    );

    if (!mounted || confirmar != true) {
      return;
    }

    try {
      await _offlineRepository.deleteOffline(idLocal: matriz.idLocal);

      if (!mounted) {
        return;
      }

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
  // CONFIRMAR ELIMINACIÓN
  // =============================================================

  Future<bool?> _confirmarEliminacion({
    required String titulo,
    required String codigo,
    required String nombre,
    required String mensaje,
  }) {
    return showDialog<bool>(
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
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '¿Deseas eliminar esta matriz?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      codigo,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
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
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Matrices IPERC'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarMatrices,
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: _puedeGestionarMatrices
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _cargando ? null : _abrirNuevaMatriz,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nueva matriz',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,

      body: RefreshIndicator(
        color: AppColors.primary,
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

    if (_cargando && noHayMatrices) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (noHayMatrices) {
      return _construirSinDatos();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: <Widget>[
        // Estado global de sincronización.
        const SyncStatusCard(compact: true),

        const SizedBox(height: 16),

        if (_mensajeErrorServidor != null) ...<Widget>[
          _construirAvisoServidor(),
          const SizedBox(height: 16),
        ],

        if (locales.isNotEmpty) ...<Widget>[
          const _TituloSeccion(
            titulo: 'Matrices del dispositivo',
            subtitulo: 'Disponibles para trabajar sin conexión.',
            icono: Icons.phone_android_outlined,
            color: AppColors.yellow,
            colorTexto: AppColors.navyDark,
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

        if (_matricesServidor.isNotEmpty) ...<Widget>[
          const _TituloSeccion(
            titulo: 'Matrices del servidor',
            subtitulo: 'Matrices registradas y sincronizadas.',
            icono: Icons.cloud_done_outlined,
            color: AppColors.green,
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
  // SIN DATOS
  // =============================================================

  Widget _construirSinDatos() {
    final bool offline = _mensajeErrorServidor != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 54),

        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: (offline ? AppColors.yellow : AppColors.primary)
                  .withValues(alpha: offline ? 0.18 : 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              offline ? Icons.cloud_off_outlined : Icons.assignment_outlined,
              size: 54,
              color: offline ? AppColors.navyDark : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Text(
          _mensajeErrorServidor ?? 'No hay matrices IPERC registradas.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          _puedeGestionarMatrices
              ? 'Presione “Nueva matriz” para registrar una matriz IPERC.'
              : 'No existen matrices disponibles para mostrar.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),

        const SizedBox(height: 24),

        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _cargando ? null : _cargarMatrices,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ),
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
        color: AppColors.yellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mensajeErrorServidor!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

    final Color colorEstado = pendiente ? AppColors.yellow : AppColors.green;

    final Color colorTexto = pendiente ? AppColors.navyDark : AppColors.green;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _abrirMatrizLocal(matriz);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 5, color: colorEstado),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            pendiente
                                ? Icons.cloud_upload_outlined
                                : Icons.cloud_done_outlined,
                            color: colorTexto,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                codigo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                matriz.nombre,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              if (matriz.descripcion?.trim().isNotEmpty ==
                                  true) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  matriz.descripcion!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
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
                                    color: colorEstado,
                                    colorTexto: colorTexto,
                                  ),
                                  const _EstadoChip(
                                    icono: Icons.phone_android_outlined,
                                    texto: 'Disponible offline',
                                    color: AppColors.primary,
                                  ),
                                  if (matriz.idServidor?.trim().isNotEmpty ==
                                      true)
                                    _EstadoChip(
                                      icono: Icons.link_outlined,
                                      texto: 'Servidor #${matriz.idServidor}',
                                      color: AppColors.primaryBright,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        if (_puedeGestionarMatrices || _puedeEliminarMatrices)
                          _menuMatrizLocal(matriz)
                        else
                          Icon(Icons.chevron_right_rounded, color: colorTexto),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MENÚ LOCAL
  // =============================================================

  Widget _menuMatrizLocal(MatrizIpercLocalModel matriz) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones de matriz',
      color: AppColors.surface,
      icon: const Icon(Icons.more_vert, color: AppColors.primary),
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
                leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                title: Text('Editar offline'),
              ),
            ),

          if (_puedeEliminarMatrices)
            const PopupMenuItem<String>(
              value: 'eliminar',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  color: AppColors.riskOrange,
                ),
                title: Text('Eliminar offline'),
              ),
            ),
        ];
      },
    );
  }

  // =============================================================
  // TARJETA MATRIZ SERVIDOR
  // =============================================================

  Widget _construirMatrizServidor(MatrizIpercModel matriz) {
    final Color color = matriz.activo ? AppColors.green : AppColors.riskOrange;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _abrirMatrizServidor(matriz);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            matriz.activo
                                ? Icons.assignment_turned_in_outlined
                                : Icons.assignment_outlined,
                            color: color,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                matriz.codigo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                matriz.nombre,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              if (matriz.objetivo != null &&
                                  matriz.objetivo!
                                      .trim()
                                      .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  matriz.objetivo!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
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
                                    texto: matriz.activo
                                        ? 'Activa'
                                        : 'Inactiva',
                                    color: color,
                                  ),
                                  const _EstadoChip(
                                    icono: Icons.cloud_done_outlined,
                                    texto: 'Servidor',
                                    color: AppColors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        if (_puedeGestionarMatrices || _puedeEliminarMatrices)
                          _menuMatrizServidor(matriz)
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MENÚ SERVIDOR
  // =============================================================

  Widget _menuMatrizServidor(MatrizIpercModel matriz) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones de matriz',
      color: AppColors.surface,
      icon: const Icon(Icons.more_vert, color: AppColors.primary),
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
                leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                title: Text('Editar'),
              ),
            ),

          if (_puedeEliminarMatrices)
            const PopupMenuItem<String>(
              value: 'eliminar',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  color: AppColors.riskOrange,
                ),
                title: Text('Eliminar'),
              ),
            ),
        ];
      },
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

/// ===============================================================
/// TÍTULO DE SECCIÓN
/// ===============================================================

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    this.colorTexto,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: foreground),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// CHIP DE ESTADO
/// ===============================================================

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({
    required this.icono,
    required this.texto,
    required this.color,
    this.colorTexto,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 16, color: foreground),

          const SizedBox(width: 5),

          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
