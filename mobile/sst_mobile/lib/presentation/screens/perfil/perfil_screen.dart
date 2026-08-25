import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../auth/welcome_screen.dart';

/// ===============================================================
/// PERFIL SCREEN - SST EDURISK
/// ===============================================================
///
/// Permite:
/// - consultar usuario y rol;
/// - ver el estado del acceso offline;
/// - cerrar únicamente la sesión online;
/// - eliminar voluntariamente el acceso offline del dispositivo.
///
/// Colores oficiales SST EduRisk:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// ===============================================================
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    required this.nombreUsuario,
    required this.rol,
    super.key,
  });

  final String nombreUsuario;
  final String rol;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthRepository _authRepository = AuthRepository();

  bool _cerrandoSesion = false;
  bool _eliminandoOffline = false;
  bool? _accesoOfflineActivo;

  @override
  void initState() {
    super.initState();
    _cargarEstadoOffline();
  }

  // =============================================================
  // DATOS VISUALES
  // =============================================================

  String get _inicial {
    final String texto = widget.nombreUsuario.trim();

    if (texto.isEmpty) {
      return 'U';
    }

    return texto.substring(0, 1).toUpperCase();
  }

  String get _rolVisible {
    switch (widget.rol.trim().toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'SUPER ADMIN';

      case 'ADMIN':
        return 'ADMINISTRADOR';

      case 'SUP_TITULAR':
        return 'SUPERVISOR TITULAR';

      case 'SUP_SUPLENTE':
        return 'SUPERVISOR SUPLENTE';

      case 'COORDINADOR':
        return 'COORDINADOR';

      default:
        return widget.rol.replaceAll('_', ' ');
    }
  }

  // =============================================================
  // ESTADO OFFLINE
  // =============================================================

  Future<void> _cargarEstadoOffline() async {
    try {
      final bool activo = await _authRepository.tieneAccesoOffline();

      if (!mounted) {
        return;
      }

      setState(() {
        _accesoOfflineActivo = activo;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accesoOfflineActivo = false;
      });
    }
  }

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion || _eliminandoOffline) {
      return;
    }

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
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: AppColors.primary, size: 32),
          ),
          title: const Text(
            'Cerrar sesión',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                '¿Deseas cerrar la sesión actual?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.28),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.cloud_done_outlined,
                      color: AppColors.green,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El acceso offline autorizado permanecerá disponible en este dispositivo.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      await _authRepository.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'No se pudo cerrar la sesión: '
        '${_limpiarError(error)}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cerrandoSesion = false;
        });
      }
    }
  }

  // =============================================================
  // ELIMINAR ACCESO OFFLINE
  // =============================================================

  Future<void> _eliminarAccesoOffline() async {
    if (_cerrandoSesion || _eliminandoOffline || _accesoOfflineActivo != true) {
      return;
    }

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
              color: AppColors.riskOrange.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phonelink_erase_outlined,
              color: AppColors.riskOrange,
              size: 32,
            ),
          ),
          title: const Text(
            'Eliminar acceso offline',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Este dispositivo dejará de poder iniciar sesión '
            'sin internet. Para volver a habilitar el modo offline '
            'deberás realizar un nuevo inicio de sesión online.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.40),
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

    if (confirmar != true || !mounted) {
      return;
    }

    setState(() {
      _eliminandoOffline = true;
    });

    try {
      await _authRepository.eliminarAccesoOffline();

      if (!mounted) {
        return;
      }

      setState(() {
        _accesoOfflineActivo = false;
      });

      _mostrarMensaje('Acceso offline eliminado de este dispositivo.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'No se pudo eliminar el acceso offline: '
        '${_limpiarError(error)}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _eliminandoOffline = false;
        });
      }
    }
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.riskOrange : AppColors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                error ? Icons.error_outline : Icons.check_circle_outline,
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

  String _limpiarError(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje;
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool cargando = _cerrandoSesion || _eliminandoOffline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: <Widget>[
            // ===================================================
            // CABECERA
            // ===================================================
            Container(
              padding: const EdgeInsets.all(22),
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
                borderRadius: BorderRadius.circular(22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.90),
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _inicial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.nombreUsuario,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _rolVisible,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDCEAFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ===================================================
            // INFORMACIÓN
            // ===================================================
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const _IconoPerfil(
                      icono: Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Usuario',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(widget.nombreUsuario),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _IconoPerfil(
                      icono: Icons.admin_panel_settings_outlined,
                      color: AppColors.primaryBright,
                    ),
                    title: const Text(
                      'Rol',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_rolVisible),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: _IconoPerfil(
                      icono: Icons.verified_user_outlined,
                      color: AppColors.green,
                    ),
                    title: Text(
                      'Estado de sesión',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Sesión autenticada'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ===================================================
            // ACCESO OFFLINE
            // ===================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.cloud_off_outlined, color: AppColors.primary),
                      SizedBox(width: 9),
                      Text(
                        'Acceso offline',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_accesoOfflineActivo == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color:
                            (_accesoOfflineActivo!
                                    ? AppColors.green
                                    : AppColors.yellow)
                                .withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _accesoOfflineActivo!
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: _accesoOfflineActivo!
                                ? AppColors.green
                                : const Color(0xFF8A5A00),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _accesoOfflineActivo!
                                  ? 'Este dispositivo está autorizado para iniciar sesión sin internet.'
                                  : 'Este dispositivo no tiene acceso offline habilitado.',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_accesoOfflineActivo == true) ...<Widget>[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.riskOrange,
                          side: const BorderSide(color: AppColors.riskOrange),
                        ),
                        onPressed: cargando ? null : _eliminarAccesoOffline,
                        icon: _eliminandoOffline
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.phonelink_erase_outlined),
                        label: Text(
                          _eliminandoOffline
                              ? 'Eliminando...'
                              : 'Eliminar acceso offline',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ===================================================
            // CERRAR SESIÓN
            // ===================================================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: cargando ? null : _cerrarSesion,
                icon: _cerrandoSesion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  _cerrandoSesion ? 'Cerrando sesión...' : 'Cerrar sesión',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Cerrar sesión no elimina el acceso offline autorizado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// ICONO PERFIL
/// ===============================================================

class _IconoPerfil extends StatelessWidget {
  const _IconoPerfil({required this.icono, required this.color});

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icono, color: color),
    );
  }
}
