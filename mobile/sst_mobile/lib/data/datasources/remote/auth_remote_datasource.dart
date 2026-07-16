import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/login_response_model.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String usuario,
    required String password,
  }) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.loginEndpoint,
      data: <String, dynamic>{'usuario': usuario, 'password': password},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('La respuesta del servidor no es válida.');
    }

    return LoginResponseModel.fromMap(response.data as Map<String, dynamic>);
  }
}
