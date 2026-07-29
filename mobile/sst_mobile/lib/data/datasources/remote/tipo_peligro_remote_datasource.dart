import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/tipo_peligro_model.dart';

/// Fuente remota del catálogo Tipos de Peligro.
///
/// Se comunica con el backend mediante [ApiClient].
class TipoPeligroRemoteDatasource {
  TipoPeligroRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene todos los tipos de peligro.
  Future<List<TipoPeligroModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.tiposPeligroEndpoint,
      );

      return TipoPeligroModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los tipos de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene solamente los tipos activos.
  ///
  /// Primero intenta usar el endpoint `/activos`.
  /// Cuando no existe, filtra la lista general.
  Future<List<TipoPeligroModel>> obtenerActivos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.tiposPeligroEndpoint}/activos',
      );

      return TipoPeligroModel.listaDesdeJson(
        response.data,
      ).where((TipoPeligroModel tipo) => tipo.estaDisponible).toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 405) {
        final List<TipoPeligroModel> tipos = await obtenerTodos();

        return tipos
            .where((TipoPeligroModel tipo) => tipo.estaDisponible)
            .toList();
      }

      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar los tipos de peligro activos.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene un tipo de peligro por ID.
  Future<TipoPeligroModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de peligro no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.tiposPeligroEndpoint}/$id',
      );

      if (response.data is! Map) {
        throw Exception('El servidor devolvió un tipo de peligro inválido.');
      }

      return TipoPeligroModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el tipo de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo tipo de peligro.
  Future<TipoPeligroModel> crear(CrearTipoPeligroRequest request) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.tiposPeligroEndpoint,
        data: request.toJson(),
      );

      if (response.data is Map) {
        return TipoPeligroModel.fromJson(
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
        'El tipo de peligro fue registrado, '
        'pero el servidor no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el tipo de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un tipo de peligro.
  Future<TipoPeligroModel> actualizar(
    int id,
    ActualizarTipoPeligroRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de peligro no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.tiposPeligroEndpoint}/$id',
        data: request.toJson(),
      );

      /*
       * Algunos controladores devuelven el registro actualizado.
       */
      if (response.data is Map) {
        final Map<String, dynamic> mapa = Map<String, dynamic>.from(
          response.data as Map,
        );

        if (mapa.containsKey('id') || mapa.containsKey('nombre')) {
          return TipoPeligroModel.fromJson(mapa);
        }
      }

      /*
       * Cuando el PUT devuelve solamente un mensaje,
       * vuelve a consultar el registro.
       */
      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el tipo de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva un tipo de peligro.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de peligro no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.tiposPeligroEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el tipo de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Busca tipos de peligro por código,
  /// nombre o descripción.
  Future<List<TipoPeligroModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<TipoPeligroModel> tipos = await obtenerTodos();

    if (criterio.isEmpty) {
      return tipos;
    }

    return tipos.where((TipoPeligroModel tipo) {
      return tipo.codigo.toLowerCase().contains(criterio) ||
          tipo.nombre.toLowerCase().contains(criterio) ||
          tipo.descripcionVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Valida los datos para crear.
  void _validarCrearRequest(CrearTipoPeligroRequest request) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
  }

  /// Valida los datos para actualizar.
  void _validarActualizarRequest(ActualizarTipoPeligroRequest request) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
  }

  /// Valida el código.
  void _validarCodigo(String valor) {
    final String codigo = valor.trim();

    if (codigo.isEmpty) {
      throw Exception('El código del tipo de peligro es obligatorio.');
    }

    if (codigo.length > 20) {
      throw Exception('El código no puede superar los 20 caracteres.');
    }
  }

  /// Valida el nombre.
  void _validarNombre(String valor) {
    final String nombre = valor.trim();

    if (nombre.length < 3) {
      throw Exception(
        'El nombre del tipo de peligro debe '
        'tener al menos 3 caracteres.',
      );
    }

    if (nombre.length > 150) {
      throw Exception(
        'El nombre del tipo de peligro no puede '
        'superar los 150 caracteres.',
      );
    }
  }

  /// Valida la descripción.
  void _validarDescripcion(String? valor) {
    final String descripcion = valor?.trim() ?? '';

    if (descripcion.length > 1000) {
      throw Exception(
        'La descripción no puede superar '
        'los 1000 caracteres.',
      );
    }
  }

  /// Extrae un mensaje entendible desde Dio.
  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      /*
       * Primero procesa errores de validación
       * producidos por ASP.NET Core.
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

      final dynamic mensaje =
          mapa['mensaje'] ?? mapa['message'] ?? mapa['detail'] ?? mapa['error'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

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
        return 'Se agotó el tiempo al procesar '
            'la respuesta del servidor.';

      case DioExceptionType.unknown:
        return mensajePredeterminado;
    }
  }

  /// Traduce códigos HTTP.
  String _mensajePorCodigoHttp(int? codigo, String mensajePredeterminado) {
    switch (codigo) {
      case 400:
        return 'Los datos enviados no son válidos.';

      case 401:
        return 'La sesión ha vencido o no está autorizada.';

      case 403:
        return 'No tienes permisos para realizar esta operación.';

      case 404:
        return 'El tipo de peligro solicitado no existe.';

      case 409:
        return 'Ya existe un tipo de peligro con los mismos datos.';

      case 422:
        return 'El servidor no pudo procesar los datos enviados.';

      case 500:
        return 'Ocurrió un error interno en el servidor.';

      default:
        return mensajePredeterminado;
    }
  }

  /// Recupera el ID desde el encabezado Location.
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

  /// Limpia el prefijo Exception.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
