import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/control_model.dart';

/// Fuente remota del módulo Controles.
///
/// Esta clase se comunica con el backend mediante [ApiClient].
///
/// Permite:
///
/// - Listar controles.
/// - Obtener controles activos.
/// - Consultar un control por ID.
/// - Crear controles.
/// - Actualizar controles.
/// - Eliminar controles.
/// - Buscar controles.
class ControlRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un [ApiClient] personalizado para pruebas.
  ControlRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP central de la aplicación.
  final ApiClient _apiClient;

  /// Obtiene todos los controles registrados.
  Future<List<ControlModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.controlesEndpoint,
      );

      return ControlModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los controles.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene únicamente los controles activos.
  Future<List<ControlModel>> obtenerActivos() async {
    final List<ControlModel> controles = await obtenerTodos();

    return controles
        .where((ControlModel control) => control.estaDisponible)
        .toList();
  }

  /// Obtiene un control por su identificador.
  Future<ControlModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del control no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.controlesEndpoint}/$id',
      );

      if (response.data is! Map) {
        throw Exception('El servidor devolvió un control inválido.');
      }

      return ControlModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo control.
  Future<ControlModel> crear(CrearControlRequest request) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.controlesEndpoint,
        data: request.toJson(),
      );

      if (response.data is Map) {
        return ControlModel.fromJson(
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
        'El control fue registrado, pero el servidor '
        'no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un control existente.
  Future<ControlModel> actualizar(
    int id,
    ActualizarControlRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador del control no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.controlesEndpoint}/$id',
        data: request.toJson(),
      );

      if (response.data is Map) {
        return ControlModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva un control.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del control no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.controlesEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Busca controles por código, nombre,
  /// descripción o clasificación.
  Future<List<ControlModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<ControlModel> controles = await obtenerTodos();

    if (criterio.isEmpty) {
      return controles;
    }

    return controles.where((ControlModel control) {
      return control.codigo.toLowerCase().contains(criterio) ||
          control.nombre.toLowerCase().contains(criterio) ||
          control.descripcionVisible.toLowerCase().contains(criterio) ||
          control.clasificacionVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Valida los datos antes de registrar.
  void _validarCrearRequest(CrearControlRequest request) {
    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre del control debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre del control no puede superar '
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

    if (request.clasificacionControlId != null &&
        request.clasificacionControlId! <= 0) {
      throw Exception('La clasificación del control no es válida.');
    }

    if (request.usuarioRegistroId <= 0) {
      throw Exception('El usuario que registra no es válido.');
    }
  }

  /// Valida los datos antes de actualizar.
  void _validarActualizarRequest(ActualizarControlRequest request) {
    final String nombre = request.nombre.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre del control debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (nombre.length > 200) {
      throw Exception(
        'El nombre del control no puede superar '
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

    if (request.clasificacionControlId != null &&
        request.clasificacionControlId! <= 0) {
      throw Exception('La clasificación del control no es válida.');
    }

    if (request.usuarioActualizacionId <= 0) {
      throw Exception('El usuario que actualiza no es válido.');
    }
  }

  /// Obtiene un mensaje entendible desde un error de Dio.
  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      /*
     * Primero procesa los errores de validación
     * devueltos por ASP.NET Core.
     */
      final dynamic errores = mapa['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        for (final MapEntry<dynamic, dynamic> entrada in errores.entries) {
          final String campo = entrada.key.toString().trim();

          final dynamic valor = entrada.value;

          if (valor is List) {
            for (final dynamic elemento in valor) {
              final String mensaje = elemento.toString().trim();

              if (mensaje.isNotEmpty) {
                mensajes.add(campo.isEmpty ? mensaje : '$campo: $mensaje');
              }
            }
          } else if (valor != null) {
            final String mensaje = valor.toString().trim();

            if (mensaje.isNotEmpty) {
              mensajes.add(campo.isEmpty ? mensaje : '$campo: $mensaje');
            }
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }

      /*
     * Después revisa mensajes personalizados
     * enviados por el controlador o servicio.
     */
      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'] ?? mapa['error'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      /*
     * El título se usa al final porque normalmente
     * contiene un mensaje general de ASP.NET.
     */
      final dynamic titulo = mapa['title'];

      if (titulo != null && titulo.toString().trim().isNotEmpty) {
        return titulo.toString().trim();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Se agotó el tiempo para conectar con el servidor.';

      case DioExceptionType.sendTimeout:
        return 'Se agotó el tiempo para enviar los datos al servidor.';

      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó demasiado en responder.';

      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor.';

      case DioExceptionType.badCertificate:
        return 'El certificado del servidor no es válido.';

      case DioExceptionType.cancel:
        return 'La solicitud fue cancelada.';

      case DioExceptionType.badResponse:
        return _mensajePorCodigoHttp(
          error.response?.statusCode,
          mensajePredeterminado,
        );

      case DioExceptionType.transformTimeout:
        return 'Se agotó el tiempo al procesar la respuesta del servidor.';

      case DioExceptionType.unknown:
        return mensajePredeterminado;
    }
  }

  /// Traduce códigos HTTP en mensajes entendibles.
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
        return 'El control solicitado no existe.';

      case 409:
        return 'Ya existe un control con los mismos datos.';

      case 422:
        return 'El servidor no pudo procesar '
            'los datos enviados.';

      case 500:
        return 'Ocurrió un error interno en el servidor.';

      default:
        return mensajePredeterminado;
    }
  }

  /// Intenta recuperar el ID desde el encabezado Location.
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

  /// Limpia el prefijo Exception del mensaje.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
