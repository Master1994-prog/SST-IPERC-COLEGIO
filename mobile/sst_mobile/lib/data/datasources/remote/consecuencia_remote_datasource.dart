import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/consecuencia_model.dart';

class ConsecuenciaRemoteDatasource {
  ConsecuenciaRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<ConsecuenciaModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.consecuenciasEndpoint,
      );

      return ConsecuenciaModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar las consecuencias.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<List<ConsecuenciaModel>> obtenerActivos() async {
    final List<ConsecuenciaModel> consecuencias = await obtenerTodos();

    return consecuencias
        .where((consecuencia) => consecuencia.estaDisponible)
        .toList();
  }

  Future<ConsecuenciaModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la consecuencia no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.consecuenciasEndpoint}/$id',
      );

      if (response.data is! Map) {
        throw Exception('El servidor devolvió una consecuencia inválida.');
      }

      return ConsecuenciaModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar la consecuencia.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<ConsecuenciaModel> crear(CrearConsecuenciaRequest request) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.consecuenciasEndpoint,
        data: request.toJson(),
      );

      if (response.data is Map) {
        return ConsecuenciaModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      final int? idCreado = _obtenerIdDesdeLocation(
        response.headers.value('location'),
      );

      if (idCreado != null) {
        return obtenerPorId(idCreado);
      }

      throw Exception(
        'La consecuencia fue registrada, '
        'pero el servidor no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar la consecuencia.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<ConsecuenciaModel> actualizar(
    int id,
    ActualizarConsecuenciaRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador de la consecuencia no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.consecuenciasEndpoint}/$id',
        data: request.toJson(),
      );

      if (response.data is Map) {
        return ConsecuenciaModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar la consecuencia.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la consecuencia no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.consecuenciasEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar la consecuencia.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  Future<List<ConsecuenciaModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<ConsecuenciaModel> consecuencias = await obtenerTodos();

    if (criterio.isEmpty) {
      return consecuencias;
    }

    return consecuencias.where((consecuencia) {
      return consecuencia.codigo.toLowerCase().contains(criterio) ||
          consecuencia.nombre.toLowerCase().contains(criterio) ||
          consecuencia.descripcionVisible.toLowerCase().contains(criterio) ||
          consecuencia.clasificacionVisible.toLowerCase().contains(criterio) ||
          consecuencia.gravedadVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  void _validarCrearRequest(CrearConsecuenciaRequest request) {
    final String codigo = request.codigo.trim();

    if (codigo.isEmpty) {
      throw Exception('El código de la consecuencia es obligatorio.');
    }

    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre de la consecuencia debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre de la consecuencia no puede superar '
        'los 200 caracteres.',
      );
    }

    final String descripcion = request.descripcion?.trim() ?? '';

    if (descripcion.length > 1000) {
      throw Exception(
        'La descripción no puede superar '
        'los 1000 caracteres.',
      );
    }

    final String clasificacion = request.clasificacion?.trim() ?? '';

    if (clasificacion.length > 150) {
      throw Exception(
        'La clasificación no puede superar '
        'los 150 caracteres.',
      );
    }

    if (request.usuarioRegistroId <= 0) {
      throw Exception('El usuario que registra no es válido.');
    }
  }

  void _validarActualizarRequest(ActualizarConsecuenciaRequest request) {
    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre de la consecuencia debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre de la consecuencia no puede superar '
        'los 200 caracteres.',
      );
    }

    final String descripcion = request.descripcion?.trim() ?? '';

    if (descripcion.length > 1000) {
      throw Exception(
        'La descripción no puede superar '
        'los 1000 caracteres.',
      );
    }

    final String clasificacion = request.clasificacion?.trim() ?? '';

    if (clasificacion.length > 150) {
      throw Exception(
        'La clasificación no puede superar '
        'los 150 caracteres.',
      );
    }

    if (request.usuarioActualizacionId <= 0) {
      throw Exception('El usuario que actualiza no es válido.');
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
          mapa['title'] ??
          mapa['detail'] ??
          mapa['error'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      final dynamic errores = mapa['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final dynamic valor in errores.values) {
          if (valor is List) {
            mensajes.addAll(valor.map((elemento) => elemento.toString()));
          } else if (valor != null) {
            mensajes.add(valor.toString());
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Se agotó el tiempo para conectar '
            'con el servidor.';

      case DioExceptionType.sendTimeout:
        return 'Se agotó el tiempo para enviar '
            'los datos al servidor.';

      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó demasiado '
            'en responder.';

      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor.';

      case DioExceptionType.badCertificate:
        return 'El certificado del servidor '
            'no es válido.';

      case DioExceptionType.cancel:
        return 'La solicitud fue cancelada.';

      case DioExceptionType.badResponse:
        return _mensajePorCodigoHttp(
          error.response?.statusCode,
          mensajePredeterminado,
        );

      case DioExceptionType.transformTimeout:
        return 'Se agotó el tiempo al procesar '
            'la respuesta del servidor.';

      case DioExceptionType.unknown:
        return mensajePredeterminado;
    }
  }

  String _mensajePorCodigoHttp(int? codigo, String mensajePredeterminado) {
    switch (codigo) {
      case 400:
        return 'Los datos enviados no son válidos.';

      case 401:
        return 'La sesión ha vencido o no está autorizada.';

      case 403:
        return 'No tienes permisos para realizar '
            'esta operación.';

      case 404:
        return 'La consecuencia solicitada no existe.';

      case 409:
        return 'Ya existe una consecuencia '
            'con los mismos datos.';

      case 422:
        return 'El servidor no pudo procesar '
            'los datos enviados.';

      case 500:
        return 'Ocurrió un error interno en el servidor.';

      default:
        return mensajePredeterminado;
    }
  }

  int? _obtenerIdDesdeLocation(String? location) {
    if (location == null || location.trim().isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(location.trim());

    if (uri == null || uri.pathSegments.isEmpty) {
      return null;
    }

    return int.tryParse(uri.pathSegments.last);
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
