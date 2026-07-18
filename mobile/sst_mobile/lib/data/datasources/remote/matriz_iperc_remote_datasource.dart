import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/matriz_iperc_model.dart';

class MatrizIpercRemoteDatasource {
  MatrizIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Obtiene las matrices registradas en el backend.
  Future<List<MatrizIpercModel>> obtenerMatrices() async {
    final Response<dynamic> response = await _apiClient.get(
      ApiConfig.matricesIpercEndpoint,
    );

    final List<dynamic> registros = _obtenerLista(response.data);

    return registros
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              MatrizIpercModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Crea una matriz y devuelve el Id generado
  /// por el backend.
  Future<String> create(Map<String, dynamic> data) async {
    final Response<dynamic> response = await _apiClient.post(
      ApiConfig.matricesIpercEndpoint,
      data: data,
    );

    final String? idRespuesta = _obtenerIdDesdeRespuesta(response.data);

    if (idRespuesta != null) {
      return idRespuesta;
    }

    final String? idLocation = _obtenerIdDesdeLocation(response);

    if (idLocation != null) {
      return idLocation;
    }

    throw FormatException(
      'El servidor respondió ${response.statusCode}, '
      'pero no devolvió el identificador de la matriz. '
      'Respuesta: ${response.data}',
    );
  }

  /// Permite interpretar diferentes formatos
  /// que podría devolver el backend.
  List<dynamic> _obtenerLista(dynamic contenido) {
    if (contenido is List) {
      return contenido;
    }

    if (contenido is Map) {
      final Map<String, dynamic> respuesta = Map<String, dynamic>.from(
        contenido,
      );

      final dynamic lista =
          respuesta['data'] ??
          respuesta['items'] ??
          respuesta['resultados'] ??
          respuesta['matrices'];

      if (lista is List) {
        return lista;
      }
    }

    return <dynamic>[];
  }

  String? _obtenerIdDesdeRespuesta(dynamic contenido) {
    if (contenido is! Map) {
      return null;
    }

    final Map<String, dynamic> respuesta = Map<String, dynamic>.from(contenido);

    final dynamic contenidoData = respuesta['data'];

    dynamic id =
        respuesta['id'] ??
        respuesta['Id'] ??
        respuesta['matrizId'] ??
        respuesta['MatrizId'] ??
        respuesta['serverId'];

    if (id == null && contenidoData is Map) {
      final Map<String, dynamic> dataInterna = Map<String, dynamic>.from(
        contenidoData,
      );

      id =
          dataInterna['id'] ??
          dataInterna['Id'] ??
          dataInterna['matrizId'] ??
          dataInterna['MatrizId'];
    }

    if (id == null) {
      return null;
    }

    final String valor = id.toString().trim();

    return valor.isEmpty ? null : valor;
  }

  String? _obtenerIdDesdeLocation(Response<dynamic> response) {
    final String? location = response.headers.value('location');

    if (location == null || location.trim().isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(location);

    if (uri == null || uri.pathSegments.isEmpty) {
      return null;
    }

    final String id = uri.pathSegments.last.trim();

    return id.isEmpty ? null : id;
  }
}
