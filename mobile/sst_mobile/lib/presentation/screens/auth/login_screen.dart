import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/models/login_response_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usuarioController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _procesando = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      final LoginResponseModel response = await _authRepository.login(
        usuario: _usuarioController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

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

  Future<void> _procesarErrorDio(DioException error) async {
    if (!mounted) {
      return;
    }

    final int? statusCode = error.response?.statusCode;

    /*
     * No se debe habilitar el acceso offline cuando el
     * servidor respondió 401 o 403, porque eso significa
     * que sí hubo conexión pero las credenciales o permisos
     * son incorrectos.
     */
    if (statusCode == 401) {
      _mostrarMensaje('Usuario o contraseña incorrectos.', esError: true);
      return;
    }

    if (statusCode == 403) {
      _mostrarMensaje(
        'El usuario no tiene permiso para ingresar.',
        esError: true,
      );
      return;
    }

    if (statusCode != null) {
      final String mensajeServidor = _obtenerMensajeServidor(
        error.response?.data,
      );

      _mostrarMensaje(mensajeServidor, esError: true);
      return;
    }

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

    final OfflineSession? sesionOffline = await _authRepository
        .getOfflineSession();

    if (!mounted) {
      return;
    }

    if (sesionOffline == null) {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. '
        'Primero debe iniciar sesión con conexión a internet.',
        esError: true,
      );
      return;
    }

    final String usuarioIngresado = _usuarioController.text
        .trim()
        .toLowerCase();

    final String usuarioGuardado = sesionOffline.nombreUsuario
        .trim()
        .toLowerCase();

    /*
     * Evita abrir la sesión guardada cuando se escribe
     * un nombre de usuario diferente.
     */
    if (usuarioIngresado != usuarioGuardado) {
      _mostrarMensaje(
        'No existe una sesión offline guardada '
        'para este usuario.',
        esError: true,
      );
      return;
    }

    _mostrarMensaje('Ingresando en modo offline.');

    _abrirPantallaPrincipal(
      nombreUsuario: sesionOffline.nombreUsuario,
      rol: sesionOffline.rol,
    );
  }

  String _obtenerMensajeServidor(dynamic contenido) {
    if (contenido is Map) {
      final Map<String, dynamic> respuesta = Map<String, dynamic>.from(
        contenido,
      );

      final dynamic mensaje =
          respuesta['mensaje'] ?? respuesta['message'] ?? respuesta['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString();
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

  void _abrirPantallaPrincipal({
    required String nombreUsuario,
    required String rol,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            MainNavigationScreen(nombreUsuario: nombreUsuario, rol: rol),
      ),
      (Route<dynamic> route) => false,
    );
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
          backgroundColor: esError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  void _volver() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _solicitarAcceso() {
    _mostrarMensaje(
      'La solicitud de acceso se implementará '
      'en el módulo de usuarios.',
    );
  }

  void _recuperarPassword() {
    _mostrarMensaje(
      'La recuperación de contraseña se '
      'implementará próximamente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colores.surface,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: -120,
              left: -110,
              child: _DecoracionCircular(tamano: 310, color: Color(0xFFDDF2F2)),
            ),
            const Positioned(
              top: -120,
              right: -140,
              child: _DecoracionCircular(tamano: 330, color: Color(0xFFE1F0FD)),
            ),
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Volver',
                      onPressed: _volver,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                    ),
                  ),
                  const SizedBox(height: 120),
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F1FD),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 48,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Text(
                    'Iniciar sesión',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '¿Todavía no tiene acceso?',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                      TextButton(
                        onPressed: _procesando ? null : _solicitarAcceso,
                        child: const Text('Solicitar acceso'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                      hintText: 'Usuario o correo electrónico',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(color: colores.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese su usuario.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                      hintText: 'Contraseña',
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
                        borderRadius: BorderRadius.circular(28),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(color: colores.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _procesando ? null : _recuperarPassword,
                      child: const Text('¿Olvidó su contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 205,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: _procesando ? null : _iniciarSesion,
                        icon: _procesando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(
                          _procesando ? 'Ingresando...' : 'Ingresar',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 180),
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF1976D2),
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Acceso seguro al sistema SST–IPERC',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
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
