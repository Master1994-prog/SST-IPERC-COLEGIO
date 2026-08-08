import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/puesto_trabajo_model.dart';

/// Accede al endpoint remoto de puestos de trabajo.
class PuestoTrabajoRemoteDatasource {
  PuestoTrabajoRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todos los puestos de trabajo activos.
  /// Puede filtrar los resultados por área.
  Future<List<PuestoTrabajoModel>> obtenerTodos({int? areaId}) async {
    try {
      final Map<String, dynamic> parametros = <String, dynamic>{};

      if (areaId != null && areaId > 0) {
        parametros['areaId'] = areaId;
      }

      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.puestosTrabajoEndpoint,
        queryParameters: parametros.isEmpty ? null : parametros,
      );

      return PuestoTrabajoModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar los puestos de trabajo.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene un puesto de trabajo por su identificador.
  Future<PuestoTrabajoModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del puesto de trabajo no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.puestosTrabajoEndpoint}/$id',
      );

      final Map<String, dynamic> json = PuestoTrabajoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un puesto de trabajo inválido.');
      }

      return PuestoTrabajoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el puesto de trabajo.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo puesto de trabajo.
  Future<PuestoTrabajoModel> crear({
    required String nombre,
    required String descripcion,
    required int areaId,
    int usuarioRegistroId = 1,
    int? colegioId,
  }) async {
    if (nombre.trim().length < 2) {
      throw Exception('El nombre del puesto debe tener al menos 2 caracteres.');
    }

    if (areaId <= 0) {
      throw Exception('Debe seleccionar un área válida.');
    }

    try {
      final Map<String, dynamic> datos = <String, dynamic>{
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'areaId': areaId,
        'usuarioRegistroId': usuarioRegistroId,
        'colegioId': colegioId,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.puestosTrabajoEndpoint,
        data: datos,
      );

      final Map<String, dynamic> json = PuestoTrabajoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor no devolvió el puesto de trabajo creado.');
      }

      return PuestoTrabajoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el puesto de trabajo.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un puesto de trabajo existente.
  Future<PuestoTrabajoModel> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int areaId,
    required bool activo,
    int usuarioActualizacionId = 1,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del puesto de trabajo no es válido.');
    }

    if (nombre.trim().length < 2) {
      throw Exception('El nombre del puesto debe tener al menos 2 caracteres.');
    }

    if (areaId <= 0) {
      throw Exception('Debe seleccionar un área válida.');
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
        '${ApiConfig.puestosTrabajoEndpoint}/$id',
        data: datos,
      );

      final Map<String, dynamic> json = PuestoTrabajoModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception(
          'El servidor no devolvió el puesto de trabajo actualizado.',
        );
      }

      return PuestoTrabajoModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el puesto de trabajo.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Realiza la eliminación lógica de un puesto de trabajo.
  Future<String> eliminar({required int id, int usuarioId = 1}) async {
    if (id <= 0) {
      throw Exception('El identificador del puesto de trabajo no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.puestosTrabajoEndpoint}/$id'
        '?usuarioId=$usuarioId',
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Puesto de trabajo eliminado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el puesto de trabajo.',
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
            'Verifica que la API esté ejecutándose y que la dirección IP sea correcta.',

      DioExceptionType.badResponse when error.response?.statusCode == 400 =>
        'Los datos enviados no son válidos.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para realizar esta operación.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró el puesto de trabajo solicitado.',

      DioExceptionType.badResponse when error.response?.statusCode == 409 =>
        'La operación no puede completarse porque existen datos relacionados.',

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
