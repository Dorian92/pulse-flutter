import 'package:equatable/equatable.dart';
import 'package:pulse/l10n/app_localizations.dart';

/// Typed failure for expected I/O and cache errors (no throws to UI).
sealed class AppFailure extends Equatable {
  const AppFailure();

  /// Maps this failure to a localized user-visible message.
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure(:final offline) =>
        offline ? l10n.errorOffline : l10n.errorNetwork,
      TimeoutFailure() => l10n.errorTimeout,
      RateLimitFailure(:final retryAfterSeconds) =>
        retryAfterSeconds != null
            ? l10n.errorRateLimitRetryAfter(retryAfterSeconds)
            : l10n.errorRateLimit,
      ServerFailure() => l10n.errorServer,
      ParsingFailure() => l10n.errorParsing,
      NotFoundFailure() => l10n.errorNotFound,
      CacheFailure() => l10n.errorCache,
      UnknownFailure() => l10n.errorUnknown,
    };
  }
}

/// Network reachability or transport errors.
final class NetworkFailure extends AppFailure {
  /// Creates a network failure.
  const NetworkFailure({this.offline = false});

  /// True when the device appears offline.
  final bool offline;

  @override
  List<Object?> get props => [offline];
}

/// Request exceeded configured timeout.
final class TimeoutFailure extends AppFailure {
  /// Creates a timeout failure.
  const TimeoutFailure();

  @override
  List<Object?> get props => [];
}

/// HTTP 429 or provider rate limit.
final class RateLimitFailure extends AppFailure {
  /// Creates a rate-limit failure.
  const RateLimitFailure({this.retryAfterSeconds});

  /// Optional hint from `Retry-After` header (seconds).
  final int? retryAfterSeconds;

  @override
  List<Object?> get props => [retryAfterSeconds];
}

/// Server-side or authorization errors (5xx, 418, invalid API key responses).
final class ServerFailure extends AppFailure {
  /// Creates a server failure.
  const ServerFailure({this.statusCode});

  /// HTTP status when available.
  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// JSON or schema decode failure.
final class ParsingFailure extends AppFailure {
  /// Creates a parsing failure.
  const ParsingFailure({this.cause});

  /// Optional underlying error for logging.
  final Object? cause;

  @override
  List<Object?> get props => [cause];
}

/// HTTP 404 or missing resource.
final class NotFoundFailure extends AppFailure {
  /// Creates a not-found failure.
  const NotFoundFailure({this.statusCode});

  /// HTTP status when available.
  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// Hive or envelope read/write problems.
final class CacheFailure extends AppFailure {
  /// Creates a cache failure.
  const CacheFailure({this.cause});

  /// Optional underlying error for logging.
  final Object? cause;

  @override
  List<Object?> get props => [cause];
}

/// Unmapped client errors.
final class UnknownFailure extends AppFailure {
  /// Creates an unknown failure.
  const UnknownFailure({this.cause});

  /// Optional underlying error for logging.
  final Object? cause;

  @override
  List<Object?> get props => [cause];
}
