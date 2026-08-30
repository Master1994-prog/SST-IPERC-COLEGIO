import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/api_config.dart';

class NetworkInfo {
  NetworkInfo._();

  static final NetworkInfo instance = NetworkInfo._();

  final Connectivity _connectivity = Connectivity();

  static const Duration _backendTimeout = Duration(seconds: 3);
  static const Duration _pollInterval = Duration(seconds: 10);

  Future<bool> get isConnected async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();

    final bool existeRed = results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );

    if (!existeRed) {
      return false;
    }

    return _backendDisponible();
  }

  Stream<bool> get connectionChanges async* {
    bool? ultimoEstado;

    while (true) {
      final bool estadoActual = await isConnected;

      if (ultimoEstado == null || estadoActual != ultimoEstado) {
        ultimoEstado = estadoActual;
        yield estadoActual;
      }

      await Future<void>.delayed(_pollInterval);
    }
  }

  Future<bool> _backendDisponible() async {
    final Uri? uri = Uri.tryParse(ApiConfig.baseUrl);

    if (uri == null || uri.host.trim().isEmpty) {
      return false;
    }

    final int port = uri.hasPort
        ? uri.port
        : uri.scheme.toLowerCase() == 'https'
        ? 443
        : 80;

    Socket? socket;

    try {
      socket = await Socket.connect(uri.host, port, timeout: _backendTimeout);

      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
