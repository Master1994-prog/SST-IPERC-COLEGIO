import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../models/seguimiento_iperc_model.dart';

/// Comunica el módulo Seguimiento IPERC con la API.
class SeguimientoIpercRemoteDatasource {
  SeguimientoIpercRemoteDatasource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const String _endpoint = '/seguimientos-iperc';

  Future<List<SeguimientoIpercModel>> obtenerTodos() async {
    try {
      final Response<dynamic> response = await _apiClient.get(_endpoint);
      final List<SeguimientoIpercModel> seguimientos =
          SeguimientoIpercModel.listaDesdeJson(response.data)
            ..sort(_ordenarPorFechaDesc);

      return seguimientos;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los seguimientos IPERC.',
        ),
      );
    }
  }

  Future<List<SeguimientoIpercModel>> obtenerPorDetalle(
    int detalleIpercId,
  ) async {
    _validarId(detalleIpercId, 'detalle IPERC');

    try {
      final Response<dynamic> response = await _apiClient.get(
        '$_endpoint/detalle/$detalleIpercId',
      );
      final List<SeguimientoIpercModel> seguimientos =
          SeguimientoIpercModel.listaDesdeJson(response.data)
            ..sort(_ordenarPorFechaDesc);

      return seguimientos;
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudieron cargar los seguimientos del detalle.',
        ),
      );
    }
  }

  Future<SeguimientoIpercModel> obtenerPorId(int id) async {
    _validarId(id, 'seguimiento IPERC');

    try {
      final Response<dynamic> response = await _apiClient.get('$_endpoint/$id');
      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception('El servidor devolvió un seguimiento inválido.');
      }

      return SeguimientoIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo obtener el seguimiento IPERC.',
        ),
      );
    }
  }

  Future<SeguimientoIpercModel> crear(
    CrearSeguimientoIpercRequest request,
  ) async {
    _validarDatos(
      detalleIpercId: request.detalleIpercId,
      usuarioId: request.usuarioId,
      descripcion: request.descripcion,
      porcentajeAvance: request.porcentajeAvance,
    );

    try {
      final Response<dynamic> response = await _apiClient.post(
        _endpoint,
        data: request.toJson(),
      );
      final Map<String, dynamic> json = _extraerObjeto(response.data);

      if (json.isEmpty) {
        throw Exception(
          'El seguimiento fue registrado, pero el servidor no devolvió datos.',
        );
      }

      return SeguimientoIpercModel.fromJson(json);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo registrar el seguimiento IPERC.',
        ),
      );
    }
  }

  Future<SeguimientoIpercModel> actualizar(
    int id,
    ActualizarSeguimientoIpercRequest request,
  ) async {
    _validarId(id, 'seguimiento IPERC');
    _validarDatos(
      detalleIpercId: request.detalleIpercId,
      usuarioId: request.usuarioId,
      descripcion: request.descripcion,
      porcentajeAvance: request.porcentajeAvance,
    );

    try {
      await _apiClient.put('$_endpoint/$id', data: request.toJson());
      return obtenerPorId(id);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo actualizar el seguimiento IPERC.',
        ),
      );
    }
  }

  Future<void> verificar(int id) async {
    _validarId(id, 'seguimiento IPERC');

    try {
      await _apiClient.patch('$_endpoint/$id/verificar');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo verificar el seguimiento IPERC.',
        ),
      );
    }
  }

  Future<void> eliminar(int id) async {
    _validarId(id, 'seguimiento IPERC');

    try {
      await _apiClient.delete('$_endpoint/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensaje(
          error,
          predeterminado: 'No se pudo eliminar el seguimiento IPERC.',
        ),
      );
    }
  }

  int _ordenarPorFechaDesc(SeguimientoIpercModel a, SeguimientoIpercModel b) {
    return b.fechaSeguimiento.compareTo(a.fechaSeguimiento);
  }

  void _validarDatos({
    required int detalleIpercId,
    required int usuarioId,
    required String descripcion,
    required double porcentajeAvance,
  }) {
    _validarId(detalleIpercId, 'detalle IPERC');
    _validarId(usuarioId, 'usuario responsable');

    if (descripcion.trim().isEmpty) {
      throw Exception('La descripción del seguimiento es obligatoria.');
    }

    if (porcentajeAvance < 0 || porcentajeAvance > 100) {
      throw Exception('El porcentaje de avance debe estar entre 0 y 100.');
    }
  }

  void _validarId(int id, String nombre) {
    if (id <= 0) {
      throw Exception('El identificador del $nombre no es válido.');
    }
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
        mapa['seguimiento'] ??
        mapa['seguimientoIPERC'] ??
        mapa['seguimientoIperc'];

    if (contenido is Map) {
      return Map<String, dynamic>.from(contenido);
    }

    return mapa;
  }

  String _obtenerMensaje(DioException error, {required String predeterminado}) {
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
