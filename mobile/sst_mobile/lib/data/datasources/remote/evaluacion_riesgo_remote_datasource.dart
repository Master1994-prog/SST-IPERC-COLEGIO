import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/evaluacion_riesgo_model.dart';

/// Comunica las evaluaciones de riesgo con la API.
class EvaluacionRiesgoRemoteDatasource {
  EvaluacionRiesgoRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // =============================================================
  // OBTENER TODAS
  // =============================================================

  Future<List<EvaluacionRiesgoModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.evaluacionesRiesgoEndpoint,
      );

      return _extraerLista(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron obtener las evaluaciones de riesgo.',
        ),
      );
    }
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<EvaluacionRiesgoModel> obtenerPorId(int id) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.evaluacionesRiesgoEndpoint}/$id',
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió la evaluación solicitada.');
      }

      return EvaluacionRiesgoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo obtener la evaluación de riesgo.',
        ),
      );
    }
  }

  // =============================================================
  // CREAR
  // =============================================================

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
          'La evaluación fue registrada, '
          'pero el servidor no devolvió datos.',
        );
      }

      return EvaluacionRiesgoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo registrar la evaluación de riesgo.',
        ),
      );
    }
  }

  // =============================================================
  // ACTUALIZAR
  // =============================================================

  Future<void> actualizar(
    int id,
    ActualizarEvaluacionRiesgoRequest request,
  ) async {
    try {
      await _apiClient.put(
        '${ApiConfig.evaluacionesRiesgoEndpoint}/$id',
        data: request.toJson(),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo actualizar la evaluación de riesgo.',
        ),
      );
    }
  }

  // =============================================================
  // EXTRAER LISTA
  // =============================================================

  List<EvaluacionRiesgoModel> _extraerLista(dynamic data) {
    List<dynamic> lista = <dynamic>[];

    if (data is List) {
      lista = data;
    } else if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic contenido =
          mapa['data'] ??
          mapa['items'] ??
          mapa['result'] ??
          mapa['results'] ??
          mapa['value'] ??
          mapa['evaluaciones'] ??
          mapa['evaluacionesRiesgo'];

      if (contenido is List) {
        lista = contenido;
      }
    }

    return lista
        .whereType<Map>()
        .map(
          (Map item) =>
              EvaluacionRiesgoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((EvaluacionRiesgoModel evaluacion) => evaluacion.id > 0)
        .toList();
  }

  // =============================================================
  // EXTRAER OBJETO
  // =============================================================

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

  // =============================================================
  // ERRORES
  // =============================================================

  String _obtenerMensaje(DioException error, {required String predeterminado}) {
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
        'Se agotó el tiempo de conexión con el servidor.',
      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. '
            'Verifica la API y tu conexión.',
      DioExceptionType.badCertificate =>
        'El certificado del servidor no es válido.',
      DioExceptionType.cancel => 'La solicitud fue cancelada.',
      _ => predeterminado,
    };
  }
}
