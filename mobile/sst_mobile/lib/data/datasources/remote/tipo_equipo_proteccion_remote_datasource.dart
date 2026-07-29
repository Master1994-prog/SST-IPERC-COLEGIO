import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/tipo_equipo_proteccion_model.dart';

/// Fuente remota del catálogo Tipos de Equipo de Protección.
///
/// Se encarga de comunicarse con el backend para:
///
/// - Listar tipos de EPP.
/// - Consultar un tipo por ID.
/// - Registrar tipos.
/// - Actualizar tipos.
/// - Eliminar o desactivar tipos.
/// - Buscar tipos por código, nombre o descripción.
class TipoEquipoProteccionRemoteDatasource {
  /// Permite utilizar el cliente principal de la aplicación
  /// o inyectar uno diferente para pruebas.
  TipoEquipoProteccionRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP utilizado para realizar las solicitudes.
  final ApiClient _apiClient;

  /// Obtiene todos los tipos de equipos de protección.
  Future<List<TipoEquipoProteccionModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.tiposEquipoProteccionEndpoint,
      );

      return TipoEquipoProteccionModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar los tipos de equipos de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene solamente los tipos activos y disponibles.
  Future<List<TipoEquipoProteccionModel>> obtenerActivos() async {
    final List<TipoEquipoProteccionModel> tipos = await obtenerTodos();

    return tipos
        .where((TipoEquipoProteccionModel tipo) => tipo.estaDisponible)
        .toList();
  }

  /// Obtiene un tipo de EPP por su identificador.
  Future<TipoEquipoProteccionModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de EPP no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.tiposEquipoProteccionEndpoint}/$id',
      );

      if (response.data is! Map) {
        throw Exception('El servidor devolvió un tipo de EPP inválido.');
      }

      return TipoEquipoProteccionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo cargar el tipo de equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo tipo de equipo de protección.
  Future<TipoEquipoProteccionModel> crear(
    CrearTipoEquipoProteccionRequest request,
  ) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.tiposEquipoProteccionEndpoint,
        data: request.toJson(),
      );

      /*
       * Cuando el controlador devuelve el objeto creado,
       * se convierte directamente al modelo.
       */
      if (_esObjetoTipoEquipo(response.data)) {
        return TipoEquipoProteccionModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      /*
       * Cuando el backend responde 201 Created sin devolver
       * el objeto, se intenta recuperar el ID desde Location.
       */
      final int? idCreado = _obtenerIdDesdeLocation(
        response.headers.value('location'),
      );

      if (idCreado != null) {
        return obtenerPorId(idCreado);
      }

      throw Exception(
        'El tipo de equipo fue registrado, '
        'pero el servidor no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo registrar el tipo de equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un tipo de EPP existente.
  Future<TipoEquipoProteccionModel> actualizar(
    int id,
    ActualizarTipoEquipoProteccionRequest request,
  ) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de EPP no es válido.');
    }

    _validarActualizarRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.tiposEquipoProteccionEndpoint}/$id',
        data: request.toJson(),
      );

      /*
       * Algunos controladores devuelven el objeto actualizado.
       */
      if (_esObjetoTipoEquipo(response.data)) {
        return TipoEquipoProteccionModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      /*
       * Si el backend devuelve solamente un mensaje,
       * se consulta nuevamente el registro actualizado.
       */
      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo actualizar el tipo de equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva un tipo de EPP.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del tipo de EPP no es válido.');
    }

    try {
      await _apiClient.delete('${ApiConfig.tiposEquipoProteccionEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo eliminar el tipo de equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Busca tipos de EPP por:
  ///
  /// - Código.
  /// - Nombre.
  /// - Descripción.
  Future<List<TipoEquipoProteccionModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<TipoEquipoProteccionModel> tipos = await obtenerTodos();

    if (criterio.isEmpty) {
      return tipos;
    }

    return tipos.where((TipoEquipoProteccionModel tipo) {
      return tipo.codigo.toLowerCase().contains(criterio) ||
          tipo.nombre.toLowerCase().contains(criterio) ||
          tipo.descripcionVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Comprueba que una respuesta Map corresponda realmente
  /// a un tipo de equipo y no solamente a un mensaje.
  bool _esObjetoTipoEquipo(dynamic data) {
    if (data is! Map) {
      return false;
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    return mapa.containsKey('id') && mapa.containsKey('nombre');
  }

  /// Valida los datos antes de registrar
  /// un nuevo tipo de equipo de protección.
  void _validarCrearRequest(CrearTipoEquipoProteccionRequest request) {
    final String codigo = request.codigo.trim();

    if (codigo.isEmpty) {
      throw Exception('El código del tipo de EPP es obligatorio.');
    }

    if (codigo.length > 20) {
      throw Exception('El código no puede superar los 20 caracteres.');
    }

    final String nombre = request.nombre.trim();

    if (nombre.isEmpty) {
      throw Exception('El nombre del tipo de EPP es obligatorio.');
    }

    if (nombre.length < 3) {
      throw Exception('El nombre debe contener al menos 3 caracteres.');
    }

    if (nombre.length > 150) {
      throw Exception('El nombre no puede superar los 150 caracteres.');
    }

    final String descripcion = request.descripcion?.trim() ?? '';

    if (descripcion.length > 1000) {
      throw Exception('La descripción no puede superar los 1000 caracteres.');
    }

    if (request.orden < 0) {
      throw Exception('El orden no puede ser negativo.');
    }

    if (!request.esGlobal &&
        (request.colegioId == null || request.colegioId! <= 0)) {
      throw Exception('Selecciona un colegio propietario válido.');
    }
  }

  /// Valida los datos antes de actualizar
  /// un tipo de equipo de protección.
  void _validarActualizarRequest(
    ActualizarTipoEquipoProteccionRequest request,
  ) {
    final String codigo = request.codigo.trim();

    if (codigo.isEmpty) {
      throw Exception('El código del tipo de EPP es obligatorio.');
    }

    if (codigo.length > 20) {
      throw Exception('El código no puede superar los 20 caracteres.');
    }

    final String nombre = request.nombre.trim();

    if (nombre.isEmpty) {
      throw Exception('El nombre del tipo de EPP es obligatorio.');
    }

    if (nombre.length < 3) {
      throw Exception('El nombre debe contener al menos 3 caracteres.');
    }

    if (nombre.length > 150) {
      throw Exception('El nombre no puede superar los 150 caracteres.');
    }

    final String descripcion = request.descripcion?.trim() ?? '';

    if (descripcion.length > 1000) {
      throw Exception('La descripción no puede superar los 1000 caracteres.');
    }

    if (request.orden < 0) {
      throw Exception('El orden no puede ser negativo.');
    }

    if (!request.esGlobal &&
        (request.colegioId == null || request.colegioId! <= 0)) {
      throw Exception('Selecciona un colegio propietario válido.');
    }
  }

  /// Extrae mensajes enviados por el backend
  /// o genera mensajes según el tipo de error.
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
            mensajes.addAll(
              valor.map((dynamic elemento) => elemento.toString()),
            );
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

  /// Traduce códigos HTTP a mensajes entendibles.
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
        return 'No se encontró el tipo de equipo '
            'o el endpoint configurado.';

      case 409:
        return 'Ya existe un tipo de equipo '
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

  /// Obtiene un ID desde un encabezado Location.
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

  /// Limpia el prefijo Exception antes
  /// de mostrar el mensaje.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
