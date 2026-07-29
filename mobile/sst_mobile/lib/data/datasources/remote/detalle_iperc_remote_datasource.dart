import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../models/detalle_iperc_model.dart';

/// Comunica el módulo Detalle IPERC con la API.
class DetalleIpercRemoteDatasource {
  DetalleIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const String _endpoint = '/detalles-iperc';

  Future<List<DetalleIpercModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(_endpoint);
      return DetalleIpercModel.listaDesdeJson(response.data);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los detalles IPERC.',
        ),
      );
    }
  }

  Future<List<DetalleIpercModel>> obtenerPorMatriz(int matrizIpercId) async {
    _validarId(matrizIpercId, 'matriz IPERC');

    try {
      final Response<dynamic> response = await _apiClient.get(
        '$_endpoint/matriz/$matrizIpercId',
      );
      final List<DetalleIpercModel> detalles =
          DetalleIpercModel.listaDesdeJson(response.data)
            ..sort(
              (DetalleIpercModel a, DetalleIpercModel b) =>
                  a.item.compareTo(b.item),
            );

      return detalles;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los peligros de la matriz.',
        ),
      );
    }
  }

  Future<DetalleIpercModel> obtenerPorId(int id) async {
    _validarId(id, 'detalle IPERC');

    try {
      final Response<dynamic> response = await _apiClient.get('$_endpoint/$id');
      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un detalle IPERC inválido.');
      }

      return DetalleIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo obtener el detalle IPERC.',
        ),
      );
    }
  }

  Future<DetalleIpercModel> crear(CrearDetalleIpercRequest request) async {
    _validarDatos(
      matrizIpercId: request.matrizIpercId,
      item: request.item,
      tarea: request.tarea,
      peligroId: request.peligroId,
      consecuenciaId: request.consecuenciaId,
      evaluacionInicialId: request.evaluacionInicialId,
    );

    try {
      final Response<dynamic> response = await _apiClient.post(
        _endpoint,
        data: request.toJson(),
      );
      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception(
          'El detalle fue registrado, pero el servidor no devolvió sus datos.',
        );
      }

      return DetalleIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo registrar el detalle IPERC.',
        ),
      );
    }
  }

  Future<DetalleIpercModel> actualizar(
    int id,
    ActualizarDetalleIpercRequest request,
  ) async {
    _validarId(id, 'detalle IPERC');
    _validarDatos(
      matrizIpercId: request.matrizIpercId,
      item: request.item,
      tarea: request.tarea,
      peligroId: request.peligroId,
      consecuenciaId: request.consecuenciaId,
      evaluacionInicialId: request.evaluacionInicialId,
    );

    try {
      await _apiClient.put('$_endpoint/$id', data: request.toJson());
      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo actualizar el detalle IPERC.',
        ),
      );
    }
  }

  Future<void> eliminar(int id) async {
    _validarId(id, 'detalle IPERC');

    try {
      await _apiClient.delete('$_endpoint/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo eliminar el detalle IPERC.',
        ),
      );
    }
  }

  void _validarId(int id, String nombre) {
    if (id <= 0) {
      throw Exception('El identificador del $nombre no es válido.');
    }
  }

  void _validarDatos({
    required int matrizIpercId,
    required int item,
    required String tarea,
    required int peligroId,
    required int consecuenciaId,
    required int evaluacionInicialId,
  }) {
    _validarId(matrizIpercId, 'matriz IPERC');

    if (item <= 0) {
      throw Exception('El ítem del detalle IPERC no es válido.');
    }

    if (tarea.trim().isEmpty) {
      throw Exception('La tarea es obligatoria.');
    }

    _validarId(peligroId, 'peligro');
    _validarId(consecuenciaId, 'consecuencia');
    _validarId(evaluacionInicialId, 'evaluación inicial');
  }

  Map<String, dynamic> _extraerObjeto(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> mapa = Map<String, dynamic>.from(data);
    final dynamic contenido =
        mapa['data'] ??
        mapa['result'] ??
        mapa['value'] ??
        mapa['detalle'] ??
        mapa['detalleIPERC'] ??
        mapa['detalleIperc'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  String _obtenerMensaje(
    DioException error, {
    required String predeterminado,
  }) {
    final dynamic data = error.response?.data;

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
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Se agotó el tiempo de conexión con el servidor.',
      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. Verifica la API y tu conexión.',
      DioExceptionType.badCertificate =>
        'El certificado del servidor no es válido.',
      DioExceptionType.cancel => 'La solicitud fue cancelada.',
      _ => predeterminado,
    };
  }
}
