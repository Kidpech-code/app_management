import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get hasConnection async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<ConnectivityResult> get onStatusChange => _connectivity.onConnectivityChanged.map(
        (results) => results.firstWhere(
          (result) => result != ConnectivityResult.none,
          orElse: () => ConnectivityResult.none,
        ),
      );
}
