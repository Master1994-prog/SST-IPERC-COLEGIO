import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/login_response_model.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // =============================================================
  // LOGIN
  // =============================================================

  Future<LoginResponseModel> login({
    required String usuario,
    required String password,
  }) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.loginEndpoint,
      data: <String, dynamic>{'usuario': usuario, 'password': password},
    );

    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es válida.');
    }

    return LoginResponseModel.fromMap(response.data as Map<String, dynamic>);
  }

  // =============================================================
  // SOLICITAR ACCESO
  // =============================================================

  Future<String> solicitarAcceso({
    required String nombres,
    required String apellidos,
    required String correo,
    required String institucion,
    String? cargo,
    String? motivo,
  }) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.solicitarAccesoEndpoint,
      data: <String, dynamic>{
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
        'institucion': institucion,
        'cargo': cargo,
        'motivo': motivo,
      },
    );

    return _extraerMensaje(
      response.data,
      mensajePredeterminado: 'Solicitud registrada correctamente.',
    );
  }

  // =============================================================
  // RECUPERAR PASSWORD
  // =============================================================

  Future<String> recuperarPassword({required String identificador}) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.recuperarPasswordEndpoint,
      data: <String, dynamic>{'identificador': identificador},
    );

    return _extraerMensaje(
      response.data,
      mensajePredeterminado: 'Solicitud de recuperación registrada.',
    );
  }

  // =============================================================
  // EXTRAER MENSAJE
  // =============================================================

  String _extraerMensaje(
    dynamic contenido, {
    required String mensajePredeterminado,
  }) {
    if (contenido is Map) {
      final Map<String, dynamic> datos = Map<String, dynamic>.from(contenido);

      final dynamic mensaje =
          datos['mensaje'] ?? datos['message'] ?? datos['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    return mensajePredeterminado;
  }

  Future<String> cambiarPasswordPropio({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.cambiarPasswordPropioEndpoint,
      data: <String, dynamic>{
        'passwordActual': passwordActual,
        'nuevaPassword': nuevaPassword,
        'confirmarPassword': confirmarPassword,
      },
    );

    return _extraerMensaje(
      response.data,
      mensajePredeterminado: 'Contraseña actualizada correctamente.',
    );
  }
}
