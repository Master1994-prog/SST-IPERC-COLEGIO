import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/usuario_model.dart';

/// Consulta en el backend los usuarios disponibles.
class UsuarioRemoteDatasource {
  UsuarioRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene los usuarios activos.
  ///
  /// Los filtros son opcionales.
  Future<List<UsuarioModel>> obtenerTodos({
    int? institucionId,
    int? sedeId,
    int? areaId,
  }) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (institucionId != null && institucionId > 0) {
        parametros['institucionId'] = institucionId;
      }

      if (sedeId != null && sedeId > 0) {
        parametros['sedeId'] = sedeId;
      }

      if (areaId != null && areaId > 0) {
        parametros['areaId'] = areaId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.usuariosEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return UsuarioModel.listaDesdeJson(
        response.data,
      ).where((UsuarioModel usuario) => usuario.activo).toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los usuarios.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene un usuario mediante su identificador.
  Future<UsuarioModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.usuariosEndpoint}/$id',
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un usuario inválido.');
      }

      return UsuarioModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(error, predeterminado: 'No se pudo cargar el usuario.'),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Map<String, dynamic> _extraerObjeto(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    final dynamic contenido =
        mapa['data'] ?? mapa['result'] ?? mapa['value'] ?? mapa['usuario'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
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

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró el endpoint de usuarios.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => predeterminado,
    };
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
