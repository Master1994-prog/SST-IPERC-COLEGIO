import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/login_response_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import 'cambiar_password_obligatorio_screen.dart';
import 'recuperar_password_screen.dart';
import 'solicitar_acceso_screen.dart';

/// ===============================================================
/// LOGIN SCREEN - SST EDURISK
/// ===============================================================
///
/// Incluye:
/// - imagen/logo completo original de SST EduRisk;
/// - colores oficiales del sistema;
/// - inicio de sesión online;
/// - acceso offline con validación de contraseña;
/// - bloqueo offline cuando existe cambio obligatorio;
/// - recordatorios de contraseña en sesiones 5, 10, 15, 20 y 25;
/// - cambio obligatorio en sesión 30;
/// - acceso a recuperación de contraseña;
/// - acceso a solicitud de cuenta.
/// ===============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // =============================================================
  // REPOSITORIO
  // =============================================================

  final AuthRepository _authRepository = AuthRepository();

  // =============================================================
  // FORMULARIO
  // =============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usuarioController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // =============================================================
  // ESTADO
  // =============================================================

  bool _procesando = false;
  bool _ocultarPassword = true;

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =============================================================
  // INICIAR SESIÓN
  // =============================================================

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido || _procesando) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      // ---------------------------------------------------------
      // LOGIN ONLINE
      // ---------------------------------------------------------

      final LoginResponseModel response = await _authRepository.login(
        usuario: _usuarioController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // ---------------------------------------------------------
      // CAMBIO OBLIGATORIO
      // ---------------------------------------------------------

      if (response.debeCambiarPassword) {
        _abrirCambioPassword(
          response: response,
          obligatorio: true,
          passwordTemporal: response.esPasswordTemporal,
        );

        return;
      }

      // ---------------------------------------------------------
      // RECORDATORIO EN SESIONES 5 / 10 / 15 / 20 / 25
      // ---------------------------------------------------------

      if (response.recordarCambioPassword) {
        final bool cambiarAhora = await _mostrarRecordatorioPassword(response);

        if (!mounted) {
          return;
        }

        if (cambiarAhora) {
          _abrirCambioPassword(
            response: response,
            obligatorio: false,
            passwordTemporal: false,
          );

          return;
        }
      }

      // ---------------------------------------------------------
      // INGRESO NORMAL
      // ---------------------------------------------------------

      _mostrarMensaje('Inicio de sesión correcto.', tipo: _TipoMensaje.exito);

      _abrirPantallaPrincipal(
        nombreUsuario: response.nombreUsuario,
        rol: response.rol,
      );
    } on DioException catch (error) {
      await _procesarErrorDio(error);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'La respuesta del servidor no es válida: ${error.message}',
        tipo: _TipoMensaje.error,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarError(error), tipo: _TipoMensaje.error);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // RECORDATORIO DE CONTRASEÑA
  // =============================================================

  Future<bool> _mostrarRecordatorioPassword(LoginResponseModel response) async {
    final bool? resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_update_warning_outlined,
              color: AppColors.navyDark,
              size: 36,
            ),
          ),
          title: const Text(
            'Recordatorio de seguridad',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Has iniciado ${response.sesionesDesdeCambioPassword} '
                'de 30 sesiones desde tu último cambio de contraseña.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.40,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.event_available_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Te quedan '
                        '${response.sesionesRestantesCambioPassword} '
                        'sesiones antes del cambio obligatorio.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
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
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Cambiar contraseña'),
            ),
          ],
        );
      },
    );

    return resultado == true;
  }

  // =============================================================
  // ABRIR CAMBIO DE CONTRASEÑA
  // =============================================================

  void _abrirCambioPassword({
    required LoginResponseModel response,
    required bool obligatorio,
    required bool passwordTemporal,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) {
          return CambiarPasswordObligatorioScreen(
            nombreUsuario: response.nombreUsuario,
            rol: response.rol,
            obligatorio: obligatorio,
            passwordTemporal: passwordTemporal,
            sesionesDesdeCambioPassword: response.sesionesDesdeCambioPassword,
          );
        },
      ),
    );
  }

  // =============================================================
  // PROCESAR ERROR DIO
  // =============================================================

  Future<void> _procesarErrorDio(DioException error) async {
    if (!mounted) {
      return;
    }

    final int? statusCode = error.response?.statusCode;

    // -----------------------------------------------------------
    // CREDENCIALES INCORRECTAS
    // -----------------------------------------------------------

    if (statusCode == 401) {
      _mostrarMensaje(
        'Usuario o contraseña incorrectos.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // SIN PERMISOS
    // -----------------------------------------------------------

    if (statusCode == 403) {
      _mostrarMensaje(
        'El usuario no tiene permiso para ingresar.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // ERROR HTTP DEL SERVIDOR
    // -----------------------------------------------------------

    if (statusCode != null) {
      _mostrarMensaje(
        _obtenerMensajeServidor(error.response?.data),
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // COMPROBAR ERROR DE CONEXIÓN
    // -----------------------------------------------------------

    final bool esErrorConexion =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;

    if (!esErrorConexion) {
      _mostrarMensaje(
        'No se pudo completar la solicitud.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // OBTENER SESIÓN OFFLINE
    // -----------------------------------------------------------

    final OfflineSession? sesionOffline = await _authRepository
        .getOfflineSession();

    if (!mounted) {
      return;
    }

    if (sesionOffline == null) {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. '
        'Primero debes iniciar sesión con conexión a internet.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // VALIDAR USUARIO OFFLINE
    // -----------------------------------------------------------

    final String usuarioIngresado = _usuarioController.text
        .trim()
        .toLowerCase();

    final String usuarioGuardado = sesionOffline.nombreUsuario
        .trim()
        .toLowerCase();

    if (usuarioIngresado != usuarioGuardado) {
      _mostrarMensaje(
        'No existe una sesión offline guardada para este usuario.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // BLOQUEAR OFFLINE SI DEBE CAMBIAR CONTRASEÑA
    // -----------------------------------------------------------

    if (sesionOffline.debeCambiarPassword) {
      _mostrarMensaje(
        'Debes conectarte a internet para realizar el cambio '
        'obligatorio de contraseña antes de usar SST EduRisk offline.',
        tipo: _TipoMensaje.advertencia,
      );

      return;
    }

    // -----------------------------------------------------------
    // VALIDAR CONTRASEÑA OFFLINE
    // -----------------------------------------------------------

    final bool passwordOfflineValido = await _authRepository
        .validarPasswordOffline(password: _passwordController.text);

    if (!mounted) {
      return;
    }

    if (!passwordOfflineValido) {
      _mostrarMensaje(
        'La contraseña no es correcta para el acceso offline.',
        tipo: _TipoMensaje.error,
      );

      return;
    }

    // -----------------------------------------------------------
    // INGRESAR OFFLINE
    // -----------------------------------------------------------

    _mostrarMensaje('Ingresando en modo offline.', tipo: _TipoMensaje.offline);

    _abrirPantallaPrincipal(
      nombreUsuario: sesionOffline.nombreUsuario,
      rol: sesionOffline.rol,
    );
  }

  // =============================================================
  // MENSAJE DEL SERVIDOR
  // =============================================================

  String _obtenerMensajeServidor(dynamic contenido) {
    if (contenido is Map) {
      final Map<String, dynamic> respuesta = Map<String, dynamic>.from(
        contenido,
      );

      final dynamic mensaje =
          respuesta['mensaje'] ??
          respuesta['message'] ??
          respuesta['detail'] ??
          respuesta['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      final dynamic errors = respuesta['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final dynamic value in errors.values) {
          if (value is List) {
            mensajes.addAll(value.map((dynamic item) => item.toString()));
          } else if (value != null) {
            mensajes.add(value.toString());
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }
    }

    return 'El servidor no pudo procesar la solicitud.';
  }

  // =============================================================
  // NAVEGACIÓN
  // =============================================================

  void _abrirPantallaPrincipal({
    required String nombreUsuario,
    required String rol,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) {
          return MainNavigationScreen(nombreUsuario: nombreUsuario, rol: rol);
        },
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _volver() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _solicitarAcceso() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const SolicitarAccesoScreen();
        },
      ),
    );
  }

  void _recuperarPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const RecuperarPasswordScreen();
        },
      ),
    );
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarMensaje(String mensaje, {required _TipoMensaje tipo}) {
    if (!mounted) {
      return;
    }

    final Color color;
    final IconData icono;

    switch (tipo) {
      case _TipoMensaje.exito:
        color = AppColors.green;
        icono = Icons.check_circle_outline;
        break;

      case _TipoMensaje.error:
        color = AppColors.riskOrange;
        icono = Icons.error_outline;
        break;

      case _TipoMensaje.advertencia:
        color = AppColors.yellow;
        icono = Icons.warning_amber_rounded;
        break;

      case _TipoMensaje.offline:
        color = AppColors.navyDark;
        icono = Icons.cloud_off_outlined;
        break;
    }

    final Color foreground = tipo == _TipoMensaje.advertencia
        ? AppColors.navyDark
        : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: <Widget>[
              Icon(icono, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(
                    color: foreground,
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

    for (final String prefijo in <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
    ]) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // ---------------------------------------------------
            // DECORACIÓN SUPERIOR
            // ---------------------------------------------------
            const Positioned(
              top: -150,
              left: -130,
              child: _DecoracionCircular(tamano: 330, color: Color(0xFFDCEAFF)),
            ),

            Positioned(
              top: -145,
              right: -145,
              child: _DecoracionCircular(
                tamano: 350,
                color: AppColors.primaryBright.withValues(alpha: 0.08),
              ),
            ),

            // ---------------------------------------------------
            // FORMULARIO
            // ---------------------------------------------------
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                children: <Widget>[
                  // -------------------------------------------------
                  // VOLVER
                  // -------------------------------------------------
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Volver',
                      color: AppColors.primary,
                      onPressed: _procesando ? null : _volver,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // -------------------------------------------------
                  // LOGO COMPLETO ORIGINAL
                  // -------------------------------------------------
                  //
                  // IMPORTANTE:
                  // Se utiliza el mismo archivo de imagen completo
                  // que ya usa SplashScreen. No se reemplaza por
                  // el icono cuadrado.
                  // -------------------------------------------------
                  Center(
                    child: Image.asset(
                      'assets/images/sst_edurisk_logo_completo.png',
                      width: 285,
                      height: 135,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const SizedBox(
                              height: 135,
                              child: Center(
                                child: Icon(
                                  Icons.health_and_safety_outlined,
                                  size: 72,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Sistema Móvil de Gestión SST e IPERC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -------------------------------------------------
                  // TARJETA DE LOGIN
                  // -------------------------------------------------
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.navyDark.withValues(alpha: 0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.09),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.login_outlined,
                            color: AppColors.primary,
                            size: 27,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Ingresa tus credenciales para continuar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -------------------------------------------
                        // USUARIO
                        // -------------------------------------------
                        TextFormField(
                          controller: _usuarioController,
                          enabled: !_procesando,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Usuario o correo electrónico',
                            hintText: 'Ingresa tu usuario',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu usuario.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // -------------------------------------------
                        // CONTRASEÑA
                        // -------------------------------------------
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_procesando,
                          obscureText: _ocultarPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.password],
                          onFieldSubmitted: (_) {
                            _iniciarSesion();
                          },
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: 'Ingresa tu contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _ocultarPassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: _procesando
                                  ? null
                                  : () {
                                      setState(() {
                                        _ocultarPassword = !_ocultarPassword;
                                      });
                                    },
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña.';
                            }

                            if (value.length < 8) {
                              return 'La contraseña debe tener '
                                  'al menos 8 caracteres.';
                            }

                            return null;
                          },
                        ),

                        // -------------------------------------------
                        // RECUPERAR CONTRASEÑA
                        // -------------------------------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _procesando ? null : _recuperarPassword,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // -------------------------------------------
                        // BOTÓN INGRESAR
                        // -------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _procesando ? null : _iniciarSesion,
                            icon: _procesando
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _procesando ? 'Ingresando...' : 'Ingresar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -------------------------------------------------
                  // SOLICITAR ACCESO
                  // -------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Flexible(
                        child: Text(
                          '¿Todavía no tienes acceso?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: _procesando ? null : _solicitarAcceso,
                        child: const Text('Solicitar acceso'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -------------------------------------------------
                  // SEGURIDAD
                  // -------------------------------------------------
                  const _SeguridadFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// FOOTER DE SEGURIDAD
/// ===============================================================

class _SeguridadFooter extends StatelessWidget {
  const _SeguridadFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.verified_user_outlined, color: AppColors.green, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Acceso seguro a SST EduRisk',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Protección de sesión, modo offline seguro '
                  'y política de cambio de contraseña.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.30,
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
/// DECORACIÓN CIRCULAR
/// ===============================================================

class _DecoracionCircular extends StatelessWidget {
  const _DecoracionCircular({required this.tamano, required this.color});

  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// ===============================================================
/// TIPO DE MENSAJE
/// ===============================================================

enum _TipoMensaje { exito, error, advertencia, offline }
