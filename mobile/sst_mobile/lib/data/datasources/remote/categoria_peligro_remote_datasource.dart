import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/categoria_peligro_model.dart';

/// Fuente de datos remota para el catálogo
/// de categorías de peligro.
class CategoriaPeligroRemoteDatasource {
  CategoriaPeligroRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP utilizado por toda la aplicación.
  final ApiClient _apiClient;

  /// Obtiene todas las categorías de peligro.
  Future<List<CategoriaPeligroModel>> obtenerTodas() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.categoriasPeligroEndpoint,
      );

      return CategoriaPeligroModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar las categorías de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(
        'Ocurrió un error inesperado al cargar '
        'las categorías de peligro: $error',
      );
    }
  }

  /// Obtiene solamente las categorías activas.
  ///
  /// Intenta consultar `/activos`. Cuando el backend no
  /// implementa esa ruta, obtiene el listado general y
  /// realiza el filtro localmente.
  Future<List<CategoriaPeligroModel>> obtenerActivas() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.categoriasPeligroEndpoint}/activos',
      );

      return CategoriaPeligroModel.listaDesdeJson(response.data).where((
        CategoriaPeligroModel categoria,
      ) {
        return categoria.estaDisponible;
      }).toList();
    } on DioException catch (error) {
      final int? estadoHttp = error.response?.statusCode;

      if (estadoHttp == 404 || estadoHttp == 405) {
        final List<CategoriaPeligroModel> categorias = await obtenerTodas();

        return categorias.where((CategoriaPeligroModel categoria) {
          return categoria.estaDisponible;
        }).toList();
      }

      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar las categorías activas.',
        ),
      );
    } catch (error) {
      throw Exception(
        'Ocurrió un error inesperado al cargar '
        'las categorías activas: $error',
      );
    }
  }

  /// Obtiene una categoría por su identificador.
  Future<CategoriaPeligroModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la categoría no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.categoriasPeligroEndpoint}/$id',
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      final CategoriaPeligroModel categoria = CategoriaPeligroModel.fromJson(
        json,
      );

      if (categoria.id <= 0) {
        throw Exception('El servidor devolvió una categoría inválida.');
      }

      return categoria;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo obtener la categoría de peligro.',
        ),
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Ocurrió un error inesperado al obtener '
        'la categoría de peligro: $error',
      );
    }
  }

  /// Registra una nueva categoría de peligro.
  Future<CategoriaPeligroModel> crear(
    CrearCategoriaPeligroRequest request,
  ) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.categoriasPeligroEndpoint,
        data: request.toJson(),
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isNotEmpty) {
        final CategoriaPeligroModel categoria = CategoriaPeligroModel.fromJson(
          json,
        );

        if (categoria.id > 0) {
          return categoria;
        }
      }

      /*
       * Algunos controladores devuelven 201 o 204
       * sin incluir el objeto creado.
       */
      return CategoriaPeligroModel(
        id: 0,
        nombre: request.nombre.trim(),
        descripcion: _normalizarTexto(request.descripcion),
        color: _normalizarTexto(request.color),
        icono: _normalizarTexto(request.icono),
        orden: request.orden,
        activo: request.activo,
        estado: true,
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo registrar la categoría de peligro.',
        ),
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Ocurrió un error inesperado al registrar '
        'la categoría de peligro: $error',
      );
    }
  }

  /// Actualiza una categoría de peligro.
  Future<CategoriaPeligroModel> actualizar(
    int id,
    ActualizarCategoriaPeligroRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador de la categoría no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.categoriasPeligroEndpoint}/$id',
        data: request.toJson(),
      );

      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isNotEmpty) {
        final CategoriaPeligroModel categoria = CategoriaPeligroModel.fromJson(
          json,
        );

        if (categoria.id > 0) {
          return categoria;
        }
      }

      /*
       * Si PUT devuelve 204 sin contenido,
       * se consulta nuevamente el registro.
       */
      try {
        return await obtenerPorId(id);
      } catch (_) {
        return CategoriaPeligroModel(
          id: id,
          nombre: request.nombre.trim(),
          descripcion: _normalizarTexto(request.descripcion),
          color: _normalizarTexto(request.color),
          icono: _normalizarTexto(request.icono),
          orden: request.orden,
          activo: request.activo,
          estado: true,
          fechaActualizacion: DateTime.now(),
        );
      }
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo actualizar la categoría de peligro.',
        ),
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Ocurrió un error inesperado al actualizar '
        'la categoría de peligro: $error',
      );
    }
  }

  /// Elimina o desactiva una categoría.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la categoría no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.categoriasPeligroEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar la categoría de peligro.',
        ),
      );
    } catch (error) {
      throw Exception(
        'Ocurrió un error inesperado al eliminar '
        'la categoría de peligro: $error',
      );
    }
  }

  /// Busca categorías localmente.
  Future<List<CategoriaPeligroModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<CategoriaPeligroModel> categorias = await obtenerTodas();

    if (criterio.isEmpty) {
      return categorias;
    }

    return categorias.where((CategoriaPeligroModel categoria) {
      return categoria.nombre.toLowerCase().contains(criterio) ||
          categoria.descripcionVisible.toLowerCase().contains(criterio) ||
          categoria.colorVisible.toLowerCase().contains(criterio) ||
          categoria.iconoVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Valida una solicitud de creación.
  void _validarCrearRequest(CrearCategoriaPeligroRequest request) {
    _validarDatos(
      nombre: request.nombre,
      descripcion: request.descripcion,
      color: request.color,
      icono: request.icono,
      orden: request.orden,
    );
  }

  /// Valida una solicitud de actualización.
  void _validarActualizarRequest(ActualizarCategoriaPeligroRequest request) {
    _validarDatos(
      nombre: request.nombre,
      descripcion: request.descripcion,
      color: request.color,
      icono: request.icono,
      orden: request.orden,
    );
  }

  /// Ejecuta las validaciones compartidas.
  void _validarDatos({
    required String nombre,
    required String? descripcion,
    required String? color,
    required String? icono,
    required int orden,
  }) {
    final String nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw Exception('El nombre de la categoría es obligatorio.');
    }

    if (nombreLimpio.length < 3) {
      throw Exception('El nombre debe tener al menos 3 caracteres.');
    }

    if (nombreLimpio.length > 150) {
      throw Exception('El nombre no puede superar los 150 caracteres.');
    }

    final String descripcionLimpia = descripcion?.trim() ?? '';

    if (descripcionLimpia.length > 1000) {
      throw Exception('La descripción no puede superar los 1000 caracteres.');
    }

    final String colorLimpio = color?.trim() ?? '';

    if (colorLimpio.length > 30) {
      throw Exception('El color no puede superar los 30 caracteres.');
    }

    final String iconoLimpio = icono?.trim() ?? '';

    if (iconoLimpio.length > 100) {
      throw Exception('El icono no puede superar los 100 caracteres.');
    }

    if (orden <= 0) {
      throw Exception('El orden debe ser mayor que cero.');
    }

    if (orden > 999) {
      throw Exception('El orden no puede superar 999.');
    }
  }

  /// Extrae el objeto enviado por el backend.
  Map<String, dynamic> _extraerObjeto(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic contenido =
          data['data'] ??
          data['result'] ??
          data['value'] ??
          data['categoria'] ??
          data['categoriaPeligro'];

      if (contenido is Map<String, dynamic>) {
        return contenido;
      }

      if (contenido is Map) {
        return Map<String, dynamic>.from(contenido);
      }

      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  /// Obtiene los mensajes enviados por ASP.NET.
  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic errores = mapa['errors'];

      if (errores is Map) {
        final List<String> mensajes = <String>[];

        errores.forEach((dynamic campo, dynamic valor) {
          if (valor is List) {
            for (final dynamic mensaje in valor) {
              final String texto = mensaje?.toString().trim() ?? '';

              if (texto.isNotEmpty) {
                mensajes.add(texto);
              }
            }

            return;
          }

          final String texto = valor?.toString().trim() ?? '';

          if (texto.isNotEmpty) {
            mensajes.add(texto);
          }
        });

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }

      final List<dynamic> posiblesMensajes = <dynamic>[
        mapa['message'],
        mapa['mensaje'],
        mapa['detail'],
        mapa['error'],
        mapa['title'],
      ];

      for (final dynamic valor in posiblesMensajes) {
        final String texto = valor?.toString().trim() ?? '';

        if (texto.isNotEmpty) {
          return texto;
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Se agotó el tiempo para conectar con el servidor.';

      case DioExceptionType.sendTimeout:
        return 'Se agotó el tiempo para enviar la solicitud.';

      case DioExceptionType.receiveTimeout:
        return 'Se agotó el tiempo para recibir la respuesta.';

      case DioExceptionType.transformTimeout:
        return 'Se agotó el tiempo para procesar la respuesta.';

      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor. '
            'Verifica tu conexión y que la API esté ejecutándose.';

      case DioExceptionType.badCertificate:
        return 'El certificado del servidor no es válido.';

      case DioExceptionType.cancel:
        return 'La solicitud fue cancelada.';

      case DioExceptionType.badResponse:
        return _mensajePorCodigoHttp(
          error.response?.statusCode,
          mensajePredeterminado,
        );

      case DioExceptionType.unknown:
        return mensajePredeterminado;
    }
  }

  /// Genera un mensaje según el código HTTP.
  String _mensajePorCodigoHttp(int? codigo, String mensajePredeterminado) {
    switch (codigo) {
      case 400:
        return 'Los datos enviados no son válidos.';

      case 401:
        return 'La sesión no está autorizada.';

      case 403:
        return 'No tienes permiso para realizar esta acción.';

      case 404:
        return 'La categoría de peligro no fue encontrada.';

      case 405:
        return 'La operación no está permitida por el servidor.';

      case 409:
        return 'Ya existe una categoría con los mismos datos.';

      case 422:
        return 'Los datos enviados no pudieron ser procesados.';

      case 500:
        return 'El servidor presentó un error interno.';

      default:
        return mensajePredeterminado;
    }
  }

  /// Convierte una cadena vacía en null.
  String? _normalizarTexto(String? valor) {
    final String texto = valor?.trim() ?? '';

    return texto.isEmpty ? null : texto;
  }
}
