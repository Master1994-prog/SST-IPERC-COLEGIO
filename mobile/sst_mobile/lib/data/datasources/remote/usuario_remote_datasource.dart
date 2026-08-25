import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/usuario_model.dart';

/// ===============================================================
/// DATASOURCE REMOTO DE USUARIOS - SST EDURISK
/// ===============================================================
///
/// Comunica Flutter con el módulo de usuarios del backend.
///
/// IMPORTANTE:
/// - Ya no utiliza IDs de auditoría fijos.
/// - usuarioRegistroId, usuarioActualizacionId y usuarioId son obligatorios.
/// - El ID debe provenir de la sesión autenticada.
/// - El backend debe validar adicionalmente el usuario desde el JWT.
/// ===============================================================
class UsuarioRemoteDatasource {
  UsuarioRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // =============================================================
  // OBTENER TODOS
  // =============================================================

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

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  Future<UsuarioModel> obtenerPorId(int id) async {
    _validarIdUsuario(id);

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

  // =============================================================
  // CREAR USUARIO
  // =============================================================

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
    required int usuarioRegistroId,
  }) async {
    _validarDatosUsuario(
      nombres: nombres,
      apellidos: apellidos,
      nombreUsuario: nombreUsuario,
      institucionId: institucionId,
    );

    if (password.length < 8) {
      throw Exception('La contraseña debe tener al menos 8 caracteres.');
    }

    _validarUsuarioAuditoria(usuarioRegistroId, campo: 'usuarioRegistroId');

    final List<int> rolesValidos = _normalizarRoles(rolIds);

    if (rolesValidos.isEmpty) {
      throw Exception('Debe seleccionar al menos un rol.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'numeroDocumento': _textoOpcional(numeroDocumento),
        'tipoDocumento': _textoOpcional(tipoDocumento),
        'correo': correo.trim().isEmpty ? null : correo.trim().toLowerCase(),
        'telefono': _textoOpcional(telefono),
        'nombreUsuario': nombreUsuario.trim().toLowerCase(),
        'password': password,
        'institucionId': institucionId,
        'sedeId': _idOpcionalValido(sedeId),
        'areaId': _idOpcionalValido(areaId),
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

  // =============================================================
  // ACTUALIZAR USUARIO
  // =============================================================

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
    required int usuarioActualizacionId,
  }) async {
    _validarIdUsuario(id);

    _validarDatosUsuario(
      nombres: nombres,
      apellidos: apellidos,
      nombreUsuario: nombreUsuario,
      institucionId: institucionId,
    );

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'numeroDocumento': _textoOpcional(numeroDocumento),
        'tipoDocumento': _textoOpcional(tipoDocumento),
        'correo': correo.trim().isEmpty ? null : correo.trim().toLowerCase(),
        'telefono': _textoOpcional(telefono),
        'nombreUsuario': nombreUsuario.trim().toLowerCase(),
        'institucionId': institucionId,
        'sedeId': _idOpcionalValido(sedeId),
        'areaId': _idOpcionalValido(areaId),
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

  // =============================================================
  // CAMBIAR CONTRASEÑA
  // =============================================================

  Future<String> cambiarPassword({
    required int id,
    required String nuevaPassword,
    bool debeCambiarPassword = true,
    required int usuarioActualizacionId,
  }) async {
    _validarIdUsuario(id);

    if (nuevaPassword.length < 8) {
      throw Exception('La nueva contraseña debe tener al menos 8 caracteres.');
    }

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

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

  // =============================================================
  // ACTUALIZAR ROLES
  // =============================================================

  Future<UsuarioModel> actualizarRoles({
    required int id,
    required List<int> rolIds,
    required int usuarioActualizacionId,
  }) async {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

    final List<int> rolesValidos = _normalizarRoles(rolIds);

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

  // =============================================================
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<String> cambiarEstado({
    required int id,
    required bool activo,
    required int usuarioActualizacionId,
  }) async {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(
      usuarioActualizacionId,
      campo: 'usuarioActualizacionId',
    );

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

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<String> eliminar({required int id, required int usuarioId}) async {
    _validarIdUsuario(id);

    _validarUsuarioAuditoria(usuarioId, campo: 'usuarioId');

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

  // =============================================================
  // MENSAJES DE RESPUESTA
  // =============================================================

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

  // =============================================================
  // MANEJO DE ERRORES DIO
  // =============================================================

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

    final int? statusCode = error.response?.statusCode;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Se agotó el tiempo de conexión con el servidor.',

      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. '
            'Verifica que la API esté ejecutándose.',

      DioExceptionType.badResponse when statusCode == 400 =>
        'Los datos enviados no son válidos.',

      DioExceptionType.badResponse when statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when statusCode == 403 =>
        'No tienes permiso para realizar esta operación.',

      DioExceptionType.badResponse when statusCode == 404 =>
        'No se encontró el usuario solicitado.',

      DioExceptionType.badResponse when statusCode == 409 =>
        'No se pudo completar la operación porque existe '
            'información duplicada o relacionada.',

      DioExceptionType.badResponse
          when statusCode != null && statusCode >= 500 =>
        'El servidor presentó un error al procesar la solicitud.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => mensajePredeterminado,
    };
  }

  // =============================================================
  // VALIDACIONES
  // =============================================================

  void _validarIdUsuario(int id) {
    if (id <= 0) {
      throw Exception('El identificador del usuario no es válido.');
    }
  }

  void _validarUsuarioAuditoria(int usuarioId, {required String campo}) {
    if (usuarioId <= 0) {
      throw Exception(
        'No se pudo identificar al usuario autenticado '
        'para $campo.',
      );
    }
  }

  void _validarDatosUsuario({
    required String nombres,
    required String apellidos,
    required String nombreUsuario,
    required int institucionId,
  }) {
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
  }

  List<int> _normalizarRoles(List<int> rolIds) {
    final List<int> roles = rolIds
        .where((int rolId) => rolId > 0)
        .toSet()
        .toList();

    roles.sort();

    return roles;
  }

  String? _textoOpcional(String valor) {
    final String texto = valor.trim();

    return texto.isEmpty ? null : texto;
  }

  int? _idOpcionalValido(int? valor) {
    if (valor == null || valor <= 0) {
      return null;
    }

    return valor;
  }

  String _limpiarMensaje(Object error) {
    String mensaje = error.toString().trim();

    const List<String> prefijos = <String>[
      'Exception: ',
      'StateError: ',
      'Bad state: ',
      'ArgumentError: ',
    ];

    for (final String prefijo in prefijos) {
      if (mensaje.startsWith(prefijo)) {
        mensaje = mensaje.substring(prefijo.length);
      }
    }

    return mensaje.isEmpty ? 'Ocurrió un error inesperado.' : mensaje;
  }
}
