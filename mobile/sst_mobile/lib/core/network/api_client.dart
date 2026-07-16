import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        responseType: ResponseType.json,
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _configureInterceptors();
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  void _configureInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await SecureStorageService.instance
                  .getAccessToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String endpoint, {Object? data}) {
    return _dio.post(endpoint, data: data);
  }

  Future<Response<dynamic>> put(String endpoint, {Object? data}) {
    return _dio.put(endpoint, data: data);
  }

  Future<Response<dynamic>> delete(String endpoint) {
    return _dio.delete(endpoint);
  }
}
