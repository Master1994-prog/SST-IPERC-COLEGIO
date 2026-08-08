import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/probabilidad_model.dart';

/// ===============================================================
/// DATASOURCE REMOTO - PROBABILIDAD
/// ===============================================================
///
/// Esta clase se encarga de obtener desde la API
/// las probabilidades utilizadas en la evaluación IPERC.
///
/// El backend trabaja con valores de probabilidad entre 1 y 5.
///
/// Ejemplo:
///
/// 1 - Rara
/// 2 - Poco probable
/// 3 - Posible
/// 4 - Probable
/// 5 - Casi segura
///
/// Esta información será utilizada principalmente
/// en el formulario de Detalle IPERC.
/// ===============================================================
class ProbabilidadRemoteDatasource {
  /// Constructor.
  ///
  /// Permite inyectar un ApiClient para pruebas.
  /// Si no se proporciona uno, usa la instancia global.
  ProbabilidadRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Cliente HTTP de la aplicación.
  final ApiClient _apiClient;

  // =============================================================
  // OBTENER TODAS LAS PROBABILIDADES
  // =============================================================

  /// Obtiene todas las probabilidades registradas.
  ///
  /// Endpoint esperado:
  ///
  /// GET /api/Probabilidades
  Future<List<ProbabilidadModel>> obtenerTodas() async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        ApiConfig.probabilidadesEndpoint,
      );

      /// Convertimos la respuesta del servidor
      /// en una lista de ProbabilidadModel.
      final List<ProbabilidadModel> probabilidades =
          ProbabilidadModel.listaDesdeJson(response.data);

      /// Las ordenamos por su valor de 1 a 5
      /// para mostrarlas correctamente en Flutter.
      probabilidades.sort((ProbabilidadModel a, ProbabilidadModel b) {
        return a.valor.compareTo(b.valor);
      });

      return probabilidades;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudieron cargar las probabilidades.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // OBTENER POR ID
  // =============================================================

  /// Obtiene una probabilidad específica por su ID.
  ///
  /// Endpoint esperado:
  ///
  /// GET /api/Probabilidades/{id}
  Future<ProbabilidadModel> obtenerPorId(int id) async {
    if (id <= 0) {
      throw Exception('El identificador de la probabilidad no es válido.');
    }

    try {
      final Response<dynamic> response = await _apiClient.get(
        '${ApiConfig.probabilidadesEndpoint}/$id',
      );

      final Map<String, dynamic> json = ProbabilidadModel.objetoDesdeJson(
        response.data,
      );

      if (json.isEmpty) {
        throw Exception('El servidor devolvió una probabilidad inválida.');
      }

      return ProbabilidadModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          mensajePredeterminado: 'No se pudo cargar la probabilidad.',
        ),
      );
    } catch (error) {
      throw Exception(_limpiarMensaje(error));
    }
  }

  // =============================================================
  // MANEJO DE ERRORES
  // =============================================================

  /// Convierte los errores de Dio en mensajes
  /// comprensibles para el usuario.
  String _obtenerMensajeError(
    DioException error, {
    required String mensajePredeterminado,
  }) {
    final dynamic data = error.response?.data;

    /// Si el backend devuelve un objeto JSON.
    if (data is Map) {
      final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);

      final dynamic mensaje =
          mapa['mensaje'] ??
          mapa['message'] ??
          mapa['detail'] ??
          mapa['error'] ??
          mapa['title'];

      if (mensaje != null && mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString().trim();
      }

      /// ASP.NET puede devolver errores
      /// de validación dentro de "errors".
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

    /// Si el backend devuelve texto plano.
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    /// Manejo de errores según el tipo.
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Se agotó el tiempo de conexión con el servidor.',

      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. '
            'Verifica que la API esté ejecutándose.',

      DioExceptionType.badResponse when error.response?.statusCode == 400 =>
        'La solicitud de probabilidades no es válida.',

      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'La sesión venció. Inicia sesión nuevamente.',

      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        'No tienes permiso para consultar las probabilidades.',

      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'No se encontró la probabilidad solicitada.',

      DioExceptionType.badResponse
          when error.response?.statusCode != null &&
              error.response!.statusCode! >= 500 =>
        'El servidor presentó un error al consultar las probabilidades.',

      DioExceptionType.cancel => 'La solicitud fue cancelada.',

      _ => mensajePredeterminado,
    };
  }

  // =============================================================
  // LIMPIAR MENSAJE
  // =============================================================

  /// Elimina prefijos innecesarios de las excepciones.
  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
