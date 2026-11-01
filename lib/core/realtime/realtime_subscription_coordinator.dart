import 'package:pulse/core/realtime/price_stream_service.dart';

/// Merges feature subscription requests into one union for [PriceStreamService].
class RealtimeSubscriptionCoordinator {
  /// Creates a coordinator bound to [priceStreamService].
  RealtimeSubscriptionCoordinator(this._priceStreamService);

  final PriceStreamService _priceStreamService;
  final Map<String, Set<String>> _byToken = {};

  /// Registers [lowercaseBinanceSymbols] for [token] (e.g. `markets`, `watchlist`).
  void setSymbols(String token, Set<String> lowercaseBinanceSymbols) {
    _byToken[token] = Set<String>.from(lowercaseBinanceSymbols);
    _syncUnion();
  }

  /// Removes a feature token entirely.
  void removeToken(String token) {
    _byToken.remove(token);
    _syncUnion();
  }

  /// Current union across tokens (read-only, for tests).
  Set<String> get unionSymbols {
    final union = <String>{};
    for (final set in _byToken.values) {
      union.addAll(set);
    }
    return Set<String>.unmodifiable(union);
  }

  void _syncUnion() {
    final union = <String>{};
    for (final set in _byToken.values) {
      union.addAll(set);
    }
    _priceStreamService.setDesiredSymbols(union);
  }
}
