import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/clasificacion_control_model.dart';

/// Fuente remota del módulo Clasificaciones de Control.
///
/// Se comunica con el backend mediante [ApiClient] y permite:
///
/// - Obtener todas las clasificaciones.
/// - Obtener solamente las clasificaciones activas.
/// - Consultar una clasificación por ID.
/// - Registrar una clasificación.
/// - Actualizar una clasificación.
/// - Eliminar o desactivar una clasificación.
/// - Buscar clasificaciones.
class ClasificacionControlRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un cliente personalizado para pruebas.
  ClasificacionControlRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP central de la aplicación.
  final ApiClient _apiClient;

  /// Obtiene todas las clasificaciones de control.
  Future<List<ClasificacionControlModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.clasificacionesControlEndpoint,
      );

      return ClasificacionControlModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar las clasificaciones de control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene solamente las clasificaciones activas.
  Future<List<ClasificacionControlModel>> obtenerActivos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.clasificacionesControlEndpoint}/activos',
      );

      return ClasificacionControlModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar las clasificaciones activas.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene una clasificación mediante su identificador.
  Future<ClasificacionControlModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la clasificación no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.clasificacionesControlEndpoint}/$id',
      );

      if (!_esObjetoClasificacion(response.data)) {
        throw Exception('El servidor devolvió una clasificación inválida.');
      }

      return ClasificacionControlModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo cargar la clasificación de control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra una nueva clasificación de control.
  Future<ClasificacionControlModel> crear(
    CrearClasificacionControlRequest request,
  ) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.clasificacionesControlEndpoint,
        data: request.toJson(),
      );

      /*
       * El controlador normalmente responde con el objeto
       * registrado mediante CreatedAtAction.
       */
      if (_esObjetoClasificacion(response.data)) {
        return ClasificacionControlModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      /*
       * Como respaldo se intenta recuperar el ID
       * desde el encabezado HTTP Location.
       */
      final int? idCreado = _obtenerIdDesdeLocation(
        response.headers.value('location'),
      );

      if (idCreado != null) {
        return obtenerPorId(idCreado);
      }

      throw Exception(
        'La clasificación fue registrada, '
        'pero el servidor no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo registrar la clasificación de control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza una clasificación de control.
  ///
  /// El endpoint PUT devuelve solamente un mensaje.
  /// Por eso, después de actualizar, se consulta
  /// nuevamente el registro mediante su ID.
  Future<ClasificacionControlModel> actualizar(
    int id,
    ActualizarClasificacionControlRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador de la clasificación no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      await _apiClient.put(
        '${ApiConfig.clasificacionesControlEndpoint}/$id',
        data: request.toJson(),
      );

      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo actualizar la clasificación de control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva una clasificación.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la clasificación no es válido.');
    }

    try {
      await _apiClient.delete(
        '${ApiConfig.clasificacionesControlEndpoint}/$id',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo eliminar la clasificación de control.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Busca clasificaciones por:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  /// - Prioridad.
  ///
  /// Cuando el texto está vacío devuelve todos los registros.
  Future<List<ClasificacionControlModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<ClasificacionControlModel> clasificaciones =
        await obtenerTodos();

    if (criterio.isEmpty) {
      return clasificaciones;
    }

    return clasificaciones.where((ClasificacionControlModel clasificacion) {
      return clasificacion.codigo.toLowerCase().contains(criterio) ||
          clasificacion.nombre.toLowerCase().contains(criterio) ||
          clasificacion.descripcionVisible.toLowerCase().contains(criterio) ||
          clasificacion.prioridad.toString().contains(criterio);
    }).toList();
  }

  /// Comprueba que la respuesta sea una clasificación
  /// y no solamente un objeto con un mensaje.
  bool _esObjetoClasificacion(dynamic data) {
    if (data is! Map) {
      return false;
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    return mapa.containsKey('id') && mapa.containsKey('nombre');
  }

  /// Valida los datos antes del registro.
  void _validarCrearRequest(CrearClasificacionControlRequest request) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
    _validarPrioridad(request.prioridad);
  }

  /// Valida los datos antes de la actualización.
  void _validarActualizarRequest(
    ActualizarClasificacionControlRequest request,
  ) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
    _validarPrioridad(request.prioridad);
  }

  /// Valida el código.
  void _validarCodigo(String codigo) {
    final String valor = codigo.trim();

    if (valor.isEmpty) {
      throw Exception('El código de la clasificación es obligatorio.');
    }

    if (valor.length > 20) {
      throw Exception('El código no puede superar los 20 caracteres.');
    }

    final RegExp formato = RegExp(r'^[A-Za-z0-9\-_]+$');

    if (!formato.hasMatch(valor)) {
      throw Exception(
        'El código solamente puede contener letras, '
        'números, guiones y guion bajo.',
      );
    }
  }

  /// Valida el nombre.
  void _validarNombre(String nombre) {
    final String valor = nombre.trim();

    if (valor.isEmpty) {
      throw Exception('El nombre de la clasificación es obligatorio.');
    }

    if (valor.length < 3) {
      throw Exception('El nombre debe contener al menos 3 caracteres.');
    }

    if (valor.length > 150) {
      throw Exception('El nombre no puede superar los 150 caracteres.');
    }
  }

  /// Valida la descripción.
  void _validarDescripcion(String? descripcion) {
    final String valor = descripcion?.trim() ?? '';

    if (valor.length > 1000) {
      throw Exception('La descripción no puede superar los 1000 caracteres.');
    }
  }

  /// Valida la prioridad.
  void _validarPrioridad(int prioridad) {
    if (prioridad < 0) {
      throw Exception('La prioridad no puede ser negativa.');
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
       * ASP.NET Core devuelve los errores de validación
       * dentro del objeto "errors".
       *
       * Se procesan antes del título general.
       */
      final dynamic errores = mapa['errors'];

      if (errores is Map && errores.isNotEmpty) {
        final List<String> mensajes = <String>[];

        errores.forEach((dynamic campo, dynamic valor) {
          if (valor is List) {
            for (final dynamic elemento in valor) {
              final String mensaje = elemento.toString().trim();

              if (mensaje.isNotEmpty) {
                mensajes.add('${campo.toString()}: $mensaje');
              }
            }
          } else if (valor != null) {
            final String mensaje = valor.toString().trim();

            if (mensaje.isNotEmpty) {
              mensajes.add('${campo.toString()}: $mensaje');
            }
          }
        });

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }

      final dynamic mensaje =
          mapa['mensaje'] ??
          mapa['message'] ??
          mapa['detail'] ??
          mapa['detalle'] ??
          mapa['error'] ??
          mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
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
        return 'El certificado del servidor no es válido.';

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

  /// Traduce códigos HTTP a mensajes entendibles.
  String _mensajePorCodigoHttp(int? codigo, String mensajePredeterminado) {
    switch (codigo) {
      case 400:
        return 'Los datos enviados no son válidos.';

      case 401:
        return 'La sesión ha vencido o no está autorizada.';

      case 403:
        return 'No tienes permisos para realizar esta operación.';

      case 404:
        return 'La clasificación solicitada no existe '
            'o la ruta no está disponible.';

      case 409:
        return 'Ya existe una clasificación con '
            'el mismo código o nombre.';

      case 422:
        return 'El servidor no pudo procesar los datos enviados.';

      case 500:
        return 'Ocurrió un error interno en el servidor.';

      default:
        return mensajePredeterminado;
    }
  }

  /// Intenta obtener el ID desde el encabezado Location.
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

  /// Elimina el prefijo `Exception:` del mensaje.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
