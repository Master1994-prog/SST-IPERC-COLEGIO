import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkInfo {
  NetworkInfo._();

  static final NetworkInfo instance = NetworkInfo._();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection = InternetConnection();

  Future<bool> get isConnected async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();

    final bool hasNetwork = results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );

    if (!hasNetwork) {
      return false;
    }

    return _internetConnection.hasInternetAccess;
  }

  Stream<bool> get connectionChanges {
    return _internetConnection.onStatusChange.map(
      (InternetStatus status) => status == InternetStatus.connected,
    );
  }
}
