import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../data/repositories/auth_repository.dart';
// import '../home/home_screen.dart';
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

  bool _ocultarPassword = true;
  bool _procesando = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarUsuario(String? value) {
    final String usuario = value?.trim() ?? '';

    if (usuario.isEmpty) {
      return 'Ingrese su usuario o correo';
    }

    if (usuario.length < 3) {
      return 'Ingrese un usuario válido';
    }

    return null;
  }

  String? _validarPassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Ingrese su contraseña';
    }

    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final response = await _authRepository.login(
        usuario: _usuarioController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => MainNavigationScreen(
            nombreUsuario: response.nombreUsuario,
            rol: response.rol,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      String mensaje = 'No se pudo conectar con el servidor.';

      if (error.response?.statusCode == 401) {
        mensaje = 'Usuario o contraseña incorrectos.';
      } else if (error.response?.data is Map<String, dynamic>) {
        final Map<String, dynamic> data =
            error.response!.data as Map<String, dynamic>;

        mensaje = data['mensaje']?.toString() ?? mensaje;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  void _recuperarPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La recuperación de contraseña se implementará después.'),
      ),
    );
  }

  void _solicitarAcceso() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El administrador de la institución debe crear su cuenta.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: -125,
              left: -105,
              child: _DecorativeCircle(size: 290, color: Color(0xFFE0F2F1)),
            ),
            const Positioned(
              top: -95,
              right: -125,
              child: _DecorativeCircle(size: 260, color: Color(0xFFE3F2FD)),
            ),
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenSize.height -
                      MediaQuery.paddingOf(context).vertical -
                      36,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Regresar',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),

                        const SizedBox(height: 72),

                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              size: 54,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),

                        const SizedBox(height: 34),

                        Text(
                          'Iniciar sesión',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF17202A),
                              ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: <Widget>[
                            Text(
                              '¿Todavía no tiene acceso?',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.black54),
                            ),
                            TextButton(
                              onPressed: _procesando ? null : _solicitarAcceso,
                              child: const Text('Solicitar acceso'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        TextFormField(
                          controller: _usuarioController,
                          validator: _validarUsuario,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Usuario o correo',
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 17,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7DEE7),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7DEE7),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          validator: _validarPassword,
                          obscureText: _ocultarPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.password],
                          onFieldSubmitted: (_) => _iniciarSesion(),
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _ocultarPassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () {
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
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 17,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7DEE7),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7DEE7),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
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
                            width: 175,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF1565C0),
                                    Color(0xFF26A69A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: _procesando ? null : _iniciarSesion,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _procesando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            'Ingresar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        const SizedBox(height: 44),

                        const Center(
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFF1565C0),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Acceso seguro al sistema SST–IPERC',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
