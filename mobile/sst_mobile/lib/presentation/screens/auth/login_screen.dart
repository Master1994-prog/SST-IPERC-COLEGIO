import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
/// Permite:
///
/// - Iniciar sesión online.
/// - Ingresar en modo offline si existe una sesión válida.
/// - Bloquear el modo offline cuando existe un cambio obligatorio
///   de contraseña pendiente.
/// - Solicitar acceso.
/// - Solicitar recuperación de contraseña.
/// - Redirigir al cambio obligatorio de contraseña.
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

      // =========================================================
      // CAMBIO OBLIGATORIO DE CONTRASEÑA
      // =========================================================
      //
      // Si el administrador asignó una contraseña temporal,
      // el usuario NO puede entrar al menú principal todavía.
      // =========================================================

      if (response.debeCambiarPassword) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) {
              return CambiarPasswordObligatorioScreen(
                nombreUsuario: response.nombreUsuario,
                rol: response.rol,
              );
            },
          ),
        );

        return;
      }

      // ---------------------------------------------------------
      // LOGIN NORMAL
      // ---------------------------------------------------------

      _mostrarMensaje('Inicio de sesión correcto.');

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
        'La respuesta del servidor no es válida: '
        '${error.message}',
        esError: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje('Ocurrió un error inesperado: $error', esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // PROCESAR ERROR DIO
  // =============================================================

  Future<void> _procesarErrorDio(DioException error) async {
    if (!mounted) {
      return;
    }

    final int? statusCode = error.response?.statusCode;

    // ===========================================================
    // EL SERVIDOR RESPONDIÓ
    // ===========================================================

    // -----------------------------------------------------------
    // CREDENCIALES INCORRECTAS
    // -----------------------------------------------------------

    if (statusCode == 401) {
      _mostrarMensaje('Usuario o contraseña incorrectos.', esError: true);

      return;
    }

    // -----------------------------------------------------------
    // SIN PERMISOS
    // -----------------------------------------------------------

    if (statusCode == 403) {
      _mostrarMensaje(
        'El usuario no tiene permiso para ingresar.',
        esError: true,
      );

      return;
    }

    // -----------------------------------------------------------
    // OTRO ERROR HTTP
    // -----------------------------------------------------------

    if (statusCode != null) {
      final String mensajeServidor = _obtenerMensajeServidor(
        error.response?.data,
      );

      _mostrarMensaje(mensajeServidor, esError: true);

      return;
    }

    // ===========================================================
    // COMPROBAR SI ES ERROR DE CONEXIÓN
    // ===========================================================

    final bool esErrorConexion =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;

    if (!esErrorConexion) {
      _mostrarMensaje('No se pudo completar la solicitud.', esError: true);

      return;
    }

    // ===========================================================
    // OBTENER SESIÓN OFFLINE
    // ===========================================================

    final OfflineSession? sesionOffline = await _authRepository
        .getOfflineSession();

    if (!mounted) {
      return;
    }

    // -----------------------------------------------------------
    // NO HAY SESIÓN OFFLINE
    // -----------------------------------------------------------

    if (sesionOffline == null) {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. '
        'Primero debe iniciar sesión con conexión '
        'a internet.',
        esError: true,
      );

      return;
    }

    // ===========================================================
    // VALIDAR USUARIO
    // ===========================================================

    final String usuarioIngresado = _usuarioController.text
        .trim()
        .toLowerCase();

    final String usuarioGuardado = sesionOffline.nombreUsuario
        .trim()
        .toLowerCase();

    if (usuarioIngresado != usuarioGuardado) {
      _mostrarMensaje(
        'No existe una sesión offline guardada '
        'para este usuario.',
        esError: true,
      );

      return;
    }

    // ===========================================================
    // BLOQUEAR OFFLINE SI DEBE CAMBIAR PASSWORD
    // ===========================================================
    //
    // IMPORTANTE:
    //
    // sesionOffline ya:
    //
    // 1. Fue declarada.
    // 2. Fue comprobada contra null.
    // 3. Pertenece al usuario escrito.
    //
    // Por eso esta comprobación debe estar AQUÍ.
    // ===========================================================

    if (sesionOffline.debeCambiarPassword) {
      _mostrarMensaje(
        'Debes conectarte a internet para cambiar '
        'la contraseña temporal antes de utilizar '
        'SST EduRisk en modo offline.',
        esError: true,
      );

      return;
    }

    // ===========================================================
    // ENTRAR EN MODO OFFLINE
    // ===========================================================

    _mostrarMensaje('Ingresando en modo offline.');

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

      // ---------------------------------------------------------
      // VALIDACIONES DEL BACKEND
      // ---------------------------------------------------------

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

    return 'El servidor no pudo procesar '
        'la solicitud.';
  }

  // =============================================================
  // ABRIR SISTEMA
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

  // =============================================================
  // MENSAJE
  // =============================================================

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  // =============================================================
  // VOLVER
  // =============================================================

  void _volver() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // =============================================================
  // SOLICITAR ACCESO
  // =============================================================

  void _solicitarAcceso() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const SolicitarAccesoScreen();
        },
      ),
    );
  }

  // =============================================================
  // RECUPERAR CONTRASEÑA
  // =============================================================

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
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colores.surface,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // ===================================================
            // DECORACIÓN
            // ===================================================
            const Positioned(
              top: -120,
              left: -110,
              child: _DecoracionCircular(tamano: 310, color: Color(0xFFDCEAFF)),
            ),

            const Positioned(
              top: -120,
              right: -140,
              child: _DecoracionCircular(tamano: 330, color: Color(0xFFE5F0FF)),
            ),

            // ===================================================
            // FORMULARIO
            // ===================================================
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
                children: <Widget>[
                  // =============================================
                  // VOLVER
                  // =============================================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Volver',
                      onPressed: _procesando ? null : _volver,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 26),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // =============================================
                  // LOGO SST EDURISK
                  // =============================================
                  Center(
                    child: SizedBox(
                      width: 125,
                      height: 125,
                      child: Image.asset(
                        'assets/icons/sst_edurisk_icon_1024.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: colores.primaryContainer,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Icon(
                                  Icons.health_and_safety_outlined,
                                  size: 62,
                                  color: colores.primary,
                                ),
                              );
                            },
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =============================================
                  // NOMBRE
                  // =============================================
                  Text(
                    'SST EduRisk',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colores.primary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Sistema Móvil de Gestión '
                    'SST e IPERC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colores.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =============================================
                  // TÍTULO
                  // =============================================
                  Text(
                    'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Ingrese sus credenciales '
                    'para continuar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colores.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // =============================================
                  // USUARIO
                  // =============================================
                  TextFormField(
                    controller: _usuarioController,
                    enabled: !_procesando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Usuario o correo electrónico',
                      hintText: 'Ingrese su usuario',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese su usuario.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // =============================================
                  // PASSWORD
                  // =============================================
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
                      hintText: 'Ingrese su contraseña',
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su contraseña.';
                      }

                      if (value.length < 6) {
                        return 'La contraseña debe tener '
                            'al menos 6 caracteres.';
                      }

                      return null;
                    },
                  ),

                  // =============================================
                  // RECUPERAR PASSWORD
                  // =============================================
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _procesando ? null : _recuperarPassword,
                      child: const Text('¿Olvidó su contraseña?'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =============================================
                  // INGRESAR
                  // =============================================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _procesando ? null : _iniciarSesion,
                      icon: _procesando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _procesando ? 'Ingresando...' : 'Ingresar',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =============================================
                  // SOLICITAR ACCESO
                  // =============================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '¿Todavía no tiene acceso?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colores.onSurfaceVariant),
                        ),
                      ),

                      TextButton(
                        onPressed: _procesando ? null : _solicitarAcceso,
                        child: const Text('Solicitar acceso'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // =============================================
                  // SEGURIDAD
                  // =============================================
                  Icon(
                    Icons.verified_user_outlined,
                    color: colores.primary,
                    size: 30,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Acceso seguro a SST EduRisk',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colores.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Sistema Móvil de Gestión '
                    'SST e IPERC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
