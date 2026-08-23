import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/solicitud_seguridad_model.dart';

class SolicitudSeguridadRemoteDatasource {
  SolicitudSeguridadRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // =============================================================
  // SOLICITUDES DE ACCESO
  // =============================================================

  Future<List<SolicitudAccesoModel>> obtenerSolicitudesAcceso({
    String? estado,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.solicitudesAccesoEndpoint,
        queryParameters: estado == null || estado.trim().isEmpty
            ? null
            : <String, dynamic>{'estado': estado.trim().toUpperCase()},
      );

      return SolicitudAccesoModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(
          error,
          'No se pudieron cargar las solicitudes de acceso.',
        ),
      );
    }
  }

  Future<String> cambiarEstadoAcceso({
    required int id,
    required String estado,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.solicitudesAccesoEndpoint}/$id/estado',
        data: <String, dynamic>{'estado': estado.toUpperCase()},
      );

      return _extraerMensaje(
        response.data,
        'Solicitud actualizada correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No se pudo actualizar la solicitud.'),
      );
    }
  }

  // =============================================================
  // RECUPERACIÓN
  // =============================================================

  Future<List<SolicitudRecuperacionModel>> obtenerSolicitudesRecuperacion({
    String? estado,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.solicitudesRecuperacionEndpoint,
        queryParameters: estado == null || estado.trim().isEmpty
            ? null
            : <String, dynamic>{'estado': estado.trim().toUpperCase()},
      );

      return SolicitudRecuperacionModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(
          error,
          'No se pudieron cargar las solicitudes de recuperación.',
        ),
      );
    }
  }

  Future<String> cambiarEstadoRecuperacion({
    required int id,
    required String estado,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.solicitudesRecuperacionEndpoint}/$id/estado',
        data: <String, dynamic>{'estado': estado.toUpperCase()},
      );

      return _extraerMensaje(
        response.data,
        'Solicitud actualizada correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No se pudo actualizar la recuperación.'),
      );
    }
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  String _extraerMensaje(dynamic data, String predeterminado) {
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'] ?? mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    return predeterminado;
  }

  String _mensajeError(DioException error, String predeterminado) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'] ?? mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'La sesión venció. Inicia sesión nuevamente.';
    }

    if (error.response?.statusCode == 403) {
      return 'Solo el SUPER_ADMIN puede administrar estas solicitudes.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar con el servidor.';
    }

    return predeterminado;
  }
}
