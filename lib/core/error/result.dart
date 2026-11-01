import 'package:pulse/core/error/app_failure.dart';

/// Outcome of an operation that may fail with a typed [AppFailure].
sealed class Result<T> {
  const Result();

  /// Pattern-matches success vs failure.
  R when<R>({
    required R Function(T value, bool isStale) success,
    required R Function(AppFailure error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value, :final isStale) => success(value, isStale),
      Failure<T>(:final error) => failure(error),
    };
  }
}

/// Successful result, optionally marked stale when served from expired cache.
final class Success<T> extends Result<T> {
  /// Creates a success value.
  const Success(this.value, {this.isStale = false});

  /// The successful value.
  final T value;

  /// True when [value] was loaded from expired cache (offline / failed refresh).
  final bool isStale;
}

/// Failed result carrying a user-mappable [AppFailure].
final class Failure<T> extends Result<T> {
  /// Creates a failure.
  const Failure(this.error);

  /// Failure details.
  final AppFailure error;
}
