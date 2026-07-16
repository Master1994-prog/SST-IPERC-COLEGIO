import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class MatrizIpercRemoteDatasource {
  MatrizIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<String> create(Map<String, dynamic> data) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.matricesIpercEndpoint,
      data: data,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'El backend respondió con código '
        '${response.statusCode}.',
      );
    }

    final dynamic responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final dynamic id =
          responseData['id'] ??
          responseData['matrizIpercId'] ??
          responseData['data']?['id'];

      if (id != null) {
        return id.toString();
      }
    }

    throw Exception(
      'El backend guardó la matriz, pero no devolvió su identificador.',
    );
  }
}
