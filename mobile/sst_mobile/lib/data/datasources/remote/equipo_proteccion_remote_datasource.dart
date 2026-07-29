import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/equipo_proteccion_model.dart';

/// Fuente remota del módulo Equipos de Protección Personal.
///
/// Se encarga de:
///
/// - Listar equipos de protección.
/// - Consultar equipos por ID.
/// - Registrar equipos.
/// - Actualizar equipos.
/// - Eliminar o desactivar equipos.
/// - Buscar equipos.
/// - Procesar errores enviados por ASP.NET Core.
class EquipoProteccionRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un cliente personalizado durante las pruebas.
  EquipoProteccionRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP principal de la aplicación.
  final ApiClient _apiClient;

  /// Obtiene todos los equipos de protección registrados.
  Future<List<EquipoProteccionModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.equiposProteccionEndpoint,
      );

      return EquipoProteccionModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar los equipos de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Obtiene únicamente los equipos activos.
  Future<List<EquipoProteccionModel>> obtenerActivos() async {
    final List<EquipoProteccionModel> equipos = await obtenerTodos();

    return equipos
        .where((EquipoProteccionModel equipo) => equipo.estaDisponible)
        .toList();
  }

  /// Obtiene un equipo por su identificador.
  Future<EquipoProteccionModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception(
        'El identificador del equipo de protección no es válido.',
      );
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.equiposProteccionEndpoint}/$id',
      );

      if (!_esObjetoEquipoProteccion(response.data)) {
        throw Exception(
          'El servidor devolvió un equipo de protección inválido.',
        );
      }

      return EquipoProteccionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Registra un nuevo equipo de protección.
  Future<EquipoProteccionModel> crear(
    CrearEquipoProteccionRequest request,
  ) async {
    _validarCrearRequest(request);

    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.equiposProteccionEndpoint,
        data: request.toJson(),
      );

      /*
       * El controlador normalmente responde con
       * el objeto creado mediante CreatedAtAction.
       */
      if (_esObjetoEquipoProteccion(response.data)) {
        return EquipoProteccionModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      /*
       * Como respaldo, se intenta recuperar el ID
       * desde el encabezado HTTP Location.
       */
      final int? idCreado = _obtenerIdDesdeLocation(
        response.headers.value('location'),
      );

      if (idCreado != null) {
        return obtenerPorId(idCreado);
      }

      throw Exception(
        'El equipo de protección fue registrado, '
        'pero el servidor no devolvió sus datos.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo registrar el equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Actualiza un equipo de protección existente.
  ///
  /// El endpoint PUT devuelve solamente un mensaje,
  /// por lo que después de actualizar se consulta
  /// nuevamente el equipo mediante su ID.
  Future<EquipoProteccionModel> actualizar(
    int id,
    ActualizarEquipoProteccionRequest request,
  ) async {
    if (id <= 0) {
      throw Exception(
        'El identificador del equipo de protección no es válido.',
      );
    }

    _validarActualizarRequest(request);

    try {
      await _apiClient.put(
        '${ApiConfig.equiposProteccionEndpoint}/$id',
        data: request.toJson(),
      );

      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudo actualizar el equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Elimina o desactiva un equipo de protección.
  Future<void> eliminar(int id) async {
    if (id <= 0) {
      throw Exception(
        'El identificador del equipo de protección no es válido.',
      );
    }

    try {
      await _apiClient.delete('${ApiConfig.equiposProteccionEndpoint}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo eliminar el equipo de protección.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  /// Busca equipos por código, nombre, descripción o tipo.
  Future<List<EquipoProteccionModel>> buscar(String texto) async {
    final String criterio = texto.trim().toLowerCase();

    final List<EquipoProteccionModel> equipos = await obtenerTodos();

    if (criterio.isEmpty) {
      return equipos;
    }

    return equipos.where((EquipoProteccionModel equipo) {
      return equipo.codigo.toLowerCase().contains(criterio) ||
          equipo.nombre.toLowerCase().contains(criterio) ||
          equipo.descripcionVisible.toLowerCase().contains(criterio) ||
          equipo.tipoVisible.toLowerCase().contains(criterio);
    }).toList();
  }

  /// Verifica que una respuesta corresponda realmente
  /// a un objeto EquipoProteccion y no solo a un mensaje.
  bool _esObjetoEquipoProteccion(dynamic data) {
    if (data is! Map) {
      return false;
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

    return mapa.containsKey('id') && mapa.containsKey('nombre');
  }

  /// Valida los datos antes de registrar un EPP.
  void _validarCrearRequest(CrearEquipoProteccionRequest request) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
    _validarTipoEquipo(request.tipoEquipoProteccionId);
    _validarMarca(request.marca);
    _validarModelo(request.modelo);
    _validarNormaTecnica(request.normaTecnica);
    _validarVidaUtil(request.vidaUtilMeses);
    _validarCatalogoYColegio(
      esGlobal: request.esGlobal,
      colegioId: request.colegioId,
    );
  }

  /// Valida los datos antes de actualizar un EPP.
  ///
  /// Esta validación coincide con
  /// UpdateEquipoProteccionDto del backend.
  void _validarActualizarRequest(ActualizarEquipoProteccionRequest request) {
    _validarCodigo(request.codigo);
    _validarNombre(request.nombre);
    _validarDescripcion(request.descripcion);
    _validarTipoEquipo(request.tipoEquipoProteccionId);
    _validarMarca(request.marca);
    _validarModelo(request.modelo);
    _validarNormaTecnica(request.normaTecnica);
    _validarVidaUtil(request.vidaUtilMeses);
    _validarCatalogoYColegio(
      esGlobal: request.esGlobal,
      colegioId: request.colegioId,
    );
  }

  /// Valida el código.
  void _validarCodigo(String codigo) {
    final String valor = codigo.trim();

    if (valor.isEmpty) {
      throw Exception('El código del equipo de protección es obligatorio.');
    }

    if (valor.length > 20) {
      throw Exception('El código no puede superar los 20 caracteres.');
    }
  }

  /// Valida el nombre.
  void _validarNombre(String nombre) {
    final String valor = nombre.trim();

    if (valor.length < 3) {
      throw Exception(
        'El nombre del equipo debe contener '
        'al menos 3 caracteres.',
      );
    }

    if (valor.length > 200) {
      throw Exception(
        'El nombre del equipo no puede superar '
        'los 200 caracteres.',
      );
    }
  }

  /// Valida la descripción.
  void _validarDescripcion(String? descripcion) {
    final String valor = descripcion?.trim() ?? '';

    if (valor.length > 2000) {
      throw Exception(
        'La descripción no puede superar '
        'los 2000 caracteres.',
      );
    }
  }

  /// Valida el tipo de equipo.
  void _validarTipoEquipo(int tipoEquipoProteccionId) {
    if (tipoEquipoProteccionId <= 0) {
      throw Exception('El tipo de equipo de protección no es válido.');
    }
  }

  /// Valida la marca.
  void _validarMarca(String? marca) {
    final String valor = marca?.trim() ?? '';

    if (valor.length > 100) {
      throw Exception('La marca no puede superar los 100 caracteres.');
    }
  }

  /// Valida el modelo.
  void _validarModelo(String? modelo) {
    final String valor = modelo?.trim() ?? '';

    if (valor.length > 100) {
      throw Exception('El modelo no puede superar los 100 caracteres.');
    }
  }

  /// Valida la norma técnica.
  void _validarNormaTecnica(String? normaTecnica) {
    final String valor = normaTecnica?.trim() ?? '';

    if (valor.length > 300) {
      throw Exception(
        'La norma técnica no puede superar '
        'los 300 caracteres.',
      );
    }
  }

  /// Valida la vida útil.
  void _validarVidaUtil(int? vidaUtilMeses) {
    if (vidaUtilMeses != null && vidaUtilMeses <= 0) {
      throw Exception('La vida útil debe ser mayor que cero.');
    }
  }

  /// Valida la relación entre catálogo global
  /// y colegio propietario.
  void _validarCatalogoYColegio({
    required bool esGlobal,
    required int? colegioId,
  }) {
    if (!esGlobal && (colegioId == null || colegioId <= 0)) {
      throw Exception('Selecciona el colegio propietario del equipo.');
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

  /// Traduce los códigos HTTP.
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
        return 'El equipo de protección solicitado '
            'no existe o la ruta no está disponible.';

      case 409:
        return 'Ya existe un equipo de protección '
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

  /// Obtiene el ID desde el encabezado Location.
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
