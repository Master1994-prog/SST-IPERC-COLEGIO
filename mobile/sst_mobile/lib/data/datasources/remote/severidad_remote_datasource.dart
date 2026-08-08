import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/severidad_model.dart';

/// ===============================================================
/// DATASOURCE REMOTO - SEVERIDAD
/// ===============================================================
///
/// Esta clase se encarga de consultar desde la API
/// los niveles de severidad utilizados en la matriz IPERC.
///
/// El backend trabaja con severidades cuyo valor está
/// comprendido entre 1 y 5.
///
/// Esta información se utilizará en:
///
/// - Evaluación inicial.
/// - Evaluación residual.
/// - Formulario de Detalle IPERC.
/// - Matriz de riesgos 5x5.
/// ===============================================================
class SeveridadRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un ApiClient para pruebas.
  /// Si no se proporciona ninguno, utiliza la instancia global.
  SeveridadRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP principal de la aplicación.
  final ApiClient _apiClient;

  // =============================================================
  // OBTENER TODAS LAS SEVERIDADES
  // =============================================================

  /// Obtiene todas las severidades registradas.
  ///
  /// Endpoint esperado:
  ///
  /// GET /api/Severidades
  Future<List<SeveridadModel>> obtenerTodas() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.severidadesEndpoint,
      );

      /// Convertimos la respuesta JSON
      /// en una lista de SeveridadModel.
      final List<SeveridadModel> severidades = SeveridadModel.listaDesdeJson(
        response.data,
      );

      /// Las ordenamos por su valor numérico.
      ///
      /// El resultado esperado será:
      ///
      /// 1
      /// 2
      /// 3
      /// 4
      /// 5
      severidades.sort((SeveridadModel a, SeveridadModel b) {
        return a.valor.compareTo(b.valor);
      });

      return severidades;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar las severidades.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // OBTENER SEVERIDAD POR ID
  // =============================================================

  /// Obtiene una severidad específica
  /// mediante su identificador.
  ///
  /// Endpoint esperado:
  ///
  /// GET /api/Severidades/{id}
  Future<SeveridadModel> obtenerPorId(int id) async {
    /// Validación local antes de consultar
    /// al servidor.
    if (id <= 0) {
      throw Exception('El identificador de la severidad no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.severidadesEndpoint}/$id',
      );

      /// Extraemos el objeto aunque el backend
      /// lo devuelva directamente o dentro
      /// de una propiedad como "data".
      final Map<String, dynamic> json = SeveridadModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió una severidad inválida.');
      }

      return SeveridadModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar la severidad.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // MANEJO DE ERRORES HTTP
  // =============================================================

  /// Convierte los errores de Dio en mensajes
  /// entendibles para el usuario.
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

      /// Intentamos obtener mensajes enviados
      /// manualmente por ASP.NET.
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
    // TIPO DE ERROR
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
        'La solicitud de severidades no es válida.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para consultar las severidades.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró la severidad solicitada.',

      DioExceptionType.badResponse
          when error.response?.statusCode != null &&
              error.response!.statusCode! >= 500 =>
        'El servidor presentó un error al consultar las severidades.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => mensajePredeterminado,
    };
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  /// Elimina prefijos innecesarios
  /// de las excepciones de Dart.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
