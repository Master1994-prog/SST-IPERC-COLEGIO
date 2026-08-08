import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/sede_model.dart';

/// Accede al endpoint remoto de sedes.
class SedeRemoteDatasource {
  SedeRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todas las sedes activas.
  ///
  /// Puede filtrar por institución.
  Future<List<SedeModel>> obtenerTodas({int? institucionId}) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (institucionId != null && institucionId > 0) {
        parametros['institucionId'] = institucionId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.sedesEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return SedeModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar las sedes.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene una sede por su identificador.
  Future<SedeModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la sede no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.sedesEndpoint}/$id',
      );

      final Map<String, dynamic> json = SedeModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió una sede inválida.');
      }

      return SedeModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar la sede.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
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

      final dynamic errores = mapa['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final dynamic valor in errores.values) {
          if (valor is List) {
            mensajes.addAll(
              valor
                  .map((dynamic item) => item.toString().trim())
                  .where((String item) => item.isNotEmpty),
            );
          } else if (valor != null) {
            final String texto = valor.toString().trim();

            if (texto.isNotEmpty) {
              mensajes.add(texto);
            }
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
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
            'Verifica que la API esté ejecutándose.',

      DioExceptionType.badResponse when error.response?.statusCode == 400 =>
        'La solicitud enviada no es válida.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para consultar las sedes.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró la sede solicitada.',

      DioExceptionType.badResponse
          when error.response?.statusCode != null &&
              error.response!.statusCode! >= 500 =>
        'El servidor presentó un error al procesar la solicitud.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => mensajePredeterminado,
    };
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
