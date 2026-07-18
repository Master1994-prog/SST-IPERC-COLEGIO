import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../models/catalogo_item_model.dart';

class CatalogosRemoteDatasource {
  CatalogosRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<CatalogoItemModel>> obtenerInstituciones() {
    return _obtenerCatalogo(ApiConfig.institucionesEndpoint);
  }

  Future<List<CatalogoItemModel>> obtenerSedes({required int institucionId}) {
    return _obtenerCatalogo(
      ApiConfig.sedesEndpoint,
      queryParameters: <String, dynamic>{'institucionId': institucionId},
    );
  }

  Future<List<CatalogoItemModel>> obtenerAreas({int? institucionId}) {
    return _obtenerCatalogo(
      ApiConfig.areasEndpoint,
      queryParameters: institucionId == null
          ? null
          : <String, dynamic>{'institucionId': institucionId},
    );
  }

  Future<List<CatalogoItemModel>> obtenerPuestosTrabajo({required int areaId}) {
    return _obtenerCatalogo(
      ApiConfig.puestosTrabajoEndpoint,
      queryParameters: <String, dynamic>{'areaId': areaId},
    );
  }

  Future<List<CatalogoItemModel>> obtenerProcesos({int? areaId}) {
    return _obtenerCatalogo(
      ApiConfig.procesosEndpoint,
      queryParameters: areaId == null
          ? null
          : <String, dynamic>{'areaId': areaId},
    );
  }

  Future<List<CatalogoItemModel>> obtenerActividades() {
    return _obtenerCatalogo(ApiConfig.actividadesEndpoint);
  }

  Future<List<CatalogoItemModel>> _obtenerCatalogo(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response<dynamic> response = await _apiClient.get(
      endpoint,
      queryParameters: queryParameters,
    );

    final List<dynamic> registros = _extraerLista(response.data);

    return registros
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              CatalogoItemModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((CatalogoItemModel item) => item.id > 0)
        .toList();
  }

  List<dynamic> _extraerLista(dynamic contenido) {
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
          respuesta['instituciones'] ??
          respuesta['sedes'] ??
          respuesta['areas'] ??
          respuesta['puestosTrabajo'] ??
          respuesta['procesos'] ??
          respuesta['actividades'];

      if (lista is List) {
        return lista;
      }
    }

    return <dynamic>[];
  }
}
