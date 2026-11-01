import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pulse/core/connectivity/connectivity_service.dart';

/// [ConnectivityService] backed by `connectivity_plus`.
///
/// [ConnectivityService.isOnline] reflects link-layer connectivity (Wi‑Fi, mobile,
/// etc.), not a guaranteed route to the public internet or API reachability.
class ConnectivityPlusService implements ConnectivityService {
  /// Creates the service with an optional underlying plugin instance.
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any(_isConnectedResult);
  }

  bool _isConnectedResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.bluetooth ||
      ConnectivityResult.ethernet ||
      ConnectivityResult.mobile ||
      ConnectivityResult.vpn ||
      ConnectivityResult.wifi ||
      ConnectivityResult.other ||
      ConnectivityResult.satellite => true,
      ConnectivityResult.none => false,
    };
  }
}
