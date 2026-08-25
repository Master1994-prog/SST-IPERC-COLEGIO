import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';

/// ===============================================================
/// CAMBIO DE CONTRASEÑA - SST EDURISK
/// ===============================================================
///
/// Se utiliza para:
/// - contraseña temporal obligatoria;
/// - sesión 30 obligatoria;
/// - recordatorio opcional en sesiones 5, 10, 15, 20 y 25.
/// ===============================================================
class CambiarPasswordObligatorioScreen extends StatefulWidget {
  const CambiarPasswordObligatorioScreen({
    required this.nombreUsuario,
    required this.rol,
    this.obligatorio = true,
    this.passwordTemporal = true,
    this.sesionesDesdeCambioPassword = 0,
    super.key,
  });

  final String nombreUsuario;
  final String rol;

  /// Si es true, el usuario no puede omitir el cambio.
  final bool obligatorio;

  /// True cuando la contraseña actual fue asignada temporalmente.
  final bool passwordTemporal;

  /// Sesiones acumuladas al abrir esta pantalla.
  final int sesionesDesdeCambioPassword;

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

  bool get _esSesion30 =>
      widget.obligatorio &&
      !widget.passwordTemporal &&
      widget.sesionesDesdeCambioPassword >= 30;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // =============================================================
  // TEXTOS
  // =============================================================

  String get _titulo {
    if (widget.passwordTemporal) {
      return 'Cambia tu contraseña temporal';
    }

    if (_esSesion30) {
      return 'Actualización de seguridad requerida';
    }

    return 'Actualizar contraseña';
  }

  String get _descripcion {
    if (widget.passwordTemporal) {
      return 'Hola ${widget.nombreUsuario}. '
          'Antes de ingresar a SST EduRisk debes reemplazar '
          'la contraseña temporal.';
    }

    if (_esSesion30) {
      return 'Has alcanzado 30 sesiones desde tu último '
          'cambio de contraseña. Por seguridad, debes '
          'actualizarla antes de continuar.';
    }

    return 'Has iniciado '
        '${widget.sesionesDesdeCambioPassword} de 30 sesiones. '
        'Puedes cambiar tu contraseña ahora o continuar '
        'y hacerlo más adelante.';
  }

  String get _labelPasswordActual =>
      widget.passwordTemporal ? 'Contraseña temporal' : 'Contraseña actual';

  Color get _colorEstado {
    if (_esSesion30) {
      return AppColors.riskOrange;
    }

    if (widget.passwordTemporal) {
      return AppColors.yellow;
    }

    return AppColors.primaryBright;
  }

  IconData get _iconoEstado {
    if (_esSesion30) {
      return Icons.gpp_bad_outlined;
    }

    if (widget.passwordTemporal) {
      return Icons.key_outlined;
    }

    return Icons.security_update_good_outlined;
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
            backgroundColor: AppColors.surface,
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 54,
            ),
            title: const Text(
              'Contraseña actualizada',
              textAlign: TextAlign.center,
            ),
            content: Text(mensaje, textAlign: TextAlign.center),
            actions: <Widget>[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
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

      _abrirSistema();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(_limpiarError(error));
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  // =============================================================
  // CONTINUAR SIN CAMBIAR
  // =============================================================

  void _continuarSinCambiar() {
    if (widget.obligatorio || _procesando) {
      return;
    }

    _abrirSistema();
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
  // NAVEGAR AL SISTEMA
  // =============================================================

  void _abrirSistema() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainNavigationScreen(
          nombreUsuario: widget.nombreUsuario,
          rol: widget.rol,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskOrange,
          content: Row(
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(mensaje)),
            ],
          ),
        ),
      );
  }

  String _limpiarError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|StateError|Bad state):\s*'), '')
        .trim();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.obligatorio,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.obligatorio,
          title: Text(
            widget.obligatorio ? 'Seguridad de cuenta' : 'Cambiar contraseña',
          ),
          actions: <Widget>[
            if (widget.obligatorio)
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              children: <Widget>[
                _CabeceraSeguridad(
                  titulo: _titulo,
                  descripcion: _descripcion,
                  color: _colorEstado,
                  icono: _iconoEstado,
                ),

                const SizedBox(height: 18),

                if (!widget.passwordTemporal)
                  _ProgresoSesiones(
                    sesiones: widget.sesionesDesdeCambioPassword,
                  ),

                if (!widget.passwordTemporal) const SizedBox(height: 18),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(
                              Icons.password_outlined,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Nueva contraseña',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _actualController,
                          obscureText: _ocultarActual,
                          enabled: !_procesando,
                          decoration: InputDecoration(
                            labelText: _labelPasswordActual,
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
                              return 'Ingresa $_labelPasswordActual.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nuevaController,
                          obscureText: _ocultarNueva,
                          enabled: !_procesando,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
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
                              return 'Debe tener al menos 8 caracteres.';
                            }

                            if (value == _actualController.text) {
                              return 'La nueva contraseña debe ser diferente.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

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
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _procesando
                                  ? null
                                  : () {
                                      setState(() {
                                        _ocultarConfirmacion =
                                            !_ocultarConfirmacion;
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
                              return 'Confirma la nueva contraseña.';
                            }

                            if (value != _nuevaController.text) {
                              return 'Las contraseñas no coinciden.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.shield_outlined,
                                color: AppColors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Usa una contraseña de al menos 8 caracteres y evita reutilizar la contraseña anterior.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _procesando ? null : _cambiarPassword,
                            icon: _procesando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _procesando
                                  ? 'Actualizando...'
                                  : 'Guardar nueva contraseña',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        if (!widget.obligatorio) ...<Widget>[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _procesando
                                ? null
                                : _continuarSinCambiar,
                            icon: const Icon(Icons.arrow_forward_outlined),
                            label: const Text('Ahora no, continuar'),
                          ),
                        ],
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
}

/// ===============================================================
/// CABECERA DE SEGURIDAD
/// ===============================================================
class _CabeceraSeguridad extends StatelessWidget {
  const _CabeceraSeguridad({
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.icono,
  });

  final String titulo;
  final String descripcion;
  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.navyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icono, size: 38, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// PROGRESO DE 30 SESIONES
/// ===============================================================
class _ProgresoSesiones extends StatelessWidget {
  const _ProgresoSesiones({required this.sesiones});

  final int sesiones;

  @override
  Widget build(BuildContext context) {
    final int valor = sesiones.clamp(0, 30);

    final double progreso = valor / 30;

    final Color color = valor >= 30
        ? AppColors.riskOrange
        : valor >= 25
        ? AppColors.yellow
        : AppColors.primaryBright;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vigencia de contraseña',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$valor / 30',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
