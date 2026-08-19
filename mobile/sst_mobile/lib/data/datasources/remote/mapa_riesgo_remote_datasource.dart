import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/mapa_riesgo_model.dart';

class MapaRiesgoRemoteDatasource {
  MapaRiesgoRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const String _endpoint = '/mapas-riesgo';

  Future<List<MapaRiesgoModel>> obtenerPorMatriz(int matrizIpercId) async {
    final response = await _apiClient.get('$_endpoint/matriz/$matrizIpercId');

    if (response.data is! List) return <MapaRiesgoModel>[];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(MapaRiesgoModel.fromJson)
        .toList(growable: false);
  }

  Future<MapaRiesgoModel> crear(MapaRiesgoModel model) async {
    final response = await _apiClient.post(
      _endpoint,
      data: model.toCreateJson(),
    );

    return MapaRiesgoModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> actualizar(MapaRiesgoModel model) async {
    await _apiClient.put('$_endpoint/${model.id}', data: model.toUpdateJson());
  }

  Future<Map<String, String>> subirPlano(String archivoPath) async {
    final archivo = File(archivoPath);

    if (!await archivo.exists()) {
      throw Exception('El archivo del plano no existe.');
    }

    final nombre = archivo.uri.pathSegments.isEmpty
        ? 'plano.jpg'
        : archivo.uri.pathSegments.last;

    final formData = FormData.fromMap(<String, dynamic>{
      'archivo': await MultipartFile.fromFile(archivo.path, filename: nombre),
    });

    final response = await _apiClient.dio.post(
      '$_endpoint/upload-plano',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final json = Map<String, dynamic>.from(response.data as Map);

    return <String, String>{
      'archivoUrl': json['archivoUrl']?.toString() ?? '',
      'tipoArchivo': json['tipoArchivo']?.toString() ?? '',
    };
  }

  String resolverUrlArchivo(String archivoUrl) {
    final String valor = archivoUrl.trim();

    if (valor.startsWith('http://') || valor.startsWith('https://')) {
      return valor;
    }

    final Uri apiUri = Uri.parse(ApiConfig.baseUrl);

    final String origin =
        '${apiUri.scheme}://${apiUri.host}'
        '${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    // El backend puede devolver:
    // /uploads/mapas-riesgo/archivo.png
    // uploads/mapas-riesgo/archivo.png
    // mapas/archivo.png
    //
    // Siempre garantizamos UN "/" entre host y ruta.
    final String ruta = valor.startsWith('/') ? valor : '/$valor';

    return '$origin$ruta';
  }
}
