import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Listen to network changes – used by SyncController
  static Stream<bool> get onConnectivityChange {
    return Connectivity().onConnectivityChanged.map(
      (results) => results.any((result) => result != ConnectivityResult.none),
    );
  }
}