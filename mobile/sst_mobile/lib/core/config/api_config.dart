class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.18.23:5006/api';

  static const Duration connectTimeout = Duration(seconds: 20);

  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String loginEndpoint = '/Auth/login';
  static const String matricesIpercEndpoint = '/iperc';
}
