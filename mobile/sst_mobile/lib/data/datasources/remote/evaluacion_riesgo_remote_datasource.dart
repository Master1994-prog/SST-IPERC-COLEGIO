import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/evaluacion_riesgo_model.dart';

/// Comunica las evaluaciones de riesgo con la API.
class EvaluacionRiesgoRemoteDatasource {
  EvaluacionRiesgoRemoteDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<EvaluacionRiesgoModel> crear(
    CrearEvaluacionRiesgoRequest request,
  ) async {
    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.evaluacionesRiesgoEndpoint,
        data: request.toJson(),
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception(
          'La evaluacion fue registrada, pero el servidor no devolvio datos.',
        );
      }

      return EvaluacionRiesgoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo registrar la evaluacion de riesgo.',
        ),
      );
    }
  }

  Map<String, dynamic> _extraerObjeto(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);
    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['evaluacion'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  String _obtenerMensaje(
    DioException error, {
    required String predeterminado,
  }) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);
      final dynamic mensaje =
          mapa['mensaje'] ??
          mapa['message'] ??
          mapa['detail'] ??
          mapa['error'] ??
          mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Se agoto el tiempo de conexion con el servidor.',
      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. Verifica la API y tu conexion.',
      DioExceptionType.badCertificate =>
        'El certificado del servidor no es valido.',
      DioExceptionType.cancel => 'La solicitud fue cancelada.',
      _ => predeterminado,
    };
  }
}
