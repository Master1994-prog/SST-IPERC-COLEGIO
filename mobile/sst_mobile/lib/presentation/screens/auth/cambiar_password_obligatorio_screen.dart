import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';

class CambiarPasswordObligatorioScreen extends StatefulWidget {
  const CambiarPasswordObligatorioScreen({
    required this.nombreUsuario,
    required this.rol,
    super.key,
  });

  final String nombreUsuario;
  final String rol;

  @override
  State<CambiarPasswordObligatorioScreen> createState() =>
      _CambiarPasswordObligatorioScreenState();
}

class _CambiarPasswordObligatorioScreenState
    extends State<CambiarPasswordObligatorioScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthRepository _repository = AuthRepository();

  final TextEditingController _actualController = TextEditingController();

  final TextEditingController _nuevaController = TextEditingController();

  final TextEditingController _confirmarController = TextEditingController();

  bool _procesando = false;

  bool _ocultarActual = true;
  bool _ocultarNueva = true;
  bool _ocultarConfirmacion = true;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();

    super.dispose();
  }

  // =============================================================
  // CAMBIAR PASSWORD
  // =============================================================

  Future<void> _cambiarPassword() async {
    FocusScope.of(context).unfocus();

    if (_procesando || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final String mensaje = await _repository.cambiarPasswordPropio(
        passwordActual: _actualController.text,
        nuevaPassword: _nuevaController.text,
        confirmarPassword: _confirmarController.text,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 52,
            ),
            title: const Text('Contraseña actualizada'),
            content: Text(mensaje, textAlign: TextAlign.center),
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => MainNavigationScreen(
            nombreUsuario: widget.nombreUsuario,
            rol: widget.rol,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String mensaje = error
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .trim();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.riskOrange,
            content: Text(mensaje),
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

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  Future<void> _cerrarSesion() async {
    await _repository.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Cambiar contraseña'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _procesando ? null : _cerrarSesion,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const SizedBox(height: 20),

                const Icon(
                  Icons.lock_reset,
                  size: 82,
                  color: AppColors.primary,
                ),

                const SizedBox(height: 18),

                Text(
                  'Cambio de contraseña obligatorio',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Hola ${widget.nombreUsuario}. '
                  'Por seguridad, debes reemplazar '
                  'la contraseña temporal antes de '
                  'ingresar a SST EduRisk.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.security_outlined, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La nueva contraseña debe '
                          'tener al menos 8 caracteres '
                          'y debe ser diferente a la '
                          'contraseña temporal.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // ACTUAL
                // =================================================
                TextFormField(
                  controller: _actualController,
                  obscureText: _ocultarActual,
                  enabled: !_procesando,
                  decoration: InputDecoration(
                    labelText: 'Contraseña temporal',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: _procesando
                          ? null
                          : () {
                              setState(() {
                                _ocultarActual = !_ocultarActual;
                              });
                            },
                      icon: Icon(
                        _ocultarActual
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la contraseña temporal.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =================================================
                // NUEVA
                // =================================================
                TextFormField(
                  controller: _nuevaController,
                  obscureText: _ocultarNueva,
                  enabled: !_procesando,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                      onPressed: _procesando
                          ? null
                          : () {
                              setState(() {
                                _ocultarNueva = !_ocultarNueva;
                              });
                            },
                      icon: Icon(
                        _ocultarNueva
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres.';
                    }

                    if (value == _actualController.text) {
                      return 'La nueva contraseña debe ser diferente.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =================================================
                // CONFIRMACIÓN
                // =================================================
                TextFormField(
                  controller: _confirmarController,
                  obscureText: _ocultarConfirmacion,
                  enabled: !_procesando,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    _cambiarPassword();
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: _procesando
                          ? null
                          : () {
                              setState(() {
                                _ocultarConfirmacion = !_ocultarConfirmacion;
                              });
                            },
                      icon: Icon(
                        _ocultarConfirmacion
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme la nueva contraseña.';
                    }

                    if (value != _nuevaController.text) {
                      return 'Las contraseñas no coinciden.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _procesando ? null : _cambiarPassword,
                    icon: _procesando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _procesando
                          ? 'Actualizando...'
                          : 'Guardar nueva contraseña',
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
}
