import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/rol_model.dart';

/// Accede al endpoint remoto de roles.
class RolRemoteDatasource {
  RolRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todos los roles activos.
  /// Puede filtrar por alcance global.
  Future<List<RolModel>> obtenerTodos({bool? esGlobal}) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (esGlobal != null) {
        parametros['esGlobal'] = esGlobal;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.rolesEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return RolModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los roles.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene un rol por su identificador.
  Future<RolModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del rol no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.rolesEndpoint}/$id',
      );

      final Map<String, dynamic> json = RolModel.objetoDesdeJson(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un rol inválido.');
      }

      return RolModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el rol.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo rol.
  Future<RolModel> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool esGlobal,
    int usuarioRegistroId = 1,
  }) async {
    if (codigo.trim().length < 2) {
      throw Exception('El código del rol debe tener al menos 2 caracteres.');
    }

    if (nombre.trim().length < 2) {
      throw Exception('El nombre del rol debe tener al menos 2 caracteres.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'codigo': codigo.trim().toUpperCase(),
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'esGlobal': esGlobal,
        'usuarioRegistroId': usuarioRegistroId,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.rolesEndpoint,
        data: datos,
      );

      final Map<String, dynamic> json = RolModel.objetoDesdeJson(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el rol creado.');
      }

      return RolModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el rol.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un rol existente.
  Future<RolModel> actualizar({
    required int id,
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool activo,
    required bool esGlobal,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del rol no es válido.');
    }

    if (codigo.trim().length < 2) {
      throw Exception('El código del rol debe tener al menos 2 caracteres.');
    }

    if (nombre.trim().length < 2) {
      throw Exception('El nombre del rol debe tener al menos 2 caracteres.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'codigo': codigo.trim().toUpperCase(),
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'activo': activo,
        'esGlobal': esGlobal,
        'usuarioActualizacionId': usuarioActualizacionId,
      };

      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.rolesEndpoint}/$id',
        data: datos,
      );

      final Map<String, dynamic> json = RolModel.objetoDesdeJson(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el rol actualizado.');
      }

      return RolModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el rol.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Activa o desactiva un rol.
  Future<RolModel> cambiarEstado({
    required int id,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del rol no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.patch(
        '${ApiConfig.rolesEndpoint}/$id/estado',
        data: <String, dynamic>{
          'activo': activo,
          'usuarioActualizacionId': usuarioActualizacionId,
        },
      );

      final Map<String, dynamic> json = RolModel.objetoDesdeJson(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el rol actualizado.');
      }

      return RolModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cambiar el estado del rol.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Realiza la eliminación lógica de un rol.
  Future<String> eliminar({required int id, int usuarioId = 1}) async {
    if (id <= 0) {
      throw Exception('El identificador del rol no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.rolesEndpoint}/$id'
        '?usuarioId=$usuarioId',
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Rol eliminado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el rol.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  String _extraerMensaje(
    dynamic data, {
    required String mensajePredeterminado,
  }) {
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'] ?? mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return mensajePredeterminado;
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
        'Los datos enviados no son válidos.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para realizar esta operación.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró el rol solicitado.',

      DioExceptionType.badResponse when error.response?.statusCode == 409 =>
        'No se puede completar la operación porque el rol está duplicado o tiene usuarios relacionados.',

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
