import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _identificadorController =
      TextEditingController();

  final AuthRepository _repository = AuthRepository();

  bool _enviando = false;

  @override
  void dispose() {
    _identificadorController.dispose();

    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    if (_enviando || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final String mensaje = await _repository.recuperarPassword(
        identificador: _identificadorController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.primaryBright,
              size: 48,
            ),
            title: const Text('Solicitud recibida'),
            content: Text(mensaje, textAlign: TextAlign.center),
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(_mensajeDio(error));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(
        'No se pudo solicitar '
        'la recuperación: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  String _mensajeDio(DioException error) {
    if (error.response?.data is Map) {
      final Map<String, dynamic> datos = Map<String, dynamic>.from(
        error.response!.data as Map,
      );

      final dynamic mensaje =
          datos['mensaje'] ?? datos['message'] ?? datos['title'];

      if (mensaje != null) {
        return mensaje.toString();
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar '
          'con el servidor.';
    }

    return 'No se pudo procesar '
        'la solicitud.';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.riskOrange),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const SizedBox(height: 30),

              const Icon(Icons.lock_reset, size: 78, color: AppColors.primary),

              const SizedBox(height: 18),

              Text(
                '¿Olvidó su contraseña?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Ingrese su nombre de usuario '
                'o correo electrónico asociado '
                'a SST EduRisk.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _identificadorController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  labelText: 'Usuario o correo electrónico',
                  prefixIcon: Icon(Icons.alternate_email_outlined),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese su usuario '
                        'o correo electrónico.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
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
                        'Por seguridad, SST EduRisk '
                        'no indicará si el usuario '
                        'o correo ingresado existe '
                        'en el sistema.',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: Text(
                    _enviando ? 'Enviando...' : 'Solicitar recuperación',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
