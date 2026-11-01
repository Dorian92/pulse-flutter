/// Explicit online/offline signal for cache-first flows.
abstract class ConnectivityService {
  /// Whether the device currently has a usable network route.
  Future<bool> get isOnline;
}
