import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/proceso_model.dart';

/// Accede al endpoint de procesos.
class ProcesoRemoteDatasource {
  ProcesoRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<ProcesoModel>> obtenerTodos({int? areaId}) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (areaId != null && areaId > 0) {
        parametros['areaId'] = areaId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.procesosEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return ProcesoModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los procesos.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<ProcesoModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del proceso no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.procesosEndpoint}/$id',
      );

      final Map<String, dynamic> json = ProcesoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un proceso inválido.');
      }

      return ProcesoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(error, predeterminado: 'No se pudo cargar el proceso.'),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<ProcesoModel> crear({
    required String nombre,
    required String descripcion,
    required int areaId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) async {
    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'areaId': areaId,
        'usuarioRegistroId': usuarioRegistroId,
        'colegioId': colegioId,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.procesosEndpoint,
        data: datos,
      );

      final Map<String, dynamic> json = ProcesoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el proceso creado.');
      }

      return ProcesoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo registrar el proceso.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<ProcesoModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int areaId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del proceso no es válido.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'areaId': areaId,
        'activo': activo,
        'usuarioActualizacionId': usuarioActualizacionId,
      };

      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.procesosEndpoint}/$id',
        data: datos,
      );

      final Map<String, dynamic> json = ProcesoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el proceso actualizado.');
      }

      return ProcesoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo actualizar el proceso.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<String> eliminar({required int id, int usuarioId = 1}) async {
    if (id <= 0) {
      throw Exception('El identificador del proceso no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.procesosEndpoint}/$id'
        '?usuarioId=$usuarioId',
      );

      return _extraerMensaje(
        response.data,
        predeterminado: 'Proceso eliminado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo eliminar el proceso.',
        ),
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
        'No se encontró el proceso solicitado.',

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
