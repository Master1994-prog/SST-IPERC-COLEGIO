import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/area_model.dart';

/// Accede al endpoint de áreas del backend.
class AreaRemoteDatasource {
  AreaRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<AreaModel>> obtenerTodas({int? institucionId}) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (institucionId != null && institucionId > 0) {
        parametros['institucionId'] = institucionId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.areasEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return AreaModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar las áreas.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<AreaModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del área no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.areasEndpoint}/$id',
      );

      final Map<String, dynamic> json = AreaModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un área inválida.');
      }

      return AreaModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(error, predeterminado: 'No se pudo cargar el área.'),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<AreaModel> crear({
    required String nombre,
    required String descripcion,
    required int institucionId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) async {
    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'institucionId': institucionId,
        'usuarioRegistroId': usuarioRegistroId,
        'colegioId': colegioId,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.areasEndpoint,
        data: datos,
      );

      final Map<String, dynamic> json = AreaModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el área creada.');
      }

      return AreaModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(error, predeterminado: 'No se pudo registrar el área.'),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<AreaModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int institucionId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del área no es válido.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'institucionId': institucionId,
        'activo': activo,
        'usuarioActualizacionId': usuarioActualizacionId,
      };

      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.areasEndpoint}/$id',
        data: datos,
      );

      final Map<String, dynamic> json = AreaModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el área actualizada.');
      }

      return AreaModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo actualizar el área.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<String> eliminar({required int id, int usuarioId = 1}) async {
    if (id <= 0) {
      throw Exception('El identificador del área no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.areasEndpoint}/$id'
        '?usuarioId=$usuarioId',
      );

      return _extraerMensaje(
        response.data,
        predeterminado: 'Área eliminada correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(error, predeterminado: 'No se pudo eliminar el área.'),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  String _extraerMensaje(dynamic data, {required String predeterminado}) {
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return predeterminado;
  }

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
            'Verifica que la API esté ejecutándose.',

      DioExceptionType.badResponse when error.response?.statusCode == 400 =>
        'Los datos enviados no son válidos.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró el área solicitada.',

      DioExceptionType.badResponse when error.response?.statusCode == 409 =>
        'La operación no puede completarse porque existen datos relacionados.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => predeterminado,
    };
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
