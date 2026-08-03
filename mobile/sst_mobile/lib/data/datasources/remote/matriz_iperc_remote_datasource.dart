import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/matriz_iperc_model.dart';

class MatrizIpercRemoteDatasource {
  MatrizIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

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

  Future<MatrizIpercModel> obtenerMatrizPorId(int id) async {
    final Response<dynamic> response = await _apiClient.get(
      '${ApiConfig.matricesIpercEndpoint}/$id',
    );

    if (response.data is! Map) {
      throw const FormatException(
        'El servidor no devolvió una matriz IPERC válida.',
      );
    }

    return MatrizIpercModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

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
      'El servidor respondió ${response.statusCode}, pero no devolvió el ID.',
    );
  }

  // Actualiza una matriz existente mediante PUT.
  Future<MatrizIpercModel> actualizar(int id, Map<String, dynamic> data) async {
    if (id <= 0) {
      throw ArgumentError('El identificador de la matriz no es válido.');
    }

    final Response<dynamic> response = await _apiClient.put(
      '${ApiConfig.matricesIpercEndpoint}/$id',
      data: data,
    );

    // Si el backend devuelve la matriz actualizada, se utiliza directamente.
    if (response.data is Map) {
      final Map<String, dynamic> contenido = Map<String, dynamic>.from(
        response.data as Map,
      );

      final dynamic dataInterna = contenido['data'];

      if (dataInterna is Map) {
        return MatrizIpercModel.fromJson(
          Map<String, dynamic>.from(dataInterna),
        );
      }

      final bool contieneMatriz =
          contenido.containsKey('id') ||
          contenido.containsKey('Id') ||
          contenido.containsKey('codigo') ||
          contenido.containsKey('Codigo');

      if (contieneMatriz) {
        return MatrizIpercModel.fromJson(contenido);
      }
    }

    // Si el PUT devuelve 204 o solo un mensaje, consulta nuevamente la matriz.
    return obtenerMatrizPorId(id);
  }

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

    dynamic id =
        respuesta['id'] ??
        respuesta['Id'] ??
        respuesta['matrizId'] ??
        respuesta['MatrizId'] ??
        respuesta['serverId'];

    final dynamic data = respuesta['data'];

    if (id == null && data is Map) {
      final Map<String, dynamic> dataInterna = Map<String, dynamic>.from(data);

      id =
          dataInterna['id'] ??
          dataInterna['Id'] ??
          dataInterna['matrizId'] ??
          dataInterna['MatrizId'];
    }

    final String valor = id?.toString().trim() ?? '';

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
