import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/usuario_model.dart';

/// Accede al endpoint remoto de usuarios.
class UsuarioRemoteDatasource {
  UsuarioRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todos los usuarios activos.
  ///
  /// Permite filtrar por institución, sede, área y rol.
  Future<List<UsuarioModel>> obtenerTodos({
    int? institucionId,
    int? sedeId,
    int? areaId,
    int? rolId,
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

      if (rolId != null && rolId > 0) {
        parametros['rolId'] = rolId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.usuariosEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return UsuarioModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los usuarios.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene un usuario por su identificador.
  Future<UsuarioModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.usuariosEndpoint}/$id',
      );

      final Map<String, dynamic> json = UsuarioModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un usuario inválido.');
      }

      return UsuarioModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el usuario.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo usuario.
  Future<UsuarioModel> crear({
    required String nombres,
    required String apellidos,
    required String numeroDocumento,
    required String tipoDocumento,
    required String correo,
    required String telefono,
    required String nombreUsuario,
    required String password,
    required int institucionId,
    int? sedeId,
    int? areaId,
    required List<int> rolIds,
    bool debeCambiarPassword = true,
    int usuarioRegistroId = 1,
  }) async {
    if (nombres.trim().length < 2) {
      throw Exception('Los nombres deben tener al menos 2 caracteres.');
    }

    if (apellidos.trim().length < 2) {
      throw Exception('Los apellidos deben tener al menos 2 caracteres.');
    }

    if (nombreUsuario.trim().length < 4) {
      throw Exception('El nombre de usuario debe tener al menos 4 caracteres.');
    }

    if (password.length < 8) {
      throw Exception('La contraseña debe tener al menos 8 caracteres.');
    }

    if (institucionId <= 0) {
      throw Exception('Debe seleccionar una institución válida.');
    }

    final List<int> rolesValidos = rolIds
        .where((int id) => id > 0)
        .toSet()
        .toList();

    if (rolesValidos.isEmpty) {
      throw Exception('Debe seleccionar al menos un rol.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'numeroDocumento': numeroDocumento.trim().isEmpty
            ? null
            : numeroDocumento.trim(),
        'tipoDocumento': tipoDocumento.trim().isEmpty
            ? null
            : tipoDocumento.trim(),
        'correo': correo.trim().isEmpty ? null : correo.trim().toLowerCase(),
        'telefono': telefono.trim().isEmpty ? null : telefono.trim(),
        'nombreUsuario': nombreUsuario.trim().toLowerCase(),
        'password': password,
        'institucionId': institucionId,
        'sedeId': sedeId,
        'areaId': areaId,
        'rolIds': rolesValidos,
        'debeCambiarPassword': debeCambiarPassword,
        'usuarioRegistroId': usuarioRegistroId,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.usuariosEndpoint,
        data: datos,
      );

      final Map<String, dynamic> json = UsuarioModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el usuario creado.');
      }

      return UsuarioModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el usuario.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza los datos generales de un usuario.
  Future<UsuarioModel> actualizar({
    required int id,
    required String nombres,
    required String apellidos,
    required String numeroDocumento,
    required String tipoDocumento,
    required String correo,
    required String telefono,
    required String nombreUsuario,
    required int institucionId,
    int? sedeId,
    int? areaId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    if (nombres.trim().length < 2) {
      throw Exception('Los nombres deben tener al menos 2 caracteres.');
    }

    if (apellidos.trim().length < 2) {
      throw Exception('Los apellidos deben tener al menos 2 caracteres.');
    }

    if (nombreUsuario.trim().length < 4) {
      throw Exception('El nombre de usuario debe tener al menos 4 caracteres.');
    }

    if (institucionId <= 0) {
      throw Exception('Debe seleccionar una institución válida.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'numeroDocumento': numeroDocumento.trim().isEmpty
            ? null
            : numeroDocumento.trim(),
        'tipoDocumento': tipoDocumento.trim().isEmpty
            ? null
            : tipoDocumento.trim(),
        'correo': correo.trim().isEmpty ? null : correo.trim().toLowerCase(),
        'telefono': telefono.trim().isEmpty ? null : telefono.trim(),
        'nombreUsuario': nombreUsuario.trim().toLowerCase(),
        'institucionId': institucionId,
        'sedeId': sedeId,
        'areaId': areaId,
        'activo': activo,
        'usuarioActualizacionId': usuarioActualizacionId,
      };

      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.usuariosEndpoint}/$id',
        data: datos,
      );

      final Map<String, dynamic> json = UsuarioModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el usuario actualizado.');
      }

      return UsuarioModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el usuario.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Cambia la contraseña de un usuario.
  Future<String> cambiarPassword({
    required int id,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    if (nuevaPassword.length < 8) {
      throw Exception('La nueva contraseña debe tener al menos 8 caracteres.');
    }

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.usuariosEndpoint}/$id/password',
        data: <String, dynamic>{
          'nuevaPassword': nuevaPassword,
          'debeCambiarPassword': debeCambiarPassword,
          'usuarioActualizacionId': usuarioActualizacionId,
        },
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Contraseña actualizada correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cambiar la contraseña.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Reemplaza los roles asignados al usuario.
  Future<UsuarioModel> actualizarRoles({
    required int id,
    required List<int> rolIds,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    final List<int> rolesValidos = rolIds
        .where((int rolId) => rolId > 0)
        .toSet()
        .toList();

    if (rolesValidos.isEmpty) {
      throw Exception('Debe seleccionar al menos un rol.');
    }

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.usuariosEndpoint}/$id/roles',
        data: <String, dynamic>{
          'rolIds': rolesValidos,
          'usuarioActualizacionId': usuarioActualizacionId,
        },
      );

      final Map<String, dynamic> json = UsuarioModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el usuario actualizado.');
      }

      return UsuarioModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron actualizar los roles del usuario.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Activa o desactiva un usuario.
  Future<String> cambiarEstado({
    required int id,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.patch(
        '${ApiConfig.usuariosEndpoint}/$id/estado',
        data: <String, dynamic>{
          'activo': activo,
          'usuarioActualizacionId': usuarioActualizacionId,
        },
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: activo
            ? 'Usuario activado correctamente.'
            : 'Usuario desactivado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cambiar el estado del usuario.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Realiza la eliminación lógica del usuario.
  Future<String> eliminar({required int id, int usuarioId = 1}) async {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.usuariosEndpoint}/$id'
        '?usuarioId=$usuarioId',
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Usuario eliminado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el usuario.',
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
        'No se encontró el usuario solicitado.',

      DioExceptionType.badResponse when error.response?.statusCode == 409 =>
        'No se pudo completar la operación porque existe información duplicada o relacionada.',

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
