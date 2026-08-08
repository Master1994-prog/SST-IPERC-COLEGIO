import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/detalle_iperc_model.dart';

/// ===============================================================
/// DATASOURCE REMOTO - DETALLE IPERC
/// ===============================================================
///
/// Esta clase se encarga exclusivamente de comunicarse con
/// la API REST del backend para gestionar los detalles de
/// una Matriz IPERC.
///
/// Endpoints utilizados:
///
/// GET    /api/detalles-iperc
/// GET    /api/detalles-iperc/{id}
/// GET    /api/detalles-iperc/matriz/{matrizId}
/// POST   /api/detalles-iperc
/// PUT    /api/detalles-iperc/{id}
/// DELETE /api/detalles-iperc/{id}
///
/// No contiene lógica de interfaz.
/// No contiene widgets.
/// No contiene lógica de negocio visual.
/// ===============================================================
class DetalleIpercRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un ApiClient para pruebas.
  /// Si no se envía ninguno, utiliza la instancia global.
  DetalleIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP principal de la aplicación.
  final ApiClient _apiClient;

  // =============================================================
  // OBTENER TODOS
  // =============================================================

  /// Obtiene todos los detalles IPERC registrados.
  ///
  /// Endpoint:
  ///
  /// GET /api/detalles-iperc
  Future<List<DetalleIpercModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.detallesIpercEndpoint,
      );

      /// Convertimos la respuesta JSON del servidor
      /// en una lista de modelos Dart.
      return DetalleIpercModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar los detalles IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  /// Obtiene un detalle IPERC específico.
  ///
  /// Endpoint:
  ///
  /// GET /api/detalles-iperc/{id}
  Future<DetalleIpercModel> obtenerPorId(int id) async {
    /// Validamos antes de llamar a la API.
    if (id <= 0) {
      throw Exception('El identificador del detalle IPERC no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.detallesIpercEndpoint}/$id',
      );

      /// Extraemos el objeto aunque el backend lo envíe
      /// directamente o dentro de "data", "result", etc.
      final Map<String, dynamic> json = DetalleIpercModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un detalle IPERC inválido.');
      }

      return DetalleIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar el detalle IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // OBTENER DETALLES DE UNA MATRIZ
  // =============================================================

  /// Obtiene únicamente los detalles pertenecientes
  /// a una Matriz IPERC.
  ///
  /// Endpoint:
  ///
  /// GET /api/detalles-iperc/matriz/{matrizIpercId}
  Future<List<DetalleIpercModel>> obtenerPorMatriz(int matrizIpercId) async {
    if (matrizIpercId <= 0) {
      throw Exception('El identificador de la Matriz IPERC no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.detallesIpercEndpoint}/matriz/$matrizIpercId',
      );

      return DetalleIpercModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado:
              'No se pudieron cargar los detalles de la Matriz IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // CREAR DETALLE IPERC
  // =============================================================

  /// Registra un nuevo detalle dentro de una Matriz IPERC.
  ///
  /// Endpoint:
  ///
  /// POST /api/detalles-iperc
  ///
  /// IMPORTANTE:
  ///
  /// Flutter NO enviará EvaluacionInicialId.
  ///
  /// Enviará:
  ///
  /// - probabilidadInicialId
  /// - severidadInicialId
  ///
  /// y el backend calculará automáticamente:
  ///
  /// Riesgo = Probabilidad x Severidad
  ///
  /// También determinará automáticamente el NivelRiesgo.
  Future<DetalleIpercModel> crear({
    required int matrizIpercId,
    int item = 0,
    required String tarea,
    required int peligroId,
    required int consecuenciaId,
    String? descripcionPeligro,

    // Evaluación inicial.
    required int probabilidadInicialId,
    required int severidadInicialId,
    String? observacionesEvaluacionInicial,

    // Evaluación residual opcional.
    int? probabilidadResidualId,
    int? severidadResidualId,
    String? observacionesEvaluacionResidual,

    // Controles.
    List<int> controlIds = const <int>[],

    // EPP.
    List<int> equipoProteccionIds = const <int>[],

    // Implementación.
    int? responsableImplementacionId,
    DateTime? fechaCompromiso,
    DateTime? fechaImplementacion,
    int estadoImplementacion = 0,
  }) async {
    /// Validaciones básicas antes de llamar al servidor.
    _validarDatosPrincipales(
      matrizIpercId: matrizIpercId,
      tarea: tarea,
      peligroId: peligroId,
      consecuenciaId: consecuenciaId,
      probabilidadInicialId: probabilidadInicialId,
      severidadInicialId: severidadInicialId,
    );

    /// La evaluación residual debe estar completa.
    _validarEvaluacionResidual(
      probabilidadResidualId: probabilidadResidualId,
      severidadResidualId: severidadResidualId,
    );

    /// Estado válido:
    ///
    /// 0 Pendiente
    /// 1 EnProceso
    /// 2 Implementado
    /// 3 Verificado
    /// 4 Cerrado
    _validarEstadoImplementacion(estadoImplementacion);

    try {
      /// Construimos exactamente el JSON que espera
      /// CreateDetalleIPERCDto en el backend.
      final Map<String, dynamic> body = <String, dynamic>{
        'matrizIPERCId': matrizIpercId,

        /// Si se envía 0, el backend genera automáticamente
        /// el siguiente item de la matriz.
        'item': item,

        'tarea': tarea.trim(),

        'peligroId': peligroId,

        'consecuenciaId': consecuenciaId,

        'descripcionPeligro': _limpiarTextoNullable(descripcionPeligro),

        // =======================================================
        // EVALUACIÓN INICIAL
        // =======================================================
        'probabilidadInicialId': probabilidadInicialId,

        'severidadInicialId': severidadInicialId,

        'observacionesEvaluacionInicial': _limpiarTextoNullable(
          observacionesEvaluacionInicial,
        ),

        // =======================================================
        // EVALUACIÓN RESIDUAL
        // =======================================================
        'probabilidadResidualId': probabilidadResidualId,

        'severidadResidualId': severidadResidualId,

        'observacionesEvaluacionResidual': _limpiarTextoNullable(
          observacionesEvaluacionResidual,
        ),

        // =======================================================
        // CONTROLES
        // =======================================================
        'controlIds': _normalizarIds(controlIds),

        // =======================================================
        // EPP
        // =======================================================
        'equipoProteccionIds': _normalizarIds(equipoProteccionIds),

        // =======================================================
        // IMPLEMENTACIÓN
        // =======================================================
        'responsableImplementacionId': responsableImplementacionId,

        'fechaCompromiso': fechaCompromiso?.toIso8601String(),

        'fechaImplementacion': fechaImplementacion?.toIso8601String(),

        'estadoImplementacion': estadoImplementacion,
      };

      final Response<dynamic> response = await _apiClient.post(
        ApiConfig.detallesIpercEndpoint,
        data: body,
      );

      final Map<String, dynamic> json = DetalleIpercModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception(
          'El servidor registró el detalle, pero devolvió una respuesta inválida.',
        );
      }

      return DetalleIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo registrar el detalle IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // ACTUALIZAR DETALLE IPERC
  // =============================================================

  /// Actualiza un detalle IPERC existente.
  ///
  /// Endpoint:
  ///
  /// PUT /api/detalles-iperc/{id}
  ///
  /// El backend volverá a calcular la evaluación
  /// inicial y residual según los valores enviados.
  Future<String> actualizar({
    required int id,
    required int matrizIpercId,
    required int item,
    required String tarea,
    required int peligroId,
    required int consecuenciaId,
    String? descripcionPeligro,

    // Evaluación inicial.
    required int probabilidadInicialId,
    required int severidadInicialId,
    String? observacionesEvaluacionInicial,

    // Evaluación residual opcional.
    int? probabilidadResidualId,
    int? severidadResidualId,
    String? observacionesEvaluacionResidual,

    // Controles.
    List<int> controlIds = const <int>[],

    // EPP.
    List<int> equipoProteccionIds = const <int>[],

    // Implementación.
    int? responsableImplementacionId,
    DateTime? fechaCompromiso,
    DateTime? fechaImplementacion,
    int estadoImplementacion = 0,
  }) async {
    if (id <= 0) {
      throw Exception('El identificador del detalle IPERC no es válido.');
    }

    _validarDatosPrincipales(
      matrizIpercId: matrizIpercId,
      tarea: tarea,
      peligroId: peligroId,
      consecuenciaId: consecuenciaId,
      probabilidadInicialId: probabilidadInicialId,
      severidadInicialId: severidadInicialId,
    );

    _validarEvaluacionResidual(
      probabilidadResidualId: probabilidadResidualId,
      severidadResidualId: severidadResidualId,
    );

    _validarEstadoImplementacion(estadoImplementacion);

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'matrizIPERCId': matrizIpercId,
        'item': item,
        'tarea': tarea.trim(),

        'peligroId': peligroId,

        'consecuenciaId': consecuenciaId,

        'descripcionPeligro': _limpiarTextoNullable(descripcionPeligro),

        // Evaluación inicial.
        'probabilidadInicialId': probabilidadInicialId,

        'severidadInicialId': severidadInicialId,

        'observacionesEvaluacionInicial': _limpiarTextoNullable(
          observacionesEvaluacionInicial,
        ),

        // Evaluación residual.
        'probabilidadResidualId': probabilidadResidualId,

        'severidadResidualId': severidadResidualId,

        'observacionesEvaluacionResidual': _limpiarTextoNullable(
          observacionesEvaluacionResidual,
        ),

        // Controles.
        'controlIds': _normalizarIds(controlIds),

        // EPP.
        'equipoProteccionIds': _normalizarIds(equipoProteccionIds),

        // Responsable y fechas.
        'responsableImplementacionId': responsableImplementacionId,

        'fechaCompromiso': fechaCompromiso?.toIso8601String(),

        'fechaImplementacion': fechaImplementacion?.toIso8601String(),

        'estadoImplementacion': estadoImplementacion,
      };

      final Response<dynamic> response = await _apiClient.put(
        '${ApiConfig.detallesIpercEndpoint}/$id',
        data: body,
      );

      /// El controlador actual devuelve:
      ///
      /// {
      ///   "mensaje": "Detalle IPERC actualizado correctamente."
      /// }
      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Detalle IPERC actualizado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo actualizar el detalle IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // CERRAR DETALLE IPERC
  // =============================================================

  /// Cierra un detalle IPERC.
  ///
  /// Endpoint:
  ///
  /// DELETE /api/detalles-iperc/{id}
  ///
  /// IMPORTANTE:
  ///
  /// Según tu backend actual, DELETE NO elimina físicamente
  /// el registro.
  ///
  /// El servicio cambia:
  ///
  /// EstadoImplementacion = Cerrado
  ///
  /// por lo tanto conservamos toda la información histórica.
  Future<String> cerrar(int id) async {
    if (id <= 0) {
      throw Exception('El identificador del detalle IPERC no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.delete(
        '${ApiConfig.detallesIpercEndpoint}/$id',
      );

      return _extraerMensaje(
        response.data,
        mensajePredeterminado: 'Detalle IPERC cerrado correctamente.',
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cerrar el detalle IPERC.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // VALIDACIONES LOCALES
  // =============================================================

  /// Valida los campos fundamentales antes de enviar
  /// información al servidor.
  void _validarDatosPrincipales({
    required int matrizIpercId,
    required String tarea,
    required int peligroId,
    required int consecuenciaId,
    required int probabilidadInicialId,
    required int severidadInicialId,
  }) {
    if (matrizIpercId <= 0) {
      throw Exception('Debe seleccionar una Matriz IPERC válida.');
    }

    if (tarea.trim().length < 2) {
      throw Exception('La tarea debe tener al menos 2 caracteres.');
    }

    if (peligroId <= 0) {
      throw Exception('Debe seleccionar un peligro.');
    }

    if (consecuenciaId <= 0) {
      throw Exception('Debe seleccionar una consecuencia.');
    }

    if (probabilidadInicialId <= 0) {
      throw Exception('Debe seleccionar la probabilidad inicial.');
    }

    if (severidadInicialId <= 0) {
      throw Exception('Debe seleccionar la severidad inicial.');
    }
  }

  /// Comprueba que la evaluación residual se complete
  /// correctamente.
  ///
  /// No permitimos:
  ///
  /// Probabilidad residual = seleccionada
  /// Severidad residual = null
  ///
  /// ni al contrario.
  void _validarEvaluacionResidual({
    required int? probabilidadResidualId,
    required int? severidadResidualId,
  }) {
    final bool tieneProbabilidad =
        probabilidadResidualId != null && probabilidadResidualId > 0;

    final bool tieneSeveridad =
        severidadResidualId != null && severidadResidualId > 0;

    if (tieneProbabilidad != tieneSeveridad) {
      throw Exception(
        'Para realizar la evaluación residual debe seleccionar probabilidad y severidad.',
      );
    }
  }

  /// Valida el enum EstadoImplementacion utilizado
  /// por el backend.
  void _validarEstadoImplementacion(int estado) {
    if (estado < 0 || estado > 4) {
      throw Exception('El estado de implementación no es válido.');
    }
  }

  // =============================================================
  // UTILIDADES
  // =============================================================

  /// Elimina IDs inválidos y duplicados.
  ///
  /// Ejemplo:
  ///
  /// [1, 1, 2, 0, -1]
  ///
  /// se convierte en:
  ///
  /// [1, 2]
  List<int> _normalizarIds(Iterable<int> ids) {
    return ids.where((int id) => id > 0).toSet().toList();
  }

  /// Limpia texto opcional.
  ///
  /// Si llega vacío, devuelve null.
  String? _limpiarTextoNullable(String? texto) {
    final String valor = texto?.trim() ?? '';

    return valor.isEmpty ? null : valor;
  }

  /// Extrae el mensaje enviado por el backend.
  String _extraerMensaje(
    dynamic data, {
    required String mensajePredeterminado,
  }) {
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje = mapa['mensaje'] ?? mapa['message'];

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
  // MANEJO DE ERRORES DE DIO
  // =============================================================

  /// Intenta obtener un mensaje entendible a partir
  /// de los diferentes errores devueltos por ASP.NET.
  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    final dynamic data = error.response?.data;

    // -----------------------------------------------------------
    // RESPUESTA JSON
    // -----------------------------------------------------------

    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      /// Errores comunes enviados manualmente
      /// por nuestros controladores.
      final dynamic mensaje =
          mapa['mensaje'] ??
          mapa['message'] ??
          mapa['detail'] ??
          mapa['error'] ??
          mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      // ---------------------------------------------------------
      // ERRORES DE VALIDACIÓN ASP.NET
      // ---------------------------------------------------------

      /// ASP.NET puede devolver:
      ///
      /// {
      ///   "errors": {
      ///      "Tarea": [
      ///        "La tarea es obligatoria."
      ///      ]
      ///   }
      /// }
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

    // -----------------------------------------------------------
    // RESPUESTA EN TEXTO
    // -----------------------------------------------------------

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    // -----------------------------------------------------------
    // ERRORES POR TIPO
    // -----------------------------------------------------------

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Se agotó el tiempo de conexión con el servidor.',

      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. '
            'Verifica que la API esté ejecutándose.',

      DioExceptionType.badResponse when error.response?.statusCode == 400 =>
        'Los datos enviados para el detalle IPERC no son válidos.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para realizar esta operación.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró el detalle IPERC solicitado.',

      DioExceptionType.badResponse when error.response?.statusCode == 409 =>
        'Existe un conflicto con los datos del detalle IPERC.',

      DioExceptionType.badResponse
          when error.response?.statusCode != null &&
              error.response!.statusCode! >= 500 =>
        'El servidor presentó un error al procesar el detalle IPERC.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => mensajePredeterminado,
    };
  }

  /// Elimina prefijos innecesarios cuando capturamos
  /// una Exception estándar de Dart.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
