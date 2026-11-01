import 'package:pulse/core/error/result.dart';
import 'package:pulse/markets/models/markets_snapshot.dart';

/// Markets list and global summary access.
abstract class MarketsRepository {
  /// Cache-first load (10 min TTL).
  Future<Result<MarketsSnapshot>> loadMarkets();

  /// Bypass TTL; used for pull-to-refresh.
  Future<Result<MarketsSnapshot>> refreshMarkets();
}
