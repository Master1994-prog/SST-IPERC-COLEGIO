import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/peligro_model.dart';

class PeligroRemoteDatasource {
  PeligroRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todos los peligros registrados.
  Future<List<PeligroModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.peligrosEndpoint,
      );

      return PeligroModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los peligros.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene únicamente los peligros activos.
  Future<List<PeligroModel>> obtenerActivos() async {
    final List<PeligroModel> peligros = await obtenerTodos();

    return peligros.where((peligro) => peligro.estaDisponible).toList();
  }

  /// Obtiene un peligro por su identificador.
  Future<PeligroModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del peligro no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.peligrosEndpoint}/$id',
      );

      if (response.data is! Map) {
        throw Exception('El servidor devolvió un peligro inválido.');
      }

      return PeligroModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo peligro.
  Future<PeligroModel> crear(CrearPeligroRequest request) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.peligrosEndpoint,
        data: request.toJson(),
      );

      if (response.data is Map) {
        return PeligroModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      /*
       * Algunos controladores devuelven 201 sin incluir
       * todo el objeto creado. En ese caso, se intenta
       * obtener el ID desde el encabezado Location.
       */
      final int? idCreado = _obtenerIdDesdeLocation(
        response.headers.value('location'),
      );

      if (idCreado != null) {
        return obtenerPorId(idCreado);
      }

      throw Exception(
        'El peligro fue registrado, pero el servidor '
        'no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un peligro existente.
  Future<PeligroModel> actualizar(
    int id,
    ActualizarPeligroRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador del peligro no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.peligrosEndpoint}/$id',
        data: request.toJson(),
      );

      if (response.data is Map) {
        return PeligroModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva un peligro.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del peligro no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.peligrosEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Permite buscar peligros por nombre, código,
  /// descripción, categoría o tipo.
  Future<List<PeligroModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<PeligroModel> peligros = await obtenerTodos();

    if (criterio.isEmpty) {
      return peligros;
    }

    return peligros.where((peligro) {
      return peligro.codigo.toLowerCase().contains(criterio) ||
          peligro.nombre.toLowerCase().contains(criterio) ||
          peligro.descripcionVisible.toLowerCase().contains(criterio) ||
          peligro.categoriaVisible.toLowerCase().contains(criterio) ||
          peligro.tipoVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  void _validarCrearRequest(CrearPeligroRequest request) {
    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre del peligro debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre del peligro no puede superar '
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
  }

  void _validarActualizarRequest(ActualizarPeligroRequest request) {
    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre del peligro debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre del peligro no puede superar '
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
        final List<String> mensajes = [];

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
        return 'El peligro solicitado no existe.';

      case 409:
        return 'Ya existe un peligro con los mismos datos.';

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
