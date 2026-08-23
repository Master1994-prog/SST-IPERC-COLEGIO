import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';

class SolicitarAccesoScreen extends StatefulWidget {
  const SolicitarAccesoScreen({super.key});

  @override
  State<SolicitarAccesoScreen> createState() => _SolicitarAccesoScreenState();
}

class _SolicitarAccesoScreenState extends State<SolicitarAccesoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthRepository _repository = AuthRepository();

  final TextEditingController _nombresController = TextEditingController();

  final TextEditingController _apellidosController = TextEditingController();

  final TextEditingController _correoController = TextEditingController();

  final TextEditingController _institucionController = TextEditingController();

  final TextEditingController _cargoController = TextEditingController();

  final TextEditingController _motivoController = TextEditingController();

  bool _enviando = false;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _institucionController.dispose();
    _cargoController.dispose();
    _motivoController.dispose();

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
      final String mensaje = await _repository.solicitarAcceso(
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        correo: _correoController.text.trim(),
        institucion: _institucionController.text.trim(),
        cargo: _textoOpcional(_cargoController.text),
        motivo: _textoOpcional(_motivoController.text),
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 48,
            ),
            title: const Text('Solicitud enviada'),
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
        'No se pudo enviar la solicitud: '
        '$error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  String? _textoOpcional(String texto) {
    final String valor = texto.trim();

    return valor.isEmpty ? null : valor;
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
      return 'No se pudo conectar con '
          'el servidor.';
    }

    return 'No se pudo enviar '
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
      appBar: AppBar(title: const Text('Solicitar acceso')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Icon(
                Icons.person_add_alt_1,
                size: 64,
                color: AppColors.primary,
              ),

              const SizedBox(height: 12),

              Text(
                'Solicitud de acceso',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Complete sus datos. '
                'Un administrador revisará '
                'la solicitud antes de '
                'habilitar una cuenta.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _nombresController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombres *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validarObligatorio,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _apellidosController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellidos *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validarObligatorio,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _validarCorreo,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _institucionController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Institución educativa *',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: _validarObligatorio,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _cargoController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Cargo / puesto',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _motivoController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la solicitud',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),

              const SizedBox(height: 24),

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
                      : const Icon(Icons.send_outlined),
                  label: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validarObligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validarCorreo(String? value) {
    final String correo = value?.trim() ?? '';

    if (correo.isEmpty) {
      return 'Ingrese su correo.';
    }

    final RegExp expresion = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!expresion.hasMatch(correo)) {
      return 'Ingrese un correo válido.';
    }

    return null;
  }
}
